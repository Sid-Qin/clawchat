import Foundation

/// Errors that can occur during pairing, authentication, or reconnection.
public enum PairingError: Error, Sendable, Equatable, LocalizedError {
    case invalidCode
    case codeExpired
    case invalidToken
    case invalidDeviceToken
    case gatewayOffline
    case deviceLimit
    case networkError(String)
    case timeout

    public var errorDescription: String? {
        switch self {
        case .invalidCode:
            return "配对码无效，请重新获取"
        case .codeExpired:
            return "配对码已过期，请重新生成"
        case .invalidToken:
            return "Token 无效或已过期，请检查后重试"
        case .invalidDeviceToken:
            return "认证失败，设备令牌无效"
        case .gatewayOffline:
            return "Gateway 离线，请确认 OpenClaw 正在运行"
        case .deviceLimit:
            return "已达设备上限（10台），请先移除旧设备"
        case .networkError(let detail):
            return "网络错误：\(detail)"
        case .timeout:
            return "连接超时，请检查地址是否正确"
        }
    }

    public static func == (lhs: PairingError, rhs: PairingError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidCode, .invalidCode),
             (.codeExpired, .codeExpired),
             (.invalidToken, .invalidToken),
             (.invalidDeviceToken, .invalidDeviceToken),
             (.gatewayOffline, .gatewayOffline),
             (.deviceLimit, .deviceLimit),
             (.timeout, .timeout):
            return true
        case (.networkError(let a), .networkError(let b)):
            return a == b
        default:
            return false
        }
    }
}
