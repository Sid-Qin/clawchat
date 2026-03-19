## ADDED Requirements

### Requirement: StateFlow-based chat state manager
`ChatStateManager` SHALL expose `state: StateFlow<ChatState>` where `ChatState` is a data class with: `messages: List<ChatMessage>`, `connectionState: ConnectionState`, `isTyping: Boolean`, `gatewayOnline: Boolean`.

#### Scenario: Compose UI observes messages
- **WHEN** a new message is added to `ChatState.messages`
- **THEN** any Compose UI collecting `chatStateManager.state` SHALL recompose

### Requirement: Accumulate streaming deltas into messages
When `message.stream` frames arrive with `phase: "streaming"`, the state manager SHALL accumulate deltas into an in-progress `ChatMessage`. When `phase: "done"` arrives, the message SHALL be finalized with `finalText`.

#### Scenario: Stream start
- **WHEN** the first `message.stream` with a new `id` and `phase: "streaming"` arrives
- **THEN** a new `ChatMessage` with `role = Role.ASSISTANT` and `isStreaming = true` SHALL be added to `messages`

#### Scenario: Stream delta accumulation
- **WHEN** subsequent `message.stream` frames with `phase: "streaming"` arrive for the same `id`
- **THEN** `delta` text SHALL be appended to the in-progress message's `text`

#### Scenario: Stream completion
- **WHEN** a `message.stream` with `phase: "done"` and `finalText` arrives
- **THEN** the message's `text` SHALL be replaced with `finalText` and `isStreaming` set to `false`

#### Scenario: Stream error
- **WHEN** a `message.stream` with `phase: "error"` arrives
- **THEN** the message SHALL be marked with `isError = true` and `isStreaming = false`

### Requirement: Reasoning block accumulation
When `message.reasoning` frames arrive, the state manager SHALL accumulate reasoning text into the current in-progress message's `reasoning` field.

#### Scenario: Reasoning during stream
- **WHEN** a `message.reasoning` frame arrives while a message is streaming
- **THEN** the reasoning `text` SHALL be appended to the message's `reasoning` property

### Requirement: Tool event tracking
The state manager SHALL track tool events by `id`, updating their phase as new `tool.event` frames arrive.

#### Scenario: Tool start then result
- **WHEN** a `tool.event` with `phase: "start"` arrives, followed by `phase: "result"`
- **THEN** the tool event in the current message's `toolEvents` list SHALL update from `START` to `RESULT`

### Requirement: Send user message
`ChatStateManager` SHALL provide `sendMessage(text: String)` that creates a `ChatMessage` with `role = Role.USER`, adds it to `messages`, and sends a `message.inbound` frame to the relay.

#### Scenario: Send text message
- **WHEN** `sendMessage("hello")` is called
- **THEN** a user message SHALL appear in `messages` and a `message.inbound` frame SHALL be sent

### Requirement: Typing indicator
When `typing` frames arrive with `active: true`, `isTyping` SHALL be set to `true`. It SHALL reset to `false` when `active: false` is received or when a message stream begins.

#### Scenario: Typing on then off
- **WHEN** a `typing` with `active: true` arrives, then `active: false`
- **THEN** `isTyping` SHALL be `true` then `false`

### Requirement: Gateway presence
When `presence` frames indicate the gateway goes offline, `gatewayOnline` SHALL update to `false`. Messages sent while gateway is offline SHALL show an appropriate error.

#### Scenario: Gateway disconnect
- **WHEN** a `presence` frame with `online: false` arrives
- **THEN** `gatewayOnline` SHALL be `false`
