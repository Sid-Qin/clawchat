import { describe, it, expect, beforeEach, afterEach, mock } from "bun:test";

describe("log", () => {
  let originalWrite: typeof process.stdout.write;
  let captured: string[];

  beforeEach(() => {
    captured = [];
    originalWrite = process.stdout.write;
    process.stdout.write = ((chunk: string) => {
      captured.push(chunk);
      return true;
    }) as typeof process.stdout.write;
  });

  afterEach(() => {
    process.stdout.write = originalWrite;
    delete process.env.LOG_LEVEL;
  });

  it("outputs structured JSON with ts, level, event", async () => {
    // Re-import to get fresh module with default log level
    const { log } = await import("./log.js");
    log("info", "test.event", { foo: "bar" });

    expect(captured.length).toBe(1);
    const parsed = JSON.parse(captured[0]!);
    expect(parsed.level).toBe("info");
    expect(parsed.event).toBe("test.event");
    expect(parsed.foo).toBe("bar");
    expect(parsed.ts).toBeTruthy();
    // Verify ISO 8601 format
    expect(new Date(parsed.ts).toISOString()).toBe(parsed.ts);
  });

  it("includes data fields in output", async () => {
    const { log } = await import("./log.js");
    log("warn", "gateway.error", { code: "unauthorized", gatewayId: "gw-1" });

    const parsed = JSON.parse(captured[0]!);
    expect(parsed.level).toBe("warn");
    expect(parsed.code).toBe("unauthorized");
    expect(parsed.gatewayId).toBe("gw-1");
  });

  it("outputs newline-terminated JSON", async () => {
    const { log } = await import("./log.js");
    log("info", "test", {});
    expect(captured[0]!.endsWith("\n")).toBe(true);
  });
});
