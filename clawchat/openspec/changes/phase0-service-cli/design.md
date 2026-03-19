## Context

ClawChat 是 OpenClaw 生态的第一方 messaging service。当前 OpenClaw 的所有 channel（Telegram、Discord、Slack 等）都受限于第三方平台的 API 能力，无法暴露 agent 的完整能力（streaming、reasoning、tool 可视化、approval、canvas）。

Phase 0 的目标是搭建最小可用的 relay service + CLI client，验证协议链路，为 Phase 2 的 iOS/Android app 打基础。

当前状态：项目刚初始化，无现有代码。架构 spec 已就位（`openspec/specs/architecture/`），wire protocol 已定义。

## Goals / Non-Goals

**Goals:**
- 实现 WebSocket relay service，支持 gateway 注册和 app 配对
- 实现 CLI reference client，能完成完整聊天链路
- 验证 Phase 0 协议最小集（连接、文本、流式、typing、error）
- 项目结构清晰，为后续 iOS/Android 开发留好位置

**Non-Goals:**
- Push notifications（Phase 2）
- E2EE（Phase 4）
- Canvas/A2UI、polls、reactions、threads（Phase 3）
- Channel plugin 提交到 openclaw 仓库（Phase 1）
- 生产级部署、HA、rate limiting（Phase 4）
- 文件传输 / 大文件上传（Phase 2+）

## Decisions

### 1. Monorepo 结构（Bun workspace）

```
clawchat/
├── packages/
│   └── protocol/          # 共享类型定义（TypeScript）
├── service/               # Relay service
├── cli/                   # CLI client
├── ios/                   # (Phase 2)
├── android/               # (Phase 2)
└── package.json           # Bun workspace root
```

**Rationale**: service 和 cli 共享协议类型。Bun workspace 零配置，比 npm/pnpm workspace 更简单。iOS/Android 不在 workspace 里，它们通过 wire protocol（JSON）通信，不依赖 TypeScript 类型。

**Alternative**: 分仓库。否决原因：Phase 0 阶段协议会频繁改动，同仓库改起来快。

### 2. Relay Service: Bun + Hono + SQLite

- **Bun**: 原生 WebSocket server（`Bun.serve`），性能好，与 OpenClaw 生态一致
- **Hono**: 轻量 HTTP 框架，用于 health check、pairing API、未来的 push webhook
- **bun:sqlite**: 零依赖嵌入式数据库，存 pairing registry + device tokens

**Rationale**: 全栈 Bun 意味着零原生依赖，`bun build` 可以产出单文件部署。Hono 比 Express 更轻，且对 Bun/Cloudflare Workers 兼容好。SQLite 足够 Phase 0 的单实例场景。

**Alternative**: Redis。否决原因：增加部署依赖，单实例场景没必要。

### 3. Pairing 机制：6 字符 code + device token

流程：
1. Gateway 连接 relay，注册 `gatewayId` + `token`
2. Gateway 调用 relay API 生成 pairing code（6 字符，5 分钟过期）
3. 用户在 CLI/app 输入 pairing code
4. Relay 验证 code，绑定 device 到 gateway，返回 `deviceToken`（UUID, long-lived）
5. 后续连接使用 `deviceToken` 自动重连，无需重新配对

**Rationale**: 类似 WhatsApp Web 的配对模式。Code 短、好输入；device token 长期有效避免反复配对。

**Alternative**: QR code。Phase 0 不做 QR（CLI 没法扫），Phase 2 app 再加。

### 4. CLI Client: 终端交互式聊天

- 使用 `readline` 或 `@clack/prompts` 做输入
- 流式输出直接写 stdout（逐 token 打印）
- Tool 事件用彩色 block 显示
- Reasoning 用灰色折叠样式

**Rationale**: CLI 是最快验证协议的方式。不需要 UI 框架，几百行代码。

### 5. 协议版本协商

连接时带 `protocolVersion: "0.1.0"`。Service 检查兼容性，不兼容则返回 error。

Phase 0 固定 `0.1.0`，后续版本变更时通过 semver 判断向后兼容性。

## Risks / Trade-offs

- **[Risk] 协议在 Phase 0 结束后大改** → Mitigation: Phase 0 只实现最小集，大功能（canvas、polls）等协议稳定后再加。CLI client 作为协议验证工具，改起来成本低。
- **[Risk] SQLite 单实例瓶颈** → Mitigation: Phase 0 不需要 HA。Phase 4 时可切换到 Redis/Postgres，pairing registry 接口抽象为 store interface。
- **[Risk] 无 auth/rate limiting，relay 可被滥用** → Mitigation: Phase 0 是开发/测试环境。Phase 4 加 token 验证 + rate limiting。
- **[Trade-off] Bun 生态不如 Node 成熟** → Accepted: WebSocket + SQLite + Hono 都是 Bun 一等公民，Phase 0 不需要复杂库。

## Open Questions

1. **Relay 部署域名**: 用 `relay.clawchat.io` 还是 `api.clawchat.io`？需要先注册域名。
2. **Gateway token 生成**: 由 gateway 本地生成（`openclaw config`）还是由 relay 分配？Phase 0 先用 gateway 本地生成。
3. **消息大小限制**: Phase 0 是否需要限制单条消息大小？暂定 1MB。
