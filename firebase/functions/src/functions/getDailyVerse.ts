import { onCall } from "firebase-functions/v2/https";
import * as functions from "firebase-functions/v1";

import "../admin";
import {
  getOrPublishDailyVerse,
  serializeDailyVerse,
} from "../services/dailyVerseService";
import { GetDailyVerseRequest } from "../types";
import { toDateKeyInTimezone, toDateKeyUtc } from "../utils/dates";
import { toHttpsError } from "../utils/errors";

/**
 * Callable: fetch today's daily verse (or a specific dateKey).
 * Auth optional — guests can read the global daily verse.
 * Publishes the verse on demand if the scheduled job has not run yet.
 */
export const getDailyVerse = onCall(
  { cors: true },
  async (request) => {
    try {
      const data = (request.data ?? {}) as GetDailyVerseRequest;
      let dateKey = data.dateKey;

      if (!dateKey) {
        const timezone = data.timezone ?? "UTC";
        dateKey = toDateKeyInTimezone(new Date(), timezone);
      }

      if (!/^\d{4}-\d{2}-\d{2}$/.test(dateKey)) {
        throw new functions.https.HttpsError(
          "invalid-argument",
          "dateKey must be yyyy-MM-dd",
        );
      }

      functions.logger.info("getDailyVerse", {
        dateKey,
        uid: request.auth?.uid ?? "guest",
      });

      const dailyVerse = await getOrPublishDailyVerse(dateKey);

      return {
        success: true,
        dailyVerse: serializeDailyVerse(dailyVerse),
        requestedDateKey: dateKey,
        serverDateKey: toDateKeyUtc(new Date()),
      };
    } catch (error) {
      throw toHttpsError(error);
    }
  },
);
