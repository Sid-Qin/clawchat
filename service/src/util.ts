import type { ServerWebSocket } from "bun";
import type { WsData } from "./connections.js";

// ---------------------------------------------------------------------------
// Pairing code generation
// ---------------------------------------------------------------------------

/** Charset: 2-9, A-H, J-K, M, N, P-Z (30 chars, no ambiguous 0/O/1/I/L) */
const PAIRING_CHARSET = "23456789ABCDEFGHJKMNPQRSTUVWXYZ";
const CODE_LENGTH = 6;

/**
 * Generate a random 6-character pairing code.
 * Returns the raw code (no hyphen). Display formatting is done elsewhere.
 */
export function generatePairingCode(): string {
  const bytes = new Uint8Array(CODE_LENGTH);
  crypto.getRandomValues(bytes);
  let code = "";
  for (let i = 0; i < CODE_LENGTH; i++) {
    code += PAIRING_CHARSET[bytes[i]! % PAIRING_CHARSET.length];
  }
  return code;
}

// ---------------------------------------------------------------------------
// Send helper
// ---------------------------------------------------------------------------

/**
 * Serialize and send a JSON message over a WebSocket.
 */
export function send(ws: ServerWebSocket<WsData>, msg: Record<string, unknown>): void {
  ws.send(JSON.stringify(msg));
}
