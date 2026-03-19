/**
 * ClawChat — OpenClaw plugin
 *
 * Bridges paired iOS/Android apps to your OpenClaw agent via the ClawChat relay.
 *
 * Install:
 *   openclaw plugins install clawchat-openclaw
 *
 * Configure in ~/.openclaw/openclaw.json (or yaml):
 *   plugins:
 *     entries:
 *       clawchat:
 *         enabled: true
 *         config:
 *           token: <your-relay-gateway-token>
 *           relay: wss://clawchat-production-db31.up.railway.app   # optional
 *           session: clawchat                                        # optional
 *
 * Commands:
 *   /clawchat pair    — generate a pairing code for the mobile app
 */

import { setClawChatRuntime } from "./runtime.js";
import { startClawChatGateway } from "./gateway.js";
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

export default function register(api: any) {
  setClawChatRuntime(api.runtime);

  const account = resolveAccount(api);

  if (!account.token) {
    api.logger.warn?.("clawchat: no token configured, skipping relay connection");
    return;
  }

  // Start relay connection as a service
  const ac = new AbortController();
  const log = {
    info: (msg: string) => api.logger.info?.(msg),
    warn: (msg: string) => api.logger.warn?.(msg),
    error: (msg: string) => api.logger.error?.(msg),
  };

  api.registerService({
    id: "clawchat-relay",
    start: async () => {
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
        return handlePairCommand(ctx, account);
      }

      return {
        text: "Usage: `/clawchat pair` — generate a pairing code for the ClawChat app.",
      };
    },
  });
}
