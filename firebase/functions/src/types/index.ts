import { Timestamp } from "firebase-admin/firestore";

import { MEMORIZATION_MODES, MEMORIZATION_STATUSES } from "../config/constants";

export type MemorizationStatus = (typeof MEMORIZATION_STATUSES)[number];
export type MemorizationMode = (typeof MEMORIZATION_MODES)[number];
export type PremiumStatus = "free" | "trial" | "active" | "expired";
export type AgeGroup = "child" | "teen" | "adult";

export interface UserSettings {
  defaultTranslation: string;
  ttsVoiceId: string | null;
  ttsSpeed: number;
  ttsPitch: number;
  notificationsEnabled: boolean;
  notificationHour: number;
  minSessionMinutesForStreak: number;
  loopBreakEveryN: number;
}

export interface StreakData {
  currentCount: number;
  longestCount: number;
  lastActivityDate: string | null;
  updatedAt?: Timestamp;
}

export interface UserStats {
  versesMemorizedCount: number;
  versesInProgressCount: number;
  favoritesCount: number;
  totalSessionsCount: number;
  totalPracticeMinutes: number;
}

export interface UserProfile {
  email: string | null;
  displayName: string | null;
  photoUrl: string | null;
  ageGroup: AgeGroup | null;
  timezone: string;
  locale: string;
  premiumStatus: PremiumStatus;
  authProviders: string[];
  settings: UserSettings;
  streak: StreakData;
  stats: UserStats;
  createdAt: Timestamp;
  updatedAt: Timestamp;
  lastActiveAt: Timestamp;
}

export interface VersePayload {
  verseId: string;
  reference: string;
  text: string;
  translation: string;
  book?: string;
  chapter?: number;
  verse?: number;
}

export interface FavoriteVerse extends VersePayload {
  addedAt: Timestamp;
  sortOrder?: number;
}

export interface UserProgress {
  verseId: string;
  reference?: string;
  status: MemorizationStatus;
  percent: number;
  repeatCount: number;
  lastMode?: MemorizationMode;
  lastPracticedAt: Timestamp;
  memorizedAt?: Timestamp | null;
  updatedAt: Timestamp;
}

export interface DailyVerse extends VersePayload {
  dateKey: string;
  curatedListId?: string;
  publishedAt: Timestamp;
}

export interface DailyVerseConfig {
  rotationStrategy: string;
  defaultTranslation: string;
  publishHourUtc: number;
  curatedReferences: string[];
}

export interface UpdateMemorizationProgressRequest {
  verseId: string;
  reference?: string;
  status?: MemorizationStatus;
  percent?: number;
  repeatCountDelta?: number;
  loopsCompleted?: number;
  lastMode?: MemorizationMode;
  durationSeconds?: number;
  completed?: boolean;
  clientId?: string;
}

export interface ToggleFavoriteRequest {
  verseId: string;
  reference: string;
  text: string;
  translation: string;
  book?: string;
  chapter?: number;
  verse?: number;
  /** When true, add favorite; when false, remove. Omit to toggle. */
  add?: boolean;
}

export interface GetDailyVerseRequest {
  dateKey?: string;
  timezone?: string;
}

export interface GetUserStatsResponse {
  stats: UserStats;
  streak: StreakData;
  recentProgress: UserProgress[];
  favoritesCount: number;
}

export interface ToggleFavoriteResponse {
  isFavorite: boolean;
  favoritesCount: number;
  favorite?: FavoriteVerse;
}

export interface UpdateMemorizationProgressResponse {
  progress: UserProgress;
  streak: StreakData;
  stats: UserStats;
}
