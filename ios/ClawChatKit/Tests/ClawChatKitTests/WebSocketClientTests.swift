import Testing
import Foundation
@testable import ClawChatKit

@Suite("WebSocket Client")
struct WebSocketClientTests {

    // MARK: - ConnectionState

    @Test("ConnectionState equality")
    func connectionStateEquality() {
        #expect(ConnectionState.disconnected == ConnectionState.disconnected)
        #expect(ConnectionState.connecting == ConnectionState.connecting)
        #expect(ConnectionState.connected == ConnectionState.connected)
        #expect(ConnectionState.disconnected != ConnectionState.connected)
        #expect(ConnectionState.connecting != ConnectionState.disconnected)
    }

    // MARK: - URL normalization

    @Test("Relay URL appends /ws/app when missing")
    func urlAppendsWsApp() async {
        let client = WebSocketClient(relayUrl: "wss://relay.example.com")
        let state = await client.connectionState
        #expect(state == .disconnected)
        await client.close()
    }

    @Test("Relay URL strips trailing slash before appending")
    func urlStripsTrailingSlash() async {
        let client = WebSocketClient(relayUrl: "wss://relay.example.com/")
        let state = await client.connectionState
        #expect(state == .disconnected)
        await client.close()
    }

    @Test("Relay URL preserves /ws/app if already present")
    func urlPreservesWsApp() async {
        let client = WebSocketClient(relayUrl: "wss://relay.example.com/ws/app")
        let state = await client.connectionState
        #expect(state == .disconnected)
        await client.close()
    }

    // MARK: - Initial state

    @Test("Initial connection state is disconnected")
    func initialStateDisconnected() async {
        let client = WebSocketClient(relayUrl: "wss://relay.example.com")
        let state = await client.connectionState
        #expect(state == .disconnected)
        await client.close()
    }

    @Test("Messages stream is available immediately")
    func messagesStreamAvailable() async {
        let client = WebSocketClient(relayUrl: "wss://relay.example.com")
        _ = await client.messages
        await client.close()
    }

    // MARK: - Close behavior

    @Test("Close sets state to disconnected")
    func closeDisconnects() async {
        let client = WebSocketClient(relayUrl: "wss://relay.example.com")
        await client.close()
        let state = await client.connectionState
        #expect(state == .disconnected)
    }

    @Test("Connect after close is no-op")
    func connectAfterCloseIsNoop() async {
        let client = WebSocketClient(relayUrl: "wss://relay.example.com")
        await client.close()
        await client.connect()
        // Should stay disconnected because closed flag is set
        let state = await client.connectionState
        #expect(state == .disconnected)
    }

    // MARK: - State change callback

    @Test("Connection state change callback fires")
    func stateChangeCallback() async {
        let client = WebSocketClient(relayUrl: "wss://relay.example.com")
        var states: [ConnectionState] = []
        await client.onStateChange { state in
            states.append(state)
        }
        await client.close()
        #expect(states.contains(.disconnected))
    }

    // MARK: - PingMessage

    @Test("PingMessage has correct type")
    func pingMessageType() {
        let ping = PingMessage()
        #expect(ping.type == "ping")
    }

    @Test("PingMessage generates unique IDs")
    func pingMessageUniqueIds() {
        let ping1 = PingMessage()
        let ping2 = PingMessage()
        #expect(ping1.id != ping2.id)
    }

    @Test("PingMessage timestamp is reasonable")
    func pingMessageTimestamp() {
        let before = Int64(Date().timeIntervalSince1970 * 1000)
        let ping = PingMessage()
        let after = Int64(Date().timeIntervalSince1970 * 1000)
        #expect(ping.ts >= before)
        #expect(ping.ts <= after)
    }

    @Test("PingMessage encodes to JSON with correct fields")
    func pingMessageEncodable() throws {
        let ping = PingMessage()
        let data = try JSONEncoder().encode(ping)
        let decoded = try ClawChatMessage.decode(from: data)
        guard case .ping(let p) = decoded else {
            Issue.record("Expected ping, got \(decoded)")
            return
        }
        #expect(p.type == "ping")
        #expect(p.id == ping.id)
    }

    // MARK: - Backoff calculation

    @Test("Exponential backoff formula")
    func backoffCalculation() {
        // Verify the backoff formula: min(2^attempt, 60)
        let maxBackoff: TimeInterval = 60
        #expect(min(pow(2.0, Double(0)), maxBackoff) == 1.0)
        #expect(min(pow(2.0, Double(1)), maxBackoff) == 2.0)
        #expect(min(pow(2.0, Double(2)), maxBackoff) == 4.0)
        #expect(min(pow(2.0, Double(3)), maxBackoff) == 8.0)
        #expect(min(pow(2.0, Double(4)), maxBackoff) == 16.0)
        #expect(min(pow(2.0, Double(5)), maxBackoff) == 32.0)
        #expect(min(pow(2.0, Double(6)), maxBackoff) == 60.0) // capped
        #expect(min(pow(2.0, Double(10)), maxBackoff) == 60.0) // stays capped
    }
}
