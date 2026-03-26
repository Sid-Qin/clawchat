import SwiftUI
import UIKit

enum AppChromeAppearance {
    static func tabBarAppearance(for theme: AppVisualTheme) -> UITabBarAppearance {
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.backgroundEffect = UIBlurEffect(style: .systemChromeMaterial)
        appearance.backgroundColor = UIColor(theme.tabBarFill)
        appearance.shadowColor = UIColor.separator.withAlphaComponent(0.15)
        return appearance
    }

    static func navigationBarAppearance(for theme: AppVisualTheme) -> UINavigationBarAppearance {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundEffect = nil
        appearance.backgroundColor = .clear
        appearance.shadowColor = .clear

        let accent = UIColor(theme.accent)
        let titleColor = UIColor.label
        appearance.titleTextAttributes = [.foregroundColor: titleColor]
        appearance.largeTitleTextAttributes = [.foregroundColor: titleColor]
        appearance.buttonAppearance.normal.titleTextAttributes = [.foregroundColor: accent]
        appearance.doneButtonAppearance.normal.titleTextAttributes = [.foregroundColor: accent]
        appearance.backButtonAppearance.normal.titleTextAttributes = [.foregroundColor: accent]

        return appearance
    }
}
