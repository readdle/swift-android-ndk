//
// Created by Andriy Druk on 9/11/18.
//

import AndroidNDK
import CAndroidNDK
import Foundation
import XCTest

class MainRunLoopTest: XCTestCase {

    public func testThreadWithoutLooper() {
        XCTAssertFalse(setupAndroidMainRunLoop(), "Shouold be no looper")
    }

    public func testDispatchQueueAsync() {
        XCTAssert(Thread.isMainThread, "Is not main thread")

        _ = AndroidLooper()
        XCTAssert(setupAndroidMainRunLoop(), "Can't find looper")

        var counter = 0
        DispatchQueue.main.async {
            XCTAssert(Thread.isMainThread, "Is not main thread")
            counter += 1
        }

        DispatchQueue.main.async {
            XCTAssert(Thread.isMainThread, "Is not main thread")
            counter += 1
        }

        DispatchQueue.main.async {
            XCTAssert(Thread.isMainThread, "Is not main thread")
            counter += 1
        }

        XCTAssertEqual(counter, 0)
        AndroidLooper.pollAll()
        XCTAssertEqual(counter, 3)
    }

    public func testDispatchQueueAsyncReentrance() {
        XCTAssert(Thread.isMainThread, "Is not main thread")

        _ = AndroidLooper()
        XCTAssert(setupAndroidMainRunLoop(), "Can't find looper")

        var counter = 0
        DispatchQueue.main.async {
            XCTAssert(Thread.isMainThread, "Is not main thread")
            counter += 1
            DispatchQueue.main.async {
                XCTAssert(Thread.isMainThread, "Is not main thread")
                counter += 1
                DispatchQueue.main.async {
                    XCTAssert(Thread.isMainThread, "Is not main thread")
                    counter += 1
                }
            }
        }

        XCTAssertEqual(counter, 0)
        AndroidLooper.pollAll()
        XCTAssertEqual(counter, 3)
    }

    public func testDispatchQueueAsyncWithDelay() {
        XCTAssert(Thread.isMainThread, "Is not main thread")

        _ = AndroidLooper()
        XCTAssert(setupAndroidMainRunLoop(), "Can't find looper")

        var counter = 0
        DispatchQueue.main.async {
            XCTAssert(Thread.isMainThread, "Is not main thread")
            counter += 1
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
            XCTAssert(Thread.isMainThread, "Is not main thread")
            counter += 1
        })

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: {
            XCTAssert(Thread.isMainThread, "Is not main thread")
            counter += 1
        })


        XCTAssertEqual(counter, 0)
        AndroidLooper.pollAll(withTimeout: 50)
        XCTAssertEqual(counter, 1)
        AndroidLooper.pollAll(withTimeout: 100)
        XCTAssertEqual(counter, 2)
        AndroidLooper.pollAll(withTimeout: 100)
        XCTAssertEqual(counter, 3)
    }


    public func testMainHandler() {

    }

    static var allTests = [
        ("testThreadWithoutLooper", testThreadWithoutLooper),
        ("testDispatchQueueAsync", testDispatchQueueAsync),
        ("testDispatchQueueAsyncReentrance", testDispatchQueueAsyncReentrance),
        ("testDispatchQueueAsyncWithDelay", testDispatchQueueAsyncWithDelay),
        ("testMainHandler", testMainHandler),
    ]

}
