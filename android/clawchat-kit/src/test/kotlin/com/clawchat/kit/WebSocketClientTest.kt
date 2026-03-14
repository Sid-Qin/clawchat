package com.clawchat.kit

import com.clawchat.kit.protocol.PingMessage
import com.clawchat.kit.websocket.ConnectionState
import com.clawchat.kit.websocket.WebSocketClient
import org.junit.Assert.*
import org.junit.Test
import kotlin.math.min
import kotlin.math.pow

class WebSocketClientTest {

    @Test
    fun `ConnectionState enum values`() {
        assertEquals(3, ConnectionState.entries.size)
        assertNotEquals(ConnectionState.DISCONNECTED, ConnectionState.CONNECTED)
        assertNotEquals(ConnectionState.CONNECTING, ConnectionState.DISCONNECTED)
    }

    @Test
    fun `relay URL appends ws app when missing`() {
        val client = WebSocketClient("wss://relay.example.com")
        assertEquals("wss://relay.example.com/ws/app", client.relayUrl)
        client.close()
    }

    @Test
    fun `relay URL strips trailing slash before appending`() {
        val client = WebSocketClient("wss://relay.example.com/")
        assertEquals("wss://relay.example.com/ws/app", client.relayUrl)
        client.close()
    }

    @Test
    fun `relay URL preserves ws app if already present`() {
        val client = WebSocketClient("wss://relay.example.com/ws/app")
        assertEquals("wss://relay.example.com/ws/app", client.relayUrl)
        client.close()
    }

    @Test
    fun `initial connection state is disconnected`() {
        val client = WebSocketClient("wss://relay.example.com")
        assertEquals(ConnectionState.DISCONNECTED, client.connectionState.value)
        client.close()
    }

    @Test
    fun `close sets state to disconnected`() {
        val client = WebSocketClient("wss://relay.example.com")
        client.close()
        assertEquals(ConnectionState.DISCONNECTED, client.connectionState.value)
    }

    @Test
    fun `connect after close is no-op`() {
        val client = WebSocketClient("wss://relay.example.com")
        client.close()
        client.connect()
        // Should stay disconnected because closed flag is set
        assertEquals(ConnectionState.DISCONNECTED, client.connectionState.value)
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
    fun `exponential backoff formula`() {
        val maxBackoff = 60L
        assertEquals(1L, min(2.0.pow(0.0).toLong(), maxBackoff))
        assertEquals(2L, min(2.0.pow(1.0).toLong(), maxBackoff))
        assertEquals(4L, min(2.0.pow(2.0).toLong(), maxBackoff))
        assertEquals(8L, min(2.0.pow(3.0).toLong(), maxBackoff))
        assertEquals(16L, min(2.0.pow(4.0).toLong(), maxBackoff))
        assertEquals(32L, min(2.0.pow(5.0).toLong(), maxBackoff))
        assertEquals(60L, min(2.0.pow(6.0).toLong(), maxBackoff)) // capped
        assertEquals(60L, min(2.0.pow(10.0).toLong(), maxBackoff)) // stays capped
    }
}
