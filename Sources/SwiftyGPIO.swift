//
// SwiftyGPIO
//
// Copyright (c) 2016 Umberto Raimondi and contributors.
// Licensed under the MIT license, as follows:
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.)
//

#if os(Linux)
    import Glibc
#else
    import Darwin.C
#endif
import Foundation

internal let GPIOBASEPATH="/sys/class/gpio/"
internal let SPIBASEPATH="/dev/spidev"


public class GPIO {
    var name: String = ""
    var id: Int = 0
    var exported = false
    var listening = false
    var intThread: Thread? = nil
    var intFuncFalling: ((GPIO)->Void)? = nil
    var intFuncRaising: ((GPIO)->Void)? = nil
    var intFuncChange: ((GPIO)->Void)? = nil
    
    
    public init(name: String,
                id: Int) {
        self.name = name
        self.id = id
    }
    
    public var direction: GPIODirection {
        set(dir){
            if !exported {enableIO(id)}
            performSetting("gpio" + String(id) + "/direction", value: dir.rawValue)
        }
        get {
            if !exported { enableIO(id)}
            return GPIODirection(rawValue: getStringValue("gpio"+String(id)+"/direction")!)!
        }
    }
    
    public var edge: GPIOEdge {
        set(dir){
            if !exported {enableIO(id)}
            performSetting("gpio"+String(id)+"/edge",value: dir.rawValue)
        }
        get {
            if !exported {enableIO(id)}
            return GPIOEdge(rawValue: getStringValue("gpio"+String(id)+"/edge")!)!
        }
    }
    
    public var activeLow: Bool{
        set(act){
            if !exported {enableIO(id)}
            performSetting("gpio"+String(id)+"/active_low",value: act ? "1":"0")
        }
        get {
            if !exported {enableIO(id)}
            return getIntValue("gpio"+String(id)+"/active_low")==0
        }
    }
    
    public var value: Int{
        set(val){
            if !exported {enableIO(id)}
            performSetting("gpio"+String(id)+"/value",value: val)
        }
        get {
            if !exported {enableIO(id)}
            return getIntValue("gpio"+String(id)+"/value")!
        }
    }
    
    public func isMemoryMapped() -> Bool {
        return false
    }
    
    public func onFalling(_ closure: @escaping (GPIO)->Void){
        intFuncFalling = closure
        if intThread == nil {
            intThread = makeInterruptThread()
            listening = true
            intThread?.start()
        }
    }
    
    public func onRaising(_ closure: @escaping (GPIO)->Void){
        intFuncRaising = closure
        if intThread == nil {
            intThread = makeInterruptThread()
            listening = true
            intThread?.start()
        }
    }
    
    public func onChange(_ closure: @escaping (GPIO)->Void){
        intFuncChange = closure
        if intThread == nil {
            intThread = makeInterruptThread()
            listening = true
            intThread?.start()
        }
    }
    
    public func clearListeners(){
        (intFuncFalling,intFuncRaising,intFuncChange) = (nil,nil,nil)
        listening = false
    }
    
}

fileprivate extension GPIO {
    
    func enableIO(_ id: Int){
        writeToFile(GPIOBASEPATH+"export",value:String(id))
        exported = true
    }
    
    func performSetting(_ filename: String, value: String){
        writeToFile(GPIOBASEPATH+filename, value:value)
    }
    
    func performSetting(_ filename: String, value: Int){
        writeToFile(GPIOBASEPATH+filename, value: String(value))
    }
    
    func getStringValue(_ filename: String)->String?{
        return readFromFile(GPIOBASEPATH+filename)
    }
    
    func getIntValue(_ filename: String)->Int?{
        if let res = readFromFile(GPIOBASEPATH+filename) {
            return Int(res)
        }
        return nil
    }
    
    func writeToFile(_ path: String, value:String){
        let fp = fopen(path,"w")
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
        
        let fp = fopen(path,"r")
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
            
            let fp = open(gpath,O_RDONLY)
            var buf:[Int8] = [0,0,0] //Dummy read to discard current value
            read(fp,&buf,3)
            
            var pfd = pollfd(fd:fp,events:Int16(truncatingBitPattern:POLLPRI),revents:0)
            
            while self.listening {
                let ready = poll(&pfd, 1, -1)
                if ready > -1 {
                    lseek(fp, 0, SEEK_SET)
                    read(fp,&buf,2)
                    buf[1]=0
                    
                    let res = String(validatingUTF8: buf)!
                    switch(res){
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

public final class RaspiGPIO : GPIO {
    
    var setGetId: UInt = 0
    var baseAddr: Int = 0
    var inited = false
    
    let BCM2708_PERI_BASE: Int
    let GPIO_BASE: Int
    let BLOCK_SIZE = 4*1024
    
    var gpioBasePointer: UnsafeMutablePointer<UInt>!
    var gpioGetPointer: UnsafeMutablePointer<UInt>!
    var gpioSetPointer: UnsafeMutablePointer<UInt>!
    var gpioClearPointer: UnsafeMutablePointer<UInt>!
    
    public init(name: String, id: Int, baseAddr: Int) {
        self.setGetId = UInt(1<<id)
        self.BCM2708_PERI_BASE = baseAddr
        self.GPIO_BASE = BCM2708_PERI_BASE + 0x200000 /* GPIO controller */
        super.init(name:name,id:id)
    }
    
    public override var value: Int{
        set(val){
            if !inited {initIO()}
            gpioSet(val)
        }
        get {
            if !inited {initIO()}
            return gpioGet()
        }
    }
   
    public override var direction: GPIODirection {
        set(dir){
            if !inited {initIO()}
            if dir == .IN {
                gpioAsInput()
            }else{
                gpioAsOutput()
            }
        }
        get {
            if !inited {initIO()}
            return gpioGetDirection()
        }
    }

    public override func isMemoryMapped() -> Bool{
        return true
    }
    
	private func initIO(){
		var mem_fd=Int32(0)

        //Try to open one of the mem devices
		for device in ["/dev/gpiomem","/dev/mem"] {
			mem_fd=open(device, O_RDWR | O_SYNC)
			if mem_fd>0 {
				break
			}
		}
		guard (mem_fd > 0) else {
            fatalError("Can't open /dev/mem , use sudo!")
		}

		let gpio_map = mmap(
			nil,                 //Any adddress in our space will do
            BLOCK_SIZE,          //Map length
            PROT_READ|PROT_WRITE,// Enable reading & writting to mapped memory
            MAP_SHARED,          //Shared with other processes
            mem_fd,              //File to map
            off_t(GPIO_BASE)     //Offset to GPIO peripheral, i.e. GPFSEL0
            )!
        
        close(mem_fd)
        
        gpioBasePointer = gpio_map.assumingMemoryBound(to: UInt.self)
        if (gpioBasePointer.pointee == UInt(bitPattern: -1)) {    //MAP_FAILED not available, but its value is (void*)-1
            print("mmap error: " + "\(gpioBasePointer)")
            abort()
        }
        
        gpioGetPointer = gpioBasePointer.advanced(by: 13)   // GPLEV0
        gpioSetPointer = gpioBasePointer.advanced(by: 7)    // GPSET0
        gpioClearPointer = gpioBasePointer.advanced(by: 10) // GPCLR0
        
        inited = true
    }
    
    private func gpioAsInput(){
        let ptr = gpioBasePointer.advanced(by: id/10)       // GPFSELn 0..5
        ptr.pointee &= ~(7<<((UInt(id)%10)*3))                    // SEL=000 input
    }
    
    private func gpioAsOutput(){
        let ptr = gpioBasePointer.advanced(by: id/10)       // GPFSELn 0..5
        ptr.pointee &= ~(7<<((UInt(id)%10)*3))
        ptr.pointee |=  (1<<((UInt(id)%10)*3))                    // SEL=001 output
    }

    private func gpioGetDirection() -> GPIODirection {
        let ptr = gpioBasePointer.advanced(by: id/10)       // GPFSELn 0..5
        let d = (ptr.pointee & (7<<((UInt(id)%10)*3)))
        return (d == 0) ? .IN : .OUT
    }
    
    private func gpioGet() -> Int{
        return ((gpioGetPointer.pointee & setGetId)>0) ? 1 : 0
    }
    
    private func gpioSet(_ value: Int){
        let ptr = value==1 ? gpioSetPointer : gpioClearPointer
        ptr!.pointee = setGetId
    }
    
}

// MARK: SPI

public protocol SPIOutput {
    func sendData(_ values: [UInt8], order: ByteOrder, clockDelayUsec: Int)
    func sendData(_ values: [UInt8])
    func isHardware()->Bool
    func isOut()->Bool
}

public struct HardwareSPI : SPIOutput {
    let spiId:String
    let isOutput:Bool
    
    public init(spiId: String,isOutput: Bool){
        self.spiId=spiId
        self.isOutput=isOutput
        //TODO: Check if available?
    }
    
    public func sendData(_ values: [UInt8], order: ByteOrder, clockDelayUsec: Int){
        guard isOutput else {return}
        
        let SPI_IOC_WR_MAX_SPEED_HZ: UInt = 0x40046b04
        
        if clockDelayUsec > 0 {
            //Try setting new frequency in Hz
            var frq: CInt = CInt(1_000_000 / Double(clockDelayUsec))
            let fp = open(SPIBASEPATH+spiId, O_WRONLY | O_SYNC)
            _ = ioctl(fp, SPI_IOC_WR_MAX_SPEED_HZ, &frq)
        }
        
        writeToFile(SPIBASEPATH+spiId, values:values)
    }
    
    public func sendData(_ values: [UInt8]){sendData(values,order:.MSBFIRST,clockDelayUsec:0)}
    
    public func isHardware()->Bool{
        return true
    }
    
    public func isOut()->Bool{
        return isOutput
    }
    
    private func writeToFile(_ path: String, values: [UInt8]){
        let fp = fopen(path,"w")
        if fp != nil {
            let ret = fwrite(values, MemoryLayout<CChar>.stride, values.count, fp)
            if ret<values.count {
                if ferror(fp) != 0 {
                    perror("Error while writing to file")
                    abort()
                }
            }
            fclose(fp)
        }
    }   
}

public struct VirtualSPI : SPIOutput{
    let dataGPIO,clockGPIO:GPIO
    
    public init(dataGPIO: GPIO,clockGPIO: GPIO){
        self.dataGPIO = dataGPIO
        self.dataGPIO.direction = .OUT
        self.dataGPIO.value = 0
        self.clockGPIO = clockGPIO
        self.clockGPIO.direction = .OUT
        self.clockGPIO.value = 0
    }
    
    
    public func sendData(_ values: [UInt8], order: ByteOrder, clockDelayUsec: Int){
        let mmapped = dataGPIO.isMemoryMapped()
        if mmapped {
            sendDataGPIOObj(values, order:order, clockDelayUsec:clockDelayUsec)
        }else{
            sendDataSysFS(values, order:order, clockDelayUsec:clockDelayUsec)
        }
    }
    
    public func sendDataGPIOObj(_ values: [UInt8], order: ByteOrder, clockDelayUsec: Int){
        
        var bit:Int = 0
        for value in values {
            for i in 0...7 {
                switch order {
                case .LSBFIRST:
                    bit = ((value & UInt8(1 << i)) == 0) ? 0 : 1
                case .MSBFIRST:
                    bit = ((value & UInt8(1 << (7-i))) == 0) ? 0 : 1
                }
                
                dataGPIO.value = bit
                clockGPIO.value = 1
                if clockDelayUsec>0 {
                    usleep(UInt32(clockDelayUsec))
                }
                clockGPIO.value = 0
            }
        }
    }
    
    public func sendDataSysFS(_ values: [UInt8], order: ByteOrder, clockDelayUsec: Int){
        
        let mosipath = GPIOBASEPATH+"gpio"+String(self.dataGPIO.id)+"/value"
        let sclkpath = GPIOBASEPATH+"gpio"+String(self.clockGPIO.id)+"/value"
        let HIGH = "1"
        let LOW = "0"
        
        let fpmosi: UnsafeMutablePointer<FILE>! = fopen(mosipath,"w")
        let fpsclk: UnsafeMutablePointer<FILE>! = fopen(sclkpath,"w")
        
        guard (fpmosi != nil)&&(fpsclk != nil) else {
            perror("Error while opening gpio")
            abort()
        }
        setvbuf(fpmosi, nil, _IONBF, 0)
        setvbuf(fpsclk, nil, _IONBF, 0)
        
        var bit:String = LOW
        for value in values {
            for i in 0...7 {
                switch order {
                case .LSBFIRST:
                    bit = ((value & UInt8(1 << i)) == 0) ? LOW : HIGH
                case .MSBFIRST:
                    bit = ((value & UInt8(1 << (7-i))) == 0) ? LOW : HIGH
                }
                
                writeToFP(fpmosi,value:bit)
                writeToFP(fpsclk,value:HIGH)
                if clockDelayUsec>0 {
                    usleep(UInt32(clockDelayUsec))
                }
                writeToFP(fpsclk,value:LOW)
            }
        }
        fclose(fpmosi)
        fclose(fpsclk)
    }
    
    private func writeToFP(_ fp: UnsafeMutablePointer<FILE>, value: String){
        let ret = fwrite(value, MemoryLayout<CChar>.stride, 1, fp)
        if ret<1 {
            if ferror(fp) != 0 {
                perror("Error while writing to file")
                abort()
            }
        }
    }
    
    public func sendData(_ values: [UInt8]){
        self.sendData(values,order:.MSBFIRST,clockDelayUsec:0)
    }
    
    public func isHardware()->Bool{
        return false
    }
    
    public func isOut()->Bool{
        return true
    }
}

public struct SwiftyGPIO {
    
    public static func GPIOs(for board: SupportedBoard) -> [GPIOName: GPIO] {
        switch(board){
        case .RaspberryPiRev1:
            return GPIORPIRev1
        case .RaspberryPiRev2:
            return GPIORPIRev2
        case .RaspberryPiPlusZero:
            return GPIORPIPlusZERO
        case .RaspberryPi2:
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
    
    public static func hardwareSPIs(for board: SupportedBoard) -> [SPIOutput]? {
        switch(board){
        case .RaspberryPiRev1:
            fallthrough
        case .RaspberryPiRev2:
            fallthrough
        case .RaspberryPiPlusZero:
            fallthrough
        case .RaspberryPi2:
            return [SPIRPI[0]!,SPIRPI[1]!]
        case .BananaPi:
            return [SPIBANANAPI[0]!,SPIBANANAPI[1]!]
        default:
            return nil
        }
    }
}


//MARK: - Global Enums

public enum SupportedBoard {
    case RaspberryPiRev1   // Pi A,B Revision 1
    case RaspberryPiRev2   // Pi A,B Revision 2
    case RaspberryPiPlusZero // Pi A+,B+,Zero with 40 pin header
    case RaspberryPi2 // Pi 2 with 40 pin header
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

public enum ByteOrder{
    case MSBFIRST
    case LSBFIRST
}


// MARK: - Darwin / Xcode Support

#if os(OSX)
    private var O_SYNC: CInt { fatalError("Linux only") }
#endif
