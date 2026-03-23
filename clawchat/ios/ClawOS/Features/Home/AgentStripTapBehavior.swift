import Foundation

enum AgentStripTapAction: Equatable {
    case ignore
    case selectItem(itemId: String)
    case openGroup(itemId: String)
    case closeGroup
}

enum AgentStripTapBehavior {
    static func action(
        for item: AgentStripItem,
        isEditMode: Bool,
        selectedStripItemId: String,
        folderOverlayActive: Bool
    ) -> AgentStripTapAction {
        switch item {
        case .single:
            return isEditMode ? .ignore : .selectItem(itemId: item.id)

        case .group:
            if selectedStripItemId == item.id && folderOverlayActive {
                return .closeGroup
            }
            return .openGroup(itemId: item.id)
        }
    }
}
