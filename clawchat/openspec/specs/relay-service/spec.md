## MODIFIED Requirements

### Requirement: Server-side WebSocket keepalive
The relay service SHALL send WebSocket ping frames every 30 seconds to all connected gateway and app sockets. If no pong is received within 10 seconds, the connection SHALL be closed and cleanup (presence update, connection removal) SHALL be performed.

#### Scenario: Ping sent to connected gateway
- **WHEN** a gateway WebSocket has been connected for 30 seconds without activity
- **THEN** the relay SHALL send a WebSocket ping frame

#### Scenario: Dead gateway detected
- **WHEN** a gateway does not respond to a ping within 10 seconds
- **THEN** the relay SHALL close the connection and notify paired apps with a presence offline event

#### Scenario: Dead app detected
- **WHEN** an app does not respond to a ping within 10 seconds
- **THEN** the relay SHALL close the connection and update the device's lastSeen timestamp

### Requirement: Expired pairing code cleanup
The relay SHALL periodically clean up expired pairing codes from the database (at least every 60 seconds).

#### Scenario: Expired code removed
- **WHEN** a pairing code's `expiresAt` is in the past
- **THEN** it SHALL be deleted from the `pairing_codes` table within 60 seconds

#### Scenario: Expired code cannot be redeemed
- **WHEN** an app attempts to pair with an expired code
- **THEN** the relay SHALL respond with `app.pair.error` code `code_expired`
