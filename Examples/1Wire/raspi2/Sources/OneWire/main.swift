import SwiftyGPIO //Remove this import if you are compiling manually with switfc
#if os(Linux)
    import Glibc
#else
    import Darwin.C
#endif
import Foundation


let ones = SwiftyGPIO.hardware1Wires(for:.RaspberryPi2)!
var onewire = ones[0]

for slave in onewire.getSlaves() {
    print("Slave: "+slave)
    print("------------------------------------")
    for data in onewire.readData(slave) {
        print(data)
    }
}
