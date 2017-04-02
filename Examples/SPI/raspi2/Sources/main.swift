//Remove this import if you are compiling manually with switfc
import SwiftyGPIO
 
// Let's use the hardware SPI with the device #0
//
// GPIO10 = MOSI -> SPI output, connect to the device input
// GPIO9 = MISO -> SPI input, connect to the device output
// GPIO11 = SLCK -> Connect to the clk pin
// GPIO8 = CE0 -> Use this
// GPIO7 = CE1

let spis = SwiftyGPIO.hardwareSPIs(for:.RaspberryPi2)
var spi = spis?[0]

// Send some bytes at 1Mhz
let d: [UInt8] = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]

pi.sendData(d, frequencyHz: 1_000_000)

// Now let's create a virtual SPI on pins P0 and P1

let gpios = SwiftyGPIO.GPIOs(for:.RaspberryPi2)
var sclk = gpios[.P0]!
var dnmosi = gpios[.P1]!

var spi = VirtualSPI(dataGPIO:dnmosi,clockGPIO:sclk) 
pi.sendData(d)
 

