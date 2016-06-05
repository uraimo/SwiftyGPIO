import Glibc

let gpios = SwiftyGPIO.getGPIOsForBoard(.RaspberryPiRev1)

gpios[.P1]!.direction = .OUT
for var i in 0 ..< 1000 {
    gpios[.P0]!.value = 1
    gpios[.P0]!.value = 0
}


