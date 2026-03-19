## ADDED Requirements

### Requirement: Message envelope format
Every message over the WebSocket SHALL be a JSON text frame with at minimum: `type` (string), `id` (UUIDv7 string), and `ts` (integer, ms since epoch).

#### Scenario: Valid message
- **WHEN** a message is received with `type`, `id`, and `ts` fields
- **THEN** the service SHALL process it according to its type

#### Scenario: Missing required fields
- **WHEN** a message is received without `type`, `id`, or `ts`
- **THEN** the receiver SHALL respond with an `error` message (code: `invalid_message`)

### Requirement: Phase 0 message types
The protocol SHALL support the following message types in Phase 0:

**Connection**: `gateway.register`, `gateway.registered`, `app.pair`, `app.paired`, `app.pair.error`, `app.connect`, `app.connected`

**Messaging**: `message.inbound`, `message.outbound`, `message.stream`

**Control**: `typing`, `presence`, `status.request`, `status.response`

**Errors**: `error`

#### Scenario: Unknown message type
- **WHEN** a message is received with an unrecognized `type`
- **THEN** the receiver SHALL ignore the message (forward compatibility)

### Requirement: Protocol version negotiation
Connection messages (`gateway.register`, `app.pair`, `app.connect`) SHALL include a `protocolVersion` field.

#### Scenario: Compatible version
- **WHEN** a connection message includes `protocolVersion: "0.1.0"` and the service supports `0.1.x`
- **THEN** the service SHALL accept the connection

#### Scenario: Incompatible version
- **WHEN** a connection message includes a `protocolVersion` the service does not support
- **THEN** the service SHALL respond with `error` (code: `incompatible_version`) including `supportedVersions` and close

### Requirement: Streaming message format
Streaming messages SHALL use `message.stream` type with `delta` (string), `phase` (enum: `streaming`, `done`, `error`), and share a consistent `id` across all deltas of one logical message.

#### Scenario: Stream a response
- **WHEN** a gateway streams a response
- **THEN** it SHALL send multiple `message.stream` frames with the same `id`, incrementing `ts`, `phase: "streaming"` for each delta, and a final frame with `phase: "done"` and optional `finalText`

### Requirement: Error message format
Error messages SHALL include `code` (string), `message` (human-readable string), and optional `requestId` (links to the request that caused the error).

#### Scenario: Error in response to a request
- **WHEN** an error occurs while processing a request message
- **THEN** the error response SHALL include `requestId` matching the original message's `id`

### Requirement: WebSocket keepalive
Both sides SHALL send WebSocket ping frames every 30 seconds. If no pong is received within 10 seconds, the connection SHALL be considered dead and closed.

#### Scenario: Keepalive timeout
- **WHEN** a WebSocket peer does not respond to a ping within 10 seconds
- **THEN** the connection SHALL be terminated and presence updated accordingly
