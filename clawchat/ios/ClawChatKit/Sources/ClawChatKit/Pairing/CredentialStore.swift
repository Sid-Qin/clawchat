import Foundation

/// Keys used for Keychain storage.
private enum CredentialKey {
    static let deviceToken = "deviceToken"
    static let relayUrl = "relayUrl"
    static let gatewayId = "gatewayId"
}

/// Stored ClawChat credentials.
public struct ClawChatCredentials: Sendable {
    public let deviceToken: String
    public let relayUrl: String
    public let gatewayId: String
}

/// Manages credential persistence using KeychainStore.
public struct CredentialStore: Sendable {
    private let keychain: KeychainStore

    public init(keychain: KeychainStore = KeychainStore()) {
        self.keychain = keychain
    }

    /// Save credentials after successful pairing.
    public func save(deviceToken: String, relayUrl: String, gatewayId: String) throws {
        try keychain.save(key: CredentialKey.deviceToken, value: deviceToken)
        try keychain.save(key: CredentialKey.relayUrl, value: relayUrl)
        try keychain.save(key: CredentialKey.gatewayId, value: gatewayId)
    }

    /// Load stored credentials, returns nil if any are missing.
    public func load() throws -> ClawChatCredentials? {
        guard let deviceToken = try keychain.load(key: CredentialKey.deviceToken),
              let relayUrl = try keychain.load(key: CredentialKey.relayUrl),
              let gatewayId = try keychain.load(key: CredentialKey.gatewayId) else {
            return nil
        }
        return ClawChatCredentials(deviceToken: deviceToken, relayUrl: relayUrl, gatewayId: gatewayId)
    }

    /// Clear all stored credentials (e.g., on unauthorized rejection).
    public func clear() throws {
        try keychain.delete(key: CredentialKey.deviceToken)
        try keychain.delete(key: CredentialKey.relayUrl)
        try keychain.delete(key: CredentialKey.gatewayId)
    }
}
