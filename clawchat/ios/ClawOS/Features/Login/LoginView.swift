import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(AppState.self) private var appState

    var onComplete: () -> Void

    @State private var showOtherOptions = false

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

                VStack(alignment: .leading, spacing: 4) {
                    Image("clawos_svg_logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                        .padding(.bottom, 2)

                    Text("Welcome to\nClawOS")
                        .font(.system(size: 32, weight: .bold, design: .default))
                        .foregroundStyle(Color(.label))
                        .lineSpacing(1)

                    Text("Your AI Agent Hub")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color(.secondaryLabel))
                }
                .padding(.bottom, 20)

                VStack(spacing: 12) {
                    Button {
                        onComplete()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "g.circle.fill")
                                .font(.system(size: 20))
                            Text("使用 Google 登录")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundStyle(Color(.label))
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(
                            colorScheme == .dark
                                ? Color.white.opacity(0.12)
                                : Color(.systemBackground),
                            in: Capsule()
                        )
                        .overlay(
                            Capsule().stroke(Color(.separator), lineWidth: colorScheme == .dark ? 0 : 0.5)
                        )
                    }
                    .buttonStyle(BounceButtonStyle())

                    Button {
                        showOtherOptions = true
                    } label: {
                        Text("其他登录方式")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color(.label))
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(
                                colorScheme == .dark
                                    ? Color.white.opacity(0.12)
                                    : Color.black.opacity(0.06),
                                in: Capsule()
                            )
                    }
                    .buttonStyle(BounceButtonStyle())
                }

                Spacer().frame(height: 16)
            }
            .padding(.horizontal, 28)
        }
        .background(Color(.systemBackground))
        .sheet(isPresented: $showOtherOptions) {
            OtherLoginSheet(onComplete: onComplete)
                .environment(appState)
                .presentationDetents([.height(260)])
                .presentationDragIndicator(.visible)
        }
    }
}

private struct OtherLoginSheet: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    var onComplete: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("选择登录方式")
                .font(.system(size: 18, weight: .semibold))
                .padding(.top, 24)

            Spacer().frame(height: 8)

            SignInWithAppleButton(.signIn) { _ in
            } onCompletion: { _ in
                dismiss()
                onComplete()
            }
            .signInWithAppleButtonStyle(
                colorScheme == .dark ? .white : .black
            )
            .frame(height: 52)
            .clipShape(Capsule())

            Button {
                dismiss()
                onComplete()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "envelope.fill")
                        .font(.system(size: 17))
                    Text("使用邮箱登录")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundStyle(Color(.label))
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    colorScheme == .dark
                        ? Color.white.opacity(0.12)
                        : Color.black.opacity(0.06),
                    in: Capsule()
                )
            }
            .buttonStyle(BounceButtonStyle())

            Spacer()
        }
        .padding(.horizontal, 28)
    }
}
