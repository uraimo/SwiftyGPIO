/*
 SwiftyGPIO

 Copyright (c) 2017 William Dillon; Racepoint Energy LLC.
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
 */
#if os(Linux)
    import Glibc
#else
    import Darwin.C
#endif

import Foundation

/// Hardware ADC via SysFS
public final class SysFSADC: ADCInterface {
    let adcPath: String
    public let id: Int
    var fd: Int32 = -1

    public init(adcPath: String, id: Int) {
        self.adcPath = adcPath
        self.id = id
    }

    public func getSample() throws -> Int {
        if fd <= 0 { self.openADC() }

        guard fd > 0 else {
            throw ADCError.fileError
        }

        var returnData = [CChar].init(repeating: 0, count: 16)
        let count = read(fd, &returnData, 16)

        guard count > 0 else {
            print("Unable to read from ADC: \(String(describing: strerror(errno)))")
            self.closeADC()
            throw ADCError.readError
        }

        guard let sampleString = String(cString: returnData, encoding: .utf8) else {
            self.closeADC()
            throw ADCError.conversionError
        }

        if let sampleInt = Int(sampleString.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)) {
            self.closeADC()
            return sampleInt
        } else {
            self.closeADC()
            throw ADCError.conversionError
        }

    }

    deinit {
        if fd != -1 {
            closeADC()
        }
    }

    private func openADC() {
        let fd  = open(adcPath, O_RDONLY)
        self.fd = fd

        if fd < 0 {
            fatalError("Couldn't open ADC device: \(String(describing: strerror(errno)))")
        }
    }

    private func closeADC() {
        close(fd)
        fd = -1
    }

}

// MARK: - Darwin / Xcode Support
#if os(OSX) || os(iOS)
    private var O_SYNC: CInt { fatalError("Linux only") }
#endif
