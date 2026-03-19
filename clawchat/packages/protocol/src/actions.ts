import type { BaseMessage } from "./envelope.js";

// ---------------------------------------------------------------------------
// Reactions
// ---------------------------------------------------------------------------

/** App -> Gateway: add a reaction */
export interface ReactionAdd extends BaseMessage {
  type: "reaction.add";
  messageId: string;
  /** Emoji shortcode or unicode character */
  emoji: string;
}

/** App -> Gateway: remove a reaction */
export interface ReactionRemove extends BaseMessage {
  type: "reaction.remove";
  messageId: string;
  emoji: string;
}

// ---------------------------------------------------------------------------
// Message editing & deletion
// ---------------------------------------------------------------------------

/** App -> Gateway: edit a previously sent message */
export interface MessageEdit extends BaseMessage {
  type: "message.edit";
  messageId: string;
  text: string;
}

/** App -> Gateway: delete a message */
export interface MessageDelete extends BaseMessage {
  type: "message.delete";
  messageId: string;
}

// ---------------------------------------------------------------------------
// Card action response
// ---------------------------------------------------------------------------

/** App -> Gateway: user tapped a card action button */
export interface ActionResponse extends BaseMessage {
  type: "action.response";
  cardId: string;
  actionId: string;
}

// ---------------------------------------------------------------------------
// Approval (human-in-the-loop)
// ---------------------------------------------------------------------------

export type ApprovalOption = "allow-once" | "allow-always" | "deny";

export type RiskLevel = "low" | "medium" | "high";

export interface ApprovalContext {
  reason?: string;
  risk?: RiskLevel;
}

/** Gateway -> App: request user approval for a command */
export interface ApprovalRequest extends BaseMessage {
  type: "approval.request";
  agentId: string;
  command: string;
  workingDir: string;
  context?: ApprovalContext;
  /** ISO 8601 expiration timestamp */
  expiresAt?: string;
  options: ApprovalOption[];
}

/** App -> Gateway: user approval decision */
export interface ApprovalResponse extends BaseMessage {
  type: "approval.response";
  approvalId: string;
  decision: ApprovalOption;
}

// ---------------------------------------------------------------------------
// Abort
// ---------------------------------------------------------------------------

/** App -> Gateway: abort the current agent operation */
export interface AgentAbort extends BaseMessage {
  type: "agent.abort";
  agentId: string;
  sessionKey?: string;
}

// ---------------------------------------------------------------------------
// Union
// ---------------------------------------------------------------------------

export type ActionMessage =
  | ReactionAdd
  | ReactionRemove
  | MessageEdit
  | MessageDelete
  | ActionResponse
  | ApprovalRequest
  | ApprovalResponse
  | AgentAbort;
