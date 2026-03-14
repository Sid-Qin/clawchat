package com.clawchat.kit

import com.clawchat.kit.pairing.PairingException
import com.clawchat.kit.protocol.*
import kotlinx.serialization.json.Json
import org.junit.Assert.*
import org.junit.Test

class PairingTest {

    @Test
    fun `PairingException types are distinct`() {
        val invalidCode = PairingException.InvalidCode()
        val codeExpired = PairingException.CodeExpired()
        val unauthorized = PairingException.Unauthorized()
        val timeout = PairingException.Timeout()
        val networkError = PairingException.NetworkError("test")

        assertNotEquals(invalidCode.message, codeExpired.message)
        assertNotEquals(unauthorized.message, timeout.message)
        assertEquals("test", networkError.message)
    }

    @Test
    fun `AppPair message has correct fields`() {
        val pair = AppPair(pairingCode = "XEW-P3P", deviceName = "Pixel 9")
        assertEquals("app.pair", pair.type)
        assertEquals("XEW-P3P", pair.pairingCode)
        assertEquals("Pixel 9", pair.deviceName)
        assertEquals(AppPlatform.ANDROID, pair.platform)
        assertEquals("0.1", pair.protocolVersion)
    }

    @Test
    fun `AppPair encodes to JSON correctly`() {
        val pair = AppPair(pairingCode = "XEW-P3P", deviceName = "Pixel 9")
        val encoded = Json.encodeToString(pair)
        assertTrue(encoded.contains("\"type\":\"app.pair\""))
        assertTrue(encoded.contains("\"pairingCode\":\"XEW-P3P\""))
        assertTrue(encoded.contains("\"platform\":\"android\""))
    }

    @Test
    fun `AppConnect message has correct fields`() {
        val connect = AppConnect(deviceToken = "tok-123")
        assertEquals("app.connect", connect.type)
        assertEquals("tok-123", connect.deviceToken)
        assertEquals("0.1", connect.protocolVersion)
    }

    @Test
    fun `AppConnect encodes to JSON correctly`() {
        val connect = AppConnect(deviceToken = "tok-123")
        val encoded = Json.encodeToString(connect)
        assertTrue(encoded.contains("\"type\":\"app.connect\""))
        assertTrue(encoded.contains("\"deviceToken\":\"tok-123\""))
    }

    @Test
    fun `PairErrorReason decodes invalid_code`() {
        val json = """{"type":"app.pair.error","id":"e1","ts":1000,"error":"invalid_code","message":"Invalid code"}"""
        val msg = ClawChatMessage.decode(json)
        assertTrue(msg is ClawChatMessage.AppPairErrorMsg)
        assertEquals(PairErrorReason.INVALID_CODE, (msg as ClawChatMessage.AppPairErrorMsg).value.error)
    }

    @Test
    fun `PairErrorReason decodes code_expired`() {
        val json = """{"type":"app.pair.error","id":"e1","ts":1000,"error":"code_expired","message":"Code expired"}"""
        val msg = ClawChatMessage.decode(json)
        assertTrue(msg is ClawChatMessage.AppPairErrorMsg)
        assertEquals(PairErrorReason.CODE_EXPIRED, (msg as ClawChatMessage.AppPairErrorMsg).value.error)
    }

    @Test
    fun `unauthorized error decoded`() {
        val json = """{"type":"error","id":"e1","ts":1000,"code":"unauthorized","message":"Invalid token"}"""
        val msg = ClawChatMessage.decode(json)
        assertTrue(msg is ClawChatMessage.ErrorMsg)
        assertTrue((msg as ClawChatMessage.ErrorMsg).value.code is ClawChatErrorCode.Unauthorized)
    }
}
