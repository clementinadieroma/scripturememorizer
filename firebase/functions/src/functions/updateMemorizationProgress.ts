import { onCall } from "firebase-functions/v2/https";
import * as functions from "firebase-functions/v1";

import "../admin";
import {
  serializeProgress,
  serializeStats,
  serializeStreak,
  updateMemorizationProgress,
} from "../services/progressService";
import { UpdateMemorizationProgressRequest } from "../types";
import { requireAuthUid, requireString, toHttpsError } from "../utils/errors";

/**
 * Callable: update users/{uid}/progress/{verseId} after a practice session.
 * Also updates streak (when session qualifies), stats, and appends a session log.
 * Requires authentication.
 */
export const updateMemorizationProgressFn = onCall(
  { cors: true },
  async (request) => {
    try {
      const uid = requireAuthUid(request);
      const data = (request.data ?? {}) as UpdateMemorizationProgressRequest;

      const verseId = requireString(
        data as unknown as Record<string, unknown>,
        "verseId",
      );

      functions.logger.info("updateMemorizationProgress", { uid, verseId });

      const result = await updateMemorizationProgress(uid, {
        ...data,
        verseId,
      });

      return {
        success: true,
        progress: serializeProgress(result.progress),
        streak: serializeStreak(result.streak),
        stats: serializeStats(result.stats),
      };
    } catch (error) {
      throw toHttpsError(error);
    }
  },
);
