import type { ServerWebSocket } from "bun";
import type { GatewayRegister } from "@clawchat/protocol";
import type { PairGenerate, DevicesList, DevicesRevoke, DeviceInfo } from "@clawchat/protocol";
import type { DbStore } from "../db.js";
import type { WsData, GatewayWsData } from "../connections.js";
import {
  addGateway,
  removeGateway,
  getAppSocketsForGateway,
  getAppSocket,
  getConnectedDeviceIds,
} from "../connections.js";
import { generatePairingCode, send } from "../util.js";
import { log } from "../log.js";
import { checkRateLimit } from "../rate-limit.js";

// ---------------------------------------------------------------------------
// Gateway message router
// ---------------------------------------------------------------------------

export function handleGatewayMessage(
  ws: ServerWebSocket<WsData>,
  raw: string,
  db: DbStore,
): void {
  let msg: { type: string; [k: string]: unknown };
  try {
    msg = JSON.parse(raw);
  } catch {
    send(ws, { type: "error", id: crypto.randomUUID(), ts: Date.now(), code: "invalid_json", message: "Failed to parse message" });
    return;
  }

  // Rate limit: 200 messages per minute per gateway
  const gwData = ws.data as GatewayWsData;
  if (gwData.gatewayId) {
    const rl = checkRateLimit(`gw:${gwData.gatewayId}`, 200, 60_000);
    if (!rl.allowed) {
      send(ws, { type: "error", id: crypto.randomUUID(), ts: Date.now(), code: "rate_limited", message: "Too many messages" });
      log("warn", "rate_limit.gateway", { gatewayId: gwData.gatewayId });
      return;
    }
  }

  switch (msg.type) {
    case "gateway.register":
      return onRegister(ws, msg as unknown as GatewayRegister, db);
    case "pair.generate":
      return onPairGenerate(ws, msg as unknown as PairGenerate, db);
    case "devices.list":
      return onDevicesList(ws, msg as unknown as DevicesList, db);
    case "devices.revoke":
      return onDevicesRevoke(ws, msg as unknown as DevicesRevoke, db);
    case "ping":
      return send(ws, { type: "pong", id: msg.id, ts: Date.now() });
    default:
      // Forward gateway -> apps relay messages
      return forwardToApps(ws, msg, raw, db);
  }
}

// ---------------------------------------------------------------------------
// gateway.register
// ---------------------------------------------------------------------------

function onRegister(
  ws: ServerWebSocket<WsData>,
  msg: GatewayRegister,
  db: DbStore,
): void {
  const { gatewayId, token, agents = [], version } = msg;

  if (!gatewayId || !token) {
    send(ws, {
      type: "error",
      id: crypto.randomUUID(),
      ts: Date.now(),
      code: "invalid_request",
      message: "Missing gatewayId or token",
    });
    ws.close(4001, "invalid_request");
    return;
  }

  // Register gateway — verifies token hash on subsequent registrations
  const gwRow = db.registerGateway(gatewayId, token);
  if (!gwRow) {
    send(ws, {
      type: "error",
      id: crypto.randomUUID(),
      ts: Date.now(),
      code: "unauthorized",
      message: "Invalid gateway token",
    });
    log("warn", "gateway.register.unauthorized", { gatewayId });
    ws.close(4003, "unauthorized");
    return;
  }

  // Attach identity to the socket
  const data = ws.data as GatewayWsData;
  data.gatewayId = gatewayId;
  data.agents = agents;

  // Track in connection store
  addGateway(gatewayId, ws);

  // Count paired devices
  const devices = db.listDevicesByGateway(gatewayId);

  send(ws, {
    type: "gateway.registered",
    id: crypto.randomUUID(),
    ts: Date.now(),
    gatewayId,
    pairedDevices: devices.length,
  });

  log("info", "gateway.register", { gatewayId, version, agents: agents.length, devices: devices.length });

  // Notify connected apps that gateway is online
  const presenceMsg = JSON.stringify({
    type: "presence",
    id: crypto.randomUUID(),
    ts: Date.now(),
    status: "online",
    online: true,
    gatewayId,
  });
  for (const appWs of getAppSocketsForGateway(gatewayId)) {
    appWs.send(presenceMsg);
  }
}

// ---------------------------------------------------------------------------
// pair.generate
// ---------------------------------------------------------------------------

function onPairGenerate(
  ws: ServerWebSocket<WsData>,
  _msg: PairGenerate,
  db: DbStore,
): void {
  const data = ws.data as GatewayWsData;
  if (!data.gatewayId) {
    send(ws, {
      type: "error",
      id: crypto.randomUUID(),
      ts: Date.now(),
      code: "not_registered",
      message: "Gateway must register before generating pairing codes",
    });
    return;
  }

  // Rate limit: 5 pairing codes per minute per gateway
  const pairRl = checkRateLimit(`pair:${data.gatewayId}`, 5, 60_000);
  if (!pairRl.allowed) {
    send(ws, { type: "error", id: crypto.randomUUID(), ts: Date.now(), code: "rate_limited", message: "Too many pairing code requests" });
    log("warn", "rate_limit.pair", { gatewayId: data.gatewayId });
    return;
  }

  const code = generatePairingCode();
  const expiresAt = Date.now() + 5 * 60 * 1000; // 5 minutes

  db.createPairingCode(code, data.gatewayId, expiresAt);

  // Format for display: XXX-XXX
  const displayCode = `${code.slice(0, 3)}-${code.slice(3)}`;

  send(ws, {
    type: "pair.code",
    id: crypto.randomUUID(),
    ts: Date.now(),
    code: displayCode,
    expiresAt,
  });

  log("info", "pair.generate", { gatewayId: data.gatewayId, code: displayCode });
}

// ---------------------------------------------------------------------------
// devices.list
// ---------------------------------------------------------------------------

function onDevicesList(
  ws: ServerWebSocket<WsData>,
  _msg: DevicesList,
  db: DbStore,
): void {
  const data = ws.data as GatewayWsData;
  if (!data.gatewayId) {
    send(ws, {
      type: "error",
      id: crypto.randomUUID(),
      ts: Date.now(),
      code: "not_registered",
      message: "Gateway must register first",
    });
    return;
  }

  const rows = db.listDevicesByGateway(data.gatewayId);
  const devices: DeviceInfo[] = rows.map((r) => ({
    deviceId: r.deviceId,
    deviceName: r.deviceName,
    platform: r.platform as DeviceInfo["platform"],
    pairedAt: r.createdAt,
    lastSeen: r.lastSeen,
  }));

  send(ws, {
    type: "devices.list.response",
    id: crypto.randomUUID(),
    ts: Date.now(),
    devices,
  });
}

// ---------------------------------------------------------------------------
// devices.revoke
// ---------------------------------------------------------------------------

function onDevicesRevoke(
  ws: ServerWebSocket<WsData>,
  msg: DevicesRevoke,
  db: DbStore,
): void {
  const data = ws.data as GatewayWsData;
  if (!data.gatewayId) {
    send(ws, {
      type: "error",
      id: crypto.randomUUID(),
      ts: Date.now(),
      code: "not_registered",
      message: "Gateway must register first",
    });
    return;
  }

  const deleted = db.revokeDevice(msg.deviceId);
  if (!deleted) {
    send(ws, {
      type: "error",
      id: crypto.randomUUID(),
      ts: Date.now(),
      code: "not_found",
      message: `Device ${msg.deviceId} not found`,
    });
    return;
  }

  // Close the device's active WebSocket if connected
  const appWs = getAppSocket(msg.deviceId);
  if (appWs) {
    send(appWs, {
      type: "error",
      id: crypto.randomUUID(),
      ts: Date.now(),
      code: "device_revoked",
      message: "This device has been revoked",
    });
    appWs.close(4003, "device_revoked");
  }

  log("info", "device.revoke", { deviceId: msg.deviceId, gatewayId: data.gatewayId });
}

// ---------------------------------------------------------------------------
// Forward gateway -> paired apps
// ---------------------------------------------------------------------------

/** Message types that the relay forwards from gateway to apps. */
const FORWARD_TYPES = new Set([
  "message.outbound",
  "message.stream",
  "message.reasoning",
  "tool.event",
  "typing",
]);

/** Message types that should be queued for offline devices (not typing/presence). */
const OFFLINE_QUEUE_TYPES = new Set([
  "message.outbound",
  "message.stream",
  "message.reasoning",
  "tool.event",
]);

function forwardToApps(
  ws: ServerWebSocket<WsData>,
  msg: { type: string },
  raw: string,
  db: DbStore,
): void {
  if (!FORWARD_TYPES.has(msg.type)) return;

  const data = ws.data as GatewayWsData;
  if (!data.gatewayId) return;

  // Get connected app sockets
  const apps = getAppSocketsForGateway(data.gatewayId);
  const connectedDeviceIds = getConnectedDeviceIds(data.gatewayId);

  for (const appWs of apps) {
    appWs.send(raw);
  }

  // Queue for offline devices (if message type is queueable)
  if (OFFLINE_QUEUE_TYPES.has(msg.type)) {
    const allDevices = db.listDevicesByGateway(data.gatewayId);
    for (const device of allDevices) {
      if (!connectedDeviceIds.has(device.deviceId)) {
        db.queueOfflineMessage(device.deviceId, raw);
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Gateway disconnect handler
// ---------------------------------------------------------------------------

export function handleGatewayClose(ws: ServerWebSocket<WsData>): void {
  const data = ws.data as GatewayWsData;
  if (!data.gatewayId) return;

  removeGateway(data.gatewayId);

  // Notify connected apps that gateway went offline
  const presenceMsg = JSON.stringify({
    type: "presence",
    id: crypto.randomUUID(),
    ts: Date.now(),
    status: "offline",
    online: false,
    gatewayId: data.gatewayId,
  });
  for (const appWs of getAppSocketsForGateway(data.gatewayId)) {
    appWs.send(presenceMsg);
  }
}
