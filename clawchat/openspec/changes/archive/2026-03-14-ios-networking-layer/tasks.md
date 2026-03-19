## 1. Swift Package Setup

- [x] 1.1 Create `ios/ClawChatKit/` Swift Package with `Package.swift` (platforms: iOS 17+, macOS 14+)
- [x] 1.2 Add `ClawChatKit` library target and `ClawChatKitTests` test target
- [x] 1.3 Add `.gitignore` for Swift (`.build/`, `.swiftpm/`, `xcuserdata/`)

## 2. Protocol Models

- [x] 2.1 Define `BaseMessage` protocol with `id`, `ts`, `type` properties
- [x] 2.2 Define connection types: `AppPair`, `AppPaired`, `AppPairError`, `AppConnect`, `AppConnected`
- [x] 2.3 Define messaging types: `MessageInbound`, `MessageStream` (with `StreamPhase` enum), `MessageReasoning`
- [x] 2.4 Define `ToolEvent` with `ToolPhase` enum (start/progress/result/error)
- [x] 2.5 Define control types: `Typing`, `Presence`, `StatusRequest`, `StatusResponse`
- [x] 2.6 Define `ErrorMessage` with `ClawChatErrorCode` enum (gateway_offline, unauthorized, etc.)
- [x] 2.7 Define pairing types: `PairGenerate`, `PairCode`, `DevicesList`, `DevicesRevoke`
- [x] 2.8 Implement `ClawChatMessage` enum with `init(from: Decoder)` discriminated union decoding
- [x] 2.9 Add unit tests for encoding/decoding all message types (round-trip, unknown type handling)

## 3. WebSocket Client

- [x] 3.1 Create `WebSocketClient` actor with `URLSessionWebSocketTask`
- [x] 3.2 Implement `connect(relayUrl:)` with `/ws/app` path appending
- [x] 3.3 Implement message receive loop emitting `AsyncStream<ClawChatMessage>`
- [x] 3.4 Implement `send(_ message: Encodable)` with connected-state guard
- [x] 3.5 Implement automatic reconnection with exponential backoff (1s–60s)
- [x] 3.6 Implement protocol-level ping keepalive (30s interval, 10s pong timeout)
- [x] 3.7 Expose `connectionState` as `ConnectionState` enum (.disconnected/.connecting/.connected)
- [x] 3.8 Add unit tests for connection state transitions and backoff logic

## 4. Pairing & Auth

- [x] 4.1 Implement `pair(code:deviceName:)` async function (send app.pair, await app.paired/error)
- [x] 4.2 Implement `reconnect(deviceToken:)` async function (send app.connect, await app.connected)
- [x] 4.3 Define `PairingError` enum (invalidCode, codeExpired, unauthorized, networkError)
- [x] 4.4 Create `KeychainStore` wrapper for Security framework (save/load/delete)
- [x] 4.5 Store `deviceToken`, `relayUrl`, `gatewayId` in Keychain after successful pairing
- [x] 4.6 Load credentials from Keychain on init, clear on unauthorized rejection
- [x] 4.7 Add unit tests for pairing flow (mock WebSocket responses)
- [x] 4.8 Add unit tests for Keychain store (save/load/delete cycle)

## 5. Chat State Manager

- [x] 5.1 Create `ChatMessage` model (id, role, text, reasoning, toolEvents, isStreaming, isError, timestamp)
- [x] 5.2 Create `ChatState` @Observable class with messages, connectionState, isTyping, gatewayOnline
- [x] 5.3 Implement stream delta accumulation (create message on first delta, append on subsequent, finalize on done)
- [x] 5.4 Implement reasoning block accumulation into current message
- [x] 5.5 Implement tool event tracking (add on start, update phase on progress/result/error)
- [x] 5.6 Implement `sendMessage(text:)` — append user message + send message.inbound frame
- [x] 5.7 Implement typing indicator state from typing frames
- [x] 5.8 Implement gateway presence tracking from presence frames
- [x] 5.9 Wire ChatState to WebSocketClient message stream (message dispatch loop)
- [x] 5.10 Add unit tests for stream accumulation, tool events, and typing state

## 6. Relay Service Keepalive (server-side)

- [x] 6.1 Add WebSocket ping/pong keepalive to relay (30s ping interval, 10s timeout)
- [x] 6.2 Close dead connections on pong timeout, trigger presence cleanup
- [x] 6.3 Add periodic expired pairing code cleanup (every 60s)
- [x] 6.4 Add integration tests for keepalive and cleanup behavior

## 7. Integration Testing

- [x] 7.1 Create test harness that connects to live relay with mock gateway
- [x] 7.2 Test full flow: pair → send message → receive stream → disconnect → reconnect
- [x] 7.3 Test error cases: invalid code, expired code, gateway offline, reconnect with bad token
