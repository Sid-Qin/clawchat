import SwiftUI

struct GlassCard<Content: View>: View {
    var cornerRadius: CGFloat = AppTheme.Radius.lg
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(AppTheme.Spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .adaptiveGlass(in: .rect(cornerRadius: cornerRadius))
    }
}

// MARK: - Adaptive glass effect (iOS 26+ with fallback)

extension View {
    /// Standard glass effect with InsettableShape (circle, capsule, rect, etc.)
    func adaptiveGlass(in shape: some InsettableShape, interactive: Bool = false) -> some View {
        modifier(AdaptiveGlassModifier(shape: shape, interactive: interactive))
    }

    /// Glass effect with AnyShape (for dynamic shape switching)
    func adaptiveGlassAnyShape(_ shape: AnyShape) -> some View {
        modifier(AdaptiveGlassAnyShapeModifier(shape: shape))
    }

    /// Glass button style with fallback to .bordered on < iOS 26
    func adaptiveGlassButtonStyle() -> some View {
        modifier(AdaptiveGlassButtonStyleModifier())
    }
}

private struct AdaptiveGlassModifier<S: InsettableShape>: ViewModifier {
    let shape: S
    let interactive: Bool

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .glassEffect(interactive ? .regular.interactive() : .regular, in: shape)
        } else {
            content
                .background(.ultraThinMaterial, in: shape)
        }
    }
}

private struct AdaptiveGlassButtonStyleModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .buttonStyle(.glass)
        } else {
            content
                .buttonStyle(.bordered)
        }
    }
}

private struct AdaptiveGlassAnyShapeModifier: ViewModifier {
    let shape: AnyShape

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .glassEffect(.regular, in: shape)
        } else {
            content
                .background(.ultraThinMaterial)
                .clipShape(shape)
        }
    }
}
