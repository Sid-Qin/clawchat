## 1. Gradle Module Setup

- [x] 1.1 Create `android/clawchat-kit/` Gradle module with `build.gradle.kts` (minSdk 26, kotlin-android, kotlinx-serialization)
- [x] 1.2 Add dependencies: OkHttp, kotlinx-serialization-json, AndroidX Security (EncryptedSharedPreferences)
- [x] 1.3 Add `.gitignore` for Android (`.gradle/`, `build/`, `local.properties`)
- [x] 1.4 Configure proguard-rules.pro for kotlinx-serialization keep rules

## 2. Protocol Models

- [x] 2.1 Define `BaseMessage` interface with `id`, `ts`, `type` properties
- [x] 2.2 Define connection types: `AppPair`, `AppPaired`, `AppPairError`, `AppConnect`, `AppConnected` as `@Serializable` data classes
- [x] 2.3 Define messaging types: `MessageInbound`, `MessageStream` (with `StreamPhase` enum), `MessageReasoning` (with `ReasoningPhase` enum)
- [x] 2.4 Define `ToolEvent` with `ToolPhase` enum (start/progress/result/error)
- [x] 2.5 Define control types: `Typing`, `Presence`, `StatusRequest`, `StatusResponse`
- [x] 2.6 Define `ErrorMessage` with `ClawChatErrorCode` enum (gateway_offline, unauthorized, etc. with UNKNOWN fallback)
- [x] 2.7 Define pairing types: `PairGenerate`, `PairCode`, `DevicesList`, `DevicesRevoke`
- [x] 2.8 Implement `ClawChatMessage` sealed class with `decode(json: String)` companion function using content-based polymorphic deserialization
- [x] 2.9 Define `PingMessage` and `PongMessage` data classes
- [x] 2.10 Add unit tests for encoding/decoding all message types (round-trip, unknown type handling)

## 3. WebSocket Client

- [x] 3.1 Create `WebSocketClient` class with OkHttp `WebSocket`
- [x] 3.2 Implement `connect(relayUrl)` with `/ws/app` path appending and URL normalization
- [x] 3.3 Implement message receive via OkHttp `WebSocketListener`, emitting `SharedFlow<ClawChatMessage>`
- [x] 3.4 Implement `send(message: BaseMessage)` with connected-state guard
- [x] 3.5 Implement automatic reconnection with exponential backoff (1s–60s) using coroutines
- [x] 3.6 Implement protocol-level ping keepalive (30s interval, 10s pong timeout)
- [x] 3.7 Expose `connectionState: StateFlow<ConnectionState>` enum (DISCONNECTED/CONNECTING/CONNECTED)
- [x] 3.8 Add unit tests for connection state transitions, URL normalization, and backoff logic

## 4. Pairing & Auth

- [x] 4.1 Implement `pair(code, deviceName)` suspend function (send app.pair, await app.paired/error)
- [x] 4.2 Implement `reconnect(deviceToken)` suspend function (send app.connect, await app.connected)
- [x] 4.3 Define `PairingException` sealed class (InvalidCode, CodeExpired, Unauthorized, NetworkError, Timeout)
- [x] 4.4 Create `CredentialStore` wrapper for EncryptedSharedPreferences (save/load/delete)
- [x] 4.5 Store `deviceToken`, `relayUrl`, `gatewayId` after successful pairing
- [x] 4.6 Load credentials on init, clear on unauthorized rejection
- [x] 4.7 Add unit tests for pairing flow (mock WebSocket responses)
- [x] 4.8 Add unit tests for credential store (save/load/delete cycle)

## 5. Chat State Manager

- [x] 5.1 Create `ChatMessage` data class (id, role, text, reasoning, toolEvents, isStreaming, isError, timestamp)
- [x] 5.2 Create `ChatStateManager` class exposing `state: StateFlow<ChatState>` with messages, connectionState, isTyping, gatewayOnline
- [x] 5.3 Implement stream delta accumulation (create message on first delta, append on subsequent, finalize on done)
- [x] 5.4 Implement reasoning block accumulation into current message
- [x] 5.5 Implement tool event tracking (add on start, update phase on progress/result/error)
- [x] 5.6 Implement `sendMessage(text)` — add user message + send message.inbound frame
- [x] 5.7 Implement typing indicator state from typing frames
- [x] 5.8 Implement gateway presence tracking from presence frames
- [x] 5.9 Wire ChatStateManager to WebSocketClient message flow (message dispatch coroutine)
- [x] 5.10 Add unit tests for stream accumulation, tool events, and typing state

## 6. Integration Testing

- [x] 6.1 Create test harness that connects to live relay with mock gateway
- [x] 6.2 Test full flow: pair → send message → receive stream → disconnect → reconnect
- [x] 6.3 Test error cases: invalid code, gateway offline, reconnect with bad token
