#!/usr/bin/env node

/**
 * ClawChat installer CLI.
 *
 * Usage:
 *   npx @claw-os/clawchat install    — install plugin, configure, and show pairing QR
 *   npx @claw-os/clawchat pair       — generate a new pairing code + QR
 */

import crypto from "node:crypto";
import fs from "node:fs";
import path from "node:path";
import os from "node:os";
import { execSync, spawnSync } from "node:child_process";

// ---------------------------------------------------------------------------
// Shell helper — same pattern as @larksuite/openclaw-lark-tools
// ---------------------------------------------------------------------------

function runCommand(command, args = []) {
  const isWindows = os.platform() === "win32";
  const { status, error } = spawnSync(command, args, {
    stdio: "inherit",
    shell: isWindows,
  });
  if (error) throw error;
  if (status !== 0) throw new Error(`Command failed with exit code ${status}`);
}

// ---------------------------------------------------------------------------
// Config helpers (read/write ~/.openclaw/openclaw.json directly)
// ---------------------------------------------------------------------------

const CONFIG_DIR = process.env.OPENCLAW_STATE_DIR
  ? path.resolve(process.env.OPENCLAW_STATE_DIR)
  : path.join(os.homedir(), ".openclaw");
const CONFIG_PATH = path.join(CONFIG_DIR, "openclaw.json");
const EXTENSIONS_DIR = path.join(CONFIG_DIR, "extensions");
const PLUGIN_ID = "clawchat";
const NPM_PACKAGE = "@claw-os/clawchat";
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

  // 3. Install plugin via openclaw CLI first (it writes config too)
  const pluginDir = path.join(EXTENSIONS_DIR, PLUGIN_ID);
  if (!fs.existsSync(pluginDir)) {
    console.log("  ⏳ Installing plugin...");
    try {
      runCommand("openclaw", ["plugins", "install", NPM_PACKAGE]);
    } catch {
      console.log("  ⚠ Auto-install failed. Run manually:");
      console.log(`    openclaw plugins install ${NPM_PACKAGE}`);
    }
  } else {
    console.log("  ✓ Plugin already installed");
  }

  // 4. Re-read config (openclaw install may have modified it), then apply our settings
  const freshConfig = readConfig();
  if (!freshConfig.plugins) freshConfig.plugins = {};
  if (!freshConfig.plugins.entries) freshConfig.plugins.entries = {};
  if (!freshConfig.plugins.allow) freshConfig.plugins.allow = [];

  let freshEntry = freshConfig.plugins.entries[PLUGIN_ID] ?? {};
  if (!freshEntry.config) freshEntry.config = {};
  freshEntry.enabled = true;
  freshEntry.config.token = token;
  if (!freshEntry.config.relay) freshEntry.config.relay = relay;
  if (!freshEntry.config.session) freshEntry.config.session = "clawchat";
  freshConfig.plugins.entries[PLUGIN_ID] = freshEntry;

  // Add to plugins.allow
  if (!freshConfig.plugins.allow.includes(PLUGIN_ID)) {
    freshConfig.plugins.allow.push(PLUGIN_ID);
  }

  writeConfig(freshConfig);
  console.log("  ✓ Updated openclaw.json");

  // 5. Restart gateway first (plugin must connect to relay before pairing)
  console.log("  ⏳ Restarting gateway...");
  try {
    runCommand("openclaw", ["gateway", "restart"]);
    console.log("  ✓ Gateway restarted");
  } catch {
    console.log("  ⚠ Could not restart gateway. Run manually:");
    console.log("    openclaw gateway restart");
    console.log("  Then run: npx @claw-os/clawchat pair");
    console.log("");
    return;
  }

  // 6. Wait for plugin to connect to relay and register
  console.log("  ⏳ Waiting for gateway to register...");
  await new Promise((r) => setTimeout(r, 3000));

  // 7. Get pairing code and show QR
  await showPairingQR(relay, token);
  console.log("");
}

async function pair() {
  const config = readConfig();
  const entry = config.plugins?.entries?.[PLUGIN_ID];
  if (!entry?.config?.token) {
    console.error("  Error: ClawChat not configured. Run: npx @claw-os/clawchat install");
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
    console.log("  Scan with ClawOS app (请使用 ClawOS 扫码配对):");
    console.log("");
    await printQR(deepLink);
    console.log(`  Pairing Code : ${data.code}`);
    console.log(`  Relay        : ${relay}`);
    console.log(`  Expires      : ${expires}`);
  } catch (err) {
    console.error(`  ⚠ Could not get pairing code: ${err.message}`);
    console.log("  The relay may not have your gateway registered yet.");
    console.log("  Restart the gateway first, then run: npx @claw-os/clawchat pair");
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
    console.log("  npx @claw-os/clawchat install  — install and configure");
    console.log("  npx @claw-os/clawchat pair     — generate pairing QR code");
    process.exit(1);
}
