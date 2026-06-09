import { onSchedule } from "firebase-functions/v2/scheduler";
import * as functions from "firebase-functions/v1";

import "../admin";
import { publishDailyVerseForDate } from "../services/dailyVerseService";
import { toDateKeyUtc } from "../utils/dates";

/**
 * Scheduled job: publishes the global daily verse at 00:05 UTC each day.
 * Idempotent — skips if daily_verses/{dateKey} already exists.
 */
export const publishDailyVerse = onSchedule(
  {
    schedule: "5 0 * * *",
    timeZone: "UTC",
    retryCount: 3,
  },
  async () => {
    const dateKey = toDateKeyUtc(new Date());
    functions.logger.info("Scheduled publishDailyVerse", { dateKey });

    try {
      const verse = await publishDailyVerseForDate(dateKey);
      functions.logger.info("Daily verse published", {
        dateKey,
        reference: verse.reference,
      });
    } catch (error) {
      functions.logger.error("publishDailyVerse failed", { dateKey, error });
      throw error;
    }
  },
);
