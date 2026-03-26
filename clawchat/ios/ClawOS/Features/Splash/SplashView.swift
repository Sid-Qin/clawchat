import SwiftUI

struct SplashView: View {
    @Environment(AppState.self) private var appState
    @State private var rotation: Double = 0

    var body: some View {
        GeometryReader { geo in
            let offsetY = SplashSpinSpec.verticalOffset(for: geo.size.height)

            Color(.systemBackground)
                .ignoresSafeArea()
                .overlay(
                    ZStack {
                        Image("clawos_logo_text")
                            .resizable()
                            .renderingMode(.template)
                            .scaledToFit()
                            .foregroundStyle(.primary)
                            .frame(width: SplashSpinSpec.logoSize, height: SplashSpinSpec.logoSize)

                        Group {
                            if appState.selectedVisualThemeID == .neutral {
                                Image("clawos_icon_spin")
                                    .resizable()
                                    .scaledToFit()
                            } else {
                                Image("clawos_icon_spin")
                                    .resizable()
                                    .renderingMode(.template)
                                    .scaledToFit()
                                    .foregroundStyle(appState.currentVisualTheme.accent)
                            }
                        }
                        .frame(width: SplashSpinSpec.logoSize, height: SplashSpinSpec.logoSize)
                        .rotationEffect(.degrees(rotation), anchor: SplashSpinSpec.iconAnchor)
                    }
                    .offset(y: offsetY)
                )
        }
        .onAppear {
            withAnimation(.easeInOut(duration: SplashSpinSpec.rotationDuration)) {
                rotation = 360
            }
        }
    }
}

#Preview {
    SplashView()
        .environment(AppState())
}
