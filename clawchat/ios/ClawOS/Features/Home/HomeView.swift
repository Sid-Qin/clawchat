import SwiftUI

enum HomeSidebarLayering {
    case sessionList
    case sidebar
    case popup

    static func zIndex(for layer: HomeSidebarLayering) -> Double {
        switch layer {
        case .sessionList: return 0
        case .sidebar: return 1
        case .popup: return 2
        }
    }
}

enum HomeSidebarGestureMetrics {
    static let minimumDistance: CGFloat = 6
    static let axisDecisionDistance: CGFloat = 6
    static let horizontalDominanceRatio: CGFloat = 1.5
    static let edgeActivationWidth: CGFloat = 72
}

enum HomeSidebarPopupTransition {
    private static func clamped(_ progress: CGFloat) -> CGFloat {
        min(1, max(0, progress))
    }

    static func sidebarOpacity(for progress: CGFloat, suppressSidebar: Bool = false) -> Double {
        if suppressSidebar { return 0 }
        let p = min(1, clamped(progress) / 0.58)
        return Double(1 - p)
    }

    static func sidebarScale(for progress: CGFloat) -> CGFloat {
        let p = min(1, clamped(progress) / 0.72)
        return 1 - 0.06 * p
    }

    static func popupOpacity(for progress: CGFloat) -> Double {
        let p = clamped(progress)
        let normalized = max(0, min(1, (p - 0.10) / 0.90))
        return Double(normalized)
    }

    static func popupScale(for progress: CGFloat) -> CGFloat {
        let visible = CGFloat(popupOpacity(for: progress))
        return 0.94 + visible * 0.06
    }

    static func popupYOffset(for progress: CGFloat) -> CGFloat {
        let visible = CGFloat(popupOpacity(for: progress))
        return (1 - visible) * 10
    }
}

struct HomeView: View {
    @Environment(AppState.self) private var appState
    @State private var sidebarLevel: Int = 0
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging = false
    @State private var lastSnappedLevel: Int = 0
    @State private var gestureAxis: GestureAxis = .undecided
    @State private var showAgentPopup = false
    @State private var popupTransitionProgress: CGFloat = 0
    @State private var suppressSidebarDuringPopupDismiss = false

    private let hapticLight = UIImpactFeedbackGenerator(style: .light)
    private let hapticMedium = UIImpactFeedbackGenerator(style: .medium)

    private enum GestureAxis { case undecided, horizontal, vertical }

    // MARK: - Animation

    private static func settleSpring(velocity: CGFloat = 0) -> Animation {
        let speed = min(abs(velocity), 2400)
        let response = max(0.22, 0.30 - (speed / 2400) * 0.06)
        return .spring(
            response: response,
            dampingFraction: 0.86,
            blendDuration: 0.08
        )
    }

    // MARK: - Gesture Travel

    private var level1Travel: CGFloat {
        HomeSidebarMetrics.singleColumnWidth
            + HomeSidebarMetrics.sidebarLeadingPadding
            + HomeSidebarMetrics.overshootPadding
            + 2
    }

    private var level2Travel: CGFloat {
        level1Travel + HomeSidebarMetrics.secondColumnGestureTravel
    }

    private var hiddenOffset: CGFloat { -level1Travel }

    private var showsPopupLayer: Bool {
        showAgentPopup || popupTransitionProgress > 0.001
    }

    private var isOpen: Bool { sidebarLevel > 0 || showsPopupLayer }

    // MARK: - Resolved Drag State

    private var resolvedOffset: CGFloat {
        let base: CGFloat = switch sidebarLevel {
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

    private var overlayFraction: CGFloat {
        guard level1Travel > 0 else { return 0 }
        let linear = min(1, max(0, slideProgress / level1Travel))
        return linear * linear
    }

    private var listBlurRadius: CGFloat {
        guard overlayFraction > 0.08 else { return 0 }
        return min(4, overlayFraction * 4)
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

            SessionListView(isSidebarDragging: isDragging || sidebarLevel > 0)
                .blur(radius: listBlurRadius)
                .allowsHitTesting(!isOpen && !isDragging)
                .overlay {
                    if isOpen && !isDragging {
                        Color.black.opacity(
                            showsPopupLayer
                            ? max(0.10, Double(overlayFraction) * 0.12)
                            : Double(overlayFraction) * 0.12
                        )
                            .ignoresSafeArea()
                            .contentShape(Rectangle())
                            .onTapGesture { dismissAll() }
                            .transition(.opacity)
                    }
                }
                .zIndex(HomeSidebarLayering.zIndex(for: .sessionList))

            AgentSidebarView(onDismiss: { closeSidebar() })
                .frame(width: HomeSidebarMetrics.singleColumnWidth + 12)
                .padding(.top, 8)
                .padding(.bottom, 96)
                .padding(.leading, HomeSidebarMetrics.sidebarLeadingPadding)
                .offset(x: sidebarXOffset)
                .opacity(
                    HomeSidebarPopupTransition.sidebarOpacity(
                        for: popupTransitionProgress,
                        suppressSidebar: suppressSidebarDuringPopupDismiss
                    )
                )
                .scaleEffect(
                    HomeSidebarPopupTransition.sidebarScale(for: popupTransitionProgress),
                    anchor: .leading
                )
                .allowsHitTesting(
                    sidebarLevel > 0
                    && !isDragging
                    && popupTransitionProgress < 0.02
                    && !suppressSidebarDuringPopupDismiss
                )
                .zIndex(HomeSidebarLayering.zIndex(for: .sidebar))

            if showsPopupLayer {
                AgentGlassPopupView(
                    revealProgress: popupTransitionProgress,
                    onDismiss: { dismissAll() }
                )
                    .opacity(HomeSidebarPopupTransition.popupOpacity(for: popupTransitionProgress))
                    .scaleEffect(
                        HomeSidebarPopupTransition.popupScale(for: popupTransitionProgress),
                        anchor: .topLeading
                    )
                    .offset(y: HomeSidebarPopupTransition.popupYOffset(for: popupTransitionProgress))
                    .zIndex(HomeSidebarLayering.zIndex(for: .popup))
            }
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
                showAgentPopup = false
                popupTransitionProgress = 0
                suppressSidebarDuringPopupDismiss = false
            }
        }
    }

    private func presentPopup() {
        showAgentPopup = true
        popupTransitionProgress = 0
        suppressSidebarDuringPopupDismiss = false
        withAnimation(.easeOut(duration: 0.24)) {
            popupTransitionProgress = 1
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

    private func dismissAll() {
        suppressSidebarDuringPopupDismiss = true
        withAnimation(.easeIn(duration: 0.16)) {
            popupTransitionProgress = 0
            showAgentPopup = false
        }
        closeSidebar()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.34) {
            if !showAgentPopup && sidebarLevel == 0 {
                suppressSidebarDuringPopupDismiss = false
            }
        }
    }

    // MARK: - Gesture

    private var sidebarDragGesture: some Gesture {
        DragGesture(minimumDistance: HomeSidebarGestureMetrics.minimumDistance, coordinateSpace: .global)
            .onChanged { value in
                guard !showAgentPopup else { return }

                let dx = value.translation.width
                let dy = value.translation.height
                let startX = value.startLocation.x

                if gestureAxis == .undecided {
                    guard abs(dx) > HomeSidebarGestureMetrics.axisDecisionDistance
                        || abs(dy) > HomeSidebarGestureMetrics.axisDecisionDistance
                    else { return }
                    gestureAxis = abs(dx) > abs(dy) * HomeSidebarGestureMetrics.horizontalDominanceRatio
                        ? .horizontal
                        : .vertical
                    if gestureAxis == .vertical { return }
                }
                guard gestureAxis == .horizontal else { return }

                if !isDragging {
                    if sidebarLevel > 0 {
                        isDragging = true
                        lastSnappedLevel = sidebarLevel
                    } else if dx > 0, startX < HomeSidebarGestureMetrics.edgeActivationWidth {
                        isDragging = true
                        lastSnappedLevel = 0
                    } else {
                        return
                    }
                }

                dragOffset = dx

                let nowLevel = SidebarExpansionBehavior.snapLevel(
                    resolvedOffset: resolvedOffset,
                    level1Travel: level1Travel,
                    level2Travel: level2Travel,
                    previousLevel: lastSnappedLevel
                )
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
                var target = SidebarExpansionBehavior.snapLevel(
                    resolvedOffset: offset,
                    level1Travel: level1Travel,
                    level2Travel: level2Travel,
                    previousLevel: lastSnappedLevel
                )

                if v > 1000, target < 2 { target = min(2, target + 1) }
                else if v < -1000, target > 0 { target = max(0, target - 1) }

                if target >= 2 {
                    withAnimation(Self.settleSpring(velocity: v)) {
                        sidebarLevel = 1
                        dragOffset = 0
                        isDragging = false
                    }
                    presentPopup()
                    hapticMedium.impactOccurred(intensity: 0.85)
                } else {
                    if target != sidebarLevel { triggerLevelHaptic(target) }
                    withAnimation(Self.settleSpring(velocity: v)) {
                        sidebarLevel = target
                        dragOffset = 0
                        isDragging = false
                    }
                }
            }
    }

    private func triggerLevelHaptic(_ level: Int) {
        switch level {
        case 1: hapticLight.impactOccurred(intensity: 0.7)
        case 2: hapticMedium.impactOccurred(intensity: 0.85)
        default: hapticLight.impactOccurred(intensity: 0.5)
        }
    }
}
