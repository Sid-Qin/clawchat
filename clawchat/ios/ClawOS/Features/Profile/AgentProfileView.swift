import SwiftUI

struct AgentProfileView: View {
    @Environment(AppState.self) private var appState
    @State private var showAvatarPicker = false
    @State private var avatarRefreshToken = UUID()
    @State private var isAdvancedExpanded = false
    @State private var showAgentSwitcher = false
    @State private var agentNameButtonHeight: CGFloat = 0

    private let maxVisibleAgentSwitcherRows = 5

    private var currentAgent: Agent? {
        appState.selectedAgent
    }

    private var currentTheme: AppVisualTheme {
        appState.currentVisualTheme
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                banner
                if currentAgent != nil {
                    profileContent
                } else {
                    emptyState
                }
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
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var emptyState: some View {
        GeometryReader { geo in
            VStack(spacing: 12) {
                Image(systemName: "person.crop.circle.badge.questionmark")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 44, height: 44)
                    .foregroundStyle(Color(.systemGray3))

                VStack(spacing: 6) {
                    Text("暂无 Agent")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color(.secondaryLabel))
                    Text("连接 Gateway 后将自动加载 Agent 列表")
                        .font(.caption)
                        .foregroundStyle(Color(.tertiaryLabel))
                }
            }
            .frame(maxWidth: .infinity)
            .position(x: geo.size.width / 2, y: geo.size.height * 0.4)
        }
        .frame(height: UIScreen.main.bounds.height * 0.5)
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
                        .overlay(Color(.systemBackground).opacity(0.12))
                }
            }
            .frame(width: geo.size.width, height: height)
            .offset(y: minY > 0 ? -minY : 0)
        }
        .frame(height: AppTheme.bannerHeight)
    }

    // MARK: - Profile Content

    private var profileContent: some View {
        ZStack(alignment: .topLeading) {
            VStack(alignment: .leading, spacing: 0) {
                headerRow
                infoCards
            }

            if showAgentSwitcher {
                Color.black.opacity(0.001)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .onTapGesture {
                        showAgentSwitcher = false
                    }

                agentSwitcherCard(selectedAgentId: currentAgent?.id ?? "")
                    .padding(.top, headerSwitcherTopOffset)
            }
        }
        .padding(.horizontal, AppTheme.Spacing.lg)
        .padding(.bottom, 100)
    }

    private var headerSwitcherTopOffset: CGFloat {
        let bannerOverlap: CGFloat = -28
        let bottomPadding: CGFloat = -12
        let avatarArea = AppTheme.largeAvatarSize + bannerOverlap + bottomPadding
        return avatarArea + agentNameButtonHeight + 8
    }

    private var headerRow: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .bottom) {
                if let agent = currentAgent {
                    Button {
                        showAvatarPicker = true
                    } label: {
                        ZStack(alignment: .bottomTrailing) {
                            agentAvatarImage(agent, size: AppTheme.largeAvatarSize)
                                .overlay(Circle().stroke(.background, lineWidth: 4))

                            Image(systemName: "camera.fill")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 24, height: 24)
                                .background(.tint, in: Circle())
                                .overlay(Circle().stroke(.background, lineWidth: 2))
                                .offset(x: 2, y: 2)
                        }
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button {
                            showAvatarPicker = true
                        } label: {
                            Label("更换头像", systemImage: "photo.on.rectangle")
                        }
                        if AvatarStorage.load(for: agent.id) != nil {
                            Button(role: .destructive) {
                                AvatarStorage.remove(for: agent.id)
                                avatarRefreshToken = UUID()
                            } label: {
                                Label("移除头像", systemImage: "trash")
                            }
                        }
                    }
                }

                Spacer()

                if let agent = currentAgent {
                    statusBadge(agent.status)
                        .padding(.bottom, 8)
                }
            }
            .offset(y: -28)
            .padding(.bottom, -12)

            if let agent = currentAgent {
                Button {
                    showAgentSwitcher.toggle()
                } label: {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(agent.name)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                            .layoutPriority(1)
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize()
                    }
                    .contentTransition(.identity)
                }
                .buttonStyle(.plain)
                .transaction { $0.animation = nil }
                .frame(maxWidth: .infinity, alignment: .leading)
                .background {
                    GeometryReader { proxy in
                        Color.clear
                            .onAppear { agentNameButtonHeight = proxy.size.height }
                            .onChange(of: proxy.size.height) { _, h in agentNameButtonHeight = h }
                    }
                }
                .padding(.bottom, 20)
            }
        }
        .sheet(isPresented: $showAvatarPicker) {
            if let agent = currentAgent {
                AvatarPickerSheet(agentId: agent.id) {
                    avatarRefreshToken = UUID()
                }
            }
        }
    }

    private func statusBadge(_ status: AgentStatus) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(status.color)
                .frame(width: 8, height: 8)
                .shadow(color: status.color.opacity(0.5), radius: 2, x: 0, y: 0)
            Text(status.label)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(.systemBackground).opacity(0.6), in: Capsule())
        .overlay(Capsule().stroke(Color(.separator).opacity(0.5), lineWidth: 0.5))
    }

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
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .id(avatarRefreshToken)
    }

    // MARK: - Info Cards

    private var infoCards: some View {
        VStack(alignment: .leading, spacing: 16) {
            agentProfileCard
            cronJobsCard
            advancedSection
        }
    }

    private var agentProfileCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 6) {
                Image(systemName: "person.text.rectangle")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(currentTheme.accent)
                Text("Agent 名片")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "quote.opening")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(currentTheme.accent.opacity(0.8))
                    .offset(y: -2)
                
                Text(currentAgent?.theme ?? "你好！我是你的专属 AI 助手，随时准备为你提供帮助。")
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .lineLimit(nil)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemBackground))
            .clipShape(
                .rect(
                    topLeadingRadius: 4,
                    bottomLeadingRadius: 16,
                    bottomTrailingRadius: 16,
                    topTrailingRadius: 16
                )
            )

            VStack(alignment: .leading, spacing: 10) {
                Text("核心功能")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                HStack(spacing: 8) {
                    featureTag("智能对话")
                    featureTag("知识问答")
                    featureTag("任务执行")
                }
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .glassEffect(.regular, in: .rect(cornerRadius: AppTheme.Radius.lg))
    }

    private func featureTag(_ text: String) -> some View {
        Text(text)
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundStyle(currentTheme.accent)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(currentTheme.accent.opacity(0.12))
            .clipShape(Capsule())
    }

    private func agentSwitcherCard(selectedAgentId: String) -> some View {
        ScrollView(showsIndicators: appState.agents.count > maxVisibleAgentSwitcherRows) {
            VStack(alignment: .leading, spacing: 6) {
                ForEach(appState.agents) { agent in
                    Button {
                        showAgentSwitcher = false
                        appState.selectedAgentId = agent.id
                    } label: {
                        HStack(alignment: .top, spacing: 10) {
                            Group {
                                if agent.id == selectedAgentId {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(currentTheme.accent)
                                } else {
                                    Color.clear
                                }
                            }
                            .frame(width: 14, height: 14)
                            .padding(.top, 2)

                            Text(agent.name)
                                .font(.system(size: 15, weight: agent.id == selectedAgentId ? .semibold : .medium))
                                .foregroundStyle(.primary)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(agent.id == selectedAgentId ? currentTheme.accent.opacity(0.08) : .clear)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(maxHeight: CGFloat(maxVisibleAgentSwitcherRows) * 52)
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular, in: .rect(cornerRadius: AppTheme.Radius.lg))
        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)
    }

    private var advancedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isAdvancedExpanded.toggle()
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(currentTheme.accent)
                    Text("Advanced")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(isAdvancedExpanded ? 90 : 0))
                }
            }
            .buttonStyle(.plain)

            if isAdvancedExpanded {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                    statCard(
                        icon: "cpu",
                        title: "模型",
                        value: currentAgent?.model ?? "未设定"
                    )
                    statCard(
                        icon: "point.3.connected.trianglepath.dotted",
                        title: "网关",
                        value: appState.gateways.first(where: { $0.id == currentAgent?.gatewayId })?.name ?? "未连接"
                    )
                    statCard(
                        icon: "puzzlepiece.extension",
                        title: "Skills",
                        value: {
                            let enabled = appState.skills.filter(\.isEnabled).count
                            let total = appState.skills.count
                            return total > 0 ? "\(enabled)/\(total) 已启用" : "暂无"
                        }()
                    )
                    statCard(
                        icon: "flame",
                        title: "Token 消耗",
                        value: formatTokenCount(currentAgent?.totalTokens ?? 0)
                    )
                }
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .glassEffect(.regular, in: .rect(cornerRadius: AppTheme.Radius.lg))
    }

    private var cronJobsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "clock.arrow.2.circlepath")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(currentTheme.accent)
                Text("定时任务 (Cron Jobs)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 14) {
                cronJobRow(time: "每天 08:00", description: "获取并总结今日 AI 行业新闻", isActive: true)
                cronJobRow(time: "每小时", description: "检查 GitHub 仓库的新 Issue", isActive: true)
                cronJobRow(time: "每周五 18:00", description: "生成本周工作周报并发送邮件", isActive: false)
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .glassEffect(.regular, in: .rect(cornerRadius: AppTheme.Radius.lg))
    }

    private func cronJobRow(time: String, description: String, isActive: Bool) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(time)
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundStyle(isActive ? currentTheme.accent : .secondary)
                .frame(width: 85, alignment: .leading)

            Text(description)
                .font(.subheadline)
                .foregroundStyle(isActive ? .primary : .secondary)
                .lineLimit(2)

            Spacer(minLength: 8)

            Toggle("", isOn: .constant(isActive))
                .labelsHidden()
                .scaleEffect(0.7)
                .frame(width: 30)
                .tint(currentTheme.accent)
        }
    }

    private func statCard(icon: String, title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(currentTheme.accent)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .glassEffect(.regular, in: .rect(cornerRadius: AppTheme.Radius.lg))
    }

    private func formatTokenCount(_ count: Int) -> String {
        if count >= 1_000_000 {
            return String(format: "%.1fM", Double(count) / 1_000_000)
        } else if count >= 1_000 {
            return String(format: "%.1fK", Double(count) / 1_000)
        } else if count > 0 {
            return "\(count)"
        }
        return "—"
    }
}

// MARK: - Avatar Picker Sheet

import PhotosUI

struct AvatarPickerSheet: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    let agentId: String
    var onChanged: () -> Void = {}

    @State private var pendingAsset: String?
    @State private var pendingCustomImage: UIImage?
    @State private var showPhotosPicker = false
    @State private var selectedPhotoItem: PhotosPickerItem?

    private let selectionHaptic = UISelectionFeedbackGenerator()
    private let confirmHaptic = UIImpactFeedbackGenerator(style: .medium)

    private var currentAgent: Agent? {
        appState.agents.first { $0.id == agentId }
    }

    private var accent: Color { appState.currentVisualTheme.accent }

    private var hasPendingChange: Bool {
        pendingAsset != nil || pendingCustomImage != nil
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 20) {
                        currentPreview

                        VStack(alignment: .leading, spacing: 12) {
                            Text("官方头像")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .padding(.leading, 4)

                            builtInGrid
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                }

                photoLibraryButton
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 16)
            }
            .navigationTitle("选择头像")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { commitAndDismiss() }
                        .fontWeight(.semibold)
                        .disabled(!hasPendingChange)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .photosPicker(
            isPresented: $showPhotosPicker,
            selection: $selectedPhotoItem,
            matching: .images,
            photoLibrary: .shared()
        )
        .onChange(of: selectedPhotoItem) { _, newItem in
            guard let item = newItem else { return }
            selectedPhotoItem = nil
            Task {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    let cropped = image.croppedToSquare(maxSize: 256)
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        pendingCustomImage = cropped
                        pendingAsset = nil
                    }
                    selectionHaptic.selectionChanged()
                }
            }
        }
        .onAppear {
            selectionHaptic.prepare()
            confirmHaptic.prepare()
        }
    }

    // MARK: - Commit

    private func commitAndDismiss() {
        if let customImage = pendingCustomImage {
            AvatarStorage.save(customImage, for: agentId)
            appState.updateAgentAvatar(id: agentId, avatar: "")
        } else if let asset = pendingAsset {
            AvatarStorage.remove(for: agentId)
            appState.updateAgentAvatar(id: agentId, avatar: asset)
        }
        confirmHaptic.impactOccurred(intensity: 0.8)
        onChanged()
        dismiss()
    }

    // MARK: - Preview

    private var currentPreview: some View {
        VStack(spacing: 8) {
            previewImage
                .frame(width: 80, height: 80)
                .clipShape(Circle())
                .overlay(Circle().stroke(accent.opacity(0.4), lineWidth: 2))
                .animation(.spring(response: 0.35, dampingFraction: 0.75), value: pendingAsset)
                .animation(.spring(response: 0.35, dampingFraction: 0.75), value: pendingCustomImage == nil)

            Text(currentAgent?.name ?? "Agent")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var previewImage: some View {
        if let customImage = pendingCustomImage {
            Image(uiImage: customImage)
                .resizable()
                .scaledToFill()
        } else if let asset = pendingAsset, UIImage(named: asset) != nil {
            Image(asset)
                .resizable()
                .scaledToFill()
        } else if let custom = AvatarStorage.load(for: agentId) {
            Image(uiImage: custom)
                .resizable()
                .scaledToFill()
        } else if let agent = currentAgent, !agent.avatar.isEmpty,
                  UIImage(named: agent.avatar) != nil {
            Image(agent.avatar)
                .resizable()
                .scaledToFill()
        } else {
            Image(systemName: "person.crop.circle.fill")
                .resizable()
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Grid

    private let builtInAvatars = [
        "avatar_shinji", "avatar_rei", "avatar_asuka",
        "avatar_kaworu", "avatar_mari", "avatar_misato",
        "avatar_eva01", "avatar_eva00", "avatar_eva02",
        "avatar_ritsuko"
    ]

    private var builtInGrid: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 14), count: 5),
            spacing: 14
        ) {
            ForEach(builtInAvatars, id: \.self) { name in
                builtInCell(name)
            }
        }
    }

    private func builtInCell(_ name: String) -> some View {
        let isActive = pendingAsset == name && pendingCustomImage == nil

        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                pendingAsset = name
                pendingCustomImage = nil
            }
            selectionHaptic.selectionChanged()
        } label: {
            Group {
                if UIImage(named: name) != nil {
                    Image(name)
                        .resizable()
                        .scaledToFill()
                } else {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .foregroundStyle(.tertiary)
                }
            }
            .frame(width: 56, height: 56)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(accent, lineWidth: isActive ? 2.5 : 0)
                    .frame(width: 60, height: 60)
                    .opacity(isActive ? 1 : 0)
            )
            .animation(.easeInOut(duration: 0.2), value: isActive)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Photo Library

    private var photoLibraryButton: some View {
        Button {
            showPhotosPicker = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.system(size: 16, weight: .medium))
                Text("从相册选择")
                    .font(.system(size: 16, weight: .medium))
            }
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .glassEffect(.regular, in: .capsule)
        }
        .buttonStyle(.plain)
    }
}
