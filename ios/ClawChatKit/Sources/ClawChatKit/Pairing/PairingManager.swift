import Foundation

/// Result of a successful pairing.
public struct PairingResult: Sendable {
    public let deviceToken: String
    public let gatewayId: String
}

/// Result of a successful reconnection.
public struct ReconnectResult: Sendable {
    public let gatewayId: String
    public let gatewayOnline: Bool
    public let newDeviceToken: String?
}

/// Manages pairing and reconnection flows over a WebSocket connection.
public actor PairingManager {
    private let client: WebSocketClient
    private let pairingTimeout: TimeInterval = 30

    public init(client: WebSocketClient) {
        self.client = client
    }

    /// Pair with a relay using a 6-character pairing code.
    /// Sends `app.pair` and awaits `app.paired` or `app.pair.error`.
    public func pair(code: String, deviceName: String) async throws -> PairingResult {
        let message = AppPair(pairingCode: code, deviceName: deviceName)
        await client.send(message)

        let timeout = pairingTimeout
        let messages = await client.messages

        return try await withThrowingTaskGroup(of: PairingResult.self) { group in
            group.addTask {
                for await msg in messages {
                    switch msg {
                    case .appPaired(let paired):
                        return PairingResult(deviceToken: paired.deviceToken, gatewayId: paired.gatewayId)
                    case .appPairError(let error):
                        throw Self.pairingError(from: error.error)
                    case .error(let error):
                        if error.code == .unauthorized {
                            throw PairingError.unauthorized
                        }
                    default:
                        continue
                    }
                }
                throw PairingError.networkError("Connection closed before pairing completed")
            }

            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                throw PairingError.timeout
            }

            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }

    /// Reconnect to the relay using a stored device token.
    /// Sends `app.connect` and awaits `app.connected` or error.
    public func reconnect(deviceToken: String) async throws -> ReconnectResult {
        let message = AppConnect(deviceToken: deviceToken)
        await client.send(message)

        let timeout = pairingTimeout
        let messages = await client.messages

        return try await withThrowingTaskGroup(of: ReconnectResult.self) { group in
            group.addTask {
                for await msg in messages {
                    switch msg {
                    case .appConnected(let connected):
                        return ReconnectResult(
                            gatewayId: connected.gatewayId,
                            gatewayOnline: connected.gatewayOnline ?? false,
                            newDeviceToken: connected.newDeviceToken
                        )
                    case .error(let error):
                        if error.code == .unauthorized {
                            throw PairingError.unauthorized
                        }
                        throw PairingError.networkError(error.message)
                    default:
                        continue
                    }
                }
                throw PairingError.networkError("Connection closed before reconnection completed")
            }

            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                throw PairingError.timeout
            }

            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }

    // MARK: - Helpers

    private static func pairingError(from reason: PairErrorReason) -> PairingError {
        switch reason {
        case .invalidCode:
            return .invalidCode
        case .codeExpired:
            return .codeExpired
        case .expired:
            return .codeExpired
        case .gatewayOffline:
            return .gatewayOffline
        }
    }
}
