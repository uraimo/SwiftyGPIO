/*
 SwiftyGPIO

 Copyright (c) 2021 Craig Altenburg
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

// ============================================================================
//  extension SwiftyGPIO
// ============================================================================
/// Extensions to SwiftyGPIO
///
/// To use the pwm create a pwm instance with code like:
///
///    let thePWMChannel = sysPWMs( for: .RaspberryPi4 )[0]
///
/// The pin on which the PWM signal is generated depends on paramters
/// set on the dtoverlay loaded at boot time. (see Class RaspberrySysPWM)

extension SwiftyGPIO
{
    public static func sysPWMs( for board: SupportedBoard ) -> [Int:RaspberrySysPWM]?
    {
        switch board
        {
        case .RaspberryPiRev1:  // #### TODO #### check this out.  Do Pi 1s only have one pwm?
            return SysPWMRPI1
        case .RaspberryPiRev2, .RaspberryPiPlusZero, .RaspberryPiZero2, .RaspberryPi2, .RaspberryPi3, .RaspberryPi4:
            return SysPWMRPI2
        default:
            return nil
        }
    }
}


extension SwiftyGPIO
{
    static let SysPWMRPI1: [Int: RaspberrySysPWM] =
    [
        0: RaspberrySysPWM( channel: "0" )
    ]

    static let SysPWMRPI2: [Int: RaspberrySysPWM] =
    [
        0: RaspberrySysPWM( channel: "0" ),
        1: RaspberrySysPWM( channel: "1" )
    ]
}

// ============================================================================
//  Class RaspberrySysPWM
// ============================================================================
/// Pulse Width Modulation
///
/// In order to use these classes you must add one of the two PWM dtoverlays.
/// This is done by adding one of the following lines to /boot/config.txt:
///
/// * for a single PWM on pin 18:        dtoverlay=pwm
/// * for a single PWM on pin 12:        dtoverlay=pwm,pin=12,func=4
/// * for two PWMs on pins 18 and 19:    dtoverlay=pwm-2chan
/// * for two PWMs on pins 12 and 13:    dtoverlay=pwm-2chan,pin=12,func=4,pin2=13,func2=4
///
/// Note: it is possible to have on PWM on 12 or 13 with the other on 18 or 19.
///       Simply omit the un-needed pin and func parameters from the final
///       dtoverlay line above.
///
/// Note: in order to use these functions the user running the code must be
///       a member of the "gpio" group or be the superuser (root).
///       The user "pi" is a member of the "gpio" group by default.

public class RaspberrySysPWM
{
    /// Enumberation for polarity setting
    public enum Polarity : String { case normal, inverse }

    /// Error set with functions return false
    public var error : Error? = nil

    let channel      : String

    let exportPath   : String = "/sys/class/pwm/pwmchip0/export"
    let pwmPath      : String

    var exported     = false


    // ------------------------------------------------------------------------
    //  Private Initializer
    // ------------------------------------------------------------------------
    /// Initializer
    ///
    /// @param  channel  the change for this instance ("0" or "1").

    init( channel: String )
    {
        self.channel = channel
        self.pwmPath = "/sys/class/pwm/pwmchip0/pwm\(channel)/"
    }

    // ------------------------------------------------------------------------
    //  Public Function initPWM
    // ------------------------------------------------------------------------
    /// Initialise the PWM
    ///
    /// Must be called at least once before starting the PWM.
    /// If called a second time the PWM output will stop until
    /// a new startPWM call is made.
    ///
    /// @param   polarity  the polarity of the output pulse
    ///
    /// @returns a boolean indicating success or failure.

    @discardableResult
    public func initPWM( polarity: Polarity = .normal ) -> Bool
    {
        let enablePath   : String = pwmPath + "enable"
        let polarityPath : String = pwmPath + "polarity"

        do
        {
            if !exported
            {
                exported = true
                try write( channel, exportPath )
            }

            try write( "0",               enablePath )
            try write( polarity.rawValue, polarityPath )
        }
        catch
        {
            self.error = error
            return false
        }

        self.error = nil
        return true
    }

    // ------------------------------------------------------------------------
    //  Public Function startPWM
    // ------------------------------------------------------------------------
    /// Start PWM
    ///
    /// Start generating a PWM stream on the output pin.
    /// This function can be called repeatedly to change the output.
    ///
    /// @param   period  the total lenght of each frame in nanoseconds
    /// @param   duty    the pulse width as a percent of the frame.
    ///
    /// @returns a boolean indicating success or failure.

    @discardableResult
    public func startPWM( period: UInt, duty: Float ) -> Bool
    {
        guard duty >= 0.0  &&  duty <= 100.00 else { return false }

        let active : UInt = UInt( Float( period ) * (duty / 100.0) )

        let periodPath    : String = pwmPath + "period"
        let dutyCyclePath : String = pwmPath + "duty_cycle"
        let enablePath    : String = pwmPath + "enable"

        do
        {
            try write( String( period ), periodPath )
            try write( String( active ), dutyCyclePath )
            try write( "1",              enablePath )
        }
        catch
        {
            self.error = error
            return false
        }

        self.error = nil
        return true
    }

    // ------------------------------------------------------------------------
    //  Public Function stopPWM
    // ------------------------------------------------------------------------
    /// Stop PWM
    ///
    /// Stop the PWM by disabling the channel
    ///
    /// @returns a boolean indicating success or failure.

    @discardableResult
    public func stopPWM() -> Bool
    {
        let enablePath :String = pwmPath + "enable"

        do
        {
            try write( "0", enablePath )
        }
        catch
        {
            self.error = error
            return false
        }

        self.error = nil
        return true
    }

    // ------------------------------------------------------------------------
    //  Private Function write
    // ------------------------------------------------------------------------
    /// Write string to file
    ///
    /// Writes the passed string to one of the sysFS endpoints.
    ///
    /// @param   value  The string to write
    /// @param   path   Path to the endpoint

    func write( _ value : String, _ path : String ) throws
    {
        let output : FileHandle? = FileHandle( forWritingAtPath: path )

        guard let output : FileHandle = output else
        {
          throw  POSIXError( .EACCES, userInfo: [:] )
        }

        if let data : Data = value.data( using: .utf8 )
        {
          try output.write( contentsOf: data )
        }

        try? output.close()
    }
}
