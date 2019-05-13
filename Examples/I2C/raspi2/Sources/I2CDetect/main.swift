import Glibc
import SwiftyGPIO //Remove this import if you are compiling manually with switfc
 
let i2cs = SwiftyGPIO.hardwareI2Cs(for:.RaspberryPi2)!
let i2c = i2cs[1]

print("Detecting devices on the I2C bus:\n")
outer: for i in 0x0...0x7 {
    if i == 0 {
        print("    0  1  2  3  4  5  6  7  8  9  a  b  c  d  e  f")
    }
    for j in 0x0...0xf {
        if j == 0 {
            print(String(format:"%x0",i), terminator: "")
        }
        // Test within allowed range 0x3...0x77
        if (i==0) && (j<3) {print("   ", terminator: "");continue}
        if (i>=7) && (j>=7) {break outer}
        
        print(" \(i2c.isReachable(i<<4 + j) ? " x" : " ." )", terminator: "")
    }
    print()
}
print("\n")

// Reading register 0 of the device with address 0x68
//print(i2c.readByte(0x68, command: 0))

// Reading register 1 of the device with address 0x68
//print(i2c.readByte(0x68, command: 1))

// Writing register 0 of the device with address 0x68
//i2c.writeByte(0x68, command: 0, value: 0)

// Reading again register 0 of the device with address 0x68
//print(i2c.readByte(0x68, command: 0))

