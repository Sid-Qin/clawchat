import Foundation

enum MockData {
    static let gateways: [Gateway] = [
        Gateway(id: "g1", name: "本地 Gateway", url: "127.0.0.1:18789", type: .local, status: .online, ping: 12),
        Gateway(id: "g2", name: "NERV Cloud", url: "nerv.openclaw.ai", type: .cloud, status: .online, ping: 45),
        Gateway(id: "g3", name: "SEELE Cloud", url: "seele.openclaw.ai", type: .cloud, status: .online, ping: 88),
    ]

    static let skills: [Skill] = [
        Skill(id: "sk1", name: "Terminal Explorer", description: "允许 Agent 执行安全的 shell 命令", isEnabled: true),
        Skill(id: "sk2", name: "File System Access", description: "读写本地工作区文件", isEnabled: true),
        Skill(id: "sk3", name: "Web Browser", description: "使用无头浏览器访问网页", isEnabled: true),
        Skill(id: "sk4", name: "GitHub Integration", description: "读取和创建 Issues, PRs", isEnabled: false),
        Skill(id: "sk5", name: "Database Client", description: "连接和查询 SQL 数据库", isEnabled: false),
    ]

    static let agents: [Agent] = [
        // 本地 Gateway (g1) — 4 agents
        Agent(id: "1", name: "EVA-01", avatar: "avatar_eva01", status: .online, unreadCount: 0, gatewayId: "g1", model: "MiniMax-M2.5", theme: "Test type: Shinji Ikari. Synchro rate 400%."),
        Agent(id: "2", name: "EVA-00", avatar: "avatar_eva00", status: .online, unreadCount: 0, gatewayId: "g1", model: "Claude 3.5 Sonnet"),
        Agent(id: "3", name: "EVA-02", avatar: "avatar_eva02", status: .idle, unreadCount: 0, gatewayId: "g1", model: "GPT-4o"),
        Agent(id: "5", name: "MAGI", avatar: "avatar_magi", status: .online, unreadCount: 0, gatewayId: "g1", model: "Claude 3.5 Sonnet"),
        // NERV Cloud (g2) — 3 agents
        Agent(id: "4", name: "Misato", avatar: "avatar_misato", status: .online, unreadCount: 0, gatewayId: "g2", model: "GPT-4o"),
        Agent(id: "6", name: "Kaworu", avatar: "avatar_kaworu", status: .online, unreadCount: 0, gatewayId: "g2", model: "MiniMax-M2.5"),
        Agent(id: "7", name: "Ritsuko", avatar: "avatar_ritsuko", status: .idle, unreadCount: 0, gatewayId: "g2", model: "Claude 3.5 Sonnet"),
        // SEELE Cloud (g3) — 2 agents
        Agent(id: "8", name: "Kaji", avatar: "avatar_kaji", status: .online, unreadCount: 0, gatewayId: "g3", model: "GPT-4o"),
        Agent(id: "9", name: "Gendo", avatar: "avatar_gendo", status: .dnd, unreadCount: 0, gatewayId: "g3", model: "MiniMax-M2.5"),
    ]

    static let sessions: [Session] = [
        Session(id: "s1", agentId: "1", title: "同步率测试", category: "作战", lastMessage: "EVA-01: AT Field 展开完毕，同步率稳定", lastMessageTime: date(2026, 3, 10, 13, 36), unreadCount: 0),
        Session(id: "s2", agentId: "2", title: "零号机诊断", category: "技术", lastMessage: "EVA-00: 核心温度正常，等待下一步指令", lastMessageTime: date(2026, 3, 10, 10, 0), unreadCount: 0),
        Session(id: "s3", agentId: "3", title: "出击准备", category: "作战", lastMessage: "EVA-02: 已就绪，随时可以出击", lastMessageTime: date(2026, 3, 7, 22, 0), unreadCount: 0),
        Session(id: "s4", agentId: "4", title: "作战计划", category: "指挥", lastMessage: "Misato: 全员进入一级战备状态", lastMessageTime: date(2026, 3, 7, 18, 0), unreadCount: 0),
        Session(id: "s5", agentId: "5", title: "系统分析", category: "技术", lastMessage: "MAGI: 使徒反应模式分析完毕", lastMessageTime: date(2026, 3, 4, 12, 0), unreadCount: 0),
        Session(id: "s6", agentId: "6", title: "交流", category: "日常", lastMessage: "Kaworu: 与你相遇，是我的命运", lastMessageTime: date(2026, 3, 3, 15, 0), unreadCount: 0),
        Session(id: "s7", agentId: "7", title: "研究报告", category: "技术", lastMessage: "Ritsuko: DUMMY PLUG 系统进入待机状态", lastMessageTime: date(2026, 3, 3, 12, 0), unreadCount: 0),
        Session(id: "s8", agentId: "8", title: "情报回传", category: "机密", lastMessage: "Kaji: 文件已送达，注意安全", lastMessageTime: date(2026, 3, 3, 10, 0), unreadCount: 0),
        Session(id: "s9", agentId: "9", title: "人类补完计划", category: "机密", lastMessage: "Gendo: 一切按计划进行", lastMessageTime: date(2026, 3, 3, 9, 0), unreadCount: 0),
    
    ]

    static let messages: [Message] = [
        Message(id: "m1", sessionId: "s1", senderId: "1", senderName: "EVA-01", senderAvatar: "avatar_eva01", content: "同步率测试开始。驾驶员：碇真嗣。", timestamp: date(2026, 3, 10, 12, 45), type: .system),
        Message(id: "m2", sessionId: "s1", senderId: "me", senderName: "Sid", senderAvatar: "me", content: "开始同步测试，目标同步率 90% 以上", timestamp: date(2026, 3, 10, 13, 36), type: .text),
        Message(id: "m3", sessionId: "s1", senderId: "1", senderName: "EVA-01", senderAvatar: "avatar_eva01", content: "AT Field 展开完毕，当前同步率 95.7%，所有系统运行正常。", timestamp: date(2026, 3, 10, 13, 36), type: .text, tokenCount: 142),
    ]

    static let availableModels = ["MiniMax-M2.5", "Claude 3.5 Sonnet", "GPT-4o"]

    private static func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        return Calendar.current.date(from: components) ?? Date()
    }
}
