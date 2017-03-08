//Remove this import if you are compiling manually with switfc
import SwiftyGPIO
 
let spis = SwiftyGPIO.hardwareSPIs(for:.RaspberryPiPlusZero)
var spi = spis?[0]

pi.sendByte(UInt8(truncatingBitPattern:0x9F))
