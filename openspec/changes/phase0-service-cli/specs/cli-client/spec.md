## ADDED Requirements

### Requirement: Connect to relay service
The CLI client SHALL connect to the ClawChat relay service via WebSocket and authenticate using either a pairing code (first time) or device token (subsequent).

#### Scenario: First-time connection with pairing code
- **WHEN** the user runs `clawchat connect --relay wss://relay.example.com --code ABC-123`
- **THEN** the CLI SHALL connect to the relay, send `app.pair`, and on success store the device token locally for future use

#### Scenario: Reconnect with stored device token
- **WHEN** the user runs `clawchat connect` and a device token exists in local config
- **THEN** the CLI SHALL connect using `app.connect` with the stored device token

#### Scenario: Connection failed
- **WHEN** the relay is unreachable or returns an auth error
- **THEN** the CLI SHALL display an error message and exit with non-zero code

### Requirement: Interactive text chat
The CLI client SHALL provide an interactive terminal prompt for sending text messages to the connected agent.

#### Scenario: Send a text message
- **WHEN** the user types a message and presses Enter
- **THEN** the CLI SHALL send a `message.inbound` to the relay and display a waiting indicator

#### Scenario: Receive a text response
- **WHEN** the relay delivers a `message.outbound` with text content
- **THEN** the CLI SHALL display the text with markdown formatting (if terminal supports it)

### Requirement: Streaming response display
The CLI client SHALL render streaming responses in real-time as deltas arrive.

#### Scenario: Display streaming text
- **WHEN** `message.stream` frames arrive with `phase: "streaming"`
- **THEN** the CLI SHALL append each `delta` to the current output line without newline, creating a typing effect

#### Scenario: Stream completes
- **WHEN** a `message.stream` frame arrives with `phase: "done"`
- **THEN** the CLI SHALL finalize the output and return to the input prompt

### Requirement: Tool event display
The CLI client SHALL display tool execution events as visual blocks in the terminal.

#### Scenario: Tool starts
- **WHEN** a `tool.event` with `phase: "start"` arrives
- **THEN** the CLI SHALL display a colored block showing the tool name and input summary

#### Scenario: Tool completes
- **WHEN** a `tool.event` with `phase: "result"` arrives
- **THEN** the CLI SHALL update the tool block with a completion indicator

### Requirement: Reasoning block display
The CLI client SHALL display reasoning/thinking blocks in a distinct visual style.

#### Scenario: Reasoning streaming
- **WHEN** `message.reasoning` frames arrive
- **THEN** the CLI SHALL display the text in a dimmed/gray style, prefixed with a "thinking" indicator

### Requirement: Typing indicator display
The CLI client SHALL display when the agent is processing.

#### Scenario: Agent typing
- **WHEN** a `typing` message with `active: true` arrives
- **THEN** the CLI SHALL show a spinner or "Agent is typing..." indicator

#### Scenario: Agent stops typing
- **WHEN** a `typing` message with `active: false` arrives or a response message arrives
- **THEN** the CLI SHALL hide the typing indicator

### Requirement: Local config storage
The CLI client SHALL store configuration (relay URL, device token, preferences) in `~/.clawchat/config.json`.

#### Scenario: Save device token after pairing
- **WHEN** pairing succeeds and the relay returns a device token
- **THEN** the CLI SHALL write the token to `~/.clawchat/config.json`

#### Scenario: Read config on startup
- **WHEN** the CLI starts and `~/.clawchat/config.json` exists
- **THEN** the CLI SHALL read relay URL and device token from it

### Requirement: Graceful disconnect
The CLI client SHALL handle Ctrl+C and connection drops gracefully.

#### Scenario: User presses Ctrl+C
- **WHEN** the user presses Ctrl+C during a chat session
- **THEN** the CLI SHALL close the WebSocket cleanly and exit with code 0

#### Scenario: Connection drops
- **WHEN** the WebSocket connection drops unexpectedly
- **THEN** the CLI SHALL display a disconnection message and attempt to reconnect with exponential backoff
