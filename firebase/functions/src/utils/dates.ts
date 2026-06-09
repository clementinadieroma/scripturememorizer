/**
 * Date helpers for daily verse rotation and streak calculation.
 * Uses UTC for global daily_verses keys; user timezone for streak dates.
 */

/** Format Date as yyyy-MM-dd in UTC. */
export function toDateKeyUtc(date: Date): string {
  return date.toISOString().slice(0, 10);
}

/** Day of year (1–366) for rotation index. */
export function dayOfYear(date: Date): number {
  const start = new Date(Date.UTC(date.getUTCFullYear(), 0, 0));
  const diff = date.getTime() - start.getTime();
  return Math.floor(diff / 86_400_000);
}

/**
 * Format yyyy-MM-dd for a given IANA timezone.
 * Falls back to UTC when timezone is invalid.
 */
export function toDateKeyInTimezone(date: Date, timezone: string): string {
  try {
    return new Intl.DateTimeFormat("en-CA", {
      timeZone: timezone,
      year: "numeric",
      month: "2-digit",
      day: "2-digit",
    }).format(date);
  } catch {
    return toDateKeyUtc(date);
  }
}

/** Parse yyyy-MM-dd into UTC midnight Date. */
export function parseDateKey(dateKey: string): Date {
  return new Date(`${dateKey}T00:00:00.000Z`);
}

/** Difference in whole calendar days between two yyyy-MM-dd strings. */
export function daysBetween(fromKey: string, toKey: string): number {
  const from = parseDateKey(fromKey).getTime();
  const to = parseDateKey(toKey).getTime();
  return Math.round((to - from) / 86_400_000);
}

/** Add/subtract days from a yyyy-MM-dd key. */
export function shiftDateKey(dateKey: string, deltaDays: number): string {
  const date = parseDateKey(dateKey);
  date.setUTCDate(date.getUTCDate() + deltaDays);
  return toDateKeyUtc(date);
}
