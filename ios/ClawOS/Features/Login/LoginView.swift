import SwiftUI

struct LoginView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(AppState.self) private var appState

    var onComplete: () -> Void

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                Image("login_bg")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
            }
            .mask {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                .gray, .gray, .gray, .gray, .gray,
                                .gray.opacity(0.8),
                                .gray.opacity(0.3),
                                .clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
            .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                Spacer()
                Spacer()
                Spacer()

                VStack(alignment: .leading, spacing: 6) {
                    Image("clawos_svg_logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 52, height: 52)
                        .padding(.bottom, 4)

                    Text("Welcome to\nClawOS")
                        .font(.custom("Futura-Bold", size: 34))
                        .foregroundStyle(Color(.label))
                        .lineSpacing(2)

                    Text("Your AI Agent Hub")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(Color(.secondaryLabel))
                }
                .padding(.bottom, 20)

                Button {
                    onComplete()
                } label: {
                    Text("LINK START")
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .tracking(2)
                        .foregroundStyle(colorScheme == .dark ? .black : .white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color(.label), in: Capsule())
                        .shadow(color: Color(.label).opacity(0.3), radius: 12, y: 4)
                }
                .buttonStyle(BounceButtonStyle())

                Spacer().frame(height: 16)
            }
            .padding(.horizontal, 28)
        }
        .background(Color(.systemBackground))
    }
}
