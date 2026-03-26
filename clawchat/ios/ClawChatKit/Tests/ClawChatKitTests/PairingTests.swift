import Testing
import Foundation
@testable import ClawChatKit

@Suite("Pairing")
struct PairingTests {

    // MARK: - PairingError

    @Test("PairingError equality")
    func pairingErrorEquality() {
        #expect(PairingError.invalidCode == PairingError.invalidCode)
        #expect(PairingError.codeExpired == PairingError.codeExpired)
        #expect(PairingError.invalidToken == PairingError.invalidToken)
        #expect(PairingError.invalidDeviceToken == PairingError.invalidDeviceToken)
        #expect(PairingError.timeout == PairingError.timeout)
        #expect(PairingError.networkError("a") == PairingError.networkError("a"))
        #expect(PairingError.networkError("a") != PairingError.networkError("b"))
        #expect(PairingError.invalidCode != PairingError.codeExpired)
        #expect(PairingError.invalidToken != PairingError.invalidDeviceToken)
    }

    // MARK: - AppPair message

    @Test("AppPair message has correct fields")
    func appPairMessage() throws {
        let pair = AppPair(pairingCode: "XEW-P3P", deviceName: "iPhone")
        #expect(pair.type == "app.pair")
        #expect(pair.pairingCode == "XEW-P3P")
        #expect(pair.deviceName == "iPhone")
        #expect(pair.platform == .ios)
        #expect(pair.protocolVersion == "0.1")

        let data = try JSONEncoder().encode(pair)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        #expect(json["type"] as? String == "app.pair")
        #expect(json["pairingCode"] as? String == "XEW-P3P")
    }

    // MARK: - AppConnect message

    @Test("AppConnect message has correct fields")
    func appConnectMessage() throws {
        let connect = AppConnect(deviceToken: "tok-123")
        #expect(connect.type == "app.connect")
        #expect(connect.deviceToken == "tok-123")
        #expect(connect.protocolVersion == "0.1")

        let data = try JSONEncoder().encode(connect)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        #expect(json["type"] as? String == "app.connect")
        #expect(json["deviceToken"] as? String == "tok-123")
    }

    // MARK: - PairErrorReason mapping

    @Test("PairErrorReason decodes invalid_code")
    func pairErrorReasonInvalidCode() throws {
        let json = """
        {"type":"app.pair.error","id":"e1","ts":1000,"error":"invalid_code","message":"Invalid code"}
        """.data(using: .utf8)!

        let msg = try ClawChatMessage.decode(from: json)
        guard case .appPairError(let err) = msg else {
            Issue.record("Expected appPairError")
            return
        }
        #expect(err.error == .invalidCode)
    }

    @Test("PairErrorReason decodes code_expired")
    func pairErrorReasonCodeExpired() throws {
        let json = """
        {"type":"app.pair.error","id":"e1","ts":1000,"error":"code_expired","message":"Code expired"}
        """.data(using: .utf8)!

        let msg = try ClawChatMessage.decode(from: json)
        guard case .appPairError(let err) = msg else {
            Issue.record("Expected appPairError")
            return
        }
        #expect(err.error == .codeExpired)
    }

    // MARK: - CredentialStore

    @Test("CredentialStore save and load relay profile")
    func credentialStoreSaveLoadRelay() throws {
        let keychain = KeychainStore(service: "com.clawchat.test.\(UUID().uuidString)")
        let store = CredentialStore(keychain: keychain)

        try store.saveRelay(deviceToken: "tok-abc", relayUrl: "wss://relay.example.com", gatewayId: "gw-1")

        let profile = try store.load()
        #expect(profile != nil)
        #expect(profile?.method == .relay)
        #expect(profile?.deviceToken == "tok-abc")
        #expect(profile?.endpointUrl == "wss://relay.example.com")
        #expect(profile?.gatewayId == "gw-1")

        try store.clear()
    }

    @Test("CredentialStore save and load direct profile")
    func credentialStoreSaveLoadDirect() throws {
        let keychain = KeychainStore(service: "com.clawchat.test.\(UUID().uuidString)")
        let store = CredentialStore(keychain: keychain)

        try store.saveDirect(deviceToken: "dt-xyz", gatewayUrl: "wss://gw.example.com", gatewayId: "gw-2")

        let profile = try store.load()
        #expect(profile != nil)
        #expect(profile?.method == .direct)
        #expect(profile?.deviceToken == "dt-xyz")
        #expect(profile?.endpointUrl == "wss://gw.example.com")
        #expect(profile?.gatewayId == "gw-2")

        try store.clear()
    }

    @Test("CredentialStore load returns nil when empty")
    func credentialStoreLoadEmpty() throws {
        let keychain = KeychainStore(service: "com.clawchat.test.\(UUID().uuidString)")
        let store = CredentialStore(keychain: keychain)

        let profile = try store.load()
        #expect(profile == nil)
    }

    @Test("CredentialStore clear removes all credentials")
    func credentialStoreClear() throws {
        let keychain = KeychainStore(service: "com.clawchat.test.\(UUID().uuidString)")
        let store = CredentialStore(keychain: keychain)

        try store.saveRelay(deviceToken: "tok-abc", relayUrl: "wss://relay.example.com", gatewayId: "gw-1")
        try store.clear()

        let profile = try store.load()
        #expect(profile == nil)
    }

    // MARK: - KeychainStore

    @Test("KeychainStore save, load, delete cycle")
    func keychainCycle() throws {
        let keychain = KeychainStore(service: "com.clawchat.test.\(UUID().uuidString)")

        try keychain.save(key: "testKey", value: "testValue")
        let loaded = try keychain.load(key: "testKey")
        #expect(loaded == "testValue")

        try keychain.delete(key: "testKey")
        let afterDelete = try keychain.load(key: "testKey")
        #expect(afterDelete == nil)
    }

    @Test("KeychainStore overwrite existing value")
    func keychainOverwrite() throws {
        let keychain = KeychainStore(service: "com.clawchat.test.\(UUID().uuidString)")

        try keychain.save(key: "testKey", value: "value1")
        try keychain.save(key: "testKey", value: "value2")

        let loaded = try keychain.load(key: "testKey")
        #expect(loaded == "value2")

        // Cleanup
        try keychain.delete(key: "testKey")
    }

    @Test("KeychainStore load missing key returns nil")
    func keychainLoadMissing() throws {
        let keychain = KeychainStore(service: "com.clawchat.test.\(UUID().uuidString)")
        let loaded = try keychain.load(key: "nonexistent")
        #expect(loaded == nil)
    }

    @Test("KeychainStore delete individual keys")
    func keychainDeleteIndividual() throws {
        let keychain = KeychainStore(service: "com.clawchat.test.\(UUID().uuidString)")

        try keychain.save(key: "key1", value: "val1")
        try keychain.save(key: "key2", value: "val2")
        try keychain.delete(key: "key1")
        try keychain.delete(key: "key2")

        #expect(try keychain.load(key: "key1") == nil)
        #expect(try keychain.load(key: "key2") == nil)
    }
}
