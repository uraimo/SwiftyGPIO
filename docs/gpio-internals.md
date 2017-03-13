## GPIO Internals

SwiftyGPIO interact with GPIOs through memory mapped gpio registers (if available, when sending data) and the sysfs file-based interface described [here](https://www.kernel.org/doc/Documentation/gpio/sysfs.txt).

The GPIO is exported the first time one of the GPIO methods is invoked, using the GPIO id provided during the creation of the object (either provided manually or from the defaults). Most of the times that id will be different from the physical id of the pin. SysFS GPIO ids can usually be found in the board documentation, we provide a few presets for tested boards (do you have the complete list of ids for an unsupported board and want to help? Cool! Consider opening a PR).

At the moment GPIOs are never unexported, let me know if you could find that useful. Multiple exporting when creating an already configured GPIO is not a problem, successive attempts to export a GPIO are simply ignored.

Regarding the actual sending of the data, when available SwiftyGPIO will use a mmapped registers interface (max pulse when used directly on a Rpi2 12Mhz) and will use a fallback sysfs interface when no mmapped implementation exists (max pulse when used directly on a Rpi2 4Khz).

At the moment the memory mapped interface is only available on all Raspberries.