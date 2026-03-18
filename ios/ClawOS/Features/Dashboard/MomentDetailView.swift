import SwiftUI

struct MomentDetailOverlay: View {
    @Environment(AppState.self) private var appState
    let moment: MockMoment
    
    @State private var dragOffset: CGSize = .zero
    @State private var isDragging = false
    @State private var isPresented = false
    
    @State private var selectedImageIndex = 0
    
    var body: some View {
        ZStack {
            // Background dimming
            Color.black
                .opacity(isPresented ? max(0, 0.8 - Double(abs(dragOffset.width) / 500) - Double(abs(dragOffset.height) / 500)) : 0)
                .ignoresSafeArea()
                .onTapGesture {
                    dismiss()
                }
            
            // Main Content
            MomentDetailView(moment: moment, selectedImageIndex: $selectedImageIndex, onDismiss: { dismiss() })
                .ignoresSafeArea()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: isDragging ? 32 : 0, style: .continuous))
                .scaleEffect(isDragging ? max(0.75, 1.0 - abs(dragOffset.width) / 800 - abs(dragOffset.height) / 800) : 1.0)
                .offset(x: dragOffset.width, y: dragOffset.height)
                .rotation3DEffect(
                    .degrees(Double(dragOffset.width) / 30),
                    axis: (x: 0, y: 1, z: 0),
                    perspective: 0.3
                )
                .shadow(color: .black.opacity(isDragging ? 0.3 : 0), radius: 20, x: 0, y: 10)
                .offset(x: isPresented ? 0 : UIScreen.main.bounds.width)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            if !isDragging {
                                // Start dragging if swiping from the left edge
                                // OR if swiping downwards
                                // OR if swiping right on the first image
                                let isEdgeSwipe = value.startLocation.x < 40 && value.translation.width > 0
                                let isDownwardSwipe = value.translation.height > abs(value.translation.width)
                                let isRightSwipeOnFirstImage = selectedImageIndex == 0 && value.translation.width > 0 && abs(value.translation.width) > abs(value.translation.height)
                                
                                if isEdgeSwipe || isDownwardSwipe || isRightSwipeOnFirstImage {
                                    isDragging = true
                                }
                            }
                            
                            if isDragging {
                                dragOffset = value.translation
                            }
                        }
                        .onEnded { value in
                            guard isDragging else { return }
                            
                            let velocityX = value.velocity.width
                            let velocityY = value.velocity.height
                            let transX = value.translation.width
                            let transY = value.translation.height
                            
                            // Dismiss if dragged far enough or fast enough
                            if abs(transX) > 120 || abs(transY) > 150 || abs(velocityX) > 500 || abs(velocityY) > 500 {
                                dismiss(velocityX: velocityX, velocityY: velocityY)
                            } else {
                                // Snap back
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                    dragOffset = .zero
                                    isDragging = false
                                }
                            }
                        }
                )
        }
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                isPresented = true
            }
        }
    }
    
    private func dismiss(velocityX: CGFloat = 0, velocityY: CGFloat = 0) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            if velocityX > 0 || dragOffset.width > 50 {
                dragOffset.width = UIScreen.main.bounds.width
            } else if velocityX < 0 || dragOffset.width < -50 {
                dragOffset.width = -UIScreen.main.bounds.width
            } else if velocityY > 0 || dragOffset.height > 50 {
                dragOffset.height = UIScreen.main.bounds.height
            } else {
                isPresented = false
            }
            isDragging = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            appState.selectedMoment = nil
        }
    }
}

struct MomentDetailView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(AppState.self) private var appState

    let moment: MockMoment
    @Binding var selectedImageIndex: Int
    var onDismiss: () -> Void

    @State private var isLiked: Bool

    private var theme: AppVisualTheme { appState.currentVisualTheme }

    init(moment: MockMoment, selectedImageIndex: Binding<Int>, onDismiss: @escaping () -> Void) {
        self.moment = moment
        self._selectedImageIndex = selectedImageIndex
        self.onDismiss = onDismiss
        self._isLiked = State(initialValue: moment.isLiked)
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color.black.ignoresSafeArea()

                fullScreenImageCarousel()

                bottomFadeGradient(screenHeight: proxy.size.height)

                VStack(spacing: 0) {
                    topOverlay()
                    Spacer()
                    informationCard
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .ignoresSafeArea()
        }
        .ignoresSafeArea()
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .tabBar)
    }

    // MARK: - Adaptive Colors

    private var cardBgColor: Color {
        colorScheme == .dark ? Color(red: 0.08, green: 0.08, blue: 0.1) : Color(.systemBackground)
    }

    private var primaryTextColor: Color {
        colorScheme == .dark ? .white : .black
    }

    private var secondaryTextColor: Color {
        colorScheme == .dark ? .white.opacity(0.85) : Color(.secondaryLabel)
    }

    private var ctaColor: Color {
        let isDark = colorScheme == .dark
        switch appState.selectedVisualThemeID {
        case .eva00:
            return isDark ? Color(red: 0.3, green: 0.6, blue: 1.0) : Color(red: 0.25, green: 0.52, blue: 0.85)
        case .eva01:
            return isDark ? Color(red: 0.6, green: 0.3, blue: 1.0) : Color(red: 0.45, green: 0.2, blue: 0.75)
        case .eva02:
            return isDark ? Color(red: 1.0, green: 0.35, blue: 0.3) : Color(red: 0.85, green: 0.22, blue: 0.18)
        case .neutral:
            return isDark ? Color.white : Color.black
        }
    }

    // MARK: - Full-Screen Image Carousel

    private func fullScreenImageCarousel() -> some View {
        ZStack {
            Image(moment.images[selectedImageIndex])
                .resizable()
                .scaledToFill()
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                .clipped()
                .ignoresSafeArea()

            TabView(selection: $selectedImageIndex) {
                ForEach(0..<moment.images.count, id: \.self) { index in
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

    // MARK: - Bottom Fade

    private func bottomFadeGradient(screenHeight: CGFloat) -> some View {
        VStack {
            Spacer()
            LinearGradient(
                colors: [.clear, cardBgColor.opacity(0.9)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: min(300, screenHeight * 0.36))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
    }

    // MARK: - Top Overlay (back, pagination, author)

    private func topOverlay() -> some View {
        VStack(spacing: 12) {
            HStack {
                Button { onDismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color.primary)
                        .frame(width: 36, height: 36)
                        .background(.ultraThinMaterial, in: Circle())
                }

                Spacer()

                Button {} label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color.primary)
                        .frame(width: 36, height: 36)
                        .background(.ultraThinMaterial, in: Circle())
                }
            }
            .padding(.horizontal, 16)

            if moment.images.count > 1 {
                HStack(spacing: 6) {
                    ForEach(0..<moment.images.count, id: \.self) { index in
                        Capsule()
                            .fill(index == selectedImageIndex ? Color.white : Color.white.opacity(0.5))
                            .frame(width: index == selectedImageIndex ? 20 : 8, height: 4)
                            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                            .animation(.easeInOut(duration: 0.2), value: selectedImageIndex)
                    }
                }
            }
        }
        .padding(.top, 76)
    }

    // MARK: - Information Card

    private var informationCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 14) {
                authorRow

                HStack(alignment: .top, spacing: 12) {
                    Text(moment.title)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(primaryTextColor)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            isLiked.toggle()
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: isLiked ? "heart.fill" : "heart")
                                .font(.system(size: 22, weight: .medium))
                                .foregroundStyle(isLiked ? ctaColor : primaryTextColor.opacity(0.4))
                            
                            Text("\(moment.likes + (isLiked && !moment.isLiked ? 1 : 0) - (!isLiked && moment.isLiked ? 1 : 0))")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(secondaryTextColor)
                        }
                        .frame(width: 44)
                    }
                    .buttonStyle(.plain)
                }

                Text(moment.content)
                    .font(.system(size: 15))
                    .foregroundStyle(secondaryTextColor)
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 16)

            ctaBar
        }
        .frame(maxWidth: .infinity)
        .background(cardBackground)
        .clipShape(
            UnevenRoundedRectangle(
                cornerRadii: .init(
                    topLeading: 28,
                    bottomLeading: 0,
                    bottomTrailing: 0,
                    topTrailing: 28
                )
            )
        )
        .shadow(color: .black.opacity(colorScheme == .dark ? 0.5 : 0.1), radius: 24, x: 0, y: -10)
    }

    private var cardBackground: some View {
        ZStack {
            cardBgColor
                .opacity(0.95)

            LinearGradient(
                colors: [primaryTextColor.opacity(0.03), .clear],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    // MARK: - Author Row

    private var authorRow: some View {
        HStack(spacing: 10) {
            Image(moment.authorAvatar)
                .resizable()
                .scaledToFill()
                .frame(width: 34, height: 34)
                .clipShape(Circle())
                .overlay(Circle().stroke(primaryTextColor.opacity(0.1), lineWidth: 1))

            VStack(alignment: .leading, spacing: 2) {
                Text(moment.authorName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(primaryTextColor)

                Text("今天 14:30")
                    .font(.system(size: 11))
                    .foregroundStyle(primaryTextColor.opacity(0.45))
            }

            Spacer()

            Button {} label: {
                Text("关注")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(primaryTextColor)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 7)
                    .background(primaryTextColor.opacity(0.06))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().stroke(primaryTextColor.opacity(0.12), lineWidth: 0.5)
                    )
            }
        }
    }

    // MARK: - CTA Bar

    private var ctaBar: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "square.and.arrow.down.fill")
                    .font(.system(size: 13, weight: .semibold))
                Text("获取同款 Agent")
                    .font(.system(size: 15, weight: .bold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(ctaColor)
            .clipShape(Capsule())
            .shadow(color: ctaColor.opacity(0.35), radius: 10, y: 4)
        }
        .buttonStyle(BounceButtonStyle())
        .padding(.horizontal, 24)
        .padding(.bottom, 44)
        .padding(.top, 6)
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
