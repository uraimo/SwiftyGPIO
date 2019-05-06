/*
 SwiftyGPIO

 Copyright (c) 2016 Umberto Raimondi
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

public struct SwiftyGPIO {

    public static func GPIOs(for board: SupportedBoard) -> [GPIOName: GPIO] {
        switch board {
        case .RaspberryPiRev1:
            return GPIORPIRev1
        case .RaspberryPiRev2:
            return GPIORPIRev2
        case .RaspberryPiPlusZero:
            return GPIORPIPlusZERO
        case .RaspberryPi2:
            fallthrough
        case .RaspberryPi3:
            return GPIORPI2
        case .CHIP:
            return GPIOCHIP
        case .BeagleBoneBlack:
            return GPIOBEAGLEBONE
        case .OrangePi:
            return GPIOORANGEPI
        case .OrangePiZero:
            return GPIOORANGEPIZERO
        }
    }
}

// MARK: - Global Enums

public enum SupportedBoard: String {
    case RaspberryPiRev1   // Pi A,B Revision 1
    case RaspberryPiRev2   // Pi A,B Revision 2
    case RaspberryPiPlusZero // Pi A+,B+,Zero with 40 pin header
    case RaspberryPi2 // Pi 2 with 40 pin header
    case RaspberryPi3 // Pi 3 with 40 pin header
    case CHIP
    case BeagleBoneBlack
    case OrangePi
    case OrangePiZero
}

// MARK: - Codable

extension SupportedBoard: Codable {}
