package com.clawchat.kit.protocol

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.JsonElement
import java.util.UUID

// MARK: - Stream Phase

@Serializable
enum class StreamPhase {
    @SerialName("streaming") STREAMING,
    @SerialName("done") DONE,
    @SerialName("error") ERROR,
}

// MARK: - Reasoning Phase

@Serializable
enum class ReasoningPhase {
    @SerialName("streaming") STREAMING,
    @SerialName("done") DONE,
}

// MARK: - Tool Phase

@Serializable
enum class ToolPhase {
    @SerialName("start") START,
    @SerialName("progress") PROGRESS,
    @SerialName("result") RESULT,
    @SerialName("error") ERROR,
}

// MARK: - Message Inbound

@Serializable
data class MessageInbound(
    override val type: String = "message.inbound",
    override val id: String = UUID.randomUUID().toString(),
    override val ts: Long = System.currentTimeMillis(),
    val text: String,
    val agentId: String? = "default",
    val sessionKey: String? = null,
) : BaseMessage

// MARK: - Message Outbound

@Serializable
data class MessageOutbound(
    override val type: String,
    override val id: String,
    override val ts: Long,
    val text: String,
    val agentId: String? = null,
) : BaseMessage

// MARK: - Message Stream

@Serializable
data class MessageStream(
    override val type: String,
    override val id: String,
    override val ts: Long,
    val agentId: String? = null,
    val delta: String,
    val phase: StreamPhase,
    val finalText: String? = null,
) : BaseMessage

// MARK: - Message Reasoning

@Serializable
data class MessageReasoning(
    override val type: String,
    override val id: String,
    override val ts: Long,
    val agentId: String? = null,
    val text: String,
    val phase: ReasoningPhase? = null,
) : BaseMessage

// MARK: - Tool Event

@Serializable
data class ToolEvent(
    override val type: String,
    override val id: String,
    override val ts: Long,
    val agentId: String? = null,
    val tool: String,
    val phase: ToolPhase,
    val label: String? = null,
    val input: JsonElement? = null,
    val result: JsonElement? = null,
) : BaseMessage
