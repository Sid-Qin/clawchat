package com.clawchat.kit.protocol

import kotlinx.serialization.KSerializer
import kotlinx.serialization.Serializable
import kotlinx.serialization.descriptors.PrimitiveKind
import kotlinx.serialization.descriptors.PrimitiveSerialDescriptor
import kotlinx.serialization.encoding.Decoder
import kotlinx.serialization.encoding.Encoder

// MARK: - Error Code

@Serializable(with = ClawChatErrorCodeSerializer::class)
sealed class ClawChatErrorCode {
    data object GatewayOffline : ClawChatErrorCode()
    data object Unauthorized : ClawChatErrorCode()
    data object NotConnected : ClawChatErrorCode()
    data object InvalidJson : ClawChatErrorCode()
    data object RateLimited : ClawChatErrorCode()
    data class Unknown(val raw: String) : ClawChatErrorCode()

    val value: String get() = when (this) {
        is GatewayOffline -> "gateway_offline"
        is Unauthorized -> "unauthorized"
        is NotConnected -> "not_connected"
        is InvalidJson -> "invalid_json"
        is RateLimited -> "rate_limited"
        is Unknown -> raw
    }

    companion object {
        fun fromString(s: String): ClawChatErrorCode = when (s) {
            "gateway_offline" -> GatewayOffline
            "unauthorized" -> Unauthorized
            "not_connected" -> NotConnected
            "invalid_json" -> InvalidJson
            "rate_limited" -> RateLimited
            else -> Unknown(s)
        }
    }
}

object ClawChatErrorCodeSerializer : KSerializer<ClawChatErrorCode> {
    override val descriptor = PrimitiveSerialDescriptor("ClawChatErrorCode", PrimitiveKind.STRING)
    override fun serialize(encoder: Encoder, value: ClawChatErrorCode) = encoder.encodeString(value.value)
    override fun deserialize(decoder: Decoder): ClawChatErrorCode = ClawChatErrorCode.fromString(decoder.decodeString())
}

// MARK: - Error Message

@Serializable
data class ErrorMessage(
    override val type: String,
    override val id: String,
    override val ts: Long,
    val code: ClawChatErrorCode,
    val message: String,
) : BaseMessage
