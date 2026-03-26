import type { BaseMessage } from "./envelope.js";

/** All known wire-protocol error codes */
export type ErrorCode =
  | "gateway_offline"
  | "agent_not_found"
  | "session_not_found"
  | "unauthorized"
  | "rate_limited"
  | "payload_too_large"
  | "internal_error"
  | "invalid_message"
  | "incompatible_version";

/** Error message returned by the relay or gateway */
export interface ErrorMessage extends BaseMessage {
  type: "error";
  code: ErrorCode;
  message: string;
  /** Links back to the request that caused the error */
  requestId?: string;
  /** Included when code is "incompatible_version" */
  supportedVersions?: string[];
}
