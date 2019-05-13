//Remove this import if you are compiling manually with switfc
import SwiftyGPIO
 
let gpios = SwiftyGPIO.GPIOs(for:.CHIP)

// Let's create a virtual SPI
//
// GPIO0 = MOSI -> SPI output, connect to the device input
// GPIO1 = SLCK -> Connect to the clk pin
// Connect CS at 1
 
var sclk = gpios[.P0]!
var dnmosi = gpios[.P1]!

var spi = VirtualSPI(dataGPIO:dnmosi,clockGPIO:sclk) 

// Send some bytes at 1Mhz
let d: [UInt8] = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]
spi.sendData(d)
 
