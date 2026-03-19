import type { BaseMessage } from "./envelope.js";

// ---------------------------------------------------------------------------
// Attachments & Voice
// ---------------------------------------------------------------------------

export type AttachmentType = "image" | "video" | "audio" | "file";

export interface Attachment {
  type: AttachmentType;
  mimeType?: string;
  filename?: string;
  /** Size in bytes */
  size?: number;
  /** Base64-encoded data for small files (< 256 KB) */
  data?: string;
  /** Presigned URL for large files */
  url?: string;
  /** Reference to a previously uploaded file */
  fileId?: string;
}

export interface VoicePayload {
  mimeType: string;
  /** Duration in milliseconds */
  duration: number;
  data: string;
  /** Client-side speech-to-text result */
  transcription?: string;
}

// ---------------------------------------------------------------------------
// Inbound (App -> Gateway)
// ---------------------------------------------------------------------------

/** App -> Gateway: user message */
export interface MessageInbound extends BaseMessage {
  type: "message.inbound";
  agentId: string;
  text?: string;
  attachments?: Attachment[];
  voice?: VoicePayload;
  /** Quote-reply to a previous message */
  replyTo?: string;
  /** Thread context identifier */
  threadId?: string;
  /** Explicit session override */
  sessionKey?: string;
}

// ---------------------------------------------------------------------------
// Outbound content variants
// ---------------------------------------------------------------------------

export interface TextContent {
  type: "text";
  text: string;
  format: "markdown" | "plain";
}

export type MediaType = "image" | "video" | "audio" | "file";

export interface Dimensions {
  width: number;
  height: number;
}

export interface MediaContent {
  type: "media";
  mediaType: MediaType;
  mimeType: string;
  url: string;
  filename?: string;
  size?: number;
  caption?: string;
  dimensions?: Dimensions;
}

export interface PollOption {
  id: string;
  text: string;
}

export interface PollContent {
  type: "poll";
  question: string;
  options: PollOption[];
  maxSelections: number;
  anonymous: boolean;
}

export type ActionStyle = "primary" | "secondary" | "danger";

export interface CardAction {
  id: string;
  label: string;
  style: ActionStyle;
}

export interface CardContent {
  type: "card";
  title: string;
  body: string;
  format: "markdown" | "plain";
  actions: CardAction[];
}

export type OutboundContent = TextContent | MediaContent | PollContent | CardContent;

// ---------------------------------------------------------------------------
// Outbound (Gateway -> App)
// ---------------------------------------------------------------------------

/** Gateway -> App: complete message */
export interface MessageOutbound extends BaseMessage {
  type: "message.outbound";
  agentId: string;
  content: OutboundContent;
  replyTo?: string;
  threadId?: string;
}

// ---------------------------------------------------------------------------
// Streaming
// ---------------------------------------------------------------------------

export type StreamPhase = "streaming" | "done" | "error";

/** Gateway -> App: streaming text delta */
export interface MessageStream extends BaseMessage {
  type: "message.stream";
  agentId?: string;
  delta: string;
  phase: StreamPhase;
  /** Full text for reconciliation (present when phase is "done") */
  finalText?: string;
}

// ---------------------------------------------------------------------------
// Reasoning (chain-of-thought)
// ---------------------------------------------------------------------------

export type ReasoningPhase = "streaming" | "done";

/** Gateway -> App: reasoning / thinking block */
export interface MessageReasoning extends BaseMessage {
  type: "message.reasoning";
  agentId: string;
  text: string;
  phase: ReasoningPhase;
}

// ---------------------------------------------------------------------------
// Tool execution events
// ---------------------------------------------------------------------------

export type ToolPhase = "start" | "progress" | "result" | "error";

/** Gateway -> App: tool execution lifecycle event */
export interface ToolEvent extends BaseMessage {
  type: "tool.event";
  agentId: string;
  /** Tool name (e.g. exec, read, write, edit) */
  tool: string;
  phase: ToolPhase;
  /** Human-readable status label */
  label?: string;
  /** Tool input parameters (phase: start) */
  input?: Record<string, unknown>;
  /** Progress info (phase: progress) */
  progress?: Record<string, unknown>;
  /** Tool output (phase: result) */
  result?: Record<string, unknown>;
  /** Error info (phase: error) */
  error?: Record<string, unknown>;
}

// ---------------------------------------------------------------------------
// Union
// ---------------------------------------------------------------------------

export type MessagingMessage =
  | MessageInbound
  | MessageOutbound
  | MessageStream
  | MessageReasoning
  | ToolEvent;
