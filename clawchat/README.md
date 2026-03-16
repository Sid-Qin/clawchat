# ClawChat

First-party messaging apps for [OpenClaw](https://github.com/openclaw/openclaw). Talk to your AI agents from any device -- no third-party chat platform required.

## How It Works

ClawChat follows the same pattern as existing OpenClaw channels (Telegram, Discord, Slack): your gateway connects **outbound** to a relay service. Your phone also connects **outbound** to the same relay. No public IP or port forwarding needed.

```
Your Phone ──> ClawChat Relay <── Your OpenClaw Gateway (behind NAT)
```

## Features

- **Full OpenClaw capability surface** -- streaming text, reasoning blocks, tool visualization, approval flows, canvas/A2UI, polls, reactions, threads
- **No public IP required** -- gateway stays behind NAT, just like with Telegram/Discord
- **Native mobile apps** -- iOS (SwiftUI) + Android (Jetpack Compose)
- **Push notifications** -- get notified when your agent needs attention
- **Multi-gateway** -- connect to multiple OpenClaw instances from one app
- **Self-hostable relay** -- run your own relay if you prefer

## Project Structure

| Directory | Description |
|-----------|-------------|
| `frontend/` | React Native (Expo) mobile app — Discord-style UI for agent chat |
| `ios/` | Native iOS client (SwiftUI) |
| `android/` | Native Android client (Jetpack Compose) |
| `service/` | Relay service backend |
| `cli/` | Command-line interface |
| `packages/protocol/` | Shared protocol definitions |
| `openspec/` | Architecture specifications |

## Status

Early development. See [architecture specs](openspec/specs/architecture/) for the design.

The `frontend/` directory contains a working React Native prototype with full UI implementation. See [frontend/README.md](frontend/README.md) for setup instructions.

## License

MIT
