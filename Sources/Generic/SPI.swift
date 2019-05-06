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

/// Hardware SPI via Linux SysFS
public final class SysFSSPI: SPIInterface {

    struct spi_ioc_transfer {
        var tx_buf: UInt64
        var rx_buf: UInt64
        var len: UInt32
        var speed_hz: UInt32 = 500000
        var delay_usecs: UInt16 = 0
        var bits_per_word: UInt8 = 8
        let cs_change: UInt8 = 0
        let tx_nbits: UInt8 = 0
        let rx_nbits: UInt8 = 0
        let pad: UInt16 = 0
    }

    let spiId: String
    var mode: CInt = 0
    var bits: UInt8 = 8
    var speed: UInt32 = 500000
    var delay: UInt16 = 0

    public init(spiId: String) {
        self.spiId=spiId
        //TODO: Check if available?
    }

    public var isHardware =  true

    public func sendData(_ values: [UInt8], frequencyHz: UInt = 500000) throws {
        if frequencyHz > 500000 {
            speed = UInt32(frequencyHz)
        }
        try transferData(SPIBASEPATH+spiId, tx:values)
    }

    public func sendData(_ values: [UInt8]) throws {
        try sendData(values, frequencyHz: 500000)
    }

    public func sendDataAndRead(_ values: [UInt8], frequencyHz: UInt = 500000) throws -> [UInt8] {
        if frequencyHz > 500000 {
            speed = UInt32(frequencyHz)
        }
        let rx = try transferData(SPIBASEPATH+spiId, tx:values)
        return rx
    }

    public func sendDataAndRead(_ values: [UInt8]) throws -> [UInt8] {
        return try sendDataAndRead(values, frequencyHz: 500000)
    }

    /// Write and read bits, will need a few dummy writes if you want only read
    @discardableResult
    private func transferData(_ path: String, tx: [UInt8]) throws -> [UInt8] {
        let rx: [UInt8] = [UInt8](repeating:0, count: tx.count)

        let fd = open(path, O_RDWR)
        guard fd > 0 else {
            throw SPIError.deviceError("Couldn't open the SPI device")
        }

        var tr = spi_ioc_transfer(
            tx_buf: UInt64( UInt(bitPattern: UnsafeMutablePointer(mutating: tx)) ),
            rx_buf: UInt64( UInt(bitPattern: UnsafeMutablePointer(mutating: rx)) ),
            len: UInt32(tx.count),
            speed_hz: speed,
            delay_usecs: delay,
            bits_per_word: bits)

        let r = ioctl(fd, SPI_IOC_MESSAGE1, &tr)
        if r < 1 {
            throw SPIError.IOError("Couldn't send spi message")
        }
        close(fd)

        return rx
    }

    public func setMode(_ to: CInt) throws {
        mode = to

        let fd = open(SPIBASEPATH+spiId, O_RDWR)
        guard fd > 0 else {
            throw SPIError.deviceError("Couldn't open the SPI device")
        }

        let r = ioctl(fd, SPI_IOC_WR_MODE, &mode)
        if r == -1 {
            throw SPIError.IOError("Couldn't set spi mode")
        }

        close(fd)
    }

    public func getMode() throws -> CInt {
        let fd = open(SPIBASEPATH+spiId, O_RDWR)
        guard fd > 0 else {
            throw SPIError.deviceError("Couldn't open the SPI device")
        }

        let r = ioctl(fd, SPI_IOC_RD_MODE, &mode)
        if r == -1 {
            throw SPIError.IOError("Couldn't get spi mode")
        }

        close(fd)
        return mode
    }

    public func setBitsPerWord(_ to: UInt8) throws {
        bits = to

        let fd = open(SPIBASEPATH+spiId, O_RDWR)
        guard fd > 0 else {
            throw SPIError.deviceError("Couldn't open the SPI device")
        }

        let r = ioctl(fd, SPI_IOC_WR_BITS_PER_WORD, &bits)
        if r == -1 {
            throw SPIError.IOError("Couldn't set bits per word")
        }

        close(fd)
    }

    public func getBitsPerWord() throws -> UInt8 {
        let fd = open(SPIBASEPATH+spiId, O_RDWR)
        guard fd > 0 else {
            throw SPIError.deviceError("Couldn't open the SPI device")
        }

        let r = ioctl(fd, SPI_IOC_RD_BITS_PER_WORD, &bits)
        if r == -1 {
            throw SPIError.IOError("Couldn't get bits per word")
        }

        close(fd)
        return bits
    }

    public func setMaxSpeedHz(_ to: UInt32) throws {
        speed = to

        let fd = open(SPIBASEPATH+spiId, O_RDWR)
        guard fd > 0 else {
            throw SPIError.deviceError("Couldn't open the SPI device")
        }

        let r = ioctl(fd, SPI_IOC_WR_MAX_SPEED_HZ, &speed)
        if r == -1 {
            throw SPIError.IOError("Couldn't set max speed hz")
        }

        close(fd)
    }

    public func getMaxSpeedHz() throws -> UInt32 {
        let fd = open(SPIBASEPATH+spiId, O_RDWR)
        guard fd > 0 else {
            throw SPIError.deviceError("Couldn't open the SPI device")
        }

        let r = ioctl(fd, SPI_IOC_RD_MAX_SPEED_HZ, &speed)
        if r == -1 {
            throw SPIError.IOError("Couldn't get max speed hz")
        }

        close(fd)
        return speed
    }

}

/// Bit-banging virtual SPI implementation, output only
public final class VirtualSPI: SPIInterface {
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
        try sendDataSysFSGPIO(values, frequencyHz: frequencyHz, read: false)
    }
    public func sendData(_ values: [UInt8]) throws {
        try sendData(values, frequencyHz: 0)
    }

    public func sendDataAndRead(_ values: [UInt8], frequencyHz: UInt = 500000) throws -> [UInt8] {
        var rx = [UInt8]()

        rx = try sendDataSysFSGPIO(values, frequencyHz: frequencyHz, read: true)
        return rx
    }

    public func sendDataAndRead(_ values: [UInt8]) throws -> [UInt8] {
        return try sendDataAndRead(values, frequencyHz: 0)
    }


    @discardableResult
    private func sendDataSysFSGPIO(_ values: [UInt8], frequencyHz: UInt, read: Bool) throws -> [UInt8] {
        var rx: [UInt8] = [UInt8]()

        let mosipath = GPIOBASEPATH+"gpio"+String(self.mosiGPIO.id)+"/value"
        let misopath = GPIOBASEPATH+"gpio"+String(self.misoGPIO.id)+"/value"
        let sclkpath = GPIOBASEPATH+"gpio"+String(self.clockGPIO.id)+"/value"
        let HIGH = "1"
        let LOW = "0"
        //Begin transmission cs=LOW
        csGPIO.value = false

        let fpmosi: UnsafeMutablePointer<FILE>! = fopen(mosipath, "w")
        let fpmiso: UnsafeMutablePointer<FILE>! = fopen(misopath, "r")
        let fpsclk: UnsafeMutablePointer<FILE>! = fopen(sclkpath, "w")

        guard (fpmosi != nil)&&(fpsclk != nil) else {
            throw SPIError.deviceError("Error while opening gpio")
        }
        setvbuf(fpmosi, nil, _IONBF, 0)
        setvbuf(fpmiso, nil, _IONBF, 0)
        setvbuf(fpsclk, nil, _IONBF, 0)

        var bit: String = LOW
        var rbit: UInt8 = 0

        for value in values {
            rbit = 0
            for i in 0...7 {
                bit = ((value & UInt8(1 << (7-i))) == 0) ? LOW : HIGH

                try writeToFP(fpmosi, value:bit)
                try writeToFP(fpsclk, value:HIGH)
                if frequencyHz > 0 {
                    let amount = UInt32(1_000_000/Double(frequencyHz))
                    // Calling usleep introduces significant delay, don't sleep for small values
                    if amount > 50 {
                        usleep(amount)
                    }
                }
                try writeToFP(fpsclk, value:LOW)
                if read {
                    rbit |= ( try readFromFP(fpmiso) << (7-UInt8(i)) )
                }
            }
            if read {
                rx.append(rbit)
            }
        }
        fclose(fpmosi)
        fclose(fpmiso)
        fclose(fpsclk)

        //End transmission cs=HIGH
        csGPIO.value = true
        return rx
    }

    private func writeToFP(_ fp: UnsafeMutablePointer<FILE>, value: String) throws {
        let ret = fwrite(value, MemoryLayout<CChar>.stride, 1, fp)
        if ret<1 {
            if ferror(fp) != 0 {
                throw SPIError.IOError("Error while writing to file")
            }
        }
    }

    private func readFromFP(_ fp: UnsafeMutablePointer<FILE>) throws -> UInt8 {
        var value: UInt8 = 0
        let ret = fread(&value, MemoryLayout<CChar>.stride, 1, fp)
        if ret<1 {
            if ferror(fp) != 0 {
                throw SPIError.IOError("Error while reading from file")
            }
        }
        return value
    }

}


// MARK: - SPI Constants
internal let SPI_IOC_WR_MODE: UInt = 0x40016b01
internal let SPI_IOC_RD_MODE: UInt = 0x80016b01
internal let SPI_IOC_WR_BITS_PER_WORD: UInt = 0x40016b03
internal let SPI_IOC_RD_BITS_PER_WORD: UInt = 0x80016b03
internal let SPI_IOC_WR_MAX_SPEED_HZ: UInt = 0x40046b04
internal let SPI_IOC_RD_MAX_SPEED_HZ: UInt = 0x80046b04
internal let SPI_IOC_MESSAGE1: UInt = 0x40206b00
internal let SPIBASEPATH="/dev/spidev"

// MARK: - Darwin / Xcode Support
#if os(OSX) || os(iOS)
    private var O_SYNC: CInt { fatalError("Linux only") }
#endif
