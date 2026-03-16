import Foundation

/// Errors that can occur during pairing or reconnection.
public enum PairingError: Error, Sendable, Equatable {
    case invalidCode
    case codeExpired
    case unauthorized
    case gatewayOffline
    case networkError(String)
    case timeout

    public static func == (lhs: PairingError, rhs: PairingError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidCode, .invalidCode),
             (.codeExpired, .codeExpired),
             (.unauthorized, .unauthorized),
             (.gatewayOffline, .gatewayOffline),
             (.timeout, .timeout):
            return true
        case (.networkError(let a), .networkError(let b)):
            return a == b
        default:
            return false
        }
    }
}
