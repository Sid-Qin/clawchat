import { Hono } from "hono";
import type { DbStore } from "../db.js";
import { stats } from "../connections.js";
import { generatePairingCode } from "../util.js";
import { log } from "../log.js";
import { checkRateLimit } from "../rate-limit.js";

// ---------------------------------------------------------------------------
// HTTP routes (mounted on Hono)
// ---------------------------------------------------------------------------

export function createHttpRoutes(db: DbStore): Hono {
  const app = new Hono();

  // Rate limit middleware: 30 requests per minute per IP (skip health check)
  app.use("*", async (c, next) => {
    if (c.req.path === "/health") return next();
    const ip = c.req.header("x-forwarded-for")?.split(",")[0]?.trim() || "unknown";
    const rl = checkRateLimit(`http:${ip}`, 30, 60_000);
    if (!rl.allowed) {
      log("warn", "rate_limit.http", { ip });
      return c.json({ error: "Too many requests" }, 429);
    }
    return next();
  });

  // Health check
  app.get("/health", (c) => {
    return c.json({
      status: "ok",
      connections: stats(),
    });
  });

  // Generate pairing code via HTTP (auth: Bearer gateway-token)
  app.post("/api/pair/code", (c) => {
    const auth = c.req.header("Authorization");
    if (!auth?.startsWith("Bearer ")) {
      return c.json({ error: "Missing or invalid Authorization header" }, 401);
    }

    const token = auth.slice(7);
    const gateway = db.findGateway(token);
    if (!gateway) {
      return c.json({ error: "Unknown gateway token" }, 403);
    }

    const code = generatePairingCode();
    const expiresAt = Date.now() + 5 * 60 * 1000; // 5 minutes

    db.createPairingCode(code, gateway.gatewayId, expiresAt);

    const displayCode = `${code.slice(0, 3)}-${code.slice(3)}`;

    log("info", "http.pair.generate", { gatewayId: gateway.gatewayId, code: displayCode });

    return c.json({
      code: displayCode,
      expiresAt: new Date(expiresAt).toISOString(),
    });
  });

  return app;
}
