import Foundation

enum MessageType: String, Codable {
    case text
    case image
    case embed
    case system
}

struct Message: Identifiable, Codable, Hashable {
    let id: String
    var sessionId: String
    var senderId: String
    var senderName: String
    var senderAvatar: String
    var content: String
    var timestamp: Date
    var type: MessageType
    var tokenCount: Int?

    var isMe: Bool { senderId == "me" }
}
