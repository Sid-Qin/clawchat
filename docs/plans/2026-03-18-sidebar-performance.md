# Sidebar Drag Performance Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Make sidebar dragging feel stable and native by keeping compact content fixed during drag and only mounting fullscreen content after the sidebar settles into level 2.

**Architecture:** Keep width interpolation and snapping in `HomeView`, but stop using drag progress to switch sidebar content. Move the visual-state rule into `SidebarExpansionBehavior`, then let `HomeView` and `AgentSidebarView` both derive a cheap compact-vs-fullscreen mode from that shared helper.

**Tech Stack:** SwiftUI, Swift Testing, Xcode `xcodebuild`

---

### Task 1: Add a testable visual-state helper

**Files:**
- Modify: `clawchat/ios/ClawOS/Features/Home/SidebarExpansionBehavior.swift`
- Modify: `clawchat/ios/ClawOSTests/ClawOSTests.swift`

**Step 1: Write the failing test**

Add tests that assert:

- dragging does not allow fullscreen content even if the target level is 2
- settled level 2 does allow fullscreen content

Example:

```swift
@Test("sidebar 拖动中不会提前显示全屏内容")
func sidebarFullscreenContentWaitsUntilSettle() {
    #expect(
        SidebarExpansionBehavior.showsFullScreenContent(
            sidebarLevel: 2,
            isDragging: true
        ) == false
    )
}
```

**Step 2: Run test to verify it fails**

Run:

```bash
xcodebuild test -project clawchat/ios/ClawOS.xcodeproj -scheme ClawOS -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:ClawOSTests/sidebarFullscreenContentWaitsUntilSettle
```

Expected: FAIL because the helper does not exist yet.

**Step 3: Write minimal implementation**

Add:

- `showsFullScreenContent(sidebarLevel:isDragging:)`

**Step 4: Run test to verify it passes**

Run the same command again.

Expected: PASS.

### Task 2: Stop drag-time visual churn in `HomeView`

**Files:**
- Modify: `clawchat/ios/ClawOS/Features/Home/HomeView.swift`
- Test: `clawchat/ios/ClawOSTests/ClawOSTests.swift`

**Step 1: Write the failing test**

Add a test that asserts compact visuals are preserved while dragging.

**Step 2: Run test to verify it fails**

Run:

```bash
xcodebuild test -project clawchat/ios/ClawOS.xcodeproj -scheme ClawOS -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:ClawOSTests
```

Expected: FAIL until `HomeView` stops deriving visual chrome from `expansionProgress`.

**Step 3: Write minimal implementation**

Update `HomeView.swift` to:

- derive sidebar content mode from settled state instead of `effectiveDisplayLevel`
- keep compact bottom padding during drag
- keep divider opacity stable during drag
- pass drag state into `AgentSidebarView`

**Step 4: Run test to verify it passes**

Run the same test command.

Expected: PASS.

### Task 3: Only mount fullscreen content after settle

**Files:**
- Modify: `clawchat/ios/ClawOS/Features/Home/AgentSidebarView.swift`
- Test: `clawchat/ios/ClawOSTests/ClawOSTests.swift`

**Step 1: Write the failing test**

Use the helper expectations from Task 1 so the view can rely on a fixed compact/fullscreen state.

**Step 2: Run test to verify it fails**

Run the sidebar-related test subset.

**Step 3: Write minimal implementation**

Update `AgentSidebarView.swift` to:

- remove drag-progress-driven content opacity logic
- show only `narrowLayer` while dragging or while settled below level 2
- show `fullScreenLayer` only when settled in level 2
- disable scroll interaction while dragging
- use a small opacity transition only when switching settled states

**Step 4: Run test to verify it passes**

Run the same test command.

Expected: PASS.

### Task 4: Verify build and recent files

**Files:**
- Modify: `clawchat/ios/ClawOS/Features/Home/HomeView.swift`
- Modify: `clawchat/ios/ClawOS/Features/Home/AgentSidebarView.swift`
- Modify: `clawchat/ios/ClawOS/Features/Home/SidebarExpansionBehavior.swift`
- Modify: `clawchat/ios/ClawOSTests/ClawOSTests.swift`

**Step 1: Run targeted tests**

```bash
xcodebuild test -project clawchat/ios/ClawOS.xcodeproj -scheme ClawOS -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:ClawOSTests
```

**Step 2: Run simulator build**

```bash
xcodebuild build -project clawchat/ios/ClawOS.xcodeproj -scheme ClawOS -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

**Step 3: Run lint/diagnostics check**

Check `HomeView.swift` and `AgentSidebarView.swift` diagnostics.
