# clawchat-openclaw

ClawChat channel plugin for [OpenClaw](https://github.com/openclaw/openclaw). Connects your OpenClaw agent to the ClawChat relay so iOS/Android apps can chat with it.

## Install

```bash
openclaw plugins install clawchat-openclaw
```

## Configure

In `~/.openclaw/openclaw.json` (or yaml):

```yaml
plugins:
  entries:
    clawchat:
      enabled: true
      config:
        token: <your-relay-gateway-token>
        relay: wss://clawchat-production-db31.up.railway.app   # optional
        session: clawchat                                        # optional
```

| Field | Required | Description |
|-------|----------|-------------|
| `token` | Yes | Gateway registration token. Keep secret. |
| `relay` | No | WebSocket URL of the ClawChat relay service. Defaults to the hosted relay. |
| `session` | No | OpenClaw session key for incoming messages. Defaults to `clawchat`. |

## Usage

After the plugin is configured and OpenClaw is running:

```
/clawchat pair
```

This generates a 6-character pairing code. Enter the code in the ClawChat iOS/Android app to connect.

## How it works

```
ClawChat App ──> ClawChat Relay <── OpenClaw Gateway (this plugin)
```

Both the app and the gateway connect **outbound** to the relay — no public IP or port forwarding needed.

## License

MIT
