import Foundation

// MARK: - Message Inbound (app → gateway)

public enum MessageAttachmentType: String, Codable, Sendable {
    case image
    case video
    case audio
    case file
}

public struct MessageAttachment: Codable, Sendable, Equatable {
    public let type: MessageAttachmentType
    public let mimeType: String?
    public let filename: String?
    public let size: Int?
    public let data: String?
    public let url: String?
    public let fileId: String?

    public init(
        type: MessageAttachmentType,
        mimeType: String? = nil,
        filename: String? = nil,
        size: Int? = nil,
        data: String? = nil,
        url: String? = nil,
        fileId: String? = nil
    ) {
        self.type = type
        self.mimeType = mimeType
        self.filename = filename
        self.size = size
        self.data = data
        self.url = url
        self.fileId = fileId
    }
}

public struct MessageInbound: BaseMessage, Sendable {
    public let type: String = "message.inbound"
    public let id: String
    public let ts: Int64
    public let text: String?
    public let agentId: String?
    public let attachments: [MessageAttachment]?
    public let sessionKey: String?
    public let replyTo: String?
    public let threadId: String?

    public init(
        text: String? = nil,
        agentId: String? = "default",
        attachments: [MessageAttachment]? = nil,
        sessionKey: String? = nil
    ) {
        self.id = UUID().uuidString
        self.ts = Int64(Date().timeIntervalSince1970 * 1000)
        self.text = text
        self.agentId = agentId
        self.attachments = attachments
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
    public let sessionKey: String?
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
    public let sessionKey: String?
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
    public let sessionKey: String?
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
    public let sessionKey: String?
    public let text: String?
    public let media: [MediaItem]?
}

public struct MediaItem: Codable, Sendable {
    public let url: String
    public let mimeType: String?
    public let filename: String?
}
