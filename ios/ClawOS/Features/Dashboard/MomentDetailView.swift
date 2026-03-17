import SwiftUI

// MARK: - Full-Screen Swipe to Go Back

extension UINavigationController: UIGestureRecognizerDelegate {
    private static var fullWidthGestureKey: UInt8 = 0

    override open func viewDidLoad() {
        super.viewDidLoad()

        guard let popGR = interactivePopGestureRecognizer,
              let targets = popGR.value(forKey: "targets") as? [NSObject],
              let targetWrapper = targets.first else { return }

        let internalTarget = targetWrapper.value(forKey: "target")
        let internalAction = Selector(("handleNavigationTransition:"))

        let pan = UIPanGestureRecognizer(target: internalTarget, action: internalAction)
        pan.maximumNumberOfTouches = 1
        pan.delegate = self
        view.addGestureRecognizer(pan)

        popGR.isEnabled = false

        objc_setAssociatedObject(self, &Self.fullWidthGestureKey, pan, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard viewControllers.count > 1 else { return false }

        if let pan = gestureRecognizer as? UIPanGestureRecognizer {
            let v = pan.velocity(in: view)
            let loc = pan.location(in: view)
            let isSwipingRight = v.x > 0 && abs(v.y) / max(v.x, 1) < 1.5
            let isInLeftZone = loc.x < view.bounds.width * 0.45
            return isSwipingRight && isInLeftZone
        }
        return true
    }

    public func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        false
    }

    public func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        guard let storedPan = objc_getAssociatedObject(self, &Self.fullWidthGestureKey) as? UIPanGestureRecognizer,
              gestureRecognizer === storedPan else {
            return false
        }
        let isScrollViewGesture = otherGestureRecognizer.view is UIScrollView
        return isScrollViewGesture
    }
}

struct MomentDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(AppState.self) private var appState

    let moment: MockMoment

    @State private var selectedImageIndex = 0
    @State private var isLiked: Bool
    @State private var isCollected = false

    private var theme: AppVisualTheme { appState.currentVisualTheme }

    init(moment: MockMoment) {
        self.moment = moment
        self._isLiked = State(initialValue: moment.isLiked)
    }

    var body: some View {
        VStack(spacing: 0) {
            navigationBar

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    imageCarousel

                    VStack(alignment: .leading, spacing: 16) {
                        Text(moment.title)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(Color(.label))

                        Text(moment.content)
                            .font(.system(size: 15))
                            .foregroundStyle(Color(.label))
                            .lineSpacing(6)

                        Text("今天 14:30")
                            .font(.system(size: 12))
                            .foregroundStyle(Color(.tertiaryLabel))
                    }
                    .padding(16)

                    Spacer().frame(height: 40)
                }
            }

            bottomBar
        }
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .background(theme.pageGradientTop)
    }

    // MARK: - Navigation Bar

    private var navigationBar: some View {
        HStack(spacing: 12) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(Color(.label))
                    .frame(width: 40, height: 40)
            }

            HStack(spacing: 8) {
                Image(moment.authorAvatar)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())

                Text(moment.authorName)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color(.label))
            }

            Spacer()

            Button {
            } label: {
                Text("关注")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(theme.accent)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .overlay(
                        Capsule().stroke(theme.accent, lineWidth: 1)
                    )
            }

            Button {
            } label: {
                Image(systemName: "arrowshape.turn.up.right")
                    .font(.system(size: 20))
                    .foregroundStyle(Color(.label))
                    .frame(width: 40, height: 40)
            }
        }
        .padding(.horizontal, 8)
        .frame(height: 44)
        .background(theme.tabBarFill)
    }

    // MARK: - Image Carousel

    private var imageCarousel: some View {
        GeometryReader { geo in
            let containerWidth = geo.size.width
            let containerHeight = containerWidth * 4 / 3

            ZStack(alignment: .bottom) {
                Color.black

                TabView(selection: $selectedImageIndex) {
                    ForEach(0..<moment.images.count, id: \.self) { index in
                        Image(moment.images[index])
                            .resizable()
                            .scaledToFit()
                            .frame(width: containerWidth, height: containerHeight)
                            .clipped()
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                if moment.images.count > 1 {
                    HStack(spacing: 6) {
                        ForEach(0..<moment.images.count, id: \.self) { index in
                            Circle()
                                .fill(index == selectedImageIndex ? theme.accent : Color.white.opacity(0.5))
                                .frame(width: 6, height: 6)
                        }
                    }
                    .padding(.bottom, 12)
                }
            }
        }
        .aspectRatio(3/4, contentMode: .fit)
    }

    // MARK: - Bottom Bar

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

    private var bottomBar: some View {
        VStack(spacing: 0) {
            Divider()

            HStack(spacing: 0) {
                HStack(spacing: 20) {
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            isLiked.toggle()
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: isLiked ? "heart.fill" : "heart")
                                .font(.system(size: 18))
                                .foregroundStyle(isLiked ? ctaColor : Color(.secondaryLabel))
                            Text("\(moment.likes + (isLiked && !moment.isLiked ? 1 : 0) - (!isLiked && moment.isLiked ? 1 : 0))")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(Color(.secondaryLabel))
                        }
                    }

                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            isCollected.toggle()
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: isCollected ? "star.fill" : "star")
                                .font(.system(size: 18))
                                .foregroundStyle(isCollected ? ctaColor : Color(.secondaryLabel))
                            Text("收藏")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(Color(.secondaryLabel))
                        }
                    }
                }
                .padding(.leading, 16)

                Spacer()

                Button {
                    let impactMed = UIImpactFeedbackGenerator(style: .medium)
                    impactMed.impactOccurred()
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "square.and.arrow.down.fill")
                            .font(.system(size: 13, weight: .semibold))
                        Text("获取同款 Agent")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(ctaColor)
                    .clipShape(Capsule())
                    .shadow(color: ctaColor.opacity(0.25), radius: 4, y: 2)
                }
                .padding(.trailing, 14)
            }
            .padding(.vertical, 8)
        }
        .background(theme.tabBarFill)
    }
}
