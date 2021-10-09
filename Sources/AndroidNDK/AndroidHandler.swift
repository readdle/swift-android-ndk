//
// Created by Andriy Druk on 9/11/18.
//

import CAndroidNDK
import Foundation
import Glibc

/**
 * A Handler allows you to send and process Message and Runnable objects associated with a thread's MessageQueue. 
 * Each Handler instance is associated with a single thread and that thread's message queue. 
 * When you create a new Handler it is bound to a Looper. It will deliver messages and runnables to that Looper's message queue and execute them on that Looper's thread.
 * There are two main uses for a Handler: 
 * (1) to schedule messages and runnables to be executed at some point in the future; and 
 * (2) to enqueue an action to be performed on a different thread than your own.
 * 
 * When a process is created for your application, its main thread is dedicated to running a message queue that takes care of managing 
 * the top-level application objects (activities, broadcast receivers, etc) and any windows they create. 
 * You can create your own threads, and communicate back with the main application thread through a Handler. 
 * This is done by calling the same post or sendMessage methods as before, but from your new thread. 
 * The given Runnable or Message will then be scheduled in the Handler's message queue and processed when appropriate.
 */
public class AndroidHandler {

    private static var globalLock = NSLock()
    private static var globalMainThreadHandler: AndroidHandler?

    // Should be called at environment setup phase from main thread
    @discardableResult
    public static func setUpMainThreadHandler() -> AndroidHandler {
        if let mainThreadHandler = globalMainThreadHandler {
            return mainThreadHandler
        }
        globalLock.lock()
        defer {
            globalLock.unlock()
        }
        if let mainThreadHandler = globalMainThreadHandler {
            return mainThreadHandler
        }
        guard let mainThreadHandler = AndroidHandler() else {
            fatalError("No looper at current thread! Call this func from Main Thread")
        }
        globalMainThreadHandler = mainThreadHandler
        return mainThreadHandler
    }

    public static var mainThreadHandler: AndroidHandler {
        if let mainThreadHandler = globalMainThreadHandler {
            return mainThreadHandler
        }
        globalLock.lock()
        defer {
            globalLock.unlock()
        }
        guard let handler = globalMainThreadHandler else {
            fatalError("Global main handler should be set before this call")
        }
        return handler
    }

    public static func isMainThread() -> Bool {
        guard let currentThreadLooper = ALooper_forThread() else {
            return false
        }
        return mainThreadHandler.looper == currentThreadLooper
    }

    private let looper: OpaquePointer // ALooper
    private var messagePipe = [Int32](repeating: 0, count: 2)

    public convenience init?() {
        guard let currentThreadLooper = ALooper_forThread() else { // get looper for current thread
            return nil
        }
        self.init(looper: currentThreadLooper)
    }

    public convenience init(looper: AndroidLooper) {
        self.init(looper: looper.pointer)
    }

    public init(looper: OpaquePointer) {
        self.looper = looper
        ALooper_acquire(looper) // add reference to keep object alive
        pipe(&messagePipe) //create send-receive pipe
        // listen for pipe read end, if there is something to read - notify via provided callback on main thread
        ALooper_addFd(looper, messagePipe[0], 0, Int32(ALOOPER_EVENT_INPUT), looperCallback, nil)
    }

    deinit {
        ALooper_removeFd(looper, messagePipe[0]) // stop listening pipe
        ALooper_release(looper) // release looper reference
    }

    public func post(block: @escaping () -> Void) {
        let runnable = Runnable(block: block)
        var pointer = Int(bitPattern: Unmanaged.passRetained(runnable).toOpaque())
        write(messagePipe[1], &pointer, MemoryLayout<Int>.size)
    }

}

private class Runnable {
    let block: () -> Void

    init(block: @escaping () -> Void) {
        self.block = block
    }
}

private func looperCallback(fd: Int32, events: Int32, data: UnsafeMutableRawPointer?) -> Int32 {
    var pointer = 0
    let readBytes = read(fd, &pointer, MemoryLayout<Int>.size)
    guard readBytes == MemoryLayout<Int>.size,
          let opaque = UnsafeMutableRawPointer(bitPattern: pointer) else {
        fatalError("Runnable broken")
    }
    let runnable = Unmanaged<Runnable>.fromOpaque(opaque).takeRetainedValue()
    runnable.block()
    return 1 // continue listening for events
}

/**
 * Class used to run a message loop for a thread. 
 * Threads by default do not have a message loop associated with them; to create one, 
 * call prepare() in the thread that is to run the loop, and then loop() to have it process messages until the loop is stopped.
 * Most interaction with a message loop is through the AndroidHandler class.
 */
public class AndroidLooper {

    public fileprivate(set) var pointer: OpaquePointer

    public init() {
        pointer = ALooper_prepare(0)
    }

    public func wake() {
        ALooper_wake(pointer)
    }

    @discardableResult
    public static func pollAll(withTimeout timeout: Int32 = 0) -> Int32 {
        return ALooper_pollAll(timeout, nil, nil, nil)
    }

    @discardableResult
    public static func pollOnce(withTimeout timeout: Int32 = 0) -> Int32 {
        return ALooper_pollOnce(timeout, nil, nil, nil)
    }

}

/**
 * A Thread that has a AndroidLooper. The AndroidLooper can then be used to create AndroidHandlers.
 * Note that just like with a regular Thread, Thread.start() must still be called.
 */
public class HandlerThread: Thread {

    private static let timeout: Int32 = 1000 // 1 sec
    private let prepareDispatchGroup = DispatchGroup()

    public private(set) var looper: AndroidLooper?

    public override func start() {
        prepareDispatchGroup.enter()
        super.start()
    }

    public override func main() {
        self.looper = AndroidLooper()
        prepareDispatchGroup.leave()
        var result = Int32(ALOOPER_POLL_TIMEOUT)
        while result == ALOOPER_POLL_TIMEOUT {
            result = AndroidLooper.pollAll(withTimeout: HandlerThread.timeout)
        }
    }

    public override func cancel() {
        looper?.wake()
    }

    public func waitUntilPrepared() {
        prepareDispatchGroup.wait()
    }

}
