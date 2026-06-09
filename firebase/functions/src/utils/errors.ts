import * as functions from "firebase-functions/v1";

/** Structured application error mapped to HTTPS callable codes. */
export class AppError extends Error {
  constructor(
    public readonly code: functions.https.FunctionsErrorCode,
    message: string,
  ) {
    super(message);
    this.name = "AppError";
  }
}

/** Convert unknown errors into HttpsError for callable functions. */
export function toHttpsError(error: unknown): functions.https.HttpsError {
  if (error instanceof AppError) {
    return new functions.https.HttpsError(error.code, error.message);
  }

  if (error instanceof functions.https.HttpsError) {
    return error;
  }

  const message = error instanceof Error ? error.message : "Unknown error";
  functions.logger.error("Unhandled error", error);
  return new functions.https.HttpsError("internal", message);
}

/** Assert authenticated callable request (Gen 1 or Gen 2); throws if missing. */
export function requireAuthUid(context: {
  auth?: { uid?: string } | null;
}): string {
  if (!context.auth?.uid) {
    throw new AppError("unauthenticated", "Authentication required.");
  }
  return context.auth.uid;
}

/** Validate required string field on callable payload. */
export function requireString(
  data: Record<string, unknown> | undefined,
  field: string,
): string {
  const value = data?.[field];
  if (typeof value !== "string" || value.trim().length === 0) {
    throw new AppError("invalid-argument", `Missing or invalid field: ${field}`);
  }
  return value.trim();
}

/** Clamp integer to inclusive range. */
export function clampInt(value: number, min: number, max: number): number {
  return Math.min(max, Math.max(min, Math.round(value)));
}
