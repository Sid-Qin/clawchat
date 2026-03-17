# iOS Chat Page Diagnostics

Date: 2026-03-17

Scope: diagnose the current chat page behavior, performance, and debugability without changing the visual style system.

## Files audited

- `ios/ClawOS/Features/Chat/ChatView.swift`
- `ios/ClawOS/Features/Chat/ChatMessageBubbleView.swift`
- `ios/ClawOS/Features/Chat/ChatInteractionPolicy.swift`
- `ios/ClawOS/Core/Services/SpeechRecognitionService.swift`
- `ios/ClawOS/Core/Services/ClawChatManager.swift`
- `ios/ClawOS/Core/Models/Session.swift`
- `ios/ClawChatKit/Sources/ClawChatKit/Chat/ChatState.swift`
- `ios/ClawOSTests/ClawOSTests.swift`

## Diagnostic hooks added

- `ios/ClawOS/Features/Chat/ChatInteractionPolicy.swift`
  - `ChatAutoScrollPolicy`
  - `ChatVoiceOverlayPolicy`
- `ios/ClawOSTests/ClawOSTests.swift`
  - tests that lock down the current auto-scroll trigger policy
  - tests that lock down the current walkie-talkie overlay hit-testing policy

These helpers intentionally preserve current behavior. They exist to make later fixes testable.

## Reproduction matrix

| Scenario | Current result | Root cause |
| --- | --- | --- |
| Tap input field while already above the latest messages | The list does not reliably jump to the newest message | `ChatView.messageArea` only scrolls on message/streaming/typing changes; input focus and keyboard changes are not bottom-follow triggers |
| Return to a chat with a saved scroll anchor, then tap input | The view may stay at the restored historical anchor instead of following the latest message | `restoreSavedScrollAnchorIfNeeded(proxy:)` restores the saved anchor, but there is no focus-triggered override |
| Keyboard appears after focus | Layout changes, but the list does not actively follow the bottom | There is no keyboard observer or keyboard-driven scroll policy |
| Tap `Speak` when keyboard is collapsed | Input focuses first instead of recording immediately | `WalkieTalkieGestureView` overlays the whole input bar and short tap routes to `isInputFocused = true` |
| Tap `Speak` when keyboard is expanded | Recording begins only after focus is dropped | `beginRecording()` always sets `isInputFocused = false` before starting speech capture |
| Long streaming conversations | Scroll and layout churn increase noticeably | `ScrollView + VStack`, per-message `GeometryReader`, full `PreferenceKey` merges, and repeated streaming scroll tasks add overhead |
| Agent messages with tool events after persistence | Tool events disappear once the live message is synced into storage | `syncLiveMessages()` persists text/reasoning only, and `MessageBubbleItem(storedMessage:)` always sets `toolEvents = []` |

## Root-cause findings

### 1. Auto-scroll and keyboard behavior

Current bottom-follow behavior is tied to four triggers only:

- rendered message count changes
- preview assistant message id changes
- streaming display text changes
- typing state changes

The current implementation does not treat either of these as follow-bottom triggers:

- input focus changes
- keyboard frame changes

This is the direct reason the latest message is not automatically revealed when the user taps the composer.

There is a second interaction with saved scroll anchors:

- `restoreSavedScrollAnchorIfNeeded(proxy:)` restores the last visible message when re-entering the chat
- that restoration is correct for reading history
- but there is no explicit rule for when composer intent should override history intent

The missing policy decision is:

- when should the app respect the saved anchor
- when should the app force follow-bottom because the user is clearly trying to continue the conversation

### 2. Voice input and hit-testing

The current input bar stacks `WalkieTalkieGestureView` over the entire composer surface. While the composer is idle and unfocused, the overlay is enabled. That means:

- the visible `Speak` button does not own the tap
- short tap focuses the input
- long press starts recording

This is why the collapsed composer feels like it ignores the `Speak` affordance.

The second voice issue is independent from hit-testing:

- `beginRecording()` always drops input focus before starting audio capture
- therefore, if the keyboard is already open, tapping record first collapses the keyboard and only then enters recording mode

This behavior may be intentional for the original walkie-talkie design, but it conflicts with the expected direct-record flow.

### 3. Message list performance

The current list is functionally correct for short chats, but several hotspots will scale poorly:

- `ScrollView + VStack` renders the whole conversation eagerly instead of lazily
- every message installs its own `GeometryReader` via `messageFrameReporter(for:)`
- all frame dictionaries are merged through a single `PreferenceKey`
- `renderedMessages.map(\\.id)` creates a new array every update and re-triggers scroll-anchor restoration checks
- streaming output schedules repeated scroll work while the typewriter effect is also updating text

None of these alone is catastrophic, but together they explain why long or highly streaming conversations may feel less stable than the rest of the app.

### 4. Agent bubble information density and persistence gaps

The current agent bubble is visually simple, but functionally dense:

- reasoning, tool events, attachments, and text are stacked with no collapse/expand behavior
- long reasoning is truncated at six lines with no way to inspect more
- tool events are shown as a flat list with generic phase icons
- there is no per-message agent avatar, so long transcripts rely almost entirely on alignment and color for scanning

The more important functional issue is persistence:

- live `ChatMessage` instances can carry `toolEvents`
- persisted `StoredMessage` does not currently store tool events
- `syncLiveMessages()` writes `text` and `reasoning`, but not tool events
- `MessageBubbleItem(storedMessage:)` explicitly rebuilds bubbles with `toolEvents = []`

This means part of the assistant output model disappears after live rendering completes.

## Priority matrix

### P0: fix next

- Define a real follow-bottom policy for composer focus and keyboard presentation.
- Separate `Speak` tap behavior from the idle overlay so the visible record affordance can directly record.
- Decide whether recording should preserve keyboard state, or dismiss it only after recording is confirmed.

### P1: stabilize immediately after P0

- Add explicit decision helpers for scroll intent and input intent, then wire them through `ChatView`.
- Persist assistant tool events alongside stored messages so the bubble does not lose semantic content after sync.
- Add more focused regression tests for scroll/focus/recording state transitions.

### P2: performance cleanup

- Replace the eager `VStack` with `LazyVStack`.
- Reduce per-message geometry work or narrow it to messages near the viewport.
- Coalesce streaming scroll scheduling and anchor updates.
- Gate continuous typing animations more carefully.

### P3: interaction polish without style redesign

- Add expand/collapse controls for reasoning and long tool-event sections.
- Improve message scanning with subtle structural cues, not theme changes.
- Add debug-friendly identifiers for composer states and message bubble blocks.

## Recommended implementation order

1. Introduce a single bottom-follow policy that distinguishes:
   - new incoming content
   - restored reading position
   - explicit reply intent from composer focus
2. Split composer hit-testing so the text field surface and `Speak` button do not share the same overlay ownership.
3. Make recording state transitions explicit and testable:
   - idle
   - focusing text
   - recording
   - finalizing transcript
4. Persist assistant semantic payloads before tuning bubble interactions.
5. Optimize message list rendering only after behavior is deterministic.

## Verification notes

The new diagnostic tests for chat scroll policy and voice overlay policy pass.

Running the full `ClawOSTests` suite still reports unrelated failures in the pre-existing session swipe tests under `SessionSwipeBehavior`, so chat-page diagnostics should be verified with targeted tests until that separate issue is resolved.
