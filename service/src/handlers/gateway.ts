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
} from "../connections.js";
import { generatePairingCode, send } from "../util.js";

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

  switch (msg.type) {
    case "gateway.register":
      return onRegister(ws, msg as unknown as GatewayRegister, db);
    case "pair.generate":
      return onPairGenerate(ws, msg as unknown as PairGenerate, db);
    case "devices.list":
      return onDevicesList(ws, msg as unknown as DevicesList, db);
    case "devices.revoke":
      return onDevicesRevoke(ws, msg as unknown as DevicesRevoke, db);
    default:
      // Forward gateway -> apps relay messages
      return forwardToApps(ws, msg, raw);
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

  // Phase 0: trust-on-first-use. Accept any token and upsert.
  // TODO(phase 1): verify token matches or require re-auth.
  db.registerGateway(gatewayId, token);

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

  console.log(`[gw] registered: ${gatewayId} (v${version}, ${agents.length} agents, ${devices.length} devices)`);

  // Notify connected apps that gateway is online
  const presenceMsg = JSON.stringify({
    type: "presence",
    id: crypto.randomUUID(),
    ts: Date.now(),
    status: "online",
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

  console.log(`[gw] pairing code generated for ${data.gatewayId}: ${displayCode}`);
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

  console.log(`[gw] device revoked: ${msg.deviceId} by gateway ${data.gatewayId}`);
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

function forwardToApps(
  ws: ServerWebSocket<WsData>,
  msg: { type: string },
  raw: string,
): void {
  if (!FORWARD_TYPES.has(msg.type)) return;

  const data = ws.data as GatewayWsData;
  if (!data.gatewayId) return;

  const apps = getAppSocketsForGateway(data.gatewayId);
  for (const appWs of apps) {
    appWs.send(raw);
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
  });
  for (const appWs of getAppSocketsForGateway(data.gatewayId)) {
    appWs.send(presenceMsg);
  }
}
