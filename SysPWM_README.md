### SysPWM

PWM output signals can be used to drive servo motors, RGB leds and other devices, or more in general, to approximate analog output values (e.g. generate values as if they where *between* 0V and 3.3V) when you only have digital GPIO ports.

Before using this class you must enable the sysFS based PWM module by loading one of two overlays at boot time. This is done by adding a line to your `/boot/config.txt` file that looks like:

```
dtoverlay=pwm-2chan,pin=12,func=4,pin2=13,func2=4
```

The `pin` and `func` paramaters are used to set the pin used by the PWM channel.

For channel 0 the appropriate values are: `pin=12,func=4` or `pin=18,func=2`.

For channel 1 the appropriate values are: `pin1=13,func2=4` or `pin2=19,func2=2`.

The pins 18 and 19 are used by default if the relevant paramters are omited.
  
In order to use these functions the user running the code must be a member of the "gpio" group or be the superuser (root). The user "pi" is a member of the "gpio" group by default.



If your board has PWM ports and is supported (at the moment only RaspberryPi boards), retrieve the available `RaspberrySysPWM` objects with the `sysPWMs` factory method:

```swift
let pwms = SwiftyGPIO.sysPWMs(for:.RaspberryPi3)!
let pwm = pwms[0]!
```

This method returns all the PWM channels supported by your board.


Once you've retrieved the `RaspberrySysPWM` for the port you plan to use you need to initialize it to select the PWM function. On this kind of boards, each port can have more than one function (simple GPIO, SPI, PWM, etc...) and you can choose the function you want configuring dedicated registers.

This function takes an optional parameter `polarity:` that can be set to `.normal` or `.inverse`.  

> Warning: due to an apparent bug in the overlay itself, the inverse polarity does not currently work.

```swift
pwm.initPWM()
```

To start the PWM signal call `startPWM` providing the period in nanoseconds (if you have the frequency convert it with 1/frequency) and the duty cycle as a percentage:

```swift
print("PWM from GPIO18 with 500ns period and 50% duty cycle")
pwm.startPWM(period: 500, duty: 50)
```

Once you call this method, the PWM subsystem of the ARM SoC will start generating the signal, you don't need to do anything else and your program will continue to execute, you could insert a `sleep(seconds)` here if you just want to wait.

And when you want to stop the PWM signal call the `stopPWM()` method:

```swift
pwm.stopPWM()
```

If you want to change the signal being generated, you don't need to stop the previous one, just call `startPWM` with different parameters.
