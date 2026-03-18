#!/usr/bin/env bun
/**
 * ClawChat Mock Engine — 独立于真实 OpenClaw 的模拟 gateway。
 *
 * Usage:
 *   bun mock/start.ts [options]
 *
 * Options:
 *   --relay <url>       Relay URL (default: ws://localhost:8787)
 *   --preset <name>     single | multi | squad | massive (default: single)
 *   --mode <name>       auto | echo | stream | reasoning | tools | long | error | silent (default: auto)
 *   --delay <ms>        Typing delay (default: 800)
 *   --chunk-delay <ms>  Stream chunk interval (default: 50)
 *
 * Examples:
 *   bun mock/start.ts                          # 1 agent, auto mode
 *   bun mock/start.ts --preset multi           # 5 agents
 *   bun mock/start.ts --preset massive         # 20 agents
 *   bun mock/start.ts --mode reasoning         # 固定推理模式
 *   bun mock/start.ts --preset squad --mode tools
 */

import { parseArgs } from "node:util";
import { getAgents, encodeDescriptor, buildAgentsMeta, PRESETS } from "./agents.js";
import { handleInbound, type EngineConfig } from "./engine.js";

const { values: args } = parseArgs({
  options: {
    relay: { type: "string", default: "ws://localhost:8787" },
    preset: { type: "string", default: "single" },
    mode: { type: "string", default: "auto" },
    delay: { type: "string", default: "800" },
    "chunk-delay": { type: "string", default: "50" },
  },
});

const RELAY_URL = args.relay!;
const PRESET = args.preset!;
const MODE = args.mode!;
const BASE_DELAY = parseInt(args.delay!, 10);
const CHUNK_DELAY = parseInt(args["chunk-delay"]!, 10);
const GATEWAY_ID = `mock-${PRESET}-${crypto.randomUUID().slice(0, 6)}`;
const GATEWAY_TOKEN = crypto.randomUUID();

const AGENTS = getAgents(PRESET);
const DESCRIPTORS = AGENTS.map(encodeDescriptor);
const AGENTS_META = buildAgentsMeta(AGENTS);

// ---------------------------------------------------------------------------
// WebSocket
// ---------------------------------------------------------------------------

let ws: WebSocket;

function send(msg: any) {
  if (ws?.readyState === WebSocket.OPEN) {
    ws.send(JSON.stringify(msg));
  }
}

const engineConfig: EngineConfig = {
  agents: AGENTS,
  mode: MODE,
  baseDelay: BASE_DELAY,
  chunkDelay: CHUNK_DELAY,
  send,
};

function broadcastStatus() {
  send({
    type: "status.response", id: crypto.randomUUID(), ts: Date.now(),
    gatewayOnline: true, agents: DESCRIPTORS,
    agentsMeta: AGENTS_META, connectedDevices: 1,
  });
}

function connect() {
  const url = `${RELAY_URL}/ws/gateway`;
  console.log(`[mock] Connecting to ${url} ...`);
  ws = new WebSocket(url);

  ws.addEventListener("open", () => {
    send({
      type: "gateway.register", id: crypto.randomUUID(), ts: Date.now(),
      gatewayId: GATEWAY_ID, token: GATEWAY_TOKEN,
      protocolVersion: "0.1.0", version: "2026.3.17-mock",
      agents: DESCRIPTORS, agentsMeta: AGENTS_META,
    });
  });

  ws.addEventListener("message", (event) => {
    const msg = JSON.parse(String(event.data));

    switch (msg.type) {
      case "gateway.registered":
        console.log(`[mock] Registered! Paired devices: ${msg.pairedDevices}`);
        broadcastStatus();
        send({ type: "pair.generate", id: crypto.randomUUID(), ts: Date.now() });
        break;

      case "pair.code":
        console.log("");
        console.log("╔══════════════════════════════════════╗");
        console.log(`║  Pairing Code:  ${msg.code}              ║`);
        console.log(`║  Expires: ${new Date(msg.expiresAt).toLocaleTimeString().padEnd(26)}║`);
        console.log("╠══════════════════════════════════════╣");
        console.log(`║  Preset:  ${PRESET.padEnd(26)}║`);
        console.log(`║  Agents:  ${String(AGENTS.length).padEnd(26)}║`);
        console.log(`║  Mode:    ${MODE.padEnd(26)}║`);
        console.log("╚══════════════════════════════════════╝");
        console.log("");
        break;

      case "app.paired":
      case "app.connected":
        console.log(`[mock] Device ${msg.type}`);
        broadcastStatus();
        break;

      case "status.request":
        broadcastStatus();
        break;

      case "message.inbound":
        handleInbound(engineConfig, msg);
        break;

      case "typing":
        break;

      case "error":
        console.error(`[mock] Error: ${msg.message}`);
        break;
    }
  });

  ws.addEventListener("close", (event) => {
    console.log(`[mock] Disconnected (code=${event.code}), reconnecting in 3s...`);
    setTimeout(connect, 3000);
  });

  ws.addEventListener("error", () => {
    console.error("[mock] Connection error");
  });
}

// ---------------------------------------------------------------------------
// Banner
// ---------------------------------------------------------------------------

console.log("╔══════════════════════════════════════╗");
console.log("║      ClawChat Mock Engine            ║");
console.log("╚══════════════════════════════════════╝");
console.log("");
console.log(`  Relay:       ${RELAY_URL}`);
console.log(`  Preset:      ${PRESET} (${AGENTS.length} agents)`);
console.log(`  Mode:        ${MODE}`);
console.log(`  Delay:       ${BASE_DELAY}ms typing, ${CHUNK_DELAY}ms chunk`);
console.log("");
console.log("  Agents:");
for (const a of AGENTS) {
  console.log(`    • ${a.name} (${a.id}) — ${a.model}`);
}
console.log("");
console.log("  Keywords (auto mode):");
console.log("    推理/分析/think → reasoning    工具/搜索/文件 → tools");
console.log("    详细/架构/long  → long         错误/error    → error");
console.log("    echo/回声       → echo         安静/silent   → silent");
console.log("");

connect();

process.on("SIGINT", () => {
  console.log("\n[mock] Shutting down...");
  ws?.close();
  process.exit(0);
});
