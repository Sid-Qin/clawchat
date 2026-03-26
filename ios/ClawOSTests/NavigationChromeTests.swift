import Testing
import UIKit
@testable import ClawOS

struct NavigationChromeTests {
    @Test("导航栏使用透明背景避免遮住沉浸式页面背景")
    func navigationBarAppearanceUsesTransparentBackground() {
        let theme = AppVisualTheme.theme(for: .eva00)
        let appearance = AppChromeAppearance.navigationBarAppearance(for: theme)

        #expect(appearance.backgroundEffect == nil)
        // configureWithTransparentBackground() may leave backgroundColor nil or .clear
        #expect(appearance.backgroundColor == nil || appearance.backgroundColor == .clear)
        #expect(appearance.shadowColor == nil || appearance.shadowColor == .clear)
    }
}
