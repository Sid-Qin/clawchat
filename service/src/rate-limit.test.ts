import { describe, it, expect, beforeEach } from "bun:test";
import { checkRateLimit, cleanupRateLimits, resetRateLimits } from "./rate-limit.js";

describe("rate-limit", () => {
  beforeEach(() => {
    resetRateLimits();
  });

  it("allows requests under the limit", () => {
    const r1 = checkRateLimit("test", 5, 60_000);
    expect(r1.allowed).toBe(true);
    expect(r1.remaining).toBe(4);

    const r2 = checkRateLimit("test", 5, 60_000);
    expect(r2.allowed).toBe(true);
    expect(r2.remaining).toBe(3);
  });

  it("blocks requests over the limit", () => {
    for (let i = 0; i < 5; i++) {
      const r = checkRateLimit("test", 5, 60_000);
      expect(r.allowed).toBe(true);
    }

    const blocked = checkRateLimit("test", 5, 60_000);
    expect(blocked.allowed).toBe(false);
    expect(blocked.remaining).toBe(0);
  });

  it("tracks keys independently", () => {
    for (let i = 0; i < 5; i++) {
      checkRateLimit("key-a", 5, 60_000);
    }

    // key-a is exhausted
    expect(checkRateLimit("key-a", 5, 60_000).allowed).toBe(false);

    // key-b is fresh
    expect(checkRateLimit("key-b", 5, 60_000).allowed).toBe(true);
  });

  it("resets after window elapses", () => {
    // Fill up the limit
    for (let i = 0; i < 3; i++) {
      checkRateLimit("test", 3, 1); // 1ms window
    }
    expect(checkRateLimit("test", 3, 1).allowed).toBe(false);

    // Wait for window to expire (the window is 1ms, so any subsequent call resets)
    // Tiny sleep not needed — the next call checks timestamp and resets
    // Force a new window by waiting >1ms
    const start = Date.now();
    while (Date.now() - start < 2) {} // busy-wait 2ms

    const r = checkRateLimit("test", 3, 1);
    expect(r.allowed).toBe(true);
    expect(r.remaining).toBe(2);
  });

  it("cleanup removes expired entries", () => {
    checkRateLimit("old", 10, 1); // 1ms window
    checkRateLimit("fresh", 10, 60_000);

    const start = Date.now();
    while (Date.now() - start < 2) {} // wait for "old" to expire

    const cleaned = cleanupRateLimits(1);
    expect(cleaned).toBe(1); // only "old" cleaned
  });
});
