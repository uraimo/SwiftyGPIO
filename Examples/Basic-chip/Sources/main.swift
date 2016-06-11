import Glibc
//Remove this import if you are compiling manually with switfc
import SwiftyGPIO

let gpios = SwiftyGPIO.GPIOs(for:.CHIP)
gpios[.P0]!.direction = .OUT
gpios[.P0]!.value = 0



