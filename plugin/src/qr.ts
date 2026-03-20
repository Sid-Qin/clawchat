/**
 * Minimal QR code generator for terminal output.
 * No external dependencies — uses a pure-JS QR encoder.
 *
 * Deep link format: clawchat://pair?relay=<url>&code=<code>
 */

// ---------------------------------------------------------------------------
// QR Code Encoding (ISO 18004, Byte mode, ECC-L, auto version 1-10)
// Based on simplified QR spec — sufficient for short URLs
// ---------------------------------------------------------------------------

const EC_L = 1;

// Error correction codewords per version (L level)
const EC_CODEWORDS: number[] = [
  0, 7, 10, 15, 20, 26, 18, 20, 24, 30, 18,
];

// Data capacity (bytes, L level) per version 1–10
const DATA_CAPACITY: number[] = [
  0, 17, 32, 53, 78, 106, 134, 154, 192, 230, 271,
];

function chooseVersion(dataLen: number): number {
  // Byte mode overhead: 4 (mode) + 8 (count) = 12 bits → need dataLen + 2 bytes approx
  const needed = dataLen + 3; // mode indicator + count + data
  for (let v = 1; v <= 10; v++) {
    if (DATA_CAPACITY[v] >= needed) return v;
  }
  return 10; // fallback
}

// GF(256) math for Reed-Solomon
const GF_EXP = new Uint8Array(512);
const GF_LOG = new Uint8Array(256);
(() => {
  let x = 1;
  for (let i = 0; i < 255; i++) {
    GF_EXP[i] = x;
    GF_LOG[x] = i;
    x = (x << 1) ^ (x & 128 ? 0x11d : 0);
  }
  for (let i = 255; i < 512; i++) GF_EXP[i] = GF_EXP[i - 255];
})();

function gfMul(a: number, b: number): number {
  if (a === 0 || b === 0) return 0;
  return GF_EXP[GF_LOG[a] + GF_LOG[b]];
}

function rsEncode(data: number[], ecCount: number): number[] {
  // Build generator polynomial
  const gen = [1];
  for (let i = 0; i < ecCount; i++) {
    const newGen = new Array(gen.length + 1).fill(0);
    for (let j = 0; j < gen.length; j++) {
      newGen[j] ^= gen[j];
      newGen[j + 1] ^= gfMul(gen[j], GF_EXP[i]);
    }
    gen.length = 0;
    gen.push(...newGen);
  }

  const msg = [...data, ...new Array(ecCount).fill(0)];
  for (let i = 0; i < data.length; i++) {
    const coef = msg[i];
    if (coef !== 0) {
      for (let j = 1; j < gen.length; j++) {
        msg[i + j] ^= gfMul(gen[j], coef);
      }
    }
  }
  return msg.slice(data.length);
}

function getModuleCount(version: number): number {
  return 17 + version * 4;
}

function createMatrix(size: number): number[][] {
  return Array.from({ length: size }, () => new Array(size).fill(-1));
}

function placeFinderPattern(matrix: number[][], row: number, col: number): void {
  for (let r = -1; r <= 7; r++) {
    for (let c = -1; c <= 7; c++) {
      const mr = row + r;
      const mc = col + c;
      if (mr < 0 || mr >= matrix.length || mc < 0 || mc >= matrix.length) continue;
      if (
        (r >= 0 && r <= 6 && (c === 0 || c === 6)) ||
        (c >= 0 && c <= 6 && (r === 0 || r === 6)) ||
        (r >= 2 && r <= 4 && c >= 2 && c <= 4)
      ) {
        matrix[mr][mc] = 1;
      } else {
        matrix[mr][mc] = 0;
      }
    }
  }
}

function placeAlignmentPattern(matrix: number[][], row: number, col: number): void {
  for (let r = -2; r <= 2; r++) {
    for (let c = -2; c <= 2; c++) {
      if (Math.abs(r) === 2 || Math.abs(c) === 2 || (r === 0 && c === 0)) {
        matrix[row + r][col + c] = 1;
      } else {
        matrix[row + r][col + c] = 0;
      }
    }
  }
}

const ALIGNMENT_POSITIONS: number[][] = [
  [], // v0
  [], // v1
  [6, 18], // v2
  [6, 22], // v3
  [6, 26], // v4
  [6, 30], // v5
  [6, 34], // v6
  [6, 22, 38], // v7
  [6, 24, 42], // v8
  [6, 26, 46], // v9
  [6, 28, 50], // v10
];

function placeFixedPatterns(matrix: number[][], version: number): void {
  const size = matrix.length;

  // Finder patterns
  placeFinderPattern(matrix, 0, 0);
  placeFinderPattern(matrix, size - 7, 0);
  placeFinderPattern(matrix, 0, size - 7);

  // Timing patterns
  for (let i = 8; i < size - 8; i++) {
    if (matrix[6][i] === -1) matrix[6][i] = i % 2 === 0 ? 1 : 0;
    if (matrix[i][6] === -1) matrix[i][6] = i % 2 === 0 ? 1 : 0;
  }

  // Dark module
  matrix[size - 8][8] = 1;

  // Alignment patterns
  const positions = ALIGNMENT_POSITIONS[version] ?? [];
  for (const r of positions) {
    for (const c of positions) {
      if (matrix[r][c] === -1) {
        placeAlignmentPattern(matrix, r, c);
      }
    }
  }
}

function reserveFormatArea(matrix: number[][]): void {
  const size = matrix.length;
  // Around top-left finder
  for (let i = 0; i <= 8; i++) {
    if (matrix[8][i] === -1) matrix[8][i] = 0;
    if (matrix[i][8] === -1) matrix[i][8] = 0;
  }
  // Around bottom-left finder
  for (let i = 0; i < 7; i++) {
    if (matrix[size - 1 - i][8] === -1) matrix[size - 1 - i][8] = 0;
  }
  // Around top-right finder
  for (let i = 0; i < 8; i++) {
    if (matrix[8][size - 1 - i] === -1) matrix[8][size - 1 - i] = 0;
  }
}

function encodeData(text: string, version: number): number[] {
  const totalCodewords = DATA_CAPACITY[version] + EC_CODEWORDS[version];
  const bytes = Buffer.from(text, "utf-8");
  const bits: number[] = [];

  // Mode indicator: Byte (0100)
  bits.push(0, 1, 0, 0);

  // Character count (8 bits for versions 1-9, 16 bits for 10+)
  const countBits = version <= 9 ? 8 : 16;
  for (let i = countBits - 1; i >= 0; i--) {
    bits.push((bytes.length >> i) & 1);
  }

  // Data
  for (const b of bytes) {
    for (let i = 7; i >= 0; i--) {
      bits.push((b >> i) & 1);
    }
  }

  // Terminator
  const totalBits = totalCodewords * 8 - EC_CODEWORDS[version] * 8;
  while (bits.length < totalBits && bits.length < totalCodewords * 8) {
    bits.push(0);
  }

  // Pad to byte boundary
  while (bits.length % 8 !== 0) bits.push(0);

  // Convert to bytes
  const dataBytes: number[] = [];
  for (let i = 0; i < bits.length; i += 8) {
    let byte = 0;
    for (let j = 0; j < 8; j++) byte = (byte << 1) | (bits[i + j] || 0);
    dataBytes.push(byte);
  }

  // Pad codewords
  const dataCodewords = totalCodewords - EC_CODEWORDS[version];
  const padPatterns = [0xec, 0x11];
  let padIdx = 0;
  while (dataBytes.length < dataCodewords) {
    dataBytes.push(padPatterns[padIdx % 2]);
    padIdx++;
  }

  // Add error correction
  const ecBytes = rsEncode(dataBytes, EC_CODEWORDS[version]);
  return [...dataBytes, ...ecBytes];
}

function placeData(matrix: number[][], codewords: number[]): void {
  const size = matrix.length;
  let bitIndex = 0;
  const totalBits = codewords.length * 8;

  let col = size - 1;
  let goingUp = true;

  while (col > 0) {
    if (col === 6) col--; // Skip timing column

    const rows = goingUp
      ? Array.from({ length: size }, (_, i) => size - 1 - i)
      : Array.from({ length: size }, (_, i) => i);

    for (const row of rows) {
      for (const dc of [0, -1]) {
        const c = col + dc;
        if (c < 0 || c >= size) continue;
        if (matrix[row][c] !== -1) continue;
        if (bitIndex < totalBits) {
          const byteIdx = Math.floor(bitIndex / 8);
          const bitPos = 7 - (bitIndex % 8);
          matrix[row][c] = (codewords[byteIdx] >> bitPos) & 1;
          bitIndex++;
        } else {
          matrix[row][c] = 0;
        }
      }
    }

    col -= 2;
    goingUp = !goingUp;
  }
}

function applyMask(matrix: number[][], fixed: number[][]): void {
  // Mask pattern 0: (row + col) % 2 == 0
  const size = matrix.length;
  for (let r = 0; r < size; r++) {
    for (let c = 0; c < size; c++) {
      if (fixed[r][c] !== -1) continue;
      if ((r + c) % 2 === 0) {
        matrix[r][c] ^= 1;
      }
    }
  }
}

function placeFormatInfo(matrix: number[][]): void {
  // Format info for ECC L, mask 0: 111011111000100
  const formatBits = [1, 1, 1, 0, 1, 1, 1, 1, 1, 0, 0, 0, 1, 0, 0];
  const size = matrix.length;

  // Horizontal (along row 8)
  const hPositions = [0, 1, 2, 3, 4, 5, 7, 8, size - 8, size - 7, size - 6, size - 5, size - 4, size - 3, size - 2];
  for (let i = 0; i < 15; i++) {
    matrix[8][hPositions[i]] = formatBits[i];
  }

  // Vertical (along col 8)
  const vPositions = [size - 1, size - 2, size - 3, size - 4, size - 5, size - 6, size - 7, 8, 7, 5, 4, 3, 2, 1, 0];
  for (let i = 0; i < 15; i++) {
    matrix[vPositions[i]][8] = formatBits[i];
  }
}

function generateQrMatrix(text: string): boolean[][] {
  const version = chooseVersion(Buffer.byteLength(text, "utf-8"));
  const size = getModuleCount(version);
  const matrix = createMatrix(size);

  // Place fixed patterns and save as template
  placeFixedPatterns(matrix, version);
  reserveFormatArea(matrix);

  // Save fixed pattern locations
  const fixed = matrix.map((row) => [...row]);

  // Encode and place data
  const codewords = encodeData(text, version);
  placeData(matrix, codewords);

  // Apply mask
  applyMask(matrix, fixed);

  // Place format info
  placeFormatInfo(matrix);

  return matrix.map((row) => row.map((cell) => cell === 1));
}

// ---------------------------------------------------------------------------
// Terminal rendering
// ---------------------------------------------------------------------------

function renderQrTerminal(matrix: boolean[][], margin = 2): string {
  const lines: string[] = [];
  const width = matrix.length + margin * 2;

  // Top margin (white)
  for (let i = 0; i < margin; i++) {
    lines.push("█".repeat(width));
  }

  // Use Unicode half-block characters for compact rendering
  // ▀ = top half dark, bottom half light
  // ▄ = top half light, bottom half dark
  // █ = both light (white in inverted)
  //   = both dark (black in inverted)
  // In QR: dark = module on, but terminals have dark bg, so invert:
  // dark module → space (black), light → █ (white)

  for (let r = 0; r < matrix.length; r += 2) {
    let line = "";
    for (let m = 0; m < margin; m++) line += "█";
    for (let c = 0; c < matrix.length; c++) {
      const top = matrix[r][c];
      const bottom = r + 1 < matrix.length ? matrix[r + 1][c] : false;
      if (!top && !bottom) line += "█"; // both white
      else if (top && bottom) line += " "; // both black
      else if (top && !bottom) line += "▄"; // top black, bottom white
      else line += "▀"; // top white, bottom black
    }
    for (let m = 0; m < margin; m++) line += "█";
    lines.push(line);
  }

  // Bottom margin
  for (let i = 0; i < margin; i++) {
    lines.push("█".repeat(width));
  }

  return lines.join("\n");
}

// ---------------------------------------------------------------------------
// Public API
// ---------------------------------------------------------------------------

export function buildDeepLink(relayUrl: string, code: string): string {
  const cleanCode = code.replace(/-/g, "");
  return `clawchat://pair?relay=${encodeURIComponent(relayUrl)}&code=${cleanCode}`;
}

export function generatePairingQR(relayUrl: string, displayCode: string): string {
  const deepLink = buildDeepLink(relayUrl, displayCode);
  const matrix = generateQrMatrix(deepLink);
  return renderQrTerminal(matrix);
}

export function formatPairingBlock(relayUrl: string, displayCode: string, expiresAt: number): string {
  const qr = generatePairingQR(relayUrl, displayCode);
  const expires = new Date(expiresAt).toLocaleTimeString();

  return [
    "",
    "  ┌─────────────────────────────────────┐",
    "  │       ClawChat — Scan to Pair        │",
    "  └─────────────────────────────────────┘",
    "",
    qr,
    "",
    `  Pairing Code : ${displayCode}`,
    `  Relay        : ${relayUrl}`,
    `  Expires      : ${expires}`,
    "",
    "  Scan the QR code with ClawChat app,",
    "  or enter the code manually.",
    "",
  ].join("\n");
}
