import SwiftUI
import ClawChatKit

struct HomeView: View {
    @Environment(AppState.self) private var appState
    @State private var searchText = ""
    @State private var isSearchExpanded = false
    @State private var folderOverlayActive = false
    @State private var folderPopoverGroupId: String?
    @State private var dragCoordinator = AgentDragCoordinator()
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        ZStack {
            SessionListView(searchText: $searchText)
                .safeAreaInset(edge: .top, spacing: 0) {
                    topChrome
                }
                .allowsHitTesting(!folderOverlayActive)
                .onTapGesture {
                    isSearchFocused = false
                    isSearchExpanded = false
                }

            if folderOverlayActive,
               let groupId = folderPopoverGroupId,
               let item = appState.agentStripItems.first(where: { $0.id == groupId }),
               case .group(let group) = item {
                folderPopoverOverlay(group: group)
            }
        }
        .environment(dragCoordinator)
        .background {
            LinearGradient(
                colors: [appState.currentVisualTheme.pageGradientTop,
                         appState.currentVisualTheme.pageGradientBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
        .ignoresSafeArea(edges: .bottom)
        .navigationBarHidden(true)
    }

    private var topChrome: some View {
        VStack(spacing: 0) {
            headerBar
            AgentStripView(folderOverlayActive: $folderOverlayActive, folderPopoverGroupId: $folderPopoverGroupId)
                .padding(.bottom, 8)
        }
        .background(Color.clear)
        .zIndex(20)
    }

    // MARK: - Header Bar

    private var headerBar: some View {
        HStack(spacing: 8) {
            gatewayPicker

            Spacer()

            if isSearchExpanded {
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)

                    TextField("搜索", text: $searchText)
                        .focused($isSearchFocused)
                        .textFieldStyle(.plain)
                        .font(.system(size: 14))
                        .frame(width: 100)

                    Button {
                        searchText = ""
                        isSearchExpanded = false
                        isSearchFocused = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(.tertiary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 12)
                .frame(height: 36)
                .adaptiveGlass(in: .capsule)
                .transition(.opacity.combined(with: .scale(scale: 0.9, anchor: .trailing)))
            }

            if !isSearchExpanded {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(width: 36, height: 36)
                    .contentShape(Circle())
                    .adaptiveGlass(in: .circle)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            isSearchExpanded = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            isSearchFocused = true
                        }
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }

            Image(systemName: "square.and.pencil")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(width: 36, height: 36)
                .contentShape(Circle())
                .adaptiveGlass(in: .circle)
                .onTapGesture {
                    _ = appState.startNewSession()
                }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 4)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSearchExpanded)
    }

    // MARK: - Gateway Picker

    private var gatewayPicker: some View {
        Menu {
            if appState.gateways.isEmpty {
                Button {
                    appState.showPairing = true
                } label: {
                    Label("配对服务器", systemImage: "antenna.radiowaves.left.and.right")
                }
            } else {
                ForEach(appState.gateways) { gw in
                    Button {
                        appState.selectGateway(gw.id)
                    } label: {
                        HStack {
                            Label {
                                VStack(alignment: .leading) {
                                    Text(gw.name)
                                    Text(gw.url)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            } icon: {
                                Image(systemName: gatewayIcon(gw.type))
                            }
                            if gw.id == appState.selectedGatewayId {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }

                Divider()

                Button {
                    appState.showPairing = true
                } label: {
                    Label("添加服务器", systemImage: "plus")
                }
            }
        } label: {
            HStack(spacing: 6) {
                connectionDot
                Image(systemName: gwTypeIcon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.primary)
            }
            .padding(.horizontal, 12)
            .frame(height: 36)
            .adaptiveGlass(in: .capsule)
        }
    }

    private var connectionDot: some View {
        let color: Color = switch appState.clawChatManager.linkState {
        case .connected: .green
        case .connecting: .orange
        default: Color(.systemGray3)
        }
        return Circle()
            .fill(color)
            .frame(width: 8, height: 8)
    }

    private var gwTypeIcon: String {
        guard let gw = appState.currentGateway else { return "antenna.radiowaves.left.and.right" }
        return gatewayIcon(gw.type)
    }

    private func gatewayIcon(_ type: GatewayType) -> String {
        switch type {
        case .local: "desktopcomputer"
        case .cloud: "cloud.fill"
        case .custom: "server.rack"
        }
    }

    // MARK: - Folder Popover (elevated z-level)

    private func folderPopoverOverlay(group: AgentGroup) -> some View {
        let groupItemId = "group_\(group.id)"

        return ZStack {
            Color.black.opacity(0.01)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeOut(duration: 0.2)) {
                        folderOverlayActive = false
                        folderPopoverGroupId = nil
                    }
                }

            AgentFolderPopoverView(
                group: group,
                isEditMode: dragCoordinator.isEditMode,
                onSelectAgent: { agentId in
                    appState.selectAgentInGroup(agentId, groupItemId: groupItemId)
                    withAnimation(.easeOut(duration: 0.2)) {
                        folderOverlayActive = false
                    }
                },
                onDismiss: {
                    withAnimation(.easeOut(duration: 0.2)) {
                        folderOverlayActive = false
                        folderPopoverGroupId = nil
                    }
                }
            )
            .transition(.scale(scale: 0.9, anchor: .top).combined(with: .opacity))
            .padding(.top, 140)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .zIndex(200)
    }
}
