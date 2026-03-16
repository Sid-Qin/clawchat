import Foundation

struct Session: Identifiable, Codable, Hashable {
    let id: String
    var agentId: String
    var title: String
    var category: String
    var lastMessage: String?
    var lastMessageTime: Date?
    var unreadCount: Int

    var timeAgo: String {
        guard let time = lastMessageTime else { return "" }
        let interval = Date().timeIntervalSince(time)
        let days = Int(interval / 86400)
        if days == 0 { return "今天" }
        if days == 1 { return "昨天" }
        return "\(days)天"
    }
}
