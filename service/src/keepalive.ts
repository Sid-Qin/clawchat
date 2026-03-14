import type { ServerWebSocket } from "bun";
import type { WsData } from "./connections.js";
import { handleGatewayClose } from "./handlers/gateway.js";
import { handleAppClose } from "./handlers/app.js";
import { log } from "./log.js";

// ---------------------------------------------------------------------------
// WebSocket ping/pong keepalive
// ---------------------------------------------------------------------------

const PING_INTERVAL_MS = 30_000;
const PONG_TIMEOUT_MS = 10_000;

/** Tracks which sockets are awaiting a pong response */
const pendingPongs = new Map<ServerWebSocket<WsData>, ReturnType<typeof setTimeout>>();

/** All tracked sockets for keepalive */
const trackedSockets = new Set<ServerWebSocket<WsData>>();

/**
 * Start tracking a WebSocket for keepalive pings.
 */
export function trackSocket(ws: ServerWebSocket<WsData>): void {
  trackedSockets.add(ws);
}

/**
 * Stop tracking a WebSocket (called on close).
 */
export function untrackSocket(ws: ServerWebSocket<WsData>): void {
  trackedSockets.delete(ws);
  const timer = pendingPongs.get(ws);
  if (timer) {
    clearTimeout(timer);
    pendingPongs.delete(ws);
  }
}

/**
 * Handle a pong response — clear the timeout for this socket.
 */
export function handlePong(ws: ServerWebSocket<WsData>): void {
  const timer = pendingPongs.get(ws);
  if (timer) {
    clearTimeout(timer);
    pendingPongs.delete(ws);
  }
}

/**
 * Start the periodic ping loop. Call once at server startup.
 */
export function startKeepaliveLoop(): ReturnType<typeof setInterval> {
  return setInterval(() => {
    for (const ws of trackedSockets) {
      // Skip if already waiting for a pong
      if (pendingPongs.has(ws)) continue;

      try {
        ws.ping();
      } catch {
        // Socket already dead
        handleDeadSocket(ws);
        continue;
      }

      // Set pong timeout
      const timer = setTimeout(() => {
        pendingPongs.delete(ws);
        handleDeadSocket(ws);
      }, PONG_TIMEOUT_MS);

      pendingPongs.set(ws, timer);
    }
  }, PING_INTERVAL_MS);
}

/**
 * Handle a dead socket — close it and trigger cleanup.
 */
function handleDeadSocket(ws: ServerWebSocket<WsData>): void {
  const { kind } = ws.data;
  log("info", "keepalive.timeout", { kind });

  untrackSocket(ws);

  try {
    ws.close(1001, "pong timeout");
  } catch {
    // Already closed
  }

  if (kind === "gateway") {
    handleGatewayClose(ws);
  } else {
    handleAppClose(ws);
  }
}
