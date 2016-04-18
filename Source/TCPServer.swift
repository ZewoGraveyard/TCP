// TCPServer.swift
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

public final class TCPServer: Host {
    private let socket: tcpsock?

    public init(host: String, port: Int, backlog: Int = 128, reusePort: Bool = false) throws {
        let ip = try IP(localAddress: host, port: port)
        self.socket = tcplisten(ip.address, Int32(backlog), reusePort ? 1 : 0)
        try ensureLastOperationSucceeded()
    }
    
    public func accept(timingOut deadline: Double) throws -> Stream {
        let socket = tcpaccept(self.socket, deadline.int64milliseconds)
        try ensureLastOperationSucceeded()
        return try TCPConnection(with: socket)
    }
}
