// ---------------------------------------------------------------------------
// Structured JSON logger
// ---------------------------------------------------------------------------

export type LogLevel = "debug" | "info" | "warn" | "error";

const LEVEL_ORDER: Record<LogLevel, number> = {
  debug: 0,
  info: 1,
  warn: 2,
  error: 3,
};

const configuredLevel: LogLevel = ((): LogLevel => {
  const env = process.env.LOG_LEVEL?.toLowerCase();
  if (env && env in LEVEL_ORDER) return env as LogLevel;
  return "info";
})();

/**
 * Emit a structured JSON log line to stdout.
 *
 * @param level  - Log severity
 * @param event  - Dot-separated event identifier (e.g. "gateway.register")
 * @param data   - Arbitrary key-value payload
 */
export function log(
  level: LogLevel,
  event: string,
  data?: Record<string, unknown>,
): void {
  if (LEVEL_ORDER[level] < LEVEL_ORDER[configuredLevel]) return;

  const entry: Record<string, unknown> = {
    ts: new Date().toISOString(),
    level,
    event,
    ...data,
  };

  process.stdout.write(JSON.stringify(entry) + "\n");
}
