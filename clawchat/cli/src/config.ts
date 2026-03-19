import { mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { homedir } from "node:os";
import { dirname, join } from "node:path";

export interface Config {
  relayUrl: string;
  deviceToken: string;
  deviceName: string;
}

export const configPath = join(homedir(), ".clawchat", "config.json");

export function loadConfig(): Config | null {
  try {
    const raw = readFileSync(configPath, "utf-8");
    return JSON.parse(raw) as Config;
  } catch {
    return null;
  }
}

export function saveConfig(config: Config): void {
  const dir = dirname(configPath);
  mkdirSync(dir, { recursive: true });
  writeFileSync(configPath, JSON.stringify(config, null, 2) + "\n", "utf-8");
}
