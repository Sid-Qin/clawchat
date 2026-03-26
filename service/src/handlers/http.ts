import { Hono } from "hono";
import { cors } from "hono/cors";
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

  app.use("*", cors());

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

  // List paired devices (auth: Bearer gateway-token)
  app.get("/api/devices", (c) => {
    const auth = c.req.header("Authorization");
    if (!auth?.startsWith("Bearer ")) {
      return c.json({ error: "Missing or invalid Authorization header" }, 401);
    }

    const token = auth.slice(7);
    const gateway = db.findGateway(token);
    if (!gateway) {
      return c.json({ error: "Unknown gateway token" }, 403);
    }

    const devices = db.listDevicesByGateway(gateway.gatewayId);
    return c.json({ gatewayId: gateway.gatewayId, devices });
  });

  // Revoke a device (auth: Bearer gateway-token)
  app.delete("/api/devices/:deviceId", (c) => {
    const auth = c.req.header("Authorization");
    if (!auth?.startsWith("Bearer ")) {
      return c.json({ error: "Missing or invalid Authorization header" }, 401);
    }

    const token = auth.slice(7);
    const gateway = db.findGateway(token);
    if (!gateway) {
      return c.json({ error: "Unknown gateway token" }, 403);
    }

    const deviceId = c.req.param("deviceId");
    const deleted = db.revokeDevice(deviceId);
    if (!deleted) {
      return c.json({ error: "Device not found" }, 404);
    }

    log("info", "http.device.revoke", { deviceId, gatewayId: gateway.gatewayId });
    return c.json({ ok: true });
  });

  // Revoke all devices for a gateway (auth: Bearer gateway-token)
  app.delete("/api/devices", (c) => {
    const auth = c.req.header("Authorization");
    if (!auth?.startsWith("Bearer ")) {
      return c.json({ error: "Missing or invalid Authorization header" }, 401);
    }

    const token = auth.slice(7);
    const gateway = db.findGateway(token);
    if (!gateway) {
      return c.json({ error: "Unknown gateway token" }, 403);
    }

    const devices = db.listDevicesByGateway(gateway.gatewayId);
    for (const device of devices) {
      db.revokeDevice(device.deviceId);
    }

    log("info", "http.devices.revoke_all", { gatewayId: gateway.gatewayId, count: devices.length });
    return c.json({ ok: true, revoked: devices.length });
  });

  return app;
}
