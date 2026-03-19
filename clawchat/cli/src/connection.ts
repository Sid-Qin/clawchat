import type { BaseMessage } from "@clawchat/protocol";

const MAX_BACKOFF_MS = 60_000;
const PING_INTERVAL_MS = 30_000;
const PONG_TIMEOUT_MS = 10_000;

export interface Connection {
  ws: WebSocket;
  close(): void;
}

/**
 * Send a typed protocol message over the WebSocket.
 */
export function send(ws: WebSocket, message: BaseMessage): void {
  if (ws.readyState === WebSocket.OPEN) {
    ws.send(JSON.stringify(message));
  }
}

/**
 * Connect to the relay WebSocket with automatic reconnection and ping tracking.
 */
export function connect(
  relayUrl: string,
  onMessage: (msg: BaseMessage) => void,
  onOpen: () => void,
  onClose: () => void,
): Connection {
  let attempt = 0;
  let closed = false;
  let currentWs: WebSocket;
  let pingTimer: ReturnType<typeof setInterval> | null = null;
  let pongTimer: ReturnType<typeof setTimeout> | null = null;

  function clearTimers(): void {
    if (pingTimer) {
      clearInterval(pingTimer);
      pingTimer = null;
    }
    if (pongTimer) {
      clearTimeout(pongTimer);
      pongTimer = null;
    }
  }

  function createWs(): WebSocket {
    const ws = new WebSocket(relayUrl);

    ws.addEventListener("open", () => {
      attempt = 0;
      onOpen();

      // Start ping interval
      pingTimer = setInterval(() => {
        if (ws.readyState === WebSocket.OPEN) {
          // Send a protocol-level ping (plain text frame)
          ws.send(JSON.stringify({ type: "ping", id: crypto.randomUUID(), ts: Date.now() }));
          pongTimer = setTimeout(() => {
            // No pong received — force reconnect
            ws.close();
          }, PONG_TIMEOUT_MS);
        }
      }, PING_INTERVAL_MS);
    });

    ws.addEventListener("message", (event) => {
      try {
        const data = typeof event.data === "string" ? event.data : String(event.data);
        const msg = JSON.parse(data) as BaseMessage;
        // Clear pong timer on any incoming message (acts as implicit pong)
        if (pongTimer) {
          clearTimeout(pongTimer);
          pongTimer = null;
        }
        if (msg.type === "pong") return; // swallow pong frames
        onMessage(msg);
      } catch {
        // Ignore unparseable frames
      }
    });

    ws.addEventListener("close", () => {
      clearTimers();
      if (closed) return;
      onClose();
      scheduleReconnect();
    });

    ws.addEventListener("error", () => {
      // error is always followed by close, so reconnect happens there
    });

    currentWs = ws;
    return ws;
  }

  function scheduleReconnect(): void {
    if (closed) return;
    const delayMs = Math.min(1000 * 2 ** attempt, MAX_BACKOFF_MS);
    attempt++;
    setTimeout(() => {
      if (!closed) createWs();
    }, delayMs);
  }

  const ws = createWs();

  return {
    ws,
    close() {
      closed = true;
      clearTimers();
      if (currentWs.readyState === WebSocket.OPEN || currentWs.readyState === WebSocket.CONNECTING) {
        currentWs.close();
      }
    },
  };
}
