import type { ServerWebSocket } from "bun";
import type { AppPair, AppConnect } from "@clawchat/protocol";
import type { DbStore } from "../db.js";
import type { WsData, AppWsData, GatewayWsData } from "../connections.js";
import {
  addApp,
  removeApp,
  getGatewaySocket,
  isGatewayOnline,
  canAddAppToGateway,
} from "../connections.js";
import { send } from "../util.js";
import { log } from "../log.js";
import { checkRateLimit } from "../rate-limit.js";

// ---------------------------------------------------------------------------
// App message router
// ---------------------------------------------------------------------------

export function handleAppMessage(
  ws: ServerWebSocket<WsData>,
  raw: string,
  db: DbStore,
): void {
  let msg: { type: string; [k: string]: unknown };
  try {
    msg = JSON.parse(raw);
  } catch {
    send(ws, {
      type: "error",
      id: crypto.randomUUID(),
      ts: Date.now(),
      code: "invalid_json",
      message: "Failed to parse message",
    });
    return;
  }

  // Rate limit: 60 messages per minute per device
  const data = ws.data as AppWsData;
  if (data.deviceId) {
    const rl = checkRateLimit(`app:${data.deviceId}`, 60, 60_000);
    if (!rl.allowed) {
      send(ws, { type: "error", id: crypto.randomUUID(), ts: Date.now(), code: "rate_limited", message: "Too many messages" });
      log("warn", "rate_limit.app", { deviceId: data.deviceId });
      return;
    }
  }

  switch (msg.type) {
    case "app.pair":
      return onPair(ws, msg as unknown as AppPair, db);
    case "app.connect":
      return onConnect(ws, msg as unknown as AppConnect, db);
    case "status.request":
      return onStatusRequest(ws, db);
    default:
      return forwardToGateway(ws, msg, raw, db);
  }
}

// ---------------------------------------------------------------------------
// app.pair — redeem a pairing code
// ---------------------------------------------------------------------------

function onPair(
  ws: ServerWebSocket<WsData>,
  msg: AppPair,
  db: DbStore,
): void {
  // Strip cosmetic hyphen if present
  const code = msg.pairingCode.replace(/-/g, "").toUpperCase();

  const codeRow = db.redeemPairingCode(code);
  if (!codeRow) {
    send(ws, {
      type: "app.pair.error",
      id: crypto.randomUUID(),
      ts: Date.now(),
      error: "invalid_code",
      message: "Invalid or expired pairing code",
    });
    return;
  }

  // Check device limit (max 10 paired devices per gateway)
  const existingDevices = db.listDevicesByGateway(codeRow.gatewayId);
  if (existingDevices.length >= 10) {
    send(ws, {
      type: "app.pair.error",
      id: crypto.randomUUID(),
      ts: Date.now(),
      error: "device_limit",
      message: "Maximum paired devices reached",
    });
    log("warn", "connection_limit.devices", { gatewayId: codeRow.gatewayId, count: existingDevices.length });
    return;
  }

  // Create device
  const deviceId = crypto.randomUUID();
  const deviceToken = crypto.randomUUID();

  db.createDevice({
    deviceId,
    deviceToken,
    deviceName: msg.deviceName || "Unknown Device",
    platform: msg.platform || "cli",
    gatewayId: codeRow.gatewayId,
  });

  // Attach identity to the socket and track connection
  const data = ws.data as AppWsData;
  data.deviceId = deviceId;
  data.gatewayId = codeRow.gatewayId;
  addApp(deviceId, codeRow.gatewayId, ws);
  db.touchDevice(deviceId);

  // Look up gateway to get agents list
  const gwSocket = getGatewaySocket(codeRow.gatewayId);
  const agents = gwSocket ? (gwSocket.data as GatewayWsData).agents ?? [] : [];

  send(ws, {
    type: "app.paired",
    id: crypto.randomUUID(),
    ts: Date.now(),
    gatewayId: codeRow.gatewayId,
    deviceToken,
    agents,
  });

  log("info", "app.paired", { deviceId, gatewayId: codeRow.gatewayId, platform: msg.platform, deviceName: msg.deviceName });
}

// ---------------------------------------------------------------------------
// app.connect — reconnect with device token
// ---------------------------------------------------------------------------

function onConnect(
  ws: ServerWebSocket<WsData>,
  msg: AppConnect,
  db: DbStore,
): void {
  const device = db.findDeviceByToken(msg.deviceToken);
  if (!device) {
    send(ws, {
      type: "error",
      id: crypto.randomUUID(),
      ts: Date.now(),
      code: "unauthorized",
      message: "Invalid device token",
    });
    ws.close(4003, "unauthorized");
    return;
  }

  // Check app connection limit per gateway
  if (!canAddAppToGateway(device.gatewayId)) {
    send(ws, {
      type: "error",
      id: crypto.randomUUID(),
      ts: Date.now(),
      code: "connection_limit",
      message: "Too many connected devices for this gateway",
    });
    log("warn", "connection_limit.app", { gatewayId: device.gatewayId });
    ws.close(4003, "connection_limit");
    return;
  }

  // Attach identity to the socket
  const data = ws.data as AppWsData;
  data.deviceId = device.deviceId;
  data.gatewayId = device.gatewayId;

  // Rotate device token
  const newDeviceToken = crypto.randomUUID();
  db.updateDeviceToken(device.deviceId, newDeviceToken);

  // Track connection
  addApp(device.deviceId, device.gatewayId, ws);
  db.touchDevice(device.deviceId);

  // Get gateway info
  const gwSocket = getGatewaySocket(device.gatewayId);
  const agents = gwSocket ? (gwSocket.data as GatewayWsData).agents ?? [] : [];
  const gatewayOnline = isGatewayOnline(device.gatewayId);

  send(ws, {
    type: "app.connected",
    id: crypto.randomUUID(),
    ts: Date.now(),
    gatewayId: device.gatewayId,
    gatewayOnline,
    agents,
    newDeviceToken,
    missedMessages: [],
  });

  // Deliver offline messages
  const offlineMsgs = db.getOfflineMessages(device.deviceId);
  if (offlineMsgs.length > 0) {
    for (const msg of offlineMsgs) {
      ws.send(msg.payload);
    }
    db.markOfflineDelivered(offlineMsgs.map((m) => m.id));
    log("info", "offline.delivered", { deviceId: device.deviceId, count: offlineMsgs.length });
  }

  log("info", "app.connected", { deviceId: device.deviceId, gatewayId: device.gatewayId, gatewayOnline, tokenRotated: true });
}

// ---------------------------------------------------------------------------
// status.request
// ---------------------------------------------------------------------------

function onStatusRequest(
  ws: ServerWebSocket<WsData>,
  _db: DbStore,
): void {
  const data = ws.data as AppWsData;
  if (!data.gatewayId) {
    send(ws, {
      type: "error",
      id: crypto.randomUUID(),
      ts: Date.now(),
      code: "not_connected",
      message: "App must connect before requesting status",
    });
    return;
  }

  const gwSocket = getGatewaySocket(data.gatewayId);
  const online = isGatewayOnline(data.gatewayId);
  const gwData = gwSocket?.data as GatewayWsData | undefined;

  send(ws, {
    type: "status.response",
    id: crypto.randomUUID(),
    ts: Date.now(),
    gateway: {
      online,
      version: "", // Gateway doesn't expose version via socket data in Phase 0
      uptime: 0,
      agents: gwData?.agents ?? [],
      channels: [],
    },
  });
}

// ---------------------------------------------------------------------------
// Forward app -> gateway
// ---------------------------------------------------------------------------

const FORWARD_TYPES = new Set([
  "message.inbound",
  "typing",
]);

function forwardToGateway(
  ws: ServerWebSocket<WsData>,
  msg: { type: string },
  raw: string,
  _db: DbStore,
): void {
  if (!FORWARD_TYPES.has(msg.type)) return;

  const data = ws.data as AppWsData;
  if (!data.gatewayId) {
    send(ws, {
      type: "error",
      id: crypto.randomUUID(),
      ts: Date.now(),
      code: "not_connected",
      message: "App must connect before sending messages",
    });
    return;
  }

  const gwSocket = getGatewaySocket(data.gatewayId);
  if (!gwSocket) {
    send(ws, {
      type: "error",
      id: crypto.randomUUID(),
      ts: Date.now(),
      code: "gateway_offline",
      message: "Gateway is not connected",
    });
    return;
  }

  gwSocket.send(raw);
}

// ---------------------------------------------------------------------------
// App disconnect handler
// ---------------------------------------------------------------------------

export function handleAppClose(ws: ServerWebSocket<WsData>): void {
  const data = ws.data as AppWsData;
  if (!data.deviceId || !data.gatewayId) return;
  removeApp(data.deviceId, data.gatewayId);
}
