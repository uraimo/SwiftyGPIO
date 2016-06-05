let gpios = SwiftyGPIO.getGPIOsForBoard(.CHIP)
var sclk = gpios[.P0]!
var dnmosi = gpios[.P1]!

var spi = VirtualSPI(dataGPIO:dnmosi,clockGPIO:sclk) 

pi.sendByte(UInt8(truncatingBitPattern:0x9F))
