import SwiftUI

enum SplashSpinSpec {
    static let logoSize: CGFloat = 180
    static let iconAnchor = UnitPoint(x: 0.178, y: 0.502)
    static let rotationDuration: Double = 2.0

    static func verticalOffset(for containerHeight: CGFloat) -> CGFloat {
        -containerHeight * 0.08
    }
}
