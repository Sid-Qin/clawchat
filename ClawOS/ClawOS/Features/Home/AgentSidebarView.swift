import SwiftUI

struct AgentSidebarView: View {
    @Environment(AppState.self) private var appState
    @State private var showAddAgent = false
    var onDismiss: () -> Void = {}

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    gatewayButton
                        .padding(.top, 24)

                    pillDivider

                    VStack(spacing: 14) {
                        ForEach(appState.currentGatewayAgents) { agent in
                            agentRow(agent)
                                .transition(.asymmetric(
                                    insertion: .scale(scale: 0.6).combined(with: .opacity),
                                    removal: .scale(scale: 0.6).combined(with: .opacity)
                                ))
                        }
                    }
                    .animation(.spring(response: 0.35, dampingFraction: 0.8), value: appState.selectedGatewayId)

                    pillDivider

                    addButton
                        .padding(.bottom, 24)
                }
                .frame(maxWidth: .infinity)
            }
            .mask(RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
        .frame(maxHeight: .infinity)
        .glassEffect(.regular, in: .rect(cornerRadius: 24))
        .sheet(isPresented: $showAddAgent) {
            AgentEditorView()
                .environment(appState)
        }
    }

    // MARK: - Gateway

    private var gatewayIcon: String {
        switch appState.currentGatewayType {
        case .local: "desktopcomputer"
        case .cloud: "cloud"
        case .custom: "server.rack"
        }
    }

    private var gatewayButton: some View {
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
            VStack(spacing: 4) {
                ZStack(alignment: .bottomTrailing) {
                    Image(systemName: gatewayIcon)
                        .font(.title3)
                        .foregroundStyle(.primary)
                        .frame(width: 52, height: 52)
                        .background(.ultraThinMaterial, in: Circle())

                    Circle()
                        .fill(appState.currentGateway?.status == .online ? Color.green : Color(.systemGray3))
                        .frame(width: 12, height: 12)
                        .overlay(Circle().stroke(.background, lineWidth: 2))
                        .offset(x: 0, y: 0)
                }

                Text(appState.currentGateway?.name ?? "")
                    .font(.system(size: 8, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .frame(maxWidth: 64)
            }
        }
        .sensoryFeedback(.selection, trigger: appState.selectedGatewayId)
    }

    // MARK: - Divider

    private var pillDivider: some View {
        Capsule()
            .fill(.quaternary)
            .frame(width: 32, height: 2)
            .padding(.vertical, 2)
    }

    // MARK: - Agent Row

    private func agentRow(_ agent: Agent) -> some View {
        let isSelected = appState.selectedAgentId == agent.id
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                appState.selectedAgentId = agent.id
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                onDismiss()
            }
        } label: {
            ZStack(alignment: .bottomTrailing) {
                Image(agent.avatar)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 48, height: 48)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(isSelected ? Color(.label) : Color.clear, lineWidth: 2)
                    )
                    .scaleEffect(isSelected ? 1.05 : 1.0)

                StatusIndicator(status: agent.status, size: 14, borderWidth: 2.5)
                    .offset(x: -2, y: -2)
            }
            .frame(width: 60, height: 60)
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: isSelected)
    }

    // MARK: - Add

    private var addButton: some View {
        Button {
            showAddAgent = true
        } label: {
            Image(systemName: "plus")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .frame(width: 52, height: 52)
                .background(.ultraThinMaterial, in: Circle())
        }
        .buttonStyle(.plain)
    }
}
