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

extension SwiftyGPIO {

    public static func hardwareSPIs(for board: SupportedBoard) -> [SPIOutput]? {
        switch board {
        case .RaspberryPiRev1:
            fallthrough
        case .RaspberryPiRev2:
            fallthrough
        case .RaspberryPiPlusZero:
            fallthrough
        case .RaspberryPi2:
            return [SPIRPI[0]!, SPIRPI[1]!]
        case .BananaPi:
            return [SPIBANANAPI[0]!, SPIBANANAPI[1]!]
        default:
            return nil
        }
    }
}

// MARK: - SPI Presets
extension SwiftyGPIO {
    // RaspberryPis SPIs
    static let SPIRPI: [Int:SPIOutput] = [
        0: HardwareSPI(spiId:"0.0", isOutput:true),
        1: HardwareSPI(spiId:"0.1", isOutput:false)
    ]

    // BananaPi
    static let SPIBANANAPI: [Int:SPIOutput] = [
        0: HardwareSPI(spiId:"0.0", isOutput:true),
        1: HardwareSPI(spiId:"0.1", isOutput:false)
    ]
}

// MARK: SPI

public protocol SPIOutput {
    func sendData(_ values: [UInt8], order: ByteOrder, clockDelayUsec: Int)
    func sendData(_ values: [UInt8])
    func isHardware() -> Bool
    func isOut() -> Bool
}

public struct HardwareSPI: SPIOutput {
    let spiId: String
    let isOutput: Bool

    public init(spiId: String, isOutput: Bool) {
        self.spiId=spiId
        self.isOutput=isOutput
        //TODO: Check if available?
    }

    public func sendData(_ values: [UInt8], order: ByteOrder, clockDelayUsec: Int) {
        guard isOutput else {return}

        if clockDelayUsec > 0 {
            //Try setting new frequency in Hz
            var frq: CInt = CInt(1_000_000 / Double(clockDelayUsec))
            let fp = open(SPIBASEPATH+spiId, O_WRONLY | O_SYNC)
            _ = ioctl(fp, SPI_IOC_WR_MAX_SPEED_HZ, &frq)
        }

        writeToFile(SPIBASEPATH+spiId, values:values)
    }

    public func sendData(_ values: [UInt8]) {sendData(values, order:.MSBFIRST, clockDelayUsec:0)}

    public func isHardware() -> Bool {
        return true
    }

    public func isOut() -> Bool {
        return isOutput
    }

    private func writeToFile(_ path: String, values: [UInt8]) {
        let fp = fopen(path, "w")
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

public struct VirtualSPI: SPIOutput {
    let dataGPIO, clockGPIO: GPIO

    public init(dataGPIO: GPIO, clockGPIO: GPIO) {
        self.dataGPIO = dataGPIO
        self.dataGPIO.direction = .OUT
        self.dataGPIO.value = 0
        self.clockGPIO = clockGPIO
        self.clockGPIO.direction = .OUT
        self.clockGPIO.value = 0
    }

    public func sendData(_ values: [UInt8], order: ByteOrder, clockDelayUsec: Int) {
        let mmapped = dataGPIO.isMemoryMapped()
        if mmapped {
            sendDataGPIOObj(values, order:order, clockDelayUsec:clockDelayUsec)
        } else {
            sendDataSysFS(values, order:order, clockDelayUsec:clockDelayUsec)
        }
    }

    private func sendDataGPIOObj(_ values: [UInt8], order: ByteOrder, clockDelayUsec: Int) {

        var bit: Int = 0
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

    private func sendDataSysFS(_ values: [UInt8], order: ByteOrder, clockDelayUsec: Int) {

        let mosipath = GPIOBASEPATH+"gpio"+String(self.dataGPIO.id)+"/value"
        let sclkpath = GPIOBASEPATH+"gpio"+String(self.clockGPIO.id)+"/value"
        let HIGH = "1"
        let LOW = "0"

        let fpmosi: UnsafeMutablePointer<FILE>! = fopen(mosipath, "w")
        let fpsclk: UnsafeMutablePointer<FILE>! = fopen(sclkpath, "w")

        guard (fpmosi != nil)&&(fpsclk != nil) else {
            perror("Error while opening gpio")
            abort()
        }
        setvbuf(fpmosi, nil, _IONBF, 0)
        setvbuf(fpsclk, nil, _IONBF, 0)

        var bit: String = LOW
        for value in values {
            for i in 0...7 {
                switch order {
                case .LSBFIRST:
                    bit = ((value & UInt8(1 << i)) == 0) ? LOW : HIGH
                case .MSBFIRST:
                    bit = ((value & UInt8(1 << (7-i))) == 0) ? LOW : HIGH
                }

                writeToFP(fpmosi, value:bit)
                writeToFP(fpsclk, value:HIGH)
                if clockDelayUsec>0 {
                    usleep(UInt32(clockDelayUsec))
                }
                writeToFP(fpsclk, value:LOW)
            }
        }
        fclose(fpmosi)
        fclose(fpsclk)
    }

    private func writeToFP(_ fp: UnsafeMutablePointer<FILE>, value: String) {
        let ret = fwrite(value, MemoryLayout<CChar>.stride, 1, fp)
        if ret<1 {
            if ferror(fp) != 0 {
                perror("Error while writing to file")
                abort()
            }
        }
    }

    public func sendData(_ values: [UInt8]) {
        self.sendData(values, order:.MSBFIRST, clockDelayUsec:0)
    }

    public func isHardware() -> Bool {
        return false
    }

    public func isOut() -> Bool {
        return true
    }
}

// MARK: - SPI Constants

internal let SPI_IOC_WR_MAX_SPEED_HZ: UInt = 0x40046b04
internal let SPIBASEPATH="/dev/spidev"