# Sidebar Drag Performance Design

**Goal:** Make sidebar dragging feel more stable, higher-FPS, and more native by keeping live drag work minimal.

## Problem

The current sidebar interaction does too much during drag:

- `HomeView` continuously changes sidebar width and several visual details from `expansionProgress`.
- `AgentSidebarView` can switch between compact and fullscreen content while the finger is still moving.
- Fullscreen-only content includes additional `ScrollView`, `LazyVGrid`, and `glassEffect` cards, which are heavier than the compact column.

This creates a drag path that feels visually busy and less stable than a native drawer.

## Design Principles

- Keep drag work cheap and predictable.
- Do not re-layout sidebar content while the user is still dragging.
- Only change the outer shell during drag: width, position, and session push.
- Defer fullscreen-only content until the sidebar has actually settled into level 2.
- Prefer fixed visual states over progress-driven content transitions.

## Interaction Model

### Phase 0: Closed

- Sidebar is offscreen.

### Phase 1: Live Compact Drag

- As the user drags, the sidebar shell expands and pushes the session list.
- Sidebar content remains the compact single-column view.
- No fullscreen cards, multi-column grid, or metadata fade should appear during this phase.

### Phase 2: Settled Fullscreen

- After release, if snapping resolves to level 2, the outer shell finishes its settle animation.
- Only then does the sidebar switch to the fullscreen content layer.
- The switch should be a simple fade, not a motion-heavy transition.

## Architecture

- Add a small helper in `SidebarExpansionBehavior` that defines whether fullscreen content is allowed for the current interaction state.
- Keep `snapLevel` and width interpolation in `HomeView`.
- Replace progress-driven content switching in `AgentSidebarView` with a binary visual mode:
  - compact content while dragging or while settled below level 2
  - fullscreen content only after settled level 2
- Reduce drag-time layout churn in `HomeView` by deriving divider opacity and bottom padding from the settled visual mode rather than `expansionProgress`.

## Testing

- Add unit tests for the visual-mode helper:
  - dragging never shows fullscreen content early
  - settled level 2 does show fullscreen content
- Run targeted sidebar tests, then a simulator build.
