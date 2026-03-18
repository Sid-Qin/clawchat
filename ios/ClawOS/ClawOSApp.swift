import SwiftUI

@main
struct ClawOSApp: App {
    @State private var appState = AppState()
    @State private var isSplashDone = false
    @State private var showSplash = false
    @State private var showLogin: Bool?
    @AppStorage("clawos_logged_in_v4") private var hasLoggedIn = false

    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .environment(appState)
                    .allowsHitTesting(!appState.showPairing)
                    .opacity(isSplashDone ? 1 : 0)

                if showSplash {
                    SplashView()
                        .environment(appState)
                        .zIndex(1)
                }

                if showLogin == true {
                    LoginView {
                        handleLoginComplete()
                    }
                    .environment(appState)
                    .zIndex(2)
                }

                PairingOverlay()
                    .environment(appState)
                    .zIndex(3)
            }
            .background {
                LinearGradient(
                    colors: [
                        appState.currentVisualTheme.pageGradientTop,
                        appState.currentVisualTheme.pageGradientBottom,
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            }
            .onAppear {
                if hasLoggedIn {
                    showLogin = false
                    showSplash = true
                    finishSplashAfterDelay()
                } else {
                    showLogin = true
                }
            }
            .task {
                appState.clawChatManager.appState = appState
                await appState.clawChatManager.autoConnect()
                if isSplashDone {
                    checkPairingState()
                }
            }
            .onChange(of: appState.clawChatManager.linkState) { _, newState in
                if case .connected = newState {
                    withAnimation { appState.showPairing = false }
                }
            }
        }
    }

    private func handleLoginComplete() {
        // Mock 模式：不持久化 hasLoggedIn，每次冷启动都弹登录
        // 正式接入后取消注释: hasLoggedIn = true

        showSplash = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeOut(duration: 0.35)) {
                showLogin = false
            }
        }

        finishSplashAfterDelay()
    }

    private func finishSplashAfterDelay() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            withAnimation(.easeOut(duration: 0.4)) {
                showSplash = false
                isSplashDone = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                checkPairingState()
            }
        }
    }

    private func checkPairingState() {
        if appState.clawChatManager.linkState == .unpaired {
            withAnimation { appState.showPairing = true }
        }
    }
}
