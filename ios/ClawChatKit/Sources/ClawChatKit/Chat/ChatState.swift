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

    public var onAppConnected: ((AppConnected) -> Void)?
    public var onStatusResponse: ((StatusResponse) -> Void)?
    public var onFatalError: ((ErrorMessage) -> Void)?

    // MARK: - Internal state

    private let client: WebSocketClient
    private var messageLoopTask: Task<Void, Never>?
    private var stateObserverTask: Task<Void, Never>?

    // Track in-progress streaming messages and typing state by route.
    private var streamingMessageIdByRoute: [ChatRoute: String] = [:]
    private var activeTypingRoutes = Set<ChatRoute>()

    // MARK: - Init

    public init(client: WebSocketClient) {
        self.client = client
    }

    // MARK: - Lifecycle

    /// Start listening to the WebSocket message stream and connection state.
    @MainActor
    public func start() {
        startMessageLoop()
        startStateObserver()
    }

    /// Stop listening and clean up.
    @MainActor
    public func stop() {
        messageLoopTask?.cancel()
        messageLoopTask = nil
        stateObserverTask?.cancel()
        stateObserverTask = nil
    }

    @MainActor
    public func setGatewayOnline(_ isOnline: Bool) {
        gatewayOnline = isOnline
    }

    /// Remove completed (non-streaming) messages that have been persisted.
    /// Call this after syncing live messages to storage to prevent replay on re-enter.
    @MainActor
    public func clearCompletedMessages(persistedIds: Set<String>) {
        messages.removeAll { msg in
            !msg.isStreaming && persistedIds.contains(msg.id)
        }
    }

    @MainActor
    public func liveMessages(for agentId: String, sessionKey: String?) -> [ChatMessage] {
        messages.filter { $0.route.matches(targetAgentId: agentId, targetSessionKey: sessionKey) }
    }

    @MainActor
    public func isTyping(for agentId: String, sessionKey: String?) -> Bool {
        activeTypingRoutes.contains { $0.matches(targetAgentId: agentId, targetSessionKey: sessionKey) }
    }

    static func mergeStreamingText(current: String, incoming: String) -> String {
        guard !incoming.isEmpty else { return current }
        guard !current.isEmpty else { return incoming }

        if incoming == current { return current }
        if incoming.hasPrefix(current) { return incoming }
        if current.hasPrefix(incoming) { return current }
        if current.hasSuffix(incoming) { return current }

        let maxOverlap = min(current.count, incoming.count)
        for overlap in stride(from: maxOverlap, to: 0, by: -1) {
            let currentSuffix = String(current.suffix(overlap))
            let incomingPrefix = String(incoming.prefix(overlap))
            if currentSuffix == incomingPrefix {
                return current + incoming.dropFirst(overlap)
            }
        }

        return current + incoming
    }

    // MARK: - Send

    /// Send a user message. Appends to messages and sends to relay.
    @MainActor
    public func sendMessage(
        text: String,
        agentId: String = "default",
        sessionKey: String? = nil,
        attachments: [MessageAttachment] = []
    ) {
        let userMessage = ChatMessage(role: .user, text: text, agentId: agentId, sessionKey: sessionKey)
        messages.append(userMessage)

        let inbound = MessageInbound(
            text: text.isEmpty ? nil : text,
            agentId: agentId,
            attachments: attachments.isEmpty ? nil : attachments,
            sessionKey: sessionKey
        )
        print("[ChatState] sendMessage: agentId=\(agentId) sessionKey=\(sessionKey ?? "-") text=\(text.prefix(40))")
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
                    guard let self else { return }
                    self.connectionState = state
                    if state == .disconnected {
                        self.cleanUpStaleStreamingState()
                    }
                }
            }
        }
    }

    @MainActor
    private func cleanUpStaleStreamingState() {
        for (_, messageId) in streamingMessageIdByRoute {
            if let idx = messages.firstIndex(where: { $0.id == messageId }) {
                messages[idx].isStreaming = false
            }
        }
        streamingMessageIdByRoute.removeAll()
        activeTypingRoutes.removeAll()
        refreshTypingState()
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
        case .appConnected(let connected):
            onAppConnected?(connected)
        case .statusResponse(let status):
            onStatusResponse?(status)
        default:
            break
        }
    }

    // MARK: - Stream accumulation (5.3)

    @MainActor
    private func handleStream(_ stream: MessageStream) {
        let route = ChatRoute(agentId: stream.agentId, sessionKey: stream.sessionKey)
        activeTypingRoutes.remove(route)
        refreshTypingState()

        switch stream.phase {
        case .streaming:
            if let idx = messages.firstIndex(where: { $0.id == stream.id }) {
                messages[idx].agentId = stream.agentId ?? messages[idx].agentId
                messages[idx].sessionKey = stream.sessionKey ?? messages[idx].sessionKey
                messages[idx].isStreaming = true
                messages[idx].text = Self.mergeStreamingText(
                    current: messages[idx].text,
                    incoming: stream.delta
                )
            } else {
                // Create new assistant message
                let msg = ChatMessage(
                    id: stream.id,
                    role: .assistant,
                    text: stream.delta,
                    isStreaming: true,
                    agentId: stream.agentId,
                    sessionKey: stream.sessionKey
                )
                messages.append(msg)
            }
            streamingMessageIdByRoute[route] = stream.id

        case .done:
            if let idx = messages.firstIndex(where: { $0.id == stream.id }) {
                messages[idx].agentId = stream.agentId ?? messages[idx].agentId
                messages[idx].sessionKey = stream.sessionKey ?? messages[idx].sessionKey
                if let finalText = stream.finalText {
                    messages[idx].text = finalText
                }
                messages[idx].isStreaming = false
            }
            if streamingMessageIdByRoute[route] == stream.id {
                streamingMessageIdByRoute.removeValue(forKey: route)
            }

        case .error:
            if let idx = messages.firstIndex(where: { $0.id == stream.id }) {
                messages[idx].agentId = stream.agentId ?? messages[idx].agentId
                messages[idx].sessionKey = stream.sessionKey ?? messages[idx].sessionKey
                messages[idx].isError = true
                messages[idx].isStreaming = false
            }
            if streamingMessageIdByRoute[route] == stream.id {
                streamingMessageIdByRoute.removeValue(forKey: route)
            }
        }
    }

    // MARK: - Reasoning accumulation (5.4)

    @MainActor
    private func handleReasoning(_ reasoning: MessageReasoning) {
        // Find the current streaming message to attach reasoning
        let route = ChatRoute(agentId: reasoning.agentId, sessionKey: reasoning.sessionKey)
        guard let id = currentStreamingMessageId(for: route),
              let idx = messages.firstIndex(where: { $0.id == id }) else {
            return
        }

        switch reasoning.phase {
        case .streaming, .none:
            if messages[idx].reasoning == nil {
                messages[idx].reasoning = reasoning.text
            } else {
                messages[idx].reasoning = Self.mergeStreamingText(
                    current: messages[idx].reasoning ?? "",
                    incoming: reasoning.text
                )
            }
        case .done:
            break
        }
    }

    // MARK: - Tool events (5.5)

    @MainActor
    private func handleToolEvent(_ event: ToolEvent) {
        // Attach tool events to current streaming message
        let route = ChatRoute(agentId: event.agentId, sessionKey: event.sessionKey)
        guard let id = currentStreamingMessageId(for: route),
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
        let route = ChatRoute(agentId: typing.agentId, sessionKey: typing.sessionKey)
        if typing.active {
            activeTypingRoutes.insert(route)
        } else {
            activeTypingRoutes.remove(route)
        }
        refreshTypingState()
    }

    // MARK: - Presence (5.8)

    @MainActor
    private func handlePresence(_ presence: Presence) {
        gatewayOnline = presence.online ?? false
    }

    // MARK: - Error

    @MainActor
    private func handleError(_ error: ErrorMessage) {
        switch error.code {
        case .unauthorized, .deviceRevoked:
            onFatalError?(error)
            return
        default:
            break
        }

        let errorMessage = ChatMessage(
            id: error.id,
            role: .assistant,
            text: error.message,
            isError: true
        )
        messages.append(errorMessage)
    }

    @MainActor
    private func currentStreamingMessageId(for route: ChatRoute) -> String? {
        if let id = streamingMessageIdByRoute[route] {
            return id
        }

        return messages.last(where: { $0.isStreaming && $0.route == route })?.id
    }

    @MainActor
    private func refreshTypingState() {
        isTyping = !activeTypingRoutes.isEmpty
    }
}
