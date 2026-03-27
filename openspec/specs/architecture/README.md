# ClawChat Architecture Specification

## Overview

ClawChat is a first-party messaging service for the OpenClaw ecosystem. It follows the same pattern as third-party channels (Telegram, Discord, Slack): the OpenClaw gateway connects outbound to a relay service, and client apps also connect outbound to the same relay. No public IP required for the gateway.

## Documents

```
openspec/specs/architecture/
├── README.md                    # This file
├── system-architecture.md       # Overall system design (3 components)
├── wire-protocol.md             # WebSocket JSON protocol specification
└── capability-matrix.md         # Feature comparison with existing channels
```

## Core Principle

> OpenClaw's capabilities should not be limited by the weakest channel.
> ClawChat is the reference channel that surfaces ALL OpenClaw features.
