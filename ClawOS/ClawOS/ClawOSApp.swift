import SwiftUI

@main
struct ClawOSApp: App {
    @State private var appState = AppState()
    @State private var isSplashDone = false

    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .environment(appState)

                if !isSplashDone {
                    SplashView()
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
            .animation(.easeOut(duration: 0.4), value: isSplashDone)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    isSplashDone = true
                }
            }
        }
    }
}
