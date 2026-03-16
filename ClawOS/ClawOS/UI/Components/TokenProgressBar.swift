import SwiftUI

struct TokenProgressBar: View {
    let label: String
    let value: String
    let progress: Double
    var tint: Color = Color(.label)

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            GeometryReader { geo in
                Capsule()
                    .fill(.quaternary)
                    .overlay(alignment: .leading) {
                        Capsule()
                            .fill(tint)
                            .frame(width: geo.size.width * progress)
                    }
            }
            .frame(height: 6)
            .clipShape(Capsule())
        }
    }
}
