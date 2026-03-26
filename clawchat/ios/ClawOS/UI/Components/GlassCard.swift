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

    /// Tinted glass effect for prominent CTAs and highlighted controls.
    func adaptiveTintedGlass(
        in shape: some InsettableShape,
        tint: Color,
        interactive: Bool = false
    ) -> some View {
        modifier(AdaptiveTintedGlassModifier(shape: shape, tint: tint, interactive: interactive))
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
        #if compiler(>=6.2)
        if #available(iOS 26.0, *) {
            content
                .glassEffect(interactive ? .regular.interactive() : .regular, in: shape)
        } else {
            content
                .background(.ultraThinMaterial, in: shape)
        }
        #else
        content
            .background(.ultraThinMaterial, in: shape)
        #endif
    }
}

private struct AdaptiveTintedGlassModifier<S: InsettableShape>: ViewModifier {
    let shape: S
    let tint: Color
    let interactive: Bool

    func body(content: Content) -> some View {
        #if compiler(>=6.2)
        if #available(iOS 26.0, *) {
            content
                .glassEffect(
                    interactive
                        ? .regular.tint(tint).interactive()
                        : .regular.tint(tint),
                    in: shape
                )
        } else {
            content
                .background(.ultraThinMaterial, in: shape)
                .overlay {
                    shape
                        .fill(tint.opacity(0.22))
                }
                .overlay {
                    shape
                        .strokeBorder(.white.opacity(0.18), lineWidth: 0.8)
                }
        }
        #else
        content
            .background(.ultraThinMaterial, in: shape)
            .overlay {
                shape
                    .fill(tint.opacity(0.22))
            }
            .overlay {
                shape
                    .strokeBorder(.white.opacity(0.18), lineWidth: 0.8)
            }
        #endif
    }
}

private struct AdaptiveGlassButtonStyleModifier: ViewModifier {
    func body(content: Content) -> some View {
        #if compiler(>=6.2)
        if #available(iOS 26.0, *) {
            content
                .buttonStyle(.glass)
        } else {
            content
                .buttonStyle(.bordered)
        }
        #else
        content
            .buttonStyle(.bordered)
        #endif
    }
}

private struct AdaptiveGlassAnyShapeModifier: ViewModifier {
    let shape: AnyShape

    func body(content: Content) -> some View {
        #if compiler(>=6.2)
        if #available(iOS 26.0, *) {
            content
                .glassEffect(.regular, in: shape)
        } else {
            content
                .background(.ultraThinMaterial)
                .clipShape(shape)
        }
        #else
        content
            .background(.ultraThinMaterial)
            .clipShape(shape)
        #endif
    }
}
