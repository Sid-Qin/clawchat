import Foundation

// MARK: - Pair Generate

public struct PairGenerate: BaseMessage, Sendable {
    public let type: String = "pair.generate"
    public let id: String
    public let ts: Int64

    public init() {
        self.id = UUID().uuidString
        self.ts = Int64(Date().timeIntervalSince1970 * 1000)
    }
}

// MARK: - Pair Code

public struct PairCode: BaseMessage, Sendable {
    public let type: String
    public let id: String
    public let ts: Int64
    public let code: String
    public let expiresAt: Int64
}

// MARK: - Device Info

public struct DeviceInfo: Codable, Sendable {
    public let deviceId: String
    public let deviceName: String
    public let platform: AppPlatform
    public let pairedAt: Int64?
    public let lastSeen: Int64?
}

// MARK: - Devices List

public struct DevicesList: BaseMessage, Sendable {
    public let type: String = "devices.list"
    public let id: String
    public let ts: Int64

    public init() {
        self.id = UUID().uuidString
        self.ts = Int64(Date().timeIntervalSince1970 * 1000)
    }
}

public struct DevicesListResponse: BaseMessage, Sendable {
    public let type: String
    public let id: String
    public let ts: Int64
    public let devices: [DeviceInfo]
}

// MARK: - Devices Revoke

public struct DevicesRevoke: BaseMessage, Sendable {
    public let type: String = "devices.revoke"
    public let id: String
    public let ts: Int64
    public let deviceId: String

    public init(deviceId: String) {
        self.id = UUID().uuidString
        self.ts = Int64(Date().timeIntervalSince1970 * 1000)
        self.deviceId = deviceId
    }
}
