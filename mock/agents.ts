/**
 * Agent 预设库 — 所有 mock agent 的定义和预设组合。
 */

export interface AgentDef {
  id: string;
  name: string;
  model: string;
  models: string[];
}

export const AGENT_POOL: AgentDef[] = [
  { id: "rei", name: "Ayanami Rei", model: "claude-sonnet-4-6", models: ["claude-sonnet-4-6", "claude-opus-4-6"] },
  { id: "asuka", name: "Asuka Langley", model: "gpt-4o", models: ["gpt-4o", "gpt-4o-mini"] },
  { id: "misato", name: "Misato Katsuragi", model: "claude-opus-4-6", models: ["claude-opus-4-6"] },
  { id: "kaworu", name: "Kaworu Nagisa", model: "gemini-2.5-pro", models: ["gemini-2.5-pro", "gemini-2.5-flash"] },
  { id: "shinji", name: "Shinji Ikari", model: "claude-sonnet-4-6", models: ["claude-sonnet-4-6"] },
  { id: "ritsuko", name: "Ritsuko Akagi", model: "deepseek-r1", models: ["deepseek-r1", "deepseek-v3"] },
  { id: "maya", name: "Maya Ibuki", model: "claude-haiku-3.5", models: ["claude-haiku-3.5"] },
  { id: "kaji", name: "Ryoji Kaji", model: "gpt-4-turbo", models: ["gpt-4-turbo", "gpt-4o"] },
  { id: "fuyutsuki", name: "Kozo Fuyutsuki", model: "claude-sonnet-4-6", models: ["claude-sonnet-4-6"] },
  { id: "gendo", name: "Gendo Ikari", model: "claude-opus-4-6", models: ["claude-opus-4-6", "claude-sonnet-4-6"] },
  { id: "hikari", name: "Hikari Horaki", model: "gemini-2.5-flash", models: ["gemini-2.5-flash"] },
  { id: "toji", name: "Toji Suzuhara", model: "llama-3.3-70b", models: ["llama-3.3-70b"] },
  { id: "kensuke", name: "Kensuke Aida", model: "gpt-4o-mini", models: ["gpt-4o-mini"] },
  { id: "pen-pen", name: "Pen Pen", model: "claude-haiku-3.5", models: ["claude-haiku-3.5"] },
  { id: "yui", name: "Yui Ikari", model: "claude-opus-4-6", models: ["claude-opus-4-6"] },
  { id: "naoko", name: "Naoko Akagi", model: "deepseek-r1", models: ["deepseek-r1"] },
  { id: "shigeru", name: "Shigeru Aoba", model: "gemini-2.5-pro", models: ["gemini-2.5-pro"] },
  { id: "makoto", name: "Makoto Hyuga", model: "claude-sonnet-4-6", models: ["claude-sonnet-4-6"] },
  { id: "mari", name: "Mari Makinami", model: "gpt-4o", models: ["gpt-4o", "gpt-4o-mini", "gpt-4-turbo"] },
  { id: "sakura", name: "Sakura Suzuhara", model: "claude-haiku-3.5", models: ["claude-haiku-3.5"] },
];

export type PresetName = "single" | "multi" | "squad" | "massive";

export const PRESETS: Record<PresetName, number> = {
  single: 1,
  multi: 5,
  squad: 10,
  massive: 20,
};

export function getAgents(preset: string): AgentDef[] {
  const count = PRESETS[preset as PresetName];
  if (!count) {
    console.warn(`Unknown preset "${preset}", using single`);
    return AGENT_POOL.slice(0, 1);
  }
  return AGENT_POOL.slice(0, count);
}

export function encodeDescriptor(a: AgentDef): string {
  return `${a.id}::${a.name}::${a.model}::${a.models.join("|")}`;
}

export function buildAgentsMeta(agents: AgentDef[]): Record<string, { name: string; model: string; avatar: string }> {
  const meta: Record<string, any> = {};
  for (const a of agents) {
    meta[encodeDescriptor(a)] = { name: a.name, model: a.model, avatar: "" };
  }
  return meta;
}
