import SwiftUI

enum HomeSidebarMetrics {
    static let sidebarLeadingPadding: CGFloat = 10
    static let overshootPadding: CGFloat = 16

    static let avatarDiameter: CGFloat = 40
    static let controlDiameter: CGFloat = avatarDiameter
    static let addButtonDiameter: CGFloat = avatarDiameter
    static let statusDotDiameter: CGFloat = 10

    static let singleColumnWidth: CGFloat = 66
    static let doubleColumnWidth: CGFloat = 136
    static let secondColumnGestureTravel: CGFloat = 130
    static let secondColumnActivationProgress: CGFloat = 0.85

    static let gridSpacing: CGFloat = 10
    static let gridPadding: CGFloat = 13

    static func columns(for level: Int) -> Int {
        level >= 2 ? 2 : 1
    }
}

struct AgentSidebarView: View {
    @Environment(AppState.self) private var appState
    @State private var showAddAgent = false
    var expansionLevel: Int = 1
    var onDismiss: () -> Void = {}

    private var isConnected: Bool {
        appState.clawChatManager.isConnected
    }

    private var hasAgents: Bool {
        !appState.currentGatewayAgents.isEmpty
    }

    private var columnCount: Int {
        HomeSidebarMetrics.columns(for: expansionLevel)
    }

    private var showsLabels: Bool {
        expansionLevel >= 2
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    gatewayButton
                        .padding(.top, 24)
                        .padding(.bottom, hasAgents ? 0 : 24)

                    if hasAgents {
                        pillDivider

                        agentGrid

                        pillDivider

                        addButton
                            .padding(.bottom, 24)
                    }
                }
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: hasAgents)
                .frame(maxWidth: .infinity)
            }
            .mask(
                RoundedRectangle(cornerRadius: 33, style: .continuous)
            )
        }
        .frame(maxHeight: .infinity)
        .adaptiveGlass(in: .rect(cornerRadius: 33))
        .sheet(isPresented: $showAddAgent) {
            AgentEditorView()
                .environment(appState)
        }
    }

    // MARK: - Agent Grid

    private var agentGrid: some View {
        let agents = appState.currentGatewayAgents
        let cols = columnCount
        let rows = stride(from: 0, to: agents.count, by: cols).map { startIndex in
            Array(agents[startIndex..<min(startIndex + cols, agents.count)])
        }

        return VStack(spacing: HomeSidebarMetrics.gridSpacing) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                HStack(spacing: HomeSidebarMetrics.gridSpacing) {
                    ForEach(row) { agent in
                        agentCell(agent)
                    }

                    if row.count < cols {
                        ForEach(0..<(cols - row.count), id: \.self) { _ in
                            Color.clear
                                .frame(width: HomeSidebarMetrics.avatarDiameter,
                                       height: HomeSidebarMetrics.avatarDiameter)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, HomeSidebarMetrics.gridPadding)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: appState.selectedGatewayId)
        .animation(nil, value: expansionLevel)
    }

    // MARK: - Agent Cell

    private var accent: Color { appState.currentVisualTheme.accent }

    private func agentCell(_ agent: Agent) -> some View {
        let isSelected = appState.selectedAgentId == agent.id
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                appState.selectedAgentId = agent.id
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                onDismiss()
            }
        } label: {
            VStack(spacing: showsLabels ? 4 : 0) {
                ZStack {
                    agentAvatarView(agent, size: HomeSidebarMetrics.avatarDiameter)
                        .scaleEffect(isSelected ? 1.15 : 1.0)

                    Circle()
                        .stroke(accent, lineWidth: isSelected ? 2.5 : 0)
                        .frame(width: HomeSidebarMetrics.avatarDiameter + 6,
                               height: HomeSidebarMetrics.avatarDiameter + 6)
                        .opacity(isSelected ? 1 : 0)
                        .shadow(color: accent.opacity(0.35), radius: isSelected ? 4 : 0, y: 0)
                }
                .animation(.spring(response: 0.35, dampingFraction: 0.65), value: isSelected)

                if showsLabels {
                    Text(agent.name.prefix(4))
                        .font(.system(size: 10, weight: isSelected ? .bold : .medium))
                        .foregroundStyle(isSelected ? accent : .secondary)
                        .lineLimit(1)
                }
            }
            .frame(width: HomeSidebarMetrics.avatarDiameter + 6,
                   height: showsLabels ? HomeSidebarMetrics.avatarDiameter + 22 : HomeSidebarMetrics.avatarDiameter + 6)
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: isSelected)
    }

    // MARK: - Gateway

    private var gatewayIcon: String {
        if !isConnected { return "antenna.radiowaves.left.and.right.slash" }
        switch appState.currentGatewayType {
        case .local: return "desktopcomputer"
        case .cloud: return "cloud"
        case .custom: return "server.rack"
        }
    }

    private var gatewayStatusColor: Color {
        switch appState.clawChatManager.linkState {
        case .connected: .green
        case .connecting: .orange
        default: Color(.systemGray3)
        }
    }

    private var gatewayButton: some View {
        Group {
            if isConnected && !appState.gateways.isEmpty {
                connectedGatewayMenu
            } else {
                disconnectedGatewayButton
            }
        }
    }

    private var connectedGatewayMenu: some View {
        Menu {
            ForEach(appState.gateways) { gw in
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        appState.selectGateway(gw.id)
                    }
                } label: {
                    Label {
                        Text(gw.name)
                    } icon: {
                        if gw.id == appState.selectedGatewayId {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            gatewayIconView
        }
        .sensoryFeedback(.selection, trigger: appState.selectedGatewayId)
    }

    private var disconnectedGatewayButton: some View {
        Button {
            withAnimation { appState.showPairing = true }
        } label: {
            gatewayIconView
        }
        .buttonStyle(.plain)
    }

    private var gatewayIconView: some View {
        ZStack(alignment: .bottomTrailing) {
            Image(systemName: gatewayIcon)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(isConnected ? .primary : .secondary)
                .frame(width: HomeSidebarMetrics.controlDiameter, height: HomeSidebarMetrics.controlDiameter)
                .adaptiveGlass(in: .circle)

            Circle()
                .fill(gatewayStatusColor)
                .frame(width: HomeSidebarMetrics.statusDotDiameter, height: HomeSidebarMetrics.statusDotDiameter)
                .overlay(Circle().stroke(.background, lineWidth: 2))
        }
    }

    // MARK: - Divider

    private var pillDivider: some View {
        Capsule()
            .fill(.quaternary)
            .frame(width: 24, height: 1)
            .padding(.vertical, 2)
    }

    // MARK: - Avatar

    private func agentAvatarView(_ agent: Agent, size: CGFloat) -> some View {
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
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }

    // MARK: - Add

    private var addButton: some View {
        Button {
            showAddAgent = true
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 18, weight: .semibold))
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .frame(width: HomeSidebarMetrics.addButtonDiameter, height: HomeSidebarMetrics.addButtonDiameter)
                .adaptiveGlass(in: .circle)
        }
        .buttonStyle(.plain)
    }
}
