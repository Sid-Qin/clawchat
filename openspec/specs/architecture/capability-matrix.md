# Capability Matrix

## ClawChat vs Existing OpenClaw Channels

This matrix shows why ClawChat exists: it's the only channel that can surface ALL of OpenClaw's capabilities.

### Core Messaging

| Capability | Discord | Telegram | Slack | Signal | iMessage | Matrix | **ClawChat** |
|---|---|---|---|---|---|---|---|
| Text (Markdown) | native | HTML | mrkdwn | plain | plain | native | **native** |
| Media (image) | native | native | native | native | native | native | **native** |
| Media (video) | native | native | native | native | native | native | **native** |
| Media (audio) | native | native | native | native | native | native | **native** |
| Media (file) | native | native | native | native | native | native | **native** |
| Reactions | native | native | native | - | tapback | native | **native** |
| Reply/Quote | native | native | native | native | - | native | **native** |
| Edit message | - | - | - | - | - | native | **native** |
| Unsend/Delete | - | - | - | - | - | native | **native** |
| Threads | native | topics | native | - | - | native | **native** |
| Polls | native | native | blocks | - | - | - | **native** |

### Rich Interactions

| Capability | Discord | Telegram | Slack | Signal | iMessage | Matrix | **ClawChat** |
|---|---|---|---|---|---|---|---|
| Buttons/Actions | components | inline kbd | blocks | - | - | - | **native (cards)** |
| Select menus | components | - | blocks | - | - | - | **native** |
| Modals/Forms | components | - | blocks | - | - | - | **native** |
| Slash commands | native | /commands | native | - | - | - | **native** |

### AI Agent Features (ClawChat Exclusives)

These capabilities are unique to ClawChat -- no third-party channel can support them because the platform APIs don't expose these concepts.

| Capability | All 3rd-party channels | **ClawChat** |
|---|---|---|
| Token-level streaming | coalesced blocks (500-1500ms) | **real-time deltas** |
| Reasoning/thinking blocks | not rendered | **collapsible thinking UI** |
| Tool call visualization | not rendered | **live progress cards** |
| Approval flow UI | text "reply yes/no" | **native dialog with context** |
| Canvas/A2UI artifacts | not supported | **embedded WebView** |
| Agent abort/cancel | not supported | **tap to cancel** |
| Session management | per-channel routing | **explicit session list/switch** |
| Agent switching | via routing config | **agent picker UI** |
| Multi-gateway | not applicable | **gateway list + switch** |
| Voice input (STT) | voice messages only | **real-time STT** |
| Push notifications (granular) | platform-level | **per-type control (messages/approvals/errors)** |

### Delivery Characteristics

| Aspect | 3rd-party channels | **ClawChat** |
|---|---|---|
| Streaming latency | 500-1500ms (coalesced) | **< 100ms (direct forward)** |
| Message format | Platform-specific conversion | **Raw markdown (app renders)** |
| Chunking | 2000-4000 char limits | **No limit (app handles)** |
| Media delivery | Platform re-hosting | **Direct URL or relay proxy** |
| Outbound identity | Bot username + avatar | **Agent name + avatar per-agent** |

### Network Requirements

| Aspect | 3rd-party channels | **ClawChat** |
|---|---|---|
| Gateway needs public IP | No (connects outbound to platform) | **No (connects outbound to relay)** |
| App needs public IP | No (uses platform app) | **No (connects outbound to relay)** |
| Works behind NAT | Yes | **Yes** |
| Works in China | Some blocked (Telegram, Discord) | **Yes (self-host relay if needed)** |
| Self-hostable relay | No (platform owns infra) | **Yes** |

---

## Why Not Just Improve Webchat?

The existing Control UI webchat (`/chat` endpoint) shares some goals with ClawChat, but has fundamental limitations:

| Aspect | Webchat | ClawChat |
|---|---|---|
| Network model | Gateway must be reachable (localhost or exposed) | Relay model, gateway behind NAT |
| Mobile support | Browser only, no push | Native apps + APNs/FCM |
| Multi-device | Single browser tab | Multiple paired devices |
| Offline | Tab must stay open | Push + reconnect |
| Streaming | Known bugs (#33641, #35308, #25316) | Clean protocol, app owns rendering |
| Canvas/A2UI | Exists but unstable (#7143) | Native WebView integration |
| Channel identity | Shares "webchat" ID (#36431) | Own `clawchat` channel ID |
| Tool access | Shared tool profile | Dedicated `tools.byChannel` profile (#31208) |
