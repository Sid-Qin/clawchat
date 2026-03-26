package com.clawchat.kit.protocol

import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import java.util.UUID

// MARK: - Ping / Pong

@Serializable
data class PingMessage(
    override val type: String = "ping",
    override val id: String = UUID.randomUUID().toString(),
    override val ts: Long = System.currentTimeMillis(),
) : BaseMessage

@Serializable
data class PongMessage(
    override val type: String,
    override val id: String,
    override val ts: Long,
) : BaseMessage

// MARK: - Discriminated union

sealed class ClawChatMessage {
    // Connection
    data class AppPairedMsg(val value: AppPaired) : ClawChatMessage()
    data class AppPairErrorMsg(val value: AppPairError) : ClawChatMessage()
    data class AppConnectedMsg(val value: AppConnected) : ClawChatMessage()

    // Messaging
    data class MessageInboundMsg(val value: MessageInbound) : ClawChatMessage()
    data class MessageOutboundMsg(val value: MessageOutbound) : ClawChatMessage()
    data class MessageStreamMsg(val value: MessageStream) : ClawChatMessage()
    data class MessageReasoningMsg(val value: MessageReasoning) : ClawChatMessage()
    data class ToolEventMsg(val value: ToolEvent) : ClawChatMessage()

    // Control
    data class TypingMsg(val value: Typing) : ClawChatMessage()
    data class PresenceMsg(val value: Presence) : ClawChatMessage()
    data class StatusResponseMsg(val value: StatusResponse) : ClawChatMessage()

    // Pairing
    data class PairCodeMsg(val value: PairCode) : ClawChatMessage()
    data class DevicesListResponseMsg(val value: DevicesListResponse) : ClawChatMessage()

    // Errors
    data class ErrorMsg(val value: ErrorMessage) : ClawChatMessage()

    // Ping/Pong
    data class PingMsg(val value: PingMessage) : ClawChatMessage()
    data class PongMsg(val value: PongMessage) : ClawChatMessage()

    // Unknown
    data class Unknown(val type: String, val rawJson: String) : ClawChatMessage()

    companion object {
        private val json = Json {
            ignoreUnknownKeys = true
            isLenient = true
        }

        /** Decode a wire protocol message from raw JSON string. */
        fun decode(rawJson: String): ClawChatMessage {
            val element = json.parseToJsonElement(rawJson)
            val type = element.jsonObject["type"]?.jsonPrimitive?.content
                ?: return Unknown("", rawJson)

            return try {
                when (type) {
                    // Connection
                    "app.paired" -> AppPairedMsg(json.decodeFromString<AppPaired>(rawJson))
                    "app.pair.error" -> AppPairErrorMsg(json.decodeFromString<AppPairError>(rawJson))
                    "app.connected" -> AppConnectedMsg(json.decodeFromString<AppConnected>(rawJson))

                    // Messaging
                    "message.inbound" -> MessageInboundMsg(json.decodeFromString<MessageInbound>(rawJson))
                    "message.outbound" -> MessageOutboundMsg(json.decodeFromString<MessageOutbound>(rawJson))
                    "message.stream" -> MessageStreamMsg(json.decodeFromString<MessageStream>(rawJson))
                    "message.reasoning" -> MessageReasoningMsg(json.decodeFromString<MessageReasoning>(rawJson))
                    "tool.event" -> ToolEventMsg(json.decodeFromString<ToolEvent>(rawJson))

                    // Control
                    "typing" -> TypingMsg(json.decodeFromString<Typing>(rawJson))
                    "presence" -> PresenceMsg(json.decodeFromString<Presence>(rawJson))
                    "status.response" -> StatusResponseMsg(json.decodeFromString<StatusResponse>(rawJson))

                    // Pairing
                    "pair.code" -> PairCodeMsg(json.decodeFromString<PairCode>(rawJson))
                    "devices.list.response" -> DevicesListResponseMsg(json.decodeFromString<DevicesListResponse>(rawJson))

                    // Errors
                    "error" -> ErrorMsg(json.decodeFromString<ErrorMessage>(rawJson))

                    // Ping/Pong
                    "ping" -> PingMsg(json.decodeFromString<PingMessage>(rawJson))
                    "pong" -> PongMsg(json.decodeFromString<PongMessage>(rawJson))

                    else -> Unknown(type, rawJson)
                }
            } catch (e: Exception) {
                Unknown(type, rawJson)
            }
        }

        /** Encode a BaseMessage to JSON string. */
        inline fun <reified T : BaseMessage> encode(message: T): String {
            return json.encodeToString(message)
        }
    }
}
