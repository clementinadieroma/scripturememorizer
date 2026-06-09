/**
 * Scripture Memorizer — Cloud Functions entry point.
 *
 * Exports all triggers and HTTPS callables for the Firebase backend.
 * See docs/BACKEND_ARCHITECTURE.md for schema and deployment details.
 */

import "./admin";

export { createUserProfile } from "./functions/createUserProfile";
export { getDailyVerse } from "./functions/getDailyVerse";
export { publishDailyVerse } from "./functions/publishDailyVerse";
export { updateMemorizationProgressFn as updateMemorizationProgress } from "./functions/updateMemorizationProgress";
export { toggleFavorite } from "./functions/toggleFavorite";
export { getUserStats } from "./functions/getUserStats";
