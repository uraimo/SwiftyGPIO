import Glibc
import SwiftyGPIO //Remove this import if you are compiling manually with switfc
 
let pwms = SwiftyGPIO.hardwarePWMs(for:.RaspberryPi2)!
let pwm = (pwms[0]?[.P18])!

print ("Executing different PWM signals for 20 sec each")
pwm.initPWM()

print("PWM from GPIO18 with 500ns period and 50% duty cycle")
pwm.startPWM(period: 500, duty: 50)
sleep(20)
pwm.stopPWM()

print("PWM from GPIO18 with 1250ns period and 25% duty cycle (WS2812B 0 value)")
pwm.startPWM(period: 1250, duty: 28)
sleep(20)
pwm.stopPWM()

print("PWM from GPIO18 with 50ms period and 50% duty cycle")
pwm.startPWM(period:50_000_000, duty: 50)
sleep(20)
pwm.stopPWM()
