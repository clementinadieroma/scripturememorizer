import { BIBLE_API_BASE_URL, DEFAULT_TRANSLATION } from "../config/constants";
import { VersePayload } from "../types";

interface BibleApiResponse {
  reference?: string;
  text?: string;
  translation_name?: string;
  verses?: Array<{
    book_name?: string;
    chapter?: number;
    verse?: number;
    text?: string;
  }>;
}

/** Normalize book name for stable verseId (remove spaces). */
function normalizeBook(book: string): string {
  return book.replace(/\s+/g, "");
}

/** Parse reference string like "John 3:16". */
function parseReference(ref: string): { book: string; chapter: number; verse: number } {
  const match = /^(.+?)\s+(\d+):(\d+)$/.exec(ref.trim());
  if (!match) {
    return { book: ref.trim(), chapter: 1, verse: 1 };
  }
  return {
    book: match[1].trim(),
    chapter: parseInt(match[2], 10),
    verse: parseInt(match[3], 10),
  };
}

/** Build canonical verseId: {TRANSLATION}-{Book}-{chapter}-{verse}. */
export function buildVerseId(
  translation: string,
  book: string,
  chapter: number,
  verse: number,
): string {
  const code = translation.toUpperCase();
  return `${code}-${normalizeBook(book)}-${chapter}-${verse}`;
}

/** Fetch verse text from bible-api.com (same source as Flutter app). */
export async function fetchVerseFromApi(
  reference: string,
  translation = DEFAULT_TRANSLATION,
): Promise<VersePayload> {
  const url = `${BIBLE_API_BASE_URL}/${encodeURIComponent(reference)}?translation=${translation.toLowerCase()}`;
  const response = await fetch(url);

  if (!response.ok) {
    throw new Error(`Bible API error ${response.status} for ${reference}`);
  }

  const json = (await response.json()) as BibleApiResponse;
  const ref = json.reference ?? reference;
  const parts = parseReference(ref);
  const firstVerse = json.verses?.[0];
  const translationName = (json.translation_name ?? translation).toUpperCase();

  return {
    verseId: buildVerseId(
      translationName,
      firstVerse?.book_name ?? parts.book,
      firstVerse?.chapter ?? parts.chapter,
      firstVerse?.verse ?? parts.verse,
    ),
    reference: ref,
    text: (json.text ?? firstVerse?.text ?? "").trim(),
    translation: translationName,
    book: firstVerse?.book_name ?? parts.book,
    chapter: firstVerse?.chapter ?? parts.chapter,
    verse: firstVerse?.verse ?? parts.verse,
  };
}
