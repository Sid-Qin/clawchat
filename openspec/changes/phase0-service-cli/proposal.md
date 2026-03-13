## Why

OpenClaw 的 AI agent 能力（流式输出、reasoning 块、tool 可视化、approval 流、canvas/A2UI）无法通过任何现有第三方 channel 完整暴露。需要一个第一方 messaging service，让 gateway 保持在 NAT 后面（outbound 连接），同时让任意客户端也通过 outbound 连接到同一个 relay 服务。Phase 0 的目标是先把 relay service 和 CLI client 跑通，验证协议可行性，为后续 iOS/Android app 打基础。

## What Changes

- 新建 ClawChat Service（WebSocket relay），接受 gateway 和 client 的 outbound 连接，转发消息
- 新建 CLI reference client，用终端实现完整的聊天交互，验证协议链路
- 实现最小协议集：连接/配对、文本收发、流式输出、typing/presence、错误处理
- 项目使用 Bun runtime + Hono（HTTP 路由）+ bun:sqlite（pairing 注册表）

## Capabilities

### New Capabilities

- `relay-service`: WebSocket relay 服务。接受 gateway 注册和 app 配对，双向转发消息，管理 presence 状态。使用 Bun 原生 WebSocket + Hono HTTP 路由 + SQLite 存储 pairing/device token。
- `wire-protocol`: 通信协议核心类型定义。Phase 0 最小集：gateway.register、app.pair/connect、message.inbound/outbound、message.stream、typing、presence、error。TypeScript 类型包，service 和 cli 共享。
- `cli-client`: 终端聊天客户端。连接 relay，完成 pairing，发送文本消息，接收并渲染流式响应和 tool 事件。用于协议验证和开发调试。
- `pairing-flow`: 配对机制。gateway 生成 6 字符 pairing code 并显示，用户在 client 输入 code，relay 验证并建立 gateway-device 绑定关系，发放 long-lived device token 用于后续自动重连。

### Modified Capabilities

- `architecture`: system-architecture.md 需要补充 Phase 0 的具体技术选型和目录结构

## Impact

- **新增目录**: `service/`（relay 服务）、`cli/`（CLI 客户端）、`protocol/`（共享类型）
- **依赖**: Bun runtime、Hono、bun:sqlite
- **部署**: Phase 0 单实例部署（Fly.io 或本地开发）
- **OpenClaw 侧**: 暂不需要改动 openclaw 仓库，channel plugin 在 Phase 1 再做
