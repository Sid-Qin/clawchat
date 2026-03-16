import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @AppStorage("isDarkMode") private var isDarkMode = false
    @State private var skillsWatchEnabled = true
    @State private var selectedModel = "MiniMax-M2.5"

    private var currentAgent: Agent {
        appState.selectedAgent ?? MockData.agents[0]
    }

    var body: some View {
        Form {
            // MARK: - Profile Header
            Section {
                HStack(spacing: 16) {
                    Image(currentAgent.avatar)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 56, height: 56)
                        .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(currentAgent.name)
                            .font(.headline)
                        Text("@\(currentAgent.id)_agent")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }

            // MARK: - General
            Section(header: Text("通用设置")) {
                NavigationLink {
                    ThemeSelectionView()
                        .environment(appState)
                } label: {
                    settingRow(icon: "circle.lefthalf.filled", title: "视觉主题", value: appState.currentVisualTheme.displayName)
                }
                
                NavigationLink {
                    ModelSelectionView(selectedModel: $selectedModel)
                } label: {
                    settingRow(icon: "cpu", title: "默认大语言模型", value: selectedModel)
                }
                
                Toggle(isOn: $isDarkMode) {
                    settingRow(icon: "moon", title: "暗色模式", value: nil)
                }
                .tint(appState.currentVisualTheme.accent)
            }

            // MARK: - Skills & Capabilities
            Section(header: Text("技能与能力")) {
                NavigationLink {
                    Text("Skills Settings")
                } label: {
                    settingRow(icon: "puzzlepiece.extension", title: "Skills 设定", value: "\(appState.skills.filter(\.isEnabled).count) 个已启用")
                }
                
                Toggle(isOn: $skillsWatchEnabled) {
                    settingRow(icon: "arrow.triangle.2.circlepath", title: "Skills 自动重载 (Watch)", value: nil)
                }
                .tint(appState.currentVisualTheme.accent)
            }

            // MARK: - Core Files
            Section(header: Text("核心文件配置")) {
                fileNavRow(icon: "doc.text", title: "soul.md")
                fileNavRow(icon: "person.text.rectangle", title: "agent.md")
                fileNavRow(icon: "person.crop.square", title: "identity.md")
                fileNavRow(icon: "hammer", title: "tools.json")
                fileNavRow(icon: "person.2", title: "users.json")
            }

            // MARK: - Memory
            Section(header: Text("记忆与上下文")) {
                NavigationLink {
                    Text("Memory Management")
                } label: {
                    settingRow(icon: "brain.head.profile", title: "长期记忆管理", value: nil)
                }
            }
        }
        .navigationTitle("设置")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .scrollContentBackground(.hidden)
        .background {
            LinearGradient(
                colors: [appState.currentVisualTheme.pageGradientTop, appState.currentVisualTheme.pageGradientBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
    }

    // MARK: - Helpers

    private func settingRow(icon: String, title: String, value: String?) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .regular))
                .foregroundStyle(.secondary)
                .frame(width: 24)
            Text(title)
                .foregroundStyle(.primary)
                .font(.system(size: 17))
            Spacer()
            if let value = value {
                Text(value)
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
            }
        }
    }

    private func fileNavRow(icon: String, title: String) -> some View {
        NavigationLink {
            Text("Editing \(title)")
        } label: {
            settingRow(icon: icon, title: title, value: nil)
        }
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
                ForEach(MockData.availableModels, id: \.self) { model in
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
