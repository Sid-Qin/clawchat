## MODIFIED Requirements

### Requirement: Implementation Phases
The architecture spec's Phase 0 section SHALL be updated with concrete technology choices.

#### Scenario: Phase 0 technology stack
- **WHEN** implementing Phase 0 (Service + CLI)
- **THEN** the implementation SHALL use: Bun runtime, Hono HTTP framework, bun:sqlite for persistence, Bun native WebSocket for relay, and a Bun workspace monorepo structure

### Requirement: Project directory structure
The project SHALL follow a monorepo structure with shared protocol types.

#### Scenario: Directory layout
- **WHEN** the project is set up
- **THEN** the directory structure SHALL be:
  - `packages/protocol/` — shared TypeScript type definitions
  - `service/` — relay service (Bun + Hono + SQLite)
  - `cli/` — CLI reference client
  - `ios/` — iOS app (Phase 2, empty placeholder)
  - `android/` — Android app (Phase 2, empty placeholder)
