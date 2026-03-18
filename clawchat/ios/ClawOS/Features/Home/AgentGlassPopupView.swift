import SwiftUI

struct AgentGlassPopupView: View {
    @Environment(AppState.self) private var appState
    var revealProgress: CGFloat = 1
    var onDismiss: () -> Void = {}

    private var accent: Color { appState.currentVisualTheme.accent }

    private var displayedAgents: [Agent] {
        SidebarExpansionBehavior.orderedAgents(
            currentGatewayAgents: appState.currentGatewayAgents,
            allAgents: appState.agents
        )
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                gatewayCardsSection
                    .opacity(sectionOpacity(from: 0.12, to: 0.70))
                    .offset(y: sectionYOffset(from: 0.12, to: 0.70))

                agentGridSection
                    .opacity(sectionOpacity(from: 0.28, to: 1.0))
                    .offset(y: sectionYOffset(from: 0.28, to: 1.0))
            }
            .padding(20)
        }
        .frame(maxWidth: HomeSidebarMetrics.screenWidth - 40, maxHeight: 580)
        .fixedSize(horizontal: false, vertical: true)
        .glassEffect(.regular, in: .rect(cornerRadius: 24))
        .shadow(color: .black.opacity(0.15), radius: 30, x: 0, y: 10)
        .padding(.leading, 16)
        .padding(.top, -50)
    }

    private func sectionOpacity(from start: CGFloat, to end: CGFloat) -> Double {
        Double(sectionProgress(from: start, to: end))
    }

    private func sectionYOffset(from start: CGFloat, to end: CGFloat) -> CGFloat {
        (1 - sectionProgress(from: start, to: end)) * 8
    }

    private func sectionProgress(from start: CGFloat, to end: CGFloat) -> CGFloat {
        guard end > start else { return 1 }
        let raw = (revealProgress - start) / (end - start)
        return min(1, max(0, raw))
    }

    // MARK: - Gateway Cards

    private var gatewayCardsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label {
                Text("服务器")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
            } icon: {
                Image(systemName: "server.rack")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.tertiary)
            }

            if appState.gateways.isEmpty {
                disconnectedCard
            } else {
                LazyVGrid(
                    columns: [GridItem(.flexible()), GridItem(.flexible())],
                    spacing: 8
                ) {
                    ForEach(appState.gateways) { gw in
                        gatewayCard(gw)
                    }
                }
            }
        }
    }

    private var disconnectedCard: some View {
        Button {
            withAnimation { appState.showPairing = true }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "antenna.radiowaves.left.and.right.slash")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 1) {
                    Text("未连接")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.primary)
                    Text("点击配对")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassEffect(.regular, in: .rect(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }

    private func gatewayCard(_ gw: Gateway) -> some View {
        let isSelected = gw.id == appState.selectedGatewayId
        let icon: String = switch gw.type {
        case .local: "desktopcomputer"
        case .cloud: "cloud.fill"
        case .custom: "server.rack"
        }
        let statusColor: Color = switch gw.status {
        case .online: .green
        case .offline: Color(.systemGray3)
        case .error: .red
        }

        return Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                appState.selectGateway(gw.id)
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(isSelected ? accent : .secondary)

                VStack(alignment: .leading, spacing: 1) {
                    Text(gw.name)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    HStack(spacing: 3) {
                        Circle()
                            .fill(statusColor)
                            .frame(width: 5, height: 5)
                        Text(gw.status == .online ? "在线" : gw.status == .error ? "错误" : "离线")
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                        if let ping = gw.ping {
                            Text("·").foregroundStyle(.quaternary)
                            Text("\(ping)ms")
                                .font(.system(size: 9, weight: .medium, design: .monospaced))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                Spacer()
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? accent : .clear, lineWidth: 1.5)
            )
            .glassEffect(.regular, in: .rect(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: isSelected)
    }

    // MARK: - Agent Grid

    private var agentGridSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label {
                Text("Agents")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
            } icon: {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.tertiary)
            }

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 14), count: 4),
                spacing: 14
            ) {
                ForEach(displayedAgents) { agent in
                    agentCell(agent)
                }
            }
        }
    }

    private func agentCell(_ agent: Agent) -> some View {
        let isSelected = appState.selectedAgentId == agent.id
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                if let gid = agent.gatewayId, gid != appState.selectedGatewayId {
                    appState.selectGateway(gid)
                }
                appState.selectedAgentId = agent.id
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
                onDismiss()
            }
        } label: {
            VStack(spacing: 5) {
                ZStack {
                    agentAvatarView(agent, size: HomeSidebarMetrics.fullScreenAvatarSize)
                        .scaleEffect(isSelected ? 1.1 : 1.0)

                    Circle()
                        .stroke(accent, lineWidth: isSelected ? 2 : 0)
                        .frame(width: HomeSidebarMetrics.fullScreenAvatarSize + 5,
                               height: HomeSidebarMetrics.fullScreenAvatarSize + 5)
                        .opacity(isSelected ? 1 : 0)
                        .shadow(color: accent.opacity(0.3), radius: isSelected ? 4 : 0)

                    statusDot(agent.status)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                        .padding(1)
                }
                .frame(width: HomeSidebarMetrics.fullScreenAvatarSize + 5,
                       height: HomeSidebarMetrics.fullScreenAvatarSize + 5)
                .animation(.spring(response: 0.35, dampingFraction: 0.65), value: isSelected)

                Text(agent.name)
                    .font(.system(size: 10, weight: isSelected ? .bold : .medium))
                    .foregroundStyle(isSelected ? accent : .primary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: isSelected)
    }

    // MARK: - Shared

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
}
