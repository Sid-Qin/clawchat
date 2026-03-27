# iOS Home Session Discovery UIUX Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Make the iOS Home screen answer three questions faster — what context the user is in, how to find a session, and which session/agent to act on next — without changing navigation, chat, or pairing flows.

**Architecture:** Polish the existing `HomeView` / `SessionListView` / `AgentStripView` surface in place. Reuse the `AppVisualTheme` token system for consistency. Extract tiny view helpers only when they reduce hard-coded UI behavior or duplicated avatar logic. No new state management, no new navigation patterns.

**Tech Stack:** SwiftUI, `@Observable`, `AppVisualTheme`, `adaptiveGlass`, Xcode `xcodebuild`

---

## Cross-Cutting Constraints

- Keep product behavior, navigation, and information architecture unchanged.
- Reuse `AppVisualTheme` tokens (`rowFill`, `rowStroke`, `softFill`, `accent`, etc.) instead of hard-coding colors.
- Do not alter `AgentDragCoordinator` drag/merge/reorder logic; only change the visual feedback and affordance layers.
- Do not change the avatar resolution priority (custom disk > bundle > default); only unify the rendering call site.
- All changes must look correct in both light and dark mode, and across all four theme variants (neutral, eva00, eva01, eva02).
- Validate on at least one narrow iPhone simulator (e.g. iPhone SE) and one standard width (e.g. iPhone 16 Pro).

## Non-Goals

- Do not redesign the chat surface.
- Do not redesign the pairing / onboarding flow.
- Do not change the tab structure or main navigation.
- Do not introduce a new design system or theme layer.
- Do not add new features (e.g. swipe actions, new session categories).

---

### Task 1: Improve the header bar control strip

**Files:**
- Modify: `ios/ClawOS/Features/Home/HomeView.swift`

**What to fix:**

The current header bar has three issues:
1. The search field is locked to `frame(width: 100)` — too narrow, feels like a stub.
2. Search focus uses `DispatchQueue.main.asyncAfter(deadline: .now() + 0.15)` — brittle timer hack.
3. The gateway button is icon-only with no state indication; users cannot tell at a glance which gateway is active or whether they are connected.

**Step 1: Widen the search capsule**

Replace the fixed-width search field with a flexible layout that expands to fill available header space while keeping gateway and new-session buttons visible:

- Remove `.frame(width: 100)` from the search `TextField`.
- Let the search capsule fill the space between gateway picker and new-session button naturally.
- Keep the expand/collapse animation and glass capsule treatment.

**Step 2: Remove the timer-based focus hack**

Replace the `DispatchQueue.main.asyncAfter` focus call with a reactive approach:

- Use `.onChange(of: isSearchExpanded)` to set `isSearchFocused = true` when `isSearchExpanded` becomes `true`, or use `.onAppear` on the expanded search branch.
- Remove the `asyncAfter` call entirely.

**Step 3: Add minimal gateway context**

Make the gateway button more legible without turning it into a full status bar:

- Show the `connectionDot` (which already exists but is unused) alongside the gateway icon to indicate connection state.
- If a gateway name is short enough, show a truncated label beneath or beside the icon; otherwise keep icon-only but with the dot.

**Step 4: Verify**

- Search capsule fills available width and does not overlap other controls.
- Focus happens reliably without timer.
- Gateway shows connection state at a glance.
- All four themes, light and dark, look correct.

**Acceptance criteria:**
- No fixed-width constraint on the search field.
- No `asyncAfter` for search focus.
- Gateway connection state visible without opening the menu.

---

### Task 2: Improve session row readability and surface consistency

**Files:**
- Modify: `ios/ClawOS/Features/Home/SessionListView.swift`
- Modify: `ios/ClawOS/Core/Theme/AppVisualTheme.swift` (only if a missing token is needed)

**What to fix:**

1. Session rows sit directly on the gradient background with no surface treatment — they blend into the page instead of reading as distinct items.
2. The avatar rendering in `SessionRowView.agentAvatar` duplicates the same priority chain as `AgentAvatarView`, `StripAvatarView`, and `AvatarViewHelper` — four separate copies.
3. Empty state and search-empty state use the same visual treatment, losing an opportunity to guide the user differently.

**Step 1: Apply row surface**

Add a subtle surface treatment to each session row using the existing theme tokens:

- Apply `appState.currentVisualTheme.rowFill` as a background and `rowStroke` as a thin border or separator on `SessionRowView`.
- Use a rounded rectangle with `AppTheme.Radius.md` to keep it consistent with the glass language elsewhere.
- Ensure it works in all four themes and both color schemes.

**Step 2: Unify avatar rendering**

Replace the inline `agentAvatar` function in `SessionRowView` with the existing `AgentAvatarView` component from `ChatMessageBubbleView.swift`:

- `AgentAvatarView` already handles the same priority chain (custom > bundle > default) and accepts `size` and `theme` parameters.
- Remove the duplicated `agentAvatar(_:size:)` function from `SessionRowView`.

**Step 3: Differentiate empty states**

Split the current `emptyState` into two distinct presentations:

- **No sessions at all**: Emphasize "start a new conversation" with a clear CTA direction (e.g. point toward the new-session button).
- **Search returned nothing**: Emphasize "try different keywords" with the search icon, and keep it lighter/more transient in feel.

**Step 4: Verify**

- Session rows have visible surface treatment in all themes.
- Avatar rendering uses the shared `AgentAvatarView`.
- The two empty states are visually distinct and contextually helpful.

**Acceptance criteria:**
- Session rows use theme `rowFill` / `rowStroke` tokens.
- No duplicated avatar resolution logic in `SessionRowView`.
- Empty state and search-empty state are visually and textually different.

---

### Task 3: Improve Agent Strip affordance and remove dead CTA

**Files:**
- Modify: `ios/ClawOS/Features/Home/AgentStripView.swift`
- Modify: `ios/ClawOS/Features/Home/StripAvatarView.swift`

**What to fix:**

1. The difference between a selected single agent and a selected group is hard to see — both rely on a thin 1.5pt selection ring that is easy to miss.
2. Long-press to enter edit mode has no discoverability hint; users must already know about it.
3. The `Add` button at the end of the strip is `disabled(true)` and `opacity(0.4)` — a dead CTA that signals broken functionality.

**Step 1: Strengthen selection and group indicators**

In `StripAvatarView`:

- For selected single agents, make the selection ring slightly more prominent: increase from 1.5pt to 2pt and use the accent color at higher opacity.
- For groups, add a small visual badge or count indicator (e.g. a tiny number showing how many agents are in the group) so groups are distinguishable from singles at a glance, not only by the 2x2 grid thumbnail.

**Step 2: Add edit-mode affordance**

In `AgentStripView`:

- When the strip has more than one item and the user has not entered edit mode in this session, show a subtle one-time hint (e.g. a small "hold to edit" tooltip-style label that appears once and auto-dismisses). This is a lightweight affordance, not a full onboarding flow.
- Alternatively, if a tooltip feels too heavy for phase 1, at minimum make the jiggle animation more deliberate by slightly increasing the jiggle amplitude so edit mode looks intentional, not glitchy.

**Step 3: Remove the dead Add button**

- Remove the `addButton` view and its reference in the `HStack`.
- Remove the rendered `Add` placeholder control and any disconnected presentation state tied only to that dead CTA.

**Step 4: Verify**

- Selected agent vs group is easier to distinguish.
- Edit mode has at least one improved affordance signal.
- No disabled/dead CTA visible in the strip.
- Drag, merge, reorder, and folder behaviors still work correctly.

**Acceptance criteria:**
- Selection ring is visually stronger.
- Groups have a visible count or distinguishing mark beyond the grid thumbnail.
- The `Add` placeholder button is removed from the rendered strip.
- All drag/edit/merge interactions remain functional.

---

### Task 4: Unify theme token usage across Home

**Files:**
- Modify: `ios/ClawOS/Features/Home/HomeView.swift`
- Modify: `ios/ClawOS/Features/Home/SessionListView.swift`
- Modify: `ios/ClawOS/Features/Home/AgentStripView.swift`
- Modify: `ios/ClawOS/Features/Home/StripAvatarView.swift`

**What to fix:**

Several places in the Home surface use raw system colors (`Color(.systemGray3)`, `Color(.secondaryLabel)`, `.ultraThinMaterial` directly) instead of the theme tokens from `AppVisualTheme`. This causes visual inconsistency when switching between the four theme variants.

**Step 1: Audit and replace**

Walk through `HomeView`, `SessionListView`, `AgentStripView`, and `StripAvatarView` and replace raw system color references with the appropriate `AppVisualTheme` token where a semantic match exists:

- `Color(.systemGray3)` for placeholders → `appState.currentVisualTheme.softStroke` or similar
- `Color(.secondaryLabel)` for secondary text → keep where it is truly neutral, but replace where it should track the theme accent or card color
- `.ultraThinMaterial` used directly in `StripAvatarView` group background → use `adaptiveGlass` for consistency with the rest of the glass system
- Badge colors (`Color(.label)` for unread capsule background) → evaluate if these should use the theme accent instead

**Step 2: Verify theme consistency**

- Switch between all four themes (neutral, eva00, eva01, eva02) in both light and dark mode.
- The Home page header, session list, and agent strip should all feel like one cohesive surface, not a mix of system defaults and themed elements.

**Acceptance criteria:**
- No raw system color used where a semantic theme token exists and fits.
- All four themes render the Home surface consistently.
- No regressions in light/dark contrast or readability.

---

### Task 5: Capture before/after evidence and verify

**Files:**
- All files modified in Tasks 1-4

**Step 1: Capture before screenshots**

Before starting implementation (or from the current commit baseline), capture screenshots for:

- Default Home with sessions (light + dark)
- Expanded search (light + dark)
- Search with no results
- Agent strip with selected single agent
- Agent strip with selected group
- Agent strip in edit mode
- Empty Home (no sessions)
- At least one narrow iPhone width (SE or similar)

**Step 2: Implement Tasks 1-4**

Execute the implementation tasks in order.

**Step 3: Capture after screenshots**

Repeat the same screenshot set after implementation.

**Step 4: Run verification**

```bash
xcodebuild test -project ios/ClawOS.xcodeproj -scheme ClawOS -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:ClawOSTests
```

**Step 5: Broader test run**

```bash
xcodebuild test -project ios/ClawOS.xcodeproj -scheme ClawOS -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

**Step 6: Review the diff**

Check for:
- Unintended changes to drag/merge/reorder behavior
- Theme regressions in any of the four variants
- Avatar rendering correctness
- Layout issues on narrow devices

**Step 7: Request independent review**

Dispatch a code-review subagent against the final diff, fix important findings, then rerun verification.

**Acceptance criteria:**
- Before/after screenshots demonstrate visible improvement in readability, affordance, and surface consistency.
- All existing tests pass.
- Independent review does not surface critical or important issues.
