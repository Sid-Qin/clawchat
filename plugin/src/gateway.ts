/**
 * Gateway — connects to the ClawChat relay and bridges inbound messages
 * directly to the OpenClaw agent via dispatchReplyWithBufferedBlockDispatcher.
 *
 * No internal WebSocket to the OpenClaw gateway is needed — the plugin runs
 * inside the gateway process and calls the agent runtime directly.
 */

import crypto from "node:crypto";
import { getClawChatRuntime } from "./runtime.js";
import { buildDeepLink, renderQrAscii } from "./qr.js";
import type { ClawChatAccount } from "./types.js";

const CHANNEL_ID = "clawchat";
const PAIRING_REFRESH_INTERVAL = 4 * 60 * 1000;
const PING_INTERVAL = 25_000;
const PONG_TIMEOUT = 10_000;

type GatewayCtx = {
  cfg: unknown;
  accountId: string;
  account: ClawChatAccount;
  abortSignal: AbortSignal;
  log?: {
    info?: (msg: string) => void;
    warn?: (msg: string) => void;
    error?: (msg: string) => void;
  };
};

/**
 * Build agent descriptors from OpenClaw config.
 * Descriptor format: id::name::model::model1|model2
 */
function buildAgentDescriptors(cfg: any): { agents: string[]; agentsMeta: Record<string, any> } {
  const agentList = cfg?.agents?.list;
  const defaults = cfg?.agents?.defaults ?? {};
  const defaultModel = typeof defaults.model === "string"
    ? defaults.model
    : defaults.model?.primary ?? "default";

  // If no agents configured, create a default one
  if (!Array.isArray(agentList) || agentList.length === 0) {
    const name = defaults.identity?.name ?? "Agent";
    const desc = `default::${name}::${defaultModel}::${defaultModel}`;
    return {
      agents: [desc],
      agentsMeta: { [desc]: { name, model: defaultModel } },
    };
  }

  const agents: string[] = [];
  const agentsMeta: Record<string, any> = {};

  for (const entry of agentList) {
    if (!entry || typeof entry !== "object") continue;
    const id = entry.id ?? "default";
    const name = entry.identity?.name ?? entry.name ?? id;
    const model = typeof entry.model === "string"
      ? entry.model
      : entry.model?.primary ?? defaultModel;
    const fallbacks = entry.model?.fallbacks ?? defaults.model?.fallbacks ?? [];
    const allModels = [model, ...fallbacks].filter(Boolean);
    const desc = `${id}::${name}::${model}::${allModels.join("|")}`;
    agents.push(desc);
    agentsMeta[desc] = { name, model };
  }

  return { agents, agentsMeta };
}

// Shared reference to the relay send function so hooks can emit tool events
let relaySend: ((msg: unknown) => void) | null = null;
let relayIsReady = false;

export function getRelaySend(): ((msg: unknown) => void) | null {
  return relayIsReady ? relaySend : null;
}

export async function startClawChatGateway(ctx: GatewayCtx): Promise<void> {
  const { account, abortSignal, log } = ctx;
  const { relay: relayUrl, token: gatewayToken, session: sessionKey } = account;

  const gatewayId = `gw-${crypto.createHash("sha256").update(gatewayToken).digest("hex").slice(0, 12)}`;
  const { agents, agentsMeta } = buildAgentDescriptors(ctx.cfg);

  log?.info?.(`[clawchat] Starting gateway accountId=${ctx.accountId} relay=${relayUrl} agents=${agents.length}`);

  let relayWs: WebSocket | null = null;
  let relayReady = false;
  let pairingTimer: ReturnType<typeof setInterval> | null = null;
  let pingTimer: ReturnType<typeof setInterval> | null = null;
  let pongTimer: ReturnType<typeof setTimeout> | null = null;

  // ------------------------------------------------------------------
  // Relay connection
  // ------------------------------------------------------------------

  function connect() {
    log?.info?.(`[clawchat] Connecting to relay ${relayUrl}`);
    relayWs = new WebSocket(`${relayUrl}/ws/gateway`);

    relayWs.addEventListener("open", () => {
      log?.info?.("[clawchat] Relay WS open, registering...");
      send({
        type: "gateway.register",
        id: crypto.randomUUID(),
        ts: Date.now(),
        token: gatewayToken,
        gatewayId,
        protocolVersion: "0.1.0",
        version: "0.1.0",
        agents,
        agentsMeta,
      });
      startPing();
    });

    relayWs.addEventListener("message", (event) => {
      try {
        const msg = JSON.parse(event.data as string);
        if (msg.type === "pong") {
          clearPongTimeout();
          return;
        }
        handleMessage(msg);
      } catch {
        log?.warn?.("[clawchat] Failed to parse relay message");
      }
    });

    relayWs.addEventListener("close", () => {
      log?.info?.("[clawchat] Relay disconnected");
      relayReady = false;
      relayIsReady = false;
      stopPing();
      stopPairingRefresh();
      if (!abortSignal.aborted) setTimeout(connect, 5000);
    });

    relayWs.addEventListener("error", () => {
      log?.error?.("[clawchat] Relay WS error");
    });

    abortSignal.addEventListener("abort", () => relayWs?.close(), { once: true });
  }

  function send(msg: unknown) {
    if (relayWs?.readyState === WebSocket.OPEN) {
      relayWs.send(JSON.stringify(msg));
    }
  }

  // Expose send for tool hooks
  relaySend = send;

  // ------------------------------------------------------------------
  // Relay message handling
  // ------------------------------------------------------------------

  function handleMessage(msg: any) {
    switch (msg.type) {
      case "gateway.registered":
        log?.info?.(`[clawchat] Registered. Paired devices: ${msg.pairedDevices}`);
        relayReady = true;
        relayIsReady = true;
        requestPairingCode();
        startPairingRefresh();
        break;

      case "pair.code":
        log?.info?.(`[clawchat] Pairing code: ${msg.code} (expires ${new Date(msg.expiresAt).toLocaleTimeString()})`);
        break;

      case "app.paired":
      case "app.connected":
        log?.info?.(`[clawchat] Device ${msg.type}`);
        // Push latest agents to newly connected app
        send({
          type: "status.response",
          id: crypto.randomUUID(),
          ts: Date.now(),
          gatewayOnline: true,
          connectedDevices: 1,
          agents,
          agentsMeta,
        });
        break;

      case "status.request":
        send({
          type: "status.response",
          id: msg.id ?? crypto.randomUUID(),
          ts: Date.now(),
          gatewayOnline: true,
          connectedDevices: 1,
          agents,
          agentsMeta,
        });
        break;

      case "message.inbound":
        void handleInbound(msg);
        break;
    }
  }

  // ------------------------------------------------------------------
  // Inbound: relay → agent (direct runtime call, no WebSocket)
  // ------------------------------------------------------------------

  async function handleInbound(msg: any) {
    log?.info?.(`[clawchat] handleInbound: text="${(msg.text || "").slice(0, 50)}" from=${msg.deviceId ?? msg.from ?? "?"}`);
    const rt = getClawChatRuntime();

    send({ type: "typing", id: crypto.randomUUID(), ts: Date.now(), active: true });

    const relayMessageId = crypto.randomUUID();
    const senderId = msg.deviceId ?? msg.from ?? "app";

    const msgCtx = rt.channel.reply.finalizeInboundContext({
      Body: msg.text || "",
      RawBody: msg.text || "",
      CommandBody: msg.text || "",
      From: `${CHANNEL_ID}:${senderId}`,
      To: `${CHANNEL_ID}:${senderId}`,
      SessionKey: sessionKey,
      AccountId: ctx.accountId,
      OriginatingChannel: CHANNEL_ID,
      OriginatingTo: `${CHANNEL_ID}:${senderId}`,
      ChatType: "direct",
      SenderId: senderId,
      Provider: CHANNEL_ID,
      Surface: CHANNEL_ID,
      Timestamp: Date.now(),
      CommandAuthorized: true,
    });

    const cfg = await rt.config.loadConfig();

    try {
      await rt.channel.reply.dispatchReplyWithBufferedBlockDispatcher({
        ctx: msgCtx,
        cfg,
        dispatcherOptions: {
          deliver: async (payload: any, info: any) => {
            const text: string | undefined = payload?.text ?? payload?.body;
            if (!relayReady) return;

            // Tool text output is still delivered here as part of the message stream.
            // Tool lifecycle events (start/result) are handled by hooks separately.
            if (!text) return;

            // Send streaming first to create the message, then done to finalize
            send({
              type: "message.stream",
              id: relayMessageId,
              ts: Date.now(),
              delta: text,
              phase: "streaming",
            });
            send({
              type: "message.stream",
              id: relayMessageId,
              ts: Date.now(),
              delta: "",
              phase: "done",
              finalText: text,
            });
          },
          onReplyStart: () => {
            log?.info?.("[clawchat] Agent reply starting");
          },
          onError: (err: unknown) => {
            log?.error?.(`[clawchat] Dispatch error: ${String((err as Error)?.message ?? err)}`);
          },
        },
      });
      log?.info?.("[clawchat] dispatch completed");
    } catch (err) {
      log?.error?.(`[clawchat] Failed to dispatch inbound: ${String((err as Error)?.message ?? err)}`);
      if (relayReady) {
        send({ type: "message.stream", id: relayMessageId, ts: Date.now(), delta: "", phase: "done", finalText: "Sorry, something went wrong." });
      }
    }
  }

  // ------------------------------------------------------------------
  // Helpers
  // ------------------------------------------------------------------

  function startPing() {
    stopPing();
    pingTimer = setInterval(() => {
      if (relayWs?.readyState === WebSocket.OPEN) {
        send({ type: "ping", id: crypto.randomUUID(), ts: Date.now() });
        pongTimer = setTimeout(() => {
          log?.warn?.("[clawchat] Pong timeout, reconnecting...");
          relayWs?.close();
        }, PONG_TIMEOUT);
      }
    }, PING_INTERVAL);
  }

  function stopPing() {
    if (pingTimer) { clearInterval(pingTimer); pingTimer = null; }
    clearPongTimeout();
  }

  function clearPongTimeout() {
    if (pongTimer) { clearTimeout(pongTimer); pongTimer = null; }
  }

  function requestPairingCode() {
    send({ type: "pair.generate", id: crypto.randomUUID(), ts: Date.now() });
  }

  function startPairingRefresh() {
    stopPairingRefresh();
    pairingTimer = setInterval(() => {
      if (relayWs?.readyState === WebSocket.OPEN) requestPairingCode();
    }, PAIRING_REFRESH_INTERVAL);
  }

  function stopPairingRefresh() {
    if (pairingTimer) { clearInterval(pairingTimer); pairingTimer = null; }
  }

  abortSignal.addEventListener("abort", () => { stopPairingRefresh(); stopPing(); }, { once: true });

  connect();

  await new Promise<void>((resolve) => {
    abortSignal.addEventListener("abort", () => resolve(), { once: true });
  });
}
