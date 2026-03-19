import { Database } from "bun:sqlite";
import { mkdirSync, existsSync } from "node:fs";
import { dirname } from "node:path";
import { createHash } from "node:crypto";

/** SHA-256 hash a string and return hex. */
function sha256(input: string): string {
  return createHash("sha256").update(input).digest("hex");
}

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

export interface GatewayRow {
  gatewayId: string;
  token: string;
  tokenHash: string | null;
  createdAt: number;
}

export interface DeviceRow {
  deviceId: string;
  deviceToken: string;
  deviceName: string;
  platform: string;
  gatewayId: string;
  lastSeen: number;
  createdAt: number;
}

export interface PairingCodeRow {
  code: string;
  gatewayId: string;
  expiresAt: number;
  redeemed: number;
}

// ---------------------------------------------------------------------------
// Store interface
// ---------------------------------------------------------------------------

export interface DbStore {
  /** Register or update a gateway. Returns the row or null if token mismatch. */
  registerGateway(gatewayId: string, token: string): GatewayRow | null;
  /** Find a gateway by its token (plaintext match — for HTTP bearer auth). */
  findGateway(token: string): GatewayRow | null;
  /** Find a gateway by its gatewayId. */
  findGatewayById(gatewayId: string): GatewayRow | null;

  /** Create a new paired device. */
  createDevice(device: Omit<DeviceRow, "lastSeen" | "createdAt">): DeviceRow;
  /** Find a device by its long-lived token. */
  findDeviceByToken(deviceToken: string): DeviceRow | null;
  /** List all devices paired to a gateway. */
  listDevicesByGateway(gatewayId: string): DeviceRow[];
  /** Revoke (delete) a device. Returns true if a row was deleted. */
  revokeDevice(deviceId: string): boolean;
  /** Touch the lastSeen timestamp for a device. */
  touchDevice(deviceId: string): void;
  /** Update a device's token. Returns the new token. */
  updateDeviceToken(deviceId: string, newToken: string): void;
  /** Count devices paired to a gateway. */
  countDevicesByGateway(gatewayId: string): number;

  /** Create a pairing code for a gateway. */
  createPairingCode(code: string, gatewayId: string, expiresAt: number): PairingCodeRow;
  /** Redeem a pairing code. Returns the row if valid, null otherwise. */
  redeemPairingCode(code: string): PairingCodeRow | null;
  /** Delete expired and redeemed codes + expired/delivered offline messages. */
  cleanExpiredCodes(): number;

  /** Queue a message for an offline device. Enforces per-device cap (100). */
  queueOfflineMessage(deviceId: string, payload: string): void;
  /** Get pending offline messages for a device (chronological order). */
  getOfflineMessages(deviceId: string): { id: number; payload: string }[];
  /** Mark offline messages as delivered. */
  markOfflineDelivered(ids: number[]): void;

  /** Close the database connection. */
  close(): void;
}

// ---------------------------------------------------------------------------
// Implementation
// ---------------------------------------------------------------------------

export function createDb(path: string): DbStore {
  const dir = dirname(path);
  if (!existsSync(dir)) {
    mkdirSync(dir, { recursive: true });
  }
  const db = new Database(path);

  // Enable WAL mode for better concurrent read performance
  db.run("PRAGMA journal_mode = WAL");
  db.run("PRAGMA foreign_keys = ON");

  // Create tables
  db.run(`
    CREATE TABLE IF NOT EXISTS gateways (
      gatewayId TEXT PRIMARY KEY,
      token TEXT NOT NULL,
      tokenHash TEXT,
      createdAt INTEGER NOT NULL
    )
  `);

  // Migration: add tokenHash column if not present
  const cols = db.query("PRAGMA table_info(gateways)").all() as { name: string }[];
  if (!cols.some((c) => c.name === "tokenHash")) {
    db.run("ALTER TABLE gateways ADD COLUMN tokenHash TEXT");
  }

  db.run(`
    CREATE TABLE IF NOT EXISTS devices (
      deviceId TEXT PRIMARY KEY,
      deviceToken TEXT NOT NULL UNIQUE,
      deviceName TEXT NOT NULL,
      platform TEXT NOT NULL,
      gatewayId TEXT NOT NULL REFERENCES gateways(gatewayId) ON DELETE CASCADE,
      lastSeen INTEGER NOT NULL,
      createdAt INTEGER NOT NULL
    )
  `);

  db.run(`
    CREATE TABLE IF NOT EXISTS pairing_codes (
      code TEXT PRIMARY KEY,
      gatewayId TEXT NOT NULL REFERENCES gateways(gatewayId) ON DELETE CASCADE,
      expiresAt INTEGER NOT NULL,
      redeemed INTEGER NOT NULL DEFAULT 0
    )
  `);

  db.run(`
    CREATE TABLE IF NOT EXISTS offline_messages (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      deviceId TEXT NOT NULL REFERENCES devices(deviceId) ON DELETE CASCADE,
      payload TEXT NOT NULL,
      createdAt INTEGER NOT NULL,
      delivered INTEGER NOT NULL DEFAULT 0
    )
  `);

  // Prepared statements
  const stmts = {
    insertGateway: db.prepare<GatewayRow, [string, string, string, number]>(
      `INSERT INTO gateways (gatewayId, token, tokenHash, createdAt)
       VALUES (?1, ?2, ?3, ?4)
       RETURNING *`,
    ),
    updateGatewayToken: db.prepare<GatewayRow, [string, string, string]>(
      `UPDATE gateways SET token = ?2, tokenHash = ?3 WHERE gatewayId = ?1
       RETURNING *`,
    ),
    findGatewayByToken: db.prepare<GatewayRow, [string]>(
      "SELECT * FROM gateways WHERE token = ?1 ORDER BY createdAt DESC LIMIT 1",
    ),
    findGatewayById: db.prepare<GatewayRow, [string]>(
      "SELECT * FROM gateways WHERE gatewayId = ?1",
    ),

    insertDevice: db.prepare<DeviceRow, [string, string, string, string, string, number, number]>(
      `INSERT INTO devices (deviceId, deviceToken, deviceName, platform, gatewayId, lastSeen, createdAt)
       VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7)
       RETURNING *`,
    ),
    findDeviceByToken: db.prepare<DeviceRow, [string]>(
      "SELECT * FROM devices WHERE deviceToken = ?1",
    ),
    listDevicesByGateway: db.prepare<DeviceRow, [string]>(
      "SELECT * FROM devices WHERE gatewayId = ?1 ORDER BY createdAt DESC",
    ),
    deleteDevice: db.prepare<void, [string]>(
      "DELETE FROM devices WHERE deviceId = ?1",
    ),
    touchDevice: db.prepare<void, [number, string]>(
      "UPDATE devices SET lastSeen = ?1 WHERE deviceId = ?2",
    ),
    updateDeviceToken: db.prepare<void, [string, string]>(
      "UPDATE devices SET deviceToken = ?1 WHERE deviceId = ?2",
    ),
    countDevicesByGateway: db.prepare<{ c: number }, [string]>(
      "SELECT COUNT(*) as c FROM devices WHERE gatewayId = ?1",
    ),

    insertPairingCode: db.prepare<PairingCodeRow, [string, string, number]>(
      `INSERT INTO pairing_codes (code, gatewayId, expiresAt)
       VALUES (?1, ?2, ?3)
       RETURNING *`,
    ),
    findPairingCode: db.prepare<PairingCodeRow, [string]>(
      "SELECT * FROM pairing_codes WHERE code = ?1",
    ),
    markCodeRedeemed: db.prepare<void, [string]>(
      "UPDATE pairing_codes SET redeemed = 1 WHERE code = ?1",
    ),
    cleanCodes: db.prepare<void, [number]>(
      "DELETE FROM pairing_codes WHERE expiresAt < ?1 OR redeemed = 1",
    ),

    // Offline messages
    insertOfflineMessage: db.prepare<void, [string, string, number]>(
      "INSERT INTO offline_messages (deviceId, payload, createdAt) VALUES (?1, ?2, ?3)",
    ),
    countOfflineByDevice: db.prepare<{ c: number }, [string]>(
      "SELECT COUNT(*) as c FROM offline_messages WHERE deviceId = ?1 AND delivered = 0",
    ),
    deleteOldestOffline: db.prepare<void, [string]>(
      "DELETE FROM offline_messages WHERE id = (SELECT id FROM offline_messages WHERE deviceId = ?1 AND delivered = 0 ORDER BY createdAt ASC LIMIT 1)",
    ),
    getOfflineMessages: db.prepare<{ id: number; payload: string }, [string]>(
      "SELECT id, payload FROM offline_messages WHERE deviceId = ?1 AND delivered = 0 ORDER BY createdAt ASC",
    ),
    markOfflineDelivered: db.prepare<void, [number]>(
      "UPDATE offline_messages SET delivered = 1 WHERE id = ?1",
    ),
    cleanOffline: db.prepare<void, [number]>(
      "DELETE FROM offline_messages WHERE delivered = 1 OR createdAt < ?1",
    ),
  };

  return {
    registerGateway(gatewayId, token) {
      const hash = sha256(token);
      const existing = stmts.findGatewayById.get(gatewayId);

      if (!existing) {
        // First registration: store token + hash
        return stmts.insertGateway.get(gatewayId, token, hash, Date.now())!;
      }

      // Subsequent registration: verify token hash
      if (existing.tokenHash && existing.tokenHash !== hash) {
        // Token mismatch
        return null;
      }

      // Token matches (or legacy row without hash) — update
      return stmts.updateGatewayToken.get(gatewayId, token, hash)!;
    },

    findGateway(token) {
      return stmts.findGatewayByToken.get(token) ?? null;
    },

    findGatewayById(gatewayId) {
      return stmts.findGatewayById.get(gatewayId) ?? null;
    },

    createDevice(device) {
      const now = Date.now();
      const row = stmts.insertDevice.get(
        device.deviceId,
        device.deviceToken,
        device.deviceName,
        device.platform,
        device.gatewayId,
        now,
        now,
      );
      return row!;
    },

    findDeviceByToken(deviceToken) {
      return stmts.findDeviceByToken.get(deviceToken) ?? null;
    },

    listDevicesByGateway(gatewayId) {
      return stmts.listDevicesByGateway.all(gatewayId);
    },

    revokeDevice(deviceId) {
      stmts.deleteDevice.run(deviceId);
      return db.query("SELECT changes() as c").get() !== null;
    },

    touchDevice(deviceId) {
      stmts.touchDevice.run(Date.now(), deviceId);
    },

    updateDeviceToken(deviceId, newToken) {
      stmts.updateDeviceToken.run(newToken, deviceId);
    },

    countDevicesByGateway(gatewayId) {
      const row = stmts.countDevicesByGateway.get(gatewayId);
      return row?.c ?? 0;
    },

    createPairingCode(code, gatewayId, expiresAt) {
      const row = stmts.insertPairingCode.get(code, gatewayId, expiresAt);
      return row!;
    },

    redeemPairingCode(code) {
      const row = stmts.findPairingCode.get(code);
      if (!row) return null;
      if (row.redeemed || row.expiresAt < Date.now()) return null;
      stmts.markCodeRedeemed.run(code);
      return row;
    },

    cleanExpiredCodes() {
      const now = Date.now();
      stmts.cleanCodes.run(now);
      const codesResult = db.query("SELECT changes() as c").get() as { c: number } | null;
      const codesCleaned = codesResult?.c ?? 0;

      // Also clean expired/delivered offline messages (24h TTL)
      const ttlCutoff = now - 24 * 60 * 60 * 1000;
      stmts.cleanOffline.run(ttlCutoff);

      return codesCleaned;
    },

    queueOfflineMessage(deviceId, payload) {
      // Enforce per-device cap (100)
      const count = stmts.countOfflineByDevice.get(deviceId);
      if (count && count.c >= 100) {
        stmts.deleteOldestOffline.run(deviceId);
      }
      stmts.insertOfflineMessage.run(deviceId, payload, Date.now());
    },

    getOfflineMessages(deviceId) {
      return stmts.getOfflineMessages.all(deviceId);
    },

    markOfflineDelivered(ids) {
      for (const id of ids) {
        stmts.markOfflineDelivered.run(id);
      }
    },

    close() {
      db.close();
    },
  };
}
