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
import Foundation

internal let GPIOBASEPATH="/sys/class/gpio/"

// MARK: GPIO

public class GPIO {
    var name: String = ""
    var id: Int = 0
    var exported = false
    var listening = false
    var intThread: Thread?
    var intFuncFalling: ((GPIO) -> Void)?
    var intFuncRaising: ((GPIO) -> Void)?
    var intFuncChange: ((GPIO) -> Void)?

    public init(name: String,
                id: Int) {
        self.name = name
        self.id = id
    }

    public var direction: GPIODirection {
        set(dir) {
            if !exported {enableIO(id)}
            performSetting("gpio" + String(id) + "/direction", value: dir.rawValue)
        }
        get {
            if !exported { enableIO(id)}
            return GPIODirection(rawValue: getStringValue("gpio"+String(id)+"/direction")!)!
        }
    }

    public var edge: GPIOEdge {
        set(dir) {
            if !exported {enableIO(id)}
            performSetting("gpio"+String(id)+"/edge", value: dir.rawValue)
        }
        get {
            if !exported {enableIO(id)}
            return GPIOEdge(rawValue: getStringValue("gpio"+String(id)+"/edge")!)!
        }
    }

    public var activeLow: Bool {
        set(act) {
            if !exported {enableIO(id)}
            performSetting("gpio"+String(id)+"/active_low", value: act ? "1":"0")
        }
        get {
            if !exported {enableIO(id)}
            return getIntValue("gpio"+String(id)+"/active_low")==0
        }
    }

    public var value: Int {
        set(val) {
            if !exported {enableIO(id)}
            performSetting("gpio"+String(id)+"/value", value: val)
        }
        get {
            if !exported {enableIO(id)}
            return getIntValue("gpio"+String(id)+"/value")!
        }
    }

    public func isMemoryMapped() -> Bool {
        return false
    }

    public func onFalling(_ closure: @escaping (GPIO) -> Void) {
        intFuncFalling = closure
        if intThread == nil {
            intThread = makeInterruptThread()
            listening = true
            intThread?.start()
        }
    }

    public func onRaising(_ closure: @escaping (GPIO) -> Void) {
        intFuncRaising = closure
        if intThread == nil {
            intThread = makeInterruptThread()
            listening = true
            intThread?.start()
        }
    }

    public func onChange(_ closure: @escaping (GPIO) -> Void) {
        intFuncChange = closure
        if intThread == nil {
            intThread = makeInterruptThread()
            listening = true
            intThread?.start()
        }
    }

    public func clearListeners() {
        (intFuncFalling, intFuncRaising, intFuncChange) = (nil, nil, nil)
        listening = false
    }

}

fileprivate extension GPIO {

    func enableIO(_ id: Int) {
        writeToFile(GPIOBASEPATH+"export", value:String(id))
        exported = true
    }

    func performSetting(_ filename: String, value: String) {
        writeToFile(GPIOBASEPATH+filename, value:value)
    }

    func performSetting(_ filename: String, value: Int) {
        writeToFile(GPIOBASEPATH+filename, value: String(value))
    }

    func getStringValue(_ filename: String) -> String? {
        return readFromFile(GPIOBASEPATH+filename)
    }

    func getIntValue(_ filename: String) -> Int? {
        if let res = readFromFile(GPIOBASEPATH+filename) {
            return Int(res)
        }
        return nil
    }

    func writeToFile(_ path: String, value: String) {
        let fp = fopen(path, "w")
        if fp != nil {
            let ret = fwrite(value, MemoryLayout<CChar>.stride, value.characters.count, fp)
            if ret<value.characters.count {
                if ferror(fp) != 0 {
                    perror("Error while writing to file")
                    abort()
                }
            }
            fclose(fp)
        }
    }

    func readFromFile(_ path: String) -> String? {
        let MAXLEN = 8

        let fp = fopen(path, "r")
        var res: String?
        if fp != nil {
            let buf = UnsafeMutablePointer<CChar>.allocate(capacity: MAXLEN)
            let len = fread(buf, MemoryLayout<CChar>.stride, MAXLEN, fp)
            if len < MAXLEN {
                if ferror(fp) != 0 {
                    perror("Error while reading from file")
                    abort()
                }
            }
            fclose(fp)
            //Remove the trailing \n
            buf[len-1]=0
            res = String.init(validatingUTF8: buf)
            buf.deallocate(capacity: MAXLEN)
        }
        return res
    }

    func makeInterruptThread() -> Thread? {
        //Ignored by Linux
        guard #available(iOS 10.0, macOS 10.12, *) else {return nil}

        let thread = Thread {

            let gpath = GPIOBASEPATH+"gpio"+String(self.id)+"/value"
            self.direction = .IN
            self.edge = .BOTH

            let fp = open(gpath, O_RDONLY)
            var buf: [Int8] = [0, 0, 0] //Dummy read to discard current value
            read(fp, &buf, 3)

            var pfd = pollfd(fd:fp, events:Int16(truncatingBitPattern:POLLPRI), revents:0)

            while self.listening {
                let ready = poll(&pfd, 1, -1)
                if ready > -1 {
                    lseek(fp, 0, SEEK_SET)
                    read(fp, &buf, 2)
                    buf[1]=0

                    let res = String(validatingUTF8: buf)!
                    switch res {
                    case "0":
                        self.intFuncFalling?(self)
                    case "1":
                        self.intFuncRaising?(self)
                    default:
                        break
                    }
                    self.intFuncChange?(self)
                }
            }
        }
        return thread
    }
}

// MARK: GPIO:Raspberry

public final class RaspberryGPIO: GPIO {

    var setGetId: UInt = 0
    var baseAddr: Int = 0
    var inited = false

    let BCM2708_PERI_BASE: Int
    let GPIO_BASE: Int

    var gpioBasePointer: UnsafeMutablePointer<UInt>!
    var gpioGetPointer: UnsafeMutablePointer<UInt>!
    var gpioSetPointer: UnsafeMutablePointer<UInt>!
    var gpioClearPointer: UnsafeMutablePointer<UInt>!

    public init(name: String, id: Int, baseAddr: Int) {
        self.setGetId = UInt(1<<id)
        self.BCM2708_PERI_BASE = baseAddr
        self.GPIO_BASE = BCM2708_PERI_BASE + 0x200000 /* GPIO controller */
        super.init(name:name, id:id)
    }

    public override var value: Int {
        set(val) {
            if !inited {initIO()}
            gpioSet(val)
        }
        get {
            if !inited {initIO()}
            return gpioGet()
        }
    }

    public override var direction: GPIODirection {
        set(dir) {
            if !inited {initIO()}
            if dir == .IN {
                gpioAsInput()
            } else {
                gpioAsOutput()
            }
        }
        get {
            if !inited {initIO()}
            return gpioGetDirection()
        }
    }

    public override func isMemoryMapped() -> Bool {
        return true
    }

	private func initIO() {
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

		let gpio_map = mmap(
			nil,                 //Any adddress in our space will do
            PAGE_SIZE,          //Map length
            PROT_READ|PROT_WRITE,// Enable reading & writting to mapped memory
            MAP_SHARED,          //Shared with other processes
            mem_fd,              //File to map
            off_t(GPIO_BASE)     //Offset to GPIO peripheral, i.e. GPFSEL0
            )!

        close(mem_fd)

        if (Int(bitPattern: gpio_map) == -1) {    //MAP_FAILED not available, but its value is (void*)-1
            perror("mmap error")
            abort()
        }
        gpioBasePointer = gpio_map.assumingMemoryBound(to: UInt.self)

        gpioGetPointer = gpioBasePointer.advanced(by: 13)   // GPLEV0
        gpioSetPointer = gpioBasePointer.advanced(by: 7)    // GPSET0
        gpioClearPointer = gpioBasePointer.advanced(by: 10) // GPCLR0

        inited = true
    }

    private func gpioAsInput() {
        let ptr = gpioBasePointer.advanced(by: id/10)       // GPFSELn 0..5
        ptr.pointee &= ~(7<<((UInt(id)%10)*3))                    // SEL=000 input
    }

    private func gpioAsOutput() {
        let ptr = gpioBasePointer.advanced(by: id/10)       // GPFSELn 0..5
        ptr.pointee &= ~(7<<((UInt(id)%10)*3))
        ptr.pointee |=  (1<<((UInt(id)%10)*3))                    // SEL=001 output
    }

    private func gpioGetDirection() -> GPIODirection {
        let ptr = gpioBasePointer.advanced(by: id/10)       // GPFSELn 0..5
        let d = (ptr.pointee & (7<<((UInt(id)%10)*3)))
        return (d == 0) ? .IN : .OUT
    }

    private func gpioGet() -> Int {
        return ((gpioGetPointer.pointee & setGetId)>0) ? 1 : 0
    }

    private func gpioSet(_ value: Int) {
        let ptr = value==1 ? gpioSetPointer : gpioClearPointer
        ptr!.pointee = setGetId
    }

}

public struct SwiftyGPIO {

    public static func GPIOs(for board: SupportedBoard) -> [GPIOName: GPIO] {
        switch board {
        case .RaspberryPiRev1:
            return GPIORPIRev1
        case .RaspberryPiRev2:
            return GPIORPIRev2
        case .RaspberryPiPlusZero:
            return GPIORPIPlusZERO
        case .RaspberryPi2:
            fallthrough
        case .RaspberryPi3:
            return GPIORPI2
        case .CHIP:
            return GPIOCHIP
        case .BeagleBoneBlack:
            return GPIOBEAGLEBONE
        case .BananaPi:
            return GPIOBANANAPI
        case .OrangePi:
            return GPIOORANGEPI
        case .OrangePiZero:
            return GPIOORANGEPIZERO
        }
    }
}

// MARK: - Global Enums

public enum SupportedBoard {
    case RaspberryPiRev1   // Pi A,B Revision 1
    case RaspberryPiRev2   // Pi A,B Revision 2
    case RaspberryPiPlusZero // Pi A+,B+,Zero with 40 pin header
    case RaspberryPi2 // Pi 2 with 40 pin header
    case RaspberryPi3 // Pi 3 with 40 pin header
    case CHIP
    case BeagleBoneBlack
    case BananaPi
    case OrangePi
    case OrangePiZero
}

public enum GPIOName {
    case P0
    case P1
    case P2
    case P3
    case P4
    case P5
    case P6
    case P7
    case P8
    case P9
    case P10
    case P11
    case P12
    case P13
    case P14
    case P15
    case P16
    case P17
    case P18
    case P19
    case P20
    case P21
    case P22
    case P23
    case P24
    case P25
    case P26
    case P27
    case P28
    case P29
    case P30
    case P31
    case P32
    case P33
    case P34
    case P35
    case P36
    case P37
    case P38
    case P39
    case P40
    case P41
    case P42
    case P43
    case P44
    case P45
    case P46
    case P47
}

public enum GPIODirection: String {
    case IN="in"
    case OUT="out"
}

public enum GPIOEdge: String {
    case NONE="none"
    case RISING="rising"
    case FALLING="falling"
    case BOTH="both"
}

public enum ByteOrder {
    case MSBFIRST
    case LSBFIRST
}

// MARK: - Constants

let PAGE_SIZE = (1 << 12)

// MARK: - Darwin / Xcode Support
#if os(OSX)
    private var O_SYNC: CInt { fatalError("Linux only") }
#endif
