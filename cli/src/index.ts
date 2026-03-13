#!/usr/bin/env bun
import { hostname } from "node:os";
import { parseArgs } from "node:util";
import type { AppConnected, AppPaired } from "@clawchat/protocol";
import { loadConfig, saveConfig, type Config } from "./config.js";
import { connect } from "./connection.js";
import { pairWithCode, reconnectWithToken } from "./pairing.js";
import { startChat, type ChatHandle } from "./chat.js";

// ANSI helpers
const RED = "\x1b[31m";
const YELLOW = "\x1b[33m";
const GREEN = "\x1b[32m";
const RESET = "\x1b[0m";

const USAGE = `
${YELLOW}ClawChat CLI${RESET} — reference client for the ClawChat relay protocol

${GREEN}Usage:${RESET}
  clawchat --relay <url> --code <pairing-code>   First-time pairing
  clawchat --relay <url>                          Reconnect (if token stored)
  clawchat                                        Reconnect using saved config

${GREEN}Options:${RESET}
  --relay <url>       Relay WebSocket URL (e.g. wss://relay.clawchat.dev)
  --code <code>       Pairing code from your gateway
  --agent <agentId>   Agent to chat with (default: "default")
  --help              Show this help message
`;

function printUsage(): void {
  process.stdout.write(USAGE);
}

async function main(): Promise<void> {
  const { values } = parseArgs({
    options: {
      relay: { type: "string" },
      code: { type: "string" },
      agent: { type: "string", default: "default" },
      help: { type: "boolean", default: false },
    },
    strict: true,
  });

  if (values.help) {
    printUsage();
    process.exit(0);
  }

  const savedConfig = loadConfig();
  const relayUrl = values.relay ?? savedConfig?.relayUrl;
  const pairingCode = values.code;
  const agentId = values.agent!;
  const deviceName = hostname();

  // Must have relay URL from args or saved config
  if (!relayUrl) {
    process.stderr.write(`${RED}No relay URL provided and no saved config found.${RESET}\n\n`);
    printUsage();
    process.exit(1);
  }

  // Must have either a pairing code or a saved device token
  if (!pairingCode && !savedConfig?.deviceToken) {
    process.stderr.write(
      `${RED}No pairing code provided and no saved device token.${RESET}\n` +
        `Use --code <pairing-code> for first-time setup.\n\n`,
    );
    process.exit(1);
  }

  // Ensure the relay URL ends with /ws/app
  const wsUrl = relayUrl.replace(/\/+$/, "") + "/ws/app";
  process.stdout.write(`Connecting to ${wsUrl}...\n`);

  let chat: ChatHandle | null = null;
  let authenticated = false;

  const conn = connect(
    wsUrl,
    // onMessage — route to chat UI after authentication
    (msg) => {
      if (chat) chat.onMessage(msg);
    },
    // onOpen
    async () => {
      try {
        if (!authenticated) {
          // First connection — authenticate
          let gatewayId: string;

          if (pairingCode) {
            const result = await pairWithCode(conn.ws, pairingCode, deviceName);
            if (!result) {
              conn.close();
              process.exit(1);
            }
            const paired = result as AppPaired;
            gatewayId = paired.gatewayId;

            const config: Config = {
              relayUrl,
              deviceToken: paired.deviceToken,
              deviceName,
            };
            saveConfig(config);
            process.stdout.write(`${GREEN}Paired successfully. Config saved.${RESET}\n`);
          } else {
            const result = await reconnectWithToken(conn.ws, savedConfig!.deviceToken);
            if (!result) {
              conn.close();
              process.exit(1);
            }
            const connected = result as AppConnected;
            gatewayId = connected.gatewayId;

            if (!connected.gatewayOnline) {
              process.stdout.write(
                `${YELLOW}Gateway is offline. Messages will be queued.${RESET}\n`,
              );
            }
          }

          authenticated = true;
          chat = startChat({ ws: conn.ws, agentId, gatewayId });

          // When chat ends (user closes readline), tear down
          chat.done.then(() => {
            conn.close();
            process.exit(0);
          });
        } else if (chat) {
          // Reconnected after a drop — re-authenticate silently
          if (savedConfig?.deviceToken) {
            const result = await reconnectWithToken(conn.ws, savedConfig.deviceToken);
            if (result) {
              chat.onReconnect();
            }
          }
        }
      } catch (err) {
        process.stderr.write(
          `${RED}Error: ${err instanceof Error ? err.message : String(err)}${RESET}\n`,
        );
        conn.close();
        process.exit(1);
      }
    },
    // onClose
    () => {
      if (chat) chat.onDisconnect();
    },
  );

  // Clean Ctrl+C handling
  process.on("SIGINT", () => {
    process.stdout.write("\n");
    if (chat) chat.close();
    conn.close();
    process.exit(0);
  });

  // Keep process alive — readline keeps the event loop running,
  // but before chat starts we need to wait for WebSocket events.
  // The process will exit via chat.done or SIGINT handler above.
}

main().catch((err) => {
  process.stderr.write(
    `${RED}Fatal: ${err instanceof Error ? err.message : String(err)}${RESET}\n`,
  );
  process.exit(1);
});
