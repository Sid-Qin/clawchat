## ADDED Requirements

### Requirement: Structured JSON logging
The relay SHALL output structured JSON log lines to stdout, replacing all ad-hoc `console.log` calls.

#### Scenario: Log format
- **WHEN** any loggable event occurs
- **THEN** the relay SHALL output a JSON object with fields: `ts` (ISO 8601), `level` (debug|info|warn|error), `event` (dot-separated identifier), and event-specific data fields

#### Scenario: Gateway registration logged
- **WHEN** a gateway registers
- **THEN** the relay SHALL log `{"level":"info","event":"gateway.register","gatewayId":"...","agents":[...]}`

#### Scenario: App pairing logged
- **WHEN** an app successfully pairs
- **THEN** the relay SHALL log `{"level":"info","event":"app.paired","deviceId":"...","gatewayId":"...","platform":"..."}`

#### Scenario: Error events logged
- **WHEN** the relay sends an error response to a client
- **THEN** the relay SHALL log at `warn` level with `event`, `code`, and `message` fields

### Requirement: Log level filtering
The relay SHALL support a configurable minimum log level via the `LOG_LEVEL` environment variable.

#### Scenario: Default log level
- **WHEN** `LOG_LEVEL` is not set
- **THEN** the relay SHALL output logs at `info` level and above (info, warn, error)

#### Scenario: Debug logging enabled
- **WHEN** `LOG_LEVEL=debug`
- **THEN** the relay SHALL also output debug-level logs (message forwarding, keepalive pings, cleanup counts)

#### Scenario: Messages below threshold suppressed
- **WHEN** `LOG_LEVEL=warn`
- **THEN** `info` and `debug` level logs SHALL not be output
