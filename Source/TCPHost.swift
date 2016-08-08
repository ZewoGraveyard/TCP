import CLibvenice

public final class TCPHost : Host {
    private let socket: tcpsock?

    public init(host: String, port: Int, backlog: Int = 128, reusePort: Bool = false) throws {
        let ip = try IP(localAddress: host, port: port)
        self.socket = tcplisten(ip.address, Int32(backlog), reusePort ? 1 : 0)
        try ensureLastOperationSucceeded()
    }

    public func accept(deadline: Double) throws -> Stream {
        let socket = tcpaccept(self.socket, deadline.int64milliseconds)
        try ensureLastOperationSucceeded()
        return try TCPConnection(with: socket!)
    }
}
