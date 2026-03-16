package com.clawchat.kit

import com.clawchat.kit.chat.*
import com.clawchat.kit.protocol.*
import org.junit.Assert.*
import org.junit.Test

class ChatStateTest {

    // MARK: - ChatMessage tests

    @Test
    fun `ChatMessage defaults`() {
        val msg = ChatMessage(role = Role.USER, text = "hello")
        assertEquals(Role.USER, msg.role)
        assertEquals("hello", msg.text)
        assertNull(msg.reasoning)
        assertTrue(msg.toolEvents.isEmpty())
        assertFalse(msg.isStreaming)
        assertFalse(msg.isError)
        assertTrue(msg.id.isNotEmpty())
        assertTrue(msg.timestamp > 0)
    }

    @Test
    fun `ChatMessage assistant streaming`() {
        val msg = ChatMessage(role = Role.ASSISTANT, text = "hi", isStreaming = true)
        assertEquals(Role.ASSISTANT, msg.role)
        assertTrue(msg.isStreaming)
    }

    @Test
    fun `ChatToolEvent tracks phase`() {
        val event = ChatToolEvent(id = "t1", tool = "bash", phase = ToolPhase.START)
        assertEquals(ToolPhase.START, event.phase)
        val updated = event.copy(phase = ToolPhase.RESULT)
        assertEquals(ToolPhase.RESULT, updated.phase)
    }

    @Test
    fun `ChatState immutable snapshot`() {
        val state = ChatState(
            messages = listOf(ChatMessage(role = Role.USER, text = "hi")),
            isTyping = true,
            gatewayOnline = true,
        )
        assertEquals(1, state.messages.size)
        assertTrue(state.isTyping)
        assertTrue(state.gatewayOnline)
    }

    // MARK: - Stream accumulation logic tests

    @Test
    fun `stream accumulation - first delta creates message`() {
        // Simulate what ChatStateManager does: first streaming delta creates a new message
        val messages = mutableListOf<ChatMessage>()
        val stream = MessageStream(
            type = "message.stream", id = "m1", ts = 1L,
            delta = "Hello", phase = StreamPhase.STREAMING,
        )

        // First delta: no existing message with this id
        val idx = messages.indexOfFirst { it.id == stream.id }
        assertEquals(-1, idx)

        val msg = ChatMessage(id = stream.id, role = Role.ASSISTANT, text = stream.delta, isStreaming = true)
        messages.add(msg)

        assertEquals(1, messages.size)
        assertEquals("Hello", messages[0].text)
        assertTrue(messages[0].isStreaming)
    }

    @Test
    fun `stream accumulation - subsequent delta appends`() {
        val messages = mutableListOf(
            ChatMessage(id = "m1", role = Role.ASSISTANT, text = "Hello", isStreaming = true)
        )

        val stream = MessageStream(
            type = "message.stream", id = "m1", ts = 2L,
            delta = " world", phase = StreamPhase.STREAMING,
        )

        val idx = messages.indexOfFirst { it.id == stream.id }
        assertEquals(0, idx)
        messages[idx] = messages[idx].copy(text = messages[idx].text + stream.delta)

        assertEquals("Hello world", messages[0].text)
        assertTrue(messages[0].isStreaming)
    }

    @Test
    fun `stream accumulation - done finalizes message`() {
        val messages = mutableListOf(
            ChatMessage(id = "m1", role = Role.ASSISTANT, text = "Hello world", isStreaming = true)
        )

        val stream = MessageStream(
            type = "message.stream", id = "m1", ts = 3L,
            delta = "", phase = StreamPhase.DONE, finalText = "Hello world!",
        )

        val idx = messages.indexOfFirst { it.id == stream.id }
        val finalText = stream.finalText ?: messages[idx].text
        messages[idx] = messages[idx].copy(text = finalText, isStreaming = false)

        assertEquals("Hello world!", messages[0].text)
        assertFalse(messages[0].isStreaming)
    }

    @Test
    fun `stream accumulation - error marks message`() {
        val messages = mutableListOf(
            ChatMessage(id = "m1", role = Role.ASSISTANT, text = "partial", isStreaming = true)
        )

        val stream = MessageStream(
            type = "message.stream", id = "m1", ts = 3L,
            delta = "", phase = StreamPhase.ERROR,
        )

        val idx = messages.indexOfFirst { it.id == stream.id }
        messages[idx] = messages[idx].copy(isError = true, isStreaming = false)

        assertTrue(messages[0].isError)
        assertFalse(messages[0].isStreaming)
    }

    @Test
    fun `reasoning appends to message`() {
        val msg = ChatMessage(id = "m1", role = Role.ASSISTANT, text = "hi", isStreaming = true)
        var reasoning: String? = msg.reasoning

        // First reasoning text
        reasoning = if (reasoning != null) reasoning + "think" else "think"
        assertEquals("think", reasoning)

        // Second reasoning text
        reasoning += "ing"
        assertEquals("thinking", reasoning)
    }

    @Test
    fun `tool event tracking - start then result`() {
        val tools = mutableListOf<ChatToolEvent>()

        // Start event
        tools.add(ChatToolEvent(id = "t1", tool = "bash", phase = ToolPhase.START, label = "Running"))

        // Result event
        val toolIdx = tools.indexOfFirst { it.id == "t1" }
        tools[toolIdx] = tools[toolIdx].copy(phase = ToolPhase.RESULT, label = "Done")

        assertEquals(1, tools.size)
        assertEquals(ToolPhase.RESULT, tools[0].phase)
        assertEquals("Done", tools[0].label)
    }
}
