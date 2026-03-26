/**
 * /clawchat pair — fetch a pairing code from the relay via HTTP and return
 * a QR code for pairing.
 *
 * - Terminal / CLI channels → ASCII QR in a code block
 * - Other channels (Lark, web, etc.) → PNG image via mediaUrl
 */

import type { ClawChatAccount } from "./types.js";
import { buildDeepLink, renderQrAscii, renderQrDataUri } from "./qr.js";

export async function handlePairCommand(
  ctx: any,
  account: ClawChatAccount,
): Promise<{ text: string; mediaUrl?: string }> {
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
  const expires = new Date(data.expiresAt).toLocaleTimeString();
  const qrAscii = await renderQrAscii(deepLink);

  const text = [
    "Scan this QR code with the ClawChat app:",
    "",
    "```",
    qrAscii,
    "```",
    "",
    `Pairing Code: \`${data.code}\``,
    `Relay: \`${account.relay}\``,
    `Expires: ${expires}`,
  ].join("\n");

  // Also generate a PNG image as data URI for channels that support it (e.g. Lark).
  // Channels that don't support mediaUrl will just show the ASCII QR above.
  let mediaUrl: string | undefined;
  try {
    mediaUrl = await renderQrDataUri(deepLink);
  } catch {
    // Ignore — ASCII fallback is always present
  }

  return { text, mediaUrl };
}
