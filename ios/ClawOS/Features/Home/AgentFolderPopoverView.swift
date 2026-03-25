import SwiftUI

struct AgentFolderPopoverView: View {
    @Environment(AppState.self) private var appState
    @Environment(AgentDragCoordinator.self) private var coordinator
    let group: AgentGroup
    let isEditMode: Bool
    var onSelectAgent: (String) -> Void = { _ in }
    var onDismiss: () -> Void = {}

    @State private var editingName = false
    @State private var nameText = ""
    @FocusState private var isNameFieldFocused: Bool

    private var accent: Color { appState.currentVisualTheme.accent }

    private var agents: [Agent] {
        group.agentIds.compactMap { appState.agent(for: $0) }
    }

    var body: some View {
        VStack(spacing: 12) {
            groupHeader

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 14), count: 3),
                spacing: 14
            ) {
                ForEach(agents) { agent in
                    agentCell(agent)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: 260)
        .adaptiveGlass(in: .rect(cornerRadius: 24))
        .shadow(color: .black.opacity(0.15), radius: 30, x: 0, y: 12)
        .onAppear { nameText = group.displayName }
        .onChange(of: group.name) { _, newValue in
            guard !editingName else { return }
            nameText = AgentGroup.normalizedName(newValue)
        }
        .onChange(of: isNameFieldFocused) { _, focused in
            if editingName && !focused {
                commitGroupName()
            }
        }
    }

    private var groupHeader: some View {
        Group {
            if editingName {
                TextField("Team name", text: $nameText)
                    .font(.system(size: 13, weight: .semibold))
                    .multilineTextAlignment(.center)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .adaptiveGlass(in: .capsule)
                    .focused($isNameFieldFocused)
                    .submitLabel(.done)
                    .onSubmit { commitGroupName() }
            } else {
                HStack(spacing: 6) {
                    Text(group.displayName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.secondary)

                    Image(systemName: "pencil")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.tertiary)
                }
                .padding(.horizontal, 8)
                .contentShape(Rectangle())
                .onTapGesture {
                    startEditingName()
                }
                .onLongPressGesture(minimumDuration: 0.35) {
                    startEditingName()
                }
            }
        }
    }

    private func startEditingName() {
        withAnimation(.spring(response: 0.22, dampingFraction: 0.84)) {
            nameText = group.displayName
            editingName = true
        }
        DispatchQueue.main.async {
            isNameFieldFocused = true
        }
    }

    private func commitGroupName() {
        let normalized = AgentGroup.normalizedName(nameText)
        appState.renameGroup("group_\(group.id)", to: normalized)
        nameText = normalized
        withAnimation(.spring(response: 0.22, dampingFraction: 0.84)) {
            editingName = false
        }
        isNameFieldFocused = false
    }

    private func agentCell(_ agent: Agent) -> some View {
        let groupItemId = "group_\(group.id)"
        let preferredAgentId = appState.preferredAgentInGroup(groupItemId)
        let isSelected = appState.selectedAgentId == agent.id && (
            appState.selectedStripItemId != groupItemId || preferredAgentId == agent.id
        )
        let isArmed: Bool = {
            if case .armed(let id) = coordinator.phase { return id == agent.id }
            return false
        }()
        let isDragged = coordinator.draggedAgentId == agent.id
        let isExtracting = isDragged && coordinator.isExtracting
        let elevation = AgentDragPresentation.folderElevation(
            isArmed: isArmed,
            isDragged: isDragged,
            isExtracting: isExtracting
        )

        return VStack(spacing: 5) {
            ZStack(alignment: .bottomTrailing) {
                ZStack {
                    if isSelected {
                        Circle()
                            .stroke(accent, lineWidth: 2.5)
                            .frame(width: 52, height: 52)
                            .shadow(color: accent.opacity(0.3), radius: 4, y: 1)
                    }

                    agentAvatarImage(agent, size: 48)
                        .scaleEffect(isSelected ? 1.05 : 1.0)
                }
                .frame(width: 52, height: 52)

                statusDot(agent.status)
                    .offset(x: -1, y: -1)
            }
            .frame(width: 52, height: 52)
            .animation(.spring(response: 0.3, dampingFraction: 0.65), value: isSelected)

            Text(agent.name)
                .font(.system(size: 10, weight: isSelected ? .bold : .medium))
                .foregroundStyle(isSelected ? accent : .primary)
                .lineLimit(1)
        }
        .opacity(isDragged ? 0.85 : 1)
        .offset(isDragged ? coordinator.dragOffset : .zero)
        .offset(y: elevation.yOffset)
        .zIndex(isDragged ? 100 : 0)
        .scaleEffect(elevation.scale)
        .shadow(
            color: .black.opacity(elevation.shadowOpacity),
            radius: elevation.shadowRadius,
            y: elevation.shadowY
        )
        .overlay {
            if isExtracting {
                Circle()
                    .stroke(accent.opacity(0.7), lineWidth: 2.5)
                    .frame(width: 56, height: 56)
                    .shadow(color: accent.opacity(0.4), radius: 8)
                    .transition(.opacity)
            }
        }
        .animation(.spring(response: 0.25, dampingFraction: 0.72), value: isDragged)
        .animation(.spring(response: 0.22, dampingFraction: 0.75), value: isArmed)
        .animation(.spring(response: 0.22, dampingFraction: 0.75), value: isExtracting)
        .contentShape(Rectangle())
        .onTapGesture {
            if !isEditMode {
                onSelectAgent(agent.id)
            }
        }
        .simultaneousGesture(longPressDragGesture(for: agent))
    }

    // MARK: - Drag to Ungroup

    private func longPressDragGesture(for agent: Agent) -> some Gesture {
        LongPressGesture(minimumDuration: AgentDragCoordinator.longPressDuration)
            .sequenced(before: DragGesture(minimumDistance: 0))
            .onChanged { value in
                switch value {
                case .first(true):
                    if coordinator.draggedAgentId != agent.id {
                        coordinator.beginArm(itemId: agent.id, surface: .folder(groupId: "group_\(group.id)"))
                    }
                case .second(true, let drag?):
                    if coordinator.draggedAgentId != agent.id {
                        coordinator.beginLift(itemId: agent.id, surface: .folder(groupId: "group_\(group.id)"))
                    }
                    coordinator.updateFolderDrag(translation: drag.translation)
                default:
                    break
                }
            }
            .onEnded { value in
                guard case .second(true, _) = value else {
                    withAnimation(AgentDragPresentation.dropSettleAnimation) {
                        coordinator.cancel()
                    }
                    return
                }

                var result: DragResult = .cancelled
                withAnimation(AgentDragPresentation.dropSettleAnimation) {
                    result = coordinator.endDrag()
                }
                if case .extractFromFolder(let agentId, let groupId, _) = result {
                    withAnimation(AgentDragPresentation.dropSettleAnimation) {
                        appState.ungroupAgent(agentId, from: groupId)
                    }
                    if group.agentIds.count <= 2 {
                        onDismiss()
                    }
                }
            }
    }

    // MARK: - Shared

    private func agentAvatarImage(_ agent: Agent, size: CGFloat) -> some View {
        Group {
            if let custom = AvatarStorage.load(for: agent.id) {
                Image(uiImage: custom)
                    .resizable()
                    .scaledToFill()
            } else if !agent.avatar.isEmpty, UIImage(named: agent.avatar) != nil {
                Image(agent.avatar)
                    .resizable()
                    .scaledToFill()
            } else {
                Image("default_agent_avatar")
                    .resizable()
                    .scaledToFill()
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
            .frame(width: 7, height: 7)
            .overlay(Circle().stroke(.background, lineWidth: 1.5))
    }
}
