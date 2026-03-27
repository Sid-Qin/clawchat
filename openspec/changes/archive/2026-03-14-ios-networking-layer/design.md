## Context

Phase 0 delivered a working relay service and CLI client in TypeScript/Bun. The iOS networking layer must implement the same wire protocol in Swift, connecting to the same relay. The CLI client (`cli/src/`) and protocol types (`packages/protocol/src/`) serve as the reference implementation.

The gateway bridge (`scripts/openclaw-bridge.ts`) proved the full message flow: app → relay → bridge → OpenClaw gateway → streaming response back. iOS needs to replicate what the CLI does on the app side.

## Goals / Non-Goals

**Goals:**
- Swift Package (`ClawChatKit`) with zero third-party dependencies — Foundation + URLSession only
- Complete wire protocol coverage matching `@clawchat/protocol` types
- WebSocket connection with automatic reconnection and keepalive
- Pairing + reconnection flows with Keychain persistence
- Observable state layer ready for SwiftUI binding (`@Observable`)
- Testable against the live Railway relay with mock gateway

**Non-Goals:**
- No UI code in this phase (SwiftUI views come later)
- No push notification registration (requires app target + APNs setup)
- No E2EE or message persistence (Phase 4)
- No media upload/download (text-only for now)
- No Canvas/A2UI rendering

## Decisions

### 1. URLSessionWebSocketTask over raw NWConnection

**Choice**: Use `URLSession.webSocketTask(with:)` for WebSocket.

**Why**: Higher-level API, handles TLS/proxy/HTTP upgrade automatically, works on all Apple platforms. NWConnection gives more control but adds complexity we don't need. Third-party libs (Starscream, etc.) add dependency risk for no gain.

**Trade-off**: Slightly less control over ping/pong frames — URLSession handles WebSocket pings internally but we'll add protocol-level pings (JSON `{"type":"ping"}`) matching the relay's expected format.

### 2. Swift Package (not embedded in app target)

**Choice**: Standalone Swift Package at `ios/ClawChatKit/`.

**Why**: Decouples networking from UI, enables unit testing without app target, shareable across iOS/macOS targets later. The package exposes `@Observable` types that SwiftUI views will bind to.

### 3. Codable models with manual CodingKeys

**Choice**: Swift `Codable` structs with string-typed `type` discriminator, decoded via a custom `ClawChatMessage` enum with `init(from:)`.

**Why**: The wire protocol uses `{"type": "message.stream", ...}` discriminated unions. Swift's Codable doesn't support this natively, so we decode the `type` field first, then decode the specific message struct. This mirrors how `parseMessage()` works in the TypeScript protocol package.

**Alternative considered**: Protocol buffers or MessagePack — rejected because the relay uses JSON and we want zero additional dependencies.

### 4. Keychain for device token storage

**Choice**: Store `deviceToken`, `relayUrl`, and `deviceName` in Keychain via Security framework.

**Why**: Device tokens are long-lived auth credentials. UserDefaults is plaintext and not secure. Keychain persists across app reinstalls and is encrypted at rest.

### 5. @Observable state layer (not Combine)

**Choice**: Use Swift 5.9 `@Observable` macro for the `ChatState` manager.

**Why**: Per project guidelines, prefer Observation framework over ObservableObject/Combine. SwiftUI views will use `@State` or `@Environment` to bind directly. Simpler, less boilerplate, better performance with fine-grained tracking.

### 6. Actor-based concurrency for WebSocket

**Choice**: The WebSocket client uses a Swift actor to serialize connection state mutations.

**Why**: WebSocket events arrive on URLSession delegate queues. An actor ensures thread-safe state without manual locking. The public API is async/await.

## Risks / Trade-offs

- **URLSession WebSocket reconnection** — URLSessionWebSocketTask cannot be reused after close; must create a new task each time. Mitigation: the connection manager creates fresh tasks on reconnect.
- **JSON decoding performance** — Streaming responses send many small frames. Mitigation: use `JSONDecoder` with pre-allocated buffers; profile if needed. For Phase 2 this is unlikely to be a bottleneck.
- **Keychain API complexity** — Security framework is C-based and error-prone. Mitigation: thin wrapper with clear error handling; unit tests with test Keychain access group.
- **Relay keepalive gap** — Relay doesn't yet implement server-side ping/pong (Phase 0 deferred). Mitigation: client sends protocol-level pings; relay improvement included in this change's scope.

## Open Questions

- Should `ClawChatKit` support macOS from day one, or iOS-only initially? (Leaning: support both since URLSession is cross-platform and we'll want a macOS test harness)
