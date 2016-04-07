// TCPClientSocket.swift
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
import C7

public final class TCPConnection: C7.Connection {
    
    public var uri: C7.URI
    var socket: tcpsock?
    public private(set) var closed = false

    public init(to uri: C7.URI) throws {
        self.uri = uri
    }
    
    public func open() throws {
        guard let host = uri.host else {
            throw TCPError.unknown(description: "Host was not defined in URI")
        }
        guard let port = uri.port else {
            throw TCPError.unknown(description: "Port was not defined in URI")
        }
        tcpconnect(try IP(remoteAddress: host, port: port).address, never)
    }
    
    
    public func receive(max byteCount: Int) throws -> C7.Data {
        return try receive(upTo: byteCount, timingOut: never)
    }
    
    public func send(data: C7.Data) throws {
        try send(data, flush: true, deadline: never)
    }
    
    public func flush() throws {
        try flush(timingOut: never)
    }

    public func flush(timingOut deadline: Deadline) throws {
        let socket = try getSocket()
        try assertNotClosed()
        
        tcpflush(socket, deadline)
        try TCPError.assertNoError()
    }

    public func send(data: Data, flush: Bool = true, deadline: Deadline = never) throws {
        let socket = try getSocket()
        try assertNotClosed()
        
        let bytesProcessed = data.withUnsafeBufferPointer {
            tcpsend(socket, $0.baseAddress, $0.count, deadline)
        }

        try TCPError.assertNoSendErrorWithData(data, bytesProcessed: bytesProcessed)

        if flush {
            try self.flush()
        }
    }

    public func receive(upTo byteCount: Int, timingOut deadline: Deadline = never) throws -> Data {
        let socket = try getSocket()
        try assertNotClosed()

        var data = Data.bufferWithSize(byteCount)
        let bytesProcessed = data.withUnsafeMutableBufferPointer {
            tcprecv(socket, $0.baseAddress, $0.count, deadline)
        }

        try TCPError.assertNoReceiveErrorWithData(data, bytesProcessed: bytesProcessed)
        return Data(data.prefix(bytesProcessed))
    }

    public func receive(lowWaterMark lowWaterMark: Int, highWaterMark: Int, timingOut deadline: Deadline = never) throws -> Data {
        let socket = try getSocket()
        try assertNotClosed()

        if lowWaterMark <= 0 || highWaterMark <= 0 {
            throw TCPError.unknown(description: "Marks should be > 0")
        }

        if lowWaterMark > highWaterMark {
            throw TCPError.unknown(description: "loweWaterMark should be less than highWaterMark")
        }

        var data = Data.bufferWithSize(highWaterMark)
        let bytesProcessed = data.withUnsafeMutableBufferPointer {
            tcprecvlh(socket, $0.baseAddress, lowWaterMark, highWaterMark, deadline)
        }

        try TCPError.assertNoReceiveErrorWithData(data, bytesProcessed: bytesProcessed)
        return Data(data.prefix(bytesProcessed))
    }

    public func receive(upTo byteCount: Int, untilDelimiter delimiter: String, timingOut deadline: Deadline = never) throws -> Data {
        let socket = try getSocket()
        try assertNotClosed()

        
        var data = Data.bufferWithSize(byteCount)
        let bytesProcessed = data.withUnsafeMutableBufferPointer {
            tcprecvuntil(socket, $0.baseAddress, $0.count, delimiter, delimiter.utf8.count, deadline)
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
    
    func getSocket() throws -> tcpsock {
        guard let socket = self.socket else {
            throw TCPError.closedSocket(description: "Socket has not been initialized. You must first connect to the socket.")
        }
        return socket
    }
    
    func assertNotClosed() throws {
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
    public func send(convertible: DataConvertible, timingOut deadline: Deadline = never) throws {
        try send(convertible.data, deadline: deadline)
    }

    public func receiveString(length length: Int, timingOut deadline: Deadline = never) throws -> String {
        let result = try receive(upTo: length, timingOut: deadline)
        return try String(data: result)
    }

    public func receiveString(length length: Int, untilDelimiter delimiter: String, timingOut deadline: Deadline = never) throws -> String {
        let result = try receive(upTo: length, untilDelimiter: delimiter, timingOut: deadline)
        return try String(data: result)
    }
}