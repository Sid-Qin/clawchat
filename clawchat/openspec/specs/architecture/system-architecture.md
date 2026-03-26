# System Architecture

## Three Components

ClawChat consists of three independent components that communicate via WebSocket:

```
┌──────────────┐          ┌─────────────────┐          ┌──────────────┐
│  Client App  │──outbound──>│  ClawChat       │<──outbound──│   OpenClaw    │
│  (any platform)│          │  Service        │          │   Gateway    │
└──────────────┘          └─────────────────┘          └──────────────┘
     iOS / Android            Message relay              Behind NAT
     Web / Desktop            + presence                 No public IP
     CLI                      + push notify
```

All connections are outbound. Neither the gateway nor the client app needs a public IP.

---

## 1. ClawChat Service (Relay)

The cloud relay service. Analogous to Telegram Bot API or Discord Gateway -- it's the "platform" that both sides connect to.

### Responsibilities

- Accept WebSocket connections from gateways (authenticated by gateway token)
- Accept WebSocket connections from client apps (authenticated by pairing code / QR)
- Route messages between matched gateway-app pairs
- Track presence (online/offline/typing indicators)
- Forward push notifications to mobile devices (APNs/FCM)
- Maintain pairing registry (which apps are paired to which gateways)

### Non-responsibilities (gateway owns these)

- Does NOT store conversation history
- Does NOT run AI inference
- Does NOT manage agents or sessions
- Does NOT process or inspect message content (relay only)

### Auth Model

- **Gateway registration**: Token is auto-generated (UUID) during `npx @claw-os/clawchat install` and saved to config. Gateway connects to relay with this token.
- **App pairing**: Pairing code is generated on-demand (not in background) via two methods:
  - `npx @claw-os/clawchat install` — automatically after installation
  - `npx @claw-os/clawchat pair` or `/clawchat pair` — manual trigger
  - Code is a 6-character alphanumeric string, expires after 5 minutes
  - QR code encodes a deep link: `clawchat://pair?relay={url}&code={code}`
- **Session persistence**: Once paired, app reconnects automatically using a device token (long-lived, revocable)

### Deployment Options

- **Hosted**: ClawChat team runs the default service (e.g. `relay.clawchat.io`)
- **Self-hosted**: Users can run their own relay (single binary / Docker image)
- **Config**: Set `relay` in `plugins.entries.clawchat.config.relay` in openclaw.json

### Technology Choices

- Runtime: Bun or Node.js (consistent with OpenClaw ecosystem)
- Transport: WebSocket (JSON frames)
- Persistence: Redis or SQLite for pairing registry + push tokens
- Push: APNs (iOS) + FCM (Android) via provider SDKs
- Deployment: Cloudflare Workers / Fly.io / single VPS

---

## 2. Channel Plugin (Gateway Side)

An independent OpenClaw channel plugin published as [`@claw-os/clawchat`](https://www.npmjs.com/package/@claw-os/clawchat) on npm. Plugin id in openclaw.json is `clawchat`.

### Installation

One-command setup via npx:

```bash
npx @claw-os/clawchat install
```

This automatically:
1. Generates a gateway token (UUID, persisted to config)
2. Writes plugin config to `~/.openclaw/openclaw.json`
3. Installs the plugin to `~/.openclaw/extensions/clawchat/`
4. Restarts the gateway
5. Requests a pairing code and displays a QR code in terminal

### Plugin Structure

```
plugin/
├── package.json
├── openclaw.plugin.json    # Plugin manifest (id: clawchat)
├── bin/
│   └── clawchat.mjs        # CLI installer & pairing tool
├── src/
│   ├── index.ts             # Plugin entry (register service + /clawchat command)
│   ├── gateway.ts           # WebSocket connection to relay
│   ├── pair.ts              # Pairing code request via relay API
│   ├── qr.ts                # QR code terminal display
│   ├── runtime.ts           # Runtime reference holder
│   └── types.ts             # ClawChatAccount type
└── tsconfig.json
```

### Gateway Identity

The `gatewayId` is derived from the gateway token, not hardcoded:

```typescript
const gatewayId = `gw-${crypto.createHash("sha256").update(gatewayToken).digest("hex").slice(0, 12)}`;
```

Each user's token is unique (auto-generated UUID), so gatewayId is unique per installation.

### Capabilities (ALL enabled)

```typescript
capabilities: {
  chatTypes: ["direct", "group", "thread"],
  polls: true,
  reactions: true,
  edit: true,
  unsend: true,
  reply: true,
  effects: true,
  threads: true,
  media: true,
  nativeCommands: true,
}
```

This is the reference channel -- it declares support for every capability OpenClaw offers.

### Gateway Lifecycle

```typescript
gateway: {
  startAccount: async (ctx) => {
    // 1. Read relay URL + token from config
    // 2. Connect WebSocket to relay service
    // 3. Send gateway.register message
    // 4. Listen for inbound messages from paired apps
    // 5. Dispatch to OpenClaw agent via ctx.channelRuntime
  },
  stopAccount: async (ctx) => {
    // Graceful WebSocket close
  },
}
```

### Outbound Delivery

Unlike other channels that coalesce streaming blocks, ClawChat forwards events at full fidelity:

- **Text**: Markdown, sent as-is (app renders natively)
- **Streaming**: Token-level deltas (no coalescing)
- **Reasoning**: Separate reasoning blocks with phase indicators
- **Tool events**: Start/progress/result/error events with full context
- **Media**: URL + metadata (app fetches directly or via relay)
- **Rich content**: Cards, polls, approval requests as structured JSON
- **Canvas**: A2UI push/reset events forwarded to app WebView

### Streaming Configuration

```typescript
streaming: {
  blockStreamingCoalesceDefaults: { minChars: 0, idleMs: 0 },
  // Zero coalescing -- forward everything immediately
  // App handles buffering and rendering
}
```

---

## 3. Client Apps

Any application that implements the ClawChat wire protocol. The protocol is the contract -- not a TypeScript interface or SDK.

### Reference Implementations (this project)

| Platform | Technology | Priority |
|----------|-----------|----------|
| iOS | SwiftUI | Phase 2 (primary) |
| Android | Jetpack Compose | Phase 2 (primary) |
| Web | React / Vue | Phase 3 (optional) |

### Client Responsibilities

- Connect to relay via WebSocket
- Handle pairing flow (enter code / scan QR)
- Render all message types (text, media, cards, polls, approval, canvas)
- Display streaming text with typing effect
- Show tool execution progress
- Send user messages, reactions, edits, deletions
- Register for push notifications
- Manage multiple sessions and agents
- Support multiple gateway connections

### Client State

Client is stateless regarding conversation history -- it requests history from gateway via the protocol. Local state is limited to:

- Pairing credentials (device token)
- UI preferences
- Push notification token
- Cached messages (for offline viewing, optional)

---

## Data Flow Examples

### User sends a message

```
1. User types "fix the login bug" in iOS app
2. App sends message.inbound via WebSocket to relay
3. Relay forwards to matched gateway WebSocket
4. Channel plugin receives, builds MsgContext
5. Plugin calls ctx.channelRuntime.reply.dispatchReply(...)
6. OpenClaw agent processes, starts tool calls
7. Gateway sends tool.event via plugin → relay → app
8. Agent completes, gateway sends message.outbound via plugin → relay → app
9. App renders the response with tool activity cards
```

### Agent needs approval

```
1. Agent wants to run `rm -rf ./build`
2. Gateway sends approval.request via plugin → relay → app
3. App shows native approval dialog with command context
4. User taps "Allow once"
5. App sends approval.response via relay → gateway
6. Plugin feeds decision back to agent
7. Agent proceeds with execution
```

### Streaming response

```
1. Agent starts generating response
2. Gateway streams:
   - message.reasoning (phase: streaming) → collapsible thinking UI
   - message.reasoning (phase: done)
   - tool.event (phase: start, tool: "exec")
   - tool.event (phase: result)
   - message.stream (delta: "The ", phase: streaming)
   - message.stream (delta: "fix is...", phase: streaming)
   - message.stream (phase: done)
3. App renders each event in real-time
```

---

## Implementation Phases

### Phase 0: Protocol + Minimal Relay
- Define JSON Schema for all message types (wire-protocol.md)
- Build relay as minimal WebSocket message forwarder
- No auth, no push -- just message routing
- Deploy single instance

### Phase 1: Channel Plugin + CLI Client
- `extensions/clawchat/` in OpenClaw repo
- CLI client for protocol testing (`clawchat connect`)
- Text + media inbound/outbound
- Pairing flow (code-based, no QR yet)

### Phase 2: Mobile Apps (Core Deliverable)
- iOS (SwiftUI) + Android (Jetpack Compose)
- Chat UI with markdown rendering
- Media capture + send (camera, gallery, files)
- Streaming text display
- Tool call activity cards
- Push notifications

### Phase 3: Full Feature Surface
- Reasoning blocks (collapsible)
- Approval flow (native UI)
- Canvas/A2UI (WebView)
- Polls, reactions, threading
- Voice input (STT)
- Session/agent management
- Multi-gateway

### Phase 4: Production Hardening
- E2EE
- Rate limiting
- HA deployment
- Offline message queue
- Delivery receipts
