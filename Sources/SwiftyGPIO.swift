#if arch(arm) && os(Linux)
    import Glibc
#else
    import Darwin
#endif

internal let BASEPATH="/sys/class/gpio/"

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


public class GPIO {
    var name:String=""
    var id:Int=0
    var exported=false

    init(name:String,
        id:Int) {
        self.name=name
        self.id=id
    }

    public var direction:GPIODirection {
        set(dir){
            if !exported {enableIO(id)}
            performSetting("gpio"+String(id)+"/direction",value: dir.rawValue)
        }
        get {
            if !exported {enableIO(id)}
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
}

extension GPIO {

    private func enableIO(id: Int){
        writeToFile(BASEPATH+"export",value:String(id))
        exported = true
    }

    private func performSetting(filename: String, value: String){
        writeToFile(BASEPATH+filename, value:value)
    }

    private func performSetting(filename: String, value: Int){
        writeToFile(BASEPATH+filename, value: String(value))
    }

    private func getStringValue(filename: String)->String?{
        return readFromFile(BASEPATH+filename)
    }

    private func getIntValue(filename: String)->Int?{
        if let res = readFromFile(BASEPATH+filename) {
            return Int(res)
        }
        return nil
    }

    private func writeToFile(path: String, value:String){
        let fp = fopen(path,"w")
        if fp != nil {
            let ret = fwrite(value, strideof(CChar), value.characters.count, fp)
            if ret<value.characters.count {
                if ferror(fp) != 0 {
                    perror("Error while writing to file")
                    abort()
                }
            }
            fclose(fp)
        }
    }

    private func readFromFile(path:String)->String?{
        let MAXLEN = 8

        let fp = fopen(path,"r")
        var res:String?
        if fp != nil {
            let buf = UnsafeMutablePointer<CChar>.alloc(MAXLEN)
            let len = fread(buf, strideof(CChar), MAXLEN, fp)
            if len < MAXLEN {
                if ferror(fp) != 0 {
                    perror("Error while reading from file")
                    abort()
                }
            }
            fclose(fp)
            //Remove the trailing \n
            buf[len-1]=0
            res = String.fromCString(buf)
            buf.dealloc(MAXLEN)
        }
        return res
    }

}

public protocol SPIOutput{                     
    func sendByte(value:UInt8, order:ByteOrder, clockDelayUsec:Int)
    func sendByte(value:UInt8)
    func sendStream(values:[UInt8], order:ByteOrder, clockDelayUsec:Int)
    func sendStream(values:[UInt8])
    func isHardware()->Bool
}

public struct VirtualSPI : SPIOutput{
    let dataGPIO,clockGPIO:GPIO

    init(dataGPIO:GPIO,clockGPIO:GPIO){
        self.dataGPIO = dataGPIO
        self.dataGPIO.direction = .OUT
        self.dataGPIO.value = 0
        self.clockGPIO = clockGPIO
        self.clockGPIO.direction = .OUT
        self.clockGPIO.value = 0
    }


    public func sendStream(values:[UInt8], order:ByteOrder, clockDelayUsec:Int){
        for value in values {        
            for i in 0...7 {
                switch order {
                    case .LSBFIRST:
                        dataGPIO.value = ((value & UInt8(1 << i)) == 0) ? 0 : 1
                    case .MSBFIRST:
                        dataGPIO.value = ((value & UInt8(1 << (7-i))) == 0) ? 0 : 1
                }

                clockGPIO.value = 1
                if clockDelayUsec>0 {
                    usleep(UInt32(clockDelayUsec))
                }
                clockGPIO.value = 0
            }
        }
    }
 
    public func sendStream(values:[UInt8]){
        self.sendStream(values,order:.MSBFIRST,clockDelayUsec:0)
    }

    public func sendByte(value:UInt8, order:ByteOrder, clockDelayUsec:Int){
        sendStream([value],order:order,clockDelayUsec:clockDelayUsec)
    }

    public func sendByte(value:UInt8){
        self.sendByte(value,order:.MSBFIRST,clockDelayUsec:0)
    }
 
    public func isHardware()->Bool{
        return false
    }

    public func isOut()->Bool{
        return true
    }
}


public struct SwiftyGPIO {

    public static func getGPIOsForBoard(board: SupportedBoard)->[GPIOName:GPIO]{
        switch(board){
            case .RaspberryPiRev1:
                return GPIORPIRev1
            case .RaspberryPiRev2:
                return GPIORPIRev2
            case .RaspberryPiPlus2Zero:
                return GPIORPIPlus2ZERO
            case .CHIP:
                return GPIOCHIP
            case .BeagleBoneBlack:
                return GPIOBEAGLEBONE
        }
    }

    public static func getHardwareSPIsForBoard(board: SupportedBoard)->[SPIOutput]?{
        switch(board){
            case .RaspberryPiRev1:
                fallthought
            case .RaspberryPiRev2:
                fallthrough
            case .RaspberryPiPlus2Zero:
                return [SPIRPI[0],SPIRPI[1]]
            default:
                return nil
        }
    }

    // RaspberryPi A and B Revision 1 (Before September 2012) - 26 pin header boards
    // 0, 1, 4, 7, 8, 9, 10, 11, 14, 15, 17, 18, 21, 22, 23, 24, 25
    static let GPIORPIRev1:[GPIOName:GPIO] = [
        .P0:GPIO(name:"GPIO0",id:0),
        .P1:GPIO(name:"GPIO1",id:1),
        .P4:GPIO(name:"GPIO4",id:4),
        .P7:GPIO(name:"GPIO7",id:7),
        .P8:GPIO(name:"GPIO8",id:8),
        .P9:GPIO(name:"GPIO9",id:9),
        .P10:GPIO(name:"GPIO10",id:10),
        .P11:GPIO(name:"GPIO11",id:11),
        .P14:GPIO(name:"GPIO14",id:14),
        .P15:GPIO(name:"GPIO15",id:15),
        .P17:GPIO(name:"GPIO17",id:17),
        .P18:GPIO(name:"GPIO18",id:18),
        .P21:GPIO(name:"GPIO21",id:21),
        .P22:GPIO(name:"GPIO22",id:22),
        .P23:GPIO(name:"GPIO23",id:23),
        .P24:GPIO(name:"GPIO24",id:24),
        .P25:GPIO(name:"GPIO25",id:25)
    ]

    // RaspberryPi A and B Revision 2 (After September 2012) - 26 pin header boards
    //TODO: Additional GPIO from 28-31 ignored for now
    // 2, 3, 4, 7, 8, 9, 10, 11, 14, 15, 17, 18, 22, 23, 24, 25, 27
    static let GPIORPIRev2:[GPIOName:GPIO] = [
        .P2:GPIO(name:"GPIO2",id:2),
        .P3:GPIO(name:"GPIO3",id:3),
        .P4:GPIO(name:"GPIO4",id:4),
        .P7:GPIO(name:"GPIO7",id:7),
        .P8:GPIO(name:"GPIO8",id:8),
        .P9:GPIO(name:"GPIO9",id:9),
        .P10:GPIO(name:"GPIO10",id:10),
        .P11:GPIO(name:"GPIO11",id:11),
        .P14:GPIO(name:"GPIO14",id:14),
        .P15:GPIO(name:"GPIO15",id:15),
        .P17:GPIO(name:"GPIO17",id:17),
        .P18:GPIO(name:"GPIO18",id:18),
        .P22:GPIO(name:"GPIO22",id:22),
        .P23:GPIO(name:"GPIO23",id:23),
        .P24:GPIO(name:"GPIO24",id:24),
        .P25:GPIO(name:"GPIO25",id:25),
        .P27:GPIO(name:"GPIO27",id:27)
    ]

    // RaspberryPi A+ and B+, Raspberry 2, Raspberry Zero - 40 pin header boards
    // 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31
    static let GPIORPIPlus2ZERO:[GPIOName:GPIO] = [
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

    // Raspberries w/raspbian
    static let SPIRPI:[Int:SPIOutput] = [
        0:HardwareSPI(spiId:"0.0",isOut:true),
        1:HardwareSPI(spiId:"0.1",isOut:false)
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
}

public enum SupportedBoard {
    case RaspberryPiRev1   // Pi A,B Revision 1
    case RaspberryPiRev2   // Pi A,B Revision 2 
    case RaspberryPiPlus2Zero // Pi A+,B+,2,Zero with 40 pin header
    case CHIP
    case BeagleBoneBlack
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
