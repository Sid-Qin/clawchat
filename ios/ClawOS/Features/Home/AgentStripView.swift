import SwiftUI

// MARK: - Frame Preference Key

private struct StripItemFrameKey: PreferenceKey {
    static var defaultValue: [String: CGRect] = [:]
    static func reduce(value: inout [String: CGRect], nextValue: () -> [String: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

// MARK: - Jiggle Modifier

private struct JiggleEffect: ViewModifier {
    let active: Bool
    @State private var angle: Double = 0

    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(active ? angle : 0))
            .onChange(of: active, initial: true) { _, isActive in
                if isActive { startJiggle() } else { angle = 0 }
            }
    }

    private func startJiggle() {
        let base = Double.random(in: 1.5...2.5)
        withAnimation(.easeInOut(duration: 0.1)) { angle = base }

        withAnimation(
            .easeInOut(duration: Double.random(in: 0.10...0.14))
            .repeatForever(autoreverses: true)
        ) {
            angle = -base
        }
    }
}

private extension View {
    func jiggle(_ active: Bool) -> some View {
        modifier(JiggleEffect(active: active))
    }
}

// MARK: - Agent Strip View

struct AgentStripView: View {
    @Environment(AppState.self) private var appState
    @Environment(AgentDragCoordinator.self) private var coordinator
    @Binding var folderOverlayActive: Bool
    @Binding var folderPopoverGroupId: String?

    @State private var itemFrames: [String: CGRect] = [:]
    @State private var armedItemId: String?
    @State private var suppressNextBackgroundTap = false
    @State private var showAddAgent = false

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AgentDragCoordinator.cellSpacing) {
                ForEach(appState.agentStripItems) { item in
                    stripCell(for: item)
                }

                addButton
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .scrollClipDisabled()
        .coordinateSpace(name: "strip")
        .onPreferenceChange(StripItemFrameKey.self) { frames in
            itemFrames = frames
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if suppressNextBackgroundTap {
                suppressNextBackgroundTap = false
                return
            }
            if coordinator.isEditMode {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    coordinator.isEditMode = false
                }
            }
        }
        .sheet(isPresented: $showAddAgent) {
            AgentEditorView()
                .environment(appState)
        }
    }

    // MARK: - Strip Cell

    private func stripCell(for item: AgentStripItem) -> some View {
        let isArmed = armedItemId == item.id && coordinator.draggedItemId == nil
        let isDragged = coordinator.draggedItemId == item.id
        let isMergeCandidate: Bool
        let isMergeReady: Bool

        switch coordinator.phase {
        case .mergeReady(let tid):
            isMergeReady = tid == item.id
            isMergeCandidate = isMergeReady
        case .mergeHover(let tid):
            isMergeReady = false
            isMergeCandidate = tid == item.id
        default:
            isMergeReady = false
            isMergeCandidate = false
        }

        let isSelected = appState.selectedStripItemId == item.id
        let shift = collisionOffset(for: item.id)

        return StripAvatarView(
            item: item,
            isSelected: isSelected,
            isEditMode: coordinator.isEditMode,
            isArmed: isArmed,
            isDragged: isDragged,
            isMergeCandidate: isMergeCandidate,
            isMergeReady: isMergeReady,
            onRemoveFromGroup: nil
        )
        .jiggle(coordinator.isEditMode && !isDragged)
        .offset(
            x: isDragged ? coordinator.dragOffset.width : shift,
            y: isDragged ? coordinator.dragOffset.height : 0
        )
        .zIndex(isDragged ? 100 : 0)
        .background(
            GeometryReader { geo in
                Color.clear.preference(
                    key: StripItemFrameKey.self,
                    value: [item.id: geo.frame(in: .named("strip"))]
                )
            }
        )
        .highPriorityGesture(
            TapGesture().onEnded {
                suppressNextBackgroundTap = true
                handleTap(item)
                DispatchQueue.main.async {
                    suppressNextBackgroundTap = false
                }
            }
        )
        .gesture(folderOverlayActive ? nil : dragGesture(for: item))
        .simultaneousGesture(longPressGesture(for: item))
        .animation(.interactiveSpring(response: 0.28, dampingFraction: 0.82), value: coordinator.placeholderIndex)
        .animation(.spring(response: 0.22, dampingFraction: 0.78), value: coordinator.phase)
    }

    // MARK: - Tap Handler

    private func handleTap(_ item: AgentStripItem) {
        switch AgentStripTapBehavior.action(
            for: item,
            isEditMode: coordinator.isEditMode,
            selectedStripItemId: appState.selectedStripItemId,
            folderOverlayActive: folderOverlayActive
        ) {
        case .ignore:
            break
        case .selectItem(let itemId):
            appState.selectStripItem(itemId)
        case .closeGroup:
            withAnimation(.easeOut(duration: 0.2)) {
                folderOverlayActive = false
                folderPopoverGroupId = nil
            }
        case .openGroup(let itemId):
            appState.selectStripItem(itemId)
            if case .group = item,
               appState.selectedStripItemId == item.id && folderOverlayActive {
                withAnimation(.easeOut(duration: 0.2)) { folderOverlayActive = false }
            }
            folderPopoverGroupId = itemId
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                folderOverlayActive = true
            }
        }
    }

    // MARK: - Long Press → Edit Mode

    private func longPressGesture(for item: AgentStripItem) -> some Gesture {
        LongPressGesture(minimumDuration: 0.5)
            .onEnded { _ in
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    armedItemId = item.id
                    coordinator.enterEditMode()
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                    guard armedItemId == item.id, coordinator.draggedItemId == nil else { return }
                    withAnimation(.spring(response: 0.22, dampingFraction: 0.86)) {
                        armedItemId = nil
                    }
                }
            }
    }

    // MARK: - Drag Gesture

    private func dragGesture(for item: AgentStripItem) -> some Gesture {
        DragGesture(minimumDistance: coordinator.isEditMode ? 5 : 500)
            .onChanged { value in
                if coordinator.draggedItemId == nil {
                    withAnimation(.spring(response: 0.18, dampingFraction: 0.82)) {
                        armedItemId = nil
                        coordinator.beginLift(itemId: item.id, surface: .strip)
                    }
                }

                coordinator.updateDrag(translation: value.translation)

                let orderedIDs = appState.agentStripItems.map(\.id)
                let dragCenter = CGPoint(
                    x: (itemFrames[item.id]?.midX ?? 0) + value.translation.width,
                    y: (itemFrames[item.id]?.midY ?? 0) + value.translation.height
                )

                coordinator.updateStripReorder(
                    draggedCenterX: dragCenter.x,
                    draggedCenter: dragCenter,
                    orderedIDs: orderedIDs,
                    frames: itemFrames
                )
            }
            .onEnded { _ in
                var result: DragResult = .cancelled
                withAnimation(AgentDragPresentation.dropSettleAnimation) {
                    armedItemId = nil
                    result = coordinator.endDrag()
                }
                withAnimation(AgentDragPresentation.dropSettleAnimation) {
                    applyDragResult(result)
                }
            }
    }

    func applyDragResult(_ result: DragResult) {
        switch result {
        case .merge(let sourceId, let targetId):
            appState.mergeStripItems(sourceId: sourceId, targetId: targetId)
        case .reorder(let itemId, let toIndex):
            guard let fromIdx = appState.agentStripItems.firstIndex(where: { $0.id == itemId }) else { return }
            appState.moveStripItem(fromIndex: fromIdx, toFinalIndex: toIndex)
        case .extractFromFolder(let agentId, let groupId, _):
            appState.ungroupAgent(agentId, from: groupId)
        case .cancelled:
            break
        }
    }

    private func collisionOffset(for itemId: String) -> CGFloat {
        guard let dragId = coordinator.draggedItemId,
              itemId != dragId,
              coordinator.sourceSurface == .strip else { return 0 }

        if case .mergeReady = coordinator.phase { return 0 }

        guard let slot = coordinator.placeholderIndex else { return 0 }
        let orderedIDs = appState.agentStripItems.map(\.id)
        let shift = AgentDragCoordinator.shiftDistance(draggedID: dragId, frames: itemFrames)
        return AgentDragCoordinator.collisionOffset(
            for: itemId,
            draggedID: dragId,
            insertionIndex: slot,
            orderedIDs: orderedIDs,
            shiftDistance: shift
        )
    }

    // MARK: - Add Button

    private var addButton: some View {
        VStack(spacing: 4) {
            Image(systemName: "plus")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(.quaternary)
                .frame(width: 52, height: 52)
                .background(.ultraThinMaterial, in: Circle())

            Text("Add")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.quaternary)
        }
        .frame(width: 64)
        .allowsHitTesting(false)
    }

}
