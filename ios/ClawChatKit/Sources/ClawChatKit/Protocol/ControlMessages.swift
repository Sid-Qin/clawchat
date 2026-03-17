import Foundation

// MARK: - Presence Status

public enum PresenceStatus: String, Codable, Sendable {
    case online, away, offline
}

// MARK: - Typing

public struct Typing: BaseMessage, Sendable {
    public let type: String
    public let id: String
    public let ts: Int64
    public let agentId: String?
    public let active: Bool
    public let label: String?

    public init(agentId: String? = "default", active: Bool) {
        self.type = "typing"
        self.id = UUID().uuidString
        self.ts = Int64(Date().timeIntervalSince1970 * 1000)
        self.agentId = agentId
        self.active = active
        self.label = nil
    }
}

// MARK: - Presence

public struct Presence: BaseMessage, Sendable {
    public let type: String
    public let id: String
    public let ts: Int64
    public let status: PresenceStatus?
    public let online: Bool?
    public let gatewayId: String?
}

// MARK: - Status Request / Response

public struct StatusRequest: BaseMessage, Sendable {
    public let type: String = "status.request"
    public let id: String
    public let ts: Int64

    public init() {
        self.id = UUID().uuidString
        self.ts = Int64(Date().timeIntervalSince1970 * 1000)
    }
}

public struct AgentMeta: Codable, Sendable {
    public let name: String?
    public let model: String?
    public let avatar: String?
}

public struct StatusResponse: BaseMessage, Sendable {
    public let type: String
    public let id: String
    public let ts: Int64
    public let gatewayOnline: Bool
    public let agents: [String]?
    public let agentsMeta: [String: AgentMeta]?
    public let connectedDevices: Int?
}
