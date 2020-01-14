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

/// UART via Linux SysFS
public final class SysFSUART: UARTInterface {
    var device: String
    var tty: termios
    var fd: Int32

    public init?(_ uartIdList: [String]) {
        // Try all items in list until one works
        for uartId in uartIdList {
            device = "/dev/"+uartId
            tty = termios()

            fd = open(device, O_RDWR | O_NOCTTY | O_SYNC)
            guard fd>0 else {
                // Couldn't open UART device, skip
                continue
            }

            let ret = tcgetattr(fd, &tty)
            guard ret == 0 else {
                // Couldn't get terminal attributes, skip
                close(fd)
                continue
            }
            return
        }
        return nil
    }

    public convenience init?(_ uartId: String) {
        self.init([uartId])
    }

    public func configureInterface(speed: UARTSpeed, bitsPerChar: CharSize, stopBits: StopBits, parity: ParityType) throws {
        speed.configure(&tty)

        bitsPerChar.configure(&tty)
        tty.c_iflag &= ~UInt32(IGNBRK)      // disable break processing
        tty.c_lflag =  0    				// no signaling chars, no echo,
        // no canonical processing -> read bytes as they come without waiting for LF
        tty.c_oflag = 0                     // no remapping, no delays

        withUnsafeMutableBytes(of: &tty.c_cc) {$0[Int(VMIN)] = UInt8(1); return}
        withUnsafeMutableBytes(of: &tty.c_cc) {$0[Int(VTIME)] = UInt8(5); return} // 5 10th of second read timeout
        tty.c_iflag &= ~UInt32(IXON | IXOFF | IXANY) // Every kind of software flow control off
        tty.c_cflag &= ~UInt32(CRTSCTS)  //No hw flow control
        tty.c_cflag |= UInt32(CLOCAL | CREAD)        // Ignore modem controls, enable read
        parity.configure(&tty)
        stopBits.configure(&tty)

        try applyConfiguration()
    }

    public func hasAvailableData() throws -> Bool {
        var bytesToRead = 0
        let result = ioctl(fd, UInt(FIONREAD), &bytesToRead)

        guard result >= 0 else { throw UARTError.IOError(String(format: "%s", strerror(errno))) }
        return bytesToRead > 0
    }

    public func readLine() throws -> String {
        var buf = [CChar](repeating:0, count: 4097) //4096 chars at max in canonical mode
        var ptr = UnsafeMutablePointer<CChar>(&buf)
        var pos = 0

        repeat {
            let n = read(fd, ptr, MemoryLayout<CChar>.stride)
            if n<0 {
                throw UARTError.IOError("Error while reading from UART")
            }
            ptr += 1
            pos += 1
        } while (buf[pos-1] != CChar(UInt8(ascii: "\n"))) && (pos < buf.count-1)

        buf[pos] = 0
        return String(cString: &buf)
    }

    public func readString() throws -> String {
        var buf = try readData()
        buf.append(0) //Add terminator to convert cString correctly
        return String(cString: &buf)
    }

    public func readData() throws -> [CChar] {
        var buf = [CChar](repeating:0, count: 4096) //4096 chars at max in canonical mode

        let n = read(fd, &buf, buf.count * MemoryLayout<CChar>.stride)
        
        usleep(100_000) //100ms sleep. Workaround for random: Index out of range: .../ContiguousArrayBuffer.swift error

        if n<0 {
            throw UARTError.IOError("Error while reading from UART")
        }
        
        return Array(buf[0..<n])
    }

    public func writeString(_ value: String) {
        let chars = Array(value.utf8CString)

        writeData(chars)
    }

    public func writeData(_ value: [CChar]) {
        var value = value

        _ = write(fd, &value, value.count)
        tcdrain(fd)
    }

    private func applyConfiguration() throws {
        if tcsetattr (fd, TCSANOW, &tty) != 0 {
            throw UARTError.configError("Couldn't set terminal attributes")
        }
    }

    deinit {
        close(fd)
    }

}

// MARK: - Darwin / Xcode Support
#if os(OSX) || os(iOS)
    private let FIONREAD = 0x541B // Cannot be found on Darwin, only on Glibc. Added this to get it to compile with XCode.

    private var O_SYNC: CInt { fatalError("Linux only") }
    private var CRTSCTS: CInt { fatalError("Linux only") }

    // Shadowing some declarations from termios.h just to get it to compile with Xcode
    // As the rest, not atually intended to be run.
    public struct termios {
        var c_iflag: UInt32 = 0
        var c_oflag: UInt32 = 0
        var c_cflag: UInt32 = 0
        var c_lflag: UInt32 = 0
        var c_cc = [UInt32]()
    }

    func tcsetattr (_ fd: Int32, _ attr: Int32, _ tty: inout termios) -> Int { fatalError("Linux only") }
    func tcgetattr(_ fd: Int32, _ tty: inout termios) -> Int { fatalError("Linux only") }
    func cfsetispeed(_ tty: inout termios, _ speed: UInt) { fatalError("Linux only") }
    func cfsetospeed(_ tty: inout termios, _ speed: UInt) { fatalError("Linux only") }

#endif
