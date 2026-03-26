import Foundation

enum GatewayMessageReducer {
    static func applying(_ event: GatewayChatEvent, to existingMessages: [ChatMessage]) -> [ChatMessage] {
        var messages = existingMessages

        switch event.state {
        case "delta":
            let text = event.textContent ?? ""
            if let idx = messages.firstIndex(where: { $0.id == event.runId }) {
                messages[idx].text = Self.mergeStreamingText(
                    current: messages[idx].text,
                    incoming: text
                )
                messages[idx].isStreaming = true
                messages[idx].sessionKey = event.sessionKey
                messages[idx].isError = false
            } else {
                messages.append(
                    ChatMessage(
                        id: event.runId,
                        role: .assistant,
                        text: text,
                        isStreaming: true,
                        sessionKey: event.sessionKey
                    )
                )
            }

        case "final":
            if let idx = messages.firstIndex(where: { $0.id == event.runId }) {
                if let finalText = event.textContent, !finalText.isEmpty {
                    messages[idx].text = finalText
                }
                messages[idx].isStreaming = false
                messages[idx].isError = false
                messages[idx].sessionKey = event.sessionKey
            } else if let finalText = event.textContent, !finalText.isEmpty {
                messages.append(
                    ChatMessage(
                        id: event.runId,
                        role: .assistant,
                        text: finalText,
                        isStreaming: false,
                        sessionKey: event.sessionKey
                    )
                )
            }

        case "error":
            if let idx = messages.firstIndex(where: { $0.id == event.runId }) {
                messages[idx].isError = true
                messages[idx].isStreaming = false
                messages[idx].sessionKey = event.sessionKey
                if let errMsg = event.errorMessage, messages[idx].text.isEmpty {
                    messages[idx].text = errMsg
                }
            } else {
                messages.append(
                    ChatMessage(
                        id: event.runId,
                        role: .assistant,
                        text: event.errorMessage ?? "Unknown error",
                        isError: true,
                        sessionKey: event.sessionKey
                    )
                )
            }

        case "aborted":
            if let idx = messages.firstIndex(where: { $0.id == event.runId }) {
                messages[idx].isStreaming = false
                messages[idx].sessionKey = event.sessionKey
            }

        default:
            break
        }

        return messages
    }

    private static func mergeStreamingText(current: String, incoming: String) -> String {
        guard !incoming.isEmpty else { return current }
        guard !current.isEmpty else { return incoming }

        if incoming == current { return current }
        if incoming.hasPrefix(current) { return incoming }
        if current.hasPrefix(incoming) { return current }
        if current.hasSuffix(incoming) { return current }

        return current + incoming
    }

    static func hydrating(
        runId: String,
        sessionKey: String,
        with history: GatewayChatHistoryResult,
        in existingMessages: [ChatMessage]
    ) -> [ChatMessage] {
        var messages = existingMessages

        guard let assistantText = history.latestAssistantText, !assistantText.isEmpty else {
            if let idx = messages.firstIndex(where: { $0.id == runId }) {
                messages[idx].isStreaming = false
            }
            return messages
        }

        if let idx = messages.firstIndex(where: { $0.id == runId }) {
            messages[idx].text = assistantText
            messages[idx].isStreaming = false
            messages[idx].isError = false
            messages[idx].sessionKey = sessionKey
        } else {
            messages.append(
                ChatMessage(
                    id: runId,
                    role: .assistant,
                    text: assistantText,
                    isStreaming: false,
                    sessionKey: sessionKey
                )
            )
        }

        return messages
    }
}
