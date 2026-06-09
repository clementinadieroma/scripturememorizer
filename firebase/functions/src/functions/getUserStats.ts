import { onCall } from "firebase-functions/v2/https";
import * as functions from "firebase-functions/v1";

import "../admin";
import {
  getUserStats as getUserStatsService,
  recalculateUserStats,
  serializeGetUserStatsResponse,
} from "../services/statsService";
import { requireAuthUid, toHttpsError } from "../utils/errors";

interface GetUserStatsRequest {
  /** When true, recount progress/favorites before returning. */
  recalculate?: boolean;
}

/**
 * Callable: return memorization dashboard stats for the authenticated user.
 * Optionally recalculates denormalized counters from subcollections.
 */
export const getUserStats = onCall(
  { cors: true },
  async (request) => {
    try {
      const uid = requireAuthUid(request);
      const data = (request.data ?? {}) as GetUserStatsRequest;

      functions.logger.info("getUserStats", { uid, recalculate: data.recalculate });

      if (data.recalculate) {
        await recalculateUserStats(uid);
      }

      const result = await getUserStatsService(uid);

      return {
        success: true,
        ...serializeGetUserStatsResponse(result),
      };
    } catch (error) {
      throw toHttpsError(error);
    }
  },
);
