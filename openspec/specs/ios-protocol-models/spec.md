## ADDED Requirements

### Requirement: Codable message types matching wire protocol
The package SHALL define Swift Codable structs for every message type in `@clawchat/protocol`, grouped by category: connection, messaging, control, pairing, actions, and errors.

#### Scenario: Decode gateway.registered message
- **WHEN** a JSON frame `{"type":"gateway.registered","id":"...","ts":1234,"pairedDevices":2}` is received
- **THEN** it decodes to a `GatewayRegistered` struct with `pairedDevices == 2`

#### Scenario: Decode message.stream delta
- **WHEN** a JSON frame with `type: "message.stream"`, `phase: "streaming"`, and `delta: "hello"` is received
- **THEN** it decodes to a `MessageStream` struct with `phase == .streaming` and `delta == "hello"`

#### Scenario: Decode message.stream done with finalText
- **WHEN** a JSON frame with `type: "message.stream"`, `phase: "done"`, and `finalText: "full response"` is received
- **THEN** it decodes to a `MessageStream` struct with `phase == .done` and `finalText == "full response"`

### Requirement: Discriminated union message decoding
The package SHALL provide a `ClawChatMessage` enum that decodes any valid wire protocol JSON frame by reading the `type` field first, then decoding the appropriate struct.

#### Scenario: Unknown message type
- **WHEN** a JSON frame with an unrecognized `type` field is received
- **THEN** decoding SHALL return a `.unknown(type: String, raw: Data)` case without throwing

#### Scenario: Round-trip encoding
- **WHEN** a `MessageInbound` is encoded to JSON and decoded back
- **THEN** the decoded value SHALL equal the original

### Requirement: BaseMessage envelope
Every message type SHALL include `id` (String), `ts` (Int64 milliseconds), and `type` (String) fields conforming to a `BaseMessage` protocol.

#### Scenario: All message types conform to BaseMessage
- **WHEN** any `ClawChatMessage` case is accessed
- **THEN** its `id`, `ts`, and `type` properties SHALL be accessible

### Requirement: Streaming phase enum
`MessageStream.phase` SHALL be a `StreamPhase` enum with cases: `.streaming`, `.done`, `.error`.

#### Scenario: Phase string mapping
- **WHEN** phase JSON value is `"streaming"`, `"done"`, or `"error"`
- **THEN** it decodes to the corresponding `StreamPhase` case

### Requirement: Tool event phases
`ToolEvent.phase` SHALL be a `ToolPhase` enum with cases: `.start`, `.progress`, `.result`, `.error`.

#### Scenario: Tool start event
- **WHEN** a `tool.event` frame with `phase: "start"`, `tool: "web_search"`, and `label: "Searching..."` is received
- **THEN** it decodes to a `ToolEvent` with `phase == .start`, `tool == "web_search"`, `label == "Searching..."`

### Requirement: Error message with codes
`ErrorMessage` SHALL include `code` (String) and `message` (String) fields. Known error codes SHALL be defined as a `ClawChatErrorCode` enum with a `.unknown(String)` fallback.

#### Scenario: Gateway offline error
- **WHEN** a frame `{"type":"error","code":"gateway_offline","message":"Gateway is not connected"}` is received
- **THEN** it decodes to `ErrorMessage` with `code == .gatewayOffline`
