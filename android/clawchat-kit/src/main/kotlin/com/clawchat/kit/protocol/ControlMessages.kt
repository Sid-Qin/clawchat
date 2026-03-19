package com.clawchat.kit.protocol

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import java.util.UUID

// MARK: - Presence Status

@Serializable
enum class PresenceStatus {
    @SerialName("online") ONLINE,
    @SerialName("away") AWAY,
    @SerialName("offline") OFFLINE,
}

// MARK: - Typing

@Serializable
data class Typing(
    override val type: String = "typing",
    override val id: String = UUID.randomUUID().toString(),
    override val ts: Long = System.currentTimeMillis(),
    val agentId: String? = "default",
    val active: Boolean,
    val label: String? = null,
) : BaseMessage

// MARK: - Presence

@Serializable
data class Presence(
    override val type: String,
    override val id: String,
    override val ts: Long,
    val status: PresenceStatus? = null,
    val online: Boolean? = null,
    val gatewayId: String? = null,
) : BaseMessage

// MARK: - Status Request

@Serializable
data class StatusRequest(
    override val type: String = "status.request",
    override val id: String = UUID.randomUUID().toString(),
    override val ts: Long = System.currentTimeMillis(),
) : BaseMessage

// MARK: - Status Response

@Serializable
data class StatusResponse(
    override val type: String,
    override val id: String,
    override val ts: Long,
    val gatewayOnline: Boolean,
    val agents: List<String>? = null,
    val connectedDevices: Int? = null,
) : BaseMessage
