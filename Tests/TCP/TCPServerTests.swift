import XCTest
@testable import TCP

class TCPServerTests: XCTestCase {
    static var allTests : [(String, TCPServerTests -> () throws -> Void)] {
        return [
                   ("testServerClient", testServerClient),
                   ("testTwoServersOnTheSamePortThrows", testTwoServersOnTheSamePortThrows),
                   ("testTwoServersOnTheSamePortWithReusePortDoesNotThrow", testTwoServersOnTheSamePortWithReusePortDoesNotThrow),
        ]
    }
    
    func testServerClient() throws {
        co {
            do {
                let server = try TCPServer(host: "0.0.0.0", port: 8080)
                let connection = try server.accept()
                let data = try connection.receive(upTo: 1024)
                try connection.send(data)
            } catch {
                XCTFail("\(error)")
            }
        }

        let connection = try TCPConnection(host: "0.0.0.0", port: 8080)
        try connection.open()
        try connection.send("hello")
        let data =  try connection.receive(upTo: 1024)
        XCTAssert(data == "hello", "Should've received hello")
    }

    func testTwoServersOnTheSamePortThrows() throws {
        co {
            do {
                let server = try TCPServer(host: "0.0.0.0", port: 8081)
                try server.accept()
            } catch {
                XCTFail("\(error)")
            }
        }

        var failed = false

        do {
            let server = try TCPServer(host: "0.0.0.0", port: 8081)
            try server.accept()
        } catch {
            failed = true
        }

        XCTAssert(failed, "Should fail with: Address already in use")
    }
}
