package com.clawchat.kit.chat

import com.clawchat.kit.protocol.*
import com.clawchat.kit.websocket.WebSocketClient
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine

/**
 * Manages chat state by processing WebSocket messages from the relay.
 * Exposes [state] as a [StateFlow] for Compose UI observation.
 */
class ChatStateManager(
    private val client: WebSocketClient,
) {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)

    // Mutable internal state
    private val _messages = MutableStateFlow<List<ChatMessage>>(emptyList())
    private val _isTyping = MutableStateFlow(false)
    private val _gatewayOnline = MutableStateFlow(false)

    // Track the currently streaming message id
    private var streamingMessageId: String? = null

    private var messageJob: Job? = null

    /** Observable snapshot of chat state for Compose. */
    val state: StateFlow<ChatState> = MutableStateFlow(ChatState()).also { stateFlow ->
        scope.launch {
            combine(
                _messages,
                client.connectionState,
                _isTyping,
                _gatewayOnline,
            ) { messages, connection, typing, gateway ->
                ChatState(
                    messages = messages,
                    connectionState = connection,
                    isTyping = typing,
                    gatewayOnline = gateway,
                )
            }.collect { (stateFlow as MutableStateFlow).value = it }
        }
    }

    /** Start listening to the WebSocket message flow. */
    fun start() {
        messageJob?.cancel()
        messageJob = scope.launch {
            client.messages.collect { dispatch(it) }
        }
    }

    /** Stop listening and clean up. */
    fun stop() {
        messageJob?.cancel()
        messageJob = null
    }

    /** Send a user message — adds to messages and sends a message.inbound frame. */
    fun sendMessage(text: String, agentId: String = "default") {
        val userMsg = ChatMessage(role = Role.USER, text = text)
        _messages.value = _messages.value + userMsg

        val inbound = MessageInbound(text = text, agentId = agentId)
        client.send(inbound)
    }

    // MARK: - Dispatch

    private fun dispatch(message: ClawChatMessage) {
        when (message) {
            is ClawChatMessage.MessageStreamMsg -> handleStream(message.value)
            is ClawChatMessage.MessageReasoningMsg -> handleReasoning(message.value)
            is ClawChatMessage.ToolEventMsg -> handleToolEvent(message.value)
            is ClawChatMessage.TypingMsg -> handleTyping(message.value)
            is ClawChatMessage.PresenceMsg -> handlePresence(message.value)
            is ClawChatMessage.ErrorMsg -> handleError(message.value)
            else -> {} // Other messages not handled by state manager
        }
    }

    // MARK: - Stream accumulation (5.3)

    private fun handleStream(stream: MessageStream) {
        // Typing stops when stream starts
        _isTyping.value = false

        val current = _messages.value.toMutableList()

        when (stream.phase) {
            StreamPhase.STREAMING -> {
                val idx = current.indexOfFirst { it.id == stream.id }
                if (idx >= 0) {
                    // Append delta to existing message
                    current[idx] = current[idx].copy(text = current[idx].text + stream.delta)
                } else {
                    // Create new assistant message
                    val msg = ChatMessage(
                        id = stream.id,
                        role = Role.ASSISTANT,
                        text = stream.delta,
                        isStreaming = true,
                    )
                    current.add(msg)
                    streamingMessageId = stream.id
                }
            }

            StreamPhase.DONE -> {
                val idx = current.indexOfFirst { it.id == stream.id }
                if (idx >= 0) {
                    val finalText = stream.finalText ?: current[idx].text
                    current[idx] = current[idx].copy(text = finalText, isStreaming = false)
                }
                if (streamingMessageId == stream.id) streamingMessageId = null
            }

            StreamPhase.ERROR -> {
                val idx = current.indexOfFirst { it.id == stream.id }
                if (idx >= 0) {
                    current[idx] = current[idx].copy(isError = true, isStreaming = false)
                }
                if (streamingMessageId == stream.id) streamingMessageId = null
            }
        }

        _messages.value = current
    }

    // MARK: - Reasoning accumulation (5.4)

    private fun handleReasoning(reasoning: MessageReasoning) {
        val id = streamingMessageId ?: return
        val current = _messages.value.toMutableList()
        val idx = current.indexOfFirst { it.id == id }
        if (idx < 0) return

        when (reasoning.phase) {
            ReasoningPhase.STREAMING, null -> {
                val existing = current[idx].reasoning
                current[idx] = current[idx].copy(
                    reasoning = if (existing != null) existing + reasoning.text else reasoning.text
                )
            }
            ReasoningPhase.DONE -> {} // No-op
        }

        _messages.value = current
    }

    // MARK: - Tool event tracking (5.5)

    private fun handleToolEvent(event: ToolEvent) {
        val id = streamingMessageId ?: return
        val current = _messages.value.toMutableList()
        val msgIdx = current.indexOfFirst { it.id == id }
        if (msgIdx < 0) return

        val msg = current[msgIdx]
        val toolIdx = msg.toolEvents.indexOfFirst { it.id == event.id }

        if (toolIdx >= 0) {
            // Update existing tool event
            msg.toolEvents[toolIdx] = msg.toolEvents[toolIdx].copy(
                phase = event.phase,
                label = event.label ?: msg.toolEvents[toolIdx].label,
                result = if (event.phase == ToolPhase.RESULT) event.result else msg.toolEvents[toolIdx].result,
            )
        } else {
            // New tool event
            msg.toolEvents.add(
                ChatToolEvent(
                    id = event.id,
                    tool = event.tool,
                    phase = event.phase,
                    label = event.label,
                    result = event.result,
                )
            )
        }

        // Force new list reference for StateFlow emission
        _messages.value = current.toList()
    }

    // MARK: - Typing indicator (5.7)

    private fun handleTyping(typing: Typing) {
        _isTyping.value = typing.active
    }

    // MARK: - Gateway presence (5.8)

    private fun handlePresence(presence: Presence) {
        _gatewayOnline.value = presence.online ?: false
    }

    // MARK: - Error messages

    private fun handleError(error: ErrorMessage) {
        val errorMsg = ChatMessage(
            id = error.id,
            role = Role.ASSISTANT,
            text = error.message,
            isError = true,
        )
        _messages.value = _messages.value + errorMsg
    }
}
