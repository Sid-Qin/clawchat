## ADDED Requirements

### Requirement: Generate pairing code
The relay service SHALL generate a pairing code when requested by a registered gateway.

#### Scenario: Gateway requests pairing code via HTTP
- **WHEN** a gateway sends `POST /api/pair/code` with its gateway token in the `Authorization` header
- **THEN** the service SHALL generate a 6-character alphanumeric code (uppercase, no ambiguous chars like 0/O/1/I/l), store it with a 5-minute TTL, and return `{ "code": "ABC-123", "expiresAt": "..." }`

#### Scenario: Gateway requests pairing code via WebSocket
- **WHEN** a registered gateway sends `{ "type": "pair.generate" }` over its WebSocket
- **THEN** the service SHALL generate a code, store it, and respond with `{ "type": "pair.code", "code": "ABC-123", "expiresAt": "..." }`

### Requirement: Redeem pairing code
The relay service SHALL allow an app to redeem a pairing code to establish a gateway-device binding.

#### Scenario: Valid pairing code
- **WHEN** an app sends `app.pair` with a valid, non-expired pairing code
- **THEN** the service SHALL create a device record (deviceId, deviceName, platform, paired gatewayId), generate a long-lived device token (UUID), return `app.paired` with the device token and gateway info

#### Scenario: Expired pairing code
- **WHEN** an app sends `app.pair` with an expired code
- **THEN** the service SHALL respond with `app.pair.error` (error: `expired`)

#### Scenario: Invalid pairing code
- **WHEN** an app sends `app.pair` with a code that doesn't exist
- **THEN** the service SHALL respond with `app.pair.error` (error: `invalid_code`)

#### Scenario: Code already redeemed
- **WHEN** an app sends `app.pair` with a code that has already been used
- **THEN** the service SHALL respond with `app.pair.error` (error: `invalid_code`)

### Requirement: Device token authentication
The relay service SHALL authenticate returning apps using their device token.

#### Scenario: Valid device token
- **WHEN** an app sends `app.connect` with a valid device token
- **THEN** the service SHALL look up the paired gateway, respond with `app.connected`, and begin relaying messages

#### Scenario: Revoked device token
- **WHEN** an app sends `app.connect` with a device token that has been revoked
- **THEN** the service SHALL respond with `error` (code: `unauthorized`)

### Requirement: Device management
The relay service SHALL allow gateways to list and revoke paired devices.

#### Scenario: List paired devices
- **WHEN** a gateway sends `{ "type": "devices.list" }` over its WebSocket
- **THEN** the service SHALL respond with a list of paired devices (deviceId, deviceName, platform, lastSeen, online status)

#### Scenario: Revoke a device
- **WHEN** a gateway sends `{ "type": "devices.revoke", "deviceId": "..." }` over its WebSocket
- **THEN** the service SHALL delete the device record, invalidate its device token, and close the device's WebSocket connection if active

### Requirement: Pairing code character set
Pairing codes SHALL use only uppercase letters and digits, excluding ambiguous characters (0, O, 1, I, L). The character set is: `2-9, A-H, J-K, M, N, P-Z` (30 characters).

#### Scenario: Code format
- **WHEN** a pairing code is generated
- **THEN** it SHALL be exactly 6 characters from the allowed set, formatted as `XXX-XXX` for display (hyphen is cosmetic, not part of the code)

### Requirement: Pairing data persistence
Pairing data (device records, gateway registrations) SHALL be stored in SQLite and survive service restarts.

#### Scenario: Service restarts
- **WHEN** the relay service restarts
- **THEN** all device tokens and gateway-device pairings SHALL remain valid. Active WebSocket connections will need to reconnect, but authentication state is preserved.
