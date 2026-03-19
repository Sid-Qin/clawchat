# ClawChat

First-party messaging apps for [OpenClaw](https://github.com/openclaw/openclaw). Talk to your AI agents from any device — no third-party chat platform required.

## How It Works

ClawChat follows the same outbound-only pattern as other OpenClaw channels (Telegram, Discord, Slack). Both your gateway and your phone connect **outbound** to a shared relay. No public IP or port forwarding needed.

```
Your Phone ──> ClawChat Relay <── Your OpenClaw Gateway (behind NAT)
```

## Installation

### 1. Install the plugin

```bash
# Build first
cd plugin && bun install && bun run build && cd ..

# Install into OpenClaw
openclaw plugins install ./plugin
```

Or copy directly to the user plugin directory:

```bash
cp -r plugin ~/.openclaw/extensions/clawchat
```

### 2. Configure

Add to `~/.openclaw/openclaw.yaml`:

```yaml
channels:
  clawchat:
    accounts:
      default:
        token: <your-relay-gateway-token>
        # Optional — defaults shown:
        # relay: wss://clawchat-production-db31.up.railway.app
        # session: clawchat
```

The `token` is your gateway registration token for the relay. Keep it secret.

### 3. Restart OpenClaw

The plugin starts automatically with the gateway. Check logs for:

```
[clawchat] Starting gateway accountId=default relay=wss://...
[clawchat] Registered. Paired devices: 0
```

### 4. Pair your phone

In any OpenClaw chat (webchat, Telegram, etc.), run:

```
/clawchat pair
```

This calls the relay and returns a 6-character pairing code and relay URL:

```
ClawChat Pairing Code

ABC-123

Relay: wss://clawchat-production-db31.up.railway.app
Expires: 14:32:00

Open ClawChat app → Settings → Pair Gateway,
enter the relay URL and code above.
```

Open the ClawChat iOS or Android app, go to **Settings → Pair Gateway**, enter the relay URL and code. Done.

## Project Structure

| Directory | Description |
|-----------|-------------|
| `plugin/` | OpenClaw channel plugin — installs into OpenClaw gateway |
| `ios/` | Native iOS app (SwiftUI, iOS 17+) |
| `android/` | Native Android app (Jetpack Compose, API 26+) |
| `service/` | ClawChat relay service (Bun) |
| `cli/` | CLI reference client |
| `packages/` | Shared protocol types (TypeScript) |
| `openspec/` | Architecture specs and wire protocol |

## Self-Hosting the Relay

```bash
cd service && bun install && bun dev
```

Then set `relay: ws://localhost:3000` in your plugin config.

## Features

- Streaming text with real-time token display
- Thinking / reasoning blocks (collapsible)
- Tool execution progress
- Approval dialogs
- No public IP required — gateway stays behind NAT
- Multi-gateway support
- Self-hostable relay

## License

MIT
