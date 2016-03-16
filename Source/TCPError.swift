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

@_exported import System
@_exported import Data

public enum TCPError: ErrorProtocol {
    case Unknown(description: String)
    case BrokenPipe(description: String, data: Data)
    case ConnectionResetByPeer(description: String, data: Data)
    case NoBufferSpaceAvailabe(description: String, data: Data)
    case OperationTimedOut(description: String, data: Data)
    case ClosedSocket(description: String)

    static func lastReceiveErrorWithData(source: Data, bytesProcessed: Int) -> TCPError {
        let data = source.prefix(bytesProcessed)
        return lastErrorWithData(data)
    }

    static func lastSendErrorWithData(source: Data, bytesProcessed: Int) -> TCPError {
        let data = source.suffix(bytesProcessed)
        return lastErrorWithData(data)
    }

    static func lastErrorWithData(data: Data) -> TCPError {
        switch errno {
        case EPIPE:
            return .BrokenPipe(description: lastErrorDescription, data: data)
        case ECONNRESET:
            return .ConnectionResetByPeer(description: lastErrorDescription, data: data)
        case ENOBUFS:
            return .NoBufferSpaceAvailabe(description: lastErrorDescription, data: data)
        case ETIMEDOUT:
            return .OperationTimedOut(description: lastErrorDescription, data: data)
        default:
            return .Unknown(description: lastErrorDescription)
        }
    }

    static var lastErrorDescription: String {
        return String(validatingUTF8: strerror(errno))!
    }

    static var lastError: TCPError {
        switch errno {
        case EPIPE:
            return .BrokenPipe(description: lastErrorDescription, data: nil)
        case ECONNRESET:
            return .ConnectionResetByPeer(description: lastErrorDescription, data: nil)
        case ENOBUFS:
            return .NoBufferSpaceAvailabe(description: lastErrorDescription, data: nil)
        case ETIMEDOUT:
            return .OperationTimedOut(description: lastErrorDescription, data: nil)
        default:
            return .Unknown(description: lastErrorDescription)
        }
    }

    static var closedSocketError: TCPError {
        return TCPError.ClosedSocket(description: "Closed socket")
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
        case Unknown(let description):
            return description
        case .BrokenPipe(let description, _):
            return description
        case ConnectionResetByPeer(let description, _):
            return description
        case NoBufferSpaceAvailabe(let description, _):
            return description
        case OperationTimedOut(let description, _):
            return description
        case ClosedSocket(let description):
            return description
        }
    }
}