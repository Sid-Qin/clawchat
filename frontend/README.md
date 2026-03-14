# ClawChat Frontend

React Native (Expo) 移动端前端，为 OpenClaw 提供类 Discord 风格的 Agent 对话交互界面。

## 技术栈

| 技术 | 版本 | 用途 |
|------|------|------|
| React Native | 0.81.5 | 跨平台移动框架 |
| Expo SDK | 54 | 开发工具链 |
| Expo Router | v6 | 文件路由系统 |
| React Native Reanimated | 4.1 | 手势动画 |
| React Native Gesture Handler | 2.28 | 手势识别 |
| expo-blur | 15.0 | 毛玻璃 / Liquid Glass 效果 |
| expo-linear-gradient | 15.0 | 渐变效果 |
| react-native-svg | 15.12 | SVG 渲染 |

## 项目结构

```
frontend/
├── app/                          # Expo Router 页面路由
│   ├── index.tsx                 # 启动 Splash Screen（ClawS Logo）
│   ├── _layout.tsx               # 根布局（ThemeProvider）
│   └── (main)/
│       ├── _layout.tsx           # 主布局（Stack Navigator）
│       ├── settings.tsx          # Agent 详细设置页
│       ├── chat/
│       │   └── [sessionId].tsx   # 聊天对话页（语音优先、模型切换、Token 消耗）
│       └── (tabs)/
│           ├── _layout.tsx       # 底部 Tab 导航（Liquid Glass 风格）
│           ├── index.tsx         # 主页（Agent Sidebar + Session 列表）
│           ├── notifications.tsx # 看板（Token 用量、系统维护、告警）
│           └── profile.tsx       # Agent 资料页（Banner、头像、信息卡片）
├── src/
│   ├── components/
│   │   ├── glass/
│   │   │   └── GlassView.tsx     # 毛玻璃组件（iOS Liquid Glass 兼容）
│   │   └── navigation/
│   │       ├── AgentSidebar.tsx   # 左侧 Agent 列表 + Gateway 切换 + 新增 Agent
│   │       ├── SessionList.tsx    # Session 列表（固定搜索框 + 可滑动列表）
│   │       └── OverlappingPanels.tsx
│   ├── theme/
│   │   ├── ThemeContext.tsx       # 主题上下文（亮/暗模式）
│   │   ├── colors.ts             # 颜色定义
│   │   ├── typography.ts         # 字体定义
│   │   └── spacing.ts            # 间距定义
│   ├── hooks/
│   │   └── useTheme.ts           # 主题 Hook
│   └── data/
│       └── mockData.ts           # Mock 数据（Agent、Session、Message、Gateway 等）
├── assets/                       # 图片资源
├── 正色版.svg                     # OpenClawS Logo
├── app.json                      # Expo 配置
├── package.json                  # 依赖清单
└── tsconfig.json                 # TypeScript 配置
```

## 页面说明

### 1. 启动页 (`app/index.tsx`)
- 纯白背景 + OpenClawS Logo
- 1.5 秒后自动跳转至主页

### 2. 主页 (`app/(main)/(tabs)/index.tsx`)
- **左侧 Sidebar**：显示当前 Gateway 下所有 Agent 头像，支持 Gateway 切换（ActionSheet）和新增 Agent（底部弹窗 + 手势下滑关闭）
- **右侧 Session 列表**：圆角面板，顶部固定搜索框，展示选中 Agent 的所有对话
- 点击 Session 进入聊天页

### 3. 聊天页 (`app/(main)/chat/[sessionId].tsx`)
- 消息气泡（用户/Agent 区分），Agent 消息底部显示 Token 消耗
- 顶部模型切换栏（MiniMax-M2.5 / 思考 / 命令 / 用量）
- 底部输入区域：附件上传、表情、文字输入、**大号麦克风按钮**（语音优先交互）

### 4. 看板页 (`app/(main)/(tabs)/notifications.tsx`)
- Token 用量卡片（7 天/30 天切换，输入/输出/缓存分项，模型分布进度条）
- 快捷操作：查看配置、恢复备份、Skills Watch、运行诊断、查看日志、工具修复、重启 Gateway、更新 OpenClaw
- 最新告警消息列表

### 5. Agent 资料页 (`app/(main)/(tabs)/profile.tsx`)
- Banner 背景图（下拉放大效果）
- 重叠式头像 + 在线状态 + 添加状态
- Agent 名称（点击切换 Agent）
- 信息卡片：默认模型、创建时间、已启用 Skills、主题设定
- 右上角设置按钮进入详细设置页

### 6. 设置页 (`app/(main)/settings.tsx`)
- 模型与能力（默认 LLM、Skills 设定、Skills Watch 开关）
- 核心文件配置（soul.md / agent.md / identity.md / tools.json / users.json）
- 记忆与上下文（长期记忆管理）
- 应用设置（暗色模式切换）

## 快速开始

### 环境要求

- Node.js >= 18
- npm 或 yarn
- Expo CLI（`npx expo`）
- iOS：Xcode + iOS 模拟器，或 [Expo Go](https://apps.apple.com/app/expo-go/id982107779) 真机调试
- Android：Android Studio + 模拟器，或 Expo Go 真机调试

### 安装与运行

```bash
# 进入前端目录
cd frontend

# 安装依赖
npm install

# 启动开发服务器
npx expo start

# 在 iOS 模拟器运行
npx expo start --ios

# 在 Android 模拟器运行
npx expo start --android
```

### 真机调试

1. 手机安装 **Expo Go** App
2. 运行 `npx expo start`
3. 扫描终端中显示的二维码即可

## 设计规范

- **风格**：极简质感，类 Discord 移动端布局
- **毛玻璃效果**：使用 `expo-blur` 实现，条件加载 `@callstack/liquid-glass`（iOS 26+）
- **底部导航**：Liquid Glass 风格，贴底无间隔，点击有弹性动画
- **主题**：支持亮色/暗色模式切换
- **安全区域**：适配 Dynamic Island 和底部 Home Indicator
- **顶部渐变遮罩**：看板页和资料页使用 `LinearGradient` 实现平滑的状态栏过渡

## 数据接口（Mock）

当前所有数据使用 `src/data/mockData.ts` 中的 Mock 数据。后端同事对接时，需要替换以下数据源：

| Mock 数据 | 说明 | 预期 API |
|-----------|------|----------|
| `mockAgents` | Agent 列表（头像、名称、模型、emoji 等） | `GET /api/agents` |
| `mockSessions` | Session 列表（标题、最后消息、时间戳） | `GET /api/agents/:id/sessions` |
| `mockMessages` | 消息列表（内容、角色、Token 消耗） | `GET /api/sessions/:id/messages` |
| `mockGateways` | Gateway 列表（名称、地址、状态） | `GET /api/gateways` |
| `mockSkills` | Skills 列表（名称、描述、启用状态） | `GET /api/agents/:id/skills` |
| `tokenUsageData` | Token 用量统计 | `GET /api/usage/tokens` |

## 注意事项

- 目前为纯前端 UI，不包含任何后端逻辑和网络请求
- 所有交互功能（Gateway 切换、Agent 新增、消息发送等）均为 UI 演示
- `react-native-svg` 用于渲染启动页的 SVG Logo
- `react-native-reanimated` + `react-native-gesture-handler` 用于弹窗手势和 Banner 拉伸动画

## License

MIT
