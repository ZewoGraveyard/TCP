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
@_exported import C7
@_exported import IP
@_exported import URI

public final class TCPConnection: Connection {
    public var uri: URI
    var socket: tcpsock?
    public private(set) var closed = true

    init(with socket: tcpsock) throws {
        self.uri = URI() // TODO: get the IP and port from socket and fill URI's host, and port
        self.socket = socket
        self.closed = false
        try assertNotClosed()
    }

    public init(to uri: URI) throws {
        self.uri = uri
    }

    public convenience init(to uri: String) throws {
        try self.init(to: URI(uri))
    }

    public func open(timingOut deadline: Double) throws {
        guard let host = uri.host else {
            throw TCPError.unknown(description: "Host was not defined in URI")
        }

        guard let port = uri.port else {
            throw TCPError.unknown(description: "Port was not defined in URI")
        }
        
        if uri.host == "0.0.0.0" || uri.host == "127.0.0.1" {
          socket = tcpconnect(try IP(localAddress: host, port: port).address, Int64(deadline))
        }
        else {
          socket = tcpconnect(try IP(remoteAddress: host, port: port).address, Int64(deadline))
        }

        if socket == nil {
            throw TCPError.closedSocket(description: "Unable to connect.")
        }

        self.closed = false
    }

    public func send(data: Data) throws {
        try send(data, flushing: true, timingOut: .never)
    }
    
    public func send(data: Data, timingOut deadline: Double) throws {
        try send(data, flushing: true, timingOut: deadline)
    }
    
    public func send(data: Data, flushing flush: Bool, timingOut deadline: Double) throws {
        let socket = try getSocket()
        try assertNotClosed()
        let bytesProcessed = data.withUnsafeBufferPointer {
            tcpsend(socket, $0.baseAddress, $0.count, Int64(deadline))
        }

        try TCPError.assertNoSendErrorWithData(data, bytesProcessed: bytesProcessed)

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

        try TCPError.assertNoReceiveErrorWithData(data, bytesProcessed: bytesProcessed)
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

        try TCPError.assertNoReceiveErrorWithData(data, bytesProcessed: bytesProcessed)
        return Data(data.prefix(bytesProcessed))
    }

    public func receive(upTo byteCount: Int, until delimiter: String, timingOut deadline: Double = .never) throws -> Data {
        let socket = try getSocket()
        try assertNotClosed()


        var data = Data.buffer(with: byteCount)
        let bytesProcessed = data.withUnsafeMutableBufferPointer {
            tcprecvuntil(socket, $0.baseAddress, $0.count, delimiter, delimiter.utf8.count, deadline.int64milliseconds)
        }

        try TCPError.assertNoReceiveErrorWithData(data, bytesProcessed: bytesProcessed)
        return Data(data.prefix(bytesProcessed))
    }

    public func close() -> Bool {
        guard let socket = self.socket else {
            closed = true
            return true
        }

        if closed {
            return false
        }

        closed = true
        tcpclose(socket)
        return true
    }

    private func getSocket() throws -> tcpsock {
        guard let socket = self.socket else {
            throw TCPError.closedSocket(description: "Connection has not been initialized. You must first open to the connection.")
        }
        if socket == nil {
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
    public func send(convertible: DataConvertible, timingOut deadline: Double = .never) throws {
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
