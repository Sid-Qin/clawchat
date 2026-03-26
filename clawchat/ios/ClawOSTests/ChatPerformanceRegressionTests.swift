import Foundation
import Testing
import ClawChatKit
import UIKit
@testable import ClawOS

struct ChatPerformanceRegressionTests {
    @MainActor
    @Test("未落库的 assistant live 消息直接显示实时文本")
    func liveAssistantPreviewUsesAuthoritativeStreamText() {
        let storedMessages = [
            StoredMessage(
                id: "u1",
                role: .user,
                text: "hello",
                timestamp: Date(timeIntervalSince1970: 1)
            )
        ]
        let liveMessages = [
            ChatMessage(
                id: "a1",
                role: .assistant,
                text: "streaming full text",
                isStreaming: true,
                timestamp: Date(timeIntervalSince1970: 2),
                agentId: "main",
                sessionKey: "session-1"
            )
        ]

        let items = ChatRenderPipeline.renderedMessages(
            storedMessages: storedMessages,
            liveMessages: liveMessages
        )

        #expect(items.map(\.id) == ["u1", "a1"])
        #expect(items.last?.text == "streaming full text")
        #expect(items.last?.isStreaming == true)
    }

    @MainActor
    @Test("已落库 assistant 消息不会追加重复的 live 预览")
    func persistedAssistantMessageSuppressesDuplicateLivePreview() {
        let timestamp = Date(timeIntervalSince1970: 10)
        let storedMessages = [
            StoredMessage(
                id: "a1",
                role: .assistant,
                text: "final text",
                timestamp: timestamp
            )
        ]
        let liveMessages = [
            ChatMessage(
                id: "a1",
                role: .assistant,
                text: "final text",
                isStreaming: false,
                timestamp: timestamp,
                agentId: "main",
                sessionKey: "session-1"
            )
        ]

        let items = ChatRenderPipeline.renderedMessages(
            storedMessages: storedMessages,
            liveMessages: liveMessages
        )

        #expect(items.count == 1)
        #expect(items.first?.id == "a1")
        #expect(items.first?.text == "final text")
    }

    @MainActor
    @Test("消息落盘会 debounce 避免 append 后立即写盘")
    func messagePersistenceIsDebounced() async throws {
        let messagesKey = "clawos_messages"
        UserDefaults.standard.removeObject(forKey: messagesKey)
        defer {
            UserDefaults.standard.removeObject(forKey: messagesKey)
        }

        let appState = AppState()
        let message = StoredMessage(
            id: "m1",
            role: .assistant,
            text: "hello",
            timestamp: Date(timeIntervalSince1970: 100)
        )

        appState.appendMessage(to: "session-1", message: message)

        try await Task.sleep(for: .milliseconds(120))
        #expect(UserDefaults.standard.data(forKey: messagesKey) == nil)

        let deadline = ContinuousClock.now + .seconds(2)
        while UserDefaults.standard.data(forKey: messagesKey) == nil,
              ContinuousClock.now < deadline {
            try await Task.sleep(for: .milliseconds(100))
        }
        #expect(UserDefaults.standard.data(forKey: messagesKey) != nil)
    }

    @Test("超限图片会先压缩后再进入 composer")
    func oversizedImageAttachmentIsCompressedBeforeEnteringComposer() throws {
        let data = try makeDenseImageData()
        #expect(data.count > 120_000)

        let attachment = try ComposerAttachment.prepared(
            data: data,
            filename: "huge-photo.png",
            mimeType: "image/png",
            type: .image,
            maxBytes: 120_000
        )

        #expect(attachment.size <= 120_000)
        #expect(attachment.mimeType == "image/jpeg")
        #expect(attachment.filename.hasSuffix(".jpg"))
        #expect(!attachment.dataBase64.isEmpty)
    }

    @MainActor
    @Test("消息气泡时间格式复用共享 formatter")
    func messageBubbleTimeFormatterReusesSharedFormatter() {
        let first = MessageBubbleTimeFormatter.sharedFormatter
        let second = MessageBubbleTimeFormatter.sharedFormatter

        #expect(first === second)
    }
}

private func makeDenseImageData() throws -> Data {
    let size = CGSize(width: 1600, height: 1600)
    let renderer = UIGraphicsImageRenderer(size: size)
    let image = renderer.image { context in
        for y in stride(from: 0, to: Int(size.height), by: 20) {
            for x in stride(from: 0, to: Int(size.width), by: 20) {
                let hue = CGFloat((x * 13 + y * 7) % 255) / 255
                UIColor(
                    hue: hue,
                    saturation: 0.9,
                    brightness: 0.95,
                    alpha: 1
                ).setFill()
                context.fill(CGRect(x: x, y: y, width: 20, height: 20))
            }
        }
    }

    guard let data = image.pngData() else {
        throw NSError(domain: "ChatPerformanceRegressionTests", code: 1)
    }
    return data
}
