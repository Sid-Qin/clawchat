package com.clawchat.kit.chat

import com.clawchat.kit.protocol.ToolPhase
import kotlinx.serialization.json.JsonElement
import java.util.UUID

/** Role of a chat message. */
enum class Role {
    USER,
    ASSISTANT,
}

/** A tracked tool event within a message. */
data class ChatToolEvent(
    val id: String,
    val tool: String,
    var phase: ToolPhase,
    var label: String? = null,
    var result: JsonElement? = null,
)

/** A single chat message for display. */
data class ChatMessage(
    val id: String = UUID.randomUUID().toString(),
    val role: Role,
    var text: String,
    var reasoning: String? = null,
    val toolEvents: MutableList<ChatToolEvent> = mutableListOf(),
    var isStreaming: Boolean = false,
    var isError: Boolean = false,
    val timestamp: Long = System.currentTimeMillis(),
)
