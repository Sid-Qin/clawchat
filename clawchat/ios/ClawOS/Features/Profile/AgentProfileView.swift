import SwiftUI

struct AgentProfileView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @State private var showAvatarPicker = false
    @State private var avatarRefreshToken = UUID()
    @State private var isAdvancedExpanded = false
    @State private var showDeleteConfirmation = false

    var agentId: String?

    private var currentAgent: Agent? {
        if let agentId {
            return appState.agents.first { $0.id == agentId }
        }
        return appState.selectedAgent
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
        .toolbarBackground(.hidden, for: .navigationBar)
        .scrollIndicators(.hidden)
        .onAppear {
            if let agentId, appState.selectedAgentId != agentId {
                appState.selectedAgentId = agentId
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
        VStack(alignment: .leading, spacing: 0) {
            headerRow
            infoCards
        }
        .padding(.horizontal, AppTheme.Spacing.lg)
        .padding(.bottom, 100)
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
                Text(agent.name)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
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
                Image("default_agent_avatar")
                    .resizable()
                    .scaledToFill()
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

            if let theme = currentAgent?.theme, !theme.isEmpty {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "quote.opening")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(currentTheme.accent.opacity(0.8))
                        .offset(y: -2)
                    
                    Text(theme)
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
            }

            // You can add logic here to display actual features if they become available in the Agent model
            // Currently leaving this out if there's no real data
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .adaptiveGlass(in: .rect(cornerRadius: AppTheme.Radius.lg))
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
                    if let model = currentAgent?.model, !model.isEmpty {
                        statCard(
                            icon: "cpu",
                            title: "模型",
                            value: model
                        )
                    }
                    if let gwId = currentAgent?.gatewayId, let gwName = appState.gateways.first(where: { $0.id == gwId })?.name {
                        statCard(
                            icon: "point.3.connected.trianglepath.dotted",
                            title: "网关",
                            value: gwName
                        )
                    }
                    let enabled = appState.skills.filter(\.isEnabled).count
                    let total = appState.skills.count
                    if total > 0 {
                        statCard(
                            icon: "puzzlepiece.extension",
                            title: "Skills",
                            value: "\(enabled)/\(total) 已启用"
                        )
                    }
                    if let tokens = currentAgent?.totalTokens, tokens > 0 {
                        statCard(
                            icon: "flame",
                            title: "Token 消耗",
                            value: formatTokenCount(tokens)
                        )
                    }
                }
                .padding(.top, 4)

                Divider()
                    .padding(.vertical, 4)

                Button {
                    showDeleteConfirmation = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "trash")
                            .font(.system(size: 13, weight: .regular))
                        Text("删除此 Agent")
                            .font(.subheadline)
                    }
                    .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .alert("确认删除", isPresented: $showDeleteConfirmation) {
                    Button("取消", role: .cancel) {}
                    Button("删除", role: .destructive) {
                        if let id = currentAgent?.id {
                            appState.deleteAgent(id: id)
                            dismiss()
                        }
                    }
                } message: {
                    if let agent = currentAgent {
                        let count = appState.sessions.filter { $0.agentId == agent.id }.count
                        if count > 0 {
                            Text("「\(agent.name)」及其 \(count) 个会话将被永久删除，此操作不可撤销。")
                        } else {
                            Text("「\(agent.name)」将被永久删除，此操作不可撤销。")
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .adaptiveGlass(in: .rect(cornerRadius: AppTheme.Radius.lg))
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

            // Placeholder for when there are no cron jobs
            VStack(spacing: 8) {
                Image(systemName: "calendar.badge.plus")
                    .font(.system(size: 24))
                    .foregroundStyle(.tertiary)
                Text("暂无定时任务")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(Color(.secondarySystemBackground).opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .adaptiveGlass(in: .rect(cornerRadius: AppTheme.Radius.lg))
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
        .adaptiveGlass(in: .rect(cornerRadius: AppTheme.Radius.lg))
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
                // 自定义顶部栏
                HStack {
                    Spacer()
                        .frame(width: 80) // 占位保持标题居中

                    Spacer()

                    Text("选择头像")
                        .font(.headline)

                    Spacer()

                    Text("完成")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(minWidth: 64)
                        .frame(height: 34)
                        .background(
                            Capsule(style: .continuous)
                                .fill(hasPendingChange ? accent : Color(.systemGray4))
                        )
                        .contentShape(Capsule(style: .continuous))
                        .opacity(hasPendingChange ? 1 : 0.7)
                        .onTapGesture {
                            guard hasPendingChange else { return }
                            commitAndDismiss()
                        }
                        .allowsHitTesting(hasPendingChange)
                        .accessibilityAddTraits(.isButton)
                        .frame(width: 80, alignment: .trailing) // 与左侧占位对称
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 8)

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
            Image("default_agent_avatar")
                .resizable()
                .scaledToFill()
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
            .adaptiveGlass(in: .capsule)
        }
        .buttonStyle(.plain)
    }
}
