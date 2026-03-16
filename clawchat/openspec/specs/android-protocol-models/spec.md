## ADDED Requirements

### Requirement: Serializable message types matching wire protocol
The library SHALL define Kotlin `@Serializable` data classes for every message type in `@clawchat/protocol`, grouped by category: connection, messaging, control, pairing, and errors.

#### Scenario: Decode message.stream delta
- **WHEN** a JSON frame with `type: "message.stream"`, `phase: "streaming"`, and `delta: "hello"` is received
- **THEN** it decodes to a `MessageStream` data class with `phase == StreamPhase.STREAMING` and `delta == "hello"`

#### Scenario: Decode message.stream done with finalText
- **WHEN** a JSON frame with `type: "message.stream"`, `phase: "done"`, and `finalText: "full response"` is received
- **THEN** it decodes to a `MessageStream` data class with `phase == StreamPhase.DONE` and `finalText == "full response"`

### Requirement: Sealed class message decoding
The library SHALL provide a `ClawChatMessage` sealed class that decodes any valid wire protocol JSON frame by reading the `type` field first, then decoding the appropriate data class.

#### Scenario: Unknown message type
- **WHEN** a JSON frame with an unrecognized `type` field is received
- **THEN** decoding SHALL return a `ClawChatMessage.Unknown(type, rawJson)` case without throwing

#### Scenario: Round-trip encoding
- **WHEN** a `MessageInbound` is encoded to JSON and decoded back
- **THEN** the decoded value SHALL equal the original

### Requirement: BaseMessage interface
Every message type SHALL include `id` (String), `ts` (Long milliseconds), and `type` (String) fields implementing a `BaseMessage` interface.

#### Scenario: All message types implement BaseMessage
- **WHEN** any `ClawChatMessage` subclass is accessed
- **THEN** its `id`, `ts`, and `type` properties SHALL be accessible

### Requirement: Streaming phase enum
`MessageStream.phase` SHALL be a `StreamPhase` enum with entries: `STREAMING`, `DONE`, `ERROR`, serialized as lowercase strings.

#### Scenario: Phase string mapping
- **WHEN** phase JSON value is `"streaming"`, `"done"`, or `"error"`
- **THEN** it decodes to the corresponding `StreamPhase` entry

### Requirement: Tool event phases
`ToolEvent.phase` SHALL be a `ToolPhase` enum with entries: `START`, `PROGRESS`, `RESULT`, `ERROR`, serialized as lowercase strings.

#### Scenario: Tool start event
- **WHEN** a `tool.event` frame with `phase: "start"`, `tool: "web_search"`, and `label: "Searching..."` is received
- **THEN** it decodes to a `ToolEvent` with `phase == ToolPhase.START`, `tool == "web_search"`, `label == "Searching..."`

### Requirement: Error message with codes
`ErrorMessage` SHALL include `code` (String) and `message` (String) fields. Known error codes SHALL be defined as a `ClawChatErrorCode` enum with an `UNKNOWN` fallback that preserves the raw string.

#### Scenario: Gateway offline error
- **WHEN** a frame `{"type":"error","code":"gateway_offline","message":"Gateway is not connected"}` is received
- **THEN** it decodes to `ErrorMessage` with `code == ClawChatErrorCode.GATEWAY_OFFLINE`
