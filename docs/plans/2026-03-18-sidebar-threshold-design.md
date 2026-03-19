# Sidebar Threshold Smoothing Design

**Goal:** Make the `single column -> fullscreen` transition shorter, more natural, and visually continuous.

## Problem

The current sidebar interaction still feels like it has a visible boundary:

- The compact single-column phase lasts too long before the layout meaningfully expands.
- `AgentSidebarView` still relies on `isFullScreen` for several major layout decisions.
- When the threshold is crossed, the user can still feel a mode switch instead of a continuous reflow.

## Design Principles

- Keep the compact column only as a short confirmation phase.
- Start visual expansion earlier, before the user feels "stuck" in the narrow state.
- Preserve the feeling that the same content keeps moving forward and rearranging.
- Avoid "disappear, then appear" transitions for existing sidebar content.
- Introduce new fullscreen-only metadata progressively and only when there is enough space.

## Interaction Model

### Phase 0: Closed

- Sidebar is hidden.

### Phase 1: Compact Confirmation

- A short drag reveals the narrow column.
- This phase is intentionally brief so the user understands the entry state without feeling blocked.

### Phase 2: Progressive Expansion

- Width begins expanding earlier than it does now.
- The selected gateway's agents remain anchored first.
- The grid reflows continuously from `1 -> 2 -> 3 -> 4` columns based on progress.
- Avatar size, spacing, and supporting labels scale with progress instead of flipping at a boolean boundary.

### Phase 3: Fullscreen

- Gateway cards are fully visible at the top.
- All agents are visible in the grid.
- Supporting metadata such as gateway badges and status dots reaches full prominence.

## Layout Rules

### Width / Progress

- Expansion should begin before the old level-1 travel is fully exhausted.
- A dedicated progress mapping should drive layout changes rather than `isFullScreen` alone.

### Agent Ordering

- Existing current-gateway agents should stay first.
- Additional agents from other gateways should append after them once there is room.
- This preserves continuity for the content the user was already looking at.

### Progressive Disclosure

- Status dots, names, gateway tags, and multi-gateway affordances should fade or scale in with progress.
- Existing content should morph in place rather than be replaced wholesale.

## Architecture

- Extract sidebar expansion math into a small helper that can be unit tested.
- Keep `HomeView` responsible for gesture travel and panel width interpolation.
- Keep `AgentSidebarView` responsible for progress-driven layout and visual disclosure.

## Testing

- Add unit tests for threshold math and progress mapping.
- Add unit tests for progress-driven column count.
- Run the relevant test target plus a simulator build to verify the change compiles.
