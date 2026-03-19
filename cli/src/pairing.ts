import type {
  AppPair,
  AppPaired,
  AppPairError,
  AppConnect,
  AppConnected,
  BaseMessage,
} from "@clawchat/protocol";
import { send } from "./connection.js";

const PROTOCOL_VERSION = "0.1";

/**
 * Pair with a gateway using a pairing code.
 * Returns the device token on success, or null on failure (error printed to stderr).
 */
export function pairWithCode(
  ws: WebSocket,
  code: string,
  deviceName: string,
): Promise<AppPaired | null> {
  return new Promise((resolve) => {
    const pairMsg: AppPair = {
      type: "app.pair",
      id: crypto.randomUUID(),
      ts: Date.now(),
      pairingCode: code,
      deviceName,
      platform: "cli",
      protocolVersion: PROTOCOL_VERSION,
    };
    send(ws, pairMsg);

    function handler(event: MessageEvent): void {
      try {
        const msg = JSON.parse(String(event.data)) as BaseMessage;
        if (msg.type === "app.paired") {
          ws.removeEventListener("message", handler);
          resolve(msg as AppPaired);
        } else if (msg.type === "app.pair.error") {
          ws.removeEventListener("message", handler);
          const err = msg as AppPairError;
          process.stderr.write(`\x1b[31mPairing failed: ${err.message} (${err.error})\x1b[0m\n`);
          resolve(null);
        }
      } catch {
        // ignore
      }
    }

    ws.addEventListener("message", handler);
  });
}

/**
 * Reconnect to the relay using a stored device token.
 * Returns the connection info on success, or null on failure.
 */
export function reconnectWithToken(
  ws: WebSocket,
  deviceToken: string,
): Promise<AppConnected | null> {
  return new Promise((resolve) => {
    const connectMsg: AppConnect = {
      type: "app.connect",
      id: crypto.randomUUID(),
      ts: Date.now(),
      deviceToken,
      protocolVersion: PROTOCOL_VERSION,
    };
    send(ws, connectMsg);

    function handler(event: MessageEvent): void {
      try {
        const msg = JSON.parse(String(event.data)) as BaseMessage;
        if (msg.type === "app.connected") {
          ws.removeEventListener("message", handler);
          resolve(msg as AppConnected);
        } else if (msg.type === "error") {
          ws.removeEventListener("message", handler);
          const err = msg as BaseMessage & { message?: string };
          process.stderr.write(
            `\x1b[31mConnection failed: ${(err as any).message ?? "unknown error"}\x1b[0m\n`,
          );
          resolve(null);
        }
      } catch {
        // ignore
      }
    }

    ws.addEventListener("message", handler);
  });
}
