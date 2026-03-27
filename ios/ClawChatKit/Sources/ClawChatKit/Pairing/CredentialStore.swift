import Foundation

// MARK: - Connection Method

public enum ConnectionMethod: String, Codable, Sendable {
    case relay
    case direct
}

// MARK: - Connection Profile (unified credential)

public struct ConnectionProfile: Codable, Sendable {
    public let method: ConnectionMethod
    public let endpointUrl: String
    public let gatewayId: String
    public let deviceToken: String

    public init(method: ConnectionMethod, endpointUrl: String, gatewayId: String, deviceToken: String) {
        self.method = method
        self.endpointUrl = endpointUrl
        self.gatewayId = gatewayId
        self.deviceToken = deviceToken
    }
}

/// Manages credential persistence using KeychainStore.
/// Stores a single `ConnectionProfile` as JSON under one Keychain key,
/// eliminating partial-write inconsistency risks.
public struct CredentialStore: Sendable {
    private static let profileKey = "connectionProfile"

    private let keychain: KeychainStore

    public init(keychain: KeychainStore = KeychainStore()) {
        self.keychain = keychain
    }

    // MARK: - Unified API

    public func save(profile: ConnectionProfile) throws {
        let data = try JSONEncoder().encode(profile)
        guard let json = String(data: data, encoding: .utf8) else { return }
        try keychain.save(key: Self.profileKey, value: json)
    }

    public func load() throws -> ConnectionProfile? {
        guard let json = try keychain.load(key: Self.profileKey),
              let data = json.data(using: .utf8) else {
            return try migrateLegacy()
        }
        return try JSONDecoder().decode(ConnectionProfile.self, from: data)
    }

    public func clear() throws {
        try keychain.delete(key: Self.profileKey)
        _ = try? keychain.delete(key: "deviceToken")
        _ = try? keychain.delete(key: "relayUrl")
        _ = try? keychain.delete(key: "gatewayId")
    }

    // MARK: - Convenience builders

    public func saveRelay(deviceToken: String, relayUrl: String, gatewayId: String) throws {
        try save(profile: ConnectionProfile(
            method: .relay,
            endpointUrl: relayUrl,
            gatewayId: gatewayId,
            deviceToken: deviceToken
        ))
    }

    public func saveDirect(deviceToken: String, gatewayUrl: String, gatewayId: String) throws {
        try save(profile: ConnectionProfile(
            method: .direct,
            endpointUrl: gatewayUrl,
            gatewayId: gatewayId,
            deviceToken: deviceToken
        ))
    }

    // MARK: - Legacy migration

    /// One-time migration from the old 3-key storage to the new JSON profile.
    private func migrateLegacy() throws -> ConnectionProfile? {
        guard let deviceToken = try keychain.load(key: "deviceToken"),
              let relayUrl = try keychain.load(key: "relayUrl"),
              let gatewayId = try keychain.load(key: "gatewayId") else {
            return nil
        }
        let profile = ConnectionProfile(
            method: .relay,
            endpointUrl: relayUrl,
            gatewayId: gatewayId,
            deviceToken: deviceToken
        )
        _ = try? save(profile: profile)
        _ = try? keychain.delete(key: "deviceToken")
        _ = try? keychain.delete(key: "relayUrl")
        _ = try? keychain.delete(key: "gatewayId")
        return profile
    }
}
