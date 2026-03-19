/**
 * Mock gateway — connects to relay, registers, generates pairing code, and echoes messages.
 * Usage: bun scripts/mock-gateway.ts [relay-url]
 * Default relay: wss://clawchat-production-db31.up.railway.app
 */

const RELAY = process.argv[2] || "wss://clawchat-production-db31.up.railway.app";
const GATEWAY_ID = "mock-gateway";
const TOKEN = "mock-token-" + Date.now();

console.log(`Connecting to ${RELAY}/ws/gateway ...`);

const ws = new WebSocket(`${RELAY}/ws/gateway`);

ws.addEventListener("open", () => {
  console.log("Connected. Registering gateway...");
  ws.send(JSON.stringify({
    type: "gateway.register",
    id: crypto.randomUUID(),
    ts: Date.now(),
    token: TOKEN,
    gatewayId: GATEWAY_ID,
    protocolVersion: "0.1.0",
    version: "2026.3.13",
    agents: ["default"],
  }));
});

ws.addEventListener("message", (event) => {
  const msg = JSON.parse(event.data as string);

  switch (msg.type) {
    case "gateway.registered":
      console.log(`Registered! Paired devices: ${msg.pairedDevices}`);
      console.log("Generating pairing code...");
      ws.send(JSON.stringify({
        type: "pair.generate",
        id: crypto.randomUUID(),
        ts: Date.now(),
      }));
      break;

    case "pair.code":
      console.log(`\n========================================`);
      console.log(`  Pairing Code:  ${msg.code}`);
      console.log(`  Expires: ${new Date(msg.expiresAt).toLocaleTimeString()}`);
      console.log(`========================================\n`);
      console.log("Waiting for messages from app...\n");
      break;

    case "message.inbound":
      console.log(`[user] ${msg.text}`);
      // Echo back as a streaming response
      const replyId = crypto.randomUUID();
      const reply = `You said: "${msg.text}" — I'm a mock gateway, not a real AI!`;
      const words = reply.split(" ");

      for (let i = 0; i < words.length; i++) {
        const delta = (i === 0 ? "" : " ") + words[i];
        ws.send(JSON.stringify({
          type: "message.stream",
          id: replyId,
          ts: Date.now(),
          agentId: "default",
          delta,
          phase: "streaming",
        }));
      }
      ws.send(JSON.stringify({
        type: "message.stream",
        id: replyId,
        ts: Date.now(),
        delta: "",
        phase: "done",
        finalText: reply,
      }));
      console.log(`[reply] ${reply}`);
      break;

    case "typing":
      console.log(`[typing] active=${msg.active}`);
      break;

    default:
      console.log(`[${msg.type}]`, JSON.stringify(msg).slice(0, 200));
  }
});

ws.addEventListener("close", (event) => {
  console.log(`Disconnected (code=${event.code})`);
  process.exit(0);
});

ws.addEventListener("error", (event) => {
  console.error("WebSocket error:", event);
});

// Keep alive
process.on("SIGINT", () => {
  console.log("\nClosing...");
  ws.close();
});
