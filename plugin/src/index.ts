/**
 * ClawChat — OpenClaw plugin
 *
 * Bridges paired iOS/Android apps to your OpenClaw agent via the ClawChat relay.
 *
 * Install:
 *   openclaw plugins install @claw-os/clawchat
 *
 * The plugin auto-generates a gateway token on first run and writes it to
 * your config. A pairing QR code is printed to the terminal automatically.
 *
 * Commands:
 *   /clawchat pair    — generate a pairing code for the mobile app
 */

import crypto from "node:crypto";
import { setClawChatRuntime } from "./runtime.js";
import { startClawChatGateway, getRelaySend } from "./gateway.js";
import { handlePairCommand } from "./pair.js";
import type { ClawChatAccount } from "./types.js";

const DEFAULT_RELAY = "wss://clawchat-production-db31.up.railway.app";

function resolveAccount(api: any): ClawChatAccount {
  const cfg = api.pluginConfig ?? {};
  return {
    relay: cfg.relay || DEFAULT_RELAY,
    token: cfg.token || "",
    session: cfg.session || "clawchat",
  };
}

async function ensureToken(api: any): Promise<string> {
  const cfg = api.pluginConfig ?? {};
  if (cfg.token) return cfg.token;

  // Auto-generate a token and persist it
  const token = crypto.randomUUID();
  const rt = api.runtime;

  try {
    const currentConfig = await rt.config.loadConfig();
    const updatedConfig = {
      ...currentConfig,
      plugins: {
        ...currentConfig.plugins,
        entries: {
          ...currentConfig.plugins?.entries,
          "clawchat": {
            ...currentConfig.plugins?.entries?.["clawchat"],
            enabled: true,
            config: {
              ...currentConfig.plugins?.entries?.["clawchat"]?.config,
              token,
            },
          },
        },
      },
    };
    await rt.config.writeConfigFile(updatedConfig);
    api.logger.info?.("[clawchat] Auto-generated gateway token and saved to config");
  } catch (err) {
    api.logger.warn?.(`[clawchat] Failed to save auto-generated token: ${String(err)}`);
  }

  return token;
}

export default function register(api: any) {
  setClawChatRuntime(api.runtime);

  const ac = new AbortController();
  const log = {
    info: (msg: string) => api.logger.info?.(msg),
    warn: (msg: string) => api.logger.warn?.(msg),
    error: (msg: string) => api.logger.error?.(msg),
  };

  // Start relay connection as a service
  api.registerService({
    id: "clawchat-relay",
    start: async () => {
      const token = await ensureToken(api);
      const account: ClawChatAccount = {
        relay: (api.pluginConfig ?? {}).relay || DEFAULT_RELAY,
        token,
        session: (api.pluginConfig ?? {}).session || "clawchat",
      };

      startClawChatGateway({
        cfg: api.config,
        accountId: "default",
        account,
        abortSignal: ac.signal,
        log,
      }).catch((err) => {
        api.logger.error?.(`clawchat: gateway crashed: ${String(err)}`);
      });
    },
    stop: async () => {
      ac.abort();
    },
  });

  // /clawchat pair command
  api.registerCommand({
    name: "clawchat",
    description: "ClawChat mobile pairing and status.",
    acceptsArgs: true,
    handler: async (ctx: any) => {
      const action = ctx.args?.trim().split(/\s+/)[0]?.toLowerCase() ?? "";

      if (action === "pair" || action === "") {
        const account = resolveAccount(api);
        if (!account.token) {
          return { text: "No token configured. Restart the gateway to auto-generate one." };
        }
        return handlePairCommand(ctx, account);
      }

      return {
        text: "Usage: `/clawchat pair` — generate a pairing code for the ClawChat app.",
      };
    },
  });

  // Tool lifecycle hooks — emit tool.event messages to paired apps
  log.info(`[clawchat] api.on available: ${typeof api.on === "function"}`);
  if (typeof api.on === "function") {
    log.info("[clawchat] Registering tool hooks");
    api.on("before_tool_call", (event: any) => {
      log.info(`[clawchat] before_tool_call: ${event.toolName}`);
      const send = getRelaySend();
      if (!send) return;
      send({
        type: "tool.event",
        id: event.toolCallId || crypto.randomUUID(),
        ts: Date.now(),
        tool: event.toolName,
        phase: "start",
        label: event.toolName,
      });
    });

    api.on("after_tool_call", (event: any) => {
      log.info(`[clawchat] after_tool_call: tool=${event.toolName} callId=${event.toolCallId} duration=${event.durationMs}ms error=${event.error ?? "none"}`);
      const send = getRelaySend();
      if (!send) return;

      // Truncate large results for mobile display
      let result = event.error ?? event.result;
      if (typeof result === "object") {
        result = JSON.stringify(result);
      }
      if (typeof result === "string" && result.length > 2000) {
        result = result.slice(0, 2000) + "…";
      }

      send({
        type: "tool.event",
        id: event.toolCallId || crypto.randomUUID(),
        ts: Date.now(),
        tool: event.toolName,
        phase: event.error ? "error" : "result",
        label: event.toolName,
        result,
        durationMs: event.durationMs,
      });
    });
  }
}
