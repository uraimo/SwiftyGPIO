import Glibc
//Remove this import if you are compiling manually with switfc
import SwiftyGPIO
 

let gpios = SwiftyGPIO.GPIOs(for:.RaspberryPiPlusZero)

gpios[.P3]!.direction = .OUT
while true {    
    gpios[.P3]!.value = 1
    sleep(1)             //Requires Glibc library
    gpios[.P3]!.value = 0
    sleep(1)
}



