import { Hono } from "hono";
import { createDb } from "./db.js";
import { createHttpRoutes } from "./handlers/http.js";
import { handleGatewayMessage, handleGatewayClose } from "./handlers/gateway.js";
import { handleAppMessage, handleAppClose } from "./handlers/app.js";
import type { WsData } from "./connections.js";
import { trackIpConnection, releaseIpConnection } from "./connections.js";
import { trackSocket, untrackSocket, handlePong, startKeepaliveLoop } from "./keepalive.js";
import { log } from "./log.js";
import { checkRateLimit, cleanupRateLimits } from "./rate-limit.js";

// ---------------------------------------------------------------------------
// Configuration
// ---------------------------------------------------------------------------

const PORT = Number(process.env.PORT) || 8787;
const DB_PATH = process.env.DB_PATH || "clawchat.db";

// ---------------------------------------------------------------------------
// Database
// ---------------------------------------------------------------------------

const db = createDb(DB_PATH);

// Periodic cleanup (every 60 seconds)
setInterval(() => {
  const cleanedCodes = db.cleanExpiredCodes();
  const cleanedRateLimits = cleanupRateLimits(60_000);
  if (cleanedCodes > 0 || cleanedRateLimits > 0) {
    log("debug", "db.cleanup", { cleanedCodes, cleanedRateLimits });
  }
}, 60 * 1000);

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
    const ip = req.headers.get("x-forwarded-for")?.split(",")[0]?.trim() || "unknown";

    // WebSocket connection rate limit: 10/min per IP + max 20 concurrent per IP
    if (url.pathname === "/ws/gateway" || url.pathname === "/ws/app") {
      const rl = checkRateLimit(`wsconn:${ip}`, 10, 60_000);
      if (!rl.allowed) {
        log("warn", "rate_limit.ws_connect", { ip });
        return new Response("Too Many Requests", { status: 429 });
      }
      if (!trackIpConnection(ip)) {
        log("warn", "connection_limit.ip", { ip });
        return new Response("Too Many Requests", { status: 429 });
      }
    }

    // WebSocket upgrade for gateway connections
    if (url.pathname === "/ws/gateway") {
      const upgraded = server.upgrade(req, {
        data: { kind: "gateway" as const, gatewayId: "", agents: [], ip },
      });
      if (upgraded) return undefined;
      releaseIpConnection(ip);
      return new Response("WebSocket upgrade failed", { status: 400 });
    }

    // WebSocket upgrade for app connections
    if (url.pathname === "/ws/app") {
      const upgraded = server.upgrade(req, {
        data: { kind: "app" as const, deviceId: "", gatewayId: "", ip },
      });
      if (upgraded) return undefined;
      releaseIpConnection(ip);
      return new Response("WebSocket upgrade failed", { status: 400 });
    }

    // Fall through to Hono for HTTP routes
    return app.fetch(req);
  },

  websocket: {
    open(ws) {
      const { kind } = ws.data;
      log("debug", "ws.open", { kind });
      trackSocket(ws);
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
      log("debug", "ws.close", { kind, code, reason });
      untrackSocket(ws);
      releaseIpConnection(ws.data.ip);

      if (kind === "gateway") {
        handleGatewayClose(ws);
      } else {
        handleAppClose(ws);
      }
    },

    pong(ws) {
      handlePong(ws);
    },

  },
});

// Start WebSocket keepalive ping loop (30s interval, 10s pong timeout)
startKeepaliveLoop();

log("info", "server.start", { port: server.port });
