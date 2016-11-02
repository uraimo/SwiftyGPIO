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
