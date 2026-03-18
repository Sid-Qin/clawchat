import SwiftUI

enum AppTheme {
    static let primary = Color(.label)
    static let success = Color(.secondaryLabel)
    static let danger = Color(.label)
    static let warning = Color(.tertiaryLabel)

    static let bubble = Color(.label)
    static let bubbleText = Color(.systemBackground)

    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
    }

    enum Radius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
    }

    static let sidebarWidth: CGFloat = 72
    static let avatarSize: CGFloat = 48
    static let largeAvatarSize: CGFloat = 84
    static let bannerHeight: CGFloat = 180
}

extension AgentStatus {
    var color: Color {
        switch self {
        case .online: .green
        case .idle: .orange
        case .dnd: .red
        case .offline: Color(.quaternaryLabel)
        }
    }

    var label: String {
        switch self {
        case .online: "在线"
        case .idle: "闲置"
        case .dnd: "勿扰"
        case .offline: "离线"
        }
    }

    var icon: String {
        switch self {
        case .online: "checkmark.circle.fill"
        case .idle: "moon.fill"
        case .dnd: "minus.circle.fill"
        case .offline: "wifi.slash"
        }
    }
}
