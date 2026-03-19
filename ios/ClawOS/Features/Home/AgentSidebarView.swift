import SwiftUI

enum HomeSidebarMetrics {
    static let sidebarLeadingPadding: CGFloat = 10
    static let overshootPadding: CGFloat = 16

    static let avatarDiameter: CGFloat = 40
    static let controlDiameter: CGFloat = 36
    static let addButtonDiameter: CGFloat = 36
    static let statusDotDiameter: CGFloat = 10

    static let singleColumnWidth: CGFloat = 62
    static let secondColumnGestureTravel: CGFloat = 180

    static let gridSpacing: CGFloat = 10
    static let gridPadding: CGFloat = 3

    static let fullScreenAvatarSize: CGFloat = 52
    static let fullScreenGridColumns = 4
    static let fullScreenGridSpacing: CGFloat = 16

    static var screenWidth: CGFloat { UIScreen.main.bounds.width }

    static func columns(for level: Int) -> Int {
        level >= 2 ? fullScreenGridColumns : 1
    }
}

struct AgentSidebarView: View {
    @Environment(AppState.self) private var appState
    @State private var showAddAgent = false
    var onDismiss: () -> Void = {}

    private var isConnected: Bool {
        appState.clawChatManager.isConnected
    }

    private var hasAgents: Bool {
        !appState.currentGatewayAgents.isEmpty
    }

    private var accent: Color { appState.currentVisualTheme.accent }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 10) {
                    gatewayButton
                        .padding(.top, 16)

                    if hasAgents {
                        ForEach(appState.currentGatewayAgents) { agent in
                            narrowAgentCell(agent)
                        }

                        addButton
                            .padding(.bottom, 16)
                    }
                }
                .padding(.horizontal, 6)
            }
            .mask(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
            )
        }
        .frame(maxHeight: .infinity)
        .adaptiveGlass(in: .rect(cornerRadius: 28))
        .shadow(color: .black.opacity(0.10), radius: 12, x: 0, y: 4)
        .sheet(isPresented: $showAddAgent) {
            AgentEditorView()
                .environment(appState)
        }
    }

    private func narrowAgentCell(_ agent: Agent) -> some View {
        let isSelected = appState.selectedAgentId == agent.id
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                appState.selectedAgentId = agent.id
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                onDismiss()
            }
        } label: {
            ZStack {
                agentAvatarView(agent, size: HomeSidebarMetrics.avatarDiameter)
                    .scaleEffect(isSelected ? 1.15 : 1.0)

                Circle()
                    .stroke(accent, lineWidth: isSelected ? 2.5 : 0)
                    .frame(width: HomeSidebarMetrics.avatarDiameter + 6,
                           height: HomeSidebarMetrics.avatarDiameter + 6)
                    .opacity(isSelected ? 1 : 0)
                    .shadow(color: accent.opacity(0.35), radius: isSelected ? 4 : 0)
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.65), value: isSelected)
            .frame(width: HomeSidebarMetrics.avatarDiameter + 6,
                   height: HomeSidebarMetrics.avatarDiameter + 6)
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: isSelected)
    }

    // MARK: - Gateway Button

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

    // MARK: - Shared Components

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
