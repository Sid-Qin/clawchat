import Testing
import Foundation
@testable import ClawChatKit

@Suite("Device Identity")
struct DeviceIdentityTests {

    @Test("DeviceIdentity rejects invalid raw private key material")
    func deviceIdentityRejectsInvalidRawPrivateKey() {
        #expect(throws: Error.self) {
            _ = try DeviceIdentity(rawRepresentation: Data([0x01]))
        }
    }

    @Test("DeviceIdentity loadOrCreate recovers from corrupted keychain material")
    func deviceIdentityRecoversFromCorruptedKeychainMaterial() throws {
        let keychain = KeychainStore(service: "com.clawchat.test.identity.\(UUID().uuidString)")
        try keychain.save(key: "gateway_device_private_key", value: Data([0x01]).base64EncodedString())

        let identity = DeviceIdentity.loadOrCreate(keychain: keychain)
        let block = try identity.signConnectRequest(
            clientId: GatewayProtocol.clientId,
            clientMode: GatewayProtocol.clientMode,
            role: GatewayConnectParams.defaultRole,
            scopes: GatewayConnectParams.defaultScopes,
            token: "token-123",
            nonce: "nonce-abc",
            platform: "ios",
            deviceFamily: "iPhone"
        )

        #expect(!identity.deviceId.isEmpty)
        #expect(!identity.publicKeyBase64Url.isEmpty)
        #expect(block.id == identity.deviceId)
        #expect(block.publicKey == identity.publicKeyBase64Url)
        #expect(block.nonce == "nonce-abc")
        #expect(!block.signature.isEmpty)
    }

    @Test("GatewayConnectParams make signs device auth block")
    func gatewayConnectParamsMakeSignsDeviceBlock() throws {
        let keychain = KeychainStore(service: "com.clawchat.test.identity.\(UUID().uuidString)")
        let identity = DeviceIdentity.loadOrCreate(keychain: keychain)

        let params = try GatewayConnectParams.make(
            token: "token-123",
            displayName: "Sid's iPhone",
            deviceFamily: "iPhone",
            nonce: "nonce-abc",
            identity: identity
        )

        #expect(params.auth?.token == "token-123")
        #expect(params.device?.id == identity.deviceId)
        #expect(params.device?.publicKey == identity.publicKeyBase64Url)
        #expect(params.device?.nonce == "nonce-abc")
        #expect(params.device?.signedAt != nil)
    }
}
