import CoreGraphics

enum AgentFolderPopoverDragBehavior {
    static let longPressDuration = 0.35
    static let dragStartDistance: CGFloat = 0
    private static let verticalEscapeThreshold: CGFloat = 80
    private static let horizontalEscapeThreshold: CGFloat = 100

    static func shouldUngroup(for translation: CGSize) -> Bool {
        abs(translation.height) > verticalEscapeThreshold ||
        abs(translation.width) > horizontalEscapeThreshold
    }
}
