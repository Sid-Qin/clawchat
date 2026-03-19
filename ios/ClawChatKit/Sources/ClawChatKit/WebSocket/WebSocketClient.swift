import Foundation

/// WebSocket client for the ClawChat relay protocol.
/// Uses URLSessionWebSocketTask with automatic reconnection and keepalive.
public actor WebSocketClient {
    // MARK: - Configuration

    private let relayUrl: String
    private let pingIntervalSeconds: TimeInterval = 30
    private let pongTimeoutSeconds: TimeInterval = 10
    private let maxBackoffSeconds: TimeInterval = 60
    private let maxReconnectAttempts = 10

    // MARK: - State

    private var webSocketTask: URLSessionWebSocketTask?
    private var session: URLSession
    private var attempt = 0
    private var closed = false
    private var pingTask: Task<Void, Never>?
    private var pongTimer: Task<Void, Never>?
    private var receiveTask: Task<Void, Never>?
    private var reconnectTask: Task<Void, Never>?

    private var messageContinuation: AsyncStream<ClawChatMessage>.Continuation?
    private var _connectionState: ConnectionState = .disconnected
    private var hasConnectedOnce = false

    // MARK: - Public API

    /// Stream of decoded protocol messages (pong messages are filtered out).
    public let messages: AsyncStream<ClawChatMessage>

    /// Current connection state.
    public var connectionState: ConnectionState {
        _connectionState
    }

    /// Callback for connection state changes (called on actor).
    public var onConnectionStateChange: ((ConnectionState) -> Void)?

    /// Called when the WebSocket reconnects after a previous successful connection.
    public var onReconnect: (@Sendable () -> Void)?

    /// Set the connection state change callback.
    public func onStateChange(_ handler: @escaping (ConnectionState) -> Void) {
        onConnectionStateChange = handler
    }

    /// Set the reconnect callback.
    public func setReconnectHandler(_ handler: @escaping @Sendable () -> Void) {
        onReconnect = handler
    }

    // MARK: - Init

    public init(relayUrl: String) {
        // Normalize URL: strip trailing slash, append /ws/app if needed
        var url = relayUrl.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        if !url.hasSuffix("/ws/app") {
            url += "/ws/app"
        }
        self.relayUrl = url
        self.session = URLSession(configuration: .default)

        var continuation: AsyncStream<ClawChatMessage>.Continuation!
        self.messages = AsyncStream { continuation = $0 }
        self.messageContinuation = continuation
    }

    // MARK: - Connect

    /// Start the WebSocket connection. Reconnects automatically on disconnect.
    public func connect() {
        guard !closed else { return }
        setConnectionState(.connecting)
        createWebSocket()
    }

    /// Gracefully close the connection. No automatic reconnection.
    public func close() {
        closed = true
        cancelAll()
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        setConnectionState(.disconnected)
        messageContinuation?.finish()
    }

    /// Send a Codable message as JSON text frame.
    public func send<T: Encodable>(_ message: T) {
        guard let task = webSocketTask else {
            print("[ClawChatKit] send() dropped: no webSocketTask")
            return
        }
        guard task.state == .running else {
            print("[ClawChatKit] send() dropped: task.state=\(task.state.rawValue) (not running)")
            return
        }
        do {
            let data = try JSONEncoder().encode(message)
            let string = String(data: data, encoding: .utf8) ?? ""
            task.send(.string(string)) { error in
                if let error {
                    print("[ClawChatKit] send() error: \(error.localizedDescription)")
                }
            }
        } catch {
            print("[ClawChatKit] send() encode error: \(error)")
        }
    }

    // MARK: - Internals

    private func createWebSocket() {
        guard let url = URL(string: relayUrl) else { return }
        let task = session.webSocketTask(with: url)
        self.webSocketTask = task
        task.resume()

        setConnectionState(.connected)

        let isReconnect = hasConnectedOnce
        hasConnectedOnce = true
        if isReconnect {
            onReconnect?()
        }

        attempt = 0
        startReceiveLoop()
        startPingLoop()
    }

    private func startReceiveLoop() {
        receiveTask?.cancel()
        receiveTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                guard let task = await self.webSocketTask else { break }
                do {
                    let wsMessage = try await task.receive()
                    await self.handleReceived(wsMessage)
                } catch {
                    // Connection closed or error
                    if !Task.isCancelled {
                        await self.handleDisconnect()
                    }
                    break
                }
            }
        }
    }

    private func handleReceived(_ wsMessage: URLSessionWebSocketTask.Message) {
        let data: Data
        switch wsMessage {
        case .string(let text):
            print("[ClawChatKit] recv:", text.prefix(200))
            guard let d = text.data(using: .utf8) else { return }
            data = d
        case .data(let d):
            data = d
        @unknown default:
            return
        }

        // Cancel pong timeout on any received message
        pongTimer?.cancel()
        pongTimer = nil

        do {
            let message = try ClawChatMessage.decode(from: data)
            // Filter pong messages — consumed internally
            if case .pong = message { return }
            messageContinuation?.yield(message)
        } catch {
            // Ignore unparseable frames
        }
    }

    private func handleDisconnect() {
        cancelAll()
        webSocketTask = nil
        setConnectionState(.disconnected)

        guard !closed else { return }

        // Give up after max attempts — avoid zombie reconnect loops
        guard attempt < maxReconnectAttempts else {
            print("[ClawChatKit] max reconnect attempts (\(maxReconnectAttempts)) reached, giving up")
            return
        }

        // Schedule reconnect with exponential backoff (1, 2, 4, 8, 16, 32, 60, 60, 60, 60)
        let delay = min(pow(2.0, Double(attempt)), maxBackoffSeconds)
        attempt += 1
        setConnectionState(.connecting)

        reconnectTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            guard !Task.isCancelled, let self else { return }
            await self.createWebSocket()
        }
    }

    // MARK: - Ping / Pong keepalive

    private func startPingLoop() {
        pingTask?.cancel()
        pingTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64(30 * 1_000_000_000))
                guard !Task.isCancelled, let self else { break }
                await self.sendPing()
            }
        }
    }

    private func sendPing() {
        let ping = PingMessage()
        send(ping)

        // Start pong timeout
        pongTimer?.cancel()
        pongTimer = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(10 * 1_000_000_000))
            guard !Task.isCancelled, let self else { return }
            // No message received in time — force reconnect
            await self.webSocketTask?.cancel(with: .abnormalClosure, reason: nil)
            await self.handleDisconnect()
        }
    }

    // MARK: - Helpers

    private func setConnectionState(_ state: ConnectionState) {
        _connectionState = state
        onConnectionStateChange?(state)
    }

    private func cancelAll() {
        pingTask?.cancel()
        pingTask = nil
        pongTimer?.cancel()
        pongTimer = nil
        receiveTask?.cancel()
        receiveTask = nil
        reconnectTask?.cancel()
        reconnectTask = nil
    }
}
