// TCPSocket.swift
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

public class TCPSocket : C7.Connection {
    
    var socket: tcpsock
    public private(set) var closed : Bool = false
    
    public var uri : URI?

    public var port: Int {
        return Int(tcpport(socket))
    }
    
    public init(socket: tcpsock) throws {
        self.socket = socket
        try open()
    }
    
    public func open() throws {
        try TCPError.assertNoError()
    }
    
    public func receive() throws -> Data {
        fatalError("Not implemented")
    }
    
    public func send(data: Data) throws {
        fatalError("Not implemented")
    }
    
    public func flush() throws {
        fatalError("Not implemented")
    }

    func attach(fileDescriptor: FileDescriptor, isServer: Bool) throws {
        if !closed {
            close()
        }

        socket = tcpattach(fileDescriptor, isServer ? 1 : 0)
        try TCPError.assertNoError()
        closed = false
    }

    public func detach() throws -> FileDescriptor {
        try assertNotClosed()
        closed = true
        return tcpdetach(socket)
    }

    public func close() -> Bool {
        if closed {
            return false
        }

        closed = true
        tcpclose(socket)
        return true
    }

    func assertNotClosed() throws {
        if closed {
            throw TCPError.closedSocketError
        }
    }

    deinit {
        if !closed && socket != nil {
            tcpclose(socket)
        }
    }

}