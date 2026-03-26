import SwiftUI

struct AgentDragElevation: Equatable {
    let scale: CGFloat
    let yOffset: CGFloat
    let shadowOpacity: Double
    let shadowRadius: CGFloat
    let shadowY: CGFloat
}

enum AgentDragPresentation {
    static let dropSettleResponse = 0.24
    static let dropSettleDamping: CGFloat = 0.74
    static let dropSettleBlend: CGFloat = 0.08

    static var dropSettleAnimation: Animation {
        .interactiveSpring(
            response: dropSettleResponse,
            dampingFraction: dropSettleDamping,
            blendDuration: dropSettleBlend
        )
    }

    static func stripElevation(
        isSelected: Bool,
        isArmed: Bool,
        isDragged: Bool,
        isMergeCandidate: Bool,
        isMergeReady: Bool
    ) -> AgentDragElevation {
        if isDragged {
            return AgentDragElevation(
                scale: 1.16,
                yOffset: -6,
                shadowOpacity: 0.24,
                shadowRadius: 16,
                shadowY: 12
            )
        }

        if isArmed {
            return AgentDragElevation(
                scale: 1.05,
                yOffset: -2,
                shadowOpacity: 0.14,
                shadowRadius: 7,
                shadowY: 5
            )
        }

        if isMergeReady {
            return AgentDragElevation(
                scale: 1.12,
                yOffset: -1,
                shadowOpacity: 0.14,
                shadowRadius: 8,
                shadowY: 4
            )
        }

        if isMergeCandidate {
            return AgentDragElevation(
                scale: 1.07,
                yOffset: -1,
                shadowOpacity: 0.08,
                shadowRadius: 4,
                shadowY: 2
            )
        }

        if isSelected {
            return AgentDragElevation(
                scale: 1.04,
                yOffset: 0,
                shadowOpacity: 0.12,
                shadowRadius: 6,
                shadowY: 2
            )
        }

        return AgentDragElevation(
            scale: 1,
            yOffset: 0,
            shadowOpacity: 0,
            shadowRadius: 0,
            shadowY: 0
        )
    }

    static func folderElevation(
        isArmed: Bool,
        isDragged: Bool,
        isExtracting: Bool
    ) -> AgentDragElevation {
        if isDragged {
            return AgentDragElevation(
                scale: isExtracting ? 1.20 : 1.16,
                yOffset: -6,
                shadowOpacity: isExtracting ? 0.28 : 0.22,
                shadowRadius: isExtracting ? 18 : 14,
                shadowY: isExtracting ? 13 : 10
            )
        }

        if isArmed {
            return AgentDragElevation(
                scale: 1.04,
                yOffset: -2,
                shadowOpacity: 0.14,
                shadowRadius: 7,
                shadowY: 5
            )
        }

        return AgentDragElevation(
            scale: 1,
            yOffset: 0,
            shadowOpacity: 0,
            shadowRadius: 0,
            shadowY: 0
        )
    }
}
