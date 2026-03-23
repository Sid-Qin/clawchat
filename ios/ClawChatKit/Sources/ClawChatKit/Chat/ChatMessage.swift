import Foundation

/// Role of a chat message.
public enum MessageRole: Sendable {
    case user
    case assistant
}

/// A tracked tool event within a message.
public struct ChatToolEvent: Identifiable, Sendable {
    public let id: String
    public let tool: String
    public var phase: ToolPhase
    public var label: String?
    public var result: AnyCodable?
}

/// A single chat message for display.
public struct ChatMessage: Identifiable, Sendable {
    public let id: String
    public let role: MessageRole
    public var text: String
    public var reasoning: String?
    public var toolEvents: [ChatToolEvent]
    public var isStreaming: Bool
    public var isError: Bool
    public let timestamp: Date
    public var agentId: String?

    public init(
        id: String = UUID().uuidString,
        role: MessageRole,
        text: String,
        reasoning: String? = nil,
        toolEvents: [ChatToolEvent] = [],
        isStreaming: Bool = false,
        isError: Bool = false,
        timestamp: Date = Date(),
        agentId: String? = nil
    ) {
        self.id = id
        self.role = role
        self.text = text
        self.reasoning = reasoning
        self.toolEvents = toolEvents
        self.isStreaming = isStreaming
        self.isError = isError
        self.timestamp = timestamp
        self.agentId = agentId
    }
}
