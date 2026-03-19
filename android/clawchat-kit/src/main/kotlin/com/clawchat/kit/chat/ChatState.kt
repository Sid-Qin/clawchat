package com.clawchat.kit.chat

import com.clawchat.kit.websocket.ConnectionState

/** Immutable snapshot of the chat state for Compose observation. */
data class ChatState(
    val messages: List<ChatMessage> = emptyList(),
    val connectionState: ConnectionState = ConnectionState.DISCONNECTED,
    val isTyping: Boolean = false,
    val gatewayOnline: Boolean = false,
)
