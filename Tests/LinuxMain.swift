#if os(Linux)

import XCTest
@testable import TCPTestSuite

XCTMain([
    testCase(TCPServerTests.allTests)
])

#endif
