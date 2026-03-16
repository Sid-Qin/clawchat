import SwiftUI

struct HomeView: View {
    @Environment(AppState.self) private var appState
    @State private var isSidebarOpen = false
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging = false

    private let totalWidth: CGFloat = 82

    private var resolvedOffset: CGFloat {
        if isDragging {
            if isSidebarOpen {
                return totalWidth + min(0, dragOffset)
            } else {
                return min(totalWidth, max(0, dragOffset))
            }
        }
        return isSidebarOpen ? totalWidth : 0
    }

    private var progress: CGFloat {
        min(1, max(0, resolvedOffset / totalWidth))
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
                isSidebarDragging: isDragging || isSidebarOpen,
                onMenuTap: {
                    withAnimation(.interpolatingSpring(stiffness: 400, damping: 35)) {
                        isSidebarOpen = true
                    }
                }
            )
            .blur(radius: progress * 6)
            .scaleEffect(1.0 - progress * 0.03)

            Color.black
                .opacity(Double(progress) * 0.15)
                .ignoresSafeArea()
                .allowsHitTesting(isSidebarOpen && !isDragging)
                .onTapGesture {
                    withAnimation(.interpolatingSpring(stiffness: 400, damping: 35)) {
                        isSidebarOpen = false
                    }
                }

            AgentSidebarView(onDismiss: {
                withAnimation(.interpolatingSpring(stiffness: 400, damping: 35)) {
                    isSidebarOpen = false
                }
            })
            .frame(width: 70)
            .shadow(color: .black.opacity(0.15 * Double(progress)), radius: 20, x: 6, y: 0)
            .padding(.top, 12)
            .padding(.bottom, 96)
            .padding(.leading, 10)
            .offset(x: resolvedOffset - totalWidth)
        }
        .simultaneousGesture(dragGesture)
        .ignoresSafeArea(edges: .bottom)
        .navigationBarHidden(true)
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 10, coordinateSpace: .global)
            .onChanged { value in
                let dx = value.translation.width
                let dy = value.translation.height

                if !isDragging {
                    guard abs(dx) > abs(dy) * 1.2 else { return }

                    if isSidebarOpen {
                        isDragging = true
                    } else if dx > 0 {
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

                withAnimation(.interpolatingSpring(stiffness: 400, damping: 35)) {
                    if isSidebarOpen {
                        if final < totalWidth * 0.5 || v < -200 {
                            isSidebarOpen = false
                        }
                    } else {
                        if final > totalWidth * 0.4 || v > 200 {
                            isSidebarOpen = true
                        }
                    }
                    dragOffset = 0
                    isDragging = false
                }
            }
    }
}
