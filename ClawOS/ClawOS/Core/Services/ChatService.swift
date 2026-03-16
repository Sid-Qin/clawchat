import Foundation

enum ChatService {
    static func fetchMessages(for sessionId: String) async -> [Message] {
        MockData.messages.filter { $0.sessionId == sessionId }
    }
}
