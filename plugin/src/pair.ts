/**
 * /clawchat pair — fetch a pairing code from the relay via HTTP and return it.
 *
 * The relay exposes POST /api/pair/code (Bearer <gateway-token>).
 * Returns the 6-char display code (XXX-XXX) + relay URL for the user to
 * enter in the ClawChat iOS/Android app. Also prints QR code to terminal.
 */

import type { ClawChatAccount } from "./types.js";
import { formatPairingBlock } from "./qr.js";

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

  // Print QR code to terminal
  const expiresAtMs = new Date(data.expiresAt).getTime();
  const block = formatPairingBlock(account.relay, data.code, expiresAtMs);
  console.log(block);

  const expires = new Date(data.expiresAt).toLocaleTimeString();
  const lines = [
    "**ClawChat Pairing Code**",
    "",
    `\`${data.code}\``,
    "",
    `Relay: \`${account.relay}\``,
    `Expires: ${expires}`,
    "",
    "Scan the QR code in the terminal with ClawChat app,",
    "or enter the relay URL and code manually.",
  ];

  return { text: lines.join("\n") };
}
