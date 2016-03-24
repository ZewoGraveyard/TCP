// TCPStream.swift
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
// IMPLIED, INCLUDINbG BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

public final class TCPStream: Stream {
    private(set) public var metadata: [String: Any] = [:]
    private let socket: TCPClientSocket

    public var lowWaterMark: Int
    public var highWaterMark: Int

    public init(socket: TCPClientSocket, lowWaterMark: Int = 1, highWaterMark: Int = 4096) {
        self.socket = socket
        self.lowWaterMark = lowWaterMark
        self.highWaterMark = highWaterMark
        self.metadata["ip"] = socket.ip
        self.metadata["port"] = socket.port
    }

    public var closed: Bool {
        return socket.closed
    }

    public func receive() throws -> Data {
        try assertNotClosed()
        do {
            return try socket.receive(lowWaterMark: lowWaterMark, highWaterMark: highWaterMark)
        } catch TCPError.connectionResetByPeer(_, let data) {
            throw StreamError.closedStream(data: data)
        } catch TCPError.brokenPipe(_, let data) {
            throw StreamError.closedStream(data: data)
        }
    }

    public func send(data: Data) throws {
        try assertNotClosed()
        do {
            try socket.send(data, flush: false)
        } catch TCPError.connectionResetByPeer(_, let data) {
            throw StreamError.closedStream(data: data)
        } catch TCPError.brokenPipe(_, let data) {
            throw StreamError.closedStream(data: data)
        }
    }

    public func flush() throws {
        try assertNotClosed()
        do {
            try socket.flush()
        } catch TCPError.connectionResetByPeer(_, let data) {
            throw StreamError.closedStream(data: data)
        } catch TCPError.brokenPipe(_, let data) {
            throw StreamError.closedStream(data: data)
        }
    }

    public func close() -> Bool {
        return socket.close()
    }

    private func assertNotClosed() throws {
        if closed {
            throw StreamError.closedStream(data: nil)
        }
    }

}