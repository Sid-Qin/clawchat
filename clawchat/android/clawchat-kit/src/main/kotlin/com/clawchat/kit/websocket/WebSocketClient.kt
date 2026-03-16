package com.clawchat.kit.websocket

import com.clawchat.kit.protocol.BaseMessage
import com.clawchat.kit.protocol.ClawChatMessage
import com.clawchat.kit.protocol.PingMessage
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.serialization.json.Json
import okhttp3.*
import java.util.concurrent.TimeUnit
import kotlin.math.min
import kotlin.math.pow

/**
 * WebSocket client for the ClawChat relay protocol.
 * Uses OkHttp with automatic reconnection and keepalive.
 */
class WebSocketClient(
    relayUrl: String,
    private val pingIntervalSeconds: Long = 30,
    private val pongTimeoutSeconds: Long = 10,
    private val maxBackoffSeconds: Long = 60,
) {
    // Normalize URL: strip trailing slash, append /ws/app if needed
    val relayUrl: String = run {
        var url = relayUrl.trimEnd('/')
        if (!url.endsWith("/ws/app")) {
            url += "/ws/app"
        }
        url
    }

    private val client = OkHttpClient.Builder()
        .readTimeout(0, TimeUnit.MILLISECONDS) // No read timeout for WebSocket
        .build()

    private val json = Json {
        ignoreUnknownKeys = true
        isLenient = true
    }

    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)

    // State
    private var webSocket: WebSocket? = null
    private var attempt = 0
    private var closed = false
    private var pingJob: Job? = null
    private var pongTimeoutJob: Job? = null
    private var reconnectJob: Job? = null

    // Public API
    private val _messages = MutableSharedFlow<ClawChatMessage>(extraBufferCapacity = 64)
    val messages: SharedFlow<ClawChatMessage> = _messages

    private val _connectionState = MutableStateFlow(ConnectionState.DISCONNECTED)
    val connectionState: StateFlow<ConnectionState> = _connectionState

    // MARK: - Connect

    /** Start the WebSocket connection. Reconnects automatically on disconnect. */
    fun connect() {
        if (closed) return
        _connectionState.value = ConnectionState.CONNECTING
        createWebSocket()
    }

    /** Gracefully close the connection. No automatic reconnection. */
    fun close() {
        closed = true
        cancelAll()
        webSocket?.close(1000, "going away")
        webSocket = null
        _connectionState.value = ConnectionState.DISCONNECTED
    }

    /** Send a BaseMessage as JSON text frame. */
    inline fun <reified T : BaseMessage> send(message: T) {
        val ws = webSocket ?: return
        val text = json.encodeToString(message)
        ws.send(text)
    }

    // MARK: - Internals

    private fun createWebSocket() {
        val request = Request.Builder().url(relayUrl).build()
        webSocket = client.newWebSocket(request, object : WebSocketListener() {
            override fun onOpen(webSocket: WebSocket, response: Response) {
                _connectionState.value = ConnectionState.CONNECTED
                attempt = 0
                startPingLoop()
            }

            override fun onMessage(webSocket: WebSocket, text: String) {
                handleReceived(text)
            }

            override fun onClosing(webSocket: WebSocket, code: Int, reason: String) {
                webSocket.close(code, reason)
            }

            override fun onClosed(webSocket: WebSocket, code: Int, reason: String) {
                if (!closed) {
                    handleDisconnect()
                }
            }

            override fun onFailure(webSocket: WebSocket, t: Throwable, response: Response?) {
                if (!closed) {
                    handleDisconnect()
                }
            }
        })
    }

    private fun handleReceived(text: String) {
        // Cancel pong timeout on any received message
        pongTimeoutJob?.cancel()
        pongTimeoutJob = null

        val message = ClawChatMessage.decode(text)
        // Filter pong messages — consumed internally
        if (message is ClawChatMessage.PongMsg) return
        _messages.tryEmit(message)
    }

    private fun handleDisconnect() {
        cancelAll()
        webSocket = null
        _connectionState.value = ConnectionState.DISCONNECTED

        if (closed) return

        // Schedule reconnect with exponential backoff
        val delay = min(2.0.pow(attempt.toDouble()).toLong(), maxBackoffSeconds)
        attempt++
        _connectionState.value = ConnectionState.CONNECTING

        reconnectJob = scope.launch {
            delay(delay * 1000)
            if (isActive && !closed) {
                createWebSocket()
            }
        }
    }

    // MARK: - Ping / Pong keepalive

    private fun startPingLoop() {
        pingJob?.cancel()
        pingJob = scope.launch {
            while (isActive && !closed) {
                delay(pingIntervalSeconds * 1000)
                if (!isActive || closed) break
                sendPing()
            }
        }
    }

    private fun sendPing() {
        val ping = PingMessage()
        send(ping)

        // Start pong timeout
        pongTimeoutJob?.cancel()
        pongTimeoutJob = scope.launch {
            delay(pongTimeoutSeconds * 1000)
            if (isActive && !closed) {
                // No message received in time — force reconnect
                webSocket?.close(1001, "pong timeout")
                handleDisconnect()
            }
        }
    }

    // MARK: - Helpers

    private fun cancelAll() {
        pingJob?.cancel()
        pingJob = null
        pongTimeoutJob?.cancel()
        pongTimeoutJob = null
        reconnectJob?.cancel()
        reconnectJob = null
    }
}
