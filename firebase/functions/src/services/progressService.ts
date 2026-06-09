import { FieldValue, getFirestore, Timestamp } from "firebase-admin/firestore";

import {
  COLLECTIONS,
  MEMORIZATION_MODES,
  MEMORIZATION_STATUSES,
  SUBCOLLECTIONS,
} from "../config/constants";
import {
  MemorizationMode,
  MemorizationStatus,
  StreakData,
  UpdateMemorizationProgressRequest,
  UpdateMemorizationProgressResponse,
  UserProgress,
  UserStats,
} from "../types";
import { toDateKeyInTimezone } from "../utils/dates";
import { AppError, clampInt } from "../utils/errors";
import { getUserProfile } from "./userService";

const db = getFirestore();

function progressRef(uid: string, verseId: string) {
  return db
    .collection(COLLECTIONS.USERS)
    .doc(uid)
    .collection(SUBCOLLECTIONS.PROGRESS)
    .doc(verseId);
}

function userDocRef(uid: string) {
  return db.collection(COLLECTIONS.USERS).doc(uid);
}

function sessionsRef(uid: string) {
  return db
    .collection(COLLECTIONS.USERS)
    .doc(uid)
    .collection(SUBCOLLECTIONS.SESSIONS);
}

function isValidStatus(status: string): status is MemorizationStatus {
  return (MEMORIZATION_STATUSES as readonly string[]).includes(status);
}

function isValidMode(mode: string): mode is MemorizationMode {
  return (MEMORIZATION_MODES as readonly string[]).includes(mode);
}

/** Derive status from completion percent when not explicitly provided. */
function deriveStatus(
  percent: number,
  requested?: MemorizationStatus,
): MemorizationStatus {
  if (requested && isValidStatus(requested)) {
    return requested;
  }
  if (percent >= 100) return "memorized";
  if (percent > 0) return "in_progress";
  return "not_started";
}

/**
 * Recompute streak after qualifying memorization activity.
 * Uses user timezone for calendar-day boundaries.
 */
export function computeStreak(
  current: StreakData,
  activityDateKey: string,
): StreakData {
  const lastDate = current.lastActivityDate;

  if (!lastDate) {
    return {
      currentCount: 1,
      longestCount: Math.max(1, current.longestCount),
      lastActivityDate: activityDateKey,
    };
  }

  if (lastDate === activityDateKey) {
    return {
      ...current,
      lastActivityDate: activityDateKey,
    };
  }

  const from = new Date(`${lastDate}T00:00:00.000Z`).getTime();
  const to = new Date(`${activityDateKey}T00:00:00.000Z`).getTime();
  const gap = Math.round((to - from) / 86_400_000);

  if (gap === 1) {
    const newCount = current.currentCount + 1;
    return {
      currentCount: newCount,
      longestCount: Math.max(current.longestCount, newCount),
      lastActivityDate: activityDateKey,
    };
  }

  if (gap === 0) {
    return { ...current, lastActivityDate: activityDateKey };
  }

  return {
    currentCount: 1,
    longestCount: Math.max(current.longestCount, 1),
    lastActivityDate: activityDateKey,
  };
}

/** Update progress subcollection, optional session log, streak, and stats. */
export async function updateMemorizationProgress(
  uid: string,
  request: UpdateMemorizationProgressRequest,
): Promise<UpdateMemorizationProgressResponse> {
  const {
    verseId,
    reference,
    repeatCountDelta = 0,
    loopsCompleted,
    durationSeconds = 0,
    completed = true,
    clientId,
  } = request;

  if (request.status && !isValidStatus(request.status)) {
    throw new AppError("invalid-argument", `Invalid status: ${request.status}`);
  }

  if (request.lastMode && !isValidMode(request.lastMode)) {
    throw new AppError("invalid-argument", `Invalid mode: ${request.lastMode}`);
  }

  const percent = clampInt(request.percent ?? 0, 0, 100);
  const status = deriveStatus(percent, request.status);
  const now = Timestamp.now();

  const user = await getUserProfile(uid);
  const timezone = user.timezone || "UTC";
  const activityDateKey = toDateKeyInTimezone(new Date(), timezone);
  const minSessionSeconds = (user.settings?.minSessionMinutesForStreak ?? 1) * 60;
  const qualifiesForStreak = completed && durationSeconds >= minSessionSeconds;

  const progressSnap = await progressRef(uid, verseId).get();
  const previous = progressSnap.data() as UserProgress | undefined;
  const previousStatus = previous?.status ?? "not_started";

  const progress: UserProgress = {
    verseId,
    reference: reference ?? previous?.reference,
    status,
    percent,
    repeatCount: (previous?.repeatCount ?? 0) + Math.max(0, repeatCountDelta),
    lastMode: request.lastMode ?? previous?.lastMode,
    lastPracticedAt: now,
    memorizedAt:
      status === "memorized"
        ? previous?.memorizedAt ?? now
        : previous?.memorizedAt ?? null,
    updatedAt: now,
  };

  let streak: StreakData = {
    currentCount: user.streak?.currentCount ?? 0,
    longestCount: user.streak?.longestCount ?? 0,
    lastActivityDate: user.streak?.lastActivityDate ?? null,
  };

  if (qualifiesForStreak) {
    streak = computeStreak(streak, activityDateKey);
  }

  const statsUpdates: Record<string, FieldValue | number> = {};
  if (completed) {
    statsUpdates["stats.totalSessionsCount"] = FieldValue.increment(1);
    if (durationSeconds > 0) {
      statsUpdates["stats.totalPracticeMinutes"] = FieldValue.increment(
        Math.ceil(durationSeconds / 60),
      );
    }
  }

  if (previousStatus !== "memorized" && status === "memorized") {
    statsUpdates["stats.versesMemorizedCount"] = FieldValue.increment(1);
    if (previousStatus === "in_progress") {
      statsUpdates["stats.versesInProgressCount"] = FieldValue.increment(-1);
    }
  } else if (previousStatus === "not_started" && status === "in_progress") {
    statsUpdates["stats.versesInProgressCount"] = FieldValue.increment(1);
  } else if (previousStatus === "memorized" && status !== "memorized") {
    statsUpdates["stats.versesMemorizedCount"] = FieldValue.increment(-1);
    if (status === "in_progress") {
      statsUpdates["stats.versesInProgressCount"] = FieldValue.increment(1);
    }
  }

  await db.runTransaction(async (tx) => {
    tx.set(progressRef(uid, verseId), progress, { merge: true });

    const userUpdate: Record<string, unknown> = {
      ...statsUpdates,
      updatedAt: FieldValue.serverTimestamp(),
      lastActiveAt: FieldValue.serverTimestamp(),
    };

    if (qualifiesForStreak) {
      userUpdate.streak = {
        ...streak,
        updatedAt: FieldValue.serverTimestamp(),
      };
    }

    tx.set(userDocRef(uid), userUpdate, { merge: true });
  });

  if (completed && (durationSeconds > 0 || loopsCompleted !== undefined)) {
    await recordSession(uid, {
      verseId,
      reference: progress.reference,
      mode: request.lastMode ?? "repeat",
      loopsCompleted: loopsCompleted ?? repeatCountDelta,
      loopsTarget: loopsCompleted,
      durationSeconds,
      percentComplete: percent,
      completed,
      clientId,
    });
  }

  const updatedUser = await getUserProfile(uid);

  return {
    progress,
    streak: updatedUser.streak,
    stats: updatedUser.stats,
  };
}

/** Record memorization session; skip duplicate clientId. */
async function recordSession(
  uid: string,
  session: {
    verseId: string;
    reference?: string;
    mode: MemorizationMode;
    loopsCompleted?: number;
    loopsTarget?: number;
    durationSeconds: number;
    percentComplete: number;
    completed: boolean;
    clientId?: string;
  },
): Promise<void> {
  const sessionData = {
    verseId: session.verseId,
    reference: session.reference ?? null,
    mode: session.mode,
    loopsCompleted: session.loopsCompleted ?? 0,
    loopsTarget: session.loopsTarget ?? null,
    durationSeconds: session.durationSeconds,
    percentComplete: session.percentComplete,
    completed: session.completed,
    clientId: session.clientId ?? null,
    startedAt: FieldValue.serverTimestamp(),
    completedAt: FieldValue.serverTimestamp(),
  };

  if (session.clientId) {
    const docRef = sessionsRef(uid).doc(session.clientId);
    const existing = await docRef.get();
    if (existing.exists) {
      return;
    }
    await docRef.set(sessionData);
    return;
  }

  await sessionsRef(uid).add(sessionData);
}

/** Serialize UserProgress for JSON response. */
export function serializeProgress(progress: UserProgress): Record<string, unknown> {
  return {
    verseId: progress.verseId,
    reference: progress.reference ?? null,
    status: progress.status,
    percent: progress.percent,
    repeatCount: progress.repeatCount,
    lastMode: progress.lastMode ?? null,
    lastPracticedAt: progress.lastPracticedAt.toDate().toISOString(),
    memorizedAt: progress.memorizedAt?.toDate().toISOString() ?? null,
    updatedAt: progress.updatedAt.toDate().toISOString(),
  };
}

export function serializeStreak(streak: StreakData): Record<string, unknown> {
  return {
    currentCount: streak.currentCount ?? 0,
    longestCount: streak.longestCount ?? 0,
    lastActivityDate: streak.lastActivityDate ?? null,
  };
}

export function serializeStats(stats: UserStats): Record<string, unknown> {
  return {
    versesMemorizedCount: stats.versesMemorizedCount ?? 0,
    versesInProgressCount: stats.versesInProgressCount ?? 0,
    favoritesCount: stats.favoritesCount ?? 0,
    totalSessionsCount: stats.totalSessionsCount ?? 0,
    totalPracticeMinutes: stats.totalPracticeMinutes ?? 0,
  };
}
