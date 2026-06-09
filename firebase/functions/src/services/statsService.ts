import { FieldValue, getFirestore } from "firebase-admin/firestore";

import { COLLECTIONS, SUBCOLLECTIONS } from "../config/constants";
import { GetUserStatsResponse, UserProgress, UserStats } from "../types";
import { countFavorites } from "./favoritesService";
import { serializeProgress, serializeStats, serializeStreak } from "./progressService";
import { defaultStats, getUserProfile } from "./userService";

const db = getFirestore();

function progressCollection(uid: string) {
  return db
    .collection(COLLECTIONS.USERS)
    .doc(uid)
    .collection(SUBCOLLECTIONS.PROGRESS);
}

/**
 * Recalculate memorization stats from progress subcollection and reconcile
 * favorites count. Updates denormalized stats on user profile.
 */
export async function recalculateUserStats(uid: string): Promise<UserStats> {
  const progressSnap = await progressCollection(uid).get();

  let versesMemorizedCount = 0;
  let versesInProgressCount = 0;

  progressSnap.docs.forEach((doc) => {
    const data = doc.data() as UserProgress;
    if (data.status === "memorized") {
      versesMemorizedCount += 1;
    } else if (data.status === "in_progress") {
      versesInProgressCount += 1;
    }
  });

  const favoritesCount = await countFavorites(uid);
  const user = await getUserProfile(uid);
  const existing = user.stats ?? defaultStats();

  const stats: UserStats = {
    versesMemorizedCount,
    versesInProgressCount,
    favoritesCount,
    totalSessionsCount: existing.totalSessionsCount ?? 0,
    totalPracticeMinutes: existing.totalPracticeMinutes ?? 0,
  };

  await db.collection(COLLECTIONS.USERS).doc(uid).set(
    {
      stats,
      updatedAt: FieldValue.serverTimestamp(),
    },
    { merge: true },
  );

  return stats;
}

/** Return dashboard stats, streak, and recent progress for the authenticated user. */
export async function getUserStats(uid: string): Promise<GetUserStatsResponse> {
  const user = await getUserProfile(uid);

  const recentSnap = await progressCollection(uid)
    .orderBy("lastPracticedAt", "desc")
    .limit(10)
    .get();

  const recentProgress = recentSnap.docs.map(
    (doc) => doc.data() as UserProgress,
  );

  const favoritesCount = await countFavorites(uid);
  const stats: UserStats = {
    ...(user.stats ?? defaultStats()),
    favoritesCount,
  };

  return {
    stats,
    streak: user.streak,
    recentProgress,
    favoritesCount,
  };
}

/** Serialize getUserStats response for callable JSON payload. */
export function serializeGetUserStatsResponse(
  response: GetUserStatsResponse,
): Record<string, unknown> {
  return {
    stats: serializeStats(response.stats),
    streak: serializeStreak(response.streak),
    favoritesCount: response.favoritesCount,
    recentProgress: response.recentProgress.map(serializeProgress),
  };
}
