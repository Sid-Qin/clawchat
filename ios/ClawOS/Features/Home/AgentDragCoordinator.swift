import SwiftUI
import Observation

enum DragSurface: Equatable {
    case strip
    case folder(groupId: String)
}

enum DragPhase: Equatable {
    case idle
    case armed(itemId: String)
    case lifted(itemId: String)
    case reordering
    case mergeHover(targetId: String)
    case mergeReady(targetId: String)
    case extractingFromFolder
}

@Observable
final class AgentDragCoordinator {

    // MARK: - Configuration

    static let longPressDuration: TimeInterval = 0.35
    static let mergeActivationDuration: TimeInterval = 0.35
    static let mergeInsetRatio: CGFloat = 0.22
    static let cellSpacing: CGFloat = 6
    static let folderExitThresholdVertical: CGFloat = 60
    static let folderExitThresholdHorizontal: CGFloat = 80

    // MARK: - Drag State

    private(set) var phase: DragPhase = .idle
    private(set) var sourceSurface: DragSurface = .strip
    private(set) var draggedItemId: String?
    private(set) var draggedAgentId: String?
    private(set) var dragOffset: CGSize = .zero
    private(set) var placeholderIndex: Int?

    var isEditMode = false

    private var mergeWorkItem: DispatchWorkItem?
    private var lastHapticSlot: Int?
    private var lastHapticMerge: String?

    // MARK: - Haptics

    private let lightGen = UIImpactFeedbackGenerator(style: .light)
    private let mediumGen = UIImpactFeedbackGenerator(style: .medium)
    private let selectionGen = UISelectionFeedbackGenerator()

    // MARK: - Computed

    var isDragging: Bool { draggedItemId != nil || draggedAgentId != nil }
    var isLifted: Bool {
        switch phase {
        case .lifted, .reordering, .mergeHover, .mergeReady, .extractingFromFolder: true
        default: false
        }
    }

    var mergeTargetId: String? {
        switch phase {
        case .mergeHover(let id), .mergeReady(let id): id
        default: nil
        }
    }

    var isMergeReady: Bool {
        if case .mergeReady = phase { return true }
        return false
    }

    var isExtracting: Bool { phase == .extractingFromFolder }

    // MARK: - Lifecycle

    func enterEditMode() {
        guard !isEditMode else { return }
        isEditMode = true
        mediumGen.impactOccurred(intensity: 0.82)
    }

    func beginArm(itemId: String, surface: DragSurface) {
        phase = .armed(itemId: itemId)
        sourceSurface = surface
        lightGen.impactOccurred()
    }

    func beginLift(itemId: String, surface: DragSurface) {
        sourceSurface = surface
        switch surface {
        case .strip:
            draggedItemId = itemId
        case .folder:
            draggedAgentId = itemId
        }
        phase = .lifted(itemId: itemId)
        mediumGen.impactOccurred()
    }

    func updateDrag(translation: CGSize) {
        dragOffset = translation
    }

    // MARK: - Strip Reorder

    func updateStripReorder(
        draggedCenterX: CGFloat,
        draggedCenter: CGPoint,
        orderedIDs: [String],
        frames: [String: CGRect]
    ) {
        guard let dragId = draggedItemId else { return }

        let newSlot = Self.insertionIndex(
            draggedID: dragId,
            draggedCenterX: draggedCenterX,
            orderedIDs: orderedIDs,
            frames: frames
        )

        if placeholderIndex != newSlot {
            placeholderIndex = newSlot
            if lastHapticSlot != newSlot {
                lastHapticSlot = newSlot
                selectionGen.selectionChanged()
            }
            phase = .reordering
        }

        let mergeCandidate = Self.mergeCandidateID(
            draggedID: dragId,
            draggedCenter: draggedCenter,
            orderedIDs: orderedIDs,
            frames: frames
        )

        if let cid = mergeCandidate {
            if case .mergeHover(let existing) = phase, existing == cid { return }
            if case .mergeReady(let existing) = phase, existing == cid { return }
            startMergeDwell(targetId: cid)
        } else {
            cancelMergeDwell()
            if case .mergeHover = phase { phase = .reordering }
            if case .mergeReady = phase { phase = .reordering }
        }
    }

    // MARK: - Folder Drag

    func updateFolderDrag(translation: CGSize) {
        dragOffset = translation

        let outside = Self.isOutsideFolder(translation: translation)

        if outside && phase != .extractingFromFolder {
            phase = .extractingFromFolder
            mediumGen.impactOccurred()
        } else if !outside && phase == .extractingFromFolder {
            phase = .lifted(itemId: draggedAgentId ?? "")
            lightGen.impactOccurred()
        }
    }

    // MARK: - End

    func endDrag() -> DragResult {
        mergeWorkItem?.cancel()
        mergeWorkItem = nil

        let result: DragResult

        switch phase {
        case .mergeReady(let targetId):
            if let dragId = draggedItemId {
                result = .merge(sourceId: dragId, targetId: targetId)
                mediumGen.impactOccurred()
            } else {
                result = .cancelled
            }

        case .extractingFromFolder:
            if let agentId = draggedAgentId, case .folder(let groupId) = sourceSurface {
                result = .extractFromFolder(agentId: agentId, groupId: groupId, insertionIndex: placeholderIndex)
                mediumGen.impactOccurred()
            } else {
                result = .cancelled
            }

        case .reordering, .mergeHover, .lifted:
            if let dragId = draggedItemId, let target = placeholderIndex {
                result = .reorder(itemId: dragId, toIndex: target)
            } else {
                result = .cancelled
            }

        default:
            result = .cancelled
        }

        reset()
        return result
    }

    func cancel() {
        mergeWorkItem?.cancel()
        mergeWorkItem = nil
        reset()
    }

    private func reset() {
        phase = .idle
        draggedItemId = nil
        draggedAgentId = nil
        dragOffset = .zero
        placeholderIndex = nil
        lastHapticSlot = nil
        lastHapticMerge = nil
    }

    // MARK: - Merge Dwell

    private func startMergeDwell(targetId: String) {
        mergeWorkItem?.cancel()

        phase = .mergeHover(targetId: targetId)
        if lastHapticMerge != targetId {
            lastHapticMerge = targetId
            lightGen.impactOccurred(intensity: 0.6)
        }

        let work = DispatchWorkItem { [weak self] in
            guard let self,
                  case .mergeHover(let current) = self.phase,
                  current == targetId else { return }
            self.phase = .mergeReady(targetId: targetId)
            self.mediumGen.impactOccurred()
        }
        mergeWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.mergeActivationDuration, execute: work)
    }

    private func cancelMergeDwell() {
        mergeWorkItem?.cancel()
        mergeWorkItem = nil
    }

    // MARK: - Pure Geometry

    static func insertionIndex(
        draggedID: String,
        draggedCenterX: CGFloat,
        orderedIDs: [String],
        frames: [String: CGRect]
    ) -> Int {
        guard orderedIDs.contains(draggedID) else { return 0 }
        let count = orderedIDs
            .filter { $0 != draggedID }
            .compactMap { frames[$0]?.midX }
            .filter { $0 < draggedCenterX }
            .count
        return min(count, max(orderedIDs.count - 1, 0))
    }

    static func mergeCandidateID(
        draggedID: String,
        draggedCenter: CGPoint,
        orderedIDs: [String],
        frames: [String: CGRect]
    ) -> String? {
        for id in orderedIDs where id != draggedID {
            guard let frame = frames[id] else { continue }
            let inX = max(10, frame.width * mergeInsetRatio)
            let inY = max(10, frame.height * mergeInsetRatio)
            if frame.insetBy(dx: inX, dy: inY).contains(draggedCenter) {
                return id
            }
        }
        return nil
    }

    static func shiftDistance(draggedID: String, frames: [String: CGRect]) -> CGFloat {
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

    static func isOutsideFolder(translation: CGSize) -> Bool {
        abs(translation.height) > folderExitThresholdVertical ||
        abs(translation.width) > folderExitThresholdHorizontal
    }
}

// MARK: - Drag Result

enum DragResult {
    case reorder(itemId: String, toIndex: Int)
    case merge(sourceId: String, targetId: String)
    case extractFromFolder(agentId: String, groupId: String, insertionIndex: Int?)
    case cancelled
}
