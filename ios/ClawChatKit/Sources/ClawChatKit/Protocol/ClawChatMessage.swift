import Foundation

/// Discriminated union of all ClawChat wire protocol messages.
/// Decodes the `type` field first, then the appropriate struct.
public enum ClawChatMessage: Sendable {
    // Connection
    case appPaired(AppPaired)
    case appPairError(AppPairError)
    case appConnected(AppConnected)

    // Messaging
    case messageInbound(MessageInbound)
    case messageOutbound(MessageOutbound)
    case messageStream(MessageStream)
    case messageReasoning(MessageReasoning)
    case toolEvent(ToolEvent)

    // Control
    case typing(Typing)
    case presence(Presence)
    case statusResponse(StatusResponse)

    // Pairing
    case pairCode(PairCode)
    case devicesListResponse(DevicesListResponse)

    // Errors
    case error(ErrorMessage)

    // Ping/Pong
    case ping(PingMessage)
    case pong(PongMessage)

    // Unknown
    case unknown(type: String, raw: Data)
}

// MARK: - Ping / Pong

public struct PingMessage: BaseMessage, Sendable {
    public let type: String = "ping"
    public let id: String
    public let ts: Int64

    public init() {
        self.id = UUID().uuidString
        self.ts = Int64(Date().timeIntervalSince1970 * 1000)
    }
}

public struct PongMessage: BaseMessage, Sendable {
    public let type: String
    public let id: String
    public let ts: Int64
}

// MARK: - Decoding

private struct MessageEnvelope: Decodable {
    let type: String
}

extension ClawChatMessage {
    /// Decode a wire protocol message from raw JSON data.
    public static func decode(from data: Data) throws -> ClawChatMessage {
        let decoder = JSONDecoder()
        let envelope = try decoder.decode(MessageEnvelope.self, from: data)

        switch envelope.type {
        // Connection
        case "app.paired":
            return .appPaired(try decoder.decode(AppPaired.self, from: data))
        case "app.pair.error":
            return .appPairError(try decoder.decode(AppPairError.self, from: data))
        case "app.connected":
            return .appConnected(try decoder.decode(AppConnected.self, from: data))

        // Messaging
        case "message.inbound":
            return .messageInbound(try decoder.decode(MessageInbound.self, from: data))
        case "message.outbound":
            return .messageOutbound(try decoder.decode(MessageOutbound.self, from: data))
        case "message.stream":
            return .messageStream(try decoder.decode(MessageStream.self, from: data))
        case "message.reasoning":
            return .messageReasoning(try decoder.decode(MessageReasoning.self, from: data))
        case "tool.event":
            return .toolEvent(try decoder.decode(ToolEvent.self, from: data))

        // Control
        case "typing":
            return .typing(try decoder.decode(Typing.self, from: data))
        case "presence":
            return .presence(try decoder.decode(Presence.self, from: data))
        case "status.response":
            return .statusResponse(try decoder.decode(StatusResponse.self, from: data))

        // Pairing
        case "pair.code":
            return .pairCode(try decoder.decode(PairCode.self, from: data))
        case "devices.list.response":
            return .devicesListResponse(try decoder.decode(DevicesListResponse.self, from: data))

        // Errors
        case "error":
            return .error(try decoder.decode(ErrorMessage.self, from: data))

        // Ping/Pong
        case "ping":
            return .ping(try decoder.decode(PingMessage.self, from: data))
        case "pong":
            return .pong(try decoder.decode(PongMessage.self, from: data))

        default:
            return .unknown(type: envelope.type, raw: data)
        }
    }
}
