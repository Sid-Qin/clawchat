#!/usr/bin/env node

/**
 * ClawChat OpenClaw installer CLI.
 *
 * Usage:
 *   npx clawchat-openclaw install    — install plugin, configure, and show pairing QR
 *   npx clawchat-openclaw pair       — generate a new pairing code + QR
 */

import crypto from "node:crypto";
import fs from "node:fs";
import path from "node:path";
import os from "node:os";
import { execSync } from "node:child_process";

// ---------------------------------------------------------------------------
// Config helpers (read/write ~/.openclaw/openclaw.json directly)
// ---------------------------------------------------------------------------

const CONFIG_DIR = process.env.OPENCLAW_STATE_DIR
  ? path.resolve(process.env.OPENCLAW_STATE_DIR)
  : path.join(os.homedir(), ".openclaw");
const CONFIG_PATH = path.join(CONFIG_DIR, "openclaw.json");
const EXTENSIONS_DIR = path.join(CONFIG_DIR, "extensions");
const PLUGIN_ID = "clawchat-openclaw";
const DEFAULT_RELAY = "wss://clawchat-production-db31.up.railway.app";

function readConfig() {
  try {
    return JSON.parse(fs.readFileSync(CONFIG_PATH, "utf-8"));
  } catch {
    return {};
  }
}

function writeConfig(config) {
  fs.mkdirSync(CONFIG_DIR, { recursive: true });
  fs.writeFileSync(CONFIG_PATH, JSON.stringify(config, null, 2) + "\n");
}

// ---------------------------------------------------------------------------
// Relay API
// ---------------------------------------------------------------------------

async function fetchPairingCode(relay, token) {
  const httpUrl = relay.replace(/^wss:\/\//, "https://").replace(/^ws:\/\//, "http://");
  const res = await fetch(`${httpUrl}/api/pair/code`, {
    method: "POST",
    headers: { Authorization: `Bearer ${token}` },
  });
  if (!res.ok) {
    const body = await res.text().catch(() => "");
    throw new Error(`Failed to get pairing code (${res.status}): ${body}`);
  }
  return res.json();
}

// ---------------------------------------------------------------------------
// QR code (uses qrcode-terminal if available, otherwise plain text)
// ---------------------------------------------------------------------------

async function printQR(data) {
  try {
    const qrcode = await import("qrcode-terminal");
    const mod = qrcode.default ?? qrcode;
    return new Promise((resolve) => {
      mod.generate(data, { small: true }, (output) => {
        console.log(output);
        resolve();
      });
    });
  } catch {
    // Fallback: just print the deep link
    console.log(`  Deep link: ${data}`);
    console.log("  (Install qrcode-terminal for QR display)");
  }
}

// ---------------------------------------------------------------------------
// Commands
// ---------------------------------------------------------------------------

async function install() {
  console.log("");
  console.log("  ┌─────────────────────────────────────┐");
  console.log("  │      ClawChat — OpenClaw Plugin       │");
  console.log("  └─────────────────────────────────────┘");
  console.log("");

  // 1. Read or create config
  const config = readConfig();
  if (!config.plugins) config.plugins = {};
  if (!config.plugins.entries) config.plugins.entries = {};
  if (!config.plugins.allow) config.plugins.allow = [];

  // 2. Generate token if needed
  let entry = config.plugins.entries[PLUGIN_ID] ?? {};
  if (!entry.config) entry.config = {};
  const existingToken = entry.config.token;
  const token = existingToken || crypto.randomUUID();
  const relay = entry.config.relay || DEFAULT_RELAY;

  if (!existingToken) {
    console.log("  ✓ Generated gateway token");
  } else {
    console.log("  ✓ Using existing gateway token");
  }

  // 3. Update config
  entry.enabled = true;
  entry.config.token = token;
  if (!entry.config.relay) entry.config.relay = relay;
  if (!entry.config.session) entry.config.session = "clawchat";
  config.plugins.entries[PLUGIN_ID] = entry;

  // Add to plugins.allow
  if (!config.plugins.allow.includes(PLUGIN_ID)) {
    config.plugins.allow.push(PLUGIN_ID);
  }

  writeConfig(config);
  console.log("  ✓ Updated openclaw.json");

  // 4. Install plugin via openclaw CLI
  const pluginDir = path.join(EXTENSIONS_DIR, PLUGIN_ID);
  if (!fs.existsSync(pluginDir)) {
    console.log("  ⏳ Installing plugin...");
    try {
      execSync(`openclaw plugins install ${PLUGIN_ID}`, {
        stdio: "inherit",
      });
    } catch {
      console.log("  ⚠ Auto-install failed. Run manually:");
      console.log(`    openclaw plugins install ${PLUGIN_ID}`);
    }
  } else {
    console.log("  ✓ Plugin already installed");
  }

  // 5. Get pairing code and show QR
  await showPairingQR(relay, token);

  console.log("");
  console.log("  Next: restart the gateway to load the plugin:");
  console.log("    openclaw gateway restart");
  console.log("");
}

async function pair() {
  const config = readConfig();
  const entry = config.plugins?.entries?.[PLUGIN_ID];
  if (!entry?.config?.token) {
    console.error("  Error: ClawChat not configured. Run: npx clawchat-openclaw install");
    process.exit(1);
  }
  await showPairingQR(entry.config.relay || DEFAULT_RELAY, entry.config.token);
}

async function showPairingQR(relay, token) {
  console.log("  ⏳ Requesting pairing code...");
  try {
    const data = await fetchPairingCode(relay, token);
    const deepLink = `clawchat://pair?relay=${encodeURIComponent(relay)}&code=${data.code.replace(/-/g, "")}`;
    const expires = new Date(data.expiresAt).toLocaleTimeString();

    console.log("");
    console.log("  Scan with ClawChat app (请使用 ClawChat 扫码配对):");
    console.log("");
    await printQR(deepLink);
    console.log(`  Pairing Code : ${data.code}`);
    console.log(`  Relay        : ${relay}`);
    console.log(`  Expires      : ${expires}`);
  } catch (err) {
    console.error(`  ⚠ Could not get pairing code: ${err.message}`);
    console.log("  The relay may not have your gateway registered yet.");
    console.log("  Restart the gateway first, then run: npx clawchat-openclaw pair");
  }
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

const command = process.argv[2] ?? "install";

switch (command) {
  case "install":
    await install();
    break;
  case "pair":
    await pair();
    break;
  default:
    console.log("Usage:");
    console.log("  npx clawchat-openclaw install  — install and configure");
    console.log("  npx clawchat-openclaw pair     — generate pairing QR code");
    process.exit(1);
}
