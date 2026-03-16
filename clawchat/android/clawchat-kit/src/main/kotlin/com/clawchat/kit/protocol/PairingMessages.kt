package com.clawchat.kit.protocol

import kotlinx.serialization.Serializable
import java.util.UUID

// MARK: - Pair Generate

@Serializable
data class PairGenerate(
    override val type: String = "pair.generate",
    override val id: String = UUID.randomUUID().toString(),
    override val ts: Long = System.currentTimeMillis(),
) : BaseMessage

// MARK: - Pair Code

@Serializable
data class PairCode(
    override val type: String,
    override val id: String,
    override val ts: Long,
    val code: String,
    val expiresAt: Long,
) : BaseMessage

// MARK: - Device Info

@Serializable
data class DeviceInfo(
    val deviceId: String,
    val deviceName: String,
    val platform: String,
    val lastSeen: Long? = null,
)

// MARK: - Devices List

@Serializable
data class DevicesList(
    override val type: String = "devices.list",
    override val id: String = UUID.randomUUID().toString(),
    override val ts: Long = System.currentTimeMillis(),
) : BaseMessage

// MARK: - Devices List Response

@Serializable
data class DevicesListResponse(
    override val type: String,
    override val id: String,
    override val ts: Long,
    val devices: List<DeviceInfo>,
) : BaseMessage

// MARK: - Devices Revoke

@Serializable
data class DevicesRevoke(
    override val type: String = "devices.revoke",
    override val id: String = UUID.randomUUID().toString(),
    override val ts: Long = System.currentTimeMillis(),
    val deviceId: String,
) : BaseMessage
