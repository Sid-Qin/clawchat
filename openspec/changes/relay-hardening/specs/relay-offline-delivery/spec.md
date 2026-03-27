## ADDED Requirements

### Requirement: Offline message persistence
The relay SHALL persist messages destined for disconnected app devices in an `offline_messages` SQLite table.

#### Scenario: Message queued for offline device
- **WHEN** the relay forwards a message (message.stream, message.outbound, message.reasoning, tool.event) to a device that is not connected
- **THEN** the message payload SHALL be inserted into `offline_messages` with the device's `deviceId` and current timestamp

#### Scenario: Typing and presence not queued
- **WHEN** the relay would forward a `typing` or `presence` message to an offline device
- **THEN** the message SHALL be dropped (not persisted)

### Requirement: Offline message delivery on reconnect
The relay SHALL deliver all pending offline messages to a device when it reconnects.

#### Scenario: Messages delivered on reconnect
- **WHEN** a device successfully completes `app.connect` and has pending offline messages
- **THEN** the relay SHALL send all pending messages in chronological order immediately after the `app.connected` response

#### Scenario: Messages marked delivered
- **WHEN** offline messages are sent to a reconnected device
- **THEN** the messages SHALL be marked as `delivered = 1` in the database

### Requirement: Offline message TTL and limits
The relay SHALL enforce a 24-hour TTL and per-device message cap on the offline queue.

#### Scenario: Expired messages cleaned up
- **WHEN** an offline message's `createdAt` is older than 24 hours
- **THEN** the message SHALL be deleted during the periodic cleanup cycle (every 60 seconds)

#### Scenario: Delivered messages cleaned up
- **WHEN** an offline message has `delivered = 1`
- **THEN** the message SHALL be deleted during the periodic cleanup cycle

#### Scenario: Per-device cap exceeded
- **WHEN** a device has 100 pending offline messages and a new message arrives
- **THEN** the oldest message SHALL be deleted before inserting the new one
