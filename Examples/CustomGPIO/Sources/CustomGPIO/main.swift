import Glibc
//Remove this import if you are compiling manually with switfc
import SwiftyGPIO


let id = 408
var gp01 = GPIO(name: "P0",id: 408)
print("Current Status")
print("Direction: "+gp01.direction.rawValue)
print("Edge: "+gp01.edge.rawValue)
print("Active Low: "+String(gp01.activeLow))
print("Value: "+String(gp01.value))
gp01.direction = .OUT
gp01.value = 1
print("New Status")
print("Direction: "+gp01.direction.rawValue)
print("Edge: "+gp01.edge.rawValue)
print("Active Low: "+String(gp01.activeLow))
print("Value: "+String(gp01.value))

repeat{
	gp01.value = (gp01.value == 0) ? 1 : 0
	usleep(150*1000)
}while(true)
