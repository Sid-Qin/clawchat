// ---------------------------------------------------------------------------
// In-memory sliding window rate limiter
// ---------------------------------------------------------------------------

interface WindowEntry {
  count: number;
  windowStart: number;
}

const windows = new Map<string, WindowEntry>();

/**
 * Check whether an action is allowed under rate limiting.
 *
 * Uses a fixed-window counter keyed by `key`. The window resets
 * after `windowMs` milliseconds.
 *
 * @returns `{ allowed, remaining }` — remaining = how many more are allowed
 */
export function checkRateLimit(
  key: string,
  limit: number,
  windowMs: number,
): { allowed: boolean; remaining: number } {
  const now = Date.now();
  const entry = windows.get(key);

  if (!entry || now - entry.windowStart >= windowMs) {
    // New window
    windows.set(key, { count: 1, windowStart: now });
    return { allowed: true, remaining: limit - 1 };
  }

  entry.count++;

  if (entry.count > limit) {
    return { allowed: false, remaining: 0 };
  }

  return { allowed: true, remaining: limit - entry.count };
}

/**
 * Remove expired entries from the rate limit map.
 * Call periodically to prevent memory growth.
 */
export function cleanupRateLimits(windowMs: number): number {
  const now = Date.now();
  let cleaned = 0;
  for (const [key, entry] of windows) {
    if (now - entry.windowStart >= windowMs) {
      windows.delete(key);
      cleaned++;
    }
  }
  return cleaned;
}

/**
 * Reset all rate limit state (for testing).
 */
export function resetRateLimits(): void {
  windows.clear();
}
