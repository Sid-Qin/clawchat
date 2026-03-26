## Context

The relay service (`service/src/`) is a Bun-based WebSocket broker that connects gateway instances to mobile/desktop apps. It uses SQLite for persistence (gateways, devices, pairing codes) and an in-memory connection store. Currently Phase 0: no rate limiting, trust-on-first-use gateway auth, console.log logging, and no offline message delivery.

The relay runs as a single-process deployment on Railway. There are no plans for horizontal scaling in this phase.

## Goals / Non-Goals

**Goals:**
- Protect against abuse: rate limiting per IP and per gateway
- Harden authentication: verify gateway tokens, rotate device tokens
- Deliver messages to temporarily offline devices (bounded queue)
- Replace ad-hoc console.log with structured JSON logging
- Add connection limits to prevent resource exhaustion

**Non-Goals:**
- Horizontal scaling / Redis-backed state (future phase)
- End-to-end encryption (delegated to reverse proxy / TLS)
- Multi-tenancy / user isolation
- Push notifications (separate change)
- Message persistence beyond offline delivery window

## Decisions

### 1. Rate Limiting: In-memory sliding window

Use a simple in-memory Map with sliding window counters, keyed by IP for connection-level and by gatewayId/deviceId for message-level limits.

**Limits:**
- WebSocket connections: 10 per IP per minute
- Messages: 60 per device per minute, 200 per gateway per minute
- HTTP API: 30 requests per IP per minute
- Pairing code generation: 5 per gateway per minute

**Why not a Redis/external store:** Single-process deployment; in-memory is sufficient and zero-dependency. If we scale horizontally later, swap to Redis.

**Why sliding window over token bucket:** Simpler to implement, predictable behavior, good enough for our scale.

### 2. Gateway Token Verification: Strict match on reconnect

Currently `gateway.register` upserts any token (trust-on-first-use). Change to:
- First registration: store token hash (SHA-256)
- Subsequent registrations: verify token matches stored hash
- Mismatch → reject with `unauthorized` error

**Why hash, not plaintext:** Defense in depth — if DB is compromised, tokens aren't directly usable.

### 3. Device Token Rotation: New token on every reconnect

When an app sends `app.connect`, the relay:
1. Validates the current `deviceToken`
2. Generates a new token
3. Updates the DB
4. Returns the new token in `app.connected` response (new field: `newDeviceToken`)

Clients must persist the new token immediately. The old token becomes invalid.

**Why rotate:** Limits the window of a stolen token. If a token leaks, it's only valid until the legitimate client reconnects.

**Client impact:** iOS `CredentialStore` and Android `CredentialStore` must check for `newDeviceToken` in `app.connected` and update stored credentials.

### 4. Offline Message Delivery: SQLite queue with TTL

New `offline_messages` table:
```sql
CREATE TABLE offline_messages (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  deviceId TEXT NOT NULL REFERENCES devices(deviceId) ON DELETE CASCADE,
  payload TEXT NOT NULL,  -- raw JSON message
  createdAt INTEGER NOT NULL,
  delivered INTEGER DEFAULT 0
);
```

**Behavior:**
- When forwarding a message to an app socket that is disconnected, insert into `offline_messages`
- On `app.connect` (reconnect), deliver all pending messages for that device, then mark delivered
- TTL: 24 hours. Cleanup job deletes expired + delivered messages every 60 seconds (piggyback on existing cleanup interval)
- Max 100 messages per device (drop oldest if exceeded)

**Why SQLite, not in-memory:** Messages must survive relay restarts. SQLite is already in use.

**Why 24h/100 limit:** Prevents unbounded growth. Users offline for >24h likely need full re-sync anyway.

### 5. Structured Logging: JSON to stdout

Replace all `console.log("[prefix]", ...)` with a `log(level, event, data)` utility that outputs JSON:

```json
{"ts":"2026-03-14T12:00:00Z","level":"info","event":"gateway.register","gatewayId":"gw-1","agents":["default"]}
```

Levels: `debug`, `info`, `warn`, `error`. Default level controlled by `LOG_LEVEL` env var (default: `info`).

**Why JSON:** Machine-parseable for Railway logs, Datadog, etc. Structured fields enable filtering/alerting.

### 6. Connection Limits

- Max 5 concurrent app connections per gateway (reject with `connection_limit` error)
- Max 20 WebSocket connections per IP (reject upgrade)
- Max 10 paired devices per gateway (reject pairing with `device_limit` error)

## Risks / Trade-offs

- **In-memory rate limit state lost on restart** → Acceptable; limits reset is benign (brief window of no limiting). Mitigated by fast Bun startup.
- **Token rotation breaks clients that don't handle it** → Both iOS and Android kits must be updated. Add `newDeviceToken` as optional field so old clients still connect (they just won't rotate).
- **Offline message queue grows DB size** → Bounded by 100 messages × device count × 24h TTL. Cleanup job keeps it manageable.
- **Single SHA-256 hash for gateway token** → No salt. Acceptable for server-generated high-entropy tokens. Not user passwords.
