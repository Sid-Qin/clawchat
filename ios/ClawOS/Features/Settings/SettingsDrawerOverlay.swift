import SwiftUI

struct SettingsDrawerOverlay: View {
    @Environment(AppState.self) private var appState
    
    var body: some View {
        GeometryReader { proxy in
            let screenWidth = proxy.size.width
            let progress = appState.effectiveSettingsProgress
            let offset = screenWidth * (1 - progress)
            
            ZStack(alignment: .trailing) {
                // Dimming background (moved here so it sits right under the drawer and responds accurately)
                Color.white.opacity(0.85 * max(0, (progress - 0.3) / 0.7))
                    .ignoresSafeArea()
                    .opacity(progress > 0 ? 1 : 0)
                    .allowsHitTesting(progress > 0)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            appState.showSettingsDrawer = false
                        }
                    }
                
                SettingsView()
                    .environment(appState)
                    .frame(width: screenWidth)
                    .frame(maxHeight: .infinity)
                    // The background color of SettingsView is light gray, we apply opacity to it
                    .background(Color(uiColor: .systemGroupedBackground))
                    .opacity(max(0, (progress - 0.5) / 0.5)) 
                    .offset(x: offset)
                    .shadow(color: .black.opacity(0.05), radius: 10, x: -5, y: 0)
                    .allowsHitTesting(progress == 1.0)
                    .highPriorityGesture(
                        DragGesture()
                            .onChanged { value in
                                // Dragging right to dismiss
                                let translation = value.translation.width
                                if translation > 0 {
                                    appState.interactiveSettingsProgress = max(0, 1.0 - (translation / screenWidth))
                                }
                            }
                            .onEnded { value in
                                let velocity = value.velocity.width
                                let translation = value.translation.width
                                
                                if velocity > 500 || translation > screenWidth * 0.3 {
                                    let generator = UIImpactFeedbackGenerator(style: .light)
                                    generator.impactOccurred()
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                        appState.interactiveSettingsProgress = nil
                                        appState.showSettingsDrawer = false
                                    }
                                } else {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        appState.interactiveSettingsProgress = nil
                                        appState.showSettingsDrawer = true
                                    }
                                }
                            }
                    )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
        }
    }
}
