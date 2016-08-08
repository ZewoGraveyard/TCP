import XCTest
@testable import TCP

class TCPTests : XCTestCase {
    func testConnectionRefused() throws {
        let connection = try TCPConnection(host: "127.0.0.1", port: 1111)
        XCTAssertThrowsError(try connection.open())
    }

    func testSendClosedSocket() throws {
        let port = 2222
        let host = try TCPHost(host: "127.0.0.1", port: port, reusePort: true)

        co {
            do {
                let connection = try TCPConnection(host: "127.0.0.1", port: port)
                try connection.open()
                try connection.close()
                XCTAssertThrowsError(try connection.write([], flush: true, deadline: .never))
            } catch {
                XCTFail()
            }
        }

        _ = try host.accept()
        nap(for: 1.millisecond)
    }

    func testFlushClosedSocket() throws {
        let port = 3333
        let host = try TCPHost(host: "127.0.0.1", port: port, reusePort: true)

        co {
            do {
                let connection = try TCPConnection(host: "127.0.0.1", port: port)
                try connection.open()
                try connection.close()
                XCTAssertThrowsError(try connection.flush())
            } catch {
                XCTFail()
            }
        }

        _ = try host.accept()
        nap(for: 1.millisecond)
    }

    func testReceiveClosedSocket() throws {
        let port = 4444
        let host = try TCPHost(host: "127.0.0.1", port: port, reusePort: true)

        co {
            do {
                let connection = try TCPConnection(host: "127.0.0.1", port: port)
                try connection.open()
                try connection.close()
                XCTAssertThrowsError(try connection.read(1))
            } catch {
                XCTFail()
            }
        }

        _ = try host.accept()
        nap(for: 1.millisecond)
    }

    func testSendReceive() throws {
        let port = 5555
        let host = try TCPHost(host: "127.0.0.1", port: port, reusePort: true)

        co {
            do {
                let connection = try TCPConnection(host: "127.0.0.1", port: port)
                try connection.open()
                try connection.write([123])
            } catch {
                XCTAssert(false)
            }
        }

        let connection = try host.accept()
        let data = try connection.read(upTo: 1)
        XCTAssert(data == [123])
        try connection.close()
    }

    func testClientServer() throws {
        let port = 6666
        let host = try TCPHost(host: "127.0.0.1", port: port, reusePort: true)

        co {
            do {
                let connection = try TCPConnection(host: "127.0.0.1", port: port)
                try connection.open()

                let data = try connection.readString(upTo: 3)
                XCTAssert(data == "ABC")

                try connection.write("123456789")
            } catch {
                XCTFail()
            }
        }

        let connection = try host.accept()
        let deadline = 30.milliseconds.fromNow()

        XCTAssertThrowsError(try connection.read(upTo: 16, deadline: deadline))

        let diff = now() - deadline
        XCTAssert(diff > -300 && diff < 300)

        try connection.write("ABC")

        let data = try connection.read(upTo: 9)
        XCTAssert(data == "123456789")
    }
}

extension TCPTests {
    static var allTests : [(String, (TCPTests) -> () throws -> Void)] {
        return [
            ("testConnectionRefused", testConnectionRefused),
            ("testSendClosedSocket", testSendClosedSocket),
            ("testFlushClosedSocket", testFlushClosedSocket),
            ("testReceiveClosedSocket", testReceiveClosedSocket),
            ("testSendReceive", testSendReceive),
            ("testClientServer", testClientServer),
        ]
    }
}
