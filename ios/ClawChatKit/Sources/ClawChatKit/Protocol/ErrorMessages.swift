import Foundation

// MARK: - Error Code

public enum ClawChatErrorCode: Codable, Sendable, Equatable {
    case gatewayOffline
    case agentNotFound
    case sessionNotFound
    case unauthorized
    case rateLimited
    case payloadTooLarge
    case internalError
    case invalidMessage
    case incompatibleVersion
    case unknown(String)

    public init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        switch raw {
        case "gateway_offline": self = .gatewayOffline
        case "agent_not_found": self = .agentNotFound
        case "session_not_found": self = .sessionNotFound
        case "unauthorized": self = .unauthorized
        case "rate_limited": self = .rateLimited
        case "payload_too_large": self = .payloadTooLarge
        case "internal_error": self = .internalError
        case "invalid_message": self = .invalidMessage
        case "incompatible_version": self = .incompatibleVersion
        default: self = .unknown(raw)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .gatewayOffline: try container.encode("gateway_offline")
        case .agentNotFound: try container.encode("agent_not_found")
        case .sessionNotFound: try container.encode("session_not_found")
        case .unauthorized: try container.encode("unauthorized")
        case .rateLimited: try container.encode("rate_limited")
        case .payloadTooLarge: try container.encode("payload_too_large")
        case .internalError: try container.encode("internal_error")
        case .invalidMessage: try container.encode("invalid_message")
        case .incompatibleVersion: try container.encode("incompatible_version")
        case .unknown(let raw): try container.encode(raw)
        }
    }
}

// MARK: - Error Message

public struct ErrorMessage: BaseMessage, Sendable {
    public let type: String
    public let id: String
    public let ts: Int64
    public let code: ClawChatErrorCode
    public let message: String
    public let requestId: String?
}
