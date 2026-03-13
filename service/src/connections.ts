import type { ServerWebSocket } from "bun";

// ---------------------------------------------------------------------------
// WebSocket data attached during upgrade
// ---------------------------------------------------------------------------

export interface GatewayWsData {
  kind: "gateway";
  gatewayId: string;
  /** Available agent identifiers reported during registration */
  agents: string[];
}

export interface AppWsData {
  kind: "app";
  deviceId: string;
  gatewayId: string;
}

export type WsData = GatewayWsData | AppWsData;

// ---------------------------------------------------------------------------
// Connection store (in-memory, lost on restart)
// ---------------------------------------------------------------------------

/** Gateway connections keyed by gatewayId */
const gatewaySockets = new Map<string, ServerWebSocket<WsData>>();

/** App connections keyed by deviceId */
const appSockets = new Map<string, ServerWebSocket<WsData>>();

/** Gateway → set of paired device IDs that are currently connected */
const gatewayDevices = new Map<string, Set<string>>();

// ---------------------------------------------------------------------------
// Gateway helpers
// ---------------------------------------------------------------------------

export function addGateway(gatewayId: string, ws: ServerWebSocket<WsData>): void {
  gatewaySockets.set(gatewayId, ws);
  if (!gatewayDevices.has(gatewayId)) {
    gatewayDevices.set(gatewayId, new Set());
  }
  console.log(`[conn] gateway connected: ${gatewayId}`);
}

export function removeGateway(gatewayId: string): void {
  gatewaySockets.delete(gatewayId);
  console.log(`[conn] gateway disconnected: ${gatewayId}`);
}

export function getGatewaySocket(gatewayId: string): ServerWebSocket<WsData> | undefined {
  return gatewaySockets.get(gatewayId);
}

export function isGatewayOnline(gatewayId: string): boolean {
  return gatewaySockets.has(gatewayId);
}

// ---------------------------------------------------------------------------
// App helpers
// ---------------------------------------------------------------------------

export function addApp(deviceId: string, gatewayId: string, ws: ServerWebSocket<WsData>): void {
  appSockets.set(deviceId, ws);
  let devices = gatewayDevices.get(gatewayId);
  if (!devices) {
    devices = new Set();
    gatewayDevices.set(gatewayId, devices);
  }
  devices.add(deviceId);
  console.log(`[conn] app connected: device=${deviceId} gateway=${gatewayId}`);
}

export function removeApp(deviceId: string, gatewayId: string): void {
  appSockets.delete(deviceId);
  gatewayDevices.get(gatewayId)?.delete(deviceId);
  console.log(`[conn] app disconnected: device=${deviceId} gateway=${gatewayId}`);
}

export function getAppSocket(deviceId: string): ServerWebSocket<WsData> | undefined {
  return appSockets.get(deviceId);
}

/**
 * Get all connected app sockets paired to a specific gateway.
 */
export function getAppSocketsForGateway(gatewayId: string): ServerWebSocket<WsData>[] {
  const deviceIds = gatewayDevices.get(gatewayId);
  if (!deviceIds) return [];
  const sockets: ServerWebSocket<WsData>[] = [];
  for (const id of deviceIds) {
    const ws = appSockets.get(id);
    if (ws) sockets.push(ws);
  }
  return sockets;
}

/**
 * Get the set of connected device IDs for a gateway.
 */
export function getConnectedDeviceIds(gatewayId: string): Set<string> {
  return gatewayDevices.get(gatewayId) ?? new Set();
}

// ---------------------------------------------------------------------------
// Stats
// ---------------------------------------------------------------------------

export function stats() {
  return {
    gateways: gatewaySockets.size,
    apps: appSockets.size,
  };
}
