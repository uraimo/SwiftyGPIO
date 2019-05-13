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
import Foundation

/// Memory mapped GPIOs
public final class RaspberryGPIO: SysFSGPIO {
    
    var setGetId: UInt32 = 0
    var inited = false
    
    var BCM2708_PERI_BASE: Int = 0
    var GPIO_BASE: Int = 0
    
    var gpioBasePointer: UnsafeMutablePointer<UInt32>!
    var gpioGetPointer: UnsafeMutablePointer<UInt32>!
    var gpioSetPointer: UnsafeMutablePointer<UInt32>!
    var gpioClearPointer: UnsafeMutablePointer<UInt32>!
    
    public override init(id: Int) {
        self.setGetId = UInt32(1<<id)
        super.init(id: id)
    }
    
    public override var value: Bool {
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
            if dir == .input {
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
    
    public override var pull: GPIOPull {
        set(pull) {
            if !inited {initIO()}
            setGpioPull(pull)
        }
        get{
            fatalError("Parameter cannot be read.")
        }
    }
    
    public override func isMemoryMapped() -> Bool {
        return true
    }

    public override func enable() throws {
        var mem_fd: Int32 = 0
        
        self.BCM2708_PERI_BASE = getbaseAddr()
        self.GPIO_BASE = BCM2708_PERI_BASE + 0x200000 /* GPIO controller */
        
        //Try to open one of the mem devices
        for device in ["/dev/gpiomem", "/dev/mem"] {
            mem_fd=open(device, O_RDWR | O_SYNC)
            if mem_fd>0 {
                break
            }
        }
        guard mem_fd > 0 else {
            throw GPIOError.deviceError("Can't open /dev/mem , use sudo!")
        }
        
        let gpio_map = mmap(
            nil,                 //Any adddress in our space will do
            PAGE_SIZE,          //Map length
            PROT_READ|PROT_WRITE, // Enable reading & writting to mapped memory
            MAP_SHARED,          //Shared with other processes
            mem_fd,              //File to map
            off_t(GPIO_BASE)     //Offset to GPIO peripheral, i.e. GPFSEL0
            )!
        
        close(mem_fd)
        
        if (Int(bitPattern: gpio_map) == -1) {    //MAP_FAILED not available, but its value is (void*)-1
            throw GPIOError.deviceError("Can't open /dev/mem, mmap error")
        }
    }
    
    private func initIO() {
        var mem_fd: Int32 = 0
        
        self.BCM2708_PERI_BASE = getbaseAddr()
        self.GPIO_BASE = BCM2708_PERI_BASE + 0x200000 /* GPIO controller */
        
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
            PROT_READ|PROT_WRITE, // Enable reading & writting to mapped memory
            MAP_SHARED,          //Shared with other processes
            mem_fd,              //File to map
            off_t(GPIO_BASE)     //Offset to GPIO peripheral, i.e. GPFSEL0
            )!
        
        close(mem_fd)
        
        if (Int(bitPattern: gpio_map) == -1) {    //MAP_FAILED not available, but its value is (void*)-1
            perror("mmap error")
            abort()
        }
        
        gpioBasePointer = gpio_map.assumingMemoryBound(to: UInt32.self)
        
        gpioGetPointer = gpioBasePointer.advanced(by: 13)   // GPLEV0
        gpioSetPointer = gpioBasePointer.advanced(by: 7)    // GPSET0
        gpioClearPointer = gpioBasePointer.advanced(by: 10) // GPCLR0
        
        inited = true
    }
    
    private func gpioAsInput() {
        let ptr = gpioBasePointer.advanced(by: id/10)       // GPFSELn 0..5
        ptr.pointee &= ~(7<<((UInt32(id)%10)*3))                    // SEL=000 input
    }
    
    private func gpioAsOutput() {
        let ptr = gpioBasePointer.advanced(by: id/10)       // GPFSELn 0..5
        ptr.pointee &= ~(7<<((UInt32(id)%10)*3))
        ptr.pointee |=  (1<<((UInt32(id)%10)*3))                    // SEL=001 output
    }
    
    private func gpioGetDirection() -> GPIODirection {
        let ptr = gpioBasePointer.advanced(by: id/10)       // GPFSELn 0..5
        let d = (ptr.pointee & (7<<((UInt32(id)%10)*3)))
        return (d == 0) ? .input : .output
    }
    
    func setGpioPull(_ value: GPIOPull){
        let gpioGPPUDPointer = gpioBasePointer.advanced(by: 37)
        gpioGPPUDPointer.pointee = value.rawValue   // Configure GPPUD
        usleep(10);                                 // 150 cycles or more
        let gpioGPPUDCLK0Pointer = gpioBasePointer.advanced(by: 38)
        gpioGPPUDCLK0Pointer.pointee = setGetId     // Configure GPPUDCLK0 for specific gpio (Ids always lower than 31, no GPPUDCLK1 needed)
        usleep(10);                                 // 150 cycles or more
        gpioGPPUDPointer.pointee = 0                // Reset GPPUD
        usleep(10);                                 // 150 cycles or more
        gpioGPPUDCLK0Pointer.pointee = 0            // Reset GPPUDCLK0/1 for specific gpio
        usleep(10);                                 // 150 cycles or more
    }
    
    private func gpioGet() -> Bool {
        return ((gpioGetPointer.pointee & setGetId)>0) ? true : false
    }
    
    private func gpioSet(_ value: Bool) {
        let ptr = value ? gpioSetPointer : gpioClearPointer
        ptr!.pointee = setGetId
    }
    
    private func getbaseAddr()->Int{
        switch(Architecture.shared.getCurrent()){
        case "armv6l":
            return 0x20000000
        case "armv7l":
            return 0x3F000000
        case "aarch64":
            return 0x3F000000
        default:
            fatalError("Unknown RaspberryPi architecture.")
        }
    }
    
    class Architecture {
        private var current: String = ""
        public static let shared = Architecture()
        
        private init() { }
        
        public func getCurrent() -> String {
            guard current.isEmpty else {return current}
            
            var name = utsname()
            guard uname(&name)==0 else { fatalError("Couldn't retrieve the current system information.") }
            
            let archstr = withUnsafeBytes(of: &name.machine, { (p) -> String in
                let charPtr = p.baseAddress!.assumingMemoryBound(to: CChar.self)
                return String(cString: charPtr).lowercased()
            })
            current=archstr
            return current
        }
    }
}


// MARK: - Darwin / Xcode Support
#if os(OSX) || os(iOS)
private var O_SYNC: CInt { fatalError("Linux only") }
#endif
