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

/// GPIO for SunXi (e.g. OrangePi) hardware.
///
/// - SeeAlso: [SunXi Wiki](http://linux-sunxi.org/GPIO)

public struct SunXiGPIO: CustomStringConvertible, Equatable {

    // MARK: - Properties

    public var letter: Letter

    public var pin: UInt

    // MARK: - Initialization

    public init(letter: Letter, pin: UInt) {

        self.letter = letter
        self.pin = pin
    }

    // MARK: - Computed Properties

    public var description: String {

        return pinName
    }

    public var pinName: String {

        return "P" + "\(letter)" + "\(pin)"
    }

    public var gpioPin: Int {

        return (letter.rawValue * 32) + Int(pin)
    }
}

// MARK: - Equatable

public func == (lhs: SunXiGPIO, rhs: SunXiGPIO) -> Bool {

    return lhs.letter == rhs.letter && lhs.pin == rhs.pin
}

// MARK: - Supporting Types

public extension SunXiGPIO {

    public enum Letter: Int {

        case A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S, T, U, V, W, X, Y, Z
    }
}

// MARK: - Extensions

public extension GPIO {

    convenience init(sunXi: SunXiGPIO) {

        self.init(name: sunXi.pinName, id: sunXi.gpioPin)
    }
}
