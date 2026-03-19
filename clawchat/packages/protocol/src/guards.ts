import type { BaseMessage } from "./envelope.js";
import type {
  GatewayRegister,
  GatewayRegistered,
  AppPair,
  AppPaired,
  AppPairError,
  AppConnect,
  AppConnected,
} from "./connection.js";
import type {
  MessageInbound,
  MessageOutbound,
  MessageStream,
  MessageReasoning,
  ToolEvent,
} from "./messaging.js";
import type { Typing, Presence, StatusRequest, StatusResponse } from "./control.js";
import type {
  PairGenerate,
  PairCode,
  DevicesList,
  DevicesListResponse,
  DevicesRevoke,
} from "./pairing.js";
import type { ErrorMessage } from "./errors.js";
import type {
  ReactionAdd,
  ReactionRemove,
  MessageEdit,
  MessageDelete,
  ActionResponse,
  ApprovalRequest,
  ApprovalResponse,
  AgentAbort,
} from "./actions.js";
import type { ClawChatMessage } from "./index.js";

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function hasType(value: unknown, type: string): value is BaseMessage {
  return (
    typeof value === "object" &&
    value !== null &&
    "type" in value &&
    (value as Record<string, unknown>).type === type
  );
}

// ---------------------------------------------------------------------------
// Connection guards
// ---------------------------------------------------------------------------

export function isGatewayRegister(msg: unknown): msg is GatewayRegister {
  return hasType(msg, "gateway.register");
}

export function isGatewayRegistered(msg: unknown): msg is GatewayRegistered {
  return hasType(msg, "gateway.registered");
}

export function isAppPair(msg: unknown): msg is AppPair {
  return hasType(msg, "app.pair");
}

export function isAppPaired(msg: unknown): msg is AppPaired {
  return hasType(msg, "app.paired");
}

export function isAppPairError(msg: unknown): msg is AppPairError {
  return hasType(msg, "app.pair.error");
}

export function isAppConnect(msg: unknown): msg is AppConnect {
  return hasType(msg, "app.connect");
}

export function isAppConnected(msg: unknown): msg is AppConnected {
  return hasType(msg, "app.connected");
}

// ---------------------------------------------------------------------------
// Messaging guards
// ---------------------------------------------------------------------------

export function isMessageInbound(msg: unknown): msg is MessageInbound {
  return hasType(msg, "message.inbound");
}

export function isMessageOutbound(msg: unknown): msg is MessageOutbound {
  return hasType(msg, "message.outbound");
}

export function isMessageStream(msg: unknown): msg is MessageStream {
  return hasType(msg, "message.stream");
}

export function isMessageReasoning(msg: unknown): msg is MessageReasoning {
  return hasType(msg, "message.reasoning");
}

export function isToolEvent(msg: unknown): msg is ToolEvent {
  return hasType(msg, "tool.event");
}

// ---------------------------------------------------------------------------
// Control guards
// ---------------------------------------------------------------------------

export function isTyping(msg: unknown): msg is Typing {
  return hasType(msg, "typing");
}

export function isPresence(msg: unknown): msg is Presence {
  return hasType(msg, "presence");
}

export function isStatusRequest(msg: unknown): msg is StatusRequest {
  return hasType(msg, "status.request");
}

export function isStatusResponse(msg: unknown): msg is StatusResponse {
  return hasType(msg, "status.response");
}

// ---------------------------------------------------------------------------
// Pairing guards
// ---------------------------------------------------------------------------

export function isPairGenerate(msg: unknown): msg is PairGenerate {
  return hasType(msg, "pair.generate");
}

export function isPairCode(msg: unknown): msg is PairCode {
  return hasType(msg, "pair.code");
}

export function isDevicesList(msg: unknown): msg is DevicesList {
  return hasType(msg, "devices.list");
}

export function isDevicesListResponse(msg: unknown): msg is DevicesListResponse {
  return hasType(msg, "devices.list.response");
}

export function isDevicesRevoke(msg: unknown): msg is DevicesRevoke {
  return hasType(msg, "devices.revoke");
}

// ---------------------------------------------------------------------------
// Error guard
// ---------------------------------------------------------------------------

export function isErrorMessage(msg: unknown): msg is ErrorMessage {
  return hasType(msg, "error");
}

// ---------------------------------------------------------------------------
// Action guards
// ---------------------------------------------------------------------------

export function isReactionAdd(msg: unknown): msg is ReactionAdd {
  return hasType(msg, "reaction.add");
}

export function isReactionRemove(msg: unknown): msg is ReactionRemove {
  return hasType(msg, "reaction.remove");
}

export function isMessageEdit(msg: unknown): msg is MessageEdit {
  return hasType(msg, "message.edit");
}

export function isMessageDelete(msg: unknown): msg is MessageDelete {
  return hasType(msg, "message.delete");
}

export function isActionResponse(msg: unknown): msg is ActionResponse {
  return hasType(msg, "action.response");
}

export function isApprovalRequest(msg: unknown): msg is ApprovalRequest {
  return hasType(msg, "approval.request");
}

export function isApprovalResponse(msg: unknown): msg is ApprovalResponse {
  return hasType(msg, "approval.response");
}

export function isAgentAbort(msg: unknown): msg is AgentAbort {
  return hasType(msg, "agent.abort");
}

// ---------------------------------------------------------------------------
// Generic parser
// ---------------------------------------------------------------------------

/**
 * Parse a raw JSON string into a typed ClawChatMessage.
 * Returns `undefined` if the input is not valid JSON or lacks required
 * envelope fields (`type`, `id`, `ts`).
 */
export function parseMessage(raw: string): ClawChatMessage | undefined {
  let parsed: unknown;
  try {
    parsed = JSON.parse(raw);
  } catch {
    return undefined;
  }

  if (
    typeof parsed !== "object" ||
    parsed === null ||
    !("type" in parsed) ||
    !("id" in parsed) ||
    !("ts" in parsed)
  ) {
    return undefined;
  }

  const obj = parsed as Record<string, unknown>;
  if (typeof obj.type !== "string" || typeof obj.id !== "string" || typeof obj.ts !== "number") {
    return undefined;
  }

  // The caller is responsible for handling unknown types via forward compatibility.
  return parsed as ClawChatMessage;
}
