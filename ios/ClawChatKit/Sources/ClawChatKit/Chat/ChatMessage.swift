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

/// Route identity for a chat stream.
public struct ChatRoute: Hashable, Sendable {
    public let agentId: String?
    public let sessionKey: String?

    public init(agentId: String?, sessionKey: String? = nil) {
        self.agentId = agentId
        self.sessionKey = sessionKey
    }

    public func matches(targetAgentId: String, targetSessionKey: String?) -> Bool {
        if let targetSessionKey {
            if sessionKey == targetSessionKey {
                return true
            }

            // Backward compatibility: older gateways/plugins may not echo sessionKey yet.
            return sessionKey == nil && agentId == targetAgentId
        }

        guard sessionKey == nil else { return false }
        return agentId == targetAgentId
    }
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
    public var sessionKey: String?

    public var route: ChatRoute {
        ChatRoute(agentId: agentId, sessionKey: sessionKey)
    }

    public init(
        id: String = UUID().uuidString,
        role: MessageRole,
        text: String,
        reasoning: String? = nil,
        toolEvents: [ChatToolEvent] = [],
        isStreaming: Bool = false,
        isError: Bool = false,
        timestamp: Date = Date(),
        agentId: String? = nil,
        sessionKey: String? = nil
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
        self.sessionKey = sessionKey
    }
}
