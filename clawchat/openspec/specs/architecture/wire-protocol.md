# Wire Protocol Specification

## Transport

- **Protocol**: WebSocket (RFC 6455)
- **Encoding**: JSON (UTF-8 text frames)
- **Ping/Pong**: WebSocket-level keepalive, 30s interval
- **Reconnection**: Exponential backoff (1s, 2s, 4s, 8s, max 60s)

## Message Envelope

Every message follows this structure:

```jsonc
{
  "type": "category.action",     // Required: message type
  "id": "uuid-v7",               // Required: unique message ID (UUIDv7 for ordering)
  "ts": 1710316800000,           // Required: timestamp (ms since epoch)
  // ... type-specific fields
}
```

---

## 1. Connection & Auth

### Gateway Registration

Gateway connects to relay and authenticates.

```jsonc
// Gateway -> Relay
{
  "type": "gateway.register",
  "id": "uuid",
  "ts": 1710316800000,
  "token": "gw-token-xxx",
  "gatewayId": "my-gateway",
  "version": "2026.3.13",         // OpenClaw version
  "agents": ["default", "coder"]  // Available agents
}

// Relay -> Gateway
{
  "type": "gateway.registered",
  "id": "uuid",
  "ts": 1710316800000,
  "gatewayId": "my-gateway",
  "pairedDevices": 2              // Number of currently paired apps
}
```

### App Pairing

First-time connection from a new device.

```jsonc
// App -> Relay: initiate pairing
{
  "type": "app.pair",
  "id": "uuid",
  "ts": 1710316800000,
  "pairingCode": "ABC-123",       // 6-char code displayed on gateway
  "deviceName": "iPhone 16",
  "platform": "ios"               // ios | android | web | cli
}

// Relay -> App: pairing successful
{
  "type": "app.paired",
  "id": "uuid",
  "ts": 1710316800000,
  "gatewayId": "my-gateway",
  "deviceToken": "long-lived-token", // For reconnection without re-pairing
  "agents": ["default", "coder"]
}

// Relay -> App: pairing failed
{
  "type": "app.pair.error",
  "id": "uuid",
  "ts": 1710316800000,
  "error": "invalid_code",        // invalid_code | expired | gateway_offline
  "message": "Pairing code not found or expired"
}
```

### App Reconnection

Subsequent connections using device token.

```jsonc
// App -> Relay
{
  "type": "app.connect",
  "id": "uuid",
  "ts": 1710316800000,
  "deviceToken": "long-lived-token",
  "lastMessageId": "uuid-of-last-received" // For missed message recovery
}

// Relay -> App
{
  "type": "app.connected",
  "id": "uuid",
  "ts": 1710316800000,
  "gatewayId": "my-gateway",
  "gatewayOnline": true,
  "agents": ["default", "coder"],
  "missedMessages": [...]          // Messages sent while app was offline (if queued)
}
```

---

## 2. Inbound Messages (App -> Gateway)

### Text Message

```jsonc
{
  "type": "message.inbound",
  "id": "uuid-v7",
  "ts": 1710316800000,
  "agentId": "default",
  "text": "help me debug this",
  "replyTo": "prev-msg-id",          // Optional: quote reply
  "threadId": "thread-abc",          // Optional: thread context
  "sessionKey": "clawchat:user1"     // Optional: explicit session override
}
```

### Message with Attachments

```jsonc
{
  "type": "message.inbound",
  "id": "uuid-v7",
  "ts": 1710316800000,
  "agentId": "default",
  "text": "what's in this screenshot?",
  "attachments": [
    {
      "type": "image",              // image | video | audio | file
      "mimeType": "image/png",
      "filename": "screenshot.png",
      "size": 245760,              // bytes
      "data": "<base64>",          // For small files (< 256KB)
      "url": "https://..."         // For large files (presigned upload URL)
    }
  ]
}
```

### Voice Message

```jsonc
{
  "type": "message.inbound",
  "id": "uuid-v7",
  "ts": 1710316800000,
  "agentId": "default",
  "voice": {
    "mimeType": "audio/opus",
    "duration": 5200,              // ms
    "data": "<base64>",
    "transcription": "fix the login bug"  // Optional: client-side STT result
  }
}
```

### Slash Command

```jsonc
{
  "type": "command.execute",
  "id": "uuid-v7",
  "ts": 1710316800000,
  "agentId": "default",
  "command": "/set model claude-sonnet-4-5-20250514"
}
```

---

## 3. Outbound Messages (Gateway -> App)

### Text Message

```jsonc
{
  "type": "message.outbound",
  "id": "uuid-v7",
  "ts": 1710316800000,
  "agentId": "default",
  "content": {
    "type": "text",
    "text": "Here's the fix for the login bug...",
    "format": "markdown"           // markdown | plain
  },
  "replyTo": "inbound-msg-id",
  "threadId": "thread-abc"
}
```

### Streaming Text

Sent token-by-token for real-time display.

```jsonc
// Stream start (implicit on first delta)
{
  "type": "message.stream",
  "id": "uuid-v7",                 // Same ID for all deltas of one message
  "ts": 1710316800000,
  "agentId": "default",
  "delta": "Here's ",
  "phase": "streaming"            // streaming | done | error
}

// Subsequent deltas
{
  "type": "message.stream",
  "id": "uuid-v7",
  "ts": 1710316800001,
  "delta": "the fix...",
  "phase": "streaming"
}

// Stream complete
{
  "type": "message.stream",
  "id": "uuid-v7",
  "ts": 1710316800500,
  "delta": "",
  "phase": "done",
  "finalText": "Here's the fix..."  // Full text for reconciliation
}
```

### Reasoning Block (Chain-of-Thought)

```jsonc
{
  "type": "message.reasoning",
  "id": "uuid-v7",
  "ts": 1710316800000,
  "agentId": "default",
  "text": "Let me analyze the stack trace to find the root cause...",
  "phase": "streaming"            // streaming | done
}
```

App should render this as a collapsible "Thinking..." section.

### Tool Execution Event

```jsonc
{
  "type": "tool.event",
  "id": "uuid-v7",
  "ts": 1710316800000,
  "agentId": "default",
  "tool": "exec",                  // Tool name
  "phase": "start",               // start | progress | result | error
  "label": "Running tests",       // Human-readable label
  "input": {                      // Tool input (phase: start)
    "command": "pnpm test"
  },
  "progress": null,               // Progress info (phase: progress)
  "result": null,                  // Tool output (phase: result)
  "error": null                   // Error info (phase: error)
}
```

Common tool names: `exec`, `read`, `write`, `edit`, `web_search`, `web_fetch`, `browser`, `image`, `pdf`, `canvas`, `tts`, `memory_search`.

### Media Message

```jsonc
{
  "type": "message.outbound",
  "id": "uuid-v7",
  "ts": 1710316800000,
  "agentId": "default",
  "content": {
    "type": "media",
    "mediaType": "image",          // image | video | audio | file
    "mimeType": "image/png",
    "url": "https://...",          // Direct URL or relay-proxied URL
    "filename": "screenshot.png",
    "size": 245760,
    "caption": "Screenshot of the bug",
    "dimensions": { "width": 1920, "height": 1080 }  // For images/video
  }
}
```

### Poll

```jsonc
{
  "type": "message.outbound",
  "id": "uuid-v7",
  "ts": 1710316800000,
  "agentId": "default",
  "content": {
    "type": "poll",
    "question": "Which approach should we take?",
    "options": [
      { "id": "opt-0", "text": "Refactor the existing code" },
      { "id": "opt-1", "text": "Rewrite from scratch" },
      { "id": "opt-2", "text": "Leave it as-is" }
    ],
    "maxSelections": 1,
    "anonymous": false
  }
}
```

### Rich Card (Buttons / Actions)

```jsonc
{
  "type": "message.outbound",
  "id": "uuid-v7",
  "ts": 1710316800000,
  "agentId": "default",
  "content": {
    "type": "card",
    "title": "Deploy to production?",
    "body": "All 42 tests pass. Branch `main` is 3 commits ahead of production.",
    "format": "markdown",
    "actions": [
      { "id": "deploy", "label": "Deploy Now", "style": "primary" },
      { "id": "diff", "label": "View Diff", "style": "secondary" },
      { "id": "cancel", "label": "Cancel", "style": "danger" }
    ]
  }
}
```

### Approval Request (Human-in-the-Loop)

```jsonc
{
  "type": "approval.request",
  "id": "approval-uuid",
  "ts": 1710316800000,
  "agentId": "coder",
  "command": "rm -rf ./build",
  "workingDir": "/Users/tis/project",
  "context": {                     // Optional: extra context for user
    "reason": "Clean build artifacts before fresh build",
    "risk": "medium"
  },
  "expiresAt": "2026-03-13T12:05:00Z",
  "options": ["allow-once", "allow-always", "deny"]
}
```

### Canvas / A2UI

```jsonc
// Present canvas
{
  "type": "canvas.update",
  "id": "canvas-uuid",
  "ts": 1710316800000,
  "agentId": "default",
  "action": "present",             // present | hide | push | reset | snapshot
  "url": "https://...",            // Web content URL (for present)
  "dimensions": { "width": 800, "height": 600 }
}

// Push A2UI data
{
  "type": "canvas.update",
  "id": "canvas-uuid",
  "ts": 1710316800000,
  "agentId": "default",
  "action": "push",
  "data": "{\"type\":\"surface\",...}\n{\"type\":\"component\",...}"  // JSONL
}
```

---

## 4. User Actions (App -> Gateway)

### Reaction

```jsonc
{
  "type": "reaction.add",
  "id": "uuid",
  "ts": 1710316800000,
  "messageId": "target-msg-id",
  "emoji": "thumbsup"             // Emoji shortcode or unicode
}

{
  "type": "reaction.remove",
  "id": "uuid",
  "ts": 1710316800000,
  "messageId": "target-msg-id",
  "emoji": "thumbsup"
}
```

### Edit Message

```jsonc
{
  "type": "message.edit",
  "id": "uuid",
  "ts": 1710316800000,
  "messageId": "original-msg-id",
  "text": "updated message text"
}
```

### Delete Message

```jsonc
{
  "type": "message.delete",
  "id": "uuid",
  "ts": 1710316800000,
  "messageId": "target-msg-id"
}
```

### Card Action Response

```jsonc
{
  "type": "action.response",
  "id": "uuid",
  "ts": 1710316800000,
  "cardId": "card-msg-id",
  "actionId": "deploy"
}
```

### Approval Response

```jsonc
{
  "type": "approval.response",
  "id": "uuid",
  "ts": 1710316800000,
  "approvalId": "approval-uuid",
  "decision": "allow-once"         // allow-once | allow-always | deny
}
```

### Poll Vote

```jsonc
{
  "type": "poll.vote",
  "id": "uuid",
  "ts": 1710316800000,
  "pollId": "poll-msg-id",
  "optionIds": ["opt-0"]           // Array for multi-select polls
}
```

### Abort / Cancel

```jsonc
{
  "type": "agent.abort",
  "id": "uuid",
  "ts": 1710316800000,
  "agentId": "default",
  "sessionKey": "clawchat:user1"   // Optional
}
```

---

## 5. Control Messages

### Typing Indicator

```jsonc
// Gateway -> App (agent is processing)
{
  "type": "typing",
  "ts": 1710316800000,
  "agentId": "default",
  "active": true,
  "label": "Thinking..."           // Optional: more specific status
}
```

### Presence

```jsonc
// Bidirectional
{
  "type": "presence",
  "ts": 1710316800000,
  "status": "online"              // online | away | offline
}
```

### Session Management

```jsonc
// App -> Relay -> Gateway: list sessions
{
  "type": "session.list",
  "id": "req-uuid",
  "ts": 1710316800000
}

// Gateway -> App: session list response
{
  "type": "session.list.response",
  "id": "req-uuid",
  "ts": 1710316800000,
  "sessions": [
    {
      "key": "clawchat:default:user1",
      "agentId": "default",
      "lastActivity": 1710316700000,
      "messageCount": 42
    }
  ]
}

// App -> Gateway: get session history
{
  "type": "session.history",
  "id": "req-uuid",
  "ts": 1710316800000,
  "sessionKey": "clawchat:default:user1",
  "limit": 50,
  "before": "msg-id"              // Pagination cursor
}

// Gateway -> App: history response
{
  "type": "session.history.response",
  "id": "req-uuid",
  "ts": 1710316800000,
  "messages": [...],               // Array of outbound message objects
  "hasMore": true
}

// App -> Gateway: create new session
{ "type": "session.new", "id": "uuid", "ts": 1710316800000, "agentId": "default" }

// App -> Gateway: switch active session
{ "type": "session.switch", "id": "uuid", "ts": 1710316800000, "sessionKey": "..." }
```

### Agent Management

```jsonc
// App -> Gateway: list agents
{ "type": "agents.list", "id": "req-uuid", "ts": 1710316800000 }

// Gateway -> App
{
  "type": "agents.list.response",
  "id": "req-uuid",
  "ts": 1710316800000,
  "agents": [
    { "id": "default", "name": "Default Agent", "model": "claude-sonnet-4-5-20250514" },
    { "id": "coder", "name": "Coder", "model": "claude-opus-4-6" }
  ]
}
```

### Gateway Status

```jsonc
// App -> Relay
{ "type": "status.request", "id": "req-uuid", "ts": 1710316800000 }

// Relay -> App
{
  "type": "status.response",
  "id": "req-uuid",
  "ts": 1710316800000,
  "gateway": {
    "online": true,
    "version": "2026.3.13",
    "uptime": 86400000,
    "agents": ["default", "coder"],
    "channels": [
      { "id": "telegram", "status": "connected" },
      { "id": "clawchat", "status": "connected" }
    ]
  }
}
```

### Push Notification Registration

```jsonc
// App -> Relay
{
  "type": "push.register",
  "id": "uuid",
  "ts": 1710316800000,
  "platform": "apns",             // apns | fcm
  "token": "device-push-token",
  "preferences": {
    "messages": true,
    "approvals": true,
    "errors": false
  }
}
```

---

## 6. Error Handling

All errors follow a consistent format:

```jsonc
{
  "type": "error",
  "id": "uuid",
  "ts": 1710316800000,
  "code": "gateway_offline",
  "message": "Gateway is not connected",
  "requestId": "original-request-uuid"  // Links to the request that caused the error
}
```

Error codes:
- `gateway_offline` - Gateway WebSocket not connected
- `agent_not_found` - Requested agent doesn't exist
- `session_not_found` - Session key doesn't exist
- `unauthorized` - Invalid token or pairing
- `rate_limited` - Too many requests
- `payload_too_large` - Message exceeds size limit
- `internal_error` - Relay service error

---

## 7. File Transfer

For files larger than 256KB, use presigned upload/download URLs:

```jsonc
// App -> Relay: request upload URL
{
  "type": "file.upload.request",
  "id": "uuid",
  "ts": 1710316800000,
  "filename": "large-file.zip",
  "mimeType": "application/zip",
  "size": 10485760
}

// Relay -> App: upload URL
{
  "type": "file.upload.response",
  "id": "uuid",
  "ts": 1710316800000,
  "uploadUrl": "https://storage.clawchat.io/upload/...",
  "fileId": "file-uuid",
  "expiresAt": "2026-03-13T12:10:00Z"
}

// App uploads file via HTTP PUT to uploadUrl, then references fileId in message:
{
  "type": "message.inbound",
  "id": "uuid-v7",
  "ts": 1710316800000,
  "agentId": "default",
  "text": "analyze this file",
  "attachments": [
    { "type": "file", "fileId": "file-uuid", "filename": "large-file.zip" }
  ]
}
```
