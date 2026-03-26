import type { ServerWebSocket } from "bun";
import { log } from "./log.js";

// ---------------------------------------------------------------------------
// WebSocket data attached during upgrade
// ---------------------------------------------------------------------------

export interface GatewayWsData {
  kind: "gateway";
  gatewayId: string;
  /** Available agent identifiers reported during registration */
  agents: string[];
  /** IP address for connection tracking */
  ip: string;
}

export interface AppWsData {
  kind: "app";
  deviceId: string;
  gatewayId: string;
  /** IP address for connection tracking */
  ip: string;
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

/** IP → count of active WebSocket connections */
const ipConnections = new Map<string, number>();

// Connection limits
const MAX_CONNECTIONS_PER_IP = 20;
const MAX_APP_CONNECTIONS_PER_GATEWAY = 5;

// ---------------------------------------------------------------------------
// Gateway helpers
// ---------------------------------------------------------------------------

export function addGateway(gatewayId: string, ws: ServerWebSocket<WsData>): void {
  gatewaySockets.set(gatewayId, ws);
  if (!gatewayDevices.has(gatewayId)) {
    gatewayDevices.set(gatewayId, new Set());
  }
  log("debug", "conn.gateway.add", { gatewayId });
}

export function removeGateway(gatewayId: string): void {
  gatewaySockets.delete(gatewayId);
  log("debug", "conn.gateway.remove", { gatewayId });
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
  log("debug", "conn.app.add", { deviceId, gatewayId });
}

export function removeApp(deviceId: string, gatewayId: string): void {
  appSockets.delete(deviceId);
  gatewayDevices.get(gatewayId)?.delete(deviceId);
  log("debug", "conn.app.remove", { deviceId, gatewayId });
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
// IP connection tracking
// ---------------------------------------------------------------------------

/** Track a new connection from an IP. Returns false if limit exceeded. */
export function trackIpConnection(ip: string): boolean {
  const current = ipConnections.get(ip) ?? 0;
  if (current >= MAX_CONNECTIONS_PER_IP) return false;
  ipConnections.set(ip, current + 1);
  return true;
}

/** Release a connection from an IP. */
export function releaseIpConnection(ip: string): void {
  const current = ipConnections.get(ip);
  if (current === undefined) return;
  if (current <= 1) {
    ipConnections.delete(ip);
  } else {
    ipConnections.set(ip, current - 1);
  }
}

/** Check if a gateway has room for more app connections. */
export function canAddAppToGateway(gatewayId: string): boolean {
  const devices = gatewayDevices.get(gatewayId);
  if (!devices) return true;
  return devices.size < MAX_APP_CONNECTIONS_PER_GATEWAY;
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
