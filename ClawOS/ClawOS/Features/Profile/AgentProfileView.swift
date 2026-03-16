import SwiftUI

struct AgentProfileView: View {
    @Environment(AppState.self) private var appState

    private var currentAgent: Agent {
        appState.selectedAgent ?? MockData.agents[0]
    }

    private var currentTheme: AppVisualTheme {
        appState.currentVisualTheme
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                banner
                profileContent
            }
        }
        .ignoresSafeArea(edges: .top)
        .background {
            LinearGradient(
                colors: [currentTheme.pageGradientTop, currentTheme.pageGradientBottom],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .overlay {
                if let name = currentTheme.ambientAssetName {
                    Image(name)
                        .resizable()
                        .scaledToFill()
                        .opacity(currentTheme.ambientOpacity)
                        .blur(radius: 0.5)
                }
            }
            .ignoresSafeArea()
        }
        .navigationBarTitleDisplayMode(.inline)
        .scrollIndicators(.hidden)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    SettingsView()
                } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 18, weight: .regular))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Banner

    private var banner: some View {
        GeometryReader { geo in
            let minY = geo.frame(in: .global).minY
            let height = max(AppTheme.bannerHeight, AppTheme.bannerHeight + minY)

            ZStack {
                LinearGradient(
                    colors: currentTheme.bannerGradient,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                if let bannerAssetName = currentTheme.bannerAssetName {
                    Image(bannerAssetName)
                        .resizable()
                        .scaledToFill()
                        .opacity(0.34)
                        .overlay(Color.white.opacity(0.12))
                }
            }
            .frame(width: geo.size.width, height: height)
            .offset(y: minY > 0 ? -minY : 0)
        }
        .frame(height: AppTheme.bannerHeight)
    }

    // MARK: - Profile Content

    private var profileContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            avatarRow
            nameSection
            infoCards
        }
        .padding(.horizontal, AppTheme.Spacing.lg)
        .padding(.bottom, 100)
    }

    private var avatarRow: some View {
        HStack(alignment: .bottom) {
            ZStack(alignment: .bottomTrailing) {
                Image(currentAgent.avatar)
                    .resizable()
                    .scaledToFill()
                    .frame(width: AppTheme.largeAvatarSize, height: AppTheme.largeAvatarSize)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(.background, lineWidth: 4))

                StatusIndicator(status: currentAgent.status, size: 20, borderWidth: 3)
                    .offset(x: 2, y: 2)
            }

            Spacer()

            Button { } label: {
                HStack(spacing: 4) {
                    Image(systemName: "plus.circle.fill")
                        .font(.caption)
                    Text("添加状态")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            .buttonStyle(.glass)
        }
        .offset(y: -28)
        .padding(.bottom, -12)
    }

    private var nameSection: some View {
        Menu {
            ForEach(appState.agents) { agent in
                Button {
                    appState.selectedAgentId = agent.id
                } label: {
                    if agent.id == currentAgent.id {
                        Label(agent.name, systemImage: "checkmark")
                    } else {
                        Text(agent.name)
                    }
                }
            }
        } label: {
            HStack(spacing: 6) {
                Text(currentAgent.name)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize()
            }
        }
        .padding(.bottom, AppTheme.Spacing.xl)
        .id(currentAgent.id)
    }

    // MARK: - Info Cards

    private var infoCards: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("快速信息")
                .font(.headline)
                .padding(.horizontal, 4)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                quickInfoCard(
                    title: "默认模型",
                    value: currentAgent.model ?? "MiniMax-M2.5",
                    icon: "cpu"
                )
                quickInfoCard(
                    title: "所在网关",
                    value: appState.gateways.first(where: { $0.id == currentAgent.gatewayId })?.name ?? "本地",
                    icon: "point.3.connected.trianglepath.dotted"
                )
            }

            skillsCard
            themeCard
        }
    }

    private func quickInfoCard(title: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                Text(title)
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .glassEffect(.regular, in: .rect(cornerRadius: AppTheme.Radius.lg))
    }

    private var skillsCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("已启用 Skills")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("3 个可用")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            Spacer()
            HStack(spacing: -8) {
                skillDot(icon: "terminal")
                skillDot(icon: "folder.fill")
                skillDot(icon: "globe")
            }
        }
        .padding(16)
        .glassEffect(.regular, in: .rect(cornerRadius: AppTheme.Radius.lg))
    }

    private func skillDot(icon: String) -> some View {
        Image(systemName: icon)
            .font(.system(size: 11))
            .foregroundStyle(.secondary)
            .frame(width: 28, height: 28)
            .background(Color(.quaternarySystemFill), in: Circle())
            .overlay(Circle().stroke(.background, lineWidth: 2))
    }

    private var themeCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "text.quote")
                Text("系统设定")
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            Text(currentAgent.theme ?? "You are a helpful AI assistant.")
                .font(.subheadline)
                .foregroundStyle(.primary)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .glassEffect(.regular, in: .rect(cornerRadius: AppTheme.Radius.lg))
    }
}
