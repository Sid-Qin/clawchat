import SwiftUI

struct DashboardView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedPeriod = 0

    private var currentTheme: AppVisualTheme {
        appState.currentVisualTheme
    }

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.lg) {
                tokenUsageCard
                configCard
                notificationsSection
            }
            .padding(.horizontal, AppTheme.Spacing.lg)
            .padding(.top, 8)
            .padding(.bottom, 80)
        }
        .scrollIndicators(.hidden)
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
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: - Token Usage

    private var tokenUsageCard: some View {
        GlassCard(cornerRadius: 20) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                HStack {
                    Text("Token 用量")
                        .font(.headline)
                    Spacer()
                    Picker("", selection: $selectedPeriod) {
                        Text("7天").tag(0)
                        Text("30天").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 120)
                }

                Text("46.8M")
                    .font(.system(size: 40, weight: .bold, design: .rounded))

                Text("tokens - 过去 7 天")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack(spacing: 0) {
                    tokenStat(label: "输入", value: "29.6M")
                    Spacer()
                    tokenStat(label: "输出", value: "84.0K")
                    Spacer()
                    tokenStat(label: "缓存", value: "17.1M")
                }
                .padding(12)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: AppTheme.Radius.md))

                VStack(spacing: AppTheme.Spacing.lg) {
                    TokenProgressBar(label: "MiniMax-M2.5", value: "32.1M", progress: 0.7, tint: Color(.label))
                    TokenProgressBar(label: "Claude 3.5 Sonnet", value: "14.7M", progress: 0.3, tint: Color(.secondaryLabel))
                }
            }
        }
        .background {
            ZStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                currentTheme.softFill.opacity(0.95),
                                Color.white.opacity(0.68),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                if let bannerAssetName = currentTheme.bannerAssetName {
                    Image(bannerAssetName)
                        .resizable()
                        .scaledToFill()
                        .opacity(0.08)
                        .rotationEffect(.degrees(-12))
                        .scaleEffect(1.4)
                        .blendMode(.multiply)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(currentTheme.softStroke.opacity(0.9), lineWidth: 0.9)
        )
    }

    private func tokenStat(label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
    }

    // MARK: - Config & Diagnostics

    private var configCard: some View {
        GlassCard(cornerRadius: 20) {
            VStack(alignment: .leading, spacing: 0) {
                sectionHeader("OPENCLAW 配置")
                actionRow(icon: "doc.text", title: "查看配置")
                actionRow(icon: "arrow.clockwise", title: "恢复配置备份")
                actionRow(icon: "eye", title: "开启 Skills Watch")

                sectionHeader("诊断与日志")
                    .padding(.top, AppTheme.Spacing.lg)
                actionRow(icon: "cross.case", title: "运行诊断")
                actionRow(icon: "list.bullet", title: "查看日志")

                sectionHeader("系统维护")
                    .padding(.top, AppTheme.Spacing.lg)
                actionRow(icon: "wrench.and.screwdriver", title: "工具权限修复")
                actionRow(icon: "power", title: "重启 Gateway", isDanger: true)
                actionRow(icon: "arrow.up.circle", title: "更新 openclaw")
            }
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.caption)
            .fontWeight(.semibold)
            .tracking(1)
            .foregroundStyle(.secondary)
            .padding(.bottom, 8)
    }

    private func actionRow(icon: String, title: String, isDanger: Bool = false) -> some View {
        Button { } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .regular))
                    .foregroundStyle(.secondary)
                    .frame(width: 24)
                Text(title)
                    .foregroundStyle(.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
        .overlay(alignment: .bottom) { Divider() }
    }

    // MARK: - Notifications

    private var notificationsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("最新消息")
                .font(.caption)
                .fontWeight(.semibold)
                .tracking(1)
                .foregroundStyle(.secondary)

            alertCard(
                icon: "exclamationmark.circle.fill",
                title: "工具执行失败",
                description: "Agent \"EVA-01\" 尝试执行 shell 命令时被拒绝，权限未开启。",
                time: "10 分钟前"
            )

            alertCard(
                icon: "arrow.up.circle.fill",
                title: "有新版本可用",
                description: "OpenClaw v2026.3.9 已发布，包含性能优化和新的模型支持。",
                time: "2 小时前"
            )
        }
    }

    private func alertCard(icon: String, title: String, description: String, time: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .regular))
                    .foregroundStyle(.secondary)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
            }

            Text(description)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(time)
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppTheme.Spacing.lg)
        .glassEffect(.regular, in: .rect(cornerRadius: AppTheme.Radius.md))
    }
}
