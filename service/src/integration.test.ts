import { describe, it, expect, beforeAll, afterAll, beforeEach, afterEach } from "bun:test";
import { createDb, type DbStore } from "./db.js";
import { randomUUID } from "crypto";

/**
 * Integration tests for relay service flows.
 *
 * These tests start a local relay server and test the full WebSocket flow:
 * pairing, messaging, reconnection, error cases, and keepalive.
 *
 * Run with: CLAWCHAT_INTEGRATION=1 bun test src/integration.test.ts
 */

const SKIP = !process.env.CLAWCHAT_INTEGRATION;

describe.skipIf(SKIP)("Integration: full relay flow", () => {
  let serverProcess: ReturnType<typeof Bun.spawn>;
  let port: number;
  let db: DbStore;

  beforeAll(async () => {
    // Start relay on a random port
    port = 9000 + Math.floor(Math.random() * 1000);
    const dbPath = `/tmp/clawchat-test-${randomUUID()}.db`;
    db = createDb(dbPath);

    serverProcess = Bun.spawn(["bun", "src/index.ts"], {
      cwd: import.meta.dir + "/..",
      env: { ...process.env, PORT: String(port), DB_PATH: dbPath },
      stdout: "pipe",
      stderr: "pipe",
    });

    // Wait for server to start
    await new Promise(resolve => setTimeout(resolve, 1000));
  });

  afterAll(() => {
    serverProcess?.kill();
  });

  function wsUrl(path: string): string {
    return `ws://localhost:${port}${path}`;
  }

  async function connectGateway(): Promise<{ ws: WebSocket; gatewayId: string; token: string }> {
    const gatewayId = `test-gw-${randomUUID().slice(0, 8)}`;
    const token = randomUUID();

    return new Promise((resolve, reject) => {
      const ws = new WebSocket(wsUrl("/ws/gateway"));
      ws.onopen = () => {
        ws.send(JSON.stringify({
          type: "gateway.register",
          id: randomUUID(),
          ts: Date.now(),
          gatewayId,
          token,
          agents: ["default"],
        }));
        // Give it a moment to register
        setTimeout(() => resolve({ ws, gatewayId, token }), 200);
      };
      ws.onerror = reject;
    });
  }

  async function generatePairCode(gwWs: WebSocket): Promise<string> {
    return new Promise((resolve) => {
      const handler = (event: MessageEvent) => {
        const msg = JSON.parse(event.data);
        if (msg.type === "pair.code") {
          gwWs.removeEventListener("message", handler);
          resolve(msg.code);
        }
      };
      gwWs.addEventListener("message", handler);

      gwWs.send(JSON.stringify({
        type: "pair.generate",
        id: randomUUID(),
        ts: Date.now(),
      }));
    });
  }

  it("7.1: pair → send message → receive stream → disconnect → reconnect", async () => {
    // Connect gateway
    const { ws: gwWs, gatewayId } = await connectGateway();

    // Generate pairing code
    const code = await generatePairCode(gwWs);
    expect(code).toBeTruthy();
    expect(code.length).toBe(7); // XXX-XXX format

    // Connect app and pair
    const appWs = new WebSocket(wsUrl("/ws/app"));
    const paired = await new Promise<any>((resolve, reject) => {
      appWs.onopen = () => {
        appWs.send(JSON.stringify({
          type: "app.pair",
          id: randomUUID(),
          ts: Date.now(),
          pairingCode: code,
          deviceName: "Test iPhone",
          platform: "ios",
          protocolVersion: "0.1",
        }));
      };
      appWs.onmessage = (event) => {
        const msg = JSON.parse(event.data);
        if (msg.type === "app.paired") resolve(msg);
        if (msg.type === "app.pair.error") reject(new Error(msg.message));
      };
      appWs.onerror = reject;
    });

    expect(paired.deviceToken).toBeTruthy();
    expect(paired.gatewayId).toBe(gatewayId);

    // Send message from app and verify gateway receives it
    const messageReceived = new Promise<any>((resolve) => {
      gwWs.addEventListener("message", (event) => {
        const msg = JSON.parse(event.data as string);
        if (msg.type === "message.inbound") resolve(msg);
      });
    });

    appWs.send(JSON.stringify({
      type: "message.inbound",
      id: randomUUID(),
      ts: Date.now(),
      text: "hello from test",
      agentId: "default",
    }));

    const inbound = await messageReceived;
    expect(inbound.text).toBe("hello from test");

    // Gateway sends stream back to app
    const streamReceived = new Promise<any>((resolve) => {
      appWs.addEventListener("message", (event) => {
        const msg = JSON.parse(event.data as string);
        if (msg.type === "message.stream") resolve(msg);
      });
    });

    gwWs.send(JSON.stringify({
      type: "message.stream",
      id: randomUUID(),
      ts: Date.now(),
      agentId: "default",
      delta: "hello back",
      phase: "done",
      finalText: "hello back",
    }));

    const stream = await streamReceived;
    expect(stream.delta).toBe("hello back");

    // Disconnect app
    const deviceToken = paired.deviceToken;
    appWs.close();
    await new Promise(resolve => setTimeout(resolve, 200));

    // Reconnect with device token
    const appWs2 = new WebSocket(wsUrl("/ws/app"));
    const connected = await new Promise<any>((resolve, reject) => {
      appWs2.onopen = () => {
        appWs2.send(JSON.stringify({
          type: "app.connect",
          id: randomUUID(),
          ts: Date.now(),
          deviceToken,
          protocolVersion: "0.1",
        }));
      };
      appWs2.onmessage = (event) => {
        const msg = JSON.parse(event.data);
        if (msg.type === "app.connected") resolve(msg);
        if (msg.type === "error") reject(new Error(msg.message));
      };
      appWs2.onerror = reject;
    });

    expect(connected.gatewayId).toBe(gatewayId);
    expect(connected.gatewayOnline).toBe(true);

    // Cleanup
    appWs2.close();
    gwWs.close();
  });

  it("7.2: invalid pairing code returns error", async () => {
    const { ws: gwWs } = await connectGateway();

    const appWs = new WebSocket(wsUrl("/ws/app"));
    const error = await new Promise<any>((resolve, reject) => {
      appWs.onopen = () => {
        appWs.send(JSON.stringify({
          type: "app.pair",
          id: randomUUID(),
          ts: Date.now(),
          pairingCode: "INVALID",
          deviceName: "Test",
          platform: "ios",
          protocolVersion: "0.1",
        }));
      };
      appWs.onmessage = (event) => {
        const msg = JSON.parse(event.data);
        if (msg.type === "app.pair.error") resolve(msg);
        if (msg.type === "app.paired") reject(new Error("Should not have paired"));
      };
      appWs.onerror = reject;
    });

    expect(error.error).toBe("invalid_code");

    appWs.close();
    gwWs.close();
  });

  it("7.3: reconnect with bad token returns unauthorized", async () => {
    const appWs = new WebSocket(wsUrl("/ws/app"));
    const error = await new Promise<any>((resolve, reject) => {
      appWs.onopen = () => {
        appWs.send(JSON.stringify({
          type: "app.connect",
          id: randomUUID(),
          ts: Date.now(),
          deviceToken: "bad-token-" + randomUUID(),
          protocolVersion: "0.1",
        }));
      };
      appWs.onmessage = (event) => {
        const msg = JSON.parse(event.data);
        if (msg.type === "error") resolve(msg);
        if (msg.type === "app.connected") reject(new Error("Should not connect"));
      };
      appWs.onerror = reject;
    });

    expect(error.code).toBe("unauthorized");
  });

  async function pairApp(gwWs: WebSocket): Promise<{ ws: WebSocket; deviceToken: string; gatewayId: string }> {
    const code = await generatePairCode(gwWs);
    const appWs = new WebSocket(wsUrl("/ws/app"));
    const paired = await new Promise<any>((resolve, reject) => {
      appWs.onopen = () => {
        appWs.send(JSON.stringify({
          type: "app.pair",
          id: randomUUID(),
          ts: Date.now(),
          pairingCode: code,
          deviceName: "Test Device",
          platform: "ios",
          protocolVersion: "0.1",
        }));
      };
      appWs.onmessage = (event) => {
        const msg = JSON.parse(event.data);
        if (msg.type === "app.paired") resolve(msg);
        if (msg.type === "app.pair.error") reject(new Error(msg.message));
      };
      appWs.onerror = reject;
    });
    return { ws: appWs, deviceToken: paired.deviceToken, gatewayId: paired.gatewayId };
  }

  it("7.4: gateway offline detected via presence", async () => {
    const { ws: gwWs, gatewayId } = await connectGateway();
    const code = await generatePairCode(gwWs);

    // Pair app
    const appWs = new WebSocket(wsUrl("/ws/app"));
    await new Promise<any>((resolve) => {
      appWs.onopen = () => {
        appWs.send(JSON.stringify({
          type: "app.pair",
          id: randomUUID(),
          ts: Date.now(),
          pairingCode: code,
          deviceName: "Test",
          platform: "ios",
          protocolVersion: "0.1",
        }));
      };
      appWs.onmessage = (event) => {
        const msg = JSON.parse(event.data);
        if (msg.type === "app.paired") resolve(msg);
      };
    });

    // Listen for presence offline
    const presenceOffline = new Promise<any>((resolve) => {
      appWs.addEventListener("message", (event) => {
        const msg = JSON.parse(event.data as string);
        if (msg.type === "presence" && msg.online === false) resolve(msg);
      });
    });

    // Gateway disconnects
    gwWs.close();

    const presence = await presenceOffline;
    expect(presence.online).toBe(false);

    appWs.close();
  });

  // ---------------------------------------------------------------------------
  // Relay hardening integration tests
  // ---------------------------------------------------------------------------

  it("hardening 7.1: rate-limited app message returns error", async () => {
    const { ws: gwWs } = await connectGateway();
    const { ws: appWs } = await pairApp(gwWs);

    // Send 61 messages rapidly (limit is 60/min per device)
    const messages: any[] = [];
    const collectMessages = (event: MessageEvent) => {
      messages.push(JSON.parse(event.data));
    };
    appWs.addEventListener("message", collectMessages);

    for (let i = 0; i < 61; i++) {
      appWs.send(JSON.stringify({
        type: "message.inbound",
        id: randomUUID(),
        ts: Date.now(),
        text: `msg-${i}`,
        agentId: "default",
      }));
    }

    // Wait for responses to arrive
    await new Promise(resolve => setTimeout(resolve, 500));

    const rateLimitError = messages.find(
      m => m.type === "error" && m.code === "rate_limited"
    );
    expect(rateLimitError).toBeTruthy();

    appWs.close();
    gwWs.close();
  });

  it("hardening 7.2: gateway token mismatch rejected on re-registration", async () => {
    const { ws: gwWs, gatewayId, token } = await connectGateway();
    gwWs.close();
    await new Promise(resolve => setTimeout(resolve, 200));

    // Re-register same gateway with different token
    const wrongToken = randomUUID();
    const ws2 = new WebSocket(wsUrl("/ws/gateway"));
    const result = await new Promise<any>((resolve, reject) => {
      ws2.onopen = () => {
        ws2.send(JSON.stringify({
          type: "gateway.register",
          id: randomUUID(),
          ts: Date.now(),
          gatewayId,
          token: wrongToken,
          agents: ["default"],
        }));
      };
      ws2.onmessage = (event) => {
        const msg = JSON.parse(event.data);
        resolve(msg);
      };
      ws2.onerror = reject;
    });

    expect(result.type).toBe("error");
    expect(result.code).toBe("unauthorized");
  });

  it("hardening 7.3: device token rotated on reconnect", async () => {
    const { ws: gwWs } = await connectGateway();
    const { ws: appWs, deviceToken } = await pairApp(gwWs);

    // Disconnect app
    appWs.close();
    await new Promise(resolve => setTimeout(resolve, 200));

    // Reconnect
    const appWs2 = new WebSocket(wsUrl("/ws/app"));
    const connected = await new Promise<any>((resolve, reject) => {
      appWs2.onopen = () => {
        appWs2.send(JSON.stringify({
          type: "app.connect",
          id: randomUUID(),
          ts: Date.now(),
          deviceToken,
          protocolVersion: "0.1",
        }));
      };
      appWs2.onmessage = (event) => {
        const msg = JSON.parse(event.data);
        if (msg.type === "app.connected") resolve(msg);
        if (msg.type === "error") reject(new Error(msg.message));
      };
      appWs2.onerror = reject;
    });

    expect(connected.newDeviceToken).toBeTruthy();
    expect(connected.newDeviceToken).not.toBe(deviceToken);

    // Old token should no longer work
    appWs2.close();
    await new Promise(resolve => setTimeout(resolve, 200));

    const appWs3 = new WebSocket(wsUrl("/ws/app"));
    const error = await new Promise<any>((resolve, reject) => {
      appWs3.onopen = () => {
        appWs3.send(JSON.stringify({
          type: "app.connect",
          id: randomUUID(),
          ts: Date.now(),
          deviceToken, // old token
          protocolVersion: "0.1",
        }));
      };
      appWs3.onmessage = (event) => {
        const msg = JSON.parse(event.data);
        resolve(msg);
      };
      appWs3.onerror = reject;
    });

    expect(error.type).toBe("error");
    expect(error.code).toBe("unauthorized");

    gwWs.close();
  });

  it("hardening 7.4: offline messages delivered on reconnect", async () => {
    const { ws: gwWs } = await connectGateway();
    const { ws: appWs, deviceToken } = await pairApp(gwWs);

    // Disconnect app
    appWs.close();
    await new Promise(resolve => setTimeout(resolve, 200));

    // Gateway sends messages while app is offline
    gwWs.send(JSON.stringify({
      type: "message.outbound",
      id: randomUUID(),
      ts: Date.now(),
      agentId: "default",
      text: "offline-msg-1",
    }));
    gwWs.send(JSON.stringify({
      type: "message.outbound",
      id: randomUUID(),
      ts: Date.now(),
      agentId: "default",
      text: "offline-msg-2",
    }));
    // typing should NOT be queued
    gwWs.send(JSON.stringify({
      type: "typing",
      id: randomUUID(),
      ts: Date.now(),
      agentId: "default",
    }));

    await new Promise(resolve => setTimeout(resolve, 300));

    // Reconnect — should receive offline messages after app.connected
    const appWs2 = new WebSocket(wsUrl("/ws/app"));
    // Token was rotated, so we need the new token from the db
    // But we can use the original token since we never reconnected yet
    const received: any[] = [];
    const connected = await new Promise<any>((resolve, reject) => {
      appWs2.onopen = () => {
        appWs2.send(JSON.stringify({
          type: "app.connect",
          id: randomUUID(),
          ts: Date.now(),
          deviceToken,
          protocolVersion: "0.1",
        }));
      };
      appWs2.onmessage = (event) => {
        const msg = JSON.parse(event.data);
        received.push(msg);
        if (msg.type === "app.connected") {
          // Wait a bit for offline messages to arrive
          setTimeout(() => resolve(msg), 300);
        }
        if (msg.type === "error") reject(new Error(msg.message));
      };
      appWs2.onerror = reject;
    });

    expect(connected.type).toBe("app.connected");

    // Should have received the 2 offline messages (not the typing)
    const offlineMsgs = received.filter(m => m.type === "message.outbound");
    expect(offlineMsgs.length).toBe(2);
    expect(offlineMsgs[0].text).toBe("offline-msg-1");
    expect(offlineMsgs[1].text).toBe("offline-msg-2");

    // No typing messages should have been queued
    const typingMsgs = received.filter(m => m.type === "typing");
    expect(typingMsgs.length).toBe(0);

    appWs2.close();
    gwWs.close();
  });

  it("hardening 7.5: connection limit enforced per gateway on reconnect", async () => {
    const { ws: gwWs } = await connectGateway();

    // Pair 6 apps (all connect during pairing — onPair skips connection limit)
    const apps: { ws: WebSocket; deviceToken: string }[] = [];
    for (let i = 0; i < 6; i++) {
      const app = await pairApp(gwWs);
      apps.push(app);
    }

    // Close the 6th app, then close all except first 5
    const sixthToken = apps[5].deviceToken;
    apps[5].ws.close();
    await new Promise(resolve => setTimeout(resolve, 200));

    // Now 5 apps are connected. The 6th trying to reconnect via app.connect
    // should be rejected because canAddAppToGateway returns false.
    const appWs6 = new WebSocket(wsUrl("/ws/app"));
    const result = await new Promise<any>((resolve, reject) => {
      appWs6.onopen = () => {
        appWs6.send(JSON.stringify({
          type: "app.connect",
          id: randomUUID(),
          ts: Date.now(),
          deviceToken: sixthToken,
          protocolVersion: "0.1",
        }));
      };
      appWs6.onmessage = (event) => {
        const msg = JSON.parse(event.data);
        resolve(msg);
      };
      appWs6.onerror = reject;
    });

    expect(result.type).toBe("error");
    expect(result.code).toBe("connection_limit");

    // Clean up
    for (const app of apps) app.ws.close();
    appWs6.close();
    gwWs.close();
  });
});
