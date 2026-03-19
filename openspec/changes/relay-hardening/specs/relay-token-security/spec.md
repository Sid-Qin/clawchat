## ADDED Requirements

### Requirement: Gateway token verification
The relay SHALL store a SHA-256 hash of the gateway token on first registration and verify subsequent registrations against the stored hash. Mismatched tokens SHALL be rejected.

#### Scenario: First gateway registration
- **WHEN** a gateway registers with `gateway.register` and no prior registration exists for that `gatewayId`
- **THEN** the relay SHALL hash the token with SHA-256, store the hash in the `gateways` table, and respond with `gateway.registered`

#### Scenario: Successful re-registration
- **WHEN** a gateway registers with a token whose SHA-256 hash matches the stored hash
- **THEN** the relay SHALL accept the registration and respond with `gateway.registered`

#### Scenario: Token mismatch
- **WHEN** a gateway registers with a token whose SHA-256 hash does not match the stored hash
- **THEN** the relay SHALL reject with an error `{"type":"error","code":"unauthorized","message":"invalid gateway token"}`

### Requirement: Device token rotation on reconnect
The relay SHALL issue a new device token on every successful `app.connect` reconnection. The old token SHALL become invalid immediately.

#### Scenario: Token rotated on reconnect
- **WHEN** an app sends `app.connect` with a valid `deviceToken`
- **THEN** the relay SHALL generate a new token, update the database, and include `newDeviceToken` in the `app.connected` response

#### Scenario: Old token invalidated
- **WHEN** an app attempts `app.connect` with a token that was already rotated
- **THEN** the relay SHALL reject with `{"type":"error","code":"unauthorized"}`

#### Scenario: Client persists new token
- **WHEN** the `app.connected` response includes `newDeviceToken`
- **THEN** the client SHALL replace its stored device token with the new value
