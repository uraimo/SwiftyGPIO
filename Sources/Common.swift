/*
 SwiftyGPIO
 
 Copyright (c) 2019 Umberto Raimondi
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


// MARK: 1-Wire

extension SwiftyGPIO {
    
    public static func hardware1Wires(for board: SupportedBoard) -> [OneWireInterface]? {
        switch board {
        case .RaspberryPiRev1:
            fallthrough
        case .RaspberryPiRev2:
            fallthrough
        case .RaspberryPiPlusZero:
            fallthrough
        case .RaspberryPi2:
            fallthrough
        case .RaspberryPi3:
            return [SysFSOneWire(masterId: 1)]
        default:
            return nil
        }
    }
}

// MARK: - 1-Wire Types

public protocol OneWireInterface {
    func getSlaves() -> [String]
    func readData(_ slaveId: String) -> [String]
}

// MARK: ADC

extension SwiftyGPIO {
    
    public static func hardwareADCs(for board: SupportedBoard) -> [ADCInterface]? {
        switch board {
        case .BeagleBoneBlack:
            return [ADCBBB[0]!, ADCBBB[1]!, ADCBBB[2]!, ADCBBB[3]!]
        case .RaspberryPiRev1:
            fallthrough
        case .RaspberryPiRev2:
            fallthrough
        case .RaspberryPiPlusZero:
            fallthrough
        case .RaspberryPi2:
            fallthrough
        case .RaspberryPi3:
            fallthrough
        default:
            return nil
        }
    }

    // Beaglebone Black ADCs
    static let ADCBBB: [Int: ADCInterface] = [
        0: SysFSADC(adcPath: "/sys/devices/platform/ocp/44e0d000.tscadc/TI-am335x-adc/iio:device1/in_voltage0_raw", id: 0),
        1: SysFSADC(adcPath: "/sys/devices/platform/ocp/44e0d000.tscadc/TI-am335x-adc/iio:device1/in_voltage1_raw", id: 1),
        2: SysFSADC(adcPath: "/sys/devices/platform/ocp/44e0d000.tscadc/TI-am335x-adc/iio:device1/in_voltage2_raw", id: 2),
        3: SysFSADC(adcPath: "/sys/devices/platform/ocp/44e0d000.tscadc/TI-am335x-adc/iio:device1/in_voltage3_raw", id: 3)
    ]
}

// MARK: - ADC Types

public protocol ADCInterface {
    var id: Int { get }
    func getSample() throws -> Int
}

enum ADCError: Error {
    case fileError
    case readError
    case conversionError
}

// MARK: I2C

extension SwiftyGPIO {
    
    public static func hardwareI2Cs(for board: SupportedBoard) -> [I2CInterface]? {
        switch board {
        case .CHIP:
            return [I2CCHIP[1]!, I2CCHIP[2]!]
        case .RaspberryPiRev1:
            fallthrough
        case .RaspberryPiRev2:
            fallthrough
        case .RaspberryPiPlusZero:
            fallthrough
        case .RaspberryPi2:
            fallthrough
        case .RaspberryPi3:
            return [I2CRPI[0]!, I2CRPI[1]!]
        default:
            return nil
        }
    }

    // RaspberryPis I2Cs
    static let I2CRPI: [Int:I2CInterface] = [
        0: SysFSI2C(i2cId: 0),
        1: SysFSI2C(i2cId: 1)
    ]
    
    // CHIP I2Cs
    // i2c.0: connected to the AXP209 chip
    // i2c.1: after 4.4.13-ntc-mlc connected to the U13 header I2C interface
    // i2c.2: connected to the U14 header I2C interface, XIO gpios are connected on this bus
    static let I2CCHIP: [Int:I2CInterface] = [
        1: SysFSI2C(i2cId: 1),
        2: SysFSI2C(i2cId: 2),
    ]
}

// MARK: - I2C Types

public protocol I2CInterface {
    func isReachable(_ address: Int) -> Bool
    func setPEC(_ address: Int, enabled: Bool)
    func readByte(_ address: Int) -> UInt8
    func readByte(_ address: Int, command: UInt8) -> UInt8
    func readWord(_ address: Int, command: UInt8) -> UInt16
    func readData(_ address: Int, command: UInt8) -> [UInt8]
    func writeQuick(_ address: Int)
    func writeByte(_ address: Int, value: UInt8)
    func writeByte(_ address: Int, command: UInt8, value: UInt8)
    func writeWord(_ address: Int, command: UInt8, value: UInt16)
    func writeData(_ address: Int, command: UInt8, values: [UInt8])
    // One-shot rd/wr not provided
}


//MARK: PWM

extension SwiftyGPIO {
    
    public static func hardwarePWMs(for board: SupportedBoard) -> [Int:[GPIOName:PWMInterface]]? {
        switch board {
        case .RaspberryPiRev1:
            fallthrough
        case .RaspberryPiRev2:
            fallthrough
        case .RaspberryPiPlusZero:
            return PWMRPI1
        case .RaspberryPi2:
            fallthrough
        case .RaspberryPi3:
            return PWMRPI23
        default:
            return nil
        }
    }
    
    // RaspberryPis ARMv6 (all 1, Zero, Zero W) PWMs, only accessible ones, divided in channels (can use only one for each channel)
    static let PWMRPI1: [Int:[GPIOName:PWMInterface]] = [
        0: [.pin12: RaspberryPWM(gpioId: 12, alt: 0, channel:0, baseAddr: 0x20000000), .pin18: RaspberryPWM(gpioId: 18, alt: 5, channel:0, baseAddr: 0x20000000)],
        1: [.pin13: RaspberryPWM(gpioId: 13, alt: 0, channel:1, baseAddr: 0x20000000), .pin19: RaspberryPWM(gpioId: 19, alt: 5, channel:1, baseAddr: 0x20000000)]
    ]
    
    // RaspberryPis ARMv7 (2-3) PWMs, only accessible ones, divided in channels (can use only one for each channel)
    static let PWMRPI23: [Int:[GPIOName:PWMInterface]] = [
        0: [.pin12: RaspberryPWM(gpioId: 12, alt: 0, channel:0, baseAddr: 0x3F000000), .pin18: RaspberryPWM(gpioId: 18, alt: 5, channel:0, baseAddr: 0x3F000000)],
        1: [.pin13: RaspberryPWM(gpioId: 13, alt: 0, channel:1, baseAddr: 0x3F000000), .pin19: RaspberryPWM(gpioId: 19, alt: 5, channel:1, baseAddr: 0x3F000000)]
    ]
}

// MARK: - PWM Types

public protocol PWMInterface {
    func initPWM()
    func startPWM(period ns: Int, duty percent: Float)
    func stopPWM()
    
    func initPWMPattern(bytes count: Int, at frequency: Int, with resetDelay: Int, dutyzero: Int, dutyone: Int)
    func sendDataWithPattern(values: [UInt8])
    func waitOnSendData()
    func cleanupPattern()
}

//MARK: SPI

extension SwiftyGPIO {
    
    public static func hardwareSPIs(for board: SupportedBoard) -> [SPIInterface]? {
        switch board {
        case .CHIP:
            return [SPICHIP[0]!]
        case .RaspberryPiRev1:
            fallthrough
        case .RaspberryPiRev2:
            fallthrough
        case .RaspberryPiPlusZero:
            fallthrough
        case .RaspberryPi2:
            fallthrough
        case .RaspberryPi3:
            return [SPIRPI[0]!, SPIRPI[1]!]
        default:
            return nil
        }
    }

    // RaspberryPis SPIs
    static let SPIRPI: [Int:SPIInterface] = [
        0: SysFSSPI(spiId:"0.0"),
        1: SysFSSPI(spiId:"0.1")
    ]
    
    // CHIP SPIs
    // Supported but not readily available
    // See: https://bbs.nextthing.co/t/can-interface-spi-and-can-utils/18042/3
    //      https://bbs.nextthing.co/t/can-bus-mcp2515-via-spi-anyone/11388/2
    static let SPICHIP: [Int:SPIInterface] = [
        0: SysFSSPI(spiId:"2.0")
    ]
}

// MARK: - SPI Types

public protocol SPIInterface {
    // Send data at the requested frequency (from 500Khz to 20 Mhz)
    func sendData(_ values: [UInt8], frequencyHz: UInt)
    // Send data at the default frequency
    func sendData(_ values: [UInt8])
    // Send data and then receive a chunck of data at the requested frequency (from 500Khz to 20 Mhz)
    func sendDataAndRead(_ values: [UInt8], frequencyHz: UInt) -> [UInt8]
    // Send data and then receive a chunck of data at the default frequency
    func sendDataAndRead(_ values: [UInt8]) -> [UInt8]
    // Returns true if the SPIInterface is using a real SPI pin, false if performing bit-banging
    var isHardware: Bool { get }
}

//MARK: UART

extension SwiftyGPIO {
    
    public static func UARTs(for board: SupportedBoard) -> [UARTInterface]? {
        switch board {
        case .CHIP:
            return [SysFSUART(["serial0","ttyAMA0"])!]
        case .RaspberryPiRev1:
            fallthrough
        case .RaspberryPiRev2:
            fallthrough
        case .RaspberryPiPlusZero:
            fallthrough
        case .RaspberryPi2:
            return [SysFSUART(["serial0","ttyAMA0"])!]
        case .RaspberryPi3:
            return [SysFSUART(["serial0","ttyS0"])!,
                    SysFSUART(["serial1","ttyAMA0"])!]
        default:
            return nil
        }
    }
}

// MARK: - UART Types
public protocol UARTInterface {
    func configureInterface(speed: UARTSpeed, bitsPerChar: CharSize, stopBits: StopBits, parity: ParityType)
    func readString() -> String
    func readLine() -> String
    func readData() -> [CChar]
    func writeString(_ value: String)
    func writeData(_ values: [CChar])
}

public enum ParityType {
    case none
    case even
    case odd
    
    public func configure(_ cfg: inout termios) {
        switch self {
        case .none:
            cfg.c_cflag &= ~UInt32(PARENB | PARODD)
        case .even:
            cfg.c_cflag &= ~UInt32(PARENB | PARODD)
            cfg.c_cflag |= UInt32(PARENB)
        case .odd:
            cfg.c_cflag |= UInt32(PARENB | PARODD)
        }
    }
}

public enum CharSize {
    case eight
    case seven
    case six
    
    public func configure(_ cfg: inout termios) {
        cfg.c_cflag = (cfg.c_cflag & ~UInt32(CSIZE))
        switch self {
        case .eight:
            cfg.c_cflag |= UInt32(CS8)
        case .seven:
            cfg.c_cflag |= UInt32(CS7)
        case .six:
            cfg.c_cflag |= UInt32(CS6)
        }
    }
}

public enum StopBits {
    case one
    case two
    
    public func configure(_ cfg: inout termios) {
        switch self {
        case .one:
            cfg.c_cflag &= ~UInt32(CSTOPB)
        case .two:
            cfg.c_cflag |= UInt32(CSTOPB)
        }
    }
}

public enum UARTSpeed {
    case s2400
    case s4800
    case s9600
    case s19200
    case s38400
    case s57600
    case s115200
    
    public func configure(_ cfg: inout termios) {
        switch self {
        case .s2400:
            cfsetispeed(&cfg, speed_t(B2400))
            cfsetospeed(&cfg, speed_t(B2400))
        case .s4800:
            cfsetispeed(&cfg, speed_t(B4800))
            cfsetospeed(&cfg, speed_t(B4800))
        case .s9600:
            cfsetispeed(&cfg, speed_t(B9600))
            cfsetospeed(&cfg, speed_t(B9600))
        case .s19200:
            cfsetispeed(&cfg, speed_t(B19200))
            cfsetospeed(&cfg, speed_t(B19200))
        case .s38400:
            cfsetispeed(&cfg, speed_t(B38400))
            cfsetospeed(&cfg, speed_t(B38400))
        case .s57600:
            cfsetispeed(&cfg, speed_t(B57600))
            cfsetospeed(&cfg, speed_t(B57600))
        case .s115200:
            cfsetispeed(&cfg, speed_t(B115200))
            cfsetospeed(&cfg, speed_t(B115200))
        }
    }
}
