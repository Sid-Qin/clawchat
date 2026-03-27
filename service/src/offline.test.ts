import { describe, it, expect, beforeEach, afterEach } from "bun:test";
import { createDb, type DbStore } from "./db.js";
import { randomUUID } from "crypto";
import { unlinkSync } from "node:fs";

describe("offline message queue", () => {
  let db: DbStore;
  let dbPath: string;
  let gatewayId: string;
  let deviceId: string;

  beforeEach(() => {
    dbPath = `/tmp/clawchat-offline-test-${randomUUID()}.db`;
    db = createDb(dbPath);

    // Set up a gateway and device
    gatewayId = `gw-${randomUUID().slice(0, 8)}`;
    deviceId = `dev-${randomUUID().slice(0, 8)}`;
    const token = randomUUID();

    db.registerGateway(gatewayId, token);
    db.createDevice({
      deviceId,
      deviceToken: randomUUID(),
      deviceName: "Test Device",
      platform: "ios",
      gatewayId,
    });
  });

  afterEach(() => {
    db.close();
    try {
      unlinkSync(dbPath);
      unlinkSync(dbPath + "-wal");
      unlinkSync(dbPath + "-shm");
    } catch {}
  });

  it("queues and retrieves messages in order", () => {
    db.queueOfflineMessage(deviceId, JSON.stringify({ type: "message.outbound", text: "first" }));
    db.queueOfflineMessage(deviceId, JSON.stringify({ type: "message.outbound", text: "second" }));
    db.queueOfflineMessage(deviceId, JSON.stringify({ type: "message.outbound", text: "third" }));

    const msgs = db.getOfflineMessages(deviceId);
    expect(msgs).toHaveLength(3);

    const payloads = msgs.map(m => JSON.parse(m.payload));
    expect(payloads[0].text).toBe("first");
    expect(payloads[1].text).toBe("second");
    expect(payloads[2].text).toBe("third");
  });

  it("marks messages as delivered", () => {
    db.queueOfflineMessage(deviceId, JSON.stringify({ type: "message.outbound", text: "a" }));
    db.queueOfflineMessage(deviceId, JSON.stringify({ type: "message.outbound", text: "b" }));

    const msgs = db.getOfflineMessages(deviceId);
    expect(msgs).toHaveLength(2);

    // Mark first as delivered
    db.markOfflineDelivered([msgs[0].id]);

    // Only undelivered should be returned
    const remaining = db.getOfflineMessages(deviceId);
    expect(remaining).toHaveLength(1);
    expect(JSON.parse(remaining[0].payload).text).toBe("b");
  });

  it("enforces per-device cap of 100 messages", () => {
    // Queue 100 messages
    for (let i = 0; i < 100; i++) {
      db.queueOfflineMessage(deviceId, JSON.stringify({ type: "message.outbound", n: i }));
    }

    let msgs = db.getOfflineMessages(deviceId);
    expect(msgs).toHaveLength(100);

    // Queue one more — oldest should be evicted
    db.queueOfflineMessage(deviceId, JSON.stringify({ type: "message.outbound", n: 100 }));

    msgs = db.getOfflineMessages(deviceId);
    expect(msgs).toHaveLength(100);

    // First message should be n:1 (n:0 was evicted)
    const first = JSON.parse(msgs[0].payload);
    expect(first.n).toBe(1);

    // Last message should be n:100
    const last = JSON.parse(msgs[msgs.length - 1].payload);
    expect(last.n).toBe(100);
  });

  it("returns empty array for device with no messages", () => {
    const msgs = db.getOfflineMessages(deviceId);
    expect(msgs).toHaveLength(0);
  });

  it("isolates messages between devices", () => {
    // Create a second device
    const deviceId2 = `dev-${randomUUID().slice(0, 8)}`;
    db.createDevice({
      deviceId: deviceId2,
      deviceToken: randomUUID(),
      deviceName: "Test Device 2",
      platform: "android",
      gatewayId,
    });

    db.queueOfflineMessage(deviceId, JSON.stringify({ type: "message.outbound", for: "dev1" }));
    db.queueOfflineMessage(deviceId2, JSON.stringify({ type: "message.outbound", for: "dev2" }));

    const msgs1 = db.getOfflineMessages(deviceId);
    const msgs2 = db.getOfflineMessages(deviceId2);

    expect(msgs1).toHaveLength(1);
    expect(msgs2).toHaveLength(1);
    expect(JSON.parse(msgs1[0].payload).for).toBe("dev1");
    expect(JSON.parse(msgs2[0].payload).for).toBe("dev2");
  });

  it("cleans delivered and expired messages", () => {
    db.queueOfflineMessage(deviceId, JSON.stringify({ type: "message.outbound", text: "delivered" }));
    db.queueOfflineMessage(deviceId, JSON.stringify({ type: "message.outbound", text: "pending" }));

    const msgs = db.getOfflineMessages(deviceId);
    // Mark first as delivered
    db.markOfflineDelivered([msgs[0].id]);

    // Run cleanup (also cleans expired codes, but we just care about offline here)
    db.cleanExpiredCodes();

    // Only pending message should remain
    const remaining = db.getOfflineMessages(deviceId);
    expect(remaining).toHaveLength(1);
    expect(JSON.parse(remaining[0].payload).text).toBe("pending");
  });
});
