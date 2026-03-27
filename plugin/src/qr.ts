/**
 * QR code generation for ClawChat pairing.
 * Uses qrcode-terminal (available via openclaw peer dependency).
 *
 * Deep link format: clawchat://pair?relay=<url>&code=<code>
 */

import qrcode from "qrcode-terminal";

export function buildDeepLink(relayUrl: string, code: string): string {
  const cleanCode = code.replace(/-/g, "");
  return `clawchat://pair?relay=${encodeURIComponent(relayUrl)}&code=${cleanCode}`;
}

export function renderQrAscii(data: string): Promise<string> {
  return new Promise((resolve) => {
    qrcode.generate(data, { small: true }, (output: string) => {
      resolve(output);
    });
  });
}
