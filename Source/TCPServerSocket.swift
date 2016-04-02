// TCPServerSocket.swift
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

public final class TCPServerSocket: TCPSocket {
    public init(ip: IP, backlog: Int = 128, reusePort: Bool = false) throws {
        let info = TCPSocketConnectionInfo(host: ip.host, port: ip.port, name: "TCPServerSocket")
        try super.init(socket: tcplisten(ip.address, Int32(backlog), reusePort ? 1 : 0), connectionInfo: info)
    }

    public init(fileDescriptor: FileDescriptor) throws {
        let info = TCPSocketConnectionInfo(name: "TCPServerSocket")
        try super.init(socket: tcpattach(fileDescriptor, 1), connectionInfo: info)
    }

    public func accept(deadline: Deadline = never) throws -> TCPClientSocket {
        try assertNotClosed()
        return try TCPClientSocket(socket: tcpaccept(socket, deadline))
    }

    public func attach(fileDescriptor: FileDescriptor) throws {
        try super.attach(fileDescriptor, isServer: true)
    }
}