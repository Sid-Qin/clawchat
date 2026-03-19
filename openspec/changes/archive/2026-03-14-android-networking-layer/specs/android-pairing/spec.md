## ADDED Requirements

### Requirement: Pair with code
The client SHALL send an `app.pair` message with a 6-character pairing code and await an `app.paired` response containing `deviceToken` and `gatewayId`.

#### Scenario: Successful pairing
- **WHEN** `pair(code = "XEW-P3P", deviceName = "Pixel 9")` is called
- **THEN** the client SHALL send `{"type":"app.pair","pairingCode":"XEW-P3P","deviceName":"Pixel 9","platform":"android","protocolVersion":"0.1"}` and resolve with the `deviceToken` and `gatewayId` from the `app.paired` response

#### Scenario: Invalid pairing code
- **WHEN** the relay responds with `app.pair.error` (code: `invalid_code`)
- **THEN** the pair function SHALL throw a `PairingException.InvalidCode`

#### Scenario: Expired pairing code
- **WHEN** the relay responds with `app.pair.error` (code: `code_expired`)
- **THEN** the pair function SHALL throw a `PairingException.CodeExpired`

### Requirement: Reconnect with device token
The client SHALL send an `app.connect` message with a stored device token and await an `app.connected` response.

#### Scenario: Successful reconnection
- **WHEN** `reconnect(deviceToken)` is called with a valid token
- **THEN** the client SHALL send `{"type":"app.connect","deviceToken":"<token>","protocolVersion":"0.1"}` and resolve with gateway status

#### Scenario: Gateway offline on reconnect
- **WHEN** the `app.connected` response has `gatewayOnline: false`
- **THEN** the client SHALL resolve successfully but indicate gateway is offline

#### Scenario: Invalid device token
- **WHEN** the relay responds with an error (code: `unauthorized`)
- **THEN** the reconnect function SHALL throw a `PairingException.Unauthorized` and clear stored credentials

### Requirement: Encrypted credential persistence
The client SHALL store `deviceToken`, `relayUrl`, and `gatewayId` in AndroidX `EncryptedSharedPreferences`. Credentials SHALL persist across app updates.

#### Scenario: Save after successful pairing
- **WHEN** pairing succeeds
- **THEN** `deviceToken`, `relayUrl`, and `gatewayId` SHALL be saved to EncryptedSharedPreferences

#### Scenario: Load on app launch
- **WHEN** the app launches and EncryptedSharedPreferences contains valid credentials
- **THEN** the client SHALL load them and attempt reconnection automatically

#### Scenario: Clear on unauthorized
- **WHEN** the relay rejects a device token as unauthorized
- **THEN** all stored credentials SHALL be deleted from EncryptedSharedPreferences

#### Scenario: Storage access error
- **WHEN** EncryptedSharedPreferences read/write fails
- **THEN** the error SHALL be propagated without crashing
