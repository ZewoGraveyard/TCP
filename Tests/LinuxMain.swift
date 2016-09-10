#if os(Linux)

import XCTest
@testable import TCPTests

XCTMain([
    testCase(TCPServerTests.allTests)
])

#endif
