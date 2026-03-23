import { describe, expect, it } from "bun:test";
import {
  buildReplyStreamMessages,
  buildToolResultEvent,
  buildTypingEvent,
} from "./reply-routing";

describe("reply routing", () => {
  it("includes agentId and sessionKey on stream messages", () => {
    const [streaming, done] = buildReplyStreamMessages({
      relayMessageId: "msg-1",
      text: "hello",
      agentId: "agent-a",
      sessionKey: "session-a",
      ts: 1234,
    });

    expect(streaming).toMatchObject({
      type: "message.stream",
      id: "msg-1",
      agentId: "agent-a",
      sessionKey: "session-a",
      delta: "hello",
      phase: "streaming",
      ts: 1234,
    });
    expect(done).toMatchObject({
      type: "message.stream",
      id: "msg-1",
      agentId: "agent-a",
      sessionKey: "session-a",
      delta: "",
      phase: "done",
      finalText: "hello",
      ts: 1234,
    });
  });

  it("includes route metadata on tool events", () => {
    const tool = buildToolResultEvent({
      text: "done",
      agentId: "agent-a",
      sessionKey: "session-a",
      ts: 2222,
    });

    expect(tool).toMatchObject({
      type: "tool.event",
      agentId: "agent-a",
      sessionKey: "session-a",
      tool: "tool",
      phase: "result",
      label: "Tool",
      result: "done",
      ts: 2222,
    });
  });

  it("preserves agent route when sessionKey is absent", () => {
    const typing = buildTypingEvent({
      active: true,
      agentId: "agent-a",
      ts: 3333,
    });

    expect(typing).toMatchObject({
      type: "typing",
      agentId: "agent-a",
      active: true,
      ts: 3333,
    });
    expect(typing.sessionKey).toBeUndefined();
  });
});
