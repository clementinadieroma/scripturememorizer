import { getFirestore, Timestamp } from "firebase-admin/firestore";
import * as functions from "firebase-functions/v1";

import {
  COLLECTIONS,
  FALLBACK_CURATED_REFERENCES,
} from "../config/constants";
import { DailyVerse, DailyVerseConfig, VersePayload } from "../types";
import { dayOfYear, toDateKeyUtc } from "../utils/dates";
import { fetchVerseFromApi } from "../utils/verse";

const db = getFirestore();

/** Read daily verse config from Firestore or use bundled fallback. */
export async function getDailyVerseConfig(): Promise<DailyVerseConfig> {
  const snap = await db.collection(COLLECTIONS.CONFIG).doc("daily_verse").get();
  if (!snap.exists) {
    return {
      rotationStrategy: "day_of_year",
      defaultTranslation: "WEB",
      publishHourUtc: 0,
      curatedReferences: FALLBACK_CURATED_REFERENCES,
    };
  }
  const data = snap.data() as DailyVerseConfig;
  return {
    rotationStrategy: data.rotationStrategy ?? "day_of_year",
    defaultTranslation: data.defaultTranslation ?? "WEB",
    publishHourUtc: data.publishHourUtc ?? 0,
    curatedReferences: data.curatedReferences?.length
      ? data.curatedReferences
      : FALLBACK_CURATED_REFERENCES,
  };
}

/** Pick curated reference for a date using day-of-year rotation. */
export function pickReferenceForDate(
  date: Date,
  references: string[],
): string {
  if (references.length === 0) {
    throw new Error("No curated references configured.");
  }
  const index = dayOfYear(date) % references.length;
  return references[index];
}

/** Publish daily verse document (idempotent). Returns existing or newly created doc. */
export async function publishDailyVerseForDate(
  dateKey: string,
): Promise<DailyVerse> {
  const docRef = db.collection(COLLECTIONS.DAILY_VERSES).doc(dateKey);
  const existing = await docRef.get();

  if (existing.exists) {
    return existing.data() as DailyVerse;
  }

  const config = await getDailyVerseConfig();
  const date = new Date(`${dateKey}T12:00:00.000Z`);
  const reference = pickReferenceForDate(date, config.curatedReferences);

  functions.logger.info("Publishing daily verse", { dateKey, reference });

  const verse = await fetchVerseFromApi(reference, config.defaultTranslation);
  const dailyVerse: DailyVerse = {
    ...verse,
    dateKey,
    curatedListId: "mvp_curated",
    publishedAt: Timestamp.now(),
  };

  await docRef.set(dailyVerse);
  return dailyVerse;
}

/** Get daily verse for dateKey, publishing on demand if missing. */
export async function getOrPublishDailyVerse(dateKey?: string): Promise<DailyVerse> {
  const key = dateKey ?? toDateKeyUtc(new Date());
  const docRef = db.collection(COLLECTIONS.DAILY_VERSES).doc(key);
  const snap = await docRef.get();

  if (snap.exists) {
    return snap.data() as DailyVerse;
  }

  return publishDailyVerseForDate(key);
}

/** Convert DailyVerse to client-friendly JSON (ISO timestamps). */
export function serializeDailyVerse(verse: DailyVerse): Record<string, unknown> {
  return {
    dateKey: verse.dateKey,
    verseId: verse.verseId,
    reference: verse.reference,
    text: verse.text,
    translation: verse.translation,
    book: verse.book,
    chapter: verse.chapter,
    verse: verse.verse,
    curatedListId: verse.curatedListId,
    publishedAt: verse.publishedAt.toDate().toISOString(),
  };
}

/** Resolve verse payload from Firestore cache or Bible API. */
export async function resolveVersePayload(
  verseId: string,
  reference?: string,
  translation?: string,
): Promise<VersePayload> {
  const cached = await db.collection("verses").doc(verseId).get();
  if (cached.exists) {
    const data = cached.data() as VersePayload;
    return { ...data, verseId };
  }

  if (reference) {
    return fetchVerseFromApi(reference, translation ?? "WEB");
  }

  throw new Error(`Cannot resolve verse: ${verseId}`);
}
