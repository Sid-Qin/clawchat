import type { BaseMessage } from "./envelope.js";

// ---------------------------------------------------------------------------
// Typing indicator
// ---------------------------------------------------------------------------

export type PresenceStatus = "online" | "away" | "offline";

/** Gateway -> App: agent typing / processing indicator */
export interface Typing extends BaseMessage {
  type: "typing";
  agentId: string;
  sessionKey?: string;
  active: boolean;
  /** More specific status text (e.g. "Thinking...") */
  label?: string;
}

// ---------------------------------------------------------------------------
// Presence
// ---------------------------------------------------------------------------

/** Bidirectional presence update */
export interface Presence extends BaseMessage {
  type: "presence";
  status: PresenceStatus;
}

// ---------------------------------------------------------------------------
// Gateway status
// ---------------------------------------------------------------------------

export interface ChannelStatus {
  id: string;
  status: "connected" | "disconnected" | "error";
}

export interface GatewayStatus {
  online: boolean;
  version: string;
  /** Uptime in milliseconds */
  uptime: number;
  agents: string[];
  channels: ChannelStatus[];
}

/** App -> Relay: request gateway status */
export interface StatusRequest extends BaseMessage {
  type: "status.request";
}

/** Relay -> App: gateway status response */
export interface StatusResponse extends BaseMessage {
  type: "status.response";
  gateway: GatewayStatus;
}

// ---------------------------------------------------------------------------
// Union
// ---------------------------------------------------------------------------

export type ControlMessage = Typing | Presence | StatusRequest | StatusResponse;
