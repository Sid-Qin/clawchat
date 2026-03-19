## 1. Structured Logging

- [x] 1.1 Create `src/log.ts` with `log(level, event, data)` function outputting JSON to stdout
- [x] 1.2 Add `LOG_LEVEL` env var support with filtering (debug < info < warn < error, default: info)
- [x] 1.3 Replace all `console.log` calls in `src/index.ts` with structured log calls
- [x] 1.4 Replace all `console.log` calls in `src/handlers/gateway.ts` with structured log calls
- [x] 1.5 Replace all `console.log` calls in `src/handlers/app.ts` with structured log calls
- [x] 1.6 Replace all `console.log` calls in `src/handlers/http.ts`, `src/keepalive.ts`, `src/db.ts` with structured log calls
- [x] 1.7 Add unit tests for log level filtering and JSON output format

## 2. Rate Limiting

- [x] 2.1 Create `src/rate-limit.ts` with sliding window counter (Map-based, keyed by identifier)
- [x] 2.2 Add `checkRateLimit(key, limit, windowMs)` function returning `{ allowed: boolean, remaining: number }`
- [x] 2.3 Wire message rate limiting into app handler (60/min per device)
- [x] 2.4 Wire message rate limiting into gateway handler (200/min per gateway)
- [x] 2.5 Wire pairing code generation rate limiting (5/min per gateway)
- [x] 2.6 Wire HTTP API rate limiting (30/min per IP) into Hono middleware
- [x] 2.7 Wire WebSocket connection rate limiting (10/min per IP) into upgrade handler
- [x] 2.8 Add periodic cleanup of expired rate limit entries (every 60s)
- [x] 2.9 Add unit tests for sliding window counter logic

## 3. Connection Limits

- [x] 3.1 Add max concurrent connections per IP tracking (limit: 20) in connection store
- [x] 3.2 Add max app connections per gateway tracking (limit: 5) in connection store
- [x] 3.3 Add max paired devices per gateway check (limit: 10) in pairing handler
- [x] 3.4 Return appropriate error codes (`connection_limit`, `device_limit`) on rejection
- [x] 3.5 Add unit tests for connection limit enforcement

## 4. Gateway Token Verification

- [x] 4.1 Add `tokenHash` column to `gateways` table (SHA-256 of token)
- [x] 4.2 Modify `gateway.register` handler: hash token, store on first registration, verify on subsequent
- [x] 4.3 Return `unauthorized` error on token mismatch
- [x] 4.4 Add DB migration logic (add column if not exists)
- [x] 4.5 Add unit tests for token verification (first reg, re-reg match, re-reg mismatch)

## 5. Device Token Rotation

- [x] 5.1 Modify `app.connect` handler to generate new token, update DB, return `newDeviceToken` in `app.connected`
- [x] 5.2 Invalidate old token immediately after rotation
- [x] 5.3 Update iOS `PairingManager` to persist `newDeviceToken` from `app.connected` response
- [x] 5.4 Update Android `PairingManager` to persist `newDeviceToken` from `app.connected` response
- [x] 5.5 Update protocol types: add `newDeviceToken` field to `AppConnected`
- [x] 5.6 Add unit tests for token rotation flow

## 6. Offline Message Delivery

- [x] 6.1 Create `offline_messages` table in `db.ts` (id, deviceId, payload, createdAt, delivered)
- [x] 6.2 Add `queueOfflineMessage(deviceId, payload)` function with per-device cap (100)
- [x] 6.3 Add `getOfflineMessages(deviceId)` and `markDelivered(ids)` functions
- [x] 6.4 Modify message forwarding: queue if device socket not connected (skip typing/presence)
- [x] 6.5 Modify `app.connect` handler: deliver pending messages after `app.connected`
- [x] 6.6 Add offline message cleanup to existing periodic cleanup (24h TTL + delivered)
- [x] 6.7 Add unit tests for queue, delivery, TTL cleanup, and cap enforcement

## 7. Integration Tests

- [x] 7.1 Add integration test: rate-limited message returns error
- [x] 7.2 Add integration test: gateway token mismatch rejected
- [x] 7.3 Add integration test: device token rotated on reconnect
- [x] 7.4 Add integration test: offline messages delivered on reconnect
- [x] 7.5 Add integration test: connection limit enforced
