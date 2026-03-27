# ClawChat Mock Engine

独立于真实 OpenClaw 的模拟 gateway，用于 iOS app 开发测试。

## 快速开始

```bash
# 先确保 relay 在跑
cd clawchat/service && bun dev

# 启动 mock（从 clawchat/ 目录）
bun mock/start.ts
```

## 预设

| 预设 | Agent 数 | 命令 |
|------|---------|------|
| `single` | 1 | `bun mock/start.ts` |
| `multi` | 5 | `bun mock/start.ts --preset multi` |
| `squad` | 10 | `bun mock/start.ts --preset squad` |
| `massive` | 20 | `bun mock/start.ts --preset massive` |

## 响应模式

`--mode auto`（默认）会根据消息关键词自动选择：

| 模式 | 触发关键词 | 行为 |
|------|-----------|------|
| `stream` | 代码/code | 流式文本 |
| `reasoning` | 想/分析/推理/think | 先推理再回答 |
| `tools` | 工具/搜索/文件/tool | 工具调用 → 结果 → 回答 |
| `long` | 长/详细/架构/long | 长篇 Markdown |
| `echo` | echo/回声 | 原样返回 |
| `error` | error/错误 | 模拟错误 |
| `silent` | silent/安静 | 不响应 |

也可以固定模式：`bun mock/start.ts --mode reasoning`

## 其他参数

```bash
--relay <url>       # Relay 地址 (default: ws://localhost:8787)
--delay <ms>        # typing 延迟 (default: 800)
--chunk-delay <ms>  # 流式 chunk 间隔 (default: 50)
```

## 文件结构

```
mock/
├── start.ts      # 入口 — 连接 relay、处理协议
├── engine.ts     # 核心 — 消息路由、响应生成
├── agents.ts     # 预设 — agent 定义和组合
├── responses.ts  # 数据 — mock 回复内容库
└── README.md
```

## 与真实数据的关系

Mock engine 完全独立运行，不依赖：
- OpenClaw 实例
- API key
- yescode 代理

和真实 `scripts/openclaw-bridge.ts` 互斥使用——同一时间只连一个 gateway 到 relay。
