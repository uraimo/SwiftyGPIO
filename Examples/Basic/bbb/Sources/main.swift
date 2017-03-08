import Glibc
//Remove this import if you are compiling manually with switfc
import SwiftyGPIO

let gpios = SwiftyGPIO.GPIOs(for:.RaspberryPiB2Zero)
var gp = GPIO(name: "GPIO_45",id: 45)  

print("Current Status")
print("Direction: "+gp.direction.rawValue)
print("Edge: "+gp.edge.rawValue)
print("Active Low: "+String(gp.activeLow))
print("Value: "+String(gp.value))

gp.direction = .OUT
gp.value = 0 // Or 1 if the previous value is 0

print("New Status")
print("Direction: "+gp.direction.rawValue)
print("Edge: "+gp.edge.rawValue)
print("Active Low: "+String(gp.activeLow))
print("Value: "+String(gp.value))

while true {
  gp.value = 1
  gp.value = 0
}
