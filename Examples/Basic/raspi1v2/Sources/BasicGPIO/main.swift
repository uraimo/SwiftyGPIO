import Glibc
import SwiftyGPIO
 

let gpios = SwiftyGPIO.GPIOs(for:.RaspberryPiRev2)

gpios[.P3]!.direction = .OUT
while true {    
    gpios[.P3]!.value = 1
    gpios[.P3]!.value = 0
}



