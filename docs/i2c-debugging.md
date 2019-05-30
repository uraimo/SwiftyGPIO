# I2C Debugging

To debug the i2c connection, enable i2c tracing first to obtain a log of everything that is being sent/received from the sensor:

```
sudo sh -c "echo 1 >/sys/kernel/debug/tracing/events/i2c/enable"
sudo sh -c "adapter_nr==1 >/sys/kernel/debug/tracing/events/i2c/filter"
```
_(To disable i2c tracing once you're done, run: `sudo sh -c "echo 0 >/sys/kernel/debug/tracing/events/i2c/enable"`)_

You'll be able to print the i2c log with `sudo cat /sys/kernel/debug/tracing/trace`.

For the i2c scanning command `sudo i2cdetect -y 1` the log would look something like this:

```
       ...
       I2CDetect-27461 [003] ....  2427.402606: i2c_read: i2c-1 #0 a=048 f=0001 l=1
       I2CDetect-27460 [003] ....  2426.482952: i2c_reply: i2c-1 #0 a=048 f=0001 l=1 [15]
       I2CDetect-27460 [003] ....  2426.482954: i2c_result: i2c-1 n=1 ret=1
       I2CDetect-27460 [003] ....  2426.483009: i2c_read: i2c-1 #0 a=049 f=0001 l=1
       I2CDetect-27460 [003] ....  2426.483218: i2c_result: i2c-1 n=0 ret=-121
       ...
```

For each exchange you'll find 2 or 3 lines, a `read` or `write` attempt, an optional `reply` for the response from the device and a `result` line with a return code and the size of the response.


```
       I2CDetect-nnnnn [nnn] ....  xxxx.xxxxxx: i2c_read:  i2c-<adapter-number> #<message-array-index> a=<addr> l=<datalen>
       I2CDetect-nnnnn [nnn] ....  xxxx.xxxxxx: i2c_reply: i2c-<adapter-number> #<message-array-index> a=<addr> f=<flags> l=<datalen> [<data-transferred>]
       I2CDetect-nnnnn [nnn] ....  xxxx.xxxxxx: i2c_result: i2c-<adapter-number> n=<message-array-size> ret=<result>
``` 

Taking a look at the first example from `i2cdetect`, we can see that the read attempt for `0x48` was successful, since we got `[15]` back and the return code was `1`.

With `0x49` we weren't so lucky, no one responded and the system logged this with an error code equal to `-121` with 0 bytes transfered.




For more information on I2C:

http://www.circuitbasics.com/basics-of-the-i2c-communication-protocol/

https://electronics.stackexchange.com/questions/151413/how-to-display-i2c-address-in-hex

https://manpages.ubuntu.com/manpages/xenial/man8/i2cdetect.8.html
