import Foundation

// MARK: - App Platform

public enum AppPlatform: String, Codable, Sendable {
    case ios, android, web, cli
}

// MARK: - App Pair

public struct AppPair: BaseMessage, Sendable {
    public let type: String = "app.pair"
    public let id: String
    public let ts: Int64
    public let pairingCode: String
    public let deviceName: String
    public let platform: AppPlatform
    public let protocolVersion: String

    public init(pairingCode: String, deviceName: String, platform: AppPlatform = .ios, protocolVersion: String = "0.1") {
        self.id = UUID().uuidString
        self.ts = Int64(Date().timeIntervalSince1970 * 1000)
        self.pairingCode = pairingCode
        self.deviceName = deviceName
        self.platform = platform
        self.protocolVersion = protocolVersion
    }
}

// MARK: - App Paired

public struct AppPaired: BaseMessage, Sendable {
    public let type: String
    public let id: String
    public let ts: Int64
    public let deviceToken: String
    public let gatewayId: String
    public let agents: [String]?
}

// MARK: - App Pair Error

public enum PairErrorReason: String, Codable, Sendable {
    case invalidCode = "invalid_code"
    case codeExpired = "code_expired"
    case expired
    case gatewayOffline = "gateway_offline"
}

public struct AppPairError: BaseMessage, Sendable {
    public let type: String
    public let id: String
    public let ts: Int64
    public let error: PairErrorReason
    public let message: String
}

// MARK: - App Connect

public struct AppConnect: BaseMessage, Sendable {
    public let type: String = "app.connect"
    public let id: String
    public let ts: Int64
    public let deviceToken: String
    public let protocolVersion: String

    public init(deviceToken: String, protocolVersion: String = "0.1") {
        self.id = UUID().uuidString
        self.ts = Int64(Date().timeIntervalSince1970 * 1000)
        self.deviceToken = deviceToken
        self.protocolVersion = protocolVersion
    }
}

// MARK: - App Connected

public struct AppConnected: BaseMessage, Sendable {
    public let type: String
    public let id: String
    public let ts: Int64
    public let gatewayId: String
    public let gatewayOnline: Bool?
    public let agents: [String]?
    public let newDeviceToken: String?
}
