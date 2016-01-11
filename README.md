![SwiftyGPIO](https://github.com/uraimo/SwiftyGPIO/raw/master/logo.png)

**A Swift library to interact with Linux GPIOs(SysFS), turn on your leds!**

<p>
<img src="https://img.shields.io/badge/os-linux-green.svg?style=flat" alt="Linux-only" />
<a href="https://developer.apple.com/swift"><img src="https://img.shields.io/badge/swift2-compatible-4BC51D.svg?style=flat" alt="Swift 2 compatible" /></a>
<a href="https://raw.githubusercontent.com/uraimo/SwiftyGPIO/master/LICENSE"><img src="http://img.shields.io/badge/license-MIT-blue.svg?style=flat" alt="License: MIT" /></a>
</p>


Built to be used esclusively on **Linux ARM Boards** with GPIOs (RaspberryPi, BeagleBone, Tegra, CHIP, etc...)
                     
## Installation

To use this library, you'll need a Linux ARM board with Swift2.

You can either compile it yourself following [these instructions](http://www.housedillon.com/?p=2267) or use precompiled binaries following one of guides from [@hpux735](http://www.housedillon.com/?p=2293) or [@iachievedit](http://dev.iachieved.it/iachievedit/open-source-swift-on-raspberry-pi-2/).

Once done, considering that at the moment the package manager is not available on ARM, you'll need to manually download Sources/SwiftyGPIO.swift: 

    wget https://raw.githubusercontent.com/uraimo/SwiftyGPIO/master/Sources/SwiftyGPIO.swift
    
For a sample project that uses the package manager retrieving SwiftyGPIO from GitHub check the **Examples** directory.

In the same directory create and additional file that will contain the code of your application (e.g. main.swift), and once done compile with:

    swiftc SwiftyGPIO.swift main.swift

The compiler will create a **main** binary you can run.

## Examples

At the moment, the library doesn't provide yet defaults for the supported boards.
In this initial implementation you can instantiate explicitly a GPIO providing a mnemonic name and the GPIO id of the pin you want to use (check your board documentation).

The following example shows the current values of GPIO0 attributes, changes direction and value and then shows again a recap of the attributes:

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

