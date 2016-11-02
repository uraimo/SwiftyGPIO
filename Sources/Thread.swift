#if os(OSX) || os(iOS) || os(watchOS) || os(tvOS)
    import Darwin.C
#elseif os(Linux)
    import Glibc
#endif

/// POSIX Thread
public final class Thread {
    
    // MARK: - Private Properties
    
    private let internalThread: pthread_t
    
    // MARK: - Intialization
    
    public init(_ closure: @escaping () -> ()) throws {
        
        let holder = Unmanaged.passRetained(Closure(closure: closure))
        
        let pointer = holder.toOpaque()
        
        #if os(Linux)
            var internalThread: pthread_t = 0
        #elseif os(OSX) || os(iOS) || os(watchOS) || os(tvOS)
            var internalThread: pthread_t? = nil
        #endif
        
        guard pthread_create(&internalThread, nil, ThreadPrivateMain, pointer) == 0
            else { throw POSIXError.fromErrorNumber! }
        
        #if os(Linux)
            self.internalThread = internalThread
        #elseif os(OSX) || os(iOS) || os(watchOS) || os(tvOS)
            self.internalThread = internalThread!
        #endif
        
        pthread_detach(self.internalThread)
    }
    
    // MARK: - Class Methods
    
    public static func exit(code: inout Int) {
        
        pthread_exit(&code)
    }
    
    // MARK: - Methods
    
    public func join() throws {
        
        let errorCode = pthread_join(internalThread, nil)
        
        guard errorCode == 0
            else { throw POSIXError(rawValue: errorCode)! }
    }
    
    public func cancel() throws {
        
        let errorCode = pthread_cancel(internalThread)
        
        guard errorCode == 0
            else { throw POSIXError(rawValue: errorCode)! }
    }
}

// MARK: - Private

// This double declaration is needed becaus of different `pthread_create` parameters requirements, between osx and linux (arm)
#if os(OSX) || os(iOS) || os(watchOS) || os(tvOS)
private func ThreadPrivateMain(arg: UnsafeMutableRawPointer) -> UnsafeMutableRawPointer? {
    let unmanaged = Unmanaged<Thread.Closure>.fromOpaque(arg)
    
    unmanaged.takeUnretainedValue().closure()
    
    unmanaged.release()
    
    return nil
}
#elseif os(Linux)
private func ThreadPrivateMain(arg: UnsafeMutableRawPointer?) -> UnsafeMutableRawPointer? {
    let unmanaged = Unmanaged<Thread.Closure>.fromOpaque(arg!)

    unmanaged.takeUnretainedValue().closure()
        
    unmanaged.release()
        
    return nil
}
#endif

fileprivate extension Thread {
    
    final class Closure {
        
        public let closure: () -> ()
        
        init(closure: @escaping () -> ()) {
            
            self.closure = closure
        }
    }
}
