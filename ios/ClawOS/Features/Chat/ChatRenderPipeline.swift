import Foundation
import ClawChatKit

@MainActor
enum ChatRenderPipeline {
    static func previewAssistantMessage(
        storedMessages: [StoredMessage],
        liveMessages: [ChatMessage]
    ) -> ChatMessage? {
        let storedIds = Set(storedMessages.map(\.id))
        return liveMessages.last(where: {
            $0.role == .assistant && !storedIds.contains($0.id)
        })
    }

    static func renderedMessages(
        storedMessages: [StoredMessage],
        liveMessages: [ChatMessage]
    ) -> [MessageBubbleItem] {
        var items = storedMessages.map(MessageBubbleItem.init(storedMessage:))
        if let previewAssistantMessage = previewAssistantMessage(
            storedMessages: storedMessages,
            liveMessages: liveMessages
        ) {
            items.append(MessageBubbleItem(chatMessage: previewAssistantMessage))
        }
        return items
    }
}
