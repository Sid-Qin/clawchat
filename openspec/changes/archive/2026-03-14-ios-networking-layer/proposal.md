## Why

Phase 0 validated the relay protocol end-to-end (CLI → relay → bridge → OpenClaw gateway). The next step toward mobile apps is building the iOS networking and protocol layer — the foundation that all iOS UI will depend on. Building this as a standalone Swift package first lets us validate the protocol implementation, test against the live relay, and iterate on the API surface before committing to UI decisions.

## What Changes

- New Swift package `ios/ClawChatKit/` containing all networking, protocol, and state logic
- WebSocket connection manager with automatic reconnection (exponential backoff) and ping/pong keepalive
- Full ClawChat wire protocol implementation in Swift (Codable models matching `@clawchat/protocol`)
- Pairing flow: exchange 6-char code for device token, persist in Keychain
- Reconnection flow: use stored device token to resume session
- Message routing: send `message.inbound`, receive and decode `message.stream`, `message.reasoning`, `tool.event`
- Observable state layer (`@Observable`) exposing connection status, messages, typing indicators for future SwiftUI binding
- Relay service keepalive improvements (ping/pong, dead connection cleanup) — deferred from Phase 0

## Capabilities

### New Capabilities
- `ios-protocol-models`: Swift Codable types mirroring the TypeScript wire protocol (all message types, enums, content blocks)
- `ios-websocket-client`: URLSessionWebSocketTask-based connection with reconnection, keepalive, and message dispatch
- `ios-pairing`: Pairing code exchange, device token Keychain persistence, reconnection with stored credentials
- `ios-chat-state`: Observable chat state manager (messages, streams, typing, presence, connection status)

### Modified Capabilities
- `relay-service`: Add server-side WebSocket ping/pong keepalive and dead connection cleanup (deferred from Phase 0 tasks 8.2–8.3)

## Impact

- New directory: `ios/ClawChatKit/` (Swift Package)
- New directory: `ios/ClawChatKitTests/` (unit + integration tests)
- Modified: `service/src/` (keepalive improvements)
- Dependencies: Foundation, Network framework (no third-party deps)
- Test target: live relay at `wss://clawchat-production-db31.up.railway.app`
