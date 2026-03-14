import Foundation
import Observation

/// Observable chat state manager that processes WebSocket messages
/// and maintains UI-ready state for SwiftUI binding.
@Observable
public final class ChatState: @unchecked Sendable {
    // MARK: - Observable state

    public private(set) var messages: [ChatMessage] = []
    public private(set) var connectionState: ConnectionState = .disconnected
    public private(set) var isTyping: Bool = false
    public private(set) var gatewayOnline: Bool = false

    // MARK: - Internal state

    private let client: WebSocketClient
    private var messageLoopTask: Task<Void, Never>?
    private var stateObserverTask: Task<Void, Never>?

    // Track in-progress streaming message by agentId
    private var streamingMessageId: String?

    // MARK: - Init

    public init(client: WebSocketClient) {
        self.client = client
    }

    // MARK: - Lifecycle

    /// Start listening to the WebSocket message stream and connection state.
    public func start() {
        startMessageLoop()
        startStateObserver()
    }

    /// Stop listening and clean up.
    public func stop() {
        messageLoopTask?.cancel()
        messageLoopTask = nil
        stateObserverTask?.cancel()
        stateObserverTask = nil
    }

    // MARK: - Send

    /// Send a user message. Appends to messages and sends to relay.
    public func sendMessage(text: String, agentId: String = "default") {
        let userMessage = ChatMessage(role: .user, text: text)
        messages.append(userMessage)

        let inbound = MessageInbound(text: text, agentId: agentId)
        Task {
            await client.send(inbound)
        }
    }

    // MARK: - Message dispatch

    private func startMessageLoop() {
        messageLoopTask?.cancel()
        messageLoopTask = Task { [weak self] in
            guard let self else { return }
            let messages = await self.client.messages
            for await msg in messages {
                guard !Task.isCancelled else { break }
                await MainActor.run {
                    self.dispatch(msg)
                }
            }
        }
    }

    private func startStateObserver() {
        stateObserverTask?.cancel()
        stateObserverTask = Task { [weak self] in
            guard let self else { return }
            await self.client.onStateChange { [weak self] state in
                Task { @MainActor in
                    self?.connectionState = state
                }
            }
        }
    }

    @MainActor
    private func dispatch(_ message: ClawChatMessage) {
        switch message {
        case .messageStream(let stream):
            handleStream(stream)
        case .messageReasoning(let reasoning):
            handleReasoning(reasoning)
        case .toolEvent(let event):
            handleToolEvent(event)
        case .typing(let typing):
            handleTyping(typing)
        case .presence(let presence):
            handlePresence(presence)
        case .error(let error):
            handleError(error)
        default:
            break
        }
    }

    // MARK: - Stream accumulation (5.3)

    @MainActor
    private func handleStream(_ stream: MessageStream) {
        // Typing stops when stream starts
        isTyping = false

        switch stream.phase {
        case .streaming:
            if let idx = messages.firstIndex(where: { $0.id == stream.id }) {
                // Append delta to existing message
                messages[idx].text += stream.delta
            } else {
                // Create new assistant message
                let msg = ChatMessage(
                    id: stream.id,
                    role: .assistant,
                    text: stream.delta,
                    isStreaming: true
                )
                messages.append(msg)
                streamingMessageId = stream.id
            }

        case .done:
            if let idx = messages.firstIndex(where: { $0.id == stream.id }) {
                if let finalText = stream.finalText {
                    messages[idx].text = finalText
                }
                messages[idx].isStreaming = false
            }
            if streamingMessageId == stream.id {
                streamingMessageId = nil
            }

        case .error:
            if let idx = messages.firstIndex(where: { $0.id == stream.id }) {
                messages[idx].isError = true
                messages[idx].isStreaming = false
            }
            if streamingMessageId == stream.id {
                streamingMessageId = nil
            }
        }
    }

    // MARK: - Reasoning accumulation (5.4)

    @MainActor
    private func handleReasoning(_ reasoning: MessageReasoning) {
        // Find the current streaming message to attach reasoning
        guard let id = streamingMessageId,
              let idx = messages.firstIndex(where: { $0.id == id }) else {
            return
        }

        switch reasoning.phase {
        case .streaming, .none:
            if messages[idx].reasoning == nil {
                messages[idx].reasoning = reasoning.text
            } else {
                messages[idx].reasoning! += reasoning.text
            }
        case .done:
            break
        }
    }

    // MARK: - Tool events (5.5)

    @MainActor
    private func handleToolEvent(_ event: ToolEvent) {
        // Attach tool events to current streaming message
        guard let id = streamingMessageId,
              let msgIdx = messages.firstIndex(where: { $0.id == id }) else {
            return
        }

        if let toolIdx = messages[msgIdx].toolEvents.firstIndex(where: { $0.id == event.id }) {
            // Update existing tool event
            messages[msgIdx].toolEvents[toolIdx].phase = event.phase
            messages[msgIdx].toolEvents[toolIdx].label = event.label ?? messages[msgIdx].toolEvents[toolIdx].label
            if case .result = event.phase {
                messages[msgIdx].toolEvents[toolIdx].result = event.result
            }
        } else {
            // New tool event
            let chatTool = ChatToolEvent(
                id: event.id,
                tool: event.tool,
                phase: event.phase,
                label: event.label,
                result: event.result
            )
            messages[msgIdx].toolEvents.append(chatTool)
        }
    }

    // MARK: - Typing (5.7)

    @MainActor
    private func handleTyping(_ typing: Typing) {
        isTyping = typing.active
    }

    // MARK: - Presence (5.8)

    @MainActor
    private func handlePresence(_ presence: Presence) {
        gatewayOnline = presence.online ?? false
    }

    // MARK: - Error

    @MainActor
    private func handleError(_ error: ErrorMessage) {
        let errorMessage = ChatMessage(
            id: error.id,
            role: .assistant,
            text: error.message,
            isError: true
        )
        messages.append(errorMessage)
    }
}
