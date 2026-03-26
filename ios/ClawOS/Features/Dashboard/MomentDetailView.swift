import SwiftUI

struct MomentDetailOverlay: View {
    @Environment(AppState.self) private var appState
    let moment: MockMoment

    @State private var dragOffset: CGSize = .zero
    @State private var dismissAxis: MomentDismissAxis?
    @State private var isDragging = false
    @State private var isPresented = false
    @State private var selectedImageIndex = 0

    private var dismissProgress: CGFloat {
        MomentDismissGestureBehavior.dismissProgress(for: dragOffset, axis: dismissAxis)
    }

    var body: some View {
        ZStack {
            Color.black
                .opacity(isPresented ? Double(1 - dismissProgress) * 0.8 : 0)
                .ignoresSafeArea()
                .onTapGesture { dismiss() }

            MomentDetailView(moment: moment, selectedImageIndex: $selectedImageIndex, onDismiss: { dismiss() })
                .ignoresSafeArea()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .compositingGroup()
                .clipShape(RoundedRectangle(cornerRadius: isDragging ? 24 : 0, style: .continuous))
                .scaleEffect(isDragging ? max(0.8, 1.0 - dismissProgress * 0.2) : 1.0)
                .offset(x: dragOffset.width, y: dragOffset.height)
                .offset(x: isPresented ? 0 : UIScreen.main.bounds.width)
                .simultaneousGesture(contentDismissGesture)
                .overlay(alignment: .leading) {
                    Color.clear
                        .frame(width: MomentDismissGestureBehavior.edgeActivationWidth)
                        .frame(maxHeight: .infinity)
                        .contentShape(Rectangle())
                        .highPriorityGesture(edgeDismissGesture)
                }
        }
        .onAppear {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.88)) {
                isPresented = true
            }
        }
    }

    private var contentDismissGesture: some Gesture {
        dismissGesture(
            allowsContentHorizontalDismiss: selectedImageIndex == 0,
            requiresEdgeStart: false
        )
    }

    private var edgeDismissGesture: some Gesture {
        dismissGesture(
            allowsContentHorizontalDismiss: true,
            requiresEdgeStart: true
        )
    }

    private func dismissGesture(
        allowsContentHorizontalDismiss: Bool,
        requiresEdgeStart: Bool
    ) -> some Gesture {
        DragGesture(minimumDistance: 4, coordinateSpace: .global)
            .onChanged { value in
                if dismissAxis == nil {
                    dismissAxis = MomentDismissGestureBehavior.beginAxis(
                        startLocation: value.startLocation,
                        translation: value.translation,
                        allowsContentHorizontalDismiss: allowsContentHorizontalDismiss,
                        requiresEdgeStart: requiresEdgeStart
                    )

                    if dismissAxis != nil {
                        isDragging = true
                    }
                }

                guard let dismissAxis else { return }
                dragOffset = MomentDismissGestureBehavior.resolvedOffset(
                    for: value.translation,
                    axis: dismissAxis
                )
            }
            .onEnded { value in
                guard let dismissAxis else {
                    resetDragState(animated: false)
                    return
                }

                let resolvedTranslation = MomentDismissGestureBehavior.resolvedOffset(
                    for: value.translation,
                    axis: dismissAxis
                )
                let resolvedVelocity = MomentDismissGestureBehavior.resolvedOffset(
                    for: value.velocity,
                    axis: dismissAxis
                )

                dragOffset = resolvedTranslation

                if MomentDismissGestureBehavior.shouldDismiss(
                    translation: resolvedTranslation,
                    velocity: resolvedVelocity,
                    axis: dismissAxis
                ) {
                    dismiss(velocityX: resolvedVelocity.width, velocityY: resolvedVelocity.height)
                } else {
                    resetDragState(animated: true)
                }
            }
    }

    private func resetDragState(animated: Bool) {
        let updates = {
            dragOffset = .zero
            isDragging = false
            dismissAxis = nil
        }

        if animated {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.82)) {
                updates()
            }
        } else {
            updates()
        }
    }

    private func dismiss(velocityX: CGFloat = 0, velocityY: CGFloat = 0) {
        let sw = UIScreen.main.bounds.width + 60
        let sh = UIScreen.main.bounds.height + 60

        withAnimation(.easeOut(duration: 0.26)) {
            if abs(velocityX) > abs(velocityY) || abs(dragOffset.width) > abs(dragOffset.height) {
                dragOffset.width = velocityX >= 0 && dragOffset.width >= 0 ? sw : -sw
                dragOffset.height += velocityY * MomentDismissGestureBehavior.crossAxisDamping
            } else {
                dragOffset.height = velocityY >= 0 && dragOffset.height >= 0 ? sh : -sh
                dragOffset.width += velocityX * MomentDismissGestureBehavior.crossAxisDamping
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
            dismissAxis = nil
            appState.selectedMoment = nil
        }
    }
}

struct MomentDetailView: View {
    @Environment(AppState.self) private var appState

    let moment: MockMoment
    @Binding var selectedImageIndex: Int
    var onDismiss: () -> Void

    @State private var isLiked: Bool
    @State private var showHireConfirmation = false
    @State private var cardPullUp: CGFloat = 0
    @State private var lastCardPullUp: CGFloat = 0

    private let minCardPull: CGFloat = 0
    private let maxCardPull: CGFloat = UIScreen.main.bounds.height * 0.45

    private var pullProgress: CGFloat { min(1, cardPullUp / maxCardPull) }

    init(moment: MockMoment, selectedImageIndex: Binding<Int>, onDismiss: @escaping () -> Void) {
        self.moment = moment
        self._selectedImageIndex = selectedImageIndex
        self.onDismiss = onDismiss
        self._isLiked = State(initialValue: moment.isLiked)
    }

    private var gradientTop: Color {
        Color(hex: moment.coverGradient.first ?? "667eea")
    }

    private var gradientBottom: Color {
        Color(hex: moment.coverGradient.last ?? "764ba2")
    }

    private var ctaColor: Color {
        appState.currentVisualTheme.accent
    }

    private var safeBottomInset: CGFloat {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        return scenes.first?.keyWindow?.safeAreaInsets.bottom ?? 0
    }

    private var ctaBottomPadding: CGFloat {
        max(16, min(20, safeBottomInset))
    }

    private var ctaReservedHeight: CGFloat {
        58 + ctaBottomPadding
    }

    private var displayLikes: String {
        let count = moment.likes + (isLiked && !moment.isLiked ? 1 : 0) - (!isLiked && moment.isLiked ? 1 : 0)
        if count >= 10000 { return String(format: "%.1fw", Double(count) / 10000) }
        if count >= 1000 { return String(format: "%.1fk", Double(count) / 1000) }
        return "\(count)"
    }

    var body: some View {
        ZStack {
            fullScreenCover()

            VStack {
                Spacer()
                LinearGradient(
                    colors: [.clear, Color.black.opacity(0.6)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 200)
            }
            .ignoresSafeArea()

            VStack(spacing: 0) {
                topOverlay()
                Spacer()
                informationCard
            }
        }
        .ignoresSafeArea()
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
    }

    // MARK: - Full-Screen Cover (URL / Asset / Gradient)

    @ViewBuilder
    private func fullScreenCover() -> some View {
        let imgs = moment.images.filter { !$0.isEmpty }
        if imgs.isEmpty {
            fullScreenGradientCover()
        } else if imgs.first?.hasPrefix("http") == true {
            urlImageCarousel(imgs)
        } else {
            assetImageCarousel(imgs)
        }
    }

    private func urlImageCarousel(_ urls: [String]) -> some View {
        ZStack {
            if let urlStr = urls[safe: selectedImageIndex],
               let url = URL(string: urlStr) {
                RemoteImageView(url: url) { isLoading in
                    fullScreenGradientCover()
                        .overlay {
                            if isLoading {
                                ProgressView().tint(.white)
                            }
                        }
                }
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                .clipped()
                .ignoresSafeArea()
            }

            if urls.count > 1 {
                TabView(selection: $selectedImageIndex) {
                    ForEach(0..<urls.count, id: \.self) { index in
                        Color.clear
                            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                            .contentShape(Rectangle())
                            .tag(index)
                    }
                }
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                .tabViewStyle(.page(indexDisplayMode: .never))
                .background(Color.clear)
                .ignoresSafeArea()
            }
        }
    }

    private func assetImageCarousel(_ names: [String]) -> some View {
        ZStack {
            Image(names[selectedImageIndex])
                .resizable()
                .scaledToFill()
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                .clipped()
                .ignoresSafeArea()

            if names.count > 1 {
                TabView(selection: $selectedImageIndex) {
                    ForEach(0..<names.count, id: \.self) { index in
                        Color.clear
                            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                            .contentShape(Rectangle())
                            .tag(index)
                    }
                }
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                .tabViewStyle(.page(indexDisplayMode: .never))
                .background(Color.clear)
                .ignoresSafeArea()
            }
        }
    }

    private func fullScreenGradientCover() -> some View {
        GeometryReader { geo in
            ZStack {
                LinearGradient(
                    colors: [gradientTop, gradientBottom],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                Circle()
                    .fill(Color.white.opacity(0.05))
                    .frame(width: geo.size.width * 1.2)
                    .offset(x: geo.size.width * 0.3, y: -geo.size.height * 0.15)

                Image(systemName: moment.coverIcon)
                    .font(.system(size: min(geo.size.width, geo.size.height) * 0.25, weight: .ultraLight))
                    .foregroundStyle(.white.opacity(0.25))
                    .offset(y: -geo.size.height * 0.1)
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - Top Overlay

    private func topOverlay() -> some View {
        VStack(spacing: 12) {
            HStack {
                Button { onDismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(.ultraThinMaterial, in: Circle())
                }

                Spacer()

                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        isLiked.toggle()
                    }
                } label: {
                    Image(systemName: isLiked ? "heart.fill" : "heart")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(isLiked ? Color.red : .white)
                        .frame(width: 36, height: 36)
                        .background(.ultraThinMaterial, in: Circle())
                }

                Button { shareMoment() } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(.ultraThinMaterial, in: Circle())
                }
            }
            .padding(.horizontal, 16)

            let imgCount = moment.images.filter { !$0.isEmpty }.count
            if imgCount > 1 {
                HStack(spacing: 6) {
                    ForEach(0..<imgCount, id: \.self) { index in
                        Capsule()
                            .fill(index == selectedImageIndex ? Color.white : Color.white.opacity(0.4))
                            .frame(width: index == selectedImageIndex ? 20 : 8, height: 4)
                            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                            .animation(.easeInOut(duration: 0.2), value: selectedImageIndex)
                    }
                }
            }

        }
        .padding(.top, 60)
    }

    // MARK: - Information Card (pull-up)

    private var informationCard: some View {
        let baseHeight = UIScreen.main.bounds.height * 0.45
        let currentHeight = baseHeight + cardPullUp

        return VStack(alignment: .leading, spacing: 0) {
            // Drag Handle Area
            VStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 2.5)
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 36, height: 5)
                    .padding(.top, 10)
                    .padding(.bottom, 6)
                
                // Add some empty space below the handle to increase the drag target area
                Color.clear.frame(height: 10)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .gesture(cardDragGesture)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 12) {
                    authorRow

                    Text(moment.title)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.white)

                    Text(moment.content)
                        .font(.system(size: 15))
                        .foregroundStyle(.white.opacity(0.9))
                        .lineSpacing(4)

                    engagementRow
                        .padding(.top, 8)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, ctaReservedHeight)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .frame(minWidth: 0, maxWidth: .infinity)
        .frame(height: currentHeight, alignment: .top)
        .background(
            ZStack {
                Color(red: 0.08, green: 0.08, blue: 0.1)
                    .opacity(0.95)

                LinearGradient(
                    colors: [Color.black.opacity(0.3), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .contentShape(Rectangle())
        )
        .clipShape(
            UnevenRoundedRectangle(
                cornerRadii: .init(
                    topLeading: 0,
                    bottomLeading: 28,
                    bottomTrailing: 28,
                    topTrailing: 0
                )
            )
        )
        .shadow(color: Color.black.opacity(0.4), radius: 20, x: 0, y: -8)
        .padding(.top, -20)
        .overlay(alignment: .bottom) {
            ctaBar
                .padding(.horizontal, 24)
                .padding(.bottom, ctaBottomPadding)
        }
    }

    private var cardDragGesture: some Gesture {
        DragGesture(coordinateSpace: .global)
            .onChanged { value in
                guard abs(value.translation.height) > abs(value.translation.width) else { return }
                let translation = -value.translation.height
                cardPullUp = max(minCardPull, min(maxCardPull, lastCardPullUp + translation))
            }
            .onEnded { value in
                guard abs(value.translation.height) > abs(value.translation.width) else { return }
                let velocity = -value.velocity.height
                let translation = -value.translation.height
                let projectedPosition = lastCardPullUp + translation + velocity * 0.2

                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    if projectedPosition > maxCardPull * 0.3 {
                        cardPullUp = maxCardPull
                    } else {
                        cardPullUp = 0
                    }
                    lastCardPullUp = cardPullUp
                }
            }
    }

    // MARK: - Author Row

    private var authorRow: some View {
        HStack(spacing: 10) {
            detailAvatarView(size: 34)

            VStack(alignment: .leading, spacing: 2) {
                Text(moment.authorName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)

                HStack(spacing: 4) {
                    Text(displayLikes)
                        .font(.system(size: 11, weight: .medium))
                    Text("likes")
                        .font(.system(size: 11))
                    Text("·")
                    Text(moment.timeAgo)
                        .font(.system(size: 11))
                }
                .foregroundStyle(.white.opacity(0.5))
            }

            Spacer()
        }
    }

    // MARK: - Engagement Row

    private var engagementRow: some View {
        HStack(spacing: 16) {
            Label("\(moment.comments) 条评论", systemImage: "bubble.right")
            Label(moment.timeAgo, systemImage: "clock")
            Spacer()
        }
        .font(.system(size: 12))
        .foregroundStyle(.white.opacity(0.4))
        .padding(.top, 4)
    }

    // MARK: - CTA Bar

    private var ctaBar: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            withAnimation(.spring(response: 0.3)) {
                showHireConfirmation = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation { showHireConfirmation = false }
            }
        } label: {
            Text(showHireConfirmation ? "已加入候选" : "雇佣 \(moment.authorName)")
                .font(.system(size: 15, weight: .bold))
                .lineLimit(1)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .adaptiveTintedGlass(in: Capsule(), tint: ctaColor, interactive: true)
        }
        .buttonStyle(BounceButtonStyle())
    }

    // MARK: - Share

    private func shareMoment() {
        let text = "\(moment.title)\n\n\(moment.content)\n\n— \(moment.authorName) via ClawOS"
        let items: [Any] = [text]

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = windowScene.keyWindow?.rootViewController else { return }

        let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
        activityVC.popoverPresentationController?.sourceView = root.view
        activityVC.popoverPresentationController?.sourceRect = CGRect(x: root.view.bounds.midX, y: 60, width: 0, height: 0)
        root.present(activityVC, animated: true)
    }

    // MARK: - Avatar

    @ViewBuilder
    private func detailAvatarView(size: CGFloat) -> some View {
        if !moment.authorAvatar.isEmpty, UIImage(named: moment.authorAvatar) != nil {
            Image(moment.authorAvatar)
                .resizable()
                .scaledToFill()
                .frame(width: size, height: size)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1))
        } else {
            let g0 = Color(hex: moment.avatarGradient.first ?? "667eea")
            let g1 = Color(hex: moment.avatarGradient.last ?? "764ba2")
            Circle()
                .fill(LinearGradient(colors: [g0, g1], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: size, height: size)
                .overlay(
                    Image(systemName: moment.coverIcon)
                        .font(.system(size: size * 0.4, weight: .medium))
                        .foregroundStyle(.white)
                )
                .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1))
        }
    }
}

// MARK: - Safe Array Subscript

private extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Custom Button Style

struct BounceButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}
