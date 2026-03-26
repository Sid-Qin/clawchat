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
            if Self.sessionKeysMatch(sessionKey, targetSessionKey) {
                return true
            }

            // Backward compatibility: older gateways/plugins may not echo sessionKey yet.
            return sessionKey == nil && agentId == targetAgentId
        }

        guard sessionKey == nil else { return false }
        return agentId == targetAgentId
    }

    private static func sessionKeysMatch(_ lhs: String?, _ rhs: String?) -> Bool {
        guard let lhs = normalizedSessionKey(lhs),
              let rhs = normalizedSessionKey(rhs) else {
            return false
        }

        if lhs == rhs {
            return true
        }

        let lhsAgentRest = agentSessionRest(lhs)
        let rhsAgentRest = agentSessionRest(rhs)

        if let lhsAgentRest, let rhsAgentRest {
            return lhsAgentRest == rhsAgentRest
        }
        if let lhsAgentRest {
            return lhsAgentRest == rhs
        }
        if let rhsAgentRest {
            return lhs == rhsAgentRest
        }

        return false
    }

    private static func normalizedSessionKey(_ value: String?) -> String? {
        guard let value else { return nil }
        let normalized = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return normalized.isEmpty ? nil : normalized
    }

    private static func agentSessionRest(_ sessionKey: String) -> String? {
        let parts = sessionKey.split(separator: ":", maxSplits: 2, omittingEmptySubsequences: false)
        guard parts.count == 3, parts[0] == "agent" else { return nil }
        return String(parts[2])
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
