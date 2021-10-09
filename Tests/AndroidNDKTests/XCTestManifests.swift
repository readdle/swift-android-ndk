import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(AndroidHandlerTest.allTests),
        testCase(MainRunLoopTest.allTests),
    ]
}
#endif
