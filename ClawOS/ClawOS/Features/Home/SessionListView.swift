import SwiftUI

struct SessionListView: View {
    @Environment(AppState.self) private var appState
    @State private var searchText = ""
    var isSidebarDragging = false
    var onMenuTap: () -> Void = {}

    private var filteredSessions: [Session] {
        let visibleAgentIds = Set(appState.currentGatewayAgents.map(\.id))
        let gatewaySessions = appState.sessions.filter { visibleAgentIds.contains($0.agentId) }
        if searchText.isEmpty {
            return gatewaySessions
        }
        return gatewaySessions.filter { session in
            let agent = appState.agent(for: session.agentId)
            return session.title.localizedCaseInsensitiveContains(searchText)
                || (agent?.name.localizedCaseInsensitiveContains(searchText) ?? false)
                || (session.lastMessage?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    @FocusState private var isSearchFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            header
            searchBar
            sessionList
        }
        .background {
            LinearGradient(
                colors: [appState.currentVisualTheme.pageGradientTop, appState.currentVisualTheme.pageGradientBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .contentShape(Rectangle())
            .onTapGesture {
                if isSearchFocused {
                    isSearchFocused = false
                }
            }
        }
        .onChange(of: isSearchFocused) { _, focused in
            if !focused && searchText.isEmpty {
                searchText = ""
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Button(action: onMenuTap) {
                Image(systemName: "text.justify.left")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(width: 36, height: 36)
                    .contentShape(Circle())
            }
            .glassEffect(.regular, in: .circle)

            Spacer()

            Text(appState.selectedAgent?.name ?? "ClawOS")
                .font(.headline)

            Spacer()

            Button { } label: {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(width: 36, height: 36)
                    .contentShape(Circle())
            }
            .glassEffect(.regular, in: .circle)
        }
        .padding(.horizontal, AppTheme.Spacing.lg)
        .padding(.top, 4)
        .padding(.bottom, 8)
    }

    // MARK: - Search

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
                .font(.system(size: 14, weight: .medium))
            TextField("搜索", text: $searchText)
                .textFieldStyle(.plain)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .focused($isSearchFocused)
        }
        .padding(.horizontal, 14)
        .frame(height: 38)
        .glassEffect(.regular, in: .capsule)
        .padding(.horizontal, AppTheme.Spacing.lg)
        .padding(.bottom, AppTheme.Spacing.sm)
    }

    // MARK: - List

    private var sessionList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(filteredSessions) { session in
                    NavigationLink(value: session) {
                        SessionRowView(session: session)
                    }
                    .buttonStyle(.plain)
                    .disabled(isSidebarDragging)
                }

                if filteredSessions.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "tray")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                        Text("暂无会话")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 80)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .contentShape(Rectangle())
        }
        .scrollDismissesKeyboard(.immediately)
        .simultaneousGesture(
            TapGesture().onEnded {
                if isSearchFocused { isSearchFocused = false }
            }
        )
        .navigationDestination(for: Session.self) { session in
            ChatView(session: session)
        }
    }
}

// MARK: - Session Row

struct SessionRowView: View {
    @Environment(AppState.self) private var appState
    let session: Session

    private var agent: Agent? {
        appState.agent(for: session.agentId)
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack(alignment: .bottomTrailing) {
                Image(agent?.avatar ?? "avatar_eva01")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 44, height: 44)
                    .clipShape(Circle())

                if let agent {
                    StatusIndicator(status: agent.status, size: 12)
                        .offset(x: 1, y: 1)
                }
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(agent?.name ?? "Unknown")
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    Spacer()
                    Text(session.timeAgo)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }

                if let lastMessage = session.lastMessage {
                    Text(lastMessage)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            if session.unreadCount > 0 {
                Text("\(session.unreadCount)")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .frame(minWidth: 20, minHeight: 20)
                    .background(Color(.label), in: Capsule())
            }
        }
        .padding(.horizontal, AppTheme.Spacing.lg)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }
}
