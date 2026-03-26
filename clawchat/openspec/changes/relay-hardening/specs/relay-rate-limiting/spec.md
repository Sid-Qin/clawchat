## ADDED Requirements

### Requirement: WebSocket message rate limiting
The relay SHALL enforce per-device and per-gateway message rate limits using an in-memory sliding window. Exceeding the limit SHALL result in a `rate_limited` error message and the offending message SHALL be dropped.

#### Scenario: App exceeds message rate
- **WHEN** an app device sends more than 60 messages within a 60-second window
- **THEN** the relay SHALL respond with an error message `{"type":"error","code":"rate_limited"}` and drop the message

#### Scenario: Gateway exceeds message rate
- **WHEN** a gateway sends more than 200 messages within a 60-second window
- **THEN** the relay SHALL respond with an error message `{"type":"error","code":"rate_limited"}` and drop the message

#### Scenario: Rate limit resets after window
- **WHEN** the 60-second sliding window elapses
- **THEN** the message counter SHALL reset and new messages SHALL be accepted

### Requirement: HTTP API rate limiting
The relay SHALL enforce per-IP rate limits on HTTP endpoints.

#### Scenario: HTTP rate limit exceeded
- **WHEN** an IP sends more than 30 HTTP requests within a 60-second window
- **THEN** the relay SHALL respond with HTTP 429 Too Many Requests

### Requirement: Pairing code generation rate limiting
The relay SHALL limit pairing code generation to prevent abuse.

#### Scenario: Too many pairing codes
- **WHEN** a gateway requests more than 5 pairing codes within a 60-second window
- **THEN** the relay SHALL respond with an error message `{"type":"error","code":"rate_limited"}`

### Requirement: WebSocket connection rate limiting
The relay SHALL limit the rate of new WebSocket connections per IP.

#### Scenario: Connection rate exceeded
- **WHEN** an IP attempts more than 10 WebSocket connections within a 60-second window
- **THEN** the relay SHALL reject the WebSocket upgrade with HTTP 429

### Requirement: Connection limits
The relay SHALL enforce maximum concurrent connection counts.

#### Scenario: Max app connections per gateway
- **WHEN** a gateway already has 5 connected app devices and a 6th attempts to connect
- **THEN** the relay SHALL reject with an error `{"type":"error","code":"connection_limit"}`

#### Scenario: Max connections per IP
- **WHEN** an IP already has 20 active WebSocket connections and another is attempted
- **THEN** the relay SHALL reject the WebSocket upgrade with HTTP 429

#### Scenario: Max paired devices per gateway
- **WHEN** a gateway already has 10 paired devices and a new pairing is attempted
- **THEN** the relay SHALL respond with `app.pair.error` code `device_limit`
