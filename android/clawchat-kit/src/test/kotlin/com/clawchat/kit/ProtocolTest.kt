package com.clawchat.kit

import com.clawchat.kit.protocol.*
import kotlinx.serialization.json.Json
import org.junit.Assert.*
import org.junit.Test

class ProtocolTest {

    @Test
    fun `decode message stream with streaming phase`() {
        val json = """{"type":"message.stream","id":"abc","ts":1234,"agentId":"default","delta":"hello","phase":"streaming"}"""
        val msg = ClawChatMessage.decode(json)
        assertTrue(msg is ClawChatMessage.MessageStreamMsg)
        val stream = (msg as ClawChatMessage.MessageStreamMsg).value
        assertEquals("hello", stream.delta)
        assertEquals(StreamPhase.STREAMING, stream.phase)
        assertEquals("abc", stream.id)
    }

    @Test
    fun `decode message stream with done phase and finalText`() {
        val json = """{"type":"message.stream","id":"abc","ts":1234,"delta":"","phase":"done","finalText":"full response"}"""
        val msg = ClawChatMessage.decode(json)
        assertTrue(msg is ClawChatMessage.MessageStreamMsg)
        val stream = (msg as ClawChatMessage.MessageStreamMsg).value
        assertEquals(StreamPhase.DONE, stream.phase)
        assertEquals("full response", stream.finalText)
    }

    @Test
    fun `decode app paired`() {
        val json = """{"type":"app.paired","id":"p1","ts":1000,"deviceToken":"tok-123","gatewayId":"gw-1"}"""
        val msg = ClawChatMessage.decode(json)
        assertTrue(msg is ClawChatMessage.AppPairedMsg)
        val paired = (msg as ClawChatMessage.AppPairedMsg).value
        assertEquals("tok-123", paired.deviceToken)
        assertEquals("gw-1", paired.gatewayId)
    }

    @Test
    fun `decode app pair error`() {
        val json = """{"type":"app.pair.error","id":"e1","ts":1000,"error":"invalid_code","message":"Invalid code"}"""
        val msg = ClawChatMessage.decode(json)
        assertTrue(msg is ClawChatMessage.AppPairErrorMsg)
        val err = (msg as ClawChatMessage.AppPairErrorMsg).value
        assertEquals(PairErrorReason.INVALID_CODE, err.error)
    }

    @Test
    fun `decode tool event start`() {
        val json = """{"type":"tool.event","id":"t1","ts":1000,"agentId":"default","tool":"web_search","phase":"start","label":"Searching..."}"""
        val msg = ClawChatMessage.decode(json)
        assertTrue(msg is ClawChatMessage.ToolEventMsg)
        val tool = (msg as ClawChatMessage.ToolEventMsg).value
        assertEquals("web_search", tool.tool)
        assertEquals(ToolPhase.START, tool.phase)
        assertEquals("Searching...", tool.label)
    }

    @Test
    fun `decode error message`() {
        val json = """{"type":"error","id":"e1","ts":1000,"code":"gateway_offline","message":"Gateway is not connected"}"""
        val msg = ClawChatMessage.decode(json)
        assertTrue(msg is ClawChatMessage.ErrorMsg)
        val err = (msg as ClawChatMessage.ErrorMsg).value
        assertTrue(err.code is ClawChatErrorCode.GatewayOffline)
        assertEquals("Gateway is not connected", err.message)
    }

    @Test
    fun `decode typing`() {
        val json = """{"type":"typing","id":"ty1","ts":1000,"agentId":"default","active":true}"""
        val msg = ClawChatMessage.decode(json)
        assertTrue(msg is ClawChatMessage.TypingMsg)
        val t = (msg as ClawChatMessage.TypingMsg).value
        assertTrue(t.active)
    }

    @Test
    fun `decode presence`() {
        val json = """{"type":"presence","id":"pr1","ts":1000,"online":false,"gatewayId":"gw-1"}"""
        val msg = ClawChatMessage.decode(json)
        assertTrue(msg is ClawChatMessage.PresenceMsg)
        val p = (msg as ClawChatMessage.PresenceMsg).value
        assertEquals(false, p.online)
    }

    @Test
    fun `unknown type returns Unknown case`() {
        val json = """{"type":"future.message","id":"f1","ts":1000,"data":"stuff"}"""
        val msg = ClawChatMessage.decode(json)
        assertTrue(msg is ClawChatMessage.Unknown)
        assertEquals("future.message", (msg as ClawChatMessage.Unknown).type)
    }

    @Test
    fun `MessageInbound round-trip encode decode`() {
        val original = MessageInbound(text = "hello world", agentId = "default")
        val encoded = Json.encodeToString(original)
        val decoded = Json { ignoreUnknownKeys = true }.decodeFromString<MessageInbound>(encoded)
        assertEquals(original.text, decoded.text)
        assertEquals(original.id, decoded.id)
        assertEquals(original.agentId, decoded.agentId)
    }

    @Test
    fun `decode message reasoning`() {
        val json = """{"type":"message.reasoning","id":"r1","ts":1000,"agentId":"default","text":"thinking...","phase":"streaming"}"""
        val msg = ClawChatMessage.decode(json)
        assertTrue(msg is ClawChatMessage.MessageReasoningMsg)
        val r = (msg as ClawChatMessage.MessageReasoningMsg).value
        assertEquals("thinking...", r.text)
        assertEquals(ReasoningPhase.STREAMING, r.phase)
    }

    @Test
    fun `decode app connected with gatewayOnline`() {
        val json = """{"type":"app.connected","id":"c1","ts":1000,"gatewayId":"gw-1","gatewayOnline":true}"""
        val msg = ClawChatMessage.decode(json)
        assertTrue(msg is ClawChatMessage.AppConnectedMsg)
        val c = (msg as ClawChatMessage.AppConnectedMsg).value
        assertEquals("gw-1", c.gatewayId)
        assertEquals(true, c.gatewayOnline)
    }

    @Test
    fun `pong message decodes`() {
        val json = """{"type":"pong","id":"p1","ts":1000}"""
        val msg = ClawChatMessage.decode(json)
        assertTrue(msg is ClawChatMessage.PongMsg)
    }

    @Test
    fun `PingMessage has correct type`() {
        val ping = PingMessage()
        assertEquals("ping", ping.type)
    }

    @Test
    fun `PingMessage generates unique IDs`() {
        val ping1 = PingMessage()
        val ping2 = PingMessage()
        assertNotEquals(ping1.id, ping2.id)
    }

    @Test
    fun `PingMessage encodes to JSON`() {
        val ping = PingMessage()
        val encoded = Json.encodeToString(ping)
        val decoded = ClawChatMessage.decode(encoded)
        assertTrue(decoded is ClawChatMessage.PingMsg)
        assertEquals(ping.id, (decoded as ClawChatMessage.PingMsg).value.id)
    }

    @Test
    fun `unknown error code preserved`() {
        val json = """{"type":"error","id":"e1","ts":1000,"code":"new_error_type","message":"Something new"}"""
        val msg = ClawChatMessage.decode(json)
        assertTrue(msg is ClawChatMessage.ErrorMsg)
        val err = (msg as ClawChatMessage.ErrorMsg).value
        assertTrue(err.code is ClawChatErrorCode.Unknown)
        assertEquals("new_error_type", (err.code as ClawChatErrorCode.Unknown).raw)
    }

    @Test
    fun `decode code_expired pair error`() {
        val json = """{"type":"app.pair.error","id":"e1","ts":1000,"error":"code_expired","message":"Code expired"}"""
        val msg = ClawChatMessage.decode(json)
        assertTrue(msg is ClawChatMessage.AppPairErrorMsg)
        val err = (msg as ClawChatMessage.AppPairErrorMsg).value
        assertEquals(PairErrorReason.CODE_EXPIRED, err.error)
    }
}
