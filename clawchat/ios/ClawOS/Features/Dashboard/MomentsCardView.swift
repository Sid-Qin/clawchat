import SwiftUI

struct MomentsCardView: View {
    let moment: MockMoment
    let colorScheme: ColorScheme
    var theme: AppVisualTheme?

    @State private var isLiked: Bool

    init(moment: MockMoment, colorScheme: ColorScheme, theme: AppVisualTheme? = nil) {
        self.moment = moment
        self.colorScheme = colorScheme
        self.theme = theme
        self._isLiked = State(initialValue: moment.isLiked)
    }

    private var randomImageHeight: CGFloat {
        let hash = abs(moment.id.hashValue)
        return CGFloat(220 + (hash % 80))
    }

    private var cardBg: Color {
        theme?.rowFill ?? (colorScheme == .dark ? Color(white: 0.12) : .white)
    }

    private var accentColor: Color {
        theme?.accent ?? Color(red: 1.0, green: 0.17, blue: 0.33)
    }

    private var firstImageSource: ImageSource {
        guard let first = moment.images.first, !first.isEmpty else { return .none }
        if first.hasPrefix("http"), let url = URL(string: first) { return .url(url) }
        if UIImage(named: first) != nil { return .asset(first) }
        return .none
    }

    private enum ImageSource {
        case asset(String)
        case url(URL)
        case none
    }

    private var gradientTop: Color {
        Color(hex: moment.coverGradient.first ?? "667eea")
    }

    private var gradientBottom: Color {
        Color(hex: moment.coverGradient.last ?? "764ba2")
    }

    private var displayLikes: String {
        let count = moment.likes + (isLiked && !moment.isLiked ? 1 : 0) - (!isLiked && moment.isLiked ? 1 : 0)
        if count >= 10000 { return String(format: "%.1fw", Double(count) / 10000) }
        if count >= 1000 { return String(format: "%.1fk", Double(count) / 1000) }
        return "\(count)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            coverSection
                .frame(height: randomImageHeight)
                .clipped()

            VStack(alignment: .leading, spacing: 8) {
                Text(moment.title)
                    .font(.system(size: 14, weight: .semibold))
                    .lineLimit(2)
                    .foregroundStyle(Color(.label))
                    .multilineTextAlignment(.leading)

                HStack(spacing: 6) {
                    avatarView(size: 18)

                    Text(moment.authorName)
                        .font(.system(size: 11))
                        .foregroundStyle(Color(.secondaryLabel))
                        .lineLimit(1)

                    Spacer(minLength: 0)

                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            isLiked.toggle()
                        }
                    } label: {
                        HStack(spacing: 3) {
                            Image(systemName: isLiked ? "heart.fill" : "heart")
                                .font(.system(size: 12))
                                .foregroundStyle(isLiked ? accentColor : Color(.secondaryLabel))

                            Text(displayLikes)
                                .font(.system(size: 11))
                                .foregroundStyle(Color(.secondaryLabel))
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 10)
        }
        .background(cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(theme?.cardStroke ?? Color.clear, lineWidth: 0.5)
        )
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.06), radius: 6, x: 0, y: 3)
        .contentShape(Rectangle())
    }

    // MARK: - Cover Section

    @ViewBuilder
    private var coverSection: some View {
        switch firstImageSource {
        case .asset(let name):
            GeometryReader { geo in
                Image(name)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
            }
        case .url(let url):
            GeometryReader { geo in
                RemoteImageView(url: url) { isLoading in
                    gradientCover
                        .overlay {
                            if isLoading {
                                ProgressView().tint(.white)
                            }
                        }
                }
                .frame(width: geo.size.width, height: geo.size.height)
                .clipped()
            }
        case .none:
            gradientCover
        }
    }

    private var gradientCover: some View {
        GeometryReader { geo in
            ZStack {
                LinearGradient(
                    colors: [gradientTop, gradientBottom],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                Circle()
                    .fill(Color.white.opacity(0.06))
                    .frame(width: geo.size.width * 0.8)
                    .offset(x: geo.size.width * 0.3, y: -geo.size.height * 0.2)

                Circle()
                    .fill(Color.white.opacity(0.04))
                    .frame(width: geo.size.width * 0.5)
                    .offset(x: -geo.size.width * 0.25, y: geo.size.height * 0.3)

                Image(systemName: moment.coverIcon)
                    .font(.system(size: geo.size.width * 0.28, weight: .light))
                    .foregroundStyle(.white.opacity(0.85))
                    .shadow(color: .black.opacity(0.15), radius: 8, y: 4)

                VStack {
                    HStack {
                        Spacer()
                        Text(moment.agentTag)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(.white.opacity(0.2))
                            .clipShape(Capsule())
                            .padding(8)
                    }
                    Spacer()
                }
            }
        }
    }

    // MARK: - Avatar

    @ViewBuilder
    private func avatarView(size: CGFloat) -> some View {
        if !moment.authorAvatar.isEmpty, UIImage(named: moment.authorAvatar) != nil {
            Image(moment.authorAvatar)
                .resizable()
                .scaledToFill()
                .frame(width: size, height: size)
                .clipShape(Circle())
        } else {
            let g0 = Color(hex: moment.avatarGradient.first ?? "667eea")
            let g1 = Color(hex: moment.avatarGradient.last ?? "764ba2")
            Circle()
                .fill(LinearGradient(colors: [g0, g1], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: size, height: size)
                .overlay(
                    Text(String(moment.authorName.prefix(1)))
                        .font(.system(size: size * 0.45, weight: .bold))
                        .foregroundStyle(.white)
                )
        }
    }
}
