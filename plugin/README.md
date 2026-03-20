# clawchat-openclaw

ClawChat channel plugin for [OpenClaw](https://github.com/openclaw/openclaw). Connects your OpenClaw agent to the ClawChat relay so iOS/Android apps can chat with it.

## Install

```bash
npx clawchat-openclaw install
```

This single command will:
1. Generate a gateway token
2. Configure `~/.openclaw/openclaw.json`
3. Install the plugin
4. Display a **QR code** for pairing with the ClawChat app

After scanning, restart the gateway:

```bash
openclaw gateway restart
```

## Pair a New Device

```bash
npx clawchat-openclaw pair
```

Or use the chat command after gateway is running:

```
/clawchat pair
```

## How it works

```
ClawChat App ──> ClawChat Relay <── OpenClaw Gateway (this plugin)
```

Both the app and the gateway connect **outbound** to the relay — no public IP or port forwarding needed.

## License

MIT
