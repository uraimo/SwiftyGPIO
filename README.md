![SwiftyGPIO](https://github.com/uraimo/SwiftyGPIO/raw/master/logo.png)

**A Swift library to interact with Linux(SysFS) GPIOs, turn on your leds!**

<p>
<img src="https://img.shields.io/badge/os-linux-green.svg?style=flat" alt="Linux-only" />
<a href="https://developer.apple.com/swift"><img src="https://img.shields.io/badge/swift2-compatible-4BC51D.svg?style=flat" alt="Swift 2 compatible" /></a>
<a href="https://raw.githubusercontent.com/uraimo/SwiftyGPIO/master/LICENSE"><img src="http://img.shields.io/badge/license-MIT-blue.svg?style=flat" alt="License: MIT" /></a>
</p>


Built to be used esclusively on Linux ARM Boards with GPIOs (RaspberryPi,BeagleBone,CHIP,etc...)
                     
## Installation

To use this library, you'll need a Linux ARM board with Swift.
You can either compile it yourself following these instructions:

http://www.housedillon.com/?p=2267

or use precompiled binaries following one of these guides: 

http://www.housedillon.com/?p=2293
http://dev.iachieved.it/iachievedit/open-source-swift-on-raspberry-pi-2/

Once done, considering that at the moment the package manager is not available on ARM, you'll need to download Sources/SwiftyGPIO.swift: 

    wget 

In the same directory create and additional file that will contain the code of your application (e.g. main.swift), and once done compile with:

    swiftc SwiftyGPIO.swift main.swift

The compiler will create a *main* executable.

## Examples

At the moment, the library don't provide yet defaults for the supported boards.
In this initial implementation you can instantiate explicitly a GPIO providing a mnemonic name and the GPIO id of the pin you want to use(check your board reference).

The following example shows the current values of the pin attributes, changes direction and value and then shows again a recap of the attributes:

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

This example makes a led blink with a frequency of 150ms:

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

