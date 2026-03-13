import { Hono } from "hono";
import { createDb } from "./db.js";
import { createHttpRoutes } from "./handlers/http.js";
import { handleGatewayMessage, handleGatewayClose } from "./handlers/gateway.js";
import { handleAppMessage, handleAppClose } from "./handlers/app.js";
import type { WsData } from "./connections.js";

// ---------------------------------------------------------------------------
// Configuration
// ---------------------------------------------------------------------------

const PORT = Number(process.env.PORT) || 8787;
const DB_PATH = process.env.DB_PATH || "clawchat.db";

// ---------------------------------------------------------------------------
// Database
// ---------------------------------------------------------------------------

const db = createDb(DB_PATH);

// Clean expired pairing codes periodically (every 10 minutes)
setInterval(() => {
  const cleaned = db.cleanExpiredCodes();
  if (cleaned > 0) {
    console.log(`[db] cleaned ${cleaned} expired pairing codes`);
  }
}, 10 * 60 * 1000);

// ---------------------------------------------------------------------------
// HTTP (Hono)
// ---------------------------------------------------------------------------

const httpRoutes = createHttpRoutes(db);

const app = new Hono();
app.route("/", httpRoutes);

// ---------------------------------------------------------------------------
// Bun.serve — HTTP + WebSocket
// ---------------------------------------------------------------------------

const server = Bun.serve<WsData>({
  port: PORT,

  fetch(req, server) {
    const url = new URL(req.url);

    // WebSocket upgrade for gateway connections
    if (url.pathname === "/ws/gateway") {
      const upgraded = server.upgrade(req, {
        data: { kind: "gateway" as const, gatewayId: "", agents: [] },
      });
      if (upgraded) return undefined;
      return new Response("WebSocket upgrade failed", { status: 400 });
    }

    // WebSocket upgrade for app connections
    if (url.pathname === "/ws/app") {
      const upgraded = server.upgrade(req, {
        data: { kind: "app" as const, deviceId: "", gatewayId: "" },
      });
      if (upgraded) return undefined;
      return new Response("WebSocket upgrade failed", { status: 400 });
    }

    // Fall through to Hono for HTTP routes
    return app.fetch(req);
  },

  websocket: {
    open(ws) {
      const { kind } = ws.data;
      console.log(`[ws] ${kind} socket opened`);
    },

    message(ws, message) {
      const raw = typeof message === "string" ? message : new TextDecoder().decode(message);
      const { kind } = ws.data;

      if (kind === "gateway") {
        handleGatewayMessage(ws, raw, db);
      } else {
        handleAppMessage(ws, raw, db);
      }
    },

    close(ws, code, reason) {
      const { kind } = ws.data;
      console.log(`[ws] ${kind} socket closed (code=${code} reason=${reason})`);

      if (kind === "gateway") {
        handleGatewayClose(ws);
      } else {
        handleAppClose(ws);
      }
    },

  },
});

console.log(`[clawchat] relay service listening on http://localhost:${server.port}`);
