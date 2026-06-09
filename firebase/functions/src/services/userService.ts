import { UserRecord } from "firebase-admin/auth";
import { FieldValue, getFirestore, Timestamp } from "firebase-admin/firestore";

import { COLLECTIONS } from "../config/constants";
import { UserProfile, UserSettings, UserStats } from "../types";

const db = getFirestore();

/** Default user settings per BACKEND_ARCHITECTURE.md. */
export function defaultSettings(): UserSettings {
  return {
    defaultTranslation: "WEB",
    ttsVoiceId: null,
    ttsSpeed: 1.0,
    ttsPitch: 1.0,
    notificationsEnabled: false,
    notificationHour: 8,
    minSessionMinutesForStreak: 1,
    loopBreakEveryN: 0,
  };
}

/** Zeroed stats counters for new users. */
export function defaultStats(): UserStats {
  return {
    versesMemorizedCount: 0,
    versesInProgressCount: 0,
    favoritesCount: 0,
    totalSessionsCount: 0,
    totalPracticeMinutes: 0,
  };
}

/** Extract auth provider ids from Firebase UserRecord. */
function extractAuthProviders(user: UserRecord): string[] {
  return (user.providerData ?? []).map((p) => p.providerId).filter(Boolean);
}

/**
 * Create the Firestore user profile document when a new Auth user is created.
 * Idempotent: skips if document already exists.
 */
export async function createUserProfileDocument(user: UserRecord): Promise<void> {
  const userRef = db.collection(COLLECTIONS.USERS).doc(user.uid);
  const existing = await userRef.get();

  if (existing.exists) {
    return;
  }

  const now = FieldValue.serverTimestamp();
  const profile: Omit<UserProfile, "createdAt" | "updatedAt" | "lastActiveAt"> & {
    createdAt: FieldValue;
    updatedAt: FieldValue;
    lastActiveAt: FieldValue;
  } = {
    email: user.email ?? null,
    displayName: user.displayName ?? null,
    photoUrl: user.photoURL ?? null,
    ageGroup: null,
    timezone: "UTC",
    locale: "en",
    premiumStatus: "free",
    authProviders: extractAuthProviders(user),
    settings: defaultSettings(),
    streak: {
      currentCount: 0,
      longestCount: 0,
      lastActivityDate: null,
    },
    stats: defaultStats(),
    createdAt: now,
    updatedAt: now,
    lastActiveAt: now,
  };

  await userRef.set(profile);
}

/** Load user profile; throws if missing. */
export async function getUserProfile(uid: string): Promise<UserProfile & { id: string }> {
  const snap = await db.collection(COLLECTIONS.USERS).doc(uid).get();
  if (!snap.exists) {
    throw new Error(`User profile not found: ${uid}`);
  }
  return { id: snap.id, ...(snap.data() as UserProfile) };
}

/** Touch lastActiveAt on user profile. */
export async function touchUserActivity(uid: string): Promise<void> {
  await db.collection(COLLECTIONS.USERS).doc(uid).update({
    lastActiveAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  });
}

/** Serialize Firestore Timestamp to ISO string for JSON responses. */
export function timestampToIso(value: Timestamp | undefined | null): string | null {
  return value?.toDate().toISOString() ?? null;
}
