import Testing
import Foundation
@testable import ClawChatKit

@Suite("Chat State")
struct ChatStateTests {

    // MARK: - ChatMessage

    @Test("ChatMessage user role defaults")
    func chatMessageUserDefaults() {
        let msg = ChatMessage(role: .user, text: "hello")
        #expect(msg.role == .user)
        #expect(msg.text == "hello")
        #expect(msg.isStreaming == false)
        #expect(msg.isError == false)
        #expect(msg.reasoning == nil)
        #expect(msg.toolEvents.isEmpty)
    }

    @Test("ChatMessage assistant streaming")
    func chatMessageAssistantStreaming() {
        var msg = ChatMessage(id: "s1", role: .assistant, text: "he", isStreaming: true)
        #expect(msg.isStreaming == true)
        msg.text += "llo"
        #expect(msg.text == "hello")
        msg.isStreaming = false
        #expect(msg.isStreaming == false)
    }

    @Test("ChatMessage unique IDs")
    func chatMessageUniqueIds() {
        let m1 = ChatMessage(role: .user, text: "a")
        let m2 = ChatMessage(role: .user, text: "b")
        #expect(m1.id != m2.id)
    }

    // MARK: - Stream accumulation logic

    @Test("Stream accumulation: create on first delta")
    func streamCreateOnFirstDelta() {
        var messages: [ChatMessage] = []
        let stream = makeStream(id: "s1", delta: "he", phase: .streaming)

        // Simulate handleStream logic
        if messages.firstIndex(where: { $0.id == stream.id }) == nil {
            messages.append(ChatMessage(id: stream.id, role: .assistant, text: stream.delta, isStreaming: true))
        }

        #expect(messages.count == 1)
        #expect(messages[0].text == "he")
        #expect(messages[0].isStreaming == true)
    }

    @Test("Stream accumulation: append subsequent deltas")
    func streamAppendDeltas() {
        var messages: [ChatMessage] = [
            ChatMessage(id: "s1", role: .assistant, text: "he", isStreaming: true)
        ]

        let stream = makeStream(id: "s1", delta: "llo", phase: .streaming)
        if let idx = messages.firstIndex(where: { $0.id == stream.id }) {
            messages[idx].text += stream.delta
        }

        #expect(messages[0].text == "hello")
    }

    @Test("Stream accumulation: cumulative snapshots should replace instead of duplicate")
    func streamMergeCumulativeSnapshots() {
        let merged = ChatState.mergeStreamingText(current: "hello", incoming: "hello world")
        #expect(merged == "hello world")
    }

    @Test("Stream accumulation: incremental chunks should still append")
    func streamMergeIncrementalChunks() {
        let merged = ChatState.mergeStreamingText(current: "hello", incoming: " world")
        #expect(merged == "hello world")
    }

    @Test("Stream accumulation: finalize on done")
    func streamFinalizeOnDone() {
        var messages: [ChatMessage] = [
            ChatMessage(id: "s1", role: .assistant, text: "he", isStreaming: true)
        ]

        let stream = makeStream(id: "s1", delta: "", phase: .done, finalText: "hello world")
        if let idx = messages.firstIndex(where: { $0.id == stream.id }) {
            if let finalText = stream.finalText {
                messages[idx].text = finalText
            }
            messages[idx].isStreaming = false
        }

        #expect(messages[0].text == "hello world")
        #expect(messages[0].isStreaming == false)
    }

    @Test("Stream accumulation: error phase")
    func streamErrorPhase() {
        var messages: [ChatMessage] = [
            ChatMessage(id: "s1", role: .assistant, text: "partial", isStreaming: true)
        ]

        if let idx = messages.firstIndex(where: { $0.id == "s1" }) {
            messages[idx].isError = true
            messages[idx].isStreaming = false
        }

        #expect(messages[0].isError == true)
        #expect(messages[0].isStreaming == false)
    }

    // MARK: - Reasoning accumulation

    @Test("Reasoning appended to message")
    func reasoningAccumulation() {
        var msg = ChatMessage(id: "s1", role: .assistant, text: "response", isStreaming: true)

        // First reasoning chunk
        msg.reasoning = "thinking"
        #expect(msg.reasoning == "thinking")

        // Subsequent chunk
        msg.reasoning! += " more"
        #expect(msg.reasoning == "thinking more")
    }

    // MARK: - Tool events

    @Test("Tool event tracking")
    func toolEventTracking() {
        var msg = ChatMessage(id: "s1", role: .assistant, text: "", isStreaming: true)

        // Add tool event
        let tool = ChatToolEvent(id: "t1", tool: "web_search", phase: .start, label: "Searching...")
        msg.toolEvents.append(tool)
        #expect(msg.toolEvents.count == 1)
        #expect(msg.toolEvents[0].phase == .start)

        // Update phase
        msg.toolEvents[0].phase = .result
        #expect(msg.toolEvents[0].phase == .result)
    }

    // MARK: - Message role

    @Test("MessageRole values")
    func messageRoles() {
        let user = MessageRole.user
        let assistant = MessageRole.assistant
        #expect(user != assistant)
    }

    // MARK: - Helpers

    private func makeStream(id: String, delta: String, phase: StreamPhase, finalText: String? = nil) -> MessageStream {
        // We can't easily construct MessageStream directly (no public init),
        // so decode from JSON
        var json = """
        {"type":"message.stream","id":"\(id)","ts":1000,"agentId":"default","delta":"\(delta)","phase":"\(phase.rawValue)"
        """
        if let ft = finalText {
            json += ",\"finalText\":\"\(ft)\""
        }
        json += "}"
        return try! JSONDecoder().decode(MessageStream.self, from: json.data(using: .utf8)!)
    }
}
