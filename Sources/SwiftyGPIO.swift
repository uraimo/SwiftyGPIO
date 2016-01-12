#if arch(arm) && os(Linux)
	import Glibc
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


public struct SwiftyGPIO {
	 
	public static func getGPIOsForBoard(board: SupportedBoard)->[GPIOName:GPIO]{
		switch(board){
			case .RaspberryPiRev1:
				return GPIORPIRev1
			case .RaspberryPiRev2:
				return GPIORPIRev2
			case .RaspberryPiB2Zero:
				return GPIORPIB2ZERO
			case .CHIP:
				return GPIOCHIP
		}
	}

	// RaspberryPiRev1: A,B
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

	// RaspberryPiRev2: A,B
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

 	// RaspberryPi2: B+,2,Zero
	// 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31
	static let GPIORPIB2ZERO:[GPIOName:GPIO] = [
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
}

public enum SupportedBoard {
	case RaspberryPiRev1   // Pi A,B Revision 1
	case RaspberryPiRev2   // Pi A,B Revision 2 
	case RaspberryPiB2Zero // Pi B+,2,Zero with 40 pin header
	case CHIP
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
}
