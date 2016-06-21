#if os(Linux)
    import Glibc
#else
    import Darwin.C
#endif

internal let GPIOBASEPATH="/sys/class/gpio/"
internal let SPIBASEPATH="/dev/spidev"


public class GPIO {
    var name:String=""
    var id:Int=0
    var exported=false
    var listening = false
    var intThread: Thread? = nil
    var intFuncFalling:((GPIO)->Void)? = nil
    var intFuncRaising:((GPIO)->Void)? = nil
    var intFuncChange:((GPIO)->Void)? = nil


    public init(name:String,
        id:Int) {
        self.name=name
        self.id=id
    }

    public var direction:GPIODirection {
        set(dir){
            if !exported {enableIO(id)}
            performSetting("gpio" + String(id) + "/direction", value: dir.rawValue)
        }
        get {
            if !exported { enableIO(id)}
            return GPIODirection(rawValue: getStringValue("gpio"+String(id)+"/direction")!)!
        }
    }

    public var edge:GPIOEdge {
        set(dir){
            if !exported {enableIO(id)}
            performSetting("gpio"+String(id)+"/edge",value: dir.rawValue)
        }
        get {
            if !exported {enableIO(id)}
            return GPIOEdge(rawValue: getStringValue("gpio"+String(id)+"/edge")!)!
        }
    }

    public var activeLow:Bool{
        set(act){
            if !exported {enableIO(id)}
            performSetting("gpio"+String(id)+"/active_low",value: act ? "1":"0")
        }
        get {
            if !exported {enableIO(id)}
            return getIntValue("gpio"+String(id)+"/active_low")==0
        }
    }

    public var value:Int{
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

    public func onFalling(_ closure:(GPIO)->Void){
        intFuncFalling = closure
        if intThread == nil {
            intThread = newInterruptThread()
            listening = true
        }
    }

    public func onRaising(_ closure:(GPIO)->Void){
        intFuncRaising = closure
        if intThread == nil {
            intThread = newInterruptThread()
            listening = true
        }
    }

    public func onChange(_ closure:(GPIO)->Void){
        intFuncChange = closure
        if intThread == nil {
            intThread = newInterruptThread()
            listening = true
        }
    }

    public func clearListeners(){
        (intFuncFalling,intFuncRaising,intFuncChange) = (nil,nil,nil)
        listening = false
    }

}

extension GPIO {

    private func enableIO(_ id: Int){
        writeToFile(GPIOBASEPATH+"export",value:String(id))
        exported = true
    }

    private func performSetting(_ filename: String, value: String){
        writeToFile(GPIOBASEPATH+filename, value:value)
    }

    private func performSetting(_ filename: String, value: Int){
        writeToFile(GPIOBASEPATH+filename, value: String(value))
    }

    private func getStringValue(_ filename: String)->String?{
        return readFromFile(GPIOBASEPATH+filename)
    }

    private func getIntValue(_ filename: String)->Int?{
        if let res = readFromFile(GPIOBASEPATH+filename) {
            return Int(res)
        }
        return nil
    }

    private func writeToFile(_ path: String, value:String){
        let fp = fopen(path,"w")
        if fp != nil {
            let ret = fwrite(value, strideof(CChar.self), value.characters.count, fp)
            if ret<value.characters.count {
                if ferror(fp) != 0 {
                    perror("Error while writing to file")
                    abort()
                }
            }
            fclose(fp)
        }
    }

    private func readFromFile(_ path:String) -> String? {
        let MAXLEN = 8

        let fp = fopen(path,"r")
        var res:String?
        if fp != nil {
            let buf = UnsafeMutablePointer<CChar>.init(allocatingCapacity: MAXLEN)
            let len = fread(buf, strideof(CChar.self), MAXLEN, fp)
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
            buf.deallocateCapacity(MAXLEN)
        }
        return res
    }

    private func newInterruptThread() -> Thread {
        
        let thread = try! Thread {

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
    
    var setGetId=0
    var baseAddr:Int=0
    var inited=false

    let BCM2708_PERI_BASE:Int
    let GPIO_BASE:Int
    let PAGE_SIZE = 4*1024
    let BLOCK_SIZE = 4*1024

    var gpioBasePointer:UnsafeMutablePointer<Int>!
    var gpioGetPointer:UnsafeMutablePointer<Int>!
    var gpioSetPointer:UnsafeMutablePointer<Int>!
    var gpioClearPointer:UnsafeMutablePointer<Int>!

    public init(name:String, id:Int, baseAddr:Int) {
        self.setGetId = 1<<id
        self.BCM2708_PERI_BASE = baseAddr
        self.GPIO_BASE = BCM2708_PERI_BASE + 0x200000 /* GPIO controller */
        super.init(name:name,id:id)
    }

    public override var value:Int{
        set(val){
            if !inited {initIO(id)}
            gpioSet(val)
        }
        get {
            if !inited {initIO(id)}
            return gpioGet()
        }
    }

    public override func isMemoryMapped()->Bool{
        return true
    }

    private func initIO(_ id: Int){
        let mem_fd = open("/dev/mem", O_RDWR | O_SYNC)
        guard (mem_fd > 0) else {
            print("Can't open /dev/mem")
            abort()
        }

        let gpio_map = mmap(
            nil,                 //Any adddress in our space will do
            BLOCK_SIZE,          //Map length
            PROT_READ|PROT_WRITE,// Enable reading & writting to mapped memory
            MAP_SHARED,          //Shared with other processes
            mem_fd,              //File to map
            off_t(GPIO_BASE)     //Offset to GPIO peripheral
            )

        close(mem_fd)

        let gpioBasePointer = UnsafeMutablePointer<Int>(gpio_map)!
        if (gpioBasePointer.pointee == -1) {    //MAP_FAILED not available, but its value is (void*)-1
            print("mmap error: " + String(gpioBasePointer))
            abort()
        }
        
        gpioGetPointer = gpioBasePointer.advanced(by: 13)
        gpioSetPointer = gpioBasePointer.advanced(by: 7)
        gpioClearPointer = gpioBasePointer.advanced(by: 10) 

        inited = true
    }
 
    private func gpioAsInput(){
        let ptr = gpioBasePointer.advanced(by: id/10)
        ptr.pointee &= ~(7<<((id%10)*3))
    }

    private func gpioAsOutput(){
        let ptr = gpioBasePointer.advanced(by: id/10)
        ptr.pointee &= ~(7<<((id%10)*3))
        ptr.pointee |=  (1<<((id%10)*3))
    }  
    
    private func gpioGet()->Int{
        return ((gpioGetPointer.pointee & setGetId)>0) ? 1 : 0
    }

    private func gpioSet(_ value:Int){
        let ptr = value==1 ? gpioSetPointer : gpioClearPointer
        ptr!.pointee = setGetId
    } 
 
}
 
// MARK: SPI

public protocol SPIOutput {
    func sendData(_ values:[UInt8], order:ByteOrder, clockDelayUsec:Int)
    func sendData(_ values:[UInt8])
    func isHardware()->Bool
    func isOut()->Bool
}

public struct HardwareSPI : SPIOutput {
    let spiId:String
    let isOutput:Bool

    public init(spiId:String,isOutput:Bool){
        self.spiId=spiId
        self.isOutput=isOutput
        //TODO: Check if available?
    }

    public func sendData(_ values:[UInt8], order:ByteOrder, clockDelayUsec:Int){
        guard isOutput else {return}

        if clockDelayUsec > 0 {
            //TODO: ioctl with new freq
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
 
    private func writeToFile(_ path: String, values:[UInt8]){
        let fp = fopen(path,"w")
        if fp != nil {
            let ret = fwrite(values, strideof(CChar.self), values.count, fp)
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

    public init(dataGPIO:GPIO,clockGPIO:GPIO){
        self.dataGPIO = dataGPIO
        self.dataGPIO.direction = .OUT
        self.dataGPIO.value = 0
        self.clockGPIO = clockGPIO
        self.clockGPIO.direction = .OUT
        self.clockGPIO.value = 0
    }


    public func sendData(_ values:[UInt8], order:ByteOrder, clockDelayUsec:Int){
        let mmapped = dataGPIO.isMemoryMapped()
        if mmapped {
            sendDataGPIOObj(values, order:order, clockDelayUsec:clockDelayUsec)
        }else{
            sendDataSysFS(values, order:order, clockDelayUsec:clockDelayUsec)
        }
    }

    public func sendDataGPIOObj(_ values:[UInt8], order:ByteOrder, clockDelayUsec:Int){

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
 
    public func sendDataSysFS(_ values:[UInt8], order:ByteOrder, clockDelayUsec:Int){

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

    private func writeToFP(_ fp: UnsafeMutablePointer<FILE>, value:String){
       let ret = fwrite(value, strideof(CChar.self), 1, fp)
       if ret<1 {
           if ferror(fp) != 0 {
               perror("Error while writing to file")
               abort()
           }
       }
    }
 
    public func sendData(_ values:[UInt8]){
        self.sendData(values,order:.MSBFIRST,clockDelayUsec:0)
    }

    public func isHardware()->Bool{
        return false
    }

    public func isOut()->Bool{
        return true
    }
}

// MARK: - GPIOs Presets 

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
        }
    }

    public static func hardwareSPIs(for board: SupportedBoard) -> [SPIOutput]? {
        switch(board){
            case .RaspberryPiRev1:
                fallthrough
            case .RaspberryPiRev2:
                fallthrough
            case .RaspberryPiPlusZero:
                return [SPIRPI[0]!,SPIRPI[1]!]
            case .RaspberryPi2:
                return [SPIRPI[0]!,SPIRPI[1]!]
            case .BananaPi:
                return [SPIBANANAPI[0]!,SPIBANANAPI[1]!]
            default:
                return nil
        }
    }


    // RaspberryPi A and B Revision 1 (Before September 2012) - 26 pin header boards
    // 0, 1, 4, 7, 8, 9, 10, 11, 14, 15, 17, 18, 21, 22, 23, 24, 25
    static let GPIORPIRev1:[GPIOName:GPIO] = [
        .P0:RaspiGPIO(name:"GPIO0",id:0,baseAddr:0x20000000),
        .P1:RaspiGPIO(name:"GPIO1",id:1,baseAddr:0x20000000),
        .P4:RaspiGPIO(name:"GPIO4",id:4,baseAddr:0x20000000),
        .P7:RaspiGPIO(name:"GPIO7",id:7,baseAddr:0x20000000),
        .P8:RaspiGPIO(name:"GPIO8",id:8,baseAddr:0x20000000),
        .P9:RaspiGPIO(name:"GPIO9",id:9,baseAddr:0x20000000),
        .P10:RaspiGPIO(name:"GPIO10",id:10,baseAddr:0x20000000),
        .P11:RaspiGPIO(name:"GPIO11",id:11,baseAddr:0x20000000),
        .P14:RaspiGPIO(name:"GPIO14",id:14,baseAddr:0x20000000),
        .P15:RaspiGPIO(name:"GPIO15",id:15,baseAddr:0x20000000),
        .P17:RaspiGPIO(name:"GPIO17",id:17,baseAddr:0x20000000),
        .P18:RaspiGPIO(name:"GPIO18",id:18,baseAddr:0x20000000),
        .P21:RaspiGPIO(name:"GPIO21",id:21,baseAddr:0x20000000),
        .P22:RaspiGPIO(name:"GPIO22",id:22,baseAddr:0x20000000),
        .P23:RaspiGPIO(name:"GPIO23",id:23,baseAddr:0x20000000),
        .P24:RaspiGPIO(name:"GPIO24",id:24,baseAddr:0x20000000),
        .P25:RaspiGPIO(name:"GPIO25",id:25,baseAddr:0x20000000)
    ]

    // RaspberryPi A and B Revision 2 (After September 2012) - 26 pin header boards
    //TODO: Additional GPIO from 28-31 ignored for now
    // 2, 3, 4, 7, 8, 9, 10, 11, 14, 15, 17, 18, 22, 23, 24, 25, 27
    static let GPIORPIRev2:[GPIOName:GPIO] = [
        .P2:RaspiGPIO(name:"GPIO2",id:2,baseAddr:0x20000000),
        .P3:RaspiGPIO(name:"GPIO3",id:3,baseAddr:0x20000000),
        .P4:RaspiGPIO(name:"GPIO4",id:4,baseAddr:0x20000000),
        .P7:RaspiGPIO(name:"GPIO7",id:7,baseAddr:0x20000000),
        .P8:RaspiGPIO(name:"GPIO8",id:8,baseAddr:0x20000000),
        .P9:RaspiGPIO(name:"GPIO9",id:9,baseAddr:0x20000000),
        .P10:RaspiGPIO(name:"GPIO10",id:10,baseAddr:0x20000000),
        .P11:RaspiGPIO(name:"GPIO11",id:11,baseAddr:0x20000000),
        .P14:RaspiGPIO(name:"GPIO14",id:14,baseAddr:0x20000000),
        .P15:RaspiGPIO(name:"GPIO15",id:15,baseAddr:0x20000000),
        .P17:RaspiGPIO(name:"GPIO17",id:17,baseAddr:0x20000000),
        .P18:RaspiGPIO(name:"GPIO18",id:18,baseAddr:0x20000000),
        .P22:RaspiGPIO(name:"GPIO22",id:22,baseAddr:0x20000000),
        .P23:RaspiGPIO(name:"GPIO23",id:23,baseAddr:0x20000000),
        .P24:RaspiGPIO(name:"GPIO24",id:24,baseAddr:0x20000000),
        .P25:RaspiGPIO(name:"GPIO25",id:25,baseAddr:0x20000000),
        .P27:RaspiGPIO(name:"GPIO27",id:27,baseAddr:0x20000000)
    ]

    // RaspberryPi A+ and B+, Raspberry Zero - 40 pin header boards
    // 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31
    static let GPIORPIPlusZERO:[GPIOName:GPIO] = [
        .P2:RaspiGPIO(name:"GPIO2",id:2,baseAddr:0x20000000),
        .P3:RaspiGPIO(name:"GPIO3",id:3,baseAddr:0x20000000),
        .P4:RaspiGPIO(name:"GPIO4",id:4,baseAddr:0x20000000),
        .P5:RaspiGPIO(name:"GPIO5",id:5,baseAddr:0x20000000),
        .P6:RaspiGPIO(name:"GPIO6",id:6,baseAddr:0x20000000),
        .P7:RaspiGPIO(name:"GPIO7",id:7,baseAddr:0x20000000),
        .P8:RaspiGPIO(name:"GPIO8",id:8,baseAddr:0x20000000),
        .P9:RaspiGPIO(name:"GPIO9",id:9,baseAddr:0x20000000),
        .P10:RaspiGPIO(name:"GPIO10",id:10,baseAddr:0x20000000),
        .P11:RaspiGPIO(name:"GPIO11",id:11,baseAddr:0x20000000),
        .P12:RaspiGPIO(name:"GPIO12",id:12,baseAddr:0x20000000),
        .P13:RaspiGPIO(name:"GPIO13",id:13,baseAddr:0x20000000),
        .P14:RaspiGPIO(name:"GPIO14",id:14,baseAddr:0x20000000),
        .P15:RaspiGPIO(name:"GPIO15",id:15,baseAddr:0x20000000),
        .P16:RaspiGPIO(name:"GPIO16",id:16,baseAddr:0x20000000),
        .P17:RaspiGPIO(name:"GPIO17",id:17,baseAddr:0x20000000),
        .P18:RaspiGPIO(name:"GPIO18",id:18,baseAddr:0x20000000),
        .P19:RaspiGPIO(name:"GPIO19",id:19,baseAddr:0x20000000),
        .P20:RaspiGPIO(name:"GPIO20",id:20,baseAddr:0x20000000),
        .P21:RaspiGPIO(name:"GPIO21",id:21,baseAddr:0x20000000),
        .P22:RaspiGPIO(name:"GPIO22",id:22,baseAddr:0x20000000),
        .P23:RaspiGPIO(name:"GPIO23",id:23,baseAddr:0x20000000),
        .P24:RaspiGPIO(name:"GPIO24",id:24,baseAddr:0x20000000),
        .P25:RaspiGPIO(name:"GPIO25",id:25,baseAddr:0x20000000),
        .P26:RaspiGPIO(name:"GPIO26",id:26,baseAddr:0x20000000),
        .P27:RaspiGPIO(name:"GPIO27",id:27,baseAddr:0x20000000)
    ]
 
    // RaspberryPi 2
    // 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31
    static let GPIORPI2:[GPIOName:GPIO] = [
        .P2:RaspiGPIO(name:"GPIO2",id:2,baseAddr:0x3F000000),
        .P3:RaspiGPIO(name:"GPIO3",id:3,baseAddr:0x3F000000),
        .P4:RaspiGPIO(name:"GPIO4",id:4,baseAddr:0x3F000000),
        .P5:RaspiGPIO(name:"GPIO5",id:5,baseAddr:0x3F000000),
        .P6:RaspiGPIO(name:"GPIO6",id:6,baseAddr:0x3F000000),
        .P7:RaspiGPIO(name:"GPIO7",id:7,baseAddr:0x3F000000),
        .P8:RaspiGPIO(name:"GPIO8",id:8,baseAddr:0x3F000000),
        .P9:RaspiGPIO(name:"GPIO9",id:9,baseAddr:0x3F000000),
        .P10:RaspiGPIO(name:"GPIO10",id:10,baseAddr:0x3F000000),
        .P11:RaspiGPIO(name:"GPIO11",id:11,baseAddr:0x3F000000),
        .P12:RaspiGPIO(name:"GPIO12",id:12,baseAddr:0x3F000000),
        .P13:RaspiGPIO(name:"GPIO13",id:13,baseAddr:0x3F000000),
        .P14:RaspiGPIO(name:"GPIO14",id:14,baseAddr:0x3F000000),
        .P15:RaspiGPIO(name:"GPIO15",id:15,baseAddr:0x3F000000),
        .P16:RaspiGPIO(name:"GPIO16",id:16,baseAddr:0x3F000000),
        .P17:RaspiGPIO(name:"GPIO17",id:17,baseAddr:0x3F000000),
        .P18:RaspiGPIO(name:"GPIO18",id:18,baseAddr:0x3F000000),
        .P19:RaspiGPIO(name:"GPIO19",id:19,baseAddr:0x3F000000),
        .P20:RaspiGPIO(name:"GPIO20",id:20,baseAddr:0x3F000000),
        .P21:RaspiGPIO(name:"GPIO21",id:21,baseAddr:0x3F000000),
        .P22:RaspiGPIO(name:"GPIO22",id:22,baseAddr:0x3F000000),
        .P23:RaspiGPIO(name:"GPIO23",id:23,baseAddr:0x3F000000),
        .P24:RaspiGPIO(name:"GPIO24",id:24,baseAddr:0x3F000000),
        .P25:RaspiGPIO(name:"GPIO25",id:25,baseAddr:0x3F000000),
        .P26:RaspiGPIO(name:"GPIO26",id:26,baseAddr:0x3F000000),
        .P27:RaspiGPIO(name:"GPIO27",id:27,baseAddr:0x3F000000)
    ]
 
    // Raspberries w/raspbian
    static let SPIRPI:[Int:SPIOutput] = [
        0:HardwareSPI(spiId:"0.0",isOutput:true),
        1:HardwareSPI(spiId:"0.1",isOutput:false)
    ]

    // CHIP
    // 408, 409, 410, 411, 412, 413, 414, 415, +undocumented LCD GPIOs
    static let GPIOCHIP:[GPIOName:GPIO] = [
        .P0:GPIO(name:"XIO-P0",id:408),
        .P1:GPIO(name:"XIO-P1",id:409),
        .P2:GPIO(name:"XIO-P2",id:410),
        .P3:GPIO(name:"XIO-P3",id:411),
        .P4:GPIO(name:"XIO-P4",id:412),
        .P5:GPIO(name:"XIO-P5",id:413),
        .P6:GPIO(name:"XIO-P6",id:414),
        .P7:GPIO(name:"XIO-P7",id:415)
    ]

    //BeagleBoneBlack
    //
    //The gpio id is the sum of the related gpio controller base number
    //and the progressive id of the gpio within its group...
    //The key of the map is assigned sequentially following the orders of
    //the pins, and i realize it could not be that useful(likely to change
    //in the future in favor of a better alternative).
    //
    //Only the pins described as gpio in the official documentation are 
    //included here: https://github.com/CircuitCo/BeagleBone-Black/blob/master/BBB_SRM.pdf?raw=true
    //Clearly this does not support mode change.
    //
    static let GPIOBEAGLEBONE:[GPIOName:GPIO] = [
        .P0:GPIO(name:"P8_PIN03_GPIO1_6",id:38),  //P8
        .P1:GPIO(name:"P8_PIN04_GPIO1_7",id:39),
        .P2:GPIO(name:"P8_PIN05_GPIO1_2",id:34),
        .P3:GPIO(name:"P8_PIN06_GPIO1_3",id:35),
        .P4:GPIO(name:"P8_PIN11_GPIO1_13",id:45),
        .P5:GPIO(name:"P8_PIN12_GPIO1_12",id:44),
        .P6:GPIO(name:"P8_PIN14_GPIO0_26",id:26),
        .P7:GPIO(name:"P8_PIN15_GPIO1_15",id:47),
        .P8:GPIO(name:"P8_PIN16_GPIO1_14",id:46),
        .P9:GPIO(name:"P8_PIN17_GPIO0_27",id:27),
        .P10:GPIO(name:"P8_PIN18_GPIO2_1",id:65),
        .P11:GPIO(name:"P8_PIN20_GPIO1_31",id:63),
        .P12:GPIO(name:"P8_PIN21_GPIO1_30",id:62),
        .P13:GPIO(name:"P8_PIN22_GPIO1_5",id:37),
        .P14:GPIO(name:"P8_PIN23_GPIO1_4",id:36),
        .P15:GPIO(name:"P8_PIN24_GPIO1_1",id:33),
        .P16:GPIO(name:"P8_PIN25_GPIO1_0",id:32),
        .P17:GPIO(name:"P8_PIN26_GPIO1_29",id:61),
        .P18:GPIO(name:"P8_PIN27_GPIO2_22",id:86),
        .P19:GPIO(name:"P8_PIN28_GPIO2_24",id:88),
        .P20:GPIO(name:"P8_PIN29_GPIO2_23",id:87),
        .P21:GPIO(name:"P8_PIN30_GPIO2_25",id:89),
        .P22:GPIO(name:"P8_PIN39_GPIO2_12",id:76),
        .P23:GPIO(name:"P8_PIN40_GPIO2_13",id:77),
        .P24:GPIO(name:"P8_PIN41_GPIO2_10",id:74),
        .P25:GPIO(name:"P8_PIN42_GPIO2_11",id:75),
        .P26:GPIO(name:"P8_PIN43_GPIO2_8",id:72),
        .P27:GPIO(name:"P8_PIN44_GPIO2_9",id:73),
        .P28:GPIO(name:"P8_PIN45_GPIO2_6",id:70),
        .P29:GPIO(name:"P8_PIN46_GPIO2_7",id:71),
        .P30:GPIO(name:"P9_PIN12_GPIO1_28",id:60),   //P9
        .P31:GPIO(name:"P9_PIN15_GPIO1_16",id:48),
        .P32:GPIO(name:"P9_PIN23_GPIO1_17",id:49),   //Ignore Pin25, requires oscillator disabled
        .P33:GPIO(name:"P9_PIN27_GPIO3_19",id:125)
    ]
    
    // BananaPi
    // CON3 Header GPIOs
    // Same header of 40pins Raspberries, not compatible with LeMaker Guitar board
    static let GPIOBANANAPI:[GPIOName:GPIO] = [
        .P2:GPIO(name:"GPIO2",id:2),
        .P3:GPIO(name:"GPIO3",id:3),
        .P4:GPIO(name:"GPIO4",id:4),
        .P5:GPIO(name:"GPIO5",id:5),
        .P6:GPIO(name:"GPIO6",id:6),
        .P7:GPIO(name:"GPIO7",id:7),
        .P8:GPIO(name:"GPIO8",id:8),
        .P9:GPIO(name:"GPIO9",id:9),
        .P10:GPIO(name:"GPIO10",id:10),
        .P11:GPIO(name:"GPIO11",id:11),
        .P12:GPIO(name:"GPIO12",id:12),
        .P13:GPIO(name:"GPIO13",id:13),
        .P14:GPIO(name:"GPIO14",id:14),
        .P15:GPIO(name:"GPIO15",id:15),
        .P16:GPIO(name:"GPIO16",id:16),
        .P17:GPIO(name:"GPIO17",id:17),
        .P18:GPIO(name:"GPIO18",id:18),
        .P19:GPIO(name:"GPIO19",id:19),
        .P20:GPIO(name:"GPIO20",id:20),
        .P21:GPIO(name:"GPIO21",id:21),
        .P22:GPIO(name:"GPIO22",id:22),
        .P23:GPIO(name:"GPIO23",id:23),
        .P24:GPIO(name:"GPIO24",id:24),
        .P25:GPIO(name:"GPIO25",id:25),
        .P26:GPIO(name:"GPIO26",id:26),
        .P27:GPIO(name:"GPIO27",id:27)
    ]
    
    // BananaPi
    static let SPIBANANAPI:[Int:SPIOutput] = [
        0:HardwareSPI(spiId:"0.0",isOutput:true),
        1:HardwareSPI(spiId:"0.1",isOutput:false)
    ]

    // OrangePi
    // The pins are ordered by name: A0-A21(P0-P16), C0-C7(P17-P22), D14(P23), G6-G9(P24-P27) 
    static let GPIOORANGEPI:[GPIOName:GPIO] = [
        .P0:GPIO(sunXi:SunXiGPIO(letter: .A,pin:0)),
        .P1:GPIO(sunXi:SunXiGPIO(letter:.A,pin:1)),
        .P2:GPIO(sunXi:SunXiGPIO(letter:.A,pin:2)),
        .P3:GPIO(sunXi:SunXiGPIO(letter:.A,pin:3)),
        .P4:GPIO(sunXi:SunXiGPIO(letter:.A,pin:6)),
        .P5:GPIO(sunXi:SunXiGPIO(letter:.A,pin:7)),
        .P6:GPIO(sunXi:SunXiGPIO(letter:.A,pin:8)),
        .P7:GPIO(sunXi:SunXiGPIO(letter:.A,pin:9)),
        .P8:GPIO(sunXi:SunXiGPIO(letter:.A,pin:10)),
        .P9:GPIO(sunXi:SunXiGPIO(letter:.A,pin:11)),
        .P10:GPIO(sunXi:SunXiGPIO(letter:.A,pin:12)),
        .P11:GPIO(sunXi:SunXiGPIO(letter:.A,pin:13)),
        .P12:GPIO(sunXi:SunXiGPIO(letter:.A,pin:14)),
        .P13:GPIO(sunXi:SunXiGPIO(letter:.A,pin:18)),
        .P14:GPIO(sunXi:SunXiGPIO(letter:.A,pin:19)),
        .P15:GPIO(sunXi:SunXiGPIO(letter:.A,pin:20)),
        .P16:GPIO(sunXi:SunXiGPIO(letter:.A,pin:21)),
        .P17:GPIO(sunXi:SunXiGPIO(letter:.C,pin:0)),
        .P18:GPIO(sunXi:SunXiGPIO(letter:.C,pin:1)),
        .P19:GPIO(sunXi:SunXiGPIO(letter:.C,pin:2)),
        .P20:GPIO(sunXi:SunXiGPIO(letter:.C,pin:3)),
        .P21:GPIO(sunXi:SunXiGPIO(letter:.C,pin:4)),
        .P22:GPIO(sunXi:SunXiGPIO(letter:.C,pin:7)),
        .P23:GPIO(sunXi:SunXiGPIO(letter:.D,pin:14)),
        .P24:GPIO(sunXi:SunXiGPIO(letter:.G,pin:6)),
        .P25:GPIO(sunXi:SunXiGPIO(letter:.G,pin:7)),
        .P26:GPIO(sunXi:SunXiGPIO(letter:.G,pin:8)),
        .P27:GPIO(sunXi:SunXiGPIO(letter:.G,pin:9))
    ]
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

public enum GPIODirection:String {
    case IN="in"
    case OUT="out"
}

public enum GPIOEdge:String {
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
