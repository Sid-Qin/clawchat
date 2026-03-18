/**
 * Mock 响应数据库 — 各种场景的预制回复内容。
 */

export const RESPONSES = {
  greeting: [
    "你好！有什么我可以帮助你的吗？",
    "嗨，今天有什么想聊的？",
    "你好啊，很高兴见到你！",
    "有什么可以效劳的？随时告诉我。",
  ],

  thinking: [
    "让我想想这个问题。首先，我们需要考虑几个方面……\n\n嗯，从技术角度来看，这确实是一个有趣的挑战。",
    "这是一个很好的问题。让我从不同维度分析一下……",
    "我正在思考最佳的解决方案。需要权衡几个因素……",
  ],

  code: [
    "这是一个 Swift 示例：\n\n```swift\nstruct ContentView: View {\n    @State private var count = 0\n    \n    var body: some View {\n        VStack(spacing: 20) {\n            Text(\"计数: \\(count)\")\n                .font(.largeTitle)\n            \n            Button(\"增加\") {\n                withAnimation {\n                    count += 1\n                }\n            }\n            .buttonStyle(.borderedProminent)\n        }\n        .padding()\n    }\n}\n```\n\n这个 View 使用了 `@State` 来管理本地状态，并通过 `withAnimation` 添加了过渡动画。",

    "好的，我来帮你写一个网络请求的例子：\n\n```swift\nfunc fetchUsers() async throws -> [User] {\n    let url = URL(string: \"https://api.example.com/users\")!\n    let (data, response) = try await URLSession.shared.data(from: url)\n    \n    guard let httpResponse = response as? HTTPURLResponse,\n          httpResponse.statusCode == 200 else {\n        throw NetworkError.invalidResponse\n    }\n    \n    return try JSONDecoder().decode([User].self, from: data)\n}\n```",

    "来看一个 Combine 的例子：\n\n```swift\nclass SearchViewModel: ObservableObject {\n    @Published var query = \"\"\n    @Published var results: [Item] = []\n    private var cancellables = Set<AnyCancellable>()\n    \n    init() {\n        $query\n            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)\n            .removeDuplicates()\n            .filter { !$0.isEmpty }\n            .flatMap { query in\n                APIService.search(query)\n            }\n            .receive(on: DispatchQueue.main)\n            .assign(to: &$results)\n    }\n}\n```\n\n这里用 `debounce` 避免频繁请求，`removeDuplicates` 去重。",
  ],

  long: [
    "# 关于 SwiftUI 的架构最佳实践\n\n## 1. MVVM 模式\n\nSwiftUI 天然适合 MVVM 架构。View 负责 UI 展示，ViewModel 负责业务逻辑和状态管理。\n\n### 核心原则\n\n- **单向数据流**: 数据从 ViewModel 流向 View，用户交互通过 ViewModel 的方法修改状态\n- **可测试性**: ViewModel 不依赖 UIKit/SwiftUI，可以独立进行单元测试\n- **关注点分离**: View 只关心「如何展示」，ViewModel 关心「展示什么」\n\n## 2. 依赖注入\n\n使用 `@Environment` 和自定义 EnvironmentKey 来实现依赖注入：\n\n```swift\nprivate struct NetworkServiceKey: EnvironmentKey {\n    static let defaultValue: NetworkService = URLSessionNetworkService()\n}\n```\n\n## 3. 状态管理\n\n- `@State` — 视图内部的简单状态\n- `@StateObject` — 视图拥有的 ObservableObject\n- `@ObservedObject` — 外部传入的 ObservableObject\n- `@EnvironmentObject` — 通过环境注入的共享状态\n\n## 4. 性能优化\n\n- 避免在 body 中做复杂计算\n- 使用 `LazyVStack` / `LazyHStack` 替代普通 Stack\n- 合理拆分子视图，减少不必要的重绘\n- 使用 `equatable()` 修饰符优化比较\n\n---\n\n以上就是 SwiftUI 架构的核心建议，希望对你有帮助！",

    "# WebSocket 实时通信完整指南\n\n## 概述\n\nWebSocket 提供全双工通信通道，适合聊天、实时协作、游戏等场景。\n\n## 1. 连接管理\n\n```swift\nclass WebSocketManager {\n    private var task: URLSessionWebSocketTask?\n    \n    func connect(to url: URL) {\n        task = URLSession.shared.webSocketTask(with: url)\n        task?.resume()\n        listen()\n    }\n    \n    private func listen() {\n        task?.receive { [weak self] result in\n            switch result {\n            case .success(let message):\n                self?.handle(message)\n                self?.listen()\n            case .failure(let error):\n                self?.handleError(error)\n            }\n        }\n    }\n}\n```\n\n## 2. 心跳机制\n\n保持连接活跃，检测断线：\n- 每 30 秒发送 ping\n- 10 秒内未收到 pong 视为断连\n- 断连后指数退避重连：1s → 2s → 4s → 8s（最大 60s）\n\n## 3. 消息协议\n\n推荐 JSON 格式，包含 `type`、`id`、`ts` 三个基础字段。\n\n---\n\n掌握这些就够应付大多数实时通信需求了。",
  ],

  reasoning_prefix: [
    "用户问了一个关于编程的问题。让我分析一下他的具体需求……\n\n首先，我需要理解上下文。看起来这是一个 iOS 开发相关的问题。\n\n让我考虑几种方案：\n1. 直接回答具体问题\n2. 提供代码示例\n3. 解释背后的原理\n\n我认为最好结合实际代码来解释。",
    "这个问题需要我思考一下。让我分析：\n\n- 用户的意图是什么？\n- 有哪些可能的解决方案？\n- 哪个方案最适合当前场景？\n\n综合考虑，我会给出一个包含代码的详细回答。",
    "好的，让我仔细思考这个问题。\n\n从几个角度来看：\n1. 性能影响 — 这个方案的时间复杂度如何？\n2. 可维护性 — 代码是否容易理解和修改？\n3. 扩展性 — 未来需求变化时是否容易适配？\n\n权衡之后，我推荐以下方案。",
  ],

  tool_names: ["read_file", "write_file", "search_code", "run_command", "web_search", "analyze_image"],
  tool_labels: ["读取文件", "写入文件", "搜索代码", "执行命令", "网页搜索", "分析图片"],
  tool_inputs: [
    { path: "src/App.swift" },
    { path: "Package.swift", content: "// updated" },
    { query: "fetchData", scope: "src/" },
    { command: "swift build" },
    { query: "SwiftUI best practices 2026" },
    { url: "https://example.com/screenshot.png" },
  ],
  tool_results: [
    "找到文件 src/App.swift (42 行)",
    "文件已写入 ✓",
    "找到 3 处匹配：App.swift:12, ViewModel.swift:34, Service.swift:56",
    "Build succeeded (2.3s)",
    "找到 5 篇相关文章",
    "图片分析完成：检测到 UI 布局问题",
  ],

  error_messages: [
    "抱歉，我在处理这个请求时遇到了问题。请稍后重试。",
    "服务暂时不可用，请稍候。",
    "模型调用超时，请重新发送消息。",
  ],
};

export function pick<T>(arr: T[]): T {
  return arr[Math.floor(Math.random() * arr.length)];
}
