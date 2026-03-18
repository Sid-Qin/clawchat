import SwiftUI

// MARK: - Settings View

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("isDarkMode") private var isDarkMode = false
    @State private var showLinkStart = false
    @State private var showPrivacyPolicy = false
    @State private var showTermsOfService = false

    private var theme: AppVisualTheme { appState.currentVisualTheme }

    private var currentAgent: Agent? {
        appState.selectedAgent
    }

    private let bottomFadeHeight: CGFloat = 60

    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(alignment: .leading, spacing: 28) {
                profileCard
                sectionBlock(title: "通用设置", cells: generalCells)
                sectionBlock(title: "ClawChat 连接", cells: connectionCells)
                sectionBlock(title: "法律与隐私", cells: legalCells)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, bottomFadeHeight + 20)
        }
        .overlay(alignment: .bottom) { bottomFade }
        .background {
            LinearGradient(
                colors: [theme.pageGradientTop, theme.pageGradientBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
        .navigationTitle("设置")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(theme.accent)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .background(InteractivePopGestureEnabler())
        .sheet(isPresented: $showLinkStart) {
            LoginView { showLinkStart = false }
                .environment(appState)
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
                .presentationBackground(Color(.systemBackground))
        }
        .sheet(isPresented: $showPrivacyPolicy) {
            NavigationStack {
                ScrollView {
                    Text("这里是隐私政策的具体内容...")
                        .padding()
                }
                .navigationTitle("隐私政策")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("完成") { showPrivacyPolicy = false }
                    }
                }
            }
            .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showTermsOfService) {
            NavigationStack {
                ScrollView {
                    Text("这里是服务条款的具体内容...")
                        .padding()
                }
                .navigationTitle("服务条款")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("完成") { showTermsOfService = false }
                    }
                }
            }
            .presentationDetents([.medium, .large])
        }
    }

    // MARK: - Profile Card

    private var profileCard: some View {
        Button { showLinkStart = true } label: {
            HStack(spacing: 14) {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .frame(width: 52, height: 52)
                    .foregroundStyle(theme.accent.opacity(0.6))

                VStack(alignment: .leading, spacing: 3) {
                    Text("LINK START")
                        .font(.system(size: 17, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color(.label))
                    Text("点击进入 ClawOS")
                        .font(.system(size: 13))
                        .foregroundStyle(Color(.secondaryLabel))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color(.tertiaryLabel))
            }
            .padding(16)
            .background(cardBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Section Block

    private func sectionBlock(title: String, cells: [SettingsCellDescriptor]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Color(.label))
                .padding(.leading, 16)
                .padding(.top, 16)
                .padding(.bottom, 8)

            ForEach(Array(cells.enumerated()), id: \.element.id) { index, cell in
                if index > 0 {
                    Divider().padding(.leading, 52)
                }
                cellRow(cell)
            }

            Spacer().frame(height: 4)
        }
        .background(cardBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - Cell Row

    @ViewBuilder
    private func cellRow(_ cell: SettingsCellDescriptor) -> some View {
        switch cell.kind {
        case .navigation(let destination):
            NavigationLink { destination } label: {
                cellContent(cell)
            }
        case .toggle(let binding):
            HStack(spacing: 0) {
                cellContent(cell, showsRightSpace: false)
                Toggle("", isOn: binding)
                    .labelsHidden()
                    .tint(theme.accent)
                    .padding(.trailing, 16)
            }
        case .button(let action):
            Button(action: action) {
                cellContent(cell)
            }
            .buttonStyle(.plain)
        case .destructiveButton(let action):
            Button(role: .destructive, action: action) {
                cellContent(cell)
                    .foregroundStyle(.red)
            }
            .buttonStyle(.plain)
        case .info:
            cellContent(cell)
        }
    }

    private func cellContent(_ cell: SettingsCellDescriptor, showsRightSpace: Bool = true) -> some View {
        HStack(spacing: 16) {
            Image(systemName: cell.icon)
                .font(.system(size: 20, weight: .regular))
                .foregroundStyle(theme.accent)
                .frame(width: 24, height: 24)

            Text(cell.title)
                .font(.system(size: 16))
                .foregroundStyle(Color(.label))

            Spacer()

            if let value = cell.value {
                Text(value)
                    .font(.system(size: 14))
                    .foregroundStyle(Color(.secondaryLabel))
            }

            if cell.showsExternalLink {
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color(.tertiaryLabel))
            }

            if case .navigation = cell.kind {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color(.tertiaryLabel))
            }
        }
        .padding(.leading, 16)
        .padding(.trailing, showsRightSpace ? 16 : 0)
        .padding(.vertical, 14)
    }

    // MARK: - Card Background

    private var cardBackground: some ShapeStyle {
        Color(.secondarySystemGroupedBackground)
    }

    // MARK: - Bottom Fade

    private var bottomFade: some View {
        LinearGradient(
            colors: [.clear, theme.pageGradientBottom],
            startPoint: .top,
            endPoint: .bottom
        )
        .frame(height: bottomFadeHeight)
        .allowsHitTesting(false)
    }

    // MARK: - Connection Helpers

    private var connectionIcon: String {
        switch appState.clawChatManager.linkState {
        case .connected: "wifi"
        case .connecting: "wifi.exclamationmark"
        case .disconnected: "wifi.slash"
        case .unpaired: "link.badge.plus"
        case .error: "exclamationmark.triangle"
        }
    }

    private var connectionLabel: String {
        switch appState.clawChatManager.linkState {
        case .connected: "已连接"
        case .connecting: "连接中…"
        case .disconnected: "已断开"
        case .unpaired: "未配对"
        case .error(let msg): "错误: \(msg)"
        }
    }

    private var connectionColor: Color {
        switch appState.clawChatManager.linkState {
        case .connected: .green
        case .connecting: .orange
        case .disconnected, .unpaired: .secondary
        case .error: .red
        }
    }

    // MARK: - Cell Data

    private var generalCells: [SettingsCellDescriptor] {
        [
            SettingsCellDescriptor(
                id: "theme", icon: "circle.lefthalf.filled", title: "视觉主题",
                value: theme.displayName,
                kind: .navigation(AnyView(ThemeSelectionView().environment(appState)))
            ),
            SettingsCellDescriptor(
                id: "model", icon: "cpu", title: "默认大语言模型",
                value: currentAgent?.model ?? "未连接",
                kind: .info
            ),
            SettingsCellDescriptor(
                id: "darkmode", icon: "moon", title: "暗色模式",
                kind: .toggle($isDarkMode)
            ),
        ]
    }

    private var connectionCells: [SettingsCellDescriptor] {
        var cells: [SettingsCellDescriptor] = [
            SettingsCellDescriptor(
                id: "conn_status", icon: connectionIcon, title: "连接状态",
                value: connectionLabel,
                iconColor: connectionColor,
                kind: .info
            )
        ]

        if appState.clawChatManager.isPaired {
            cells.append(SettingsCellDescriptor(
                id: "unpair", icon: "link.badge.plus", title: "取消配对",
                kind: .destructiveButton { Task { await appState.clawChatManager.unpair() } }
            ))
        } else {
            cells.append(SettingsCellDescriptor(
                id: "pair", icon: "antenna.radiowaves.left.and.right", title: "配对 Gateway",
                kind: .button { withAnimation { appState.showPairing = true } }
            ))
        }

        return cells
    }

    private var legalCells: [SettingsCellDescriptor] {
        [
            SettingsCellDescriptor(
                id: "privacy", icon: "hand.raised", title: "隐私政策",
                showsExternalLink: true,
                kind: .button { showPrivacyPolicy = true }
            ),
            SettingsCellDescriptor(
                id: "tos", icon: "doc.text", title: "服务条款",
                showsExternalLink: true,
                kind: .button { showTermsOfService = true }
            ),
            SettingsCellDescriptor(
                id: "memory", icon: "brain.head.profile", title: "长期记忆管理",
                kind: .navigation(AnyView(Text("Memory Management")))
            ),
        ]
    }
}

// MARK: - Cell Descriptor

private struct SettingsCellDescriptor: Identifiable {
    let id: String
    let icon: String
    let title: String
    var value: String? = nil
    var iconColor: Color? = nil
    var showsExternalLink: Bool = false
    var kind: CellKind = .info

    enum CellKind {
        case navigation(AnyView)
        case toggle(Binding<Bool>)
        case button(() -> Void)
        case destructiveButton(() -> Void)
        case info
    }
}

// MARK: - Sub Views

struct ModelSelectionView: View {
    @Environment(AppState.self) private var appState
    @Binding var selectedModel: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            Section {
                ForEach(appState.allAvailableModels, id: \.self) { model in
                    Button {
                        selectedModel = model
                        dismiss()
                    } label: {
                        HStack {
                            Text(model)
                                .foregroundStyle(.primary)
                            Spacer()
                            if model == selectedModel {
                                Image(systemName: "checkmark")
                                    .fontWeight(.semibold)
                                    .foregroundStyle(appState.currentVisualTheme.accent)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("选择默认模型")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
    }
}

struct ThemeSelectionView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            Section {
                ForEach(AppVisualThemeID.allCases) { themeId in
                    let theme = AppVisualTheme.theme(for: themeId)
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            appState.selectedVisualThemeID = themeId
                        }
                        UIApplication.shared.setAlternateIconName(themeId.alternateIconName)
                        dismiss()
                    } label: {
                        HStack {
                            Text(theme.displayName)
                                .foregroundStyle(.primary)
                            Spacer()
                            if themeId == appState.selectedVisualThemeID {
                                Image(systemName: "checkmark")
                                    .fontWeight(.semibold)
                                    .foregroundStyle(appState.currentVisualTheme.accent)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("选择视觉主题")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
    }
}
