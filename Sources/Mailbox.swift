/*
   SwiftyGPIO

   Copyright (c) 2016 Umberto Raimondi and contributors.
   Licensed under the MIT license, as follows:

   Permission is hereby granted, free of charge, to any person obtaining a copy
   of this software and associated documentation files (the "Software"), to deal
   in the Software without restriction, including without limitation the rights
   to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
   copies of the Software, and to permit persons to whom the Software is
   furnished to do so, subject to the following conditions:

   The above copyright notice and this permission notice shall be included in all
   copies or substantial portions of the Software.

   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
   OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
   SOFTWARE.)

   ------------------------------------------------------------------------------

   The RaspberryPi uses a mechanism based on the mailbox primitive to allow
   communication between subsystems.
   Different subsystems like the ARM CPU, VideoCore GPU, the power management
   unit, leds, etc... can communicate sending requestes to each other using the
   mailboxes as request routers. The CPU could for example require information 
   about the power status sending a request with the correct request tag or ask 
   to the GPU to execute some instruction or other tasks.

   In this case, the GPU is used to allocate a contiguous block of memory in 
   the secton of the global memory controlled by it. This memory will not be cached
   by the L1 cache of the CPU to get around issues with cache flushing.

   Reference implementation for mailbox and other kernel components:
   https://github.com/raspberrypi/firmware

   More info on RaspberryPi's mailboxes:
   https://github.com/raspberrypi/firmware/wiki/Mailboxes
   https://github.com/raspberrypi/firmware/wiki/Mailbox-property-interface

   Thanks to Jeremy Garff and Richard Hirst, for their great work on the WS281x 
   library, from which I took more than a few ideas and used to verify that the bit 
   pattern PWM signal generator was working as expected.

   https://github.com/jgarff/rpi_ws281x
*/

#if os(Linux)
    import Glibc
#else
    import Darwin.C
#endif

// We use the mailbox interface to request memory from the VideoCore.
//
// This lets us request one physically contiguous chunk, find its
// physical address, and map it 'uncached' so that writes from this
// code are immediately visible to the DMA controller.  This struct
// holds data relevant to the mailbox interface.
//
public struct MailBox {

    private let IOCTL_MBOX_PROPERTY: UInt = 0xc0046400 // _IOWR(100, 0, char *)

    private var mailboxFd: Int32 = 0
    private var memRef: UInt32 = 0
    public var size: Int = 0
    private(set) var baseBusAddress: UInt32 = 0
    private(set) var baseVirtualAddress: UnsafeMutableRawPointer! = nil

    /// Converts a classic address to a bus address usable by the DMA
    public func virtualTobaseBusAddress(_ pointer: UnsafeMutableRawPointer) -> UInt {
        let offset = baseVirtualAddress.distance(to: pointer)
        return UInt(baseBusAddress + UInt32(offset))
    }

    /// Initializes a new mailbox with size and an handle (-1 per-session handle)
    public init?(handle: Int = -1, size: Int, isRaspi2: Bool = true) {
        let MEM_FLAG_L1_NONALLOCATING = isRaspi2 ? 0x4 : 0xC

        mailboxFd = Int32(handle)
        self.size = size

        // MEM_FLAG_L1_NONALLOCATING  = (MEM_FLAG_DIRECT | MEM_FLAG_COHERENT) --> Allocating in L2 
        memRef = memAlloc(align: PAGE_SIZE, flags: MEM_FLAG_L1_NONALLOCATING)
        if memRef < 0 {
           fatalError("Couldn't allocate mailbox")
        }

        baseBusAddress = memLock()
        if baseBusAddress == ~0 {
           memFree()
           fatalError("Couldn't lock mailbox")
        }
        baseVirtualAddress = mapmem(UInt(baseBusAddress) & ~0xC0000000, size: size)
    }

    public mutating func cleanup() {
        unmapmem(baseVirtualAddress, size: size)
        memUnlock()
        memFree()
        if mailboxFd >= 0 {
            mailboxClose(mailboxFd)
        }
    }

    /// MARK: Memory mapping methods

    /// Map the requested address with page alignement
    private func mapmem(_ address: UInt, size: Int) -> UnsafeMutableRawPointer {
        var mem_fd: Int32 = 0
        let offset = Int(address) % PAGE_SIZE
        let ad = Int(address) - offset
        let size = size + offset

        //Try to open one of the mem devices
        mem_fd = open("/dev/mem", O_RDWR | O_SYNC)
        guard mem_fd > 0 else {
            fatalError("Can't open /dev/mem , use sudo!")
        }

        let base_map = mmap(
            nil,                 //Any adddress in our space will do
            size,                //Map length
            PROT_READ|PROT_WRITE,// Enable reading & writting to mapped memory
            MAP_SHARED,          //Shared with other processes
            mem_fd,              //File to map
            off_t(ad)            //Address
            )!

        close(mem_fd)

        let basePointer = base_map.assumingMemoryBound(to: UInt.self)
        if basePointer.pointee == UInt(bitPattern: -1) {    //MAP_FAILED not available, but its value is (void*)-1
            print("mapmem error: " + "\(basePointer)")
            abort()
        }

        return UnsafeMutableRawPointer(basePointer) + offset
    }

    /// Unmap the page aligned pointer
    private func unmapmem(_ pointer: UnsafeMutableRawPointer, size: Int) {
        let address = UInt(bitPattern: pointer)
        let offset = address % UInt(PAGE_SIZE)
        let alignedAddress = pointer - Int(offset)
        let res = munmap(alignedAddress, size)
        guard res == 0 else {
            fatalError("Couldn't unmapmem: \(alignedAddress)")
        }
    }

    /// MARK: Mailbox methods

    /// Open the mailbox
    private func mailboxOpen() -> Int32 {
        var file_desc: Int32
        var filename: String

        // Kernel 4.0+
        file_desc = open("/dev/vcio", 0)
        if file_desc >= 0 {
            return file_desc
        }

        // Older kernels

        // open a char device file used for communicating with kernel mbox driver
        filename = "/tmp/swifty-mailbox-" + String(getpid())
        unlink(filename)

        //makedev is a macro not imported by Swift that resolves to gnu_dev_makedev
        if mknod(filename, S_IFCHR|0600, gnu_dev_makedev(100, 0)) < 0 {
            perror("Failed to create mailbox device\n")
            return -1
        }

        file_desc = open(filename, 0)
        if file_desc < 0 {
            perror("Can't open device file\n")
            unlink(filename)
            return -1
        }
        unlink(filename)

        return file_desc
    }

    /// Closes the mailbox
    private func mailboxClose(_ fileDesc: Int32) {
        close(fileDesc)
    }

    /// Perform and ioctl ont he mailbox, if the mailbox is not already open, it opens it
    @discardableResult
    private func mailboxSetProperty(buf: UnsafeMutableRawPointer) -> Int32 {
        var fd: Int32 = mailboxFd
        var ret_val: Int32 = -1

        // If the global mailbox fd is -1, open/close the mailbox for this session
        if mailboxFd < 0 {
            fd = mailboxOpen()
        }

        if fd >= 0 {
            ret_val = ioctl(fd, IOCTL_MBOX_PROPERTY, buf)

            if ret_val < 0 {
                fatalError("ioctl on mailbox failed!")
            }

            // Close temporary handle
            if mailboxFd < 0 {
                mailboxClose(fd)
            }
        }

        return ret_val
    }

    /// MARK: Mailbox Memory methods

    /// Allocates contiguous memory on the GPU. size and alignment are in bytes.
    private func memAlloc(align: Int, flags: Int) -> UInt32 {
        var i = 0
        var p = [UInt32](repeating:0x0, count:32)

        p[i] = 0                  // Actual size, to be set at the end
        i += 1
        p[i] = 0x00000000         // Process request
        i += 1
        p[i] = 0x3000c            // Tag id
        i += 1
        p[i] = 12                 // Buffer size
        i += 1
        p[i] = 12                 // Data size
        i += 1
        p[i] = UInt32(self.size)  // Memory block size
        i += 1
        p[i] = UInt32(align)      // Alignment
        i += 1
        p[i] = UInt32(flags)      // Should be MEM_FLAG_L1_NONALLOCATING
        i += 1
        p[i] = 0x00000000         // End tag
        i += 1
        p[0] = UInt32(i * MemoryLayout<UInt32>.size)  // Actual size

        if mailboxSetProperty(buf: &p) < 0 {
            return 0
        } else {
            return p[5]           // Handle
        }
    }

    /// Free the memory buffer. 
    private func memFree() {
        var i = 0
        var p = [UInt32](repeating:0x0, count:32)

        p[i] = 0            // Actual size, to be set at the end
        i += 1
        p[i] = 0x00000000   // Process request
        i += 1
        p[i] = 0x3000f      // Tag id
        i += 1
        p[i] = 4            // Buffer size
        i += 1
        p[i] = 4            // Data size
        i += 1
        p[i] = self.memRef  // Handle
        i += 1
        p[i] = 0x00000000   // End tag
        i += 1
        p[0] = UInt32(i * MemoryLayout<UInt32>.size)  // Actual size

        mailboxSetProperty(buf: &p)
    }

    /// Lock buffer in place, and return a bus address. Must be done before memory can be accessed.
    private func memLock() -> UInt32 {
        var i = 0
        var p = [UInt32](repeating:0x0, count:32)

        p[i] = 0            // Actual size, to be set at the end
        i += 1
        p[i] = 0x00000000   // Process request
        i += 1
        p[i] = 0x3000d      // Tag id
        i += 1
        p[i] = 4            // Buffer size
        i += 1
        p[i] = 4            // Data size
        i += 1
        p[i] = self.memRef  // Handle
        i += 1
        p[i] = 0x00000000   // End tag
        i += 1
        p[0] = UInt32(i * MemoryLayout<UInt32>.size)  // Actual size

        if mailboxSetProperty(buf: &p) < 0 {
            return ~0
        } else {
            return p[5]     // bus address of locked memory block
        }
    }

    /// Unlock buffer. It retains contents, but may move. Needs to be locked before next use. 
    private func memUnlock() {
        var i = 0
        var p = [UInt32](repeating:0x0, count:32)

        p[i] = 0            // Actual size, to be set at the end
        i += 1
        p[i] = 0x00000000   // Process request
        i += 1
        p[i] = 0x3000e      // Tag id
        i += 1
        p[i] = 4            // Buffer size
        i += 1
        p[i] = 4            // Data size
        i += 1
        p[i] = self.memRef  // Handle
        i += 1
        p[i] = 0x00000000   // End tag
        i += 1
        p[0] = UInt32(i * MemoryLayout<UInt32>.size)  // Actual size

        mailboxSetProperty(buf: &p)
    }
}

// MARK: - Darwin / Xcode Support
#if os(OSX)
    private var O_SYNC: CInt { fatalError("Linux only") }
    
    func gnu_dev_makedev(_ maj: UInt, _ min: UInt) -> Int32 {
        fatalError("Linux only")
    }
#endif
