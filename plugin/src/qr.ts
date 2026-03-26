/**
 * QR code generation for ClawChat pairing.
 *
 * - ASCII: qrcode-terminal (for CLI / terminal contexts)
 * - PNG data URI: qrcode (for channel contexts where ASCII renders poorly)
 *
 * Deep link format: clawchat://pair?relay=<url>&code=<code>
 */

import qrcode from "qrcode-terminal";
import QRCode from "qrcode";

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

/** Generate a QR code PNG as a data URI (base64). */
export async function renderQrDataUri(data: string): Promise<string> {
  return QRCode.toDataURL(data, { width: 400, margin: 2 });
}
