import { createInterface, type Interface as ReadlineInterface } from "node:readline";
import type {
  BaseMessage,
  MessageInbound,
  MessageOutbound,
  MessageStream,
  MessageReasoning,
  ToolEvent,
  Typing,
  ErrorMessage,
} from "@clawchat/protocol";
import { send } from "./connection.js";

// ANSI helpers
const DIM = "\x1b[2m";
const RESET = "\x1b[0m";
const GREEN = "\x1b[32m";
const CYAN = "\x1b[36m";
const RED = "\x1b[31m";
const YELLOW = "\x1b[33m";

// Erase current line and move cursor to start
const CLEAR_LINE = "\x1b[2K\r";

export interface ChatOptions {
  ws: WebSocket;
  agentId: string;
  gatewayId: string;
}

export interface ChatHandle {
  /** Feed an incoming protocol message into the chat UI */
  onMessage(msg: BaseMessage): void;
  /** Notify the chat UI that the connection dropped */
  onDisconnect(): void;
  /** Notify the chat UI that the connection was restored */
  onReconnect(): void;
  /** Close readline and resolve the chat promise */
  close(): void;
  /** The promise that resolves when the user exits */
  done: Promise<void>;
}

/**
 * Start the interactive chat loop.
 * Returns a handle with callbacks for wiring to the connection layer.
 */
export function startChat(opts: ChatOptions): ChatHandle {
  const { ws, agentId, gatewayId } = opts;

  let typingVisible = false;
  let isStreaming = false;
  let isReasoning = false;

  const rl = createInterface({
    input: process.stdin,
    output: process.stdout,
    prompt: `${CYAN}> ${RESET}`,
  });

  function showPrompt(): void {
    if (!isStreaming && !isReasoning) {
      rl.prompt();
    }
  }

  function clearTypingIndicator(): void {
    if (typingVisible) {
      process.stdout.write(CLEAR_LINE);
      typingVisible = false;
    }
  }

  // --- Message handlers ---

  function handleOutbound(msg: MessageOutbound): void {
    clearTypingIndicator();
    isStreaming = false;

    const content = msg.content;
    if (content.type === "text") {
      process.stdout.write(`\n${content.text}\n\n`);
    } else if (content.type === "media") {
      const label = content.caption ?? content.filename ?? content.url;
      process.stdout.write(`\n${CYAN}[${content.mediaType}] ${label}${RESET}\n\n`);
    } else if (content.type === "card") {
      process.stdout.write(`\n${CYAN}${content.title}${RESET}\n${content.body}\n\n`);
    } else if (content.type === "poll") {
      process.stdout.write(`\n${CYAN}${content.question}${RESET}\n`);
      for (const opt of content.options) {
        process.stdout.write(`  - ${opt.text}\n`);
      }
      process.stdout.write("\n");
    }
    showPrompt();
  }

  function handleStream(msg: MessageStream): void {
    clearTypingIndicator();

    if (msg.phase === "streaming") {
      if (!isStreaming) {
        isStreaming = true;
        process.stdout.write("\n");
      }
      process.stdout.write(msg.delta);
    } else if (msg.phase === "done") {
      if (msg.finalText && !isStreaming) {
        // If we missed streaming frames, print the full text
        process.stdout.write(`\n${msg.finalText}`);
      }
      isStreaming = false;
      process.stdout.write("\n\n");
      showPrompt();
    } else if (msg.phase === "error") {
      isStreaming = false;
      process.stdout.write(`\n${RED}Stream error${RESET}\n\n`);
      showPrompt();
    }
  }

  function handleReasoning(msg: MessageReasoning): void {
    clearTypingIndicator();

    if (msg.phase === "streaming") {
      if (!isReasoning) {
        isReasoning = true;
        process.stdout.write(`\n${DIM}`);
      }
      process.stdout.write(msg.text);
    } else if (msg.phase === "done") {
      if (isReasoning) {
        process.stdout.write(`${RESET}\n`);
      }
      isReasoning = false;
    }
  }

  function handleToolEvent(msg: ToolEvent): void {
    clearTypingIndicator();

    const label = msg.label ?? msg.tool;
    switch (msg.phase) {
      case "start":
        process.stdout.write(`${YELLOW}> ${label}${RESET}\n`);
        break;
      case "progress":
        process.stdout.write(`${YELLOW}  ... ${label}${RESET}\n`);
        break;
      case "result":
        process.stdout.write(`${GREEN}< ${label}${RESET}\n`);
        break;
      case "error":
        process.stdout.write(`${RED}! ${label}${RESET}\n`);
        break;
    }
  }

  function handleTyping(msg: Typing): void {
    if (msg.active) {
      if (!isStreaming && !isReasoning) {
        clearTypingIndicator();
        const label = msg.label ?? "Agent is typing...";
        process.stdout.write(`${DIM}${label}${RESET}`);
        typingVisible = true;
      }
    } else {
      clearTypingIndicator();
    }
  }

  function handleError(msg: ErrorMessage): void {
    clearTypingIndicator();
    process.stdout.write(`\n${RED}Error [${msg.code}]: ${msg.message}${RESET}\n\n`);
    showPrompt();
  }

  function onMessage(msg: BaseMessage): void {
    switch (msg.type) {
      case "message.outbound":
        handleOutbound(msg as MessageOutbound);
        break;
      case "message.stream":
        handleStream(msg as MessageStream);
        break;
      case "message.reasoning":
        handleReasoning(msg as MessageReasoning);
        break;
      case "tool.event":
        handleToolEvent(msg as ToolEvent);
        break;
      case "typing":
        handleTyping(msg as Typing);
        break;
      case "error":
        handleError(msg as ErrorMessage);
        break;
      default:
        break;
    }
  }

  // --- Initialize UI ---
  process.stdout.write(`${GREEN}Connected to gateway ${gatewayId}${RESET}\n\n`);
  rl.prompt();

  rl.on("line", (line) => {
    const text = line.trim();
    if (!text) {
      showPrompt();
      return;
    }

    const inbound: MessageInbound = {
      type: "message.inbound",
      id: crypto.randomUUID(),
      ts: Date.now(),
      agentId,
      text,
    };
    send(ws, inbound);
  });

  const done = new Promise<void>((resolve) => {
    rl.on("close", () => resolve());
  });

  return {
    onMessage,
    onDisconnect() {
      clearTypingIndicator();
      process.stdout.write(`\n${YELLOW}Disconnected. Reconnecting...${RESET}\n`);
    },
    onReconnect() {
      process.stdout.write(`${GREEN}Reconnected.${RESET}\n`);
      showPrompt();
    },
    close() {
      rl.close();
    },
    done,
  };
}
