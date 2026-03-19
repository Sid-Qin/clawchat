/**
 * QR code output — generates a terminal-friendly ASCII QR code
 * encoding the ClawChat deep link for mobile app scanning.
 *
 * Deep link format: clawchat://pair?relay=<url>&code=<code>
 */

import qrcode from "qrcode-terminal";

export function printPairingQR(relayUrl: string, displayCode: string, expiresAt: number): void {
  // Build deep link — the app will parse relay + code from the URL
  const deepLink = `clawchat://pair?relay=${encodeURIComponent(relayUrl)}&code=${displayCode.replace("-", "")}`;

  qrcode.generate(deepLink, { small: true }, (qr: string) => {
    console.log("");
    console.log("  ┌─────────────────────────────────────┐");
    console.log("  │       ClawChat — Scan to Pair        │");
    console.log("  └─────────────────────────────────────┘");
    console.log("");
    console.log(qr);
    console.log(`  Pairing Code : ${displayCode}`);
    console.log(`  Expires      : ${new Date(expiresAt).toLocaleTimeString()}`);
    console.log("");
    console.log("  Scan the QR code with ClawChat app,");
    console.log("  or enter the code manually.");
    console.log("");
  });
}
