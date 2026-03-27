import type { BaseMessage } from "./envelope.js";

// ---------------------------------------------------------------------------
// Gateway Registration
// ---------------------------------------------------------------------------

/** Gateway -> Relay: authenticate and register */
export interface GatewayRegister extends BaseMessage {
  type: "gateway.register";
  token: string;
  gatewayId: string;
  /** OpenClaw version string */
  version: string;
  /** Available agent identifiers */
  agents: string[];
  protocolVersion: string;
}

/** Relay -> Gateway: registration acknowledged */
export interface GatewayRegistered extends BaseMessage {
  type: "gateway.registered";
  gatewayId: string;
  /** Number of currently paired app devices */
  pairedDevices: number;
}

// ---------------------------------------------------------------------------
// App Pairing
// ---------------------------------------------------------------------------

export type AppPlatform = "ios" | "android" | "web" | "cli";

/** App -> Relay: initiate pairing with a code */
export interface AppPair extends BaseMessage {
  type: "app.pair";
  pairingCode: string;
  deviceName: string;
  platform: AppPlatform;
  protocolVersion: string;
}

/** Relay -> App: pairing succeeded */
export interface AppPaired extends BaseMessage {
  type: "app.paired";
  gatewayId: string;
  /** Long-lived token for subsequent reconnections */
  deviceToken: string;
  agents: string[];
}

export type PairErrorReason = "invalid_code" | "expired" | "gateway_offline";

/** Relay -> App: pairing failed */
export interface AppPairError extends BaseMessage {
  type: "app.pair.error";
  error: PairErrorReason;
  message: string;
}

// ---------------------------------------------------------------------------
// App Reconnection
// ---------------------------------------------------------------------------

/** App -> Relay: reconnect with existing device token */
export interface AppConnect extends BaseMessage {
  type: "app.connect";
  deviceToken: string;
  /** Last received message id for missed-message recovery */
  lastMessageId?: string;
  protocolVersion: string;
}

/** Relay -> App: reconnection acknowledged */
export interface AppConnected extends BaseMessage {
  type: "app.connected";
  gatewayId: string;
  gatewayOnline: boolean;
  agents: string[];
  /** New device token issued on reconnect (token rotation). Client must persist this. */
  newDeviceToken?: string;
  /** Messages sent while the app was offline */
  missedMessages: BaseMessage[];
}

// ---------------------------------------------------------------------------
// Union
// ---------------------------------------------------------------------------

export type ConnectionMessage =
  | GatewayRegister
  | GatewayRegistered
  | AppPair
  | AppPaired
  | AppPairError
  | AppConnect
  | AppConnected;
