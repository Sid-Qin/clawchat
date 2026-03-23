//
//  ClawOSTests.swift
//  ClawOSTests
//
//  Created by Sid Qin on 2026/3/15.
//

import Testing
import Foundation
import CoreGraphics
@testable import ClawOS

struct ClawOSTests {

    @Test("folder popover 拖拽使用长按激活")
    func folderPopoverDragUsesLongPressActivation() {
        #expect(AgentFolderPopoverDragBehavior.longPressDuration > 0)
        #expect(AgentFolderPopoverDragBehavior.longPressDuration <= 0.4)
        #expect(AgentFolderPopoverDragBehavior.dragStartDistance == 0)
    }

    @Test("folder popover 只有拖出阈值后才拆分 agent")
    func folderPopoverDragRequiresEscapeThreshold() {
        #expect(AgentFolderPopoverDragBehavior.shouldUngroup(for: CGSize(width: 0, height: 81)))
        #expect(AgentFolderPopoverDragBehavior.shouldUngroup(for: CGSize(width: 101, height: 0)))
        #expect(AgentFolderPopoverDragBehavior.shouldUngroup(for: CGSize(width: 60, height: 40)) == false)
    }

    @Test("startNewSession 为当前选中 agent 创建会话")
    func startNewSessionCreatesSessionForSelectedAgent() {
        let appState = AppState()
        appState.agents = [
            Agent(
                id: "hulu",
                name: "呼噜",
                avatar: "",
                status: .online,
                unreadCount: 0,
                gatewayId: "gw-1",
                model: "claude-opus-4-6",
                availableModels: ["claude-opus-4-6"]
            )
        ]
        appState.selectedAgentId = "hulu"

        let session = appState.startNewSession()

        #expect(session != nil)
        #expect(session?.agentId == "hulu")
        #expect(session?.title == "新对话")
        #expect(appState.sessions.count == 1)
        #expect(appState.sessions.first?.id == session?.id)
    }

    @Test("group 内切换过 agent 后重新聚焦 group 不应把新建目标重置为第一个 agent")
    func groupSelectionKeepsChosenAgentForNewSession() {
        let appState = AppState()
        appState.selectedGatewayId = "gw-1"
        appState.agents = [
            Agent(id: "a1", name: "Ayanami", avatar: "", status: .online, unreadCount: 0, gatewayId: "gw-1"),
            Agent(id: "a2", name: "Asuka", avatar: "", status: .online, unreadCount: 0, gatewayId: "gw-1")
        ]
        let group = AgentGroup(id: "g1", name: "Group", agentIds: ["a1", "a2"])
        let groupItemId = "group_\(group.id)"
        appState.agentStripItems = [.group(group)]

        appState.selectStripItem(groupItemId)
        appState.selectAgentInGroup("a2", groupItemId: groupItemId)
        appState.selectStripItem(groupItemId)

        let session = appState.startNewSession()

        #expect(appState.selectedStripItemId == groupItemId)
        #expect(appState.selectedAgentId == "a2")
        #expect(session?.agentId == "a2")
    }

    @Test("deleteSession 删除指定会话")
    func deleteSessionRemovesMatchingSession() {
        let appState = AppState()
        appState.sessions = [
            Session(id: "s1", agentId: "hulu", title: "会话1", category: "对话", lastMessage: nil, lastMessageTime: nil, unreadCount: 0),
            Session(id: "s2", agentId: "hulu", title: "会话2", category: "对话", lastMessage: nil, lastMessageTime: nil, unreadCount: 0),
        ]

        appState.deleteSession(id: "s1")

        #expect(appState.sessions.count == 1)
        #expect(appState.sessions.first?.id == "s2")
    }

    @Test("applyConnectionInfo 解析 agent 描述中的名字模型与可用模型")
    func applyConnectionInfoParsesAgentDescriptor() {
        let appState = AppState()

        appState.applyConnectionInfo(
            gatewayId: "gw-1",
            relayUrl: "wss://relay.example.com",
            agentIds: ["hulu::呼噜::claude-opus-4-6::claude-opus-4-6||gpt-5.3-codex"]
        )

        #expect(appState.agents.count == 1)
        #expect(appState.agents.first?.id == "hulu")
        #expect(appState.agents.first?.name == "呼噜")
        #expect(appState.agents.first?.model == "claude-opus-4-6")
        #expect(appState.agents.first?.availableModels == ["claude-opus-4-6", "gpt-5.3-codex"])
    }

    @Test("appendMessage 在仅有附件时仍会更新会话预览")
    func appendMessageUsesAttachmentSummaryWhenTextEmpty() {
        let appState = AppState()
        appState.sessions = [
            Session(id: "s1", agentId: "hulu", title: "会话1", category: "对话", lastMessage: nil, lastMessageTime: nil, unreadCount: 0)
        ]

        let attachment = StoredMessageAttachment(
            id: "a1",
            type: .image,
            filename: "eva.png",
            mimeType: "image/png",
            size: 128
        )
        let message = StoredMessage(
            id: "m1",
            role: .user,
            text: "",
            attachments: [attachment],
            timestamp: Date()
        )

        appState.appendMessage(to: "s1", message: message)

        #expect(appState.sessions.first?.lastMessage == "附件：eva.png")
    }

    @Test("startNewSession 为同一 agent 生成独立 sessionKey")
    func startNewSessionGeneratesDistinctSessionKeys() {
        let appState = AppState()
        appState.agents = [
            Agent(
                id: "hulu",
                name: "呼噜",
                avatar: "",
                status: .online,
                unreadCount: 0,
                gatewayId: "gw-1",
                model: "claude-opus-4-6",
                availableModels: ["claude-opus-4-6"]
            )
        ]
        appState.selectedAgentId = "hulu"

        let first = appState.startNewSession()
        let second = appState.startNewSession()
        let firstKey = reflectedOptionalString(named: "sessionKey", from: first as Any)
        let secondKey = reflectedOptionalString(named: "sessionKey", from: second as Any)

        #expect(first != nil)
        #expect(second != nil)
        #expect(firstKey != nil)
        #expect(secondKey != nil)
        #expect(firstKey?.isEmpty == false)
        #expect(secondKey?.isEmpty == false)
        #expect(firstKey != secondKey)
    }

    @Test("session 左滑超过确认阈值后会进入阻尼区")
    func sessionSwipeDampensBeyondConfirmThreshold() {
        let offset = SessionSwipeBehavior.interactiveOffset(
            initialOffset: 0,
            translation: -320
        )

        #expect(offset < -SessionSwipeBehavior.confirmThreshold)
        #expect(offset > -320)
    }

    @Test("session 中段左滑松手会吸附到动作展开态")
    func sessionSwipeSettlesToRevealForModerateDrag() {
        let target = SessionSwipeBehavior.settleTarget(
            currentOffset: -108,
            predictedEndOffset: -148,
            velocity: -180
        )

        #expect(target == .revealed)
        #expect(SessionSwipeBehavior.targetOffset(for: target) == -SessionSwipeBehavior.revealWidth)
    }

    @Test("session 深拉松手会进入删除确认就绪态")
    func sessionSwipeSettlesToArmedForDelete() {
        let target = SessionSwipeBehavior.settleTarget(
            currentOffset: -198,
            predictedEndOffset: -236,
            velocity: -210
        )

        #expect(target == .armedForDelete)
        #expect(SessionSwipeBehavior.targetOffset(for: target) == -SessionSwipeBehavior.armedLockWidth)
    }

    @Test("session 删除接管阶段会压缩 pin 并扩展删除按钮")
    func sessionSwipeMetricsShiftFromPinToDelete() {
        let revealed = SessionSwipeBehavior.metrics(for: -130)
        let dominant = SessionSwipeBehavior.metrics(for: -190)

        #expect(revealed.stage == .actionsRevealed)
        #expect(dominant.stage == .deleteDominant)
        #expect(dominant.pinWidth < revealed.pinWidth)
        #expect(dominant.deleteWidth > revealed.deleteWidth)
    }

    @Test("session 左滑进入删除确认区时 pin 会被完全挤压消失")
    func sessionSwipeConfirmZoneFullyHidesPin() {
        let armedMetrics = SessionSwipeBehavior.metrics(for: -SessionSwipeBehavior.confirmThreshold)

        #expect(armedMetrics.stage == .armedForDelete)
        #expect(armedMetrics.pinWidth == 0)
        #expect(armedMetrics.deleteWidth == SessionSwipeBehavior.armedLockWidth)
    }

    @Test("Siri glow 在没有键盘时保持整屏边缘模式")
    func siriGlowUsesFullscreenModeWithoutKeyboard() {
        let screen = CGRect(x: 0, y: 0, width: 393, height: 852)

        let mode = SiriGlowLayout.mode(for: screen, keyboardFrame: nil)

        #expect(mode == .fullScreen)
    }

    @Test("Siri glow 在底部键盘出现时切换为键盘顶部光带")
    func siriGlowUsesKeyboardTopModeWhenKeyboardVisible() {
        let screen = CGRect(x: 0, y: 0, width: 393, height: 852)
        let keyboard = CGRect(x: 0, y: 548, width: 393, height: 304)

        let mode = SiriGlowLayout.mode(for: screen, keyboardFrame: keyboard)

        guard case .keyboardTop(let glowFrame) = mode else {
            Issue.record("Expected keyboardTop glow mode")
            return
        }

        #expect(glowFrame.minY < keyboard.minY)
        #expect(glowFrame.maxY > keyboard.minY)
        #expect(glowFrame.minX > screen.minX)
        #expect(glowFrame.maxX < screen.maxX)
    }

    @Test("打字机效果每个节拍只前进固定字符数")
    func typewriterAdvanceUsesFixedStep() {
        let next = StreamingTypewriter.nextDisplayText(
            current: "",
            target: "你好世界",
            charactersPerTick: 2
        )

        #expect(next == "你好")
    }

    @Test("打字机效果不会超过真实已返回内容")
    func typewriterAdvanceNeverExceedsTarget() {
        let next = StreamingTypewriter.nextDisplayText(
            current: "你好世",
            target: "你好世界",
            charactersPerTick: 8
        )

        #expect(next == "你好世界")
    }

    @Test("打字机效果遇到最终文本回退时会以真实文本为准")
    func typewriterAdvanceSnapsToAuthoritativeTargetWhenCurrentIsNotPrefix() {
        let next = StreamingTypewriter.nextDisplayText(
            current: "hello world world",
            target: "hello world",
            charactersPerTick: 2
        )

        #expect(next == "hello world")
    }

    @Test("流式滚动跟随会节流避免每个字都触发滚动")
    func typewriterScrollFollowCadenceIsThrottledForStreaming() {
        #expect(StreamingTypewriter.followScrollDelayMilliseconds >= StreamingTypewriter.tickIntervalMilliseconds)
    }

    @Test("流式或 typing 期间暂停消息可见性测量")
    func chatViewportTrackingSuspendsDuringLiveUpdates() {
        #expect(ChatViewportPerformancePolicy.shouldMeasureVisibleFrames(
            hasStreamingPreview: true,
            isTyping: false
        ) == false)
        #expect(ChatViewportPerformancePolicy.shouldMeasureVisibleFrames(
            hasStreamingPreview: false,
            isTyping: true
        ) == false)
        #expect(ChatViewportPerformancePolicy.shouldMeasureVisibleFrames(
            hasStreamingPreview: false,
            isTyping: false
        ))
    }

    @Test("聊天滚动恢复会选择最接近顶部的可见消息")
    func chatScrollAnchorChoosesTopVisibleMessage() {
        let frames: [String: CGRect] = [
            "m1": CGRect(x: 0, y: -88, width: 200, height: 60),
            "m2": CGRect(x: 0, y: -12, width: 200, height: 60),
            "m3": CGRect(x: 0, y: 44, width: 200, height: 60),
            "m4": CGRect(x: 0, y: 520, width: 200, height: 60)
        ]

        let anchorId = ChatScrollAnchorResolver.anchorMessageID(
            from: frames,
            viewportHeight: 480
        )

        #expect(anchorId == "m2")
    }

    @Test("聊天滚动恢复会忽略完全不可见的消息")
    func chatScrollAnchorIgnoresOffscreenMessages() {
        let frames: [String: CGRect] = [
            "m1": CGRect(x: 0, y: -200, width: 200, height: 60),
            "m2": CGRect(x: 0, y: 520, width: 200, height: 60)
        ]

        let anchorId = ChatScrollAnchorResolver.anchorMessageID(
            from: frames,
            viewportHeight: 480
        )

        #expect(anchorId == nil)
    }

    @Test("sidebar 入口尺寸与新增按钮尺寸保持一致")
    func sidebarUsesUnifiedControlSizing() {
        #expect(HomeSidebarMetrics.controlDiameter == 36)
        #expect(HomeSidebarMetrics.addButtonDiameter == 36)
    }

    @Test("统一入口在已连接时显示在线状态点")
    func sidebarHubShowsConnectedTone() {
        let tone = SidebarHubBehavior.indicatorTone(for: .connected)

        #expect(tone == .connected)
    }

    @Test("统一入口在连接中时显示过渡状态点")
    func sidebarHubShowsConnectingTone() {
        let tone = SidebarHubBehavior.indicatorTone(for: .connecting)

        #expect(tone == .connecting)
    }

    @Test("统一入口在未连接或错误时显示离线状态点")
    func sidebarHubShowsInactiveToneForOfflineStates() {
        #expect(SidebarHubBehavior.indicatorTone(for: .unpaired) == .inactive)
        #expect(SidebarHubBehavior.indicatorTone(for: .disconnected) == .inactive)
        #expect(SidebarHubBehavior.indicatorTone(for: .error("timeout")) == .inactive)
    }

    @Test("sidebar 单列宽度为 62pt")
    func sidebarUsesCompactWidth() {
        #expect(HomeSidebarMetrics.singleColumnWidth == 62)
    }

    @Test("sidebar 推出式侧边栏使用全高布局")
    func sidebarUsesFullHeightSlideOut() {
        #expect(HomeSidebarMetrics.singleColumnWidth == 62)
        #expect(HomeSidebarMetrics.sidebarLeadingPadding == 10)
    }

    @Test("sidebar 单列阶段结束后开始进入扩展进度")
    func sidebarExpansionStartsAfterCompactPhase() {
        let level1Travel: CGFloat = 102
        let level2Travel: CGFloat = 222

        let beforeCompact = SidebarExpansionBehavior.expansionProgress(
            resolvedOffset: 80,
            level1Travel: level1Travel,
            level2Travel: level2Travel
        )
        #expect(beforeCompact == 0)

        let afterCompact = SidebarExpansionBehavior.expansionProgress(
            resolvedOffset: 100,
            level1Travel: level1Travel,
            level2Travel: level2Travel
        )
        #expect(afterCompact > 0)
    }

    @Test("sidebar 扩展列数从单列直接跳到四列")
    func sidebarExpansionJumpsFromOneToFourColumns() {
        #expect(SidebarExpansionBehavior.columnCount(for: 0.0) == 1)
        #expect(SidebarExpansionBehavior.columnCount(for: 0.20) == 1)
        #expect(SidebarExpansionBehavior.columnCount(for: 0.35) == 4)
        #expect(SidebarExpansionBehavior.columnCount(for: 1.0) == 4)
    }

    @Test("sidebar 拖动中不会提前显示全屏内容")
    func sidebarFullscreenContentWaitsUntilSettle() {
        #expect(
            SidebarExpansionBehavior.showsFullScreenContent(
                sidebarLevel: 2,
                isDragging: true
            ) == false
        )

        #expect(
            SidebarExpansionBehavior.showsFullScreenContent(
                sidebarLevel: 2,
                isDragging: false
            ) == true
        )
    }

    @Test("sidebar 在 level1 和 level2 临界点附近使用 hysteresis 防抖")
    func sidebarLevelTransitionUsesHysteresis() {
        let level1Travel: CGFloat = 102
        let level2Travel: CGFloat = 222
        let boundaryOffset: CGFloat = 138

        #expect(
            SidebarExpansionBehavior.snapLevel(
                resolvedOffset: boundaryOffset,
                level1Travel: level1Travel,
                level2Travel: level2Travel,
                previousLevel: 1
            ) == 1
        )

        #expect(
            SidebarExpansionBehavior.snapLevel(
                resolvedOffset: boundaryOffset,
                level1Travel: level1Travel,
                level2Travel: level2Travel,
                previousLevel: 2
            ) == 2
        )
    }

    @Test("sidebar 会更早从 level1 进入 level2")
    func sidebarEntersLevelTwoEarlier() {
        let level1Travel: CGFloat = 102
        let level2Travel: CGFloat = 222

        #expect(
            SidebarExpansionBehavior.snapLevel(
                resolvedOffset: 150,
                level1Travel: level1Travel,
                level2Travel: level2Travel,
                previousLevel: 1
            ) == 2
        )
    }

    @Test("sidebar 会优先保留当前 gateway 的 agent 顺序再追加其他 agent")
    func sidebarExpansionKeepsCurrentGatewayAgentsFirst() {
        let current = [
            Agent(id: "a1", name: "A1", avatar: "", status: .online, unreadCount: 0, gatewayId: "gw-1"),
            Agent(id: "a2", name: "A2", avatar: "", status: .online, unreadCount: 0, gatewayId: "gw-1")
        ]
        let all = current + [
            Agent(id: "b1", name: "B1", avatar: "", status: .idle, unreadCount: 0, gatewayId: "gw-2"),
            Agent(id: "b2", name: "B2", avatar: "", status: .offline, unreadCount: 0, gatewayId: "gw-3")
        ]

        let ordered = SidebarExpansionBehavior.orderedAgents(
            currentGatewayAgents: current,
            allAgents: all
        )

        #expect(ordered.map(\.id) == ["a1", "a2", "b1", "b2"])
    }

    @Test("固定轨道侧边栏从展开态左滑后会收起")
    func sidebarRailClosesAfterLeftSwipeFromOpen() {
        let next = SidebarRailBehavior.settleOpenState(
            isOpen: true,
            translation: -40,
            predictedEndTranslation: -52
        )

        #expect(next == false)
    }

    @Test("固定轨道侧边栏从收起态右滑后会展开")
    func sidebarRailOpensAfterRightSwipeFromClosed() {
        let next = SidebarRailBehavior.settleOpenState(
            isOpen: false,
            translation: 28,
            predictedEndTranslation: 44
        )

        #expect(next == true)
    }

    @Test("固定轨道侧边栏拖拽偏移会被限制在轨道宽度内")
    func sidebarRailOffsetClampsToTrackWidth() {
        #expect(
            SidebarRailBehavior.sidebarOffset(
                isOpen: true,
                translation: -200
            ) == -SidebarRailBehavior.railWidth
        )
        #expect(
            SidebarRailBehavior.sidebarOffset(
                isOpen: false,
                translation: 200
            ) == 0
        )
    }

    @Test("session 长按预览默认锚定到最后一条消息")
    func sessionPreviewAnchorsToLastMessage() {
        let messages = [
            StoredMessage(id: "m1", role: .user, text: "第一条", timestamp: Date()),
            StoredMessage(id: "m2", role: .assistant, text: "第二条", timestamp: Date()),
            StoredMessage(id: "m3", role: .user, text: "最新一条", timestamp: Date())
        ]

        let anchorId = SessionPreviewScrollAnchorResolver.initialAnchorMessageID(in: messages)

        #expect(anchorId == "m3")
    }

    @Test("session 长按预览在没有消息时不设置锚点")
    func sessionPreviewHasNoAnchorWhenEmpty() {
        let anchorId = SessionPreviewScrollAnchorResolver.initialAnchorMessageID(in: [])

        #expect(anchorId == nil)
    }

    private func reflectedOptionalString(named label: String, from value: Any) -> String? {
        let mirror = Mirror(reflecting: value)
        guard let child = mirror.children.first(where: { $0.label == label }) else { return nil }
        if let string = child.value as? String {
            return string
        }

        let optionalMirror = Mirror(reflecting: child.value)
        guard optionalMirror.displayStyle == .optional else { return nil }
        return optionalMirror.children.first?.value as? String
    }

}
