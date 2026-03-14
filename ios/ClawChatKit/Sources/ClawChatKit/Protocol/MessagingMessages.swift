import Foundation

// MARK: - Message Inbound (app → gateway)

public struct MessageInbound: BaseMessage, Sendable {
    public let type: String = "message.inbound"
    public let id: String
    public let ts: Int64
    public let text: String
    public let agentId: String?
    public let sessionKey: String?
    public let replyTo: String?
    public let threadId: String?

    public init(text: String, agentId: String? = "default", sessionKey: String? = nil) {
        self.id = UUID().uuidString
        self.ts = Int64(Date().timeIntervalSince1970 * 1000)
        self.text = text
        self.agentId = agentId
        self.sessionKey = sessionKey
        self.replyTo = nil
        self.threadId = nil
    }
}

// MARK: - Stream Phase

public enum StreamPhase: String, Codable, Sendable {
    case streaming
    case done
    case error
}

// MARK: - Message Stream (gateway → app)

public struct MessageStream: BaseMessage, Sendable {
    public let type: String
    public let id: String
    public let ts: Int64
    public let agentId: String?
    public let delta: String
    public let phase: StreamPhase
    public let finalText: String?
}

// MARK: - Reasoning Phase

public enum ReasoningPhase: String, Codable, Sendable {
    case streaming
    case done
}

// MARK: - Message Reasoning (gateway → app)

public struct MessageReasoning: BaseMessage, Sendable {
    public let type: String
    public let id: String
    public let ts: Int64
    public let agentId: String?
    public let text: String
    public let phase: ReasoningPhase?
}

// MARK: - Tool Phase

public enum ToolPhase: String, Codable, Sendable {
    case start
    case progress
    case result
    case error
}

// MARK: - Tool Event (gateway → app)

public struct ToolEvent: BaseMessage, Sendable {
    public let type: String
    public let id: String
    public let ts: Int64
    public let agentId: String?
    public let tool: String
    public let phase: ToolPhase
    public let label: String?
    public let input: AnyCodable?
    public let result: AnyCodable?
}

// MARK: - Message Outbound (gateway → app, non-streaming)

public struct MessageOutbound: BaseMessage, Sendable {
    public let type: String
    public let id: String
    public let ts: Int64
    public let agentId: String?
    public let text: String?
    public let media: [MediaItem]?
}

public struct MediaItem: Codable, Sendable {
    public let url: String
    public let mimeType: String?
    public let filename: String?
}
