import SwiftUI

struct MessageBubbleView: View {
    @Environment(AppState.self) private var appState
    let message: Message
    var agentName: String = "Agent"

    private var currentTheme: AppVisualTheme {
        appState.currentVisualTheme
    }

    var body: some View {
        switch message.type {
        case .system:
            systemMessage
        default:
            if message.isMe {
                userMessage
            } else {
                agentMessage
            }
        }
    }

    // MARK: - System

    private var systemMessage: some View {
        Text(message.content)
            .font(.caption)
            .foregroundStyle(.tertiary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
    }

    // MARK: - User Message (right-aligned bubble)

    private var userMessage: some View {
        HStack {
            Spacer(minLength: 72)

            Text(message.content)
                .font(.body)
                .foregroundStyle(AppTheme.bubbleText)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(AppTheme.bubble, in: RoundedRectangle(cornerRadius: 20))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 3)
    }

    // MARK: - Agent Message (left-aligned, ChatGPT style)

    private var agentMessage: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "sparkle")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(currentTheme.accent)
                .frame(width: 28, height: 28)
                .background(currentTheme.softFill, in: Circle())
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 6) {
                Text(message.content)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .textSelection(.enabled)

                HStack(spacing: 16) {
                    if let tokenCount = message.tokenCount {
                        Label("\(tokenCount) tokens", systemImage: "bolt.fill")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }

                    Button { } label: {
                        Image(systemName: "doc.on.doc")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }

                    Button { } label: {
                        Image(systemName: "hand.thumbsup")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }

                    Button { } label: {
                        Image(systemName: "hand.thumbsdown")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }

                    Button { } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
                .padding(.top, 2)
            }

            Spacer(minLength: 24)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
    }
}

extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
