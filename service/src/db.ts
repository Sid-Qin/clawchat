import { Database } from "bun:sqlite";

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

export interface GatewayRow {
  gatewayId: string;
  token: string;
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
  /** Register or update a gateway. Returns the row. */
  registerGateway(gatewayId: string, token: string): GatewayRow;
  /** Find a gateway by its token. */
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

  /** Create a pairing code for a gateway. */
  createPairingCode(code: string, gatewayId: string, expiresAt: number): PairingCodeRow;
  /** Redeem a pairing code. Returns the row if valid, null otherwise. */
  redeemPairingCode(code: string): PairingCodeRow | null;
  /** Delete expired and redeemed codes. */
  cleanExpiredCodes(): number;

  /** Close the database connection. */
  close(): void;
}

// ---------------------------------------------------------------------------
// Implementation
// ---------------------------------------------------------------------------

export function createDb(path: string): DbStore {
  const db = new Database(path);

  // Enable WAL mode for better concurrent read performance
  db.run("PRAGMA journal_mode = WAL");
  db.run("PRAGMA foreign_keys = ON");

  // Create tables
  db.run(`
    CREATE TABLE IF NOT EXISTS gateways (
      gatewayId TEXT PRIMARY KEY,
      token TEXT NOT NULL,
      createdAt INTEGER NOT NULL
    )
  `);

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

  // Prepared statements
  const stmts = {
    upsertGateway: db.prepare<GatewayRow, [string, string, number]>(
      `INSERT INTO gateways (gatewayId, token, createdAt)
       VALUES (?1, ?2, ?3)
       ON CONFLICT(gatewayId) DO UPDATE SET token = excluded.token
       RETURNING *`,
    ),
    findGatewayByToken: db.prepare<GatewayRow, [string]>(
      "SELECT * FROM gateways WHERE token = ?1",
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
  };

  return {
    registerGateway(gatewayId, token) {
      const row = stmts.upsertGateway.get(gatewayId, token, Date.now());
      return row!;
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
      stmts.cleanCodes.run(Date.now());
      const result = db.query("SELECT changes() as c").get() as { c: number } | null;
      return result?.c ?? 0;
    },

    close() {
      db.close();
    },
  };
}
