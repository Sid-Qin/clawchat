import Testing
import Foundation
@testable import ClawChatKit

@Suite("Protocol Message Decoding")
struct ProtocolTests {

    @Test("Decode message.stream with streaming phase")
    func decodeStreamDelta() throws {
        let json = """
        {"type":"message.stream","id":"abc","ts":1234,"agentId":"default","delta":"hello","phase":"streaming"}
        """.data(using: .utf8)!

        let msg = try ClawChatMessage.decode(from: json)
        guard case .messageStream(let stream) = msg else {
            Issue.record("Expected messageStream, got \(msg)")
            return
        }
        #expect(stream.delta == "hello")
        #expect(stream.phase == .streaming)
        #expect(stream.id == "abc")
    }

    @Test("Decode message.stream with done phase and finalText")
    func decodeStreamDone() throws {
        let json = """
        {"type":"message.stream","id":"abc","ts":1234,"delta":"","phase":"done","finalText":"full response"}
        """.data(using: .utf8)!

        let msg = try ClawChatMessage.decode(from: json)
        guard case .messageStream(let stream) = msg else {
            Issue.record("Expected messageStream")
            return
        }
        #expect(stream.phase == .done)
        #expect(stream.finalText == "full response")
    }

    @Test("Decode message.stream preserves sessionKey")
    func decodeStreamSessionKey() throws {
        let json = """
        {"type":"message.stream","id":"abc","ts":1234,"agentId":"default","sessionKey":"session-a","delta":"hello","phase":"streaming"}
        """.data(using: .utf8)!

        let msg = try ClawChatMessage.decode(from: json)
        guard case .messageStream(let stream) = msg else {
            Issue.record("Expected messageStream")
            return
        }

        #expect(reflectedOptionalString(named: "sessionKey", from: stream) == "session-a")
    }

    @Test("Decode app.paired")
    func decodeAppPaired() throws {
        let json = """
        {"type":"app.paired","id":"p1","ts":1000,"deviceToken":"tok-123","gatewayId":"gw-1","agents":["hulu::呼噜::claude-opus-4-6"]}
        """.data(using: .utf8)!

        let msg = try ClawChatMessage.decode(from: json)
        guard case .appPaired(let paired) = msg else {
            Issue.record("Expected appPaired")
            return
        }
        #expect(paired.deviceToken == "tok-123")
        #expect(paired.gatewayId == "gw-1")
        #expect(paired.agents == ["hulu::呼噜::claude-opus-4-6"])
    }

    @Test("Decode app.pair.error")
    func decodePairError() throws {
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

    @Test("Decode tool.event start")
    func decodeToolEvent() throws {
        let json = """
        {"type":"tool.event","id":"t1","ts":1000,"agentId":"default","tool":"web_search","phase":"start","label":"Searching..."}
        """.data(using: .utf8)!

        let msg = try ClawChatMessage.decode(from: json)
        guard case .toolEvent(let tool) = msg else {
            Issue.record("Expected toolEvent")
            return
        }
        #expect(tool.tool == "web_search")
        #expect(tool.phase == .start)
        #expect(tool.label == "Searching...")
    }

    @Test("Decode tool.event preserves sessionKey")
    func decodeToolEventSessionKey() throws {
        let json = """
        {"type":"tool.event","id":"t1","ts":1000,"agentId":"default","sessionKey":"session-a","tool":"web_search","phase":"result","label":"Searching..."}
        """.data(using: .utf8)!

        let msg = try ClawChatMessage.decode(from: json)
        guard case .toolEvent(let tool) = msg else {
            Issue.record("Expected toolEvent")
            return
        }

        #expect(reflectedOptionalString(named: "sessionKey", from: tool) == "session-a")
    }

    @Test("Decode error message")
    func decodeError() throws {
        let json = """
        {"type":"error","id":"e1","ts":1000,"code":"gateway_offline","message":"Gateway is not connected"}
        """.data(using: .utf8)!

        let msg = try ClawChatMessage.decode(from: json)
        guard case .error(let err) = msg else {
            Issue.record("Expected error")
            return
        }
        #expect(err.code == .gatewayOffline)
        #expect(err.message == "Gateway is not connected")
    }

    @Test("Decode typing")
    func decodeTyping() throws {
        let json = """
        {"type":"typing","id":"ty1","ts":1000,"agentId":"default","active":true}
        """.data(using: .utf8)!

        let msg = try ClawChatMessage.decode(from: json)
        guard case .typing(let t) = msg else {
            Issue.record("Expected typing")
            return
        }
        #expect(t.active == true)
    }

    @Test("Decode typing preserves sessionKey")
    func decodeTypingSessionKey() throws {
        let json = """
        {"type":"typing","id":"ty1","ts":1000,"agentId":"default","sessionKey":"session-a","active":true}
        """.data(using: .utf8)!

        let msg = try ClawChatMessage.decode(from: json)
        guard case .typing(let typing) = msg else {
            Issue.record("Expected typing")
            return
        }

        #expect(reflectedOptionalString(named: "sessionKey", from: typing) == "session-a")
    }

    @Test("Decode presence")
    func decodePresence() throws {
        let json = """
        {"type":"presence","id":"pr1","ts":1000,"online":false,"gatewayId":"gw-1"}
        """.data(using: .utf8)!

        let msg = try ClawChatMessage.decode(from: json)
        guard case .presence(let p) = msg else {
            Issue.record("Expected presence")
            return
        }
        #expect(p.online == false)
    }

    @Test("Unknown type returns .unknown case")
    func decodeUnknown() throws {
        let json = """
        {"type":"future.message","id":"f1","ts":1000,"data":"stuff"}
        """.data(using: .utf8)!

        let msg = try ClawChatMessage.decode(from: json)
        guard case .unknown(let type, _) = msg else {
            Issue.record("Expected unknown")
            return
        }
        #expect(type == "future.message")
    }

    @Test("MessageInbound round-trip encode/decode")
    func roundTrip() throws {
        let original = MessageInbound(text: "hello world", agentId: "default")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(MessageInbound.self, from: data)
        #expect(decoded.text == original.text)
        #expect(decoded.id == original.id)
        #expect(decoded.agentId == original.agentId)
    }

    @Test("MessageInbound round-trip with attachments")
    func roundTripWithAttachments() throws {
        let original = MessageInbound(
            text: nil,
            agentId: "default",
            attachments: [
                MessageAttachment(
                    type: .image,
                    mimeType: "image/png",
                    filename: "eva.png",
                    size: 128,
                    data: "aGVsbG8="
                )
            ]
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(MessageInbound.self, from: data)
        #expect(decoded.text == nil)
        #expect(decoded.attachments?.count == 1)
        #expect(decoded.attachments?.first?.filename == "eva.png")
        #expect(decoded.attachments?.first?.mimeType == "image/png")
    }

    @Test("Decode message.reasoning")
    func decodeReasoning() throws {
        let json = """
        {"type":"message.reasoning","id":"r1","ts":1000,"agentId":"default","text":"thinking...","phase":"streaming"}
        """.data(using: .utf8)!

        let msg = try ClawChatMessage.decode(from: json)
        guard case .messageReasoning(let r) = msg else {
            Issue.record("Expected messageReasoning")
            return
        }
        #expect(r.text == "thinking...")
        #expect(r.phase == .streaming)
    }

    @Test("Decode app.connected with gatewayOnline")
    func decodeAppConnected() throws {
        let json = """
        {"type":"app.connected","id":"c1","ts":1000,"gatewayId":"gw-1","gatewayOnline":true,"agents":["hulu::呼噜::claude-opus-4-6"]}
        """.data(using: .utf8)!

        let msg = try ClawChatMessage.decode(from: json)
        guard case .appConnected(let c) = msg else {
            Issue.record("Expected appConnected")
            return
        }
        #expect(c.gatewayId == "gw-1")
        #expect(c.gatewayOnline == true)
        #expect(c.agents == ["hulu::呼噜::claude-opus-4-6"])
    }

    @Test("Pong message decodes")
    func decodePong() throws {
        let json = """
        {"type":"pong","id":"p1","ts":1000}
        """.data(using: .utf8)!

        let msg = try ClawChatMessage.decode(from: json)
        guard case .pong = msg else {
            Issue.record("Expected pong")
            return
        }
    }

    private func reflectedOptionalString(named label: String, from value: Any) -> String? {
        let mirror = Mirror(reflecting: value)
        guard let child = mirror.children.first(where: { $0.label == label }) else { return nil }
        if let string = child.value as? String {
            return string
        }

        let optionalMirror = Mirror(reflecting: child.value)
        guard optionalMirror.displayStyle == .optional else { return nil }
        return optionalMirror.children.first?.value as? String
    }
}
