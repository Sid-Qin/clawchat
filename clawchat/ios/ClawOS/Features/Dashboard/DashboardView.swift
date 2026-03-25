import SwiftUI

struct DashboardView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.colorScheme) private var colorScheme
    @State private var viewModel = DashboardViewModel()
    @State private var selectedTab: Int = 0

    private var theme: AppVisualTheme { appState.currentVisualTheme }

    var body: some View {
        VStack(spacing: 0) {
            headerTabs

            TabView(selection: $selectedTab) {
                feedPage(moments: viewModel.moments)
                    .tag(0)

                feedPage(moments: viewModel.moments.filter { $0.isFollowed })
                    .tag(1)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .background {
            LinearGradient(
                colors: [theme.pageGradientTop, theme.pageGradientBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: - Feed Page

    private func cardHeight(for moment: MockMoment) -> CGFloat {
        let imgHeight = CGFloat(220 + (abs(moment.id.hashValue) % 80))
        return imgHeight + 80
    }

    private func splitColumns(_ moments: [MockMoment]) -> ([MockMoment], [MockMoment]) {
        var left: [MockMoment] = []
        var right: [MockMoment] = []
        var leftH: CGFloat = 0
        var rightH: CGFloat = 0

        for moment in moments {
            let h = cardHeight(for: moment) + 6
            if leftH <= rightH {
                left.append(moment)
                leftH += h
            } else {
                right.append(moment)
                rightH += h
            }
        }
        return (left, right)
    }

    private func gridHeight(for moments: [MockMoment]) -> CGFloat {
        let (leftCol, rightCol) = splitColumns(moments)
        let leftH = leftCol.reduce(CGFloat(0)) { $0 + cardHeight(for: $1) + 6 }
        let rightH = rightCol.reduce(CGFloat(0)) { $0 + cardHeight(for: $1) + 6 }
        return max(leftH, rightH)
    }

    private func feedPage(moments: [MockMoment]) -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                Color.clear.frame(height: 6)
                
                if moments.isEmpty {
                    emptyState
                } else {
                    let (leftCol, rightCol) = splitColumns(moments)

                    GeometryReader { geo in
                        let colWidth = (geo.size.width - 6 * 2 - 6) / 2

                        HStack(alignment: .top, spacing: 6) {
                            LazyVStack(spacing: 6) {
                                ForEach(leftCol) { moment in
                                    Button {
                                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                            appState.selectedMoment = moment
                                        }
                                    } label: {
                                        MomentsCardView(
                                            moment: moment,
                                            colorScheme: colorScheme,
                                            theme: theme
                                        )
                                        .frame(width: colWidth)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .frame(width: colWidth)

                            LazyVStack(spacing: 6) {
                                ForEach(rightCol) { moment in
                                    Button {
                                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                            appState.selectedMoment = moment
                                        }
                                    } label: {
                                        MomentsCardView(
                                            moment: moment,
                                            colorScheme: colorScheme,
                                            theme: theme
                                        )
                                        .frame(width: colWidth)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .frame(width: colWidth)
                        }
                        .padding(.horizontal, 6)
                    }
                    .frame(height: gridHeight(for: moments))
                }

                Color.clear.frame(height: 16)
            }
        }
        .refreshable {
            await viewModel.refresh()
        }
    }

    // MARK: - Header Tabs

    private var headerBg: Color {
        colorScheme == .dark ? Color(white: 0.08) : .white
    }

    private var headerTabs: some View {
        VStack(spacing: 0) {
            HStack(spacing: 28) {
                tabButton(title: "发现", index: 0)
                tabButton(title: "关注", index: 1)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 8)
            .frame(height: 50)

            Divider().opacity(0.3)
        }
        .background(headerBg)
    }

    private func tabButton(title: String, index: Int) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.25)) {
                selectedTab = index
            }
        } label: {
            VStack(spacing: 4) {
                Text(title)
                    .font(.system(size: selectedTab == index ? 18 : 16, weight: selectedTab == index ? .bold : .medium))
                    .foregroundStyle(selectedTab == index ? Color(.label) : Color(.secondaryLabel))

                Capsule()
                    .fill(selectedTab == index ? theme.accent : Color.clear)
                    .frame(width: 20, height: 3)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkles.rectangle.stack")
                .resizable()
                .scaledToFit()
                .frame(width: 44, height: 44)
                .foregroundStyle(Color(.systemGray3))

            VStack(spacing: 6) {
                Text("暂无动态")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color(.secondaryLabel))
                Text("关注感兴趣的创作者，这里会展示他们的最新动态")
                    .font(.caption)
                    .foregroundStyle(Color(.tertiaryLabel))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 160)
    }
}
