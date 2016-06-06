//
//  Thread.swift
//  SwiftFoundation
//
//  Created by Alsey Coleman Miller on 4/5/16.
//  Copyright © 2016 PureSwift. All rights reserved.
//

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
    
    public init(_ closure: () -> ()) throws {
        
        let holder = Unmanaged.passRetained(Closure(closure: closure))
        
        let pointer = UnsafeMutablePointer<Void>(holder.toOpaque())
        
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
        
        pthread_detach(internalThread)
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

private func ThreadPrivateMain(arg: UnsafeMutablePointer<Void>?) -> UnsafeMutablePointer<Void>? {
    
    let unmanaged = Unmanaged<Thread.Closure>.fromOpaque(arg!)
    
    unmanaged.takeUnretainedValue().closure()
    
    unmanaged.release()
    
    return nil
}

private extension Thread {
    
    private final class Closure {
        
        let closure: () -> ()
        
        init(closure: () -> ()) {
            
            self.closure = closure
        }
    }
}
