/**
 * /clawchat pair — fetch a pairing code from the relay via HTTP and return
 * an ASCII QR code in the chat response (same pattern as device-pair plugin).
 */

import type { ClawChatAccount } from "./types.js";
import { buildDeepLink, renderQrAscii } from "./qr.js";

export async function handlePairCommand(
  ctx: unknown,
  account: ClawChatAccount,
): Promise<{ text: string }> {
  const httpUrl = account.relay
    .replace(/^wss:\/\//, "https://")
    .replace(/^ws:\/\//, "http://");

  let data: { code: string; expiresAt: string };
  try {
    const res = await fetch(`${httpUrl}/api/pair/code`, {
      method: "POST",
      headers: { Authorization: `Bearer ${account.token}` },
    });
    if (!res.ok) {
      const body = await res.text().catch(() => "");
      return { text: `Failed to get pairing code (${res.status}): ${body}` };
    }
    data = await res.json() as { code: string; expiresAt: string };
  } catch (err) {
    return { text: `Could not reach relay: ${String((err as Error)?.message ?? err)}` };
  }

  const deepLink = buildDeepLink(account.relay, data.code);
  const qrAscii = await renderQrAscii(deepLink);
  const expires = new Date(data.expiresAt).toLocaleTimeString();

  const lines = [
    "Scan this QR code with the ClawChat app:",
    "",
    "```",
    qrAscii,
    "```",
    "",
    `Pairing Code: \`${data.code}\``,
    `Relay: \`${account.relay}\``,
    `Expires: ${expires}`,
  ];

  return { text: lines.join("\n") };
}
