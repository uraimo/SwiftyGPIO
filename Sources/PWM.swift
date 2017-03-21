/*
   SwiftyGPIO

   Copyright (c) 2016 Umberto Raimondi
   Licensed under the MIT license, as follows:

   Permission is hereby granted, free of charge, to any person obtaining a copy
   of this software and associated documentation files (the "Software"), to deal
   in the Software without restriction, including without limitation the rights
   to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
   copies of the Software, and to permit persons to whom the Software is
   furnished to do so, subject to the following conditions:

   The above copyright notice and this permission notice shall be included in all
   copies or substantial portions of the Software.

   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
   OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
   SOFTWARE.)
*/
#if os(Linux)
    import Glibc
#else
    import Darwin.C
#endif

extension SwiftyGPIO {

    public static func hardwarePWMs(for board: SupportedBoard) -> [Int:[GPIOName:PWMOutput]]? {
        switch board {
        case .RaspberryPiRev1:
            fallthrough
        case .RaspberryPiRev2:
            fallthrough
        case .RaspberryPiPlusZero:
            return PWMRPI1
        case .RaspberryPi2:
            return PWMRPI23
        default:
            return nil
        }
    }
}

// MARK: - SPI Presets
extension SwiftyGPIO {

    // RaspberryPis ARMv6 (all 1, Zero, Zero W) PWMs, only accessible ones, divided in channels (can use only one for each channel)
    static let PWMRPI1: [Int:[GPIOName:PWMOutput]] = [
        0: [.P12: HardwarePWM(gpioId: 12, alt: 0, channel:0, baseAddr: 0x20000000), .P18: HardwarePWM(gpioId: 18, alt: 5, channel:0, baseAddr: 0x20000000)],
        1: [.P13: HardwarePWM(gpioId: 13, alt: 0, channel:1, baseAddr: 0x20000000), .P19: HardwarePWM(gpioId: 19, alt: 5, channel:1, baseAddr: 0x20000000)]
    ]

    // RaspberryPis ARMv7 (2-3) PWMs, only accessible ones, divided in channels (can use only one for each channel)
    static let PWMRPI23: [Int:[GPIOName:PWMOutput]] = [
        0: [.P12: HardwarePWM(gpioId: 12, alt: 0, channel:0, baseAddr: 0x3F000000), .P18: HardwarePWM(gpioId: 18, alt: 5, channel:0, baseAddr: 0x3F000000)],
        1: [.P13: HardwarePWM(gpioId: 13, alt: 0, channel:1, baseAddr: 0x3F000000), .P19: HardwarePWM(gpioId: 19, alt: 5, channel:1, baseAddr: 0x3F000000)]
    ]
}

// MARK: PWM

public protocol PWMOutput {
    func initPWM()
    func startPWM(period ns: Int, duty percent: Int)
    func stopPWM()
    func sendData(with zero: PWMPattern, and one: PWMPattern, values: [UInt8])
}

public struct PWMPattern {
    let period: Int  //ns
    let duty: Int    //percentage
}

public class HardwarePWM: PWMOutput {
    let gpioId: UInt
    let alt: UInt
    let channel: Int

    let BCM2708_PERI_BASE: Int
    let GPIO_BASE: Int  // GPIO Register
    let PWM_BASE: Int   // PWM Register
    let CLOCK_BASE: Int // Clock Manager Register

    var gpioBasePointer: UnsafeMutablePointer<UInt>!
    var pwmBasePointer: UnsafeMutablePointer<UInt>!
    var clockBasePointer: UnsafeMutablePointer<UInt>!

    public init(gpioId: UInt, alt: UInt, channel: Int, baseAddr: Int) {
        self.gpioId = gpioId
        self.alt = alt
        self.channel = channel
        BCM2708_PERI_BASE = baseAddr
        GPIO_BASE = BCM2708_PERI_BASE + 0x200000  // GPIO Register
        PWM_BASE =  BCM2708_PERI_BASE + 0x20C000  // PWM Register
        CLOCK_BASE = BCM2708_PERI_BASE + 0x101000 // Clock Manager Register
    }

    /// Init PWM on this pin, set alternative function
    public func initPWM() {
        var mem_fd: Int32 = 0

        //Try to open one of the mem devices
        for device in ["/dev/gpiomem", "/dev/mem"] {
            mem_fd=open(device, O_RDWR | O_SYNC)
            if mem_fd>0 {
                break
            }
        }
        guard mem_fd > 0 else {
            fatalError("Can't open /dev/mem , use sudo!")
        }

        gpioBasePointer = memmap(from: mem_fd, at: GPIO_BASE)
        pwmBasePointer = memmap(from: mem_fd, at: PWM_BASE)
        clockBasePointer = memmap(from: mem_fd, at: CLOCK_BASE)

        close(mem_fd)

        // set PWM alternate function for this GPIO
        setAlt()
    }

    /// Start a PWM signal with specific period in ns and duty cycle from 0 to 100.
    /// The signal starts, asynchronously(manged by a device external to the CPU), once this method is called and 
    /// needs to be stopped manually calling `stopPWM()`.
    public func startPWM(period ns: Int, duty percent: Int) {
        // Kill the clock
        clockBasePointer.advanced(by: 40).pointee = CLKM_PASSWD | CLKM_CTL_KILL     //CM CTL register: Set KILL flag
        usleep(10)

        // If the required frequency is too high, this value reduces the number of samples (scale does the opposite)
        let highFreqSampleReduction: UInt = (ns < 750) ? 10 : 1

        let freq: UInt = (1_000_000_000/UInt(ns)) * 100 / highFreqSampleReduction
        let (idiv, scale) = calculateDIVI(base: .PLLD, desired: freq)                               //Using the faster (with known freq) available clock to reduce jitter

        // Configure the clock and divisor that will be used to generate the signal
        clockBasePointer.advanced(by: 41).pointee = CLKM_PASSWD | (idiv << CLKM_DIV_DIVI)            //CM CTL DIV register: Set DIVI value 
        clockBasePointer.advanced(by: 40).pointee = CLKM_PASSWD | CLKM_CTL_ENAB | CLKM_CTL_SRC_PLLD  //CM CTL register: Enable clock, MASH 0, source PLLD /////////////0x16
        pwmBasePointer.pointee = 0                                                                   //PWM CTL register: Everything at 0, enable flag included, disables previous PWM
        usleep(10)
        // Configure the parameters for the M/S algorithm, S the number of total slots in RNG1 and M the number of slots with high value in DAT1
        let RNG = (channel == 0) ? 4 : 8
        let DAT = (channel == 0) ? 5 : 9
        pwmBasePointer.advanced(by: RNG).pointee = 100 * scale / highFreqSampleReduction                                    //RNG1 register
        pwmBasePointer.advanced(by: DAT).pointee = UInt((Float(percent) / Float(highFreqSampleReduction)) * Float(scale))   //DAT1 register
        let PWMCTL_MSEN = (channel == 0) ? PWMCTL_MSEN1 : PWMCTL_MSEN2
        let PWMCTL_PWEN = (channel == 0) ? PWMCTL_PWEN1 : PWMCTL_PWEN2
        pwmBasePointer.pointee = PWMCTL_MSEN | PWMCTL_PWEN                                                              //PWM CTL register, channel enabled, M/S mode
    }

    public func stopPWM() {
        pwmBasePointer.pointee = 0      //PWM CTL register, everything at 0, enable flag included
    }

    public func sendData(with zero: PWMPattern, and one: PWMPattern, values: [UInt8]) {
        //???
    }

    /// Maps a block of memory and returns the pointer
    private func memmap(from mem_fd: Int32, at offset: Int) -> UnsafeMutablePointer<UInt> {
        let m = mmap(
            nil,                 //Any adddress in our space will do
            BLOCK_SIZE,          //Map length
            PROT_READ|PROT_WRITE,// Enable reading & writting to mapped memory
            MAP_SHARED,          //Shared with other processes
            mem_fd,              //File to map
            off_t(offset)     //Offset to GPIO peripheral
            )!

        if (unsafeBitCast(m, to: Int.self) == -1) {    //MAP_FAILED not available, but its value is (void*)-1
            perror("mmap error")
            abort()
        }
        let pointer = m.assumingMemoryBound(to: UInt.self)

        return pointer
    }

    /// Set the alternative function for this GPIO
    private func setAlt() {
        let altid = (self.alt<=3) ? self.alt+4 : self.alt==4 ? 3 : 2
        let ptr = gpioBasePointer.advanced(by: Int(gpioId/10))       // GPFSELn 0..5
        ptr.pointee &= ~(7<<((gpioId%10)*3))
        ptr.pointee |=  (altid<<((gpioId%10)*3))
    }

    /// Calculate the DIVI value that will divide the selected base clock frequency to obtain the desired frequency.
    ///
    /// For low frequencies, the DIVI value is calculated again increasing the scale value until an acceptable value 
    /// for the divisor is found. DIVI should be smaller than half the maximum value (0x1000) to reduce jitter.
    /// The scale value (increased by 10 every time the DIVI value is too high) will be used to increase the number 
    /// of samples generated by the M/S algorithm.
    ///
    /// - Parameter base: base clock that will be used to generate the signal
    ///
    /// - Parameter desired: desired target frequency
    ///
    /// - Returns: divi divisor value, and scale value as a multiple of ten
    ///
    private func calculateDIVI(base: ClockSource, desired: UInt) -> (divi: UInt, scale: UInt) {
        var divi: UInt = base.rawValue/desired
        var scale: UInt = 1

        while divi > 0x800 {
            // Divisor too high (greater then half the limit), would not be generated properly
            scale *= 10
            divi = base.rawValue/(desired*scale)
        }
        if divi < 1 {
            divi = 1
        }
        return (divi, scale)
    }
}

// MARK: - PWM Contants

// Constants for the Clock Manager General Purpose Control Register
let CLKM_PASSWD: UInt = 0x5A000000
let CLKM_CTL_KILL: UInt = (1 << 5)
let CLKM_CTL_ENAB: UInt = (1 << 4)
let CLKM_CTL_SRC_OSC: UInt = 1    // 19.2 MHz oscillator
let CLKM_CTL_SRC_PLLA: UInt = 4   // ~393.216 MHz PLLA (Audio)
let CLKM_CTL_SRC_PLLC: UInt = 5   // 1000 MHz PLLC (changes with overclock settings)
let CLKM_CTL_SRC_PLLD: UInt = 6   // 500 MHz  PLLD
let CLKM_CTL_SRC_HDMI: UInt = 7   // 216 MHz  HDMI auxiliary
// Constants for the Clock Manager General Purpose Divisors Register
let CLKM_DIV_DIVI: UInt = 12
let CLKM_DIV_DIVF: UInt = 0
// Constants for the PWM Control Register
let PWMCTL_MSEN2: UInt =  (1 << 15)
// No PWMCTL_CLRF2, the FIFO is shared
let PWMCTL_USEF2: UInt =  (1 << 13)
let PWMCTL_POLA2: UInt =  (1 << 12)
let PWMCTL_SBIT2: UInt =  (1 << 11)
let PWMCTL_RPTL2: UInt =  (1 << 10)
let PWMCTL_MODE2: UInt =  (1 << 9)
let PWMCTL_PWEN2: UInt =  (1 << 8)
let PWMCTL_MSEN1: UInt =  (1 << 7)
let PWMCTL_CLRF1: UInt =  (1 << 6)
let PWMCTL_USEF1: UInt =  (1 << 5)
let PWMCTL_POLA1: UInt =  (1 << 4)
let PWMCTL_SBIT1: UInt =  (1 << 3)
let PWMCTL_RPTL1: UInt =  (1 << 2)
let PWMCTL_MODE1: UInt =  (1 << 1)
let PWMCTL_PWEN1: UInt =  (1 << 0)

// Clock sources
// 0     0 Hz     Ground
// 1     19.2 MHz oscillator
// 2     0 Hz     testdebug0
// 3     0 Hz     testdebug1
// 4     ~393.216 MHz PLLA (Audio)
// 5     1000 MHz PLLC (changes with overclock settings)
// 6     500 MHz  PLLD
// 7     216 MHz  HDMI auxiliary
// 8-15  0 Hz     Ground
enum ClockSource: UInt {
    case Oscillator = 19200000
    case PLLA = 393216000
    case PLLC = 1000000000
    case PLLD = 500000000
    case HDMI = 216000000
}
