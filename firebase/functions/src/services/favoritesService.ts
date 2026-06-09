import { FieldValue, getFirestore, Timestamp } from "firebase-admin/firestore";

import { COLLECTIONS, FAVORITE_LIMIT, SUBCOLLECTIONS } from "../config/constants";
import { FavoriteVerse, ToggleFavoriteRequest, ToggleFavoriteResponse } from "../types";
import { AppError } from "../utils/errors";

const db = getFirestore();

function favoritesRef(uid: string) {
  return db
    .collection(COLLECTIONS.USERS)
    .doc(uid)
    .collection(SUBCOLLECTIONS.FAVORITES);
}

function userRef(uid: string) {
  return db.collection(COLLECTIONS.USERS).doc(uid);
}

/** Add or remove a favorite verse in users/{uid}/favorites/{verseId}. */
export async function toggleFavorite(
  uid: string,
  request: ToggleFavoriteRequest,
): Promise<ToggleFavoriteResponse> {
  const { verseId, reference, text, translation, book, chapter, verse } = request;
  const favRef = favoritesRef(uid).doc(verseId);
  const existing = await favRef.get();

  let shouldAdd: boolean;
  if (typeof request.add === "boolean") {
    shouldAdd = request.add;
  } else {
    shouldAdd = !existing.exists;
  }

  if (shouldAdd && existing.exists) {
    const favorite = existing.data() as FavoriteVerse;
    const userSnap = await userRef(uid).get();
    const favoritesCount =
      (userSnap.data()?.stats as { favoritesCount?: number } | undefined)
        ?.favoritesCount ?? 1;

    return {
      isFavorite: true,
      favoritesCount,
      favorite,
    };
  }

  if (!shouldAdd && !existing.exists) {
    const userSnap = await userRef(uid).get();
    const favoritesCount =
      (userSnap.data()?.stats as { favoritesCount?: number } | undefined)
        ?.favoritesCount ?? 0;

    return {
      isFavorite: false,
      favoritesCount,
    };
  }

  if (shouldAdd) {
    const userSnap = await userRef(uid).get();
    const currentCount =
      (userSnap.data()?.stats as { favoritesCount?: number } | undefined)
        ?.favoritesCount ?? 0;

    if (currentCount >= FAVORITE_LIMIT) {
      throw new AppError(
        "resource-exhausted",
        `Favorite limit reached (${FAVORITE_LIMIT}).`,
      );
    }

    const favorite: FavoriteVerse = {
      verseId,
      reference,
      text,
      translation: translation.toUpperCase(),
      book,
      chapter,
      verse,
      addedAt: Timestamp.now(),
    };

    await db.runTransaction(async (tx) => {
      tx.set(favRef, favorite);
      tx.set(
        userRef(uid),
        {
          "stats.favoritesCount": FieldValue.increment(1),
          updatedAt: FieldValue.serverTimestamp(),
          lastActiveAt: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
    });

    return {
      isFavorite: true,
      favoritesCount: currentCount + 1,
      favorite,
    };
  }

  const userSnap = await userRef(uid).get();
  const currentCount =
    (userSnap.data()?.stats as { favoritesCount?: number } | undefined)
      ?.favoritesCount ?? 1;

  await db.runTransaction(async (tx) => {
    tx.delete(favRef);
    tx.set(
      userRef(uid),
      {
        "stats.favoritesCount": FieldValue.increment(-1),
        updatedAt: FieldValue.serverTimestamp(),
        lastActiveAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
  });

  return {
    isFavorite: false,
    favoritesCount: Math.max(0, currentCount - 1),
  };
}

/** Count favorites subcollection (for stats reconciliation). */
export async function countFavorites(uid: string): Promise<number> {
  const snap = await favoritesRef(uid).count().get();
  return snap.data().count;
}
