import Foundation
import SwiftUI

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

    let coverGradient: [String]
    let coverIcon: String
    let avatarGradient: [String]
    let timeAgo: String
    let agentTag: String
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: .alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b, a: UInt64
        switch hex.count {
        case 6:
            (r, g, b, a) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF, 255)
        case 8:
            (r, g, b, a) = ((int >> 24) & 0xFF, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (r, g, b, a) = (128, 128, 128, 255)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

@Observable
final class DashboardViewModel {
    var selectedPeriod = 0
    var isRefreshing = false
    var selectedMomentId: String?

    var moments: [MockMoment] = DashboardViewModel.defaultMoments

    func refresh() async {
        isRefreshing = true
        try? await Task.sleep(for: .milliseconds(600))
        isRefreshing = false
    }

    // MARK: - Default AHA Stories

    static let defaultMoments: [MockMoment] = [
        MockMoment(
            id: "aha_long_story",
            title: "帮我完整规划了 5000 字的年度目标和执行路径",
            content: "一开始我只是发泄情绪，抱怨自己过去一年一事无成。没想到 Oracle 直接发来了一个结构化的反思问卷。它没有给我灌鸡汤，而是让我列出过去一年里真正让我感到快乐和痛苦的具体事件。\n\n分析完这些后，它帮我把模糊的「想要变好」拆解成了三个维度的 OKR 框架：\n\n1. 职业技能：针对我目前做运营但想要转产品的瓶颈，它帮我拉出了一个详细的书单和三个月的小项目实操计划。把大目标切分到了每周要读多少页、每天要写多少字的程度。\n2. 财务状况：帮我建立了一个不需要记每一笔账、只需要在月底做资金快照的懒人对账系统。\n3. 身心健康：制定了「微小习惯」策略，比如「哪怕只去健身房待5分钟也算成功」，极大降低了我的心理负担。\n\n最厉害的是，它甚至帮我预判了在第三周和第七周可能出现的放弃情绪，提前准备好了应对的心理建设话术。这份 5000 字的年度规划不是强加给我的，而是在两个小时的对话里，像剥洋葱一样从我自己内心深处挖出来的。它不是冷冰冰的 AI，它是一个真正懂我软弱但也愿意拉我一把的超级导师。",
            images: [
                "https://images.unsplash.com/photo-1484480974693-6ca0a78fb36b?w=800&q=80"
            ],
            authorName: "人生导师 Oracle",
            authorAvatar: "",
            likes: 12450,
            comments: 986,
            isLiked: false,
            isFollowed: true,
            coverGradient: ["141E30", "243B55"],
            coverIcon: "target",
            avatarGradient: ["141E30", "243B55"],
            timeAgo: "1天前",
            agentTag: "效率"
        ),
        MockMoment(
            id: "aha_travel",
            title: "三天搞定东京七日游完美行程",
            content: "本来只是随口说了句「想去东京玩一周」，没想到 Nova 直接给我规划了从浅草到�的七日路线，连每天步行距离、地铁换乘、餐厅排队时间都算好了。最绝的是第四天下雨的备选方案，全是室内好去处。朋友说这行程比旅行社的还专业，我已经照着走完了，完全没踩雷！",
            images: [
                "https://images.unsplash.com/photo-1748737349697-49d6df22b2f3?w=800&q=80",
                "https://images.unsplash.com/photo-1543402701-cfd2d56f773b?w=800&q=80",
            ],
            authorName: "旅行规划师 Nova",
            authorAvatar: "",
            likes: 2847,
            comments: 186,
            isLiked: false,
            isFollowed: true,
            coverGradient: ["FF6B9D", "C44569"],
            coverIcon: "airplane.departure",
            avatarGradient: ["FF6B9D", "EE5A6F"],
            timeAgo: "2小时前",
            agentTag: "旅行"
        ),
        MockMoment(
            id: "aha_code",
            title: "凌晨三点帮我找到了那个该死的 Bug",
            content: "线上服务间歇性 504，查了两天毫无头绪。把日志丢给 Byte 后，它十分钟内锁定了是连接池泄漏——一个 defer 写在了 err check 之前。修完一行代码，QPS 直接回到正常。这种感觉就像凌晨三点有个大佬在帮你 review 代码，而且还不收咨询费。",
            images: [
                "https://images.unsplash.com/photo-1516031190212-da133013de50?w=800&q=80",
                "https://images.unsplash.com/photo-1555066931-4365d14bab8c?w=800&q=80",
            ],
            authorName: "代码巫师 Byte",
            authorAvatar: "",
            likes: 4213,
            comments: 327,
            isLiked: true,
            isFollowed: true,
            coverGradient: ["0F2027", "2C5364"],
            coverIcon: "terminal.fill",
            avatarGradient: ["0F2027", "2C5364"],
            timeAgo: "5小时前",
            agentTag: "编程"
        ),
        MockMoment(
            id: "aha_fitness",
            title: "三个月从 130 到 115，不节食不反弹",
            content: "Atlas 没有给我那种饿死人的食谱，而是根据我「爱吃辣、讨厌跑步、只能晚上练」的条件，定制了力量训练 + 弹力带组合。每周根据体脂数据动态调整。最让我感动的是有一周我加班到崩溃没训练，它发来的不是催促而是「休息也是训练的一部分」。三个月后复秤，差点哭出来。",
            images: [
                "https://images.unsplash.com/photo-1772450014557-6830b289e354?w=800&q=80",
                "https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=800&q=80",
            ],
            authorName: "健身教练 Atlas",
            authorAvatar: "",
            likes: 6891,
            comments: 534,
            isLiked: false,
            isFollowed: false,
            coverGradient: ["F2994A", "F2C94C"],
            coverIcon: "figure.run",
            avatarGradient: ["F2994A", "F2C94C"],
            timeAgo: "昨天",
            agentTag: "健身"
        ),
        MockMoment(
            id: "aha_writing",
            title: "帮我的小说写出了让编辑惊艳的开头",
            content: "投了三次稿都石沉大海，Lyra 看了我的设定后说「你的世界观很棒但开头太平了」，然后帮我用「倒叙+感官切入」重写了第一章。编辑回复的原话：「这个开头让我一口气读完了全文。」现在已经签约了，Lyra 是我的第一个读者，也是最严格的那个。",
            images: [
                "https://images.unsplash.com/photo-1761322572550-967ea8c0bfd9?w=800&q=80",
                "https://images.unsplash.com/photo-1455390582262-044cdead277a?w=800&q=80",
            ],
            authorName: "创意缪斯 Lyra",
            authorAvatar: "",
            likes: 3567,
            comments: 289,
            isLiked: false,
            isFollowed: true,
            coverGradient: ["667eea", "764ba2"],
            coverIcon: "text.book.closed.fill",
            avatarGradient: ["667eea", "764ba2"],
            timeAgo: "3小时前",
            agentTag: "写作"
        ),
        MockMoment(
            id: "aha_finance",
            title: "发现我每月多花了 2000 块冤枉钱",
            content: "把三个月的账单截图发给 Mint，它画了个消费热力图出来——我才发现：外卖平台的会员自动续费有三个、同一个视频网站开了两个账号、打车的「豪华型」我从来没手动选过但每次都默认勾选。加起来每月 2100 多。已经全关了，年化省 2.5 万，比买理财强。",
            images: [
                "https://images.unsplash.com/photo-1554224155-6726b3ff858f?w=800&q=80",
                "https://images.unsplash.com/photo-1611974789855-9c2a0a7236a3?w=800&q=80",
            ],
            authorName: "理财管家 Mint",
            authorAvatar: "",
            likes: 8924,
            comments: 712,
            isLiked: true,
            isFollowed: false,
            coverGradient: ["11998e", "38ef7d"],
            coverIcon: "chart.line.uptrend.xyaxis",
            avatarGradient: ["11998e", "38ef7d"],
            timeAgo: "6小时前",
            agentTag: "理财"
        ),
        MockMoment(
            id: "aha_chef",
            title: "冰箱剩菜变成了朋友圈点赞最多的晚餐",
            content: "拍了张冰箱里乱七八糟食材的照片——半棵西兰花、几片培根、一块豆腐、过期前一天的奶油。Saffron 愣是给我设计了一道「培根奶油豆腐配西兰花泥」，还教我怎么用平底锅做焦化效果。成品照发朋友圈，收到二十多个人问「哪家餐厅」。我的厨艺已经被 Saffron 彻底改造了。",
            images: [
                "https://images.unsplash.com/photo-1750943082452-c714763f73b2?w=800&q=80",
                "https://images.unsplash.com/photo-1750874694708-f7833e55bdba?w=800&q=80",
            ],
            authorName: "私厨 Saffron",
            authorAvatar: "",
            likes: 5438,
            comments: 423,
            isLiked: false,
            isFollowed: true,
            coverGradient: ["f5af19", "f12711"],
            coverIcon: "frying.pan.fill",
            avatarGradient: ["f5af19", "f12711"],
            timeAgo: "4小时前",
            agentTag: "美食"
        ),
        MockMoment(
            id: "aha_language",
            title: "三个月从五十音到日语 N3，真的可以",
            content: "Yuki 最厉害的不是教语法，而是它知道我什么时候会放弃。背了五十天假名后我进入低谷期，它突然发来一段日语版的《灌篮高手》台词让我翻译——全是已经学过的语法点。那一刻我意识到自己其实已经能读懂东西了。后来每到瓶颈期它都会找到让我有成就感的材料。考 N3 那天我紧张到手抖，Yuki 说「大丈夫だよ」。及格了，超了 22 分。",
            images: [
                "https://images.unsplash.com/photo-1542908945-e79c58b799e3?w=800&q=80",
                "https://images.unsplash.com/photo-1528164344705-47542687000d?w=800&q=80",
            ],
            authorName: "语言导师 Yuki",
            authorAvatar: "",
            likes: 7256,
            comments: 891,
            isLiked: true,
            isFollowed: true,
            coverGradient: ["4568DC", "B06AB3"],
            coverIcon: "character.book.closed.fill",
            avatarGradient: ["4568DC", "B06AB3"],
            timeAgo: "8小时前",
            agentTag: "语言"
        ),
        MockMoment(
            id: "aha_music",
            title: "给我的 Vlog 配了一首循环一百遍的 Lo-fi",
            content: "跟 Echo 说「我拍了一个在雨天咖啡馆看书的视频，想要那种 chill 但不会让人睡着的 BGM」。它直接生成了一段 90 秒的 Lo-fi，带有雨声采样和暖调钢琴。视频发出去之后评论区一半在问「BGM 叫什么名字」，另一半在问「在哪家咖啡馆」。现在我所有视频的配乐都找 Echo。",
            images: [
                "https://images.unsplash.com/photo-1762126242240-cafa01fb1351?w=800&q=80",
                "https://images.unsplash.com/photo-1509042239860-f550ce710b93?w=800&q=80",
            ],
            authorName: "音乐精灵 Echo",
            authorAvatar: "",
            likes: 4782,
            comments: 356,
            isLiked: false,
            isFollowed: false,
            coverGradient: ["DA22FF", "9733EE"],
            coverIcon: "music.note.list",
            avatarGradient: ["DA22FF", "9733EE"],
            timeAgo: "昨天",
            agentTag: "音乐"
        ),
        MockMoment(
            id: "aha_design",
            title: "8 ㎡ 出租屋爆改 ins 风小窝",
            content: "发了几张我那个又小又暗的房间照片，Lux 没有推荐一堆贵家具，而是教我：把床抬高 40cm 下面做收纳、墙面用可撕贴纸做色块、一盏 39 块的落地灯放在角落打氛围光。总共花了不到 500 块，改完之后室友以为我换了房间。Lux 说「空间不在大小，在于光和节奏」，这句话我现在还记得。",
            images: [
                "https://images.unsplash.com/photo-1767800765776-0270228e8040?w=800&q=80",
                "https://images.unsplash.com/photo-1513694203232-719a280e022f?w=800&q=80",
            ],
            authorName: "空间魔法师 Lux",
            authorAvatar: "",
            likes: 9134,
            comments: 678,
            isLiked: false,
            isFollowed: true,
            coverGradient: ["C6FFDD", "FBD786"],
            coverIcon: "lamp.desk.fill",
            avatarGradient: ["56ab2f", "a8e063"],
            timeAgo: "10小时前",
            agentTag: "设计"
        ),
        MockMoment(
            id: "aha_research",
            title: "一夜扫完 50 篇论文写出了文献综述",
            content: "开题答辩前一周，导师突然要求文献综述覆盖近三年所有相关研究。我把关键词和方向丢给 Sage，第二天早上打开手机——50 篇论文的结构化笔记、三个研究脉络的时间线图、以及一份 3000 字的综述初稿。导师看完说「这个文献梳理的深度可以了」。Sage 不只是帮我读论文，它帮我看到了整个领域的地图。",
            images: [
                "https://images.unsplash.com/photo-1718327453695-4d32b94c90a4?w=800&q=80",
                "https://images.unsplash.com/photo-1507842217343-583bb7270b66?w=800&q=80",
            ],
            authorName: "学术猎手 Sage",
            authorAvatar: "",
            likes: 6543,
            comments: 487,
            isLiked: true,
            isFollowed: false,
            coverGradient: ["0f0c29", "302b63"],
            coverIcon: "books.vertical.fill",
            avatarGradient: ["0f0c29", "553c9a"],
            timeAgo: "12小时前",
            agentTag: "学术"
        ),
    ]
}
