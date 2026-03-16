## 1. Project Setup

- [ ] 1.1 Initialize Bun workspace root (`package.json` with `workspaces`)
- [ ] 1.2 Create `packages/protocol/` with TypeScript config and package.json
- [ ] 1.3 Create `service/` with Bun + Hono + bun:sqlite dependencies
- [ ] 1.4 Create `cli/` with Bun dependencies
- [ ] 1.5 Add shared tsconfig base and configure workspace references
- [ ] 1.6 Add placeholder directories for `ios/` and `android/` with `.gitkeep`

## 2. Protocol Types (`packages/protocol/`)

- [ ] 2.1 Define message envelope type (`BaseMessage`: type, id, ts)
- [ ] 2.2 Define connection message types (`gateway.register`, `gateway.registered`, `app.pair`, `app.paired`, `app.pair.error`, `app.connect`, `app.connected`)
- [ ] 2.3 Define messaging types (`message.inbound`, `message.outbound`, `message.stream`)
- [ ] 2.4 Define control message types (`typing`, `presence`, `status.request`, `status.response`)
- [ ] 2.5 Define error message type and error codes
- [ ] 2.6 Define pairing-specific types (`pair.generate`, `pair.code`, `devices.list`, `devices.revoke`)
- [ ] 2.7 Define `message.reasoning` and `tool.event` types
- [ ] 2.8 Export all types and add type guards / validation helpers

## 3. Relay Service — Database Layer (`service/`)

- [ ] 3.1 Set up SQLite schema: `gateways` table (gatewayId, token, createdAt)
- [ ] 3.2 Set up SQLite schema: `devices` table (deviceId, deviceToken, deviceName, platform, gatewayId, lastSeen, createdAt)
- [ ] 3.3 Set up SQLite schema: `pairing_codes` table (code, gatewayId, expiresAt, redeemed)
- [ ] 3.4 Implement store interface with CRUD operations for all tables
- [ ] 3.5 Add TTL cleanup for expired pairing codes (periodic or on-read)

## 4. Relay Service — WebSocket Gateway Endpoint

- [ ] 4.1 Create Bun WebSocket server with Hono HTTP routing
- [ ] 4.2 Implement `/ws/gateway` endpoint: accept connection, await `gateway.register`
- [ ] 4.3 Validate gateway token against database, respond with `gateway.registered`
- [ ] 4.4 Track active gateway connections in memory (Map<gatewayId, WebSocket>)
- [ ] 4.5 Handle gateway disconnect: mark offline, notify paired apps with `presence` update
- [ ] 4.6 Implement protocol version check on `gateway.register`

## 5. Relay Service — WebSocket App Endpoint

- [ ] 5.1 Implement `/ws/app` endpoint: accept connection, await `app.pair` or `app.connect`
- [ ] 5.2 Handle `app.connect`: validate device token, associate with gateway, respond `app.connected`
- [ ] 5.3 Handle `app.pair`: validate pairing code, create device, respond `app.paired`
- [ ] 5.4 Track active app connections in memory (Map<deviceId, WebSocket>)
- [ ] 5.5 Handle app disconnect: update lastSeen, send presence if needed

## 6. Relay Service — Message Routing

- [ ] 6.1 Forward `message.inbound` from app → matched gateway
- [ ] 6.2 Forward `message.outbound` from gateway → all paired online apps
- [ ] 6.3 Forward `message.stream` from gateway → all paired online apps
- [ ] 6.4 Forward `message.reasoning` from gateway → all paired online apps
- [ ] 6.5 Forward `tool.event` from gateway → all paired online apps
- [ ] 6.6 Forward `typing` indicators bidirectionally
- [ ] 6.7 Handle `status.request` from app: respond with gateway status
- [ ] 6.8 Return `error` (gateway_offline) when app sends message to offline gateway

## 7. Relay Service — Pairing API

- [ ] 7.1 Implement `pair.generate` (WebSocket): generate 6-char code, store with 5min TTL, respond `pair.code`
- [ ] 7.2 Implement `POST /api/pair/code` (HTTP): same logic as 7.1 but over HTTP with gateway token auth
- [ ] 7.3 Implement `devices.list`: return all paired devices for a gateway
- [ ] 7.4 Implement `devices.revoke`: delete device, invalidate token, close active connection
- [ ] 7.5 Implement pairing code character set (30 chars, no ambiguous: 0/O/1/I/L excluded)

## 8. Relay Service — Health & Keepalive

- [ ] 8.1 Implement `GET /health` endpoint returning connection counts
- [ ] 8.2 Implement WebSocket ping/pong keepalive (30s interval, 10s timeout)
- [ ] 8.3 Close dead connections on keepalive timeout, update presence

## 9. CLI Client — Connection

- [ ] 9.1 Set up CLI entry point with argument parsing (`--relay`, `--code`, `--agent`)
- [ ] 9.2 Implement config file read/write (`~/.clawchat/config.json`)
- [ ] 9.3 Implement first-time pairing flow: prompt for code, send `app.pair`, store device token
- [ ] 9.4 Implement reconnection with stored device token (`app.connect`)
- [ ] 9.5 Implement exponential backoff reconnection on connection drop

## 10. CLI Client — Chat Interface

- [ ] 10.1 Implement interactive input prompt (readline)
- [ ] 10.2 Send user input as `message.inbound` to relay
- [ ] 10.3 Render `message.outbound` text responses (with basic markdown)
- [ ] 10.4 Render `message.stream` deltas as real-time typing output
- [ ] 10.5 Render `message.reasoning` blocks in dimmed/gray style
- [ ] 10.6 Render `tool.event` as colored status blocks (start → result)
- [ ] 10.7 Display typing indicator (spinner) on `typing` messages
- [ ] 10.8 Handle Ctrl+C for graceful disconnect

## 11. Testing & Validation

- [ ] 11.1 Add unit tests for protocol type guards and validation helpers
- [ ] 11.2 Add unit tests for pairing code generation (character set, uniqueness)
- [ ] 11.3 Add integration test: gateway register → app pair → send message → receive response
- [ ] 11.4 Add integration test: gateway disconnect → app receives offline presence
- [ ] 11.5 Add integration test: expired pairing code rejection
- [ ] 11.6 Manual end-to-end test: CLI ↔ relay ↔ (mock gateway) full chat loop
