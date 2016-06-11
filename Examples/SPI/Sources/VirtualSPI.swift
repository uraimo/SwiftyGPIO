//Remove this import if you are compiling manually with switfc
import SwiftyGPIO
 

let gpios = SwiftyGPIO.GPIOs(for:.CHIP)
var sclk = gpios[.P0]!
var dnmosi = gpios[.P1]!

var spi = VirtualSPI(dataGPIO:dnmosi,clockGPIO:sclk) 

pi.sendByte(UInt8(truncatingBitPattern:0x9F))
