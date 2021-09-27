import XCTest

import AndroidNDKTests

var tests = [XCTestCaseEntry]()
tests += AndroidNDKTests.allTests()
XCTMain(tests)
