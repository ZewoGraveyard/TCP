import XCTest
@testable import TCP

class TCPServerTests: XCTestCase {
    static var allTests : [(String, TCPServerTests -> () throws -> Void)] {
        return [
                   ("testCreateServer", testCreateServer),
        ]
    }
    
    func testCreateServer() throws {
        co {
            do {
                let server = try TCPServer(for: URI("tcp://0.0.0.0:8080"))
                let connection = try server.accept()
                let data = try connection.receive(max: 1024)
                try connection.send(data)
            } catch {
                print(error)
            }
        }
        // while(true) {}
        let connection = try TCPConnection(to: URI("tcp://0.0.0.0:8080"))
        try connection.open()
        try connection.send("hello")
        let data =  try connection.receive(upTo: 1024)
        print(data)
        XCTAssert(data == "hello", "Something is severely wrong here.")
    }
    
}
