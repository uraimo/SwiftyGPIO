import Glibc
//Remove this import if you are compiling manually with switfc
import SwiftyGPIO
 
let gpios = SwiftyGPIO.GPIOs(for:.RaspberryPiRev1)

gpios[.P1]!.direction = .OUT
for var i in 0 ..< 1000 {
    gpios[.P0]!.value = 1
    gpios[.P0]!.value = 0
}


