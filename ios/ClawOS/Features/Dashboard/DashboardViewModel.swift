import Foundation

struct MockMoment: Identifiable {
    let id: String
    let title: String
    let content: String
    /// Asset image names (local) or URL strings (remote)
    let images: [String]
    let authorName: String
    /// Asset image name for avatar
    let authorAvatar: String
    let likes: Int
    let comments: Int
    let isLiked: Bool
    let isFollowed: Bool
}

@Observable
final class DashboardViewModel {
    var selectedPeriod = 0
    var isRefreshing = false
    var selectedMomentId: String?

    let mockMoments: [MockMoment] = [
        MockMoment(
            id: "m1",
            title: "EVA 初号机机械设定图 | Agent 一键生成",
            content: "用 Mech Blueprint Agent 直接生成了这张初号机的机械设定水彩图。\n提示词只写了 'EVA Unit-01 mechanical blueprint watercolor'。\n细节炸裂，连内部骨架结构都画出来了！",
            images: ["eva_unit01_green", "eva_mech_hd"],
            authorName: "NERV技术部",
            authorAvatar: "avatar_misato",
            likes: 3072,
            comments: 89,
            isLiked: false,
            isFollowed: true
        ),
        MockMoment(
            id: "m2",
            title: "三台 EVA 同框出击 | 经典名场面复刻",
            content: "经典的初号机、零号机、贰号机三机同框画面！\n用 Classic Anime Agent 一键还原了这个名场面，夕阳下的剪影太帅了。\n直接设成壁纸了！",
            images: ["eva_units_lineup", "eva_unit_battle"],
            authorName: "绫波の猫",
            authorAvatar: "avatar_eva00",
            likes: 5120,
            comments: 178,
            isLiked: true,
            isFollowed: false
        ),
        MockMoment(
            id: "m3",
            title: "使徒殲滅战 | 初号机暴走名场面",
            content: "初号机 vs 使徒的经典对决！这个 Agent 对 EVA 暴走状态的理解太到位了。\n光环 + 长枪 + 爆炸的构图，完美还原了剧场版的名场面。",
            images: ["eva_cockpit"],
            authorName: "式波同学",
            authorAvatar: "avatar_eva02",
            likes: 4096,
            comments: 134,
            isLiked: false,
            isFollowed: true
        ),
        MockMoment(
            id: "m4",
            title: "NERV 第三新东京市 | 概念设定图",
            content: "这张第三新东京市的概念设定图让人想起 NERV 本部上空的那片天空。\n远处的穹顶结构 + NERV Logo，世界观沉浸感拉满。\n适合做手机壁纸！",
            images: ["eva_scene02", "eva_mech_wide"],
            authorName: "碇指令",
            authorAvatar: "avatar_gendo",
            likes: 2048,
            comments: 67,
            isLiked: false,
            isFollowed: false
        ),
        MockMoment(
            id: "m5",
            title: "量产机红海名场面 | 明日香最后的战斗",
            content: "明日香 vs 量产机的红海场景！\n这个 Agent 把 End of Evangelion 最震撼的一幕完美重现了。\n蓝色的量产机群 + 红色的 LCL 之海，视觉冲击力太强了。",
            images: ["eva_poster", "eva_city_attack"],
            authorName: "初号机补完计划",
            authorAvatar: "avatar_kaworu",
            likes: 6144,
            comments: 312,
            isLiked: false,
            isFollowed: true
        ),
        MockMoment(
            id: "m6",
            title: "零号机 × 绫波丽 | 机体细节 3D 渲染",
            content: "用 3D Render Agent 生成了零号机的超精细渲染图。\n绫波丽坐在机体旁边，零号机的橙黄配色和机械细节清晰可见。\n这个 Agent 对 EVA 机体结构的理解简直是专业级。",
            images: ["eva_mech_detail", "eva_scene03"],
            authorName: "使徒歼灭者",
            authorAvatar: "avatar_ritsuko",
            likes: 2560,
            comments: 93,
            isLiked: false,
            isFollowed: true
        )
    ]

    func refresh() async {
        isRefreshing = true
        try? await Task.sleep(for: .milliseconds(600))
        isRefreshing = false
    }
}
