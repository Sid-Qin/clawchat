import { describe, it, expect, mock, beforeEach } from "bun:test";
import { trackSocket, untrackSocket, handlePong } from "./keepalive.js";

// Minimal mock for ServerWebSocket
function createMockSocket(kind: "gateway" | "app" = "gateway") {
  return {
    data: { kind, gatewayId: "gw-1", deviceId: "dev-1" },
    ping: mock(() => {}),
    close: mock(() => {}),
    send: mock(() => {}),
  } as any;
}

describe("keepalive", () => {
  it("trackSocket and untrackSocket manage socket set", () => {
    const ws = createMockSocket();
    // Should not throw
    trackSocket(ws);
    untrackSocket(ws);
  });

  it("handlePong clears timeout for tracked socket", () => {
    const ws = createMockSocket();
    trackSocket(ws);
    // handlePong should not throw even without pending pong
    handlePong(ws);
    untrackSocket(ws);
  });

  it("untrackSocket is idempotent", () => {
    const ws = createMockSocket();
    untrackSocket(ws);
    untrackSocket(ws);
    // Should not throw
  });
});
