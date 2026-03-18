import SwiftUI

struct HomeView: View {
    @Environment(AppState.self) private var appState
    @State private var sidebarLevel: Int = 0
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging = false
    @State private var lastSnappedLevel: Int = 0
    @State private var gestureAxis: GestureAxis = .undecided

    private let hapticLight = UIImpactFeedbackGenerator(style: .light)
    private let hapticMedium = UIImpactFeedbackGenerator(style: .medium)

    private enum GestureAxis { case undecided, horizontal, vertical }

    // MARK: - Animation

    private static func settleSpring(velocity: CGFloat = 0) -> Animation {
        let speed = min(abs(velocity), 2200)
        let response = max(0.2, 0.28 - (speed / 2200) * 0.05)
        return .interactiveSpring(
            response: response,
            dampingFraction: 0.95,
            blendDuration: 0.02
        )
    }

    // MARK: - Layout Constants

    private var level1Travel: CGFloat {
        HomeSidebarMetrics.singleColumnWidth
            + HomeSidebarMetrics.sidebarLeadingPadding
            + HomeSidebarMetrics.overshootPadding
            + 10
    }

    private var level2Travel: CGFloat {
        level1Travel + HomeSidebarMetrics.secondColumnGestureTravel
    }

    private var hiddenOffset: CGFloat { -level1Travel }

    private var isOpen: Bool { sidebarLevel > 0 }

    // MARK: - Resolved Drag State

    private var resolvedOffset: CGFloat {
        let base: CGFloat = switch sidebarLevel {
        case 2: level2Travel
        case 1: level1Travel
        default: 0
        }
        guard isDragging else { return base }
        let raw = base + dragOffset
        if raw < 0 {
            return -Self.rubberBand(-raw, limit: 40)
        }
        if raw > level2Travel {
            return level2Travel + Self.rubberBand(raw - level2Travel, limit: 50)
        }
        return raw
    }

    private var slideProgress: CGFloat {
        min(resolvedOffset, level1Travel)
    }

    private var expansionProgress: CGFloat {
        guard resolvedOffset > level1Travel else { return 0 }
        return min(1, (resolvedOffset - level1Travel) / HomeSidebarMetrics.secondColumnGestureTravel)
    }

    private var currentSidebarWidth: CGFloat {
        let delta = HomeSidebarMetrics.doubleColumnWidth - HomeSidebarMetrics.singleColumnWidth
        return HomeSidebarMetrics.singleColumnWidth + delta * expansionProgress
    }

    private var effectiveDisplayLevel: Int {
        let offset = resolvedOffset
        if offset < 1 { return 0 }
        if offset >= level1Travel + (level2Travel - level1Travel) * HomeSidebarMetrics.secondColumnActivationProgress {
            return 2
        }
        if offset >= level1Travel * 0.3 { return 1 }
        return 0
    }

    private var overlayFraction: CGFloat {
        guard level1Travel > 0 else { return 0 }
        let linear = min(1, max(0, slideProgress / level1Travel))
        return linear * linear
    }

    private var listBlurRadius: CGFloat {
        guard overlayFraction > 0.08 else { return 0 }
        return min(1.0, overlayFraction)
    }

    private var sidebarXOffset: CGFloat {
        guard isOpen || isDragging else { return hiddenOffset }
        return hiddenOffset + slideProgress
    }

    private static func rubberBand(_ offset: CGFloat, limit: CGFloat) -> CGFloat {
        guard offset > 0, limit > 0 else { return 0 }
        return limit * (1 - exp(-offset / limit))
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .leading) {
            LinearGradient(
                colors: [appState.currentVisualTheme.pageGradientTop,
                         appState.currentVisualTheme.pageGradientBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            SessionListView(isSidebarDragging: isDragging || isOpen)
                .blur(radius: listBlurRadius)
                .allowsHitTesting(!isDragging && !isOpen)

            Color.black
                .opacity(Double(overlayFraction) * 0.12)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .allowsHitTesting(isOpen && !isDragging)
                .onTapGesture { closeSidebar() }

            AgentSidebarView(
                expansionLevel: effectiveDisplayLevel,
                onDismiss: { closeSidebar() }
            )
            .frame(width: isOpen || isDragging ? currentSidebarWidth : HomeSidebarMetrics.singleColumnWidth)
            .padding(.top, 8)
            .padding(.bottom, 96)
            .padding(.leading, HomeSidebarMetrics.sidebarLeadingPadding)
            .offset(x: sidebarXOffset)
        }
        .simultaneousGesture(sidebarDragGesture)
        .ignoresSafeArea(edges: .bottom)
        .navigationBarHidden(true)
        .onAppear {
            hapticLight.prepare()
            hapticMedium.prepare()
        }
        .onDisappear {
            if isOpen {
                sidebarLevel = 0
                dragOffset = 0
                isDragging = false
            }
        }
    }

    private func closeSidebar(velocity: CGFloat = 0) {
        withAnimation(Self.settleSpring(velocity: velocity)) {
            sidebarLevel = 0
            dragOffset = 0
            isDragging = false
        }
        hapticLight.impactOccurred(intensity: 0.5)
    }

    // MARK: - Gesture

    private var sidebarDragGesture: some Gesture {
        DragGesture(minimumDistance: 10, coordinateSpace: .global)
            .onChanged { value in
                let dx = value.translation.width
                let dy = value.translation.height
                let startX = value.startLocation.x

                if gestureAxis == .undecided {
                    guard abs(dx) > 8 || abs(dy) > 8 else { return }
                    gestureAxis = abs(dx) > abs(dy) * 1.6 ? .horizontal : .vertical
                    if gestureAxis == .vertical { return }
                }
                guard gestureAxis == .horizontal else { return }

                if !isDragging {
                    if isOpen {
                        isDragging = true
                        lastSnappedLevel = sidebarLevel
                    } else if dx > 0, startX < 48 {
                        isDragging = true
                        lastSnappedLevel = 0
                    } else {
                        return
                    }
                }

                dragOffset = dx

                let nowLevel = snapLevel(for: resolvedOffset)
                if nowLevel != lastSnappedLevel {
                    triggerLevelHaptic(nowLevel)
                    lastSnappedLevel = nowLevel
                }
            }
            .onEnded { value in
                defer { gestureAxis = .undecided }
                guard isDragging else { return }

                let v = value.velocity.width
                let offset = resolvedOffset
                var target = snapLevel(for: offset)

                if v > 1000, target < 2 { target = min(2, target + 1) }
                else if v < -1000, target > 0 { target = max(0, target - 1) }

                if target != sidebarLevel { triggerLevelHaptic(target) }

                withAnimation(Self.settleSpring(velocity: v)) {
                    sidebarLevel = target
                    dragOffset = 0
                    isDragging = false
                }
            }
    }

    private func snapLevel(for offset: CGFloat) -> Int {
        if offset < level1Travel * 0.35 { return 0 }
        if offset < level1Travel + (level2Travel - level1Travel) * HomeSidebarMetrics.secondColumnActivationProgress {
            return 1
        }
        return 2
    }

    private func triggerLevelHaptic(_ level: Int) {
        switch level {
        case 1: hapticLight.impactOccurred(intensity: 0.7)
        case 2: hapticMedium.impactOccurred(intensity: 0.85)
        default: hapticLight.impactOccurred(intensity: 0.5)
        }
    }
}
