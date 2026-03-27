# ClawChat

First-party messaging service for the OpenClaw ecosystem.

## Project Structure

```
clawchat/
├── openspec/specs/architecture/   # Architecture specs & wire protocol
├── service/                       # ClawChat relay service (Node.js/Bun)
├── plugin/                        # OpenClaw plugin (@claw-os/clawchat on npm)
├── ios/                           # iOS app (SwiftUI)
├── android/                       # Android app (Jetpack Compose)
└── packages/protocol/             # Shared protocol types (TypeScript)
```

## Architecture

Three components, all connecting outbound (no public IP needed for gateway):

```
Client App ──> ClawChat Service (relay) <── OpenClaw Gateway
```

- **ClawChat Service**: Lightweight WebSocket relay. Routes messages between paired gateways and apps.
- **Channel Plugin**: [`@claw-os/clawchat`](https://www.npmjs.com/package/@claw-os/clawchat) on npm. Standard channel plugin.
- **Client Apps**: iOS, Android, CLI. Any app implementing the wire protocol can connect.

## Plugin Usage

### Install

```bash
npx @claw-os/clawchat install
```

Or manually:

```bash
openclaw plugins install @claw-os/clawchat
```

This single command will:
1. Generate a gateway token
2. Configure `~/.openclaw/openclaw.json`
3. Install the plugin
4. Restart the gateway
5. Display a **QR code** for pairing with the ClawOS app

### Pair a New Device

```bash
npx @claw-os/clawchat pair
```

Or use the chat command after gateway is running: `/clawchat pair`

## Specs

- System architecture: `openspec/specs/architecture/system-architecture.md`
- Wire protocol: `openspec/specs/architecture/wire-protocol.md`
- Capability matrix: `openspec/specs/architecture/capability-matrix.md`

## Related OpenClaw Issues

- openclaw/openclaw#40476 - Mobile App API & SDK
- openclaw/openclaw#24754 - Native E2EE Browser Chat
- openclaw/openclaw#19977 - Local-first Control UI with built-in chat
- openclaw/openclaw#22590 - Mobile Web UI
- openclaw/openclaw#41130 - Streaming support for webchat
- openclaw/openclaw#8000 - Agora relay pattern
- openclaw/openclaw#44406 - Claw Messenger relay pattern

## Development

### iOS
- SwiftUI, minimum iOS 17
- Xcode project in `ios/`

### Android
- Jetpack Compose, minimum API 26
- Gradle project in `android/`

### Service
- Bun / Node.js
- `cd service && bun install && bun dev`

### Plugin
- `cd plugin && npm publish --access public`
