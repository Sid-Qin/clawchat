import Testing
import SwiftUI
@testable import ClawOS

struct SplashThemeTests {
    @Test("开屏旋转件颜色跟随主题 accent")
    func splashSpinColorFollowsThemeAccent() {
        let themes: [(AppVisualThemeID, Color)] = [
            (.neutral, Color(.label)),
            (.eva00, Color(red: 0.63, green: 0.76, blue: 0.88)),
            (.eva01, Color(red: 0.56, green: 0.27, blue: 0.78)),
            (.eva02, Color(red: 0.88, green: 0.28, blue: 0.22)),
        ]
        for (id, expectedAccent) in themes {
            let theme = AppVisualTheme.theme(for: id)
            #expect(theme.accent == expectedAccent, "accent mismatch for \(id)")
        }
    }

    @Test("开屏旋转件沿历史锚点原地旋转")
    func splashSpinUsesHistoricalAnchorLayout() {
        #expect(SplashSpinSpec.logoSize == 180)
        #expect(SplashSpinSpec.iconAnchor == UnitPoint(x: 0.178, y: 0.502))
        #expect(SplashSpinSpec.verticalOffset(for: 1000) == -80)
    }
}
