## Why

The iOS networking layer (ClawChatKit) is complete — protocol models, WebSocket client, pairing, and chat state manager are tested and working against the live relay. Android needs the same foundation: a Kotlin library implementing the ClawChat wire protocol so that the Android app can pair, send messages, and receive streaming responses through the relay.

## What Changes

- New Kotlin library module `android/clawchat-kit/` containing all networking, protocol, and state logic
- WebSocket connection using OkHttp with automatic reconnection (exponential backoff) and ping/pong keepalive
- Full ClawChat wire protocol in Kotlin (kotlinx.serialization models matching `@clawchat/protocol`)
- Pairing flow: exchange 6-char code for device token, persist in EncryptedSharedPreferences
- Reconnection flow: use stored device token to resume session
- Message routing: send `message.inbound`, receive and decode `message.stream`, `message.reasoning`, `tool.event`
- StateFlow-based state layer exposing connection status, messages, typing indicators for Compose UI binding
- Unit and integration tests mirroring the iOS test suite

## Capabilities

### New Capabilities
- `android-protocol-models`: Kotlin serializable data classes mirroring the TypeScript wire protocol (all message types, enums, content blocks)
- `android-websocket-client`: OkHttp WebSocket-based connection with reconnection, keepalive, and message dispatch
- `android-pairing`: Pairing code exchange, device token EncryptedSharedPreferences persistence, reconnection with stored credentials
- `android-chat-state`: StateFlow-based chat state manager (messages, streams, typing, presence, connection status)

### Modified Capabilities
(none — relay keepalive was already added in the iOS networking layer change)

## Impact

- New directory: `android/clawchat-kit/` (Kotlin library module)
- Dependencies: OkHttp (WebSocket), kotlinx.serialization (JSON), AndroidX Security (EncryptedSharedPreferences)
- Min SDK: Android API 26 (Android 8.0)
- Test target: live relay at `wss://clawchat-production-db31.up.railway.app`
