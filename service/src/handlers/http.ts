import { Hono } from "hono";
import type { DbStore } from "../db.js";
import { stats } from "../connections.js";
import { generatePairingCode } from "../util.js";

// ---------------------------------------------------------------------------
// HTTP routes (mounted on Hono)
// ---------------------------------------------------------------------------

export function createHttpRoutes(db: DbStore): Hono {
  const app = new Hono();

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

    console.log(`[http] pairing code generated for ${gateway.gatewayId}: ${displayCode}`);

    return c.json({
      code: displayCode,
      expiresAt: new Date(expiresAt).toISOString(),
    });
  });

  return app;
}
