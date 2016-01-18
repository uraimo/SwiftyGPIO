![SwiftyGPIO](https://github.com/uraimo/SwiftyGPIO/raw/master/logo.png)

**A Swift library to interact with Linux GPIOs, turn on your leds and more!**

<p>
<img src="https://img.shields.io/badge/os-linux-green.svg?style=flat" alt="Linux-only" />
<a href="https://developer.apple.com/swift"><img src="https://img.shields.io/badge/swift2-compatible-4BC51D.svg?style=flat" alt="Swift 2 compatible" /></a>
<a href="https://raw.githubusercontent.com/uraimo/SwiftyGPIO/master/LICENSE"><img src="http://img.shields.io/badge/license-MIT-blue.svg?style=flat" alt="License: MIT" /></a>
<a href="https://travis-ci.org/uraimo/SwiftyGPIO"><img src="https://api.travis-ci.org/uraimo/SwiftyGPIO.svg" alt="TravisCI"></a>
</p>

## Summary

This library provides an easy way to interact with digital GPIOs using Swift on Linux. You'll be able to configure a port attributes (direction,edge,active low) and read/write the current value.

It's built to run **exclusively on Linux ARM Boards** (RaspberryPi, BeagleBone Black, UDOO, Tegra, CHIP, etc...) with accessible GPIOs.

**Do you own an unsupported/untested board and would like to help? Check out issue  [#10](https://github.com/uraimo/SwiftyGPIO/issues/10)**

## Supported Boards

Tested:
* C.H.I.P.
* BeagleBone Black
* Raspberry Pi 2

Not tested but they should work(basically everything that has an ARMv7 and ubuntu 14.04):
* UDOOs
* OLinuXinos
* ODROIDs
* Cubieboards
* Tegra Jetson TK1

Not tested, Swift is not yet available for ARM6 boards:
* Raspberry Pi A,B Revision 1
* Raspberry Pi A,B Revision 2
* Raspberry Pi A+, B+, Pi Zero
                     
## Installation

To use this library, you'll need a Linux ARM board with Swift 2.2.

You can either compile Swift yourself following [these instructions](http://www.housedillon.com/?p=2267) or use precompiled binaries following one of guides from [@hpux735](http://www.housedillon.com/?p=2293) or [@iachievedit](http://dev.iachieved.it/iachievedit/open-source-swift-on-raspberry-pi-2/) if you have a Raspberry Pi 2, BeagleBoneBlack, C.H.I.P. or one of the other ARMv7 boards.

Once done, considering that at the moment the package manager is not available on ARM, you'll need to manually download Sources/SwiftyGPIO.swift: 

    wget https://raw.githubusercontent.com/uraimo/SwiftyGPIO/master/Sources/SwiftyGPIO.swift
    
(For sample projects that uses the package manager retrieving SwiftyGPIO from GitHub check the **Examples** directory)

Once downloaded, in the same directory create an additional file that will contain the code of your application (e.g. main.swift). 

When your code is ready, compile it with:

    swiftc SwiftyGPIO.swift main.swift

The compiler will create a **main** executable.

## Usage

Let's suppose we are using a CHIP board and have a led connected between the GPIO pin P0 and GND and we want to turn it on.

First, we need to retrieve the list of GPIOs available on the board and get a reference to the one we want to modify:

```swift
let gpios = SwiftyGPIO.getGPIOsForBoard(.CHIP)
var gp = gpios[.P0]!
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
var gp = GPIO(name: "P0",id: 408)  // User defined name and GPIO Id
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

Now, suppose we have a switch connected to P0 instead, to read the value coming in the P0 port, the direction must be configured as *.IN* and the value can be read from the *value* property:

```swift
gp.direction = .IN
let current = gp.value
```

The other properties available on the GPIO object (edge,active low) refer to the additional attributes of the GPIO that can be configured but you will not need them most of the times. For a detailed description refer to the [kernel documentation](https://www.kernel.org/doc/Documentation/gpio/sysfs.txt)

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

Other examples are available in the *Examples* directory.

## TODO

- [x] Create Package.swift
- [x] Basic example w/ package import
- [x] Add GPIOs default configurations for supported boards
- [x] Testing on the BeagleBone Black
- [x] Software SPI via GPIOs
- [x] Add BeagleBone Black pinout defaults
- [ ] Support for additional GPIOs on separate header for RasPi Rev 2 boards?
- [ ] Add Tegra TK1 when Swift support confirmed
- [ ] Add UDOOs when Swift support confirmed
- [ ] Testing on the Raspberries 1
- [ ] SysFS PWN and/or software PWM?
- [ ] Support for hardware SPI
- [ ] Support for external ADCs or support for platform-specific ADC drivers?
- [ ] Refactoring
