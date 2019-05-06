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

/// Bit-banging virtual SPI implementation, output only
public final class RaspberryVirtualSPI: SPIInterface {
    let mosiGPIO, misoGPIO, clockGPIO, csGPIO: GPIO
    
    public init(mosiGPIO: GPIO, misoGPIO: GPIO, clockGPIO: GPIO, csGPIO: GPIO) {
        self.mosiGPIO = mosiGPIO
        self.mosiGPIO.direction = .output
        self.mosiGPIO.value = false
        self.misoGPIO = misoGPIO
        self.misoGPIO.direction = .output
        self.clockGPIO = clockGPIO
        self.clockGPIO.direction = .output
        self.clockGPIO.value = false
        self.csGPIO = csGPIO
        self.csGPIO.direction = .output
        self.csGPIO.value = true
    }
    
    public var isHardware =  true
    
    public func sendData(_ values: [UInt8], frequencyHz: UInt = 500000) throws {
        sendDataGPIOObj(values, frequencyHz: frequencyHz, read: false)
    }
    
    public func sendData(_ values: [UInt8]) throws {
        try sendData(values, frequencyHz: 0)
    }
    
    public func sendDataAndRead(_ values: [UInt8], frequencyHz: UInt = 500000) throws -> [UInt8] {
        var rx = [UInt8]()
        
        rx = sendDataGPIOObj(values, frequencyHz: frequencyHz, read: true)
        return rx
    }
    
    public func sendDataAndRead(_ values: [UInt8]) throws -> [UInt8] {
        return try sendDataAndRead(values, frequencyHz: 0)
    }
    
    @discardableResult
    private func sendDataGPIOObj(_ values: [UInt8], frequencyHz: UInt, read: Bool) -> [UInt8] {
        var rx: [UInt8] = [UInt8]()
        
        var bit: UInt8 = 0
        var rbit: UInt8 = 0
        
        //Begin transmission cs=LOW
        csGPIO.value = false
        
        for value in values {
            rbit = 0
            
            for i in 0...7 {
                bit = ((value & UInt8(1 << (7-i))) == 0) ? 0 : 1
                
                mosiGPIO.value = bit.toBool()
                clockGPIO.value = true
                if frequencyHz > 0 {
                    let amount = UInt32(1_000_000/Double(frequencyHz))
                    // Calling usleep introduces significant delay, don't sleep for small values
                    if amount > 50 {
                        usleep(amount)
                    }
                }
                clockGPIO.value = false
                if read {
                    rbit |= ( misoGPIO.value.toUInt8() << (7-UInt8(i)) )
                }
            }
            if read {
                rx.append(rbit)
            }
        }
        
        //End transmission cs=HIGH
        csGPIO.value = true
        return rx
    }
    
}


extension UInt8{
    fileprivate func toBool() -> Bool {
        return self != 0
    }
}

extension Bool{
    fileprivate func toUInt8() -> UInt8 {
        return self ? UInt8(1) : UInt8(0)
    }
}
