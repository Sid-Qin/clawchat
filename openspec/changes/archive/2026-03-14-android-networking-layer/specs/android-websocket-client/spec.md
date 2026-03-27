## ADDED Requirements

### Requirement: WebSocket connection to relay
The client SHALL connect to a relay URL via OkHttp `WebSocket`, appending `/ws/app` to the base URL if not already present. The URL scheme SHALL be converted from `https://` to `wss://` and `http://` to `ws://` if needed.

#### Scenario: Successful connection
- **WHEN** `connect(relayUrl)` is called with a valid relay URL
- **THEN** a WebSocket connection SHALL be established to `<relayUrl>/ws/app`

#### Scenario: Connection with trailing slash
- **WHEN** the relay URL ends with `/`
- **THEN** the trailing slash SHALL be stripped before appending `/ws/app`

### Requirement: Automatic reconnection with exponential backoff
On unexpected disconnect, the client SHALL automatically reconnect with exponential backoff starting at 1 second, doubling each attempt, capped at 60 seconds. The backoff SHALL reset to 1 second on successful connection.

#### Scenario: First reconnection attempt
- **WHEN** the WebSocket disconnects unexpectedly
- **THEN** the client SHALL attempt reconnection after 1 second

#### Scenario: Backoff cap
- **WHEN** 7 consecutive reconnection attempts fail
- **THEN** the delay SHALL be capped at 60 seconds (not 128s)

#### Scenario: Backoff reset on success
- **WHEN** a reconnection attempt succeeds
- **THEN** the backoff delay SHALL reset to 1 second

### Requirement: Protocol-level ping keepalive
The client SHALL send a JSON ping frame `{"type":"ping","id":"<uuid>","ts":<ms>}` every 30 seconds. If no message is received within 10 seconds after a ping, the client SHALL close and reconnect.

#### Scenario: Ping sent on schedule
- **WHEN** 30 seconds pass without sending a message
- **THEN** the client SHALL send a protocol-level ping

#### Scenario: Pong timeout triggers reconnect
- **WHEN** no message is received within 10 seconds of a ping
- **THEN** the client SHALL close the connection and begin reconnection

#### Scenario: Any message resets pong timer
- **WHEN** any message is received after a ping was sent
- **THEN** the pong timeout timer SHALL be cancelled

### Requirement: Message dispatch via SharedFlow
The client SHALL expose received messages as a `SharedFlow<ClawChatMessage>`. Messages of type `pong` SHALL be consumed internally and not emitted.

#### Scenario: Message delivery
- **WHEN** the relay sends a `message.stream` frame
- **THEN** the decoded `MessageStream` SHALL appear in the shared flow

#### Scenario: Pong suppression
- **WHEN** the relay sends a `{"type":"pong"}` frame
- **THEN** it SHALL NOT appear in the message flow

### Requirement: Send typed messages
The client SHALL provide `send(message: BaseMessage)` that JSON-encodes and sends via WebSocket.

#### Scenario: Send message.inbound
- **WHEN** `send(messageInbound)` is called while connected
- **THEN** the message SHALL be sent as a JSON text frame

#### Scenario: Send while disconnected
- **WHEN** `send()` is called while the WebSocket is not connected
- **THEN** the call SHALL silently drop the message (no exception)

### Requirement: Connection state observation
The client SHALL expose a `connectionState: StateFlow<ConnectionState>` property of type `ConnectionState` enum (`DISCONNECTED`, `CONNECTING`, `CONNECTED`) that updates in real time.

#### Scenario: State transitions on connect
- **WHEN** `connect()` is called
- **THEN** state SHALL transition: `DISCONNECTED` → `CONNECTING` → `CONNECTED`

#### Scenario: State on disconnect
- **WHEN** the WebSocket closes
- **THEN** state SHALL transition to `DISCONNECTED` (then `CONNECTING` if auto-reconnecting)
