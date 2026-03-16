package com.clawchat.kit.pairing

import com.clawchat.kit.protocol.*
import com.clawchat.kit.websocket.WebSocketClient
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.withTimeout

/** Result of a successful pairing. */
data class PairingResult(
    val deviceToken: String,
    val gatewayId: String,
)

/** Result of a successful reconnection. */
data class ReconnectResult(
    val gatewayId: String,
    val gatewayOnline: Boolean,
    val newDeviceToken: String? = null,
)

/**
 * Manages pairing and reconnection flows over a WebSocket connection.
 */
class PairingManager(
    private val client: WebSocketClient,
    private val timeoutMs: Long = 30_000,
) {
    /** Pair with a relay using a 6-character pairing code. */
    suspend fun pair(code: String, deviceName: String): PairingResult {
        val message = AppPair(pairingCode = code, deviceName = deviceName)
        client.send(message)

        return withTimeout(timeoutMs) {
            client.messages.first { msg ->
                when (msg) {
                    is ClawChatMessage.AppPairedMsg -> true
                    is ClawChatMessage.AppPairErrorMsg -> true
                    is ClawChatMessage.ErrorMsg ->
                        msg.value.code is ClawChatErrorCode.Unauthorized
                    else -> false
                }
            }.let { msg ->
                when (msg) {
                    is ClawChatMessage.AppPairedMsg ->
                        PairingResult(msg.value.deviceToken, msg.value.gatewayId)
                    is ClawChatMessage.AppPairErrorMsg ->
                        throw pairingException(msg.value.error)
                    is ClawChatMessage.ErrorMsg ->
                        throw PairingException.Unauthorized()
                    else -> error("unreachable")
                }
            }
        }
    }

    /** Reconnect to the relay using a stored device token. */
    suspend fun reconnect(deviceToken: String): ReconnectResult {
        val message = AppConnect(deviceToken = deviceToken)
        client.send(message)

        return withTimeout(timeoutMs) {
            client.messages.first { msg ->
                when (msg) {
                    is ClawChatMessage.AppConnectedMsg -> true
                    is ClawChatMessage.ErrorMsg -> true
                    else -> false
                }
            }.let { msg ->
                when (msg) {
                    is ClawChatMessage.AppConnectedMsg ->
                        ReconnectResult(
                            gatewayId = msg.value.gatewayId,
                            gatewayOnline = msg.value.gatewayOnline ?: false,
                            newDeviceToken = msg.value.newDeviceToken,
                        )
                    is ClawChatMessage.ErrorMsg -> {
                        if (msg.value.code is ClawChatErrorCode.Unauthorized) {
                            throw PairingException.Unauthorized()
                        }
                        throw PairingException.NetworkError(msg.value.message)
                    }
                    else -> error("unreachable")
                }
            }
        }
    }

    private fun pairingException(reason: PairErrorReason): PairingException = when (reason) {
        PairErrorReason.INVALID_CODE -> PairingException.InvalidCode()
        PairErrorReason.CODE_EXPIRED -> PairingException.CodeExpired()
        PairErrorReason.EXPIRED -> PairingException.CodeExpired()
        PairErrorReason.GATEWAY_OFFLINE -> PairingException.GatewayOffline()
    }
}
