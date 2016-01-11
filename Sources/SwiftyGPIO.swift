#if arch(arm) && os(Linux)
	import Glibc
#endif
 

internal let BASEPATH="/sys/class/gpio/"

enum GPIODirection:String {
   case IN="in"
   case OUT="out"
}

enum GPIOEdge:String {
   case NONE="none"
   case RISING="rising"
   case FALLING="falling"
   case BOTH="both"
}

struct GPIO {
    var name:String=""
    var id:Int=0
    
    init(name:String,
        id:Int) {
            self.name=name
            self.id=id
            enableIO(id)
    }
    
    var direction:GPIODirection {
        set(dir){
           performSetting("gpio"+String(id)+"/direction",value: dir.rawValue)
        }
        get {
           return GPIODirection(rawValue: getStringValue("gpio"+String(id)+"/direction")!)!
        }
    }
        
    var edge:GPIOEdge {
        set(dir){
            performSetting("gpio"+String(id)+"/edge",value: dir.rawValue)
        }
        get {
            return GPIOEdge(rawValue: getStringValue("gpio"+String(id)+"/edge")!)!
        }
    }
    
    var activeLow:Bool{
        set(act){
            performSetting("gpio"+String(id)+"/active_low",value: act ? "1":"0")
        }
        get {
            return getIntValue("gpio"+String(id)+"/active_low")==0
        }
    }
    
    var value:Int{
        set(val){
            performSetting("gpio"+String(id)+"/value",value: val)
        }
        get {
            return getIntValue("gpio"+String(id)+"/value")!
        }
    }
}

extension GPIO {
    
    private func enableIO(id: Int){
        writeToFile(BASEPATH+"/export",value:String(id))
    }
    
    private func performSetting(filename: String, value: String){
        writeToFile(BASEPATH+"/"+filename, value:value)
    }
    
    private func performSetting(filename: String, value: Int){
        writeToFile(BASEPATH+"/"+filename, value: String(value))
    }
    
    private func getStringValue(filename: String)->String?{
        return readFromFile(BASEPATH+"/"+filename)
    }
    
    private func getIntValue(filename: String)->Int?{
        if let res = readFromFile(BASEPATH+"/"+filename) {
            return Int(res)
        }
        return nil
    }
    
    
    private func writeToFile(path: String, value:String){
        let fp = fopen(path,"w")
        if fp != nil {
            fwrite(value, strideof(CChar), value.characters.count, fp)
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
            fclose(fp)
		    //Remove the trailing \n
            buf[len-1]=0
            res = String.fromCString(buf)
            buf.dealloc(MAXLEN)
        }
        return res
    }
        
}


