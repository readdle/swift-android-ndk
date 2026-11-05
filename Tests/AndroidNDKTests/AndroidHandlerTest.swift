//
// Created by Andriy Druk on 9/11/18.
//

@testable import AndroidNDK

import Foundation
import XCTest

#if canImport(Android)
import Android
#elseif canImport(Glibc)
import Glibc
#endif

class AndroidHandlerTest: XCTestCase {

    private var handlerThread: HandlerThread?

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        handlerThread = HandlerThread()
        handlerThread?.start()
        handlerThread?.waitUntilPrepared()
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        handlerThread?.cancel()
        handlerThread = nil
        super.tearDown()
    }

    public func testHandler() {
        let group = DispatchGroup()
        let handler = AndroidHandler(looper: handlerThread!.looper!)

        for _ in 0 ..< 100 {
            group.enter()
            handler.post {
                group.leave()
            }
        }

        group.wait()
    }

    public func testHandlerReentrance() {
        let group = DispatchGroup()
        let handler = AndroidHandler(looper: handlerThread!.looper!)

        group.enter()
        handler.post {
            handler.post {
                group.leave()
            }
        }
        group.wait()
    }

    public func testMemoryFreeing() {
        let group = DispatchGroup()
        let handler = AndroidHandler(looper: handlerThread!.looper!)

        var string: NSString? = "1"
        weak var weakReferenceToString: NSString? = string

        for _ in 0 ..< 100 {
            group.enter()
            handler.post { [string] in
                _ = string?.description.count
                group.leave()
            }
        }
        group.wait()

        // Looks like we need small sleep here to be sure weak was removed
        usleep(10000) // 10ms

        // Make `string` nil should make `weakReferenceToString` nil as well
        // Otherwise it means that some block still holds strong reference to `string`
        string = nil
        XCTAssert(weakReferenceToString == nil)
    }

    public func testCancelWhileBusy() {
        let thread = handlerThread!
        let handler = AndroidHandler(looper: thread.looper!)

        // Keep the looper busy, so cancel's wake() lands in the same poll as a callback
        func repost() {
            handler.post { repost() }
        }
        repost()
        usleep(10000) // 10ms

        thread.cancel()
        handlerThread = nil

        let deadline = Date().addingTimeInterval(3)
        while !thread.isFinished && Date() < deadline {
            usleep(10000) // 10ms
        }
        XCTAssertTrue(thread.isFinished)
    }

    static var allTests = [
        ("testHandler", testHandler),
        ("testHandlerReentrance", testHandlerReentrance),
        ("testMemoryFreeing", testMemoryFreeing),
        ("testCancelWhileBusy", testCancelWhileBusy),
    ]

}
