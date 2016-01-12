![SwiftyGPIO](https://github.com/uraimo/SwiftyGPIO/raw/master/logo.png)

**A Swift library to interact with Linux GPIOs, turn on your leds!**

<p>
<img src="https://img.shields.io/badge/os-linux-green.svg?style=flat" alt="Linux-only" />
<a href="https://developer.apple.com/swift"><img src="https://img.shields.io/badge/swift2-compatible-4BC51D.svg?style=flat" alt="Swift 2 compatible" /></a>
<a href="https://raw.githubusercontent.com/uraimo/SwiftyGPIO/master/LICENSE"><img src="http://img.shields.io/badge/license-MIT-blue.svg?style=flat" alt="License: MIT" /></a>
</p>

## Summary

This library provides an easy way to interact with digital GPIOs using Swift on Linux. You'll be able to configure a port attributes (direction,edge,active low) and get/set the current value.

It's built to run **esclusively on Linux ARM Boards** (RaspberryPi, BeagleBone Black, UDOO, Tegra, CHIP, etc...) with accessible GPIOs.

## Supported Boards

Tested:
* Raspberry Pi A,B Revision 1
* $9 C.H.I.P.

Not tested(See #4) but they should work:
* Raspberry Pi A+,B+ (called revision 2)
* Raspberry Pi 2, Pi Zero
                     
## Installation

To use this library, you'll need a Linux ARM board with Swift2.

You can either compile Swift yourself following [these instructions](http://www.housedillon.com/?p=2267) or use precompiled binaries following one of guides from [@hpux735](http://www.housedillon.com/?p=2293) or [@iachievedit](http://dev.iachieved.it/iachievedit/open-source-swift-on-raspberry-pi-2/).

Once done, considering that at the moment the package manager is not available on ARM, you'll need to manually download Sources/SwiftyGPIO.swift: 

    wget https://raw.githubusercontent.com/uraimo/SwiftyGPIO/master/Sources/SwiftyGPIO.swift
    
(For a sample project that uses the package manager retrieving SwiftyGPIO from GitHub check the **Examples** directory)

Once downloaded, in the same directory create an additional file that will contain the code of your application (e.g. main.swift). 

When your code is ready, compile it with:

    swiftc SwiftyGPIO.swift main.swift

The compiler will create a **main** executable.

## Usage

Let's suppose we have a led connected between the GPIO pin P0 and GND and we want to turn it on.

First, to write to that GPIO port P0, we need to create a GPIO object:

    var gp = GPIO(name: "P0",id: 408)
    
The next step is configuring the port direction, that can be either *GPIODirection.IN* or *GPIODirection.OUT*, in this case we'll choose .OUT:

    gp.direction = .OUT

Then we'll change the pin value to the HIGH value "1":
	
    gp.value = 1

That's it, the led will turn on.

To read the value coming in the P0 port, the direction must be configured as *.IN* and the value read from the *value* property:

    gp.direction = .OUT
    let current = gp.value

The other properties available on the GPIO object (edge,active low) refer to the additional attributes of the GPIO that can be configured but you will not need them most of the times. For a detailed description refer to the [kernel documentation](https://www.kernel.org/doc/Documentation/gpio/sysfs.txt)

## Under the hood

SwiftyGPIO interact with GPIOs through the sysfs file-based interface described [here](https://www.kernel.org/doc/Documentation/gpio/sysfs.txt).

The GPIO is exported when a new GPIO struct is created using the provided numerical id, that most of the times is different from the physical id of the pin. SysFS GPIO ids can usually be found in the board documentation, defaults will be provided soon.

At the moment GPIOs are never unexported, let me know if you could find that useful. Multiple exporting when creating an already configured GPIO is not a problem, successive attempts to export a GPIO are simply ignored.

## Examples

At the moment, the library doesn't provide yet defaults for the supported boards.
In this initial implementation you can instantiate explicitly a GPIO struct providing a mnemonic name and the GPIO id of the pin you want to use (check your board documentation).

The following example, built to run on the $9 C.H.I.P., shows the current values of GPIO0(sysfs id 408) attributes, changes direction and value and then shows again a recap of the attributes:

```Swift
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
```

This second example makes a led blink with a frequency of 150ms:

```Swift
import Glibc

let id = 408
var gp01 = GPIO(name: "P0",id: 408)
gp01.direction = .OUT
repeat{
	gp01.value = (gp01.value == 0) ? 1 : 0
	usleep(150*1000)
}while(true) 
```

## TODO

- [x] Create Package.swift
- [x] Basic example w/ package import
- [ ] Add GPIOs default configurations for supported boards
- [ ] Refactoring

