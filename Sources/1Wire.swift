/*
 SwiftyGPIO

 Copyright (c) 2017 Umberto Raimondi
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


// MARK: - 1-Wire Presets
extension SwiftyGPIO {

    public static func hardware1Wires(for board: SupportedBoard) -> [OneWireInterface]? {
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
            return [SysFSOneWire(masterId: 1)]
        default:
            return nil
        }
    }
}

// MARK: 1-Wire
public protocol OneWireInterface {
    func getSlaves() -> [String]
    func readData(_ slaveId: String) -> [String]
}

/// Hardware 1-Wire via SysFS
public final class SysFSOneWire: OneWireInterface {

    let masterId: Int

    public init(masterId: Int) {
        self.masterId = masterId
    }

    public func getSlaves() -> [String] {
            let listpath = ONEWIREBASEPATH+"w1_bus_master"+String(masterId)+"/w1_master_slaves"

            let fd = open(listpath, O_RDONLY | O_SYNC)
            guard fd>0 else {
                perror("Couldn't open 1-Wire master device")
                abort()
            }

            var slaves = [String]()
            while let s = readLine(fd) {
                slaves.append(s)
            }

            close(fd)
            return slaves
    }

    public func readData(_ slaveId: String) -> [String] {
        let devicepath = ONEWIREBASEPATH+slaveId+"/w1_slave"
            
        let fd = open(devicepath, O_RDONLY | O_SYNC)
        guard fd>0 else {
            perror("Couldn't open 1-Wire slave device")
            abort()
        }

        var lines = [String]()
        while let s = readLine(fd) {
            lines.append(s)
        }

        close(fd)
        return lines      
    }

    private func readLine(_ fd: Int32) -> String? {
        var buf = [CChar](repeating:0, count: 128) 
        var ptr = UnsafeMutablePointer<CChar>(&buf)
        var pos = 0

        repeat {
            let n = read(fd, ptr, MemoryLayout<CChar>.stride)
            if n<0 {
                perror("Error while reading from 1-Wire interface")
                abort()
            } else if n == 0 {
                break
            }
            ptr += 1
            pos += 1
        } while buf[pos-1] != CChar(UInt8(ascii: "\n"))

        if pos == 0 {
            return nil
        } else {
            buf[pos-1] = 0
            return String(cString: &buf)
        }
    }

}

// MARK: - 1-Wire Constants

internal let ONEWIREBASEPATH = "/sys/bus/w1/devices/"

// MARK: - Darwin / Xcode Support
#if os(OSX) || os(iOS)
    private var O_SYNC: CInt { fatalError("Linux only") }
#endif

