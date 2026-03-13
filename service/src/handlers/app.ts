import type { ServerWebSocket } from "bun";
import type { AppPair, AppConnect } from "@clawchat/protocol";
import type { DbStore } from "../db.js";
import type { WsData, AppWsData, GatewayWsData } from "../connections.js";
import {
  addApp,
  removeApp,
  getGatewaySocket,
  isGatewayOnline,
} from "../connections.js";
import { send } from "../util.js";

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
    // Distinguish expired vs invalid
    // redeemPairingCode returns null for invalid, expired, or already-redeemed
    send(ws, {
      type: "app.pair.error",
      id: crypto.randomUUID(),
      ts: Date.now(),
      error: "invalid_code",
      message: "Invalid or expired pairing code",
    });
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

  console.log(`[app] paired: device=${deviceId} gateway=${codeRow.gatewayId} name=${msg.deviceName}`);
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

  // Attach identity to the socket
  const data = ws.data as AppWsData;
  data.deviceId = device.deviceId;
  data.gatewayId = device.gatewayId;

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
    missedMessages: [], // Phase 0: no offline queue
  });

  console.log(`[app] connected: device=${device.deviceId} gateway=${device.gatewayId} (gateway ${gatewayOnline ? "online" : "offline"})`);
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
