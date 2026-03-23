import SwiftUI

struct StripAvatarView: View {
    @Environment(AppState.self) private var appState
    let item: AgentStripItem
    let isSelected: Bool
    let isEditMode: Bool
    let isArmed: Bool
    let isDragged: Bool
    let isMergeCandidate: Bool
    let isMergeReady: Bool
    let onRemoveFromGroup: ((String) -> Void)?

    private var accent: Color { appState.currentVisualTheme.accent }

    private static let avatarSize: CGFloat = 52
    private static let miniAvatarSize: CGFloat = 22

    private var elevation: AgentDragElevation {
        AgentDragPresentation.stripElevation(
            isSelected: isSelected,
            isArmed: isArmed,
            isDragged: isDragged,
            isMergeCandidate: isMergeCandidate,
            isMergeReady: isMergeReady
        )
    }

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                selectionRing
                mergeOverlay

                switch item {
                case .single(let agentId):
                    singleAvatarContent(agentId: agentId)
                case .group(let group):
                    groupAvatarContent(group: group)
                }
            }
            .frame(width: Self.avatarSize + 6, height: Self.avatarSize + 6)
            .offset(y: elevation.yOffset)
            .scaleEffect(elevation.scale)
            .opacity(isDragged ? 0.88 : 1.0)
            .shadow(
                color: .black.opacity(elevation.shadowOpacity),
                radius: elevation.shadowRadius,
                y: elevation.shadowY
            )
            .animation(.spring(response: 0.28, dampingFraction: 0.72), value: isSelected)
            .animation(.spring(response: 0.18, dampingFraction: 0.82), value: isArmed)
            .animation(.spring(response: 0.22, dampingFraction: 0.7), value: isMergeCandidate)
            .animation(.spring(response: 0.2, dampingFraction: 0.72), value: isMergeReady)
            .animation(.spring(response: 0.25, dampingFraction: 0.68), value: isDragged)

            itemLabel
        }
        .frame(width: 64)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private var selectionRing: some View {
        if isSelected && !isMergeCandidate {
            Circle()
                .stroke(accent, lineWidth: 1.5)
                .frame(width: Self.avatarSize + 6, height: Self.avatarSize + 6)
                .shadow(color: accent.opacity(0.3), radius: 4, y: 1)
        }
    }

    @ViewBuilder
    private var mergeOverlay: some View {
        if isMergeReady {
            Circle()
                .stroke(accent, lineWidth: 3.5)
                .frame(width: Self.avatarSize + 10, height: Self.avatarSize + 10)
                .shadow(color: accent.opacity(0.55), radius: 8)
        } else if isMergeCandidate {
            Circle()
                .stroke(accent.opacity(0.55), lineWidth: 2)
                .frame(width: Self.avatarSize + 8, height: Self.avatarSize + 8)
                .shadow(color: accent.opacity(0.2), radius: 4)
        }
    }

    // MARK: - Single Agent Avatar

    private func singleAvatarContent(agentId: String) -> some View {
        let agent = appState.agent(for: agentId)
        return ZStack(alignment: .bottomTrailing) {
            agentAvatarImage(agent, size: Self.avatarSize)
            if let status = agent?.status {
                statusDot(status)
                    .offset(x: -1, y: -1)
            }
            if let count = agent?.unreadCount, count > 0 {
                unreadBadge(count)
                    .offset(x: 4, y: -Self.avatarSize + 10)
            }
        }
    }

    // MARK: - Group (Folder) Avatar

    private func groupAvatarContent(group: AgentGroup) -> some View {
        let visibleIds = Array(group.agentIds.prefix(4))
        return ZStack {
            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: Self.avatarSize, height: Self.avatarSize)
                .overlay(
                    Circle().stroke(Color.secondary.opacity(0.18), lineWidth: 0.5)
                )

            let gridSize = Self.avatarSize - 8
            let cellSize = (gridSize - 4) / 2
            LazyVGrid(
                columns: [
                    GridItem(.fixed(cellSize), spacing: 4),
                    GridItem(.fixed(cellSize), spacing: 4)
                ],
                spacing: 4
            ) {
                ForEach(visibleIds, id: \.self) { agentId in
                    let agent = appState.agent(for: agentId)
                    agentAvatarImage(agent, size: cellSize)
                }
            }
            .frame(width: gridSize, height: gridSize)

            let totalUnread = group.agentIds.compactMap { appState.agent(for: $0)?.unreadCount }.reduce(0, +)
            if totalUnread > 0 {
                unreadBadge(totalUnread)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .offset(x: 4, y: -2)
            }
        }
    }

    // MARK: - Label

    private var itemLabel: some View {
        Group {
            switch item {
            case .single(let agentId):
                Text(appState.agent(for: agentId)?.name ?? "Agent")
            case .group(let group):
                Text(group.displayName)
            }
        }
        .font(.system(size: 10, weight: isSelected ? .bold : .medium))
        .foregroundStyle(isSelected ? accent : .primary)
        .lineLimit(1)
    }

    // MARK: - Shared

    private func agentAvatarImage(_ agent: Agent?, size: CGFloat) -> some View {
        Group {
            if let agentId = agent?.id, let custom = AvatarStorage.load(for: agentId) {
                Image(uiImage: custom)
                    .resizable()
                    .scaledToFill()
            } else if let avatar = agent?.avatar, !avatar.isEmpty, UIImage(named: avatar) != nil {
                Image(avatar)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }

    private func statusDot(_ status: AgentStatus) -> some View {
        let color: Color = switch status {
        case .online: .green
        case .idle: .orange
        case .dnd: .red
        case .offline: Color(.systemGray3)
        }
        return Circle()
            .fill(color)
            .frame(width: 10, height: 10)
            .overlay(Circle().stroke(.background, lineWidth: 2))
    }

    private func unreadBadge(_ count: Int) -> some View {
        Text("\(min(count, 99))")
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 4)
            .frame(minWidth: 18, minHeight: 18)
            .background(Color.red, in: Capsule())
    }
}
