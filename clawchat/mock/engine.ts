/**
 * Mock Engine 核心 — 处理消息路由和模拟响应生成。
 */

import type { AgentDef } from "./agents.js";
import { RESPONSES, pick } from "./responses.js";

export type ResponseMode = "echo" | "stream" | "reasoning" | "tools" | "long" | "error" | "silent";
export const ALL_INTERACTIVE_MODES: ResponseMode[] = ["stream", "reasoning", "tools", "long", "echo"];

export interface EngineConfig {
  agents: AgentDef[];
  mode: string;
  baseDelay: number;
  chunkDelay: number;
  send: (msg: any) => void;
}

export function resolveMode(text: string, configMode: string): ResponseMode {
  if (configMode !== "auto") return configMode as ResponseMode;

  const lower = text.toLowerCase();
  if (lower.includes("error") || lower.includes("错误")) return "error";
  if (lower.includes("tool") || lower.includes("工具") || lower.includes("搜索") || lower.includes("文件")) return "tools";
  if (lower.includes("think") || lower.includes("想") || lower.includes("分析") || lower.includes("推理")) return "reasoning";
  if (lower.includes("long") || lower.includes("长") || lower.includes("详细") || lower.includes("架构")) return "long";
  if (lower.includes("echo") || lower.includes("回声")) return "echo";
  if (lower.includes("silent") || lower.includes("安静")) return "silent";
  if (lower.includes("代码") || lower.includes("code")) return "stream";

  return pick(ALL_INTERACTIVE_MODES);
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function sleep(ms: number): Promise<void> {
  return new Promise((r) => setTimeout(r, ms));
}

function chunkText(text: string, size: number = 3): string[] {
  const chunks: string[] = [];
  let i = 0;
  while (i < text.length) {
    const end = Math.min(i + size + Math.floor(Math.random() * 4), text.length);
    chunks.push(text.slice(i, end));
    i = end;
  }
  return chunks;
}

// ---------------------------------------------------------------------------
// Wire-level senders
// ---------------------------------------------------------------------------

function sendTyping(cfg: EngineConfig, agentId: string, active: boolean) {
  cfg.send({ type: "typing", id: crypto.randomUUID(), ts: Date.now(), agentId, active });
}

async function sendStream(cfg: EngineConfig, agentId: string, text: string, messageId: string) {
  const chunks = chunkText(text);
  for (const chunk of chunks) {
    cfg.send({
      type: "message.stream", id: messageId, ts: Date.now(),
      agentId, delta: chunk, phase: "streaming",
    });
    await sleep(cfg.chunkDelay);
  }
  cfg.send({
    type: "message.stream", id: messageId, ts: Date.now(),
    agentId, delta: "", phase: "done", finalText: text,
  });
}

async function sendReasoning(cfg: EngineConfig, agentId: string, text: string, messageId: string) {
  const chunks = chunkText(text, 8);
  for (const chunk of chunks) {
    cfg.send({
      type: "message.reasoning", id: messageId, ts: Date.now(),
      agentId, text: chunk, phase: "streaming",
    });
    await sleep(cfg.chunkDelay * 0.7);
  }
  cfg.send({
    type: "message.reasoning", id: messageId, ts: Date.now(),
    agentId, text: "", phase: "done",
  });
}

async function sendToolEvent(cfg: EngineConfig, agentId: string, toolIndex: number) {
  const toolId = crypto.randomUUID();
  const idx = toolIndex % RESPONSES.tool_names.length;

  cfg.send({
    type: "tool.event", id: toolId, ts: Date.now(), agentId,
    tool: RESPONSES.tool_names[idx], phase: "start",
    label: RESPONSES.tool_labels[idx],
    input: RESPONSES.tool_inputs[idx],
  });

  await sleep(600 + Math.random() * 1200);

  cfg.send({
    type: "tool.event", id: toolId, ts: Date.now(), agentId,
    tool: RESPONSES.tool_names[idx], phase: "result",
    label: "完成", result: RESPONSES.tool_results[idx],
  });
}

// ---------------------------------------------------------------------------
// Public: handle an inbound message
// ---------------------------------------------------------------------------

export async function handleInbound(cfg: EngineConfig, msg: any): Promise<void> {
  const text: string = msg.text || msg.content || "";
  const agentId = msg.agentId || cfg.agents[0].id;
  const agent = cfg.agents.find((a) => a.id === agentId) || cfg.agents[0];
  const mode = resolveMode(text, cfg.mode);
  const messageId = crypto.randomUUID();

  console.log(`[${agent.name}] ← "${text}" (mode: ${mode})`);

  sendTyping(cfg, agent.id, true);
  await sleep(cfg.baseDelay);
  sendTyping(cfg, agent.id, false);

  switch (mode) {
    case "echo": {
      cfg.send({
        type: "message.outbound", id: messageId, ts: Date.now(),
        agentId: agent.id, deviceId: msg.deviceId,
        text: `Echo: ${text}`, sessionId: msg.sessionId, done: true,
      });
      break;
    }

    case "stream": {
      const response = text.includes("代码") || text.includes("code")
        ? pick(RESPONSES.code)
        : pick(RESPONSES.greeting);
      await sendStream(cfg, agent.id, response, messageId);
      break;
    }

    case "reasoning": {
      const reasoning = pick(RESPONSES.reasoning_prefix);
      const response = pick(RESPONSES.code);

      cfg.send({
        type: "message.stream", id: messageId, ts: Date.now(),
        agentId: agent.id, delta: "", phase: "streaming",
      });
      await sleep(100);

      await sendReasoning(cfg, agent.id, reasoning, messageId);
      await sleep(300);
      await sendStream(cfg, agent.id, response, messageId);
      break;
    }

    case "tools": {
      cfg.send({
        type: "message.stream", id: messageId, ts: Date.now(),
        agentId: agent.id, delta: "", phase: "streaming",
      });
      await sleep(100);

      const numTools = 1 + Math.floor(Math.random() * 3);
      for (let i = 0; i < numTools; i++) {
        await sendToolEvent(cfg, agent.id, Math.floor(Math.random() * RESPONSES.tool_names.length));
        await sleep(200);
      }
      await sleep(300);

      const response = pick(RESPONSES.code);
      await sendStream(cfg, agent.id, response, messageId);
      break;
    }

    case "long": {
      const response = pick(RESPONSES.long);
      await sendStream(cfg, agent.id, response, messageId);
      break;
    }

    case "error": {
      cfg.send({
        type: "message.stream", id: messageId, ts: Date.now(),
        agentId: agent.id, delta: "", phase: "error",
      });
      break;
    }

    case "silent":
      break;
  }
}
