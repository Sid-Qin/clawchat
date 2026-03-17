import SwiftUI

struct HomeView: View {
    @Environment(AppState.self) private var appState
    @State private var isSidebarOpen = false
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging = false

    private static let settleSpring: Animation = .interpolatingSpring(
        stiffness: 280, damping: 28
    )

    private var resolvedOffset: CGFloat {
        let travel = HomeSidebarMetrics.travelWidth
        if isDragging {
            let raw: CGFloat
            if isSidebarOpen {
                raw = travel + min(0, dragOffset)
            } else {
                raw = max(0, dragOffset)
            }
            return min(travel, Self.rubberBand(raw, limit: travel))
        }
        return isSidebarOpen ? travel : 0
    }

    private var progress: CGFloat {
        min(1, max(0, resolvedOffset / HomeSidebarMetrics.travelWidth))
    }

    private static func rubberBand(_ offset: CGFloat, limit: CGFloat) -> CGFloat {
        guard offset > 0, limit > 0 else { return offset }
        if offset <= limit { return offset }
        let overshoot = offset - limit
        return limit + overshoot / (1 + overshoot / (limit * 0.4))
    }

    var body: some View {
        ZStack(alignment: .leading) {
            LinearGradient(
                colors: [appState.currentVisualTheme.pageGradientTop, appState.currentVisualTheme.pageGradientBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            SessionListView(
                isSidebarDragging: isDragging || isSidebarOpen
            )
            .blur(radius: progress * 6)

            Color.black
                .opacity(Double(progress) * 0.15)
                .ignoresSafeArea()
                .allowsHitTesting(isSidebarOpen && !isDragging)
                .onTapGesture {
                    withAnimation(Self.settleSpring) {
                        isSidebarOpen = false
                    }
                }

            AgentSidebarView(onDismiss: {
                withAnimation(Self.settleSpring) {
                    isSidebarOpen = false
                }
            })
            .frame(width: HomeSidebarMetrics.sidebarWidth)
            .padding(.top, 12)
            .padding(.bottom, 96)
            .padding(.leading, HomeSidebarMetrics.sidebarLeadingPadding)
            .offset(x: resolvedOffset - HomeSidebarMetrics.travelWidth)
        }
        .simultaneousGesture(dragGesture)
        .sensoryFeedback(.impact(flexibility: .soft), trigger: isSidebarOpen)
        .ignoresSafeArea(edges: .bottom)
        .navigationBarHidden(true)
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 12, coordinateSpace: .global)
            .onChanged { value in
                let dx = value.translation.width
                let dy = value.translation.height
                let startX = value.startLocation.x

                if !isDragging {
                    guard abs(dx) > abs(dy) * 1.4 else { return }

                    if isSidebarOpen {
                        isDragging = true
                    } else if dx > 0 && startX < 44 {
                        isDragging = true
                    }
                }

                if isDragging {
                    dragOffset = dx
                }
            }
            .onEnded { value in
                guard isDragging else { return }

                let v = value.velocity.width
                let final = resolvedOffset
                let travel = HomeSidebarMetrics.travelWidth

                withAnimation(Self.settleSpring) {
                    if isSidebarOpen {
                        if final < travel * 0.45 || v < -400 {
                            isSidebarOpen = false
                        }
                    } else {
                        if final > travel * 0.45 || v > 400 {
                            isSidebarOpen = true
                        }
                    }
                    dragOffset = 0
                    isDragging = false
                }
            }
    }
}
