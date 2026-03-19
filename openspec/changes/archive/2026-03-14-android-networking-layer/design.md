## Context

The iOS networking layer (`ClawChatKit`) proved the architecture: actor-based WebSocket client, Codable protocol models, Keychain persistence, and @Observable state manager. The Android layer mirrors this design in idiomatic Kotlin, using platform-native equivalents.

The relay protocol is identical — the Android client connects to the same relay at `/ws/app` and exchanges the same JSON wire protocol messages.

## Goals / Non-Goals

**Goals:**
- Kotlin library module (`clawchat-kit`) usable from any Android app target
- Complete wire protocol coverage matching `@clawchat/protocol` and the iOS implementation
- WebSocket connection with automatic reconnection and keepalive
- Pairing + reconnection flows with encrypted credential persistence
- StateFlow-based state layer ready for Jetpack Compose binding
- Testable against the live Railway relay with mock gateway

**Non-Goals:**
- No UI code in this phase (Compose views come later)
- No push notification registration (requires FCM setup)
- No E2EE or message persistence
- No media upload/download (text-only)

## Decisions

### 1. OkHttp WebSocket over java.net or Ktor

**Choice**: Use OkHttp's `WebSocket` API.

**Why**: OkHttp is the de-facto Android HTTP client. Its WebSocket implementation handles TLS, reconnection callbacks, ping/pong at the transport level, and is well-tested at scale. Ktor would add a heavier dependency for no added value. Raw `java.net.HttpURLConnection` doesn't support WebSocket.

**Trade-off**: Adds OkHttp as a dependency (~2MB). This is acceptable as virtually all Android apps already include it.

### 2. Kotlin library module (not embedded in app)

**Choice**: Standalone Gradle module at `android/clawchat-kit/`.

**Why**: Mirrors the iOS approach — decouples networking from UI, enables unit testing without Android instrumentation, shareable across app variants. Publishes a clean API surface.

### 3. kotlinx.serialization over Gson/Moshi

**Choice**: Use `kotlinx.serialization` with `@Serializable` data classes and `Json` decoder.

**Why**: First-party Kotlin solution, compile-time safe (no reflection), supports sealed class polymorphism for the discriminated union pattern. Smaller runtime than Gson. The `type` discriminator in wire protocol maps naturally to `@SerialName` on sealed class subtypes.

**Alternative considered**: Moshi — good but requires kapt/KSP for codegen. kotlinx.serialization integrates with Kotlin compiler directly.

### 4. EncryptedSharedPreferences for credential storage

**Choice**: Store `deviceToken`, `relayUrl`, and `gatewayId` in AndroidX `EncryptedSharedPreferences`.

**Why**: Device tokens are long-lived auth credentials. Regular SharedPreferences stores plaintext on disk. EncryptedSharedPreferences uses AES-256 with Android Keystore master key. Persists across app updates (not uninstalls, unlike iOS Keychain).

### 5. StateFlow + coroutines for state management

**Choice**: Use `StateFlow<ChatState>` exposed from a `ChatStateManager` class.

**Why**: Kotlin coroutines + Flow is the standard Android reactive pattern. `StateFlow` provides hot, replay-1 state that Compose `collectAsState()` observes efficiently. Mirrors the iOS `@Observable` pattern.

### 6. Coroutine-based concurrency

**Choice**: Use `CoroutineScope` with `Dispatchers.IO` for WebSocket operations, `Dispatchers.Main` for state updates.

**Why**: Kotlin coroutines provide structured concurrency equivalent to Swift's actor isolation. A `Mutex` or single-threaded dispatcher serializes connection state mutations.

## Risks / Trade-offs

- **OkHttp WebSocket reconnection** — OkHttp doesn't auto-reconnect. Mitigation: custom reconnection loop with exponential backoff, same pattern as iOS.
- **EncryptedSharedPreferences on older devices** — Requires Android 6.0+ (API 23) for Keystore. Our min SDK 26 covers this.
- **kotlinx.serialization sealed class decoding** — Requires `classDiscriminator` config for `type` field. Mitigation: use content-based polymorphic deserialization with custom serializer.
- **Proguard/R8** — kotlinx.serialization requires keep rules. Mitigation: include proguard-rules.pro in the library module.

## Open Questions

- Should we use Android Keystore directly instead of EncryptedSharedPreferences for maximum security parity with iOS Keychain? (Leaning: EncryptedSharedPreferences is sufficient and simpler)
