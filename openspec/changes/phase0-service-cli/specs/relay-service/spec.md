## ADDED Requirements

### Requirement: WebSocket server accepts gateway connections
The relay service SHALL expose a WebSocket endpoint at `/ws/gateway` that accepts connections from OpenClaw gateways.

#### Scenario: Gateway connects successfully
- **WHEN** a gateway opens a WebSocket to `/ws/gateway` and sends a `gateway.register` message with a valid token and gatewayId
- **THEN** the service SHALL store the gateway as online, respond with `gateway.registered`, and begin relaying messages to paired devices

#### Scenario: Gateway sends invalid token
- **WHEN** a gateway sends `gateway.register` with an unrecognized token
- **THEN** the service SHALL respond with an `error` message (code: `unauthorized`) and close the connection

#### Scenario: Gateway disconnects
- **WHEN** a registered gateway's WebSocket connection closes
- **THEN** the service SHALL mark the gateway as offline and send `presence` (status: `offline`) to all paired devices

### Requirement: WebSocket server accepts app connections
The relay service SHALL expose a WebSocket endpoint at `/ws/app` that accepts connections from client apps.

#### Scenario: App connects with device token
- **WHEN** an app opens a WebSocket to `/ws/app` and sends `app.connect` with a valid `deviceToken`
- **THEN** the service SHALL associate the connection with the paired gateway and respond with `app.connected` including gateway online status

#### Scenario: App connects with invalid device token
- **WHEN** an app sends `app.connect` with an unrecognized `deviceToken`
- **THEN** the service SHALL respond with an `error` message (code: `unauthorized`) and close the connection

### Requirement: Bidirectional message relay
The relay service SHALL forward messages between paired gateways and apps without inspecting or modifying message content.

#### Scenario: App sends message to gateway
- **WHEN** a paired app sends a `message.inbound` message
- **THEN** the service SHALL forward the message to the paired gateway's WebSocket connection

#### Scenario: Gateway sends message to app
- **WHEN** a gateway sends a `message.outbound` or `message.stream` message
- **THEN** the service SHALL forward the message to all paired app connections for that gateway

#### Scenario: Gateway is offline when app sends message
- **WHEN** a paired app sends a message but the gateway is not connected
- **THEN** the service SHALL respond with an `error` message (code: `gateway_offline`)

### Requirement: Presence tracking
The relay service SHALL track and broadcast presence status for gateways.

#### Scenario: Gateway comes online
- **WHEN** a gateway successfully registers
- **THEN** the service SHALL send `presence` (status: `online`) to all paired app connections

#### Scenario: App queries gateway status
- **WHEN** an app sends `status.request`
- **THEN** the service SHALL respond with `status.response` including gateway online/offline status

### Requirement: HTTP health check
The relay service SHALL expose `GET /health` returning HTTP 200 with service status.

#### Scenario: Health check
- **WHEN** an HTTP GET request is made to `/health`
- **THEN** the service SHALL respond with `200 OK` and a JSON body including `{ "status": "ok", "connections": { "gateways": N, "apps": N } }`

### Requirement: Typing indicator relay
The relay service SHALL forward typing indicators bidirectionally.

#### Scenario: Gateway sends typing indicator
- **WHEN** a gateway sends a `typing` message
- **THEN** the service SHALL forward it to all paired app connections

#### Scenario: App sends typing indicator
- **WHEN** an app sends a `typing` message
- **THEN** the service SHALL forward it to the paired gateway
