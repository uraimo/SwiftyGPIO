![SwiftyGPIO](https://github.com/uraimo/SwiftyGPIO/raw/master/logo.png)

**A Swift library to interact with Linux GPIOs, turn on your leds and more!**

<p>
<img src="https://img.shields.io/badge/os-linux-green.svg?style=flat" alt="Linux-only" />
<a href="https://developer.apple.com/swift"><img src="https://img.shields.io/badge/swift2-compatible-4BC51D.svg?style=flat" alt="Swift 2 compatible" /></a>
<a href="https://raw.githubusercontent.com/uraimo/SwiftyGPIO/master/LICENSE"><img src="http://img.shields.io/badge/license-MIT-blue.svg?style=flat" alt="License: MIT" /></a>
<a href="https://travis-ci.org/uraimo/SwiftyGPIO"><img src="https://api.travis-ci.org/uraimo/SwiftyGPIO.svg" alt="Travis CI"></a>
</p>

## Summary

This library provides an easy way to interact with digital GPIOs using Swift on Linux. You'll be able to configure a port attributes (direction,edge,active low) and read/write the current value.

It's built to run **exclusively on Linux ARM Boards** (RaspberryPi, BeagleBone Black, UDOO, Tegra, CHIP, etc...) with accessible GPIOs.

**Do you own an unsupported/untested board and would like to help? Check out issue  [#10](https://github.com/uraimo/SwiftyGPIO/issues/10)**

## Supported Boards

Tested:
* C.H.I.P.
* BeagleBone Black (Thanks to [@hpux735](https://twitter.com/hpux735))
* Raspberry Pi 2 (Thanks to [@iachievedit](https://twitter.com/iachievedit))
* Raspberry Pi Zero (Thanks to [@MacmeDan](https://twitter.com/MacmeDan))
* Raspberry Pi A,B Revision 1
* Raspberry Pi A,B Revision 2
* Raspberry Pi A+, B+

Not tested but they should work(basically everything that has an ARMv7/Ubuntu14/Raspbian or an ARMv6/Raspbian):
* UDOOs
* OLinuXinos
* ODROIDs
* Cubieboards
* Tegra Jetson TK1

 
## Installation

To use this library, you'll need a Linux ARM(ARMv7 or ARMv6) board with Swift 2.2.

You can either compile Swift yourself following [these instructions](http://www.housedillon.com/?p=2267) or use precompiled binaries following one of guides from [@hpux735](http://www.housedillon.com/?p=2293) or [@iachievedit](http://dev.iachieved.it/iachievedit/open-source-swift-on-raspberry-pi-2/) if you have a Raspberry Pi 2, BeagleBoneBlack, C.H.I.P. or one of the other ARMv7 boards.
If you have a ARMv6 RaspberryPi 1 (A,B,A+,B+) or a Zero, get the precompiled binaries from [here](https://www.uraimo.com/2016/02/10/swift-available-on-armv6-raspberry-1-zero/). 

Once done, considering that at the moment the package manager is not available on ARM, you'll need to manually download Sources/SwiftyGPIO.swift: 

    wget https://raw.githubusercontent.com/uraimo/SwiftyGPIO/master/Sources/SwiftyGPIO.swift
    
(For sample projects that uses the package manager retrieving SwiftyGPIO from GitHub check the **Examples** directory)

Once downloaded, in the same directory create an additional file that will contain the code of your application (e.g. main.swift). 

When your code is ready, compile it with:

    swiftc SwiftyGPIO.swift main.swift

The compiler will create a **main** executable.
As everything interacting with GPIOs via sysfs, if you are not already root, you will need to run that binary with `sudo ./main`.

If you prefer an alternative approach that does not require to use sudo every time check out this [answer on stackoverflow](https://stackoverflow.com/questions/30938991/access-gpio-sys-class-gpio-as-non-root/30940526#30940526).
After following those instruction, remember to add your user (e.g. pi) to the gpio group with `sudo usermod -aG gpio pi` and to reboot so that the changes you made are applied.

## Your First Project: Blinking leds

Joe from iachievedit has written a [fantastic tutorial](http://dev.iachieved.it/iachievedit/raspberry-pi-2-gpio-with-swiftygpio/) that presents a practical example of how to use SwiftyGPIO, if you prefer starting with a real project instead of just reading documentation, check out his tutorial first.

## Usage

Currently, SwiftyGPIO expose GPIOs and SPIs(if not available a bit-banging VirtualSPI can be created), let's see how to use them.

#### GPIOs

Let's suppose we are using a Raspberry 2 board and have a led connected between the GPIO pin P2 (possibly with a resistance of 1k or so) and GND and we want to turn it on.

First, we need to retrieve the list of GPIOs available on the board and get a reference to the one we want to modify:

```swift
let gpios = SwiftyGPIO.getGPIOsForBoard(.RaspberryPiPlus2Zero)
var gp = gpios[.P2]!
```

The following are the possible values for the predefined boards:
    
* .RaspberryPiRev1 (Pi A,B Revision 1, pre-2012, 26 pin header)
* .RaspberryPiRev2 (Pi A,B Revision 2, post-2012, 26 pin header) 
* .RaspberryPiPlus2Zero (Raspberry Pi A+ and B+, Raspberry 2, Raspberry Zero, all with a 40 pin header)
* .BeagleBoneBlack (BeagleBone Black)
* .CHIP (the $9 C.H.I.P. computer).

The map returned by *getGPIOsForBoard* contains all the GPIOs of a specific board as described by [these diagrams](https://github.com/uraimo/SwiftyGPIO/wiki/GPIO-Pinout). 

Alternatively, if our board is not supported, each single GPIO object can be instantiated manually, using its SysFS GPIO Id:

```swift
var gp = GPIO(name: "P2",id: 2)  // User defined name and GPIO Id
```
    
The next step is configuring the port direction, that can be either *GPIODirection.IN* or *GPIODirection.OUT*, in this case we'll choose .OUT:

```swift
gp.direction = .OUT
```

Then we'll change the pin value to the HIGH value "1":

```swift
gp.value = 1
```

That's it, the led will turn on.

Now, suppose we have a switch connected to P2 instead, to read the value coming in the P2 port, the direction must be configured as *.IN* and the value can be read from the *value* property:

```swift
gp.direction = .IN
let current = gp.value
```

The other properties available on the GPIO object (edge,active low) refer to the additional attributes of the GPIO that can be configured but you will not need them most of the times. For a detailed description refer to the [kernel documentation](https://www.kernel.org/doc/Documentation/gpio/sysfs.txt)

#### SPIs

If your board has SPI connections and SwiftyGPIO has them among its presets, a list of the available SPIs can be retrieved invoking `getHardwareSPIsForBoard` with one of the predefined boards.

On RaspberryPi and other boards the SPI SysFS interface is not enabled by default, check out the setup guide on [wiki](https://github.com/uraimo/SwiftyGPIO/wiki/Enabling-SPI-on-RaspberryPi-and-others).

Let's see some examples using a Raspberry2 that has one bidirectional SPI, managed by SwiftyGPIO as two mono-directional SPIObjects:
 
```swift
let spis = SwiftyGPIO.getHardwareSPIsForBoard(.RaspberryPiPlus2Zero)
var spi = spis?[0]
```

The first item returned is the output channel and this can be verified invoking the method `isOut` on the `SPIObject`.

Alternatively, we can create a software SPI using two GPIOs, one that wil serve as clock pin and the other will be used to send the actual data. This kind of bit-banging SPI is way slower than the hardware one, so, the recommended approach is to use hardware SPIs when available.

To create a software SPI, just retrieve two pins and create a `VirtualSPI` object:
```swift
let gpios = SwiftyGPIO.getGPIOsForBoard(.RaspberryPiPlus2Zero)
var sclk = gpios[.P2]!
var dnmosi = gpios[.P3]!
var spi = VirtualSPI(dataGPIO:dnmosi,clockGPIO:sclk) 
```

Both objects implement the same `SPIObject` protocol and so provide the same methods.
To distinguish between hardware and software SPIObjects, use the `isHardware` method.

To send one or more byte over a SPI, use the `sendData` method.
In its simplest form it just needs an array of UInt8 as parameter:

```swift
spi?.sendData([UInt(42)])
```

But for software SPIs (for now, these values are ignored when using a hardware SPI) you can also specify the preferred byte ordering (MSB,LSB) and the delay between two succesive bits (clock width):

```swift
spi?.sendData([UInt(42)], order:.LSBFIRST, clockDelayUsec:1000)
```


## Under the hood

SwiftyGPIO interact with GPIOs through the sysfs file-based interface described [here](https://www.kernel.org/doc/Documentation/gpio/sysfs.txt).

The GPIO is exported the first time one of the GPIO methods is invoked, using the GPIO id provided during the creation of the object (either provided manually or from the defaults). Most of the times that id will be different from the physical id of the pin. SysFS GPIO ids can usually be found in the board documentation, we provide a few presets for tested boards (do you have the complete list of ids for an unsupported board and want to help? Cool! Consider opening a PR).

At the moment GPIOs are never unexported, let me know if you could find that useful. Multiple exporting when creating an already configured GPIO is not a problem, successive attempts to export a GPIO are simply ignored.

## Examples

The following example, built to run on the $9 C.H.I.P., shows the current value of all the GPIO0 attributes, changes direction and value and then shows again a recap of the attributes:

```Swift
let gpios = SwiftyGPIO.getGPIOsForBoard(.CHIP)
var gp0 = gpios[.P0]!
print("Current Status")
print("Direction: "+gp0.direction.rawValue)
print("Edge: "+gp0.edge.rawValue)
print("Active Low: "+String(gp0.activeLow))
print("Value: "+String(gp0.value))

gp0.direction = .OUT
gp0.value = 1

print("New Status")
print("Direction: "+gp0.direction.rawValue)
print("Edge: "+gp0.edge.rawValue)
print("Active Low: "+String(gp0.activeLow))
print("Value: "+String(gp0.value))
```

This second example makes a led blink with a frequency of 150ms:

```Swift
import Glibc

let gpios = SwiftyGPIO.getGPIOsForBoard(.CHIP)
var gp0 = gpios[.P0]!
gp0.direction = .OUT

repeat{
	gp0.value = (gp0.value == 0) ? 1 : 0
	usleep(150*1000)
}while(true) 
```

We can't test the hardware SPI with the CHIP but SwiftyGPIO also provide a bit banging software implementation of a SPI interface, you just need two GPIOs to initialize it:

```Swift
let gpios = SwiftyGPIO.getGPIOsForBoard(.CHIP)
var sclk = gpios[.P0]!
var dnmosi = gpios[.P1]!

var spi = VirtualSPI(dataGPIO:dnmosi,clockGPIO:sclk) 

pi.sendData([UInt8(truncatingBitPattern:0x9F)]) 
```

Notice that we are converting the 0x9F `Int` using the constructor `UInt8(truncatingBitPattern:)`, that in this case it's not actually needed, but it's recommended for every user-provided or calculated integer because Swift does not support implicit truncation for conversion to smaller integer types, it will just crash if the `Int` you are trying to convert does not fit in a `UInt8`.

Other examples for differen boards are available in the *Examples* directory.

## Projects that use SwiftyGPIO

* [Nokia5110(PCD8544) LCD Library](http://github.com/uraimo/5110lcd_pcd8544.swift) - Show text and graphics on a Nokia 3110/5110 LCD display.
* {Your project or library here!!}

## TODO

- [x] Create Package.swift
- [x] Basic example w/ package import
- [x] Add GPIOs default configurations for supported boards
- [x] Testing on the BeagleBone Black
- [x] Software SPI via GPIOs
- [x] Add BeagleBone Black pinout defaults
- [x] Support for hardware SPI
- [x] Testing on the Raspberries 1
- [ ] Support for additional GPIOs on separate header for RasPi Rev 2 boards?
- [ ] Add Tegra TK1 when Swift support confirmed
- [ ] Add UDOOs when Swift support confirmed
- [ ] SysFS PWM and/or software PWM and/or ServoBlaster?
- [ ] Block/Function execution on gpio interrupts
- [ ] Support for external ADCs or support for platform-specific ADC drivers?
- [ ] Refactoring
