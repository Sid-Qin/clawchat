import Foundation

/// Shared envelope fields for all ClawChat wire protocol messages.
public protocol BaseMessage: Codable, Sendable {
    var type: String { get }
    var id: String { get }
    var ts: Int64 { get }
}
