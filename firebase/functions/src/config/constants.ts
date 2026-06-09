/** Firestore collection and field constants. */
export const COLLECTIONS = {
  USERS: "users",
  DAILY_VERSES: "daily_verses",
  CONFIG: "config",
} as const;

export const SUBCOLLECTIONS = {
  FAVORITES: "favorites",
  PROGRESS: "progress",
  SESSIONS: "sessions",
} as const;

/** MVP favorite limit (all features free). */
export const FAVORITE_LIMIT = 100;

/** Default Bible translation code. */
export const DEFAULT_TRANSLATION = "WEB";

/** Bible API base URL (matches Flutter AppConstants). */
export const BIBLE_API_BASE_URL = "https://bible-api.com";

/** Fallback curated references when config/daily_verse is missing. */
export const FALLBACK_CURATED_REFERENCES = [
  "John 3:16",
  "Psalm 23:1",
  "Philippians 4:13",
  "Jeremiah 29:11",
  "Proverbs 3:5",
  "Romans 8:28",
  "Isaiah 41:10",
  "Matthew 6:33",
  "Joshua 1:9",
  "Psalm 46:1",
  "1 Corinthians 13:4",
  "Ephesians 2:8",
  "Galatians 5:22",
  "Hebrews 11:1",
  "James 1:5",
  "1 John 4:19",
  "Genesis 1:1",
  "Psalm 119:105",
  "Matthew 28:19",
  "Romans 12:2",
];

export const MEMORIZATION_STATUSES = [
  "not_started",
  "in_progress",
  "memorized",
] as const;

export const MEMORIZATION_MODES = [
  "read",
  "listen",
  "repeat",
  "recite",
  "fill_in_blank",
] as const;
