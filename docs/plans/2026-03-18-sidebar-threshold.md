# Sidebar Threshold Smoothing Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Shorten the compact sidebar threshold and turn the compact-to-fullscreen transition into a continuous progress-driven reflow.

**Architecture:** Move the threshold and progress math into a small testable helper, then let `HomeView` use that helper for earlier width expansion. Update `AgentSidebarView` to derive columns, ordering, and supporting metadata from expansion progress instead of relying on a hard `isFullScreen` switch for major layout changes.

**Tech Stack:** SwiftUI, Swift Testing, Xcode build/test via `xcodebuild`

---

### Task 1: Extract sidebar expansion behavior

**Files:**
- Create: `clawchat/ios/ClawOS/Features/Home/SidebarExpansionBehavior.swift`
- Modify: `clawchat/ios/ClawOSTests/ClawOSTests.swift`

**Step 1: Write the failing test**

Add tests that assert:

- compact confirmation progress ends before the old level-1 travel finishes
- expansion progress starts before fullscreen mode is reached
- column count increases as progress grows

Example test cases:

```swift
@Test("sidebar 会在单列结束前开始进入扩展进度")
func sidebarExpansionStartsBeforeOldLevelOneEnds() {
    let progress = SidebarExpansionBehavior.expansionProgress(
        resolvedOffset: 70,
        level1Travel: 102,
        level2Travel: 222
    )

    #expect(progress > 0)
}
```

**Step 2: Run test to verify it fails**

Run:

```bash
xcodebuild test -project clawchat/ios/ClawOS.xcodeproj -scheme ClawOS -destination 'platform=iOS Simulator,OS=latest,name=iPhone 17 Pro' -only-testing:ClawOSTests/ClawOSTests
```

Expected: FAIL because `SidebarExpansionBehavior` does not exist yet.

**Step 3: Write minimal implementation**

Create `SidebarExpansionBehavior.swift` with helpers such as:

- `compactConfirmationTravel(level1Travel:)`
- `expansionProgress(resolvedOffset:level1Travel:level2Travel:)`
- `columnCount(for:)`
- `showsSupplementaryMetadata(for:)`

**Step 4: Run test to verify it passes**

Run the same `xcodebuild test` command.

Expected: PASS for the new sidebar behavior tests.

**Step 5: Commit**

```bash
git add clawchat/ios/ClawOS/Features/Home/SidebarExpansionBehavior.swift clawchat/ios/ClawOSTests/ClawOSTests.swift
git commit -m "refactor: extract sidebar expansion behavior"
```

### Task 2: Make HomeView expand earlier and snap more naturally

**Files:**
- Modify: `clawchat/ios/ClawOS/Features/Home/HomeView.swift`
- Test: `clawchat/ios/ClawOSTests/ClawOSTests.swift`

**Step 1: Write the failing test**

Add tests that assert:

- the fullscreen snap threshold is shorter than the current behavior
- progress reaches a meaningful non-zero value earlier in the drag

**Step 2: Run test to verify it fails**

Run:

```bash
xcodebuild test -project clawchat/ios/ClawOS.xcodeproj -scheme ClawOS -destination 'platform=iOS Simulator,OS=latest,name=iPhone 17 Pro' -only-testing:ClawOSTests/ClawOSTests
```

Expected: FAIL until `HomeView` adopts the new helper.

**Step 3: Write minimal implementation**

Update `HomeView.swift` to:

- reduce the second-stage travel distance
- start expansion progress before the old level-1 segment fully completes
- use the helper for snap thresholds and progress mapping
- slightly refine settle behavior so the final snap feels less abrupt

**Step 4: Run test to verify it passes**

Run the same `xcodebuild test` command.

Expected: PASS for the threshold behavior tests.

**Step 5: Commit**

```bash
git add clawchat/ios/ClawOS/Features/Home/HomeView.swift clawchat/ios/ClawOSTests/ClawOSTests.swift
git commit -m "feat: smooth sidebar threshold transition"
```

### Task 3: Turn AgentSidebarView into a progress-driven reflow

**Files:**
- Modify: `clawchat/ios/ClawOS/Features/Home/AgentSidebarView.swift`
- Test: `clawchat/ios/ClawOSTests/ClawOSTests.swift`

**Step 1: Write the failing test**

Add tests that assert:

- low progress uses one column
- medium progress uses intermediate columns
- high progress uses four columns
- ordered agents keep current-gateway agents first before appending others

Example helper expectation:

```swift
#expect(
    SidebarExpansionBehavior.columnCount(for: 0.18) == 2
)
```

**Step 2: Run test to verify it fails**

Run:

```bash
xcodebuild test -project clawchat/ios/ClawOS.xcodeproj -scheme ClawOS -destination 'platform=iOS Simulator,OS=latest,name=iPhone 17 Pro' -only-testing:ClawOSTests/ClawOSTests
```

Expected: FAIL until the layout logic matches the tests.

**Step 3: Write minimal implementation**

Update `AgentSidebarView.swift` to:

- derive columns from progress rather than `isFullScreen` alone
- keep current-gateway agents first, then append remaining agents
- reveal gateway cards and supplementary metadata progressively
- avoid shrink/backtrack/disappear-then-reappear behavior for existing content

**Step 4: Run test to verify it passes**

Run:

```bash
xcodebuild test -project clawchat/ios/ClawOS.xcodeproj -scheme ClawOS -destination 'platform=iOS Simulator,OS=latest,name=iPhone 17 Pro' -only-testing:ClawOSTests/ClawOSTests
```

Expected: PASS for the sidebar behavior tests and a clean build.

**Step 5: Commit**

```bash
git add clawchat/ios/ClawOS/Features/Home/AgentSidebarView.swift clawchat/ios/ClawOSTests/ClawOSTests.swift
git commit -m "feat: reflow sidebar content with expansion progress"
```

### Task 4: Final verification

**Files:**
- Modify: `clawchat/ios/ClawOS/Features/Home/HomeView.swift`
- Modify: `clawchat/ios/ClawOS/Features/Home/AgentSidebarView.swift`
- Modify: `clawchat/ios/ClawOSTests/ClawOSTests.swift`

**Step 1: Run focused tests**

```bash
xcodebuild test -project clawchat/ios/ClawOS.xcodeproj -scheme ClawOS -destination 'platform=iOS Simulator,OS=latest,name=iPhone 17 Pro' -only-testing:ClawOSTests/ClawOSTests
```

Expected: PASS.

**Step 2: Run simulator build**

```bash
xcodebuild -project clawchat/ios/ClawOS.xcodeproj -scheme ClawOS -destination 'platform=iOS Simulator,OS=latest,name=iPhone 17 Pro' build
```

Expected: `** BUILD SUCCEEDED **`

**Step 3: Commit**

```bash
git add clawchat/ios/ClawOS/Features/Home/HomeView.swift clawchat/ios/ClawOS/Features/Home/AgentSidebarView.swift clawchat/ios/ClawOSTests/ClawOSTests.swift
git commit -m "refine: shorten sidebar compact threshold"
```
