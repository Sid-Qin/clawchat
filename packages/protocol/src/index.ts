// Envelope
export type { BaseMessage } from "./envelope.js";

// Connection & auth
export type {
  GatewayRegister,
  GatewayRegistered,
  AppPair,
  AppPaired,
  AppPairError,
  AppConnect,
  AppConnected,
  AppPlatform,
  PairErrorReason,
  ConnectionMessage,
} from "./connection.js";

// Messaging
export type {
  Attachment,
  AttachmentType,
  VoicePayload,
  MessageInbound,
  TextContent,
  MediaType,
  Dimensions,
  MediaContent,
  PollOption,
  PollContent,
  ActionStyle,
  CardAction,
  CardContent,
  OutboundContent,
  MessageOutbound,
  StreamPhase,
  MessageStream,
  ReasoningPhase,
  MessageReasoning,
  ToolPhase,
  ToolEvent,
  MessagingMessage,
} from "./messaging.js";

// Control
export type {
  PresenceStatus,
  Typing,
  Presence,
  ChannelStatus,
  GatewayStatus,
  StatusRequest,
  StatusResponse,
  ControlMessage,
} from "./control.js";

// Pairing
export type {
  PairGenerate,
  PairCode,
  DeviceInfo,
  DevicesList,
  DevicesListResponse,
  DevicesRevoke,
  PairingMessage,
} from "./pairing.js";

// Errors
export type { ErrorCode, ErrorMessage } from "./errors.js";

// Actions
export type {
  ReactionAdd,
  ReactionRemove,
  MessageEdit,
  MessageDelete,
  ActionResponse,
  ApprovalOption,
  RiskLevel,
  ApprovalContext,
  ApprovalRequest,
  ApprovalResponse,
  AgentAbort,
  ActionMessage,
} from "./actions.js";

// Guards & parser
export {
  isGatewayRegister,
  isGatewayRegistered,
  isAppPair,
  isAppPaired,
  isAppPairError,
  isAppConnect,
  isAppConnected,
  isMessageInbound,
  isMessageOutbound,
  isMessageStream,
  isMessageReasoning,
  isToolEvent,
  isTyping,
  isPresence,
  isStatusRequest,
  isStatusResponse,
  isPairGenerate,
  isPairCode,
  isDevicesList,
  isDevicesListResponse,
  isDevicesRevoke,
  isErrorMessage,
  isReactionAdd,
  isReactionRemove,
  isMessageEdit,
  isMessageDelete,
  isActionResponse,
  isApprovalRequest,
  isApprovalResponse,
  isAgentAbort,
  parseMessage,
} from "./guards.js";

// ---------------------------------------------------------------------------
// Master union of all wire-protocol message types
// ---------------------------------------------------------------------------

import type { ConnectionMessage } from "./connection.js";
import type { MessagingMessage } from "./messaging.js";
import type { ControlMessage } from "./control.js";
import type { PairingMessage } from "./pairing.js";
import type { ErrorMessage } from "./errors.js";
import type { ActionMessage } from "./actions.js";

export type ClawChatMessage =
  | ConnectionMessage
  | MessagingMessage
  | ControlMessage
  | PairingMessage
  | ErrorMessage
  | ActionMessage;
