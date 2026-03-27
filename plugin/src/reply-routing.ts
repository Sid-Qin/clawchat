import crypto from "node:crypto";

type RouteInfo = {
  agentId: string;
  sessionKey?: string;
};

type TimestampedRouteInfo = RouteInfo & {
  ts?: number;
};

type ReplyStreamInput = TimestampedRouteInfo & {
  relayMessageId: string;
  text: string;
};

type TypingInput = TimestampedRouteInfo & {
  active: boolean;
  label?: string;
};

type ToolResultInput = TimestampedRouteInfo & {
  text: string;
};

export function buildTypingEvent(input: TypingInput) {
  return {
    type: "typing" as const,
    id: crypto.randomUUID(),
    ts: input.ts ?? Date.now(),
    agentId: input.agentId,
    sessionKey: input.sessionKey,
    active: input.active,
    label: input.label,
  };
}

export function buildReplyStreamMessages(input: ReplyStreamInput) {
  const ts = input.ts ?? Date.now();

  return [
    {
      type: "message.stream" as const,
      id: input.relayMessageId,
      ts,
      agentId: input.agentId,
      sessionKey: input.sessionKey,
      delta: input.text,
      phase: "streaming" as const,
    },
    {
      type: "message.stream" as const,
      id: input.relayMessageId,
      ts,
      agentId: input.agentId,
      sessionKey: input.sessionKey,
      delta: "",
      phase: "done" as const,
      finalText: input.text,
    },
  ] as const;
}

export function buildToolResultEvent(input: ToolResultInput) {
  return {
    type: "tool.event" as const,
    id: crypto.randomUUID(),
    ts: input.ts ?? Date.now(),
    agentId: input.agentId,
    sessionKey: input.sessionKey,
    tool: "tool",
    phase: "result" as const,
    label: "Tool",
    result: input.text,
  };
}
