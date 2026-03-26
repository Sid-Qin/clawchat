import Foundation

/// WebSocket connection state.
public enum ConnectionState: Sendable, Equatable {
    case disconnected
    case connecting
    case connected
}
