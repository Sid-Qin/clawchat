#!/usr/bin/env bun
const RELAY_URL = "ws://127.0.0.1:8787/ws/gateway";
const GATEWAY_ID = "local-gw-" + crypto.randomUUID().slice(0, 8);
const GATEWAY_TOKEN = crypto.randomUUID();

const AGENT_DESCRIPTOR = "main::Ayanami Rei::yescode/claude-sonnet-4-6::yescode/claude-sonnet-4-6|yescode/claude-opus-4-6";

const ws = new WebSocket(RELAY_URL);

ws.addEventListener("open", () => {
  console.log("Connected to relay. Registering gateway...");
  ws.send(JSON.stringify({
    type: "gateway.register",
    id: crypto.randomUUID(),
    ts: Date.now(),
    gatewayId: GATEWAY_ID,
    token: GATEWAY_TOKEN,
    agents: [AGENT_DESCRIPTOR],
    version: "2026.3.13",
  }));
});

ws.addEventListener("message", (event) => {
  const msg = JSON.parse(String(event.data));
  console.log("[recv]", msg.type, JSON.stringify(msg).slice(0, 200));

  if (msg.type === "gateway.registered") {
    console.log("Gateway registered:", msg.gatewayId, "devices:", msg.pairedDevices);
    if (msg.pairedDevices === 0) {
      console.log("No paired devices. Generating pairing code...");
      ws.send(JSON.stringify({
        type: "pair.generate",
        id: crypto.randomUUID(),
        ts: Date.now(),
      }));
    } else {
      console.log("Device(s) already paired. Waiting for app to reconnect...");
    }
  }

  if (msg.type === "pair.code") {
    console.log("\n========================================");
    console.log(`  Relay URL: ws://192.168.0.105:8787`);
    console.log(`  Pairing Code: ${msg.code}`);
    console.log(`  Expires: ${new Date(msg.expiresAt).toLocaleTimeString()}`);
    console.log("========================================\n");
  }

  if (msg.type === "message.inbound") {
    console.log("[chat]", msg.text || msg.content || "(no text)");
    ws.send(JSON.stringify({
      type: "message.outbound",
      id: crypto.randomUUID(),
      ts: Date.now(),
      agentId: "main",
      deviceId: msg.deviceId,
      text: `Echo: ${msg.text || msg.content || ""}`,
      sessionId: msg.sessionId,
      done: true,
    }));
  }

  if (msg.type === "error") {
    console.error("[error]", msg.message);
  }
});

ws.addEventListener("close", () => {
  console.log("Connection closed");
});

process.on("SIGINT", () => {
  ws.close();
  process.exit(0);
});
