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
            fallthrough
        case .RaspberryPi3:
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
        0: SysFSSPI(spiId:"0.0"),
        1: SysFSSPI(spiId:"0.1")
    ]

    // BananaPi
    static let SPIBANANAPI: [Int:SPIOutput] = [
        0: SysFSSPI(spiId:"0.0"),
        1: SysFSSPI(spiId:"0.1")
    ]
}

// MARK: SPI

public protocol SPIOutput {
    // Send data at the requested frequency (from 500Khz to 20 Mhz)
    func sendData(_ values: [UInt8], frequencyHz: UInt)
    // Send data at the default frequency
    func sendData(_ values: [UInt8])
    // Send data and then receive a chunck of data at the requested frequency (from 500Khz to 20 Mhz)
    func sendDataAndRead(_ values: [UInt8], frequencyHz: UInt) -> [UInt8]
    // Send data and then receive a chunck of data at the default frequency
    func sendDataAndRead(_ values: [UInt8]) -> [UInt8]
    // Returns true if the SPIOutput is using a real SPI pin, false if performing bit-banging
    func isHardware() -> Bool
}

/// Hardware SPI via SysFS
public final class SysFSSPI: SPIOutput {

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

    public func sendData(_ values: [UInt8], frequencyHz: UInt = 500000) {
        if frequencyHz > 500000 {
            speed = UInt32(frequencyHz)
        }
        transferData(SPIBASEPATH+spiId, tx:values)
    }

    public func sendData(_ values: [UInt8]) {
        sendData(values, frequencyHz: 500000)
    }

    public func sendDataAndRead(_ values: [UInt8], frequencyHz: UInt = 500000) -> [UInt8] {
        if frequencyHz > 500000 {
            speed = UInt32(frequencyHz)
        }
        let rx = transferData(SPIBASEPATH+spiId, tx:values)
        return rx
    }

    public func sendDataAndRead(_ values: [UInt8]) -> [UInt8] {
        return sendDataAndRead(values, frequencyHz: 500000)
    }

    public func isHardware() -> Bool {
        return true
    }

    /// Write and read bits, will need a few dummy writes if you want only read
    @discardableResult
    private func transferData(_ path: String, tx: [UInt8]) -> [UInt8] {
        let rx: [UInt8] = [UInt8](repeating:0, count: tx.count)

        let fd = open(path, O_RDWR)
        guard fd > 0 else {
            fatalError("Couldn't open the SPI device")
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
            perror("Couldn't send spi message")
            abort()
        }
        close(fd)

        return rx
    }

    public func setMode(_ to: CInt) {
        mode = to

        let fd = open(SPIBASEPATH+spiId, O_RDWR)
        guard fd > 0 else {
            fatalError("Couldn't open the SPI device")
        }

        let r = ioctl(fd, SPI_IOC_WR_MODE, &mode)
        if r == -1 {
            fatalError("Couldn't set spi mode")
        }

        close(fd)
    }

    public func getMode() -> CInt {
        let fd = open(SPIBASEPATH+spiId, O_RDWR)
        guard fd > 0 else {
            fatalError("Couldn't open the SPI device")
        }

        let r = ioctl(fd, SPI_IOC_RD_MODE, &mode);
        if r == -1 {
            fatalError("Couldn't get spi mode")
        }

        close(fd)
        return mode
    }

    public func setBitsPerWord(_ to: UInt8) {
        bits = to
        
        let fd = open(SPIBASEPATH+spiId, O_RDWR)
        guard fd > 0 else {
            fatalError("Couldn't open the SPI device")
        }

        let r = ioctl(fd, SPI_IOC_WR_BITS_PER_WORD, &bits)
        if r == -1 {
            fatalError("Couldn't set bits per word")
        }

        close(fd)
    }

    public func getBitsPerWord() -> UInt8 {
        let fd = open(SPIBASEPATH+spiId, O_RDWR)
        guard fd > 0 else {
            fatalError("Couldn't open the SPI device")
        }

        let r = ioctl(fd, SPI_IOC_RD_BITS_PER_WORD, &bits)
        if r == -1 {
            fatalError("Couldn't get bits per word")
        }

        close(fd)
        return bits
    }

    public func setMaxSpeedHz(_ to: UInt32) {
        speed = to

        let fd = open(SPIBASEPATH+spiId, O_RDWR)
        guard fd > 0 else {
            fatalError("Couldn't open the SPI device")
        }

        let r = ioctl(fd, SPI_IOC_WR_MAX_SPEED_HZ, &speed)
        if r == -1 {
            fatalError("Couldn't set max speed hz")
        }

        close(fd)
    }

    public func getMaxSpeedHz() -> UInt32 {
        let fd = open(SPIBASEPATH+spiId, O_RDWR)
        guard fd > 0 else {
            fatalError("Couldn't open the SPI device")
        }

        let r = ioctl(fd, SPI_IOC_RD_MAX_SPEED_HZ, &speed)
        if r == -1 {
            fatalError("Couldn't get max speed hz")
        }

        close(fd)
        return speed
    }

}

/// Bit-banging virtual SPI implementation, output only
public final class VirtualSPI: SPIOutput {
    let dataGPIO, clockGPIO: GPIO

    public init(dataGPIO: GPIO, clockGPIO: GPIO) {
        self.dataGPIO = dataGPIO
        self.dataGPIO.direction = .OUT
        self.dataGPIO.value = 0
        self.clockGPIO = clockGPIO
        self.clockGPIO.direction = .OUT
        self.clockGPIO.value = 0
    }

    public func sendData(_ values: [UInt8], frequencyHz: UInt = 500000) {
        let mmapped = dataGPIO.isMemoryMapped()
        if mmapped {
            sendDataGPIOObj(values, frequencyHz: frequencyHz)
        } else {
            sendDataSysFSGPIO(values, frequencyHz: frequencyHz)
        }
    }
    public func sendData(_ values: [UInt8]) {
        sendData(values, frequencyHz: 0)
    }

    public func sendDataAndRead(_ values: [UInt8], frequencyHz: UInt = 500000) -> [UInt8] {
        self.sendData(values, frequencyHz: frequencyHz)
        return [UInt8]()
    }

    public func sendDataAndRead(_ values: [UInt8]) -> [UInt8] {
        return sendDataAndRead(values, frequencyHz: 0)
    }

    private func sendDataGPIOObj(_ values: [UInt8], frequencyHz: UInt) {

        var bit: Int = 0
        for value in values {
            for i in 0...7 {
                bit = ((value & UInt8(1 << (7-i))) == 0) ? 0 : 1

                dataGPIO.value = bit
                clockGPIO.value = 1
                if frequencyHz > 0 {
                    let amount = UInt32(1_000_000/Double(frequencyHz))
                    // Calling usleep introduces significant delay, don't sleep for small values
                    if amount > 50 {
                        usleep(amount)
                    }
                }
                clockGPIO.value = 0
            }
        }
    }

    private func sendDataSysFSGPIO(_ values: [UInt8], frequencyHz: UInt) {

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
                bit = ((value & UInt8(1 << (7-i))) == 0) ? LOW : HIGH

                writeToFP(fpmosi, value:bit)
                writeToFP(fpsclk, value:HIGH)
                if frequencyHz > 0 {
                    let amount = UInt32(1_000_000/Double(frequencyHz))
                    // Calling usleep introduces significant delay, don't sleep for small values
                    if amount > 50 {
                        usleep(amount)
                    }
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

    public func isHardware() -> Bool {
        return false
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
#if os(OSX)
    private var O_SYNC: CInt { fatalError("Linux only") }
#endif
