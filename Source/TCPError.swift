// TCPError.swift
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

public enum TCPError: ErrorProtocol {
    case unknown(description: String)
    case brokenPipe(description: String, data: Data)
    case connectionResetByPeer(description: String, data: Data)
    case noBufferSpaceAvailabe(description: String, data: Data)
    case operationTimedOut(description: String, data: Data)
    case closedSocket(description: String)

    static func lastReceiveErrorWithData(source: Data, bytesProcessed: Int) -> TCPError {
        let data = Data(source.prefix(bytesProcessed))
        return lastErrorWithData(data)
    }

    static func lastSendErrorWithData(source: Data, bytesProcessed: Int) -> TCPError {
        let data = Data(source.suffix(bytesProcessed))
        return lastErrorWithData(data)
    }

    static func lastErrorWithData(data: Data) -> TCPError {
        switch errno {
        case EPIPE:
            return .brokenPipe(description: lastErrorDescription, data: data)
        case ECONNRESET:
            return .connectionResetByPeer(description: lastErrorDescription, data: data)
        case ENOBUFS:
            return .noBufferSpaceAvailabe(description: lastErrorDescription, data: data)
        case ETIMEDOUT:
            return .operationTimedOut(description: lastErrorDescription, data: data)
        default:
            return .unknown(description: lastErrorDescription)
        }
    }

    static var lastErrorDescription: String {
        return String(validatingUTF8: strerror(errno))!
    }

    static var lastError: TCPError {
        switch errno {
        case EPIPE:
            return .brokenPipe(description: lastErrorDescription, data: Data())
        case ECONNRESET:
            return .connectionResetByPeer(description: lastErrorDescription, data: Data())
        case ENOBUFS:
            return .noBufferSpaceAvailabe(description: lastErrorDescription, data: Data())
        case ETIMEDOUT:
            return .operationTimedOut(description: lastErrorDescription, data: Data())
        default:
            return .unknown(description: lastErrorDescription)
        }
    }

    static var closedSocketError: TCPError {
        return TCPError.closedSocket(description: "Closed socket")
    }

    static func assertNoError() throws {
        if errno != 0 {
            throw TCPError.lastError
        }
    }

    static func assertNoReceiveErrorWithData(data: Data, bytesProcessed: Int) throws {
        if errno != 0 {
            throw TCPError.lastReceiveErrorWithData(data, bytesProcessed: bytesProcessed)
        }
    }

    static func assertNoSendErrorWithData(data: Data, bytesProcessed: Int) throws {
        if errno != 0 {
            throw TCPError.lastSendErrorWithData(data, bytesProcessed: bytesProcessed)
        }
    }
}

extension TCPError: CustomStringConvertible {
    public var description: String {
        switch self {
        case unknown(let description):
            return description
        case .brokenPipe(let description, _):
            return description
        case connectionResetByPeer(let description, _):
            return description
        case noBufferSpaceAvailabe(let description, _):
            return description
        case operationTimedOut(let description, _):
            return description
        case closedSocket(let description):
            return description
        }
    }
}