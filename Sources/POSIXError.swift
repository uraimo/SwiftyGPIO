#if os(OSX) || os(iOS) || os(watchOS) || os(tvOS)
    import Darwin.C
#elseif os(Linux)
    import Glibc
#endif

public extension POSIXError {
    
    /// Creates error from C ```errno```.
    static var fromErrorNumber: POSIXError? { return self.init(rawValue: errno) }
}
    
    /// Enumeration describing POSIX error codes.
    public enum POSIXError: Error, RawRepresentable {
        
        case Value(CInt)
        
        public init?(rawValue: CInt) {
            
            self = .Value(rawValue)
        }
        
        public var rawValue: CInt {
            
            switch self {
                
            case let .Value(rawValue): return rawValue
            }
        }
    }


