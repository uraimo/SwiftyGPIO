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


/// GPIOs via Linux SysFS
public class SysFSGPIO : GPIOInterface {
    public var bounceTime: TimeInterval?
    
    public private(set) var name: String = ""
    public private(set) var id: Int = 0
    var exported = false
    var listening = false
    var intThread: Thread?
    var intFalling: (func: ((GPIOInterface) -> Void), lastCall: Date?)?
    var intRaising: (func: ((GPIOInterface) -> Void), lastCall: Date?)?
    var intChange: (func: ((GPIOInterface) -> Void), lastCall: Date?)?
    
    public init(name: String,
                id: Int) {
        self.name = name
        self.id = id
    }
    
    public init(id: Int) {
        self.name = "GPIO\(id)"
        self.id = id
    }
    
    public var direction: GPIODirection {
        set(dir) {
            if !exported {enableIO(id)}
            try! performSetting("gpio" + String(id) + "/direction", value: dir.rawValue)
        }
        get {
            if !exported { enableIO(id)}
            return GPIODirection(rawValue: try! getStringValue("gpio"+String(id)+"/direction")!)!
        }
    }
    
    public var edge: GPIOEdge {
        set(dir) {
            if !exported {enableIO(id)}
            try! performSetting("gpio"+String(id)+"/edge", value: dir.rawValue)
        }
        get {
            if !exported {enableIO(id)}
            return GPIOEdge(rawValue: try! getStringValue("gpio"+String(id)+"/edge")!)!
        }
    }
    
    public var activeLow: Bool {
        set(act) {
            if !exported {enableIO(id)}
            try! performSetting("gpio"+String(id)+"/active_low", value: act)
        }
        get {
            if !exported {enableIO(id)}
            return try! getBoolValue("gpio"+String(id)+"/active_low")!
        }
    }
    
    public var pull: GPIOPull {
        set(dir) {
            fatalError("Unsupported parameter.")
        }
        get{
            fatalError("Parameter cannot be read.")
        }
    }
    
    public var value: Bool {
        set(val) {
            if !exported {enableIO(id)}
            try! performSetting("gpio"+String(id)+"/value", value: val)
        }
        get {
            if !exported {enableIO(id)}
            return try! getBoolValue("gpio"+String(id)+"/value")!
        }
    }
    
    public func isMemoryMapped() -> Bool {
        return false
    }
    
    public func enable() throws {
        try writeToFile(GPIOBASEPATH+"export", value:String(id))
        _ = try getStringValue("gpio"+String(id)+"/direction")
        _ = try getStringValue("gpio"+String(id)+"/edge")
        _ = try getBoolValue("gpio"+String(id)+"/active_low")
        _ = try getBoolValue("gpio"+String(id)+"/value")
        exported = true
    }
    
    func enableIO(_ id: Int) {
        guard !exported else {return}
        
        try! writeToFile(GPIOBASEPATH+"export", value:String(id))
        exported = true
    }
    
    public func onFalling(_ closure: @escaping (GPIOInterface) -> Void) {
        intFalling = (func: closure, lastCall: nil)
        if intThread == nil {
            if !exported {enableIO(id)}
            intThread = makeInterruptThread()
            listening = true
            intThread?.start()
        }
    }
    
    public func onRaising(_ closure: @escaping (GPIOInterface) -> Void) {
        intRaising = (func: closure, lastCall: nil)
        if intThread == nil {
            if !exported {enableIO(id)}
            intThread = makeInterruptThread()
            listening = true
            intThread?.start()
        }
    }
    
    public func onChange(_ closure: @escaping (GPIOInterface) -> Void) {
        intChange = (func: closure, lastCall: nil)
        if intThread == nil {
            if !exported {enableIO(id)}
            intThread = makeInterruptThread()
            listening = true
            intThread?.start()
        }
    }
    
    public func clearListeners() {
        (intFalling, intRaising, intChange) = (nil, nil, nil)
        listening = false
    }
    
}


fileprivate extension SysFSGPIO {
    
    func performSetting(_ filename: String, value: Bool) throws {
        try writeToFile(GPIOBASEPATH+filename, value: String(value ? 1 : 0))
    }
    
    func getBoolValue(_ filename: String) throws -> Bool? {
        if let res = try readFromFile(GPIOBASEPATH+filename) {
            return Int(res)==1
        }
        return nil
    }
    
    func performSetting(_ filename: String, value: String) throws {
        try writeToFile(GPIOBASEPATH+filename, value:value)
    }
    
    func getStringValue(_ filename: String) throws -> String? {
        return try readFromFile(GPIOBASEPATH+filename)
    }
    
    func writeToFile(_ path: String, value: String) throws {
        let fp = fopen(path, "w")
        if fp != nil {
            let len = value.count
            let ret = fwrite(value, MemoryLayout<CChar>.stride, len, fp)
            if ret<len {
                if ferror(fp) != 0 {
                    throw GPIOError.IOError("Error while writing to file")
                }
            }
            fclose(fp)
        }
    }
    
    func readFromFile(_ path: String) throws -> String? {
        let MAXLEN = 8
        
        let fp = fopen(path, "r")
        var res: String?
        if fp != nil {
            let buf = UnsafeMutablePointer<CChar>.allocate(capacity: MAXLEN)
            let len = fread(buf, MemoryLayout<CChar>.stride, MAXLEN, fp)
            if len < MAXLEN {
                if ferror(fp) != 0 {
                    throw GPIOError.IOError("Error while reading from file")
                }
            }
            fclose(fp)
            //Remove the trailing \n
            buf[len-1]=0
            res = String.init(validatingUTF8: buf)
            #if swift(>=4.1)
            buf.deallocate()
            #else
            buf.deallocate(capacity: MAXLEN)
            #endif
        }
        return res
    }
    
    func makeInterruptThread() -> Thread? {
        //Ignored by Linux
        guard #available(iOS 10.0, macOS 10.12, *) else {return nil}
        
        usleep(100000) //100ms sleep: Workaround for poll blocking forever the first time we poll a gpio after the initial export

        let thread = Thread {
            
            let gpath = GPIOBASEPATH+"gpio"+String(self.id)+"/value"
            self.direction = .input
            self.edge = .both
            
            let fp = open(gpath, O_RDWR)
            var buf: [Int8] = [0, 0, 0]
            read(fp, &buf, 3)  //Dummy read to discard current value
            
            var pfd = pollfd(fd:fp, events:Int16(truncatingIfNeeded:POLLPRI), revents:0)
            
            while self.listening {
                let ready = poll(&pfd, 1, -1)
                if ready > -1 {
                    lseek(fp, 0, SEEK_SET)
                    read(fp, &buf, 2)
                    buf[1]=0
                    
                    let res = String(validatingUTF8: buf)!
                    switch res {
                    case "0":
                        self.interrupt(type: &(self.intFalling))
                    case "1":
                        self.interrupt(type: &(self.intRaising))
                    default:
                        break
                    }
                    self.interrupt(type: &(self.intChange))
                }
            }
        }
        return thread
    }
    
    func interrupt(type: inout (func: ((GPIOInterface) -> Void), lastCall: Date?)?) {
        guard let itype = type else {
            return
        }
        if let interval = self.bounceTime, let lastCall = itype.lastCall, Date().timeIntervalSince(lastCall) < interval {
            return
        }
        itype.func(self)
        type?.lastCall = Date()
    }
}

extension SysFSGPIO: CustomStringConvertible {
    public var description: String {
        return "\(name)<\(id)> with direction:<\(direction), edge:\(edge), active:\(activeLow)>: \(value)"
    }
}

// MARK: - Constants

internal let GPIOBASEPATH="/sys/class/gpio/"
let PAGE_SIZE = (1 << 12)

// MARK: - Darwin / Xcode Support
#if os(OSX) || os(iOS)
private var O_SYNC: CInt { fatalError("Linux only") }
#endif
