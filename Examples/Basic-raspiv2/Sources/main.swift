import Glibc

let gpios = SwiftyGPIO.getGPIOsForBoard(.RaspberryPiRev2)

gpios[.P3]!.direction = .OUT
while true {    
    gpios[.P3]!.value = 1
    gpios[.P3]!.value = 0
}



