// TCPConnection.swift
//
// The MIT License (MIT)
//
// Copyright (c) 2015 Zewo
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import CLibvenice
@_exported import IP

public final class TCPConnection: Connection {
    public var ip: IP
    var socket: tcpsock?
    public private(set) var closed = true

    init(with socket: tcpsock) throws {
        self.ip = try IP(address: tcpaddr(socket))
        self.socket = socket
        self.closed = false
        try assertNotClosed()
    }

    public init(to host: String, on port: Int) throws {
        if host == "0.0.0.0" || host == "127.0.0.1" {
            self.ip = try IP(localAddress: host, port: port)
        } else {
            self.ip = try IP(remoteAddress: host, port: port)
        }
    }

    public func open(timingOut deadline: Double) throws {
        socket = tcpconnect(ip.address, deadline.int64milliseconds)

        if socket == nil {
            throw TCPError.closedSocket(description: "Unable to connect.")
        }

        self.closed = false
    }

    public func send(_ data: Data) throws {
        try send(data, flushing: true, timingOut: .never)
    }
    
    public func send(_ data: Data, timingOut deadline: Double) throws {
        try send(data, flushing: true, timingOut: deadline)
    }
    
    public func send(_ data: Data, flushing flush: Bool, timingOut deadline: Double) throws {
        let socket = try getSocket()
        try assertNotClosed()
        let bytesProcessed = data.withUnsafeBufferPointer {
            tcpsend(socket, $0.baseAddress, $0.count, Int64(deadline))
        }

        try TCPError.assertNoSendError(withData: data, bytesProcessed: bytesProcessed)

        if flush {
            try self.flush()
        }
    }

    public func flush() throws {
        try flush(timingOut: .never)
    }
    
    public func flush(timingOut deadline: Double) throws {
        let socket = try getSocket()
        try assertNotClosed()

        tcpflush(socket, Int64(deadline))
        try TCPError.assertNoError()
    }

    public func receive(max byteCount: Int) throws -> Data {
        return try receive(upTo: byteCount, timingOut: .never)
    }

    public func receive(upTo byteCount: Int, timingOut deadline: Double = .never) throws -> Data {
        let socket = try getSocket()
        try assertNotClosed()

        var data = Data.buffer(with: byteCount)
        let bytesProcessed = data.withUnsafeMutableBufferPointer {
            tcprecvlh(socket, $0.baseAddress, 1, $0.count, deadline.int64milliseconds)
        }

        try TCPError.assertNoReceiveError(withData: data, bytesProcessed: bytesProcessed)
        return Data(data.prefix(bytesProcessed))
    }

    public func receive(from start: Int, to end: Int, timingOut deadline: Double = .never) throws -> Data {
        let socket = try getSocket()
        try assertNotClosed()

        if start <= 0 || end <= 0 {
            throw TCPError.unknown(description: "Marks should be > 0")
        }

        if start > end {
            throw TCPError.unknown(description: "loweWaterMark should be less than highWaterMark")
        }

        var data = Data.buffer(with: end)
        let bytesProcessed = data.withUnsafeMutableBufferPointer {
            tcprecvlh(socket, $0.baseAddress, start, $0.count, deadline.int64milliseconds)
        }

        try TCPError.assertNoReceiveError(withData: data, bytesProcessed: bytesProcessed)
        return Data(data.prefix(bytesProcessed))
    }

    public func receive(upTo byteCount: Int, until delimiter: String, timingOut deadline: Double = .never) throws -> Data {
        let socket = try getSocket()
        try assertNotClosed()


        var data = Data.buffer(with: byteCount)
        let bytesProcessed = data.withUnsafeMutableBufferPointer {
            tcprecvuntil(socket, $0.baseAddress, $0.count, delimiter, delimiter.utf8.count, deadline.int64milliseconds)
        }

        try TCPError.assertNoReceiveError(withData: data, bytesProcessed: bytesProcessed)
        return Data(data.prefix(bytesProcessed))
    }

    public func close() {
        guard let socket = self.socket else {
            closed = true;
            return
        }

        if closed {
            return
        }

        closed = true
        tcpclose(socket)
    }

    private func getSocket() throws -> tcpsock {
        guard let socket = self.socket else {
            throw TCPError.closedSocket(description: "Connection has not been initialized. You must first open to the connection.")
        }
        return socket
    }

    private func assertNotClosed() throws {
        if closed {
            throw TCPError.closedSocketError
        }
    }

    deinit {
        if let socket = socket where !closed {
            tcpclose(socket)
        }
    }

}

extension TCPConnection {
    public func send(_ convertible: DataConvertible, timingOut deadline: Double = .never) throws {
        try send(convertible.data, timingOut: deadline)
    }

    public func receiveString(upTo codeUnitCount: Int, timingOut deadline: Double = .never) throws -> String {
        let result = try receive(upTo: codeUnitCount, timingOut: deadline)
        return try String(data: result)
    }

    public func receiveString(upTo codeUnitCount: Int, until delimiter: String, timingOut deadline: Double = .never) throws -> String {
        let result = try receive(upTo: codeUnitCount, until: delimiter, timingOut: deadline)
        return try String(data: result)
    }
}
