## Why

The relay service is currently a Phase 0 prototype with no rate limiting, trust-on-first-use gateway auth, no token rotation, basic console logging, and no message delivery guarantees for offline devices. Before building client UI layers, the relay needs production-grade hardening so client features (reconnect, offline messaging, device management) work reliably.

## What Changes

- Add per-IP and per-gateway rate limiting for WebSocket messages and HTTP endpoints
- Implement gateway token verification (reject mismatched tokens on reconnect instead of trust-on-first-use upsert)
- Add device token rotation on reconnect (issue new token, invalidate old)
- Add message queue for offline devices (persist undelivered messages, deliver on reconnect)
- Add structured logging with request tracing (replace console.log with structured JSON logs)
- Add connection limits (max connections per IP, max devices per gateway)

## Capabilities

### New Capabilities
- `relay-rate-limiting`: Per-IP and per-gateway rate limiting for WebSocket messages and HTTP API calls
- `relay-token-security`: Gateway token verification and device token rotation on reconnect
- `relay-offline-delivery`: Message persistence and delivery for temporarily offline devices
- `relay-logging`: Structured JSON logging with request correlation IDs

### Modified Capabilities
- `relay-service`: Updated keepalive and cleanup behaviors, connection limits, error codes for rate limiting

## Impact

- **Code**: `service/src/` — handlers, db schema (new tables for message queue), connection store (rate tracking), logging utility
- **Database**: New `offline_messages` table, schema migration
- **Protocol**: New error codes (`rate_limited`, `token_rotated`), new `app.connected` field for rotated token
- **Clients**: iOS/Android kit must handle token rotation on reconnect (update stored credential)
- **Deployment**: No new dependencies beyond what Bun provides (SQLite, timers)
