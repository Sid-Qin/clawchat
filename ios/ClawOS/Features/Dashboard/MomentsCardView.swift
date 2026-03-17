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

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            GeometryReader { geo in
                if let firstImage = moment.images.first {
                    Image(firstImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                }
            }
            .frame(height: randomImageHeight)
            .clipped()

            VStack(alignment: .leading, spacing: 8) {
                Text(moment.title)
                    .font(.system(size: 14, weight: .medium))
                    .lineLimit(2)
                    .foregroundStyle(Color(.label))
                    .multilineTextAlignment(.leading)

                HStack(spacing: 6) {
                    Image(moment.authorAvatar)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 18, height: 18)
                        .clipShape(Circle())

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

                            Text("\(moment.likes + (isLiked && !moment.isLiked ? 1 : 0) - (!isLiked && moment.isLiked ? 1 : 0))")
                                .font(.system(size: 11))
                                .foregroundStyle(Color(.secondaryLabel))
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
        }
        .background(cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(theme?.cardStroke ?? Color.clear, lineWidth: 0.5)
        )
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.04), radius: 4, x: 0, y: 2)
        .contentShape(Rectangle())
    }
}
