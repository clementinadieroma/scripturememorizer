import { onCall } from "firebase-functions/v2/https";
import * as functions from "firebase-functions/v1";

import "../admin";
import { toggleFavorite as toggleFavoriteService } from "../services/favoritesService";
import { ToggleFavoriteRequest } from "../types";
import { requireAuthUid, requireString, toHttpsError } from "../utils/errors";

/**
 * Callable: add or remove a verse from users/{uid}/favorites/{verseId}.
 * Pass add: true/false to force action, or omit to toggle.
 * Requires authentication.
 */
export const toggleFavorite = onCall(
  { cors: true },
  async (request) => {
    try {
      const uid = requireAuthUid(request);
      const data = (request.data ?? {}) as ToggleFavoriteRequest;
      const payload = data as unknown as Record<string, unknown>;

      const verseId = requireString(payload, "verseId");
      const isExplicitRemove = data.add === false;

      if (!isExplicitRemove) {
        requireString(payload, "reference");
        requireString(payload, "text");
        requireString(payload, "translation");
      } else if (!payload.reference || !payload.text || !payload.translation) {
        // Removal only needs verseId; placeholders for type satisfaction.
        data.reference = data.reference ?? "";
        data.text = data.text ?? "";
        data.translation = data.translation ?? "WEB";
      }

      functions.logger.info("toggleFavorite", { uid, verseId, add: data.add });

      const result = await toggleFavoriteService(uid, {
        verseId,
        reference: (payload.reference as string) ?? "",
        text: (payload.text as string) ?? "",
        translation: (payload.translation as string) ?? "WEB",
        book: data.book,
        chapter: data.chapter,
        verse: data.verse,
        add: data.add,
      });

      return {
        success: true,
        isFavorite: result.isFavorite,
        favoritesCount: result.favoritesCount,
        favorite: result.favorite
          ? {
            ...result.favorite,
            addedAt: result.favorite.addedAt.toDate().toISOString(),
          }
          : null,
      };
    } catch (error) {
      throw toHttpsError(error);
    }
  },
);
