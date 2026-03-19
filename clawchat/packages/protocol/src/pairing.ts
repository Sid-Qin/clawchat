import type { BaseMessage } from "./envelope.js";
import type { AppPlatform } from "./connection.js";

// ---------------------------------------------------------------------------
// Pairing code generation
// ---------------------------------------------------------------------------

/** Gateway -> Relay: request a new pairing code */
export interface PairGenerate extends BaseMessage {
  type: "pair.generate";
}

/** Relay -> Gateway: generated pairing code */
export interface PairCode extends BaseMessage {
  type: "pair.code";
  code: string;
  /** Expiration timestamp (ms since epoch) */
  expiresAt: number;
}

// ---------------------------------------------------------------------------
// Device management
// ---------------------------------------------------------------------------

export interface DeviceInfo {
  deviceId: string;
  deviceName: string;
  platform: AppPlatform;
  /** When the device was first paired (ms since epoch) */
  pairedAt: number;
  /** Last seen timestamp (ms since epoch) */
  lastSeen: number;
}

/** App/Gateway -> Relay: list paired devices */
export interface DevicesList extends BaseMessage {
  type: "devices.list";
}

/** Relay -> App/Gateway: paired device list */
export interface DevicesListResponse extends BaseMessage {
  type: "devices.list.response";
  devices: DeviceInfo[];
}

/** App/Gateway -> Relay: revoke a paired device */
export interface DevicesRevoke extends BaseMessage {
  type: "devices.revoke";
  deviceId: string;
}

// ---------------------------------------------------------------------------
// Union
// ---------------------------------------------------------------------------

export type PairingMessage =
  | PairGenerate
  | PairCode
  | DevicesList
  | DevicesListResponse
  | DevicesRevoke;
