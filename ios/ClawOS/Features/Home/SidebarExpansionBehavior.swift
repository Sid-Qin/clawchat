import Foundation

enum SidebarExpansionBehavior {
    static let compactConfirmationRatio: CGFloat = 0.84
    private static let level1EnterRatio: CGFloat = 0.28
    private static let level1ExitRatio: CGFloat = 0.18
    private static let level2EnterProgress: CGFloat = 0.45
    private static let level2ExitProgress: CGFloat = 0.33

    static func compactConfirmationTravel(level1Travel: CGFloat) -> CGFloat {
        level1Travel * compactConfirmationRatio
    }

    static func expansionProgress(
        resolvedOffset: CGFloat,
        level1Travel: CGFloat,
        level2Travel: CGFloat
    ) -> CGFloat {
        let compactTravel = compactConfirmationTravel(level1Travel: level1Travel)
        guard resolvedOffset > compactTravel else { return 0 }
        let available = max(1, level2Travel - compactTravel)
        return min(1, (resolvedOffset - compactTravel) / available)
    }

    static func columnCount(for progress: CGFloat) -> Int {
        progress < 0.3 ? 1 : 4
    }

    static func snapLevel(
        resolvedOffset: CGFloat,
        level1Travel: CGFloat,
        level2Travel: CGFloat,
        previousLevel: Int
    ) -> Int {
        let compactTravel = compactConfirmationTravel(level1Travel: level1Travel)
        let progress = expansionProgress(
            resolvedOffset: resolvedOffset,
            level1Travel: level1Travel,
            level2Travel: level2Travel
        )

        let normalizedPrevious = min(2, max(0, previousLevel))
        let level1Threshold = compactTravel * (normalizedPrevious == 0 ? level1EnterRatio : level1ExitRatio)

        switch normalizedPrevious {
        case 2:
            if progress >= level2ExitProgress { return 2 }
            return resolvedOffset >= level1Threshold ? 1 : 0
        case 1:
            if progress >= level2EnterProgress { return 2 }
            return resolvedOffset >= level1Threshold ? 1 : 0
        default:
            if resolvedOffset < level1Threshold { return 0 }
            if progress >= level2EnterProgress { return 2 }
            return 1
        }
    }

    static func showsFullScreenContent(sidebarLevel: Int, isDragging: Bool) -> Bool {
        sidebarLevel >= 2 && !isDragging
    }

    static func orderedAgents(
        currentGatewayAgents: [Agent],
        allAgents: [Agent]
    ) -> [Agent] {
        let currentIDs = Set(currentGatewayAgents.map(\.id))
        let remaining = allAgents.filter { !currentIDs.contains($0.id) }
        return currentGatewayAgents + remaining
    }
}
