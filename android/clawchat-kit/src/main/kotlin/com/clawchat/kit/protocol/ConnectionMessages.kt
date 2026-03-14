package com.clawchat.kit.protocol

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import java.util.UUID

// MARK: - App Platform

@Serializable
enum class AppPlatform {
    @SerialName("ios") IOS,
    @SerialName("android") ANDROID,
    @SerialName("web") WEB,
    @SerialName("cli") CLI,
}

// MARK: - App Pair

@Serializable
data class AppPair(
    override val type: String = "app.pair",
    override val id: String = UUID.randomUUID().toString(),
    override val ts: Long = System.currentTimeMillis(),
    val pairingCode: String,
    val deviceName: String,
    val platform: AppPlatform = AppPlatform.ANDROID,
    val protocolVersion: String = "0.1",
) : BaseMessage

// MARK: - App Paired

@Serializable
data class AppPaired(
    override val type: String,
    override val id: String,
    override val ts: Long,
    val deviceToken: String,
    val gatewayId: String,
) : BaseMessage

// MARK: - App Pair Error

@Serializable
enum class PairErrorReason {
    @SerialName("invalid_code") INVALID_CODE,
    @SerialName("code_expired") CODE_EXPIRED,
    @SerialName("expired") EXPIRED,
    @SerialName("gateway_offline") GATEWAY_OFFLINE,
}

@Serializable
data class AppPairError(
    override val type: String,
    override val id: String,
    override val ts: Long,
    val error: PairErrorReason,
    val message: String,
) : BaseMessage

// MARK: - App Connect

@Serializable
data class AppConnect(
    override val type: String = "app.connect",
    override val id: String = UUID.randomUUID().toString(),
    override val ts: Long = System.currentTimeMillis(),
    val deviceToken: String,
    val protocolVersion: String = "0.1",
) : BaseMessage

// MARK: - App Connected

@Serializable
data class AppConnected(
    override val type: String,
    override val id: String,
    override val ts: Long,
    val gatewayId: String,
    val gatewayOnline: Boolean? = null,
    val newDeviceToken: String? = null,
) : BaseMessage
