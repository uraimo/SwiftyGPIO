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


/// Hardware I2C(SMBus) via Linux SysFS using I2C_SMBUS ioctl
public final class SysFSI2C: I2CInterface {

    let i2cId: Int
    var fd: Int32 = -1
    var currentSlave: Int = -1

    public init(i2cId: Int) {
        self.i2cId=i2cId
    }

    deinit {
        if fd != -1 {
            closeI2C()
        }
    }

    public func readByte(_ address: Int) throws -> UInt8 {
        try setSlaveAddress(address)

        let r =  try i2c_smbus_read_byte()

        if r < 0 {
            throw I2CError.IOError("I2C read failed")
        }
        return UInt8(truncatingIfNeeded: r)
    }

    public func readByte(_ address: Int, command: UInt8) throws -> UInt8 {
        try setSlaveAddress(address)

        let r =  try i2c_smbus_read_byte_data(command: command)

        if r < 0 {
            throw I2CError.IOError("I2C read failed")
        }
        return UInt8(truncatingIfNeeded: r)
    }

    public func readWord(_ address: Int, command: UInt8) throws -> UInt16 {
        try setSlaveAddress(address)

        let r =  try i2c_smbus_read_word_data(command: command)

        if r < 0 {
            throw I2CError.IOError("I2C read failed")
        }
        return UInt16(truncatingIfNeeded: r)
    }

    public func readData(_ address: Int, command: UInt8) throws -> [UInt8] {
        var buf: [UInt8] = [UInt8](repeating:0, count: 32)

        try setSlaveAddress(address)

        let r =  try i2c_smbus_read_block_data(command: command, values: &buf)

        if r < 0 {
            throw I2CError.IOError("I2C read failed")
        }
        return buf
    }

    public func writeQuick(_ address: Int) throws {
        try setSlaveAddress(address)

        let r =  try i2c_smbus_write_quick(value: I2C_SMBUS_WRITE)

        if r < 0 {
            throw I2CError.IOError("I2C write failed")
        }
    }

    public func writeByte(_ address: Int, value: UInt8) throws {
        try setSlaveAddress(address)

        let r =  try i2c_smbus_write_byte(value: value)

        if r < 0 {
            throw I2CError.IOError("I2C write failed")
        }
    }

    public func writeByte(_ address: Int, command: UInt8, value: UInt8) throws {
        try setSlaveAddress(address)

        let r =  try i2c_smbus_write_byte_data(command: command, value: value)

        if r < 0 {
            throw I2CError.IOError("I2C write failed")
        }
    }

    public func writeWord(_ address: Int, command: UInt8, value: UInt16) throws {
        try setSlaveAddress(address)

        let r =  try i2c_smbus_write_word_data(command: command, value: value)

        if r < 0 {
            throw I2CError.IOError("I2C write failed")
        }
    }

    public func writeData(_ address: Int, command: UInt8, values: [UInt8]) throws {
        try setSlaveAddress(address)

        let r =  try i2c_smbus_write_block_data(command: command, values: values)

        if r < 0 {
            throw I2CError.IOError("I2C write failed")
        }
    }

    public func isReachable(_ address: Int) throws -> Bool {
        try setSlaveAddress(address)

        var r: Int32 =  -1
        switch(address){
            case 0x3...0x2f:
                r =  i2c_smbus_write_quick(value: 0)
            case 0x30...0x37:
                r =  i2c_smbus_read_byte()
            case 0x38...0x4f:
                r = i2c_smbus_write_quick(value: 0)
            case 0x50...0x5f:
                r =  i2c_smbus_read_byte()
            case 0x60...0x77:
                r =  i2c_smbus_write_quick(value: 0)
            default:
                r =  i2c_smbus_read_byte()
        }

        guard r >= 0 else { return false }

        return true
    }

    public func setPEC(_ address: Int, enabled: Bool) throws {
        try setSlaveAddress(address)

        let r =  ioctl(fd, I2C_PEC, enabled ? 1 : 0)

        if r != 0 {
            throw I2CError.deviceError("I2C communication failed, couldn't set PEC")
        }
    }

    private func setSlaveAddress(_ to: Int) throws {

        if fd == -1 {
            try openI2C()
        }

        guard currentSlave != to else {return}

        let r = ioctl(fd, I2C_SLAVE_FORCE, CInt(to))
        if r != 0 {
            throw I2CError.deviceError("I2C communication failed, couldn't select slave")
        }

        currentSlave = to
    }

    private func openI2C() throws {
        let fd = open(I2CBASEPATH+String(i2cId), O_RDWR)
        guard fd > 0 else {
            throw I2CError.deviceError("Couldn't open the I2C device")
        }

        self.fd = fd
    }

    private func closeI2C() {
        close(fd)
    }

    // Private functions
    // Swift implementation of the smbus functions provided by i2c-dev

    private struct i2c_smbus_ioctl_data {
        var read_write: UInt8
        var command: UInt8
        var size: Int32
        var data: UnsafeMutablePointer<UInt8>? //union: UInt8, UInt16, [UInt8]33
    }

    private func smbus_ioctl(rw: UInt8, command: UInt8, size: Int32, data: UnsafeMutablePointer<UInt8>?) throws -> Int32 {
        if fd == -1 {
            try openI2C()
        }

        var args = i2c_smbus_ioctl_data(read_write: rw,
                                        command: command,
                                        size: size,
                                        data: data)
        return ioctl(fd, I2C_SMBUS, &args)
    }

    //
    // Read
    //

    private func i2c_smbus_read_byte() throws -> Int32 {
        var data = [UInt8](repeating:0, count: I2C_MAX_LENGTH+1)

        let r = try smbus_ioctl(rw: I2C_SMBUS_READ,
                            command: 0,
                            size: I2C_SMBUS_BYTE,
                            data: &data)
        if r >= 0 {
            return Int32(data[0])
        } else {
            return -1
        }
    }

    private func i2c_smbus_read_byte_data(command: UInt8) throws -> Int32 {
        var data = [UInt8](repeating:0, count: I2C_MAX_LENGTH+1)

        let r = try smbus_ioctl(rw: I2C_SMBUS_READ,
                            command: command,
                            size: I2C_SMBUS_BYTE_DATA,
                            data: &data)
        if r >= 0 {
            return Int32(data[0])
        } else {
            return -1
        }
    }

    private func i2c_smbus_read_word_data(command: UInt8) throws -> Int32 {
        var data = [UInt8](repeating:0, count: I2C_MAX_LENGTH+1)

        let r = try smbus_ioctl(rw: I2C_SMBUS_READ,
                            command: command,
                            size: I2C_SMBUS_WORD_DATA,
                            data: &data)
        if r >= 0 {
            return (Int32(data[1]) << 8) + Int32(data[0])
        } else {
            return -1
        }
    }

    private func i2c_smbus_read_block_data(command: UInt8, values: inout [UInt8]) throws -> Int32 {
        var data = [UInt8](repeating:0, count: I2C_MAX_LENGTH+1)

        let r = try smbus_ioctl(rw: I2C_SMBUS_READ,
                            command: command,
                            size: I2C_SMBUS_WORD_DATA,
                            data: &data)
        if r >= 0 {
            for i in 0..<Int(data[0]) {
                values[i] = data[i+1]
            }
            return Int32(data[0])
        } else {
            return -1
        }
    }

    //
    // Write
    //

    private func i2c_smbus_write_quick(value: UInt8) throws -> Int32 {
        return try smbus_ioctl(rw: value,
                           command: 0,
                           size: I2C_SMBUS_QUICK,
                           data: nil)
    }

    private func i2c_smbus_write_byte(value: UInt8) throws -> Int32 {
        return try smbus_ioctl(rw: I2C_SMBUS_WRITE,
                           command: value,
                           size: I2C_SMBUS_BYTE,
                           data: nil)
    }

    private func i2c_smbus_write_byte_data(command: UInt8, value: UInt8) throws -> Int32 {
        var data = [UInt8](repeating:0, count: I2C_MAX_LENGTH+1)

        data[0] = value

        return try smbus_ioctl(rw: I2C_SMBUS_WRITE,
                           command: command,
                           size: I2C_SMBUS_BYTE_DATA,
                           data: &data)
    }

    private func i2c_smbus_write_word_data(command: UInt8, value: UInt16) throws -> Int32 {
        var data = [UInt8](repeating:0, count: I2C_MAX_LENGTH+1)

        data[0] = UInt8(value & 0xFF)
        data[1] = UInt8(value >> 8)

        return try smbus_ioctl(rw: I2C_SMBUS_WRITE,
                           command: command,
                           size: I2C_SMBUS_WORD_DATA,
                           data: &data)
    }

    private func i2c_smbus_write_block_data(command: UInt8, values: [UInt8]) throws -> Int32 {
        var data = [UInt8](repeating:0, count: I2C_MAX_LENGTH+1)

        for i in 1...values.count {
            data[i] = values[i-1]
        }
        data[0] = UInt8(values.count)

        return try smbus_ioctl(rw: I2C_SMBUS_WRITE,
                           command: command,
                           size: I2C_SMBUS_BLOCK_DATA,
                           data: &data)
    }

}

// MARK: - I2C/SMBUS Constants
internal let I2C_SMBUS_READ: UInt8 =   1
internal let I2C_SMBUS_WRITE: UInt8 =  0

internal let I2C_SMBUS_QUICK: Int32 = 0
internal let I2C_SMBUS_BYTE: Int32 = 1
internal let I2C_SMBUS_BYTE_DATA: Int32 = 2
internal let I2C_SMBUS_WORD_DATA: Int32 = 3
internal let I2C_SMBUS_BLOCK_DATA: Int32 = 5

internal let I2C_SLAVE: UInt = 0x703
internal let I2C_SLAVE_FORCE: UInt = 0x706
internal let I2C_RDWR: UInt = 0x707
internal let I2C_PEC: UInt = 0x708
internal let I2C_SMBUS: UInt = 0x720
internal let I2C_MAX_LENGTH: Int = 32
internal let I2CBASEPATH="/dev/i2c-"

// MARK: - Darwin / Xcode Support
#if os(OSX) || os(iOS)
    private var O_SYNC: CInt { fatalError("Linux only") }
#endif
