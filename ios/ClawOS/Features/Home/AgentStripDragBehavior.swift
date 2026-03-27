import CoreGraphics
import Foundation

enum AgentStripDragBehavior {
    static let cellSpacing: CGFloat = 6
    static let mergeActivationDuration: TimeInterval = 0.35
    private static let mergeInsetRatio: CGFloat = 0.22

    static func insertionIndex(
        draggedID: String,
        draggedCenterX: CGFloat,
        orderedIDs: [String],
        frames: [String: CGRect]
    ) -> Int {
        guard orderedIDs.contains(draggedID) else { return 0 }

        let itemsToLeft = orderedIDs
            .filter { $0 != draggedID }
            .compactMap { id -> CGFloat? in
                frames[id]?.midX
            }
            .filter { $0 < draggedCenterX }
            .count

        return min(itemsToLeft, max(orderedIDs.count - 1, 0))
    }

    static func mergeCandidateID(
        draggedID: String,
        draggedCenter: CGPoint,
        orderedIDs: [String],
        frames: [String: CGRect]
    ) -> String? {
        for id in orderedIDs where id != draggedID {
            guard let frame = frames[id] else { continue }

            let insetX = max(10, frame.width * mergeInsetRatio)
            let insetY = max(10, frame.height * mergeInsetRatio)

            if frame.insetBy(dx: insetX, dy: insetY).contains(draggedCenter) {
                return id
            }
        }

        return nil
    }

    static func shiftDistance(
        draggedID: String,
        frames: [String: CGRect]
    ) -> CGFloat {
        (frames[draggedID]?.width ?? 64) + cellSpacing
    }

    static func collisionOffset(
        for itemID: String,
        draggedID: String,
        insertionIndex: Int,
        orderedIDs: [String],
        shiftDistance: CGFloat
    ) -> CGFloat {
        guard itemID != draggedID,
              let fromIndex = orderedIDs.firstIndex(of: draggedID),
              let itemIndex = orderedIDs.firstIndex(of: itemID) else {
            return 0
        }

        if insertionIndex > fromIndex,
           itemIndex > fromIndex,
           itemIndex <= insertionIndex {
            return -shiftDistance
        }

        if insertionIndex < fromIndex,
           itemIndex >= insertionIndex,
           itemIndex < fromIndex {
            return shiftDistance
        }

        return 0
    }
}
