import Glibc


let gpios = SwiftyGPIO.getGPIOsForBoard(.CHIP)
gpios[.P0]!.direction = .OUT
gpios[.P0]!.value = 0



