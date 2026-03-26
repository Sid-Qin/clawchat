package com.clawchat.kit.pairing

/** Exceptions that can occur during pairing or reconnection. */
sealed class PairingException(message: String) : Exception(message) {
    class InvalidCode : PairingException("Invalid pairing code")
    class CodeExpired : PairingException("Pairing code expired")
    class Unauthorized : PairingException("Unauthorized")
    class GatewayOffline : PairingException("Gateway is offline")
    class NetworkError(message: String) : PairingException(message)
    class Timeout : PairingException("Pairing timed out")
}
