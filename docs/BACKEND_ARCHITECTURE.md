# Scripture Memorizer — Firebase Backend Architecture (MVP)

**Version:** 1.0  
**Based on:** [PRD.md](../PRD.md)  
**Stack:** Firebase Auth, Cloud Firestore, Cloud Functions, Cloud Storage, FCM  
**MVP scope:** All features free; premium fields reserved for future monetization.

---

## Table of Contents

1. [Architecture Overview](#1-architecture-overview)
2. [Firestore Data Schema](#2-firestore-data-schema)
3. [Firestore Security Rules](#3-firestore-security-rules)
4. [Firebase Project Structure](#4-firebase-project-structure)
5. [Flutter Data Models (JSON)](#5-flutter-data-models-json)
6. [Cloud Functions](#6-cloud-functions)
7. [Offline, Performance & Consistency](#7-offline-performance--consistency)
8. [Migration Notes (Existing Flutter Code)](#8-migration-notes-existing-flutter-code)

---

## 1. Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         Flutter App (iOS / Android)                      │
│  Guest: local Hive/SharedPreferences  │  Auth: Email, Apple, Google      │
└───────────────┬─────────────────────────┴──────────────────┬────────────┘
                │ offline cache                              │ online sync
                ▼                                            ▼
┌───────────────────────────┐              ┌────────────────────────────────┐
│  Local storage            │              │  Firebase                       │
│  • favorites              │   merge on   │  • Authentication               │
│  • progress / streak      │   signup     │  • Firestore (user data)        │
│  • daily verse cache      │◄────────────►│  • Cloud Functions (scheduled)  │
│  • verse catalog cache    │              │  • Storage (catalog JSON, TTS)  │
└───────────────────────────┘              │  • FCM (daily verse push)       │
                                           └────────────────────────────────┘
                │                                            │
                │  read-only                                 │
                ▼                                            ▼
┌───────────────────────────┐              ┌────────────────────────────────┐
│  Bible API / bundled JSON │              │  Admin-only writes              │
│  (verse text, MVP catalog)│              │  daily_verses, config, verses   │
└───────────────────────────┘              └────────────────────────────────┘
```

### Design principles

| Principle | Implementation |
|-----------|----------------|
| **User-owned writes** | Only `users/{uid}/**` is writable by that user |
| **Global content is read-only** | `daily_verses`, `config`, `translations`, `verses` — client read, server write |
| **Denormalize for offline** | Store `reference`, `text`, `translation` on favorites for offline display |
| **Idempotent keys** | Document IDs = `verseId` or `yyyy-MM-dd` to prevent duplicates |
| **MVP = full sync for registered users** | `premiumStatus` field exists but does not gate sync in MVP |
| **Guest → account merge** | Client uploads local snapshot once; server merges with timestamps |

### Collection summary

| Collection | Scope | Written by |
|------------|-------|------------|
| `users` | User profile + settings | User (own doc) |
| `users/{uid}/favorites` | Favorite verses | User |
| `users/{uid}/progress` | Per-verse memorization | User |
| `users/{uid}/sessions` | Practice session log | User |
| `users/{uid}/daily_verse_history` | Viewed daily verses (optional MVP+) | User |
| `users/{uid}/loop_sessions` | Repeat/loop session summaries | User |
| `daily_verses` | Global verse of the day | Cloud Functions / Admin |
| `config` | App config, curated lists | Admin |
| `translations` | Translation metadata | Admin |
| `verses` | Optional cached catalog subset | Admin (optional; MVP may use API + Storage) |

---

## 2. Firestore Data Schema

### 2.1 `users/{userId}`

Root profile document. Created on first successful auth via Cloud Function or client `set` with merge.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `email` | string | yes* | From Firebase Auth (*omitted for Apple private relay if unavailable) |
| `displayName` | string | no | User display name |
| `photoUrl` | string | no | Avatar URL |
| `ageGroup` | string | no | `child` \| `teen` \| `adult` |
| `timezone` | string | no | IANA tz, e.g. `America/New_York` — for daily verse & streak |
| `locale` | string | no | e.g. `en` |
| `premiumStatus` | string | yes | `free` \| `trial` \| `active` \| `expired` (MVP default: `free`) |
| `premiumExpiresAt` | timestamp | no | Future subscription support |
| `authProviders` | array\<string\> | no | `email`, `google.com`, `apple.com` |
| `settings` | map | no | See [UserSettings](#usersettings-map) |
| `streak` | map | yes | Embedded streak (see [Streak](#streak-map-on-user-doc)) |
| `stats` | map | no | Denormalized counters for dashboard |
| `createdAt` | timestamp | yes | Server timestamp on create |
| `updatedAt` | timestamp | yes | Server timestamp on each profile update |
| `lastActiveAt` | timestamp | no | Updated on meaningful activity |

#### `settings` map

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `defaultTranslation` | string | `WEB` | Preferred translation code |
| `ttsVoiceId` | string | null | Platform/cloud voice id |
| `ttsSpeed` | number | `1.0` | 0.5–2.0 |
| `ttsPitch` | number | `1.0` | Low–high multiplier |
| `notificationsEnabled` | boolean | `false` | Daily verse push opt-in |
| `notificationHour` | number | `8` | Local hour 0–23 |
| `minSessionMinutesForStreak` | number | `1` | PRD: configurable minimum session |
| `loopBreakEveryN` | number | `0` | 0 = disabled; break every N loops |

#### `streak` map (on user doc)

| Field | Type | Description |
|-------|------|-------------|
| `currentCount` | number | Consecutive days with qualifying activity |
| `longestCount` | number | All-time best |
| `lastActivityDate` | string | `yyyy-MM-dd` in user's timezone |
| `updatedAt` | timestamp | Last streak recalculation |

#### `stats` map (denormalized)

| Field | Type | Description |
|-------|------|-------------|
| `versesMemorizedCount` | number | Count where status = `memorized` |
| `versesInProgressCount` | number | Count where status = `in_progress` |
| `totalSessionsCount` | number | Lifetime sessions |
| `totalPracticeMinutes` | number | Sum of session durations |

**Example document:**

```json
{
  "email": "user@example.com",
  "displayName": "Jane",
  "ageGroup": "adult",
  "timezone": "America/Chicago",
  "locale": "en",
  "premiumStatus": "free",
  "authProviders": ["google.com"],
  "settings": {
    "defaultTranslation": "WEB",
    "ttsSpeed": 1.0,
    "notificationsEnabled": true,
    "notificationHour": 7,
    "minSessionMinutesForStreak": 1
  },
  "streak": {
    "currentCount": 5,
    "longestCount": 12,
    "lastActivityDate": "2026-05-28"
  },
  "stats": {
    "versesMemorizedCount": 3,
    "versesInProgressCount": 7,
    "totalSessionsCount": 42,
    "totalPracticeMinutes": 180
  },
  "createdAt": "2026-05-01T12:00:00Z",
  "updatedAt": "2026-05-29T08:00:00Z",
  "lastActiveAt": "2026-05-29T08:00:00Z"
}
```

---

### 2.2 `users/{userId}/favorites/{verseId}`

Subcollection (recommended). Document ID = canonical `verseId` (e.g. `WEB-John-3-16`).

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `verseId` | string | yes | Same as document ID |
| `reference` | string | yes | e.g. `John 3:16` |
| `text` | string | yes | Denormalized for offline |
| `translation` | string | yes | e.g. `WEB`, `KJV` |
| `book` | string | no | Denormalized |
| `chapter` | number | no | Denormalized |
| `verse` | number | no | Denormalized |
| `addedAt` | timestamp | yes | Server timestamp |
| `sortOrder` | number | no | Optional manual ordering |

**Example:**

```json
{
  "verseId": "WEB-John-3-16",
  "reference": "John 3:16",
  "text": "For God so loved the world...",
  "translation": "WEB",
  "book": "John",
  "chapter": 3,
  "verse": 16,
  "addedAt": "2026-05-20T14:30:00Z"
}
```

> **MVP free tier (future):** Enforce max 10 favorites via Security Rules + client. For current MVP (all free), set limit to 100 or omit rule.

---

### 2.3 `users/{userId}/progress/{verseId}`

Per-verse memorization state. Document ID = `verseId`.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `verseId` | string | yes | Canonical verse id |
| `reference` | string | no | Display reference |
| `status` | string | yes | `not_started` \| `in_progress` \| `memorized` |
| `percent` | number | yes | 0–100 completion |
| `repeatCount` | number | no | Total repeat/loop iterations (lifetime) |
| `lastMode` | string | no | `read` \| `listen` \| `repeat` \| `recite` \| `fill_in_blank` |
| `lastPracticedAt` | timestamp | yes | Last session on this verse |
| `memorizedAt` | timestamp | no | Set when status → `memorized` |
| `updatedAt` | timestamp | yes | Server timestamp |

**Example:**

```json
{
  "verseId": "WEB-Psalms-23-1",
  "reference": "Psalm 23:1",
  "status": "in_progress",
  "percent": 65,
  "repeatCount": 12,
  "lastMode": "repeat",
  "lastPracticedAt": "2026-05-29T07:15:00Z",
  "updatedAt": "2026-05-29T07:15:00Z"
}
```

---

### 2.4 `users/{userId}/sessions/{sessionId}`

Memorization session log for analytics and streak validation. Auto-generated `sessionId` (UUID).

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `verseId` | string | yes | |
| `reference` | string | no | |
| `mode` | string | yes | Memorization mode |
| `loopsCompleted` | number | no | For repeat/loop mode |
| `loopsTarget` | number | no | 5, 10, 25, or -1 unlimited |
| `durationSeconds` | number | yes | Session length |
| `percentComplete` | number | no | End-of-session score |
| `completed` | boolean | yes | User finished vs abandoned |
| `startedAt` | timestamp | yes | |
| `completedAt` | timestamp | no | |
| `clientId` | string | no | Idempotency key from device |

**Example:**

```json
{
  "verseId": "WEB-John-3-16",
  "reference": "John 3:16",
  "mode": "repeat",
  "loopsCompleted": 10,
  "loopsTarget": 10,
  "durationSeconds": 420,
  "percentComplete": 100,
  "completed": true,
  "startedAt": "2026-05-29T07:00:00Z",
  "completedAt": "2026-05-29T07:07:00Z",
  "clientId": "device-abc-session-xyz"
}
```

---

### 2.5 `users/{userId}/loop_sessions/{loopSessionId}`

Dedicated summaries for Repeat/Loop mode (PRD §4.2.4). Optional if `sessions` already captures loops; use when you want richer loop analytics without bloating `sessions`.

| Field | Type | Description |
|-------|------|-------------|
| `verseId` | string | |
| `reference` | string | |
| `targetLoops` | number | 5, 10, 25, or -1 |
| `completedLoops` | number | |
| `pausedCount` | number | |
| `durationSeconds` | number | |
| `completed` | boolean | |
| `createdAt` | timestamp | |

---

### 2.6 `users/{userId}/daily_verse_history/{dateKey}`

Optional for MVP; recommended for “history archive” (premium roadmap). Document ID = `yyyy-MM-dd` (user-local or UTC — pick one and document).

| Field | Type | Description |
|-------|------|-------------|
| `dateKey` | string | `yyyy-MM-dd` |
| `verseId` | string | |
| `reference` | string | |
| `translation` | string | |
| `viewedAt` | timestamp | First view |
| `memorized` | boolean | User completed memorize flow |
| `shared` | boolean | Future: share card |

---

### 2.7 `daily_verses/{dateKey}`

Global daily verse. Document ID = `yyyy-MM-dd` (UTC recommended for consistency; app converts to local for display).

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `dateKey` | string | yes | `yyyy-MM-dd` |
| `verseId` | string | yes | Canonical id |
| `reference` | string | yes | |
| `text` | string | yes | Full verse text |
| `translation` | string | yes | |
| `book` | string | yes | |
| `chapter` | number | yes | |
| `verse` | number | yes | |
| `curatedListId` | string | no | Source list id |
| `publishedAt` | timestamp | yes | When CF published |
| `expiresAt` | timestamp | no | End of day UTC |

**Example:**

```json
{
  "dateKey": "2026-05-29",
  "verseId": "WEB-Philippians-4-13",
  "reference": "Philippians 4:13",
  "text": "I can do all things through Christ...",
  "translation": "WEB",
  "book": "Philippians",
  "chapter": 4,
  "verse": 13,
  "curatedListId": "mvp_curated",
  "publishedAt": "2026-05-29T00:05:00Z"
}
```

---

### 2.8 `config/{docId}`

App-wide configuration. Suggested documents: `app`, `daily_verse`, `curated_lists`.

#### `config/daily_verse`

| Field | Type | Description |
|-------|------|-------------|
| `rotationStrategy` | string | `day_of_year` \| `sequential` \| `random_seeded` |
| `curatedReferences` | array\<string\> | e.g. `["John 3:16", ...]` |
| `defaultTranslation` | string | `WEB` |
| `publishHourUtc` | number | When scheduled function runs |

#### `config/curated_lists`

| Field | Type | Description |
|-------|------|-------------|
| `lists` | array\<map\> | `{ id, title, description, verseIds[] }` |

---

### 2.9 `translations/{translationId}`

Read-only metadata (PRD §4.2.6).

| Field | Type | Description |
|-------|------|-------------|
| `code` | string | `KJV`, `WEB`, `NIV` |
| `name` | string | Display name |
| `language` | string | `en` |
| `license` | string | Copyright notice |
| `isPremium` | boolean | Future gating |
| `sortOrder` | number | |

---

### 2.10 `verses/{verseId}` (optional)

Optional Firestore cache for free-catalog subset. MVP may rely on Bible API + local cache instead.

| Field | Type | Description |
|-------|------|-------------|
| `translation` | string | |
| `book` | string | |
| `chapter` | number | |
| `verse` | number | |
| `text` | string | |
| `reference` | string | |
| `tags` | array\<string\> | `comfort`, `kids`, etc. |
| `isFreeTier` | boolean | |

---

### 2.11 Indexes (Firestore)

Create composite indexes as needed:

| Collection | Fields | Query use |
|------------|--------|-----------|
| `users/{uid}/favorites` | `addedAt` DESC | Recent favorites |
| `users/{uid}/progress` | `status`, `lastPracticedAt` DESC | Filter memorized / recent |
| `users/{uid}/sessions` | `completedAt` DESC | Activity feed |
| `users/{uid}/sessions` | `verseId`, `completedAt` DESC | Per-verse history |
| `daily_verses` | `dateKey` | Single-doc get by id (no composite needed) |

---

## 3. Firestore Security Rules

Save as `firestore.rules` in the Firebase project root.

```javascript
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {

    // ─── Helpers ───────────────────────────────────────────────────────────

    function isSignedIn() {
      return request.auth != null;
    }

    function isOwner(userId) {
      return isSignedIn() && request.auth.uid == userId;
    }

    function isValidAgeGroup() {
      return !('ageGroup' in request.resource.data)
        || request.resource.data.ageGroup in ['child', 'teen', 'adult'];
    }

    function isValidPremiumStatus() {
      return !('premiumStatus' in request.resource.data)
        || request.resource.data.premiumStatus in ['free', 'trial', 'active', 'expired'];
    }

    function isValidMemorizationStatus() {
      return request.resource.data.status in ['not_started', 'in_progress', 'memorized'];
    }

    function isValidPercent() {
      return request.resource.data.percent is int
        && request.resource.data.percent >= 0
        && request.resource.data.percent <= 100;
    }

    function isValidMode() {
      return request.resource.data.mode in [
        'read', 'listen', 'repeat', 'recite', 'fill_in_blank'
      ];
    }

    // Prevent clients from setting server-only or privilege fields on create/update
    function userProfileAllowedKeys() {
      let forbidden = ['premiumExpiresAt', 'role', 'isAdmin'];
      return !request.resource.data.keys().hasAny(forbidden);
    }

  // ─── User profile ────────────────────────────────────────────────────────

    match /users/{userId} {
      allow read: if isOwner(userId);
      allow create: if isOwner(userId)
        && isValidAgeGroup()
        && isValidPremiumStatus()
        && userProfileAllowedKeys()
        // MVP: force free tier on client writes; RevenueCat/webhook upgrades later
        && request.resource.data.premiumStatus == 'free';
      allow update: if isOwner(userId)
        && isValidAgeGroup()
        && userProfileAllowedKeys()
        // Users cannot self-assign premium
        && (!('premiumStatus' in request.resource.data.diff(resource.data).affectedKeys())
            || request.resource.data.premiumStatus == resource.data.premiumStatus)
        && (!('premiumExpiresAt' in request.resource.data)
            || request.resource.data.premiumExpiresAt == resource.data.get('premiumExpiresAt', null));
      allow delete: if isOwner(userId);

      // ─── Favorites subcollection ─────────────────────────────────────────

      match /favorites/{verseId} {
        allow read: if isOwner(userId);
        allow create: if isOwner(userId)
          && request.resource.data.verseId == verseId
          && request.resource.data.keys().hasAll(['verseId', 'reference', 'text', 'translation', 'addedAt'])
          // MVP: generous limit; tighten to 10 for free tier later
          && get(/databases/$(database)/documents/users/$(userId)/favorites).size() < 100;
        allow update: if isOwner(userId)
          && request.resource.data.verseId == verseId;
        allow delete: if isOwner(userId);
      }

      // ─── Progress subcollection ──────────────────────────────────────────

      match /progress/{verseId} {
        allow read: if isOwner(userId);
        allow create, update: if isOwner(userId)
          && request.resource.data.verseId == verseId
          && isValidMemorizationStatus()
          && isValidPercent();
        allow delete: if isOwner(userId);
      }

      // ─── Sessions subcollection ──────────────────────────────────────────

      match /sessions/{sessionId} {
        allow read: if isOwner(userId);
        allow create: if isOwner(userId)
          && isValidMode()
          && request.resource.data.durationSeconds is int
          && request.resource.data.durationSeconds >= 0
          && request.resource.data.completed is bool;
        // Sessions are append-only (no tampering with history)
        allow update, delete: if false;
      }

      // ─── Loop sessions ───────────────────────────────────────────────────

      match /loop_sessions/{loopSessionId} {
        allow read: if isOwner(userId);
        allow create: if isOwner(userId)
          && request.resource.data.targetLoops is int
          && request.resource.data.completedLoops is int
          && request.resource.data.completedLoops >= 0;
        allow update, delete: if false;
      }

      // ─── Daily verse history (per user) ──────────────────────────────────

      match /daily_verse_history/{dateKey} {
        allow read: if isOwner(userId);
        allow create, update: if isOwner(userId)
          && dateKey.matches('^\\d{4}-\\d{2}-\\d{2}$');
        allow delete: if isOwner(userId);
      }

      // ─── Legacy embedded data path (optional migration support) ──────────
      // users/{uid}/data/{docId} — matches existing Flutter FirestoreUserDatasource

      match /data/{docId} {
        allow read, write: if isOwner(userId);
      }
    }

    // ─── Global read-only content ────────────────────────────────────────────

    match /daily_verses/{dateKey} {
      allow read: if true;  // Guests need daily verse
      allow write: if false; // Cloud Functions use Admin SDK
    }

    match /config/{docId} {
      allow read: if true;
      allow write: if false;
    }

    match /translations/{translationId} {
      allow read: if true;
      allow write: if false;
    }

    match /verses/{verseId} {
      allow read: if true;
      allow write: if false;
    }

    // Deny all other paths
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

### Rules notes

1. **`get()` on favorites count** — Firestore rules `get()` on a collection path returns collection metadata in rules v2 only for `list` operations; for `create` validation of count, prefer a Cloud Function or maintain `stats.favoritesCount` on the user doc updated atomically via transaction.
2. **Simpler favorite limit (MVP):** Remove the `get().size()` check and enforce limits in the app until you add a counter field + transaction.
3. **Premium upgrades:** Use Callable Function or RevenueCat Firebase Extension to set `premiumStatus` with Admin SDK (bypasses rules).

**Revised favorite limit (recommended):** Track `stats.favoritesCount` on user profile, validate in rules:

```javascript
// In favorites create rule, replace get().size() with:
&& get(/databases/$(database)/documents/users/$(userId)).data.get('stats', {}).get('favoritesCount', 0) < 100;
```

---

## 4. Firebase Project Structure

```
scripture-memorizer/                    # Firebase project root (repo: /firebase)
├── .firebaserc                         # Project aliases (dev, staging, prod)
├── firebase.json                       # Services config
├── firestore.rules
├── firestore.indexes.json
├── storage.rules
├── functions/
│   ├── package.json
│   ├── tsconfig.json
│   └── src/
│       ├── index.ts                    # Exports all functions
│       ├── auth/
│       │   └── onUserCreate.ts         # Initialize user profile
│       ├── dailyVerse/
│       │   ├── publishDailyVerse.ts    # Scheduled rotation
│       │   └── fetchDailyVerse.ts      # Callable: get today’s verse
│       ├── streaks/
│       │   └── updateStreak.ts         # Callable or trigger on session
│       ├── sync/
│       │   └── mergeGuestData.ts       # Callable: guest → account merge
│       └── admin/
│           └── seedCatalog.ts          # One-time verse/config seed
├── seed/
│   ├── config.daily_verse.json
│   ├── translations.json
│   └── curated_references.json
└── README.md
```

### `firebase.json` (minimal)

```json
{
  "firestore": {
    "rules": "firestore.rules",
    "indexes": "firestore.indexes.json"
  },
  "functions": [
    {
      "source": "functions",
      "codebase": "default",
      "ignore": ["node_modules", ".git", "firebase-debug.log", "firebase-debug.*.log", "*.local"]
    }
  ],
  "storage": {
    "rules": "storage.rules"
  },
  "emulators": {
    "auth": { "port": 9099 },
    "functions": { "port": 5001 },
    "firestore": { "port": 8080 },
    "storage": { "port": 9199 },
    "ui": { "enabled": true }
  }
}
```

### Environment strategy

| Alias | Use |
|-------|-----|
| `dev` | Local emulators + test data |
| `staging` | QA, TestFlight / internal track |
| `prod` | App Store / Play production |

### Authentication providers

Enable in Firebase Console → Authentication:

- Email/Password
- Google
- Apple (iOS required for App Store if other social logins exist)

### Storage buckets (optional MVP)

| Path | Access | Content |
|------|--------|---------|
| `catalog/verses/{translation}.json` | Public read | Free tier verse bundle |
| `tts-cache/{userId}/{verseId}.mp3` | User read/write | Premium offline audio (future) |

---

## 5. Flutter Data Models (JSON)

These align with existing Dart models in `lib/data/models/` and Firestore field names (camelCase in app maps; Firestore Timestamps serialize to ISO-8601 in JSON examples).

### 5.1 UserProfile

```json
{
  "id": "firebase_uid_abc123",
  "email": "user@example.com",
  "displayName": "Jane Doe",
  "photoUrl": null,
  "ageGroup": "adult",
  "timezone": "America/New_York",
  "locale": "en",
  "premiumStatus": "free",
  "premiumExpiresAt": null,
  "settings": {
    "defaultTranslation": "WEB",
    "ttsVoiceId": null,
    "ttsSpeed": 1.0,
    "ttsPitch": 1.0,
    "notificationsEnabled": false,
    "notificationHour": 8,
    "minSessionMinutesForStreak": 1,
    "loopBreakEveryN": 0
  },
  "streak": {
    "currentCount": 5,
    "longestCount": 12,
    "lastActivityDate": "2026-05-28"
  },
  "stats": {
    "versesMemorizedCount": 3,
    "versesInProgressCount": 7,
    "favoritesCount": 4,
    "totalSessionsCount": 42,
    "totalPracticeMinutes": 180
  },
  "createdAt": "2026-05-01T12:00:00.000Z",
  "updatedAt": "2026-05-29T08:00:00.000Z"
}
```

### 5.2 FavoriteVerse

Matches `FavoriteVerse.toMap()`:

```json
{
  "verseId": "WEB-John-3-16",
  "addedAt": "2026-05-20T14:30:00.000Z",
  "reference": "John 3:16",
  "text": "For God so loved the world, that he gave his only begotten Son...",
  "translation": "WEB",
  "book": "John",
  "chapter": 3,
  "verse": 16
}
```

### 5.3 UserProgress

Matches `UserProgress.toMap()`:

```json
{
  "verseId": "WEB-Psalms-23-1",
  "status": "in_progress",
  "percent": 65,
  "lastPracticedAt": "2026-05-29T07:15:00.000Z",
  "repeatCount": 12,
  "reference": "Psalm 23:1",
  "lastMode": "repeat",
  "memorizedAt": null
}
```

**Status enum strings:** `not_started` | `in_progress` | `memorized`

### 5.4 StreakData

Matches `StreakData.toMap()`:

```json
{
  "currentCount": 5,
  "longestCount": 12,
  "lastActivityDate": "2026-05-28"
}
```

### 5.5 MemorizationSession

```json
{
  "id": "session_uuid",
  "verseId": "WEB-John-3-16",
  "reference": "John 3:16",
  "mode": "repeat",
  "loopsCompleted": 10,
  "loopsTarget": 10,
  "durationSeconds": 420,
  "percentComplete": 100,
  "completed": true,
  "startedAt": "2026-05-29T07:00:00.000Z",
  "completedAt": "2026-05-29T07:07:00.000Z",
  "clientId": "device-abc-session-xyz"
}
```

### 5.6 LoopSession

```json
{
  "id": "loop_session_uuid",
  "verseId": "WEB-John-3-16",
  "reference": "John 3:16",
  "targetLoops": 10,
  "completedLoops": 10,
  "pausedCount": 1,
  "durationSeconds": 420,
  "completed": true,
  "createdAt": "2026-05-29T07:00:00.000Z"
}
```

### 5.7 DailyVerse

```json
{
  "dateKey": "2026-05-29",
  "verseId": "WEB-Philippians-4-13",
  "reference": "Philippians 4:13",
  "text": "I can do all things in Christ who strengthens me.",
  "translation": "WEB",
  "book": "Philippians",
  "chapter": 4,
  "verse": 13,
  "publishedAt": "2026-05-29T00:05:00.000Z"
}
```

### 5.8 Verse (catalog)

Matches `Verse.toMap()`:

```json
{
  "id": "WEB-John-3-16",
  "translation": "WEB",
  "book": "John",
  "chapter": 3,
  "verse": 16,
  "text": "For God so loved the world...",
  "reference": "John 3:16"
}
```

### 5.9 Translation

```json
{
  "id": "WEB",
  "code": "WEB",
  "name": "World English Bible",
  "language": "en",
  "license": "Public Domain",
  "isPremium": false,
  "sortOrder": 1
}
```

### 5.10 GuestMergePayload (Callable Function input)

Used when guest signs up (PRD §4.2.7):

```json
{
  "favorites": [ "/* FavoriteVerse[] */" ],
  "progress": [ "/* UserProgress[] */" ],
  "streak": { "/* StreakData */" },
  "localUpdatedAt": "2026-05-29T08:00:00.000Z"
}
```

---

## 6. Cloud Functions

All functions use **Firebase Admin SDK** for writes to `daily_verses` and privileged user fields.

### 6.1 `auth.onUserCreate` (Trigger)

| Property | Value |
|----------|-------|
| **Trigger** | `functions.auth.user().onCreate` |
| **Purpose** | Create `users/{uid}` with defaults |

**Actions:**

1. Set `email`, `displayName`, `photoUrl` from Auth record
2. Set `premiumStatus: 'free'`, default `settings`, `streak: { currentCount: 0, longestCount: 0 }`
3. Set `stats` counters to 0
4. Set `createdAt`, `updatedAt` server timestamps

### 6.2 `dailyVerse.publishDailyVerse` (Scheduled)

| Property | Value |
|----------|-------|
| **Trigger** | `functions.pubsub.schedule('5 0 * * *').timeZone('UTC')` |
| **Purpose** | Publish global daily verse |

**Algorithm (aligns with current app `dayOfYear % curatedReferences.length`):**

1. Read `config/daily_verse.curatedReferences` and `defaultTranslation`
2. Compute `dateKey` for today (UTC)
3. `index = dayOfYear % references.length`
4. Resolve verse text (Bible API or `verses` collection)
5. Write `daily_verses/{dateKey}` (idempotent — skip if exists)
6. Optionally pre-publish tomorrow’s doc

### 6.3 `dailyVerse.getDailyVerse` (Callable, optional)

| Property | Value |
|----------|-------|
| **Trigger** | HTTPS Callable |
| **Auth** | Optional (guests allowed) |
| **Input** | `{ dateKey?: string, timezone?: string }` |
| **Returns** | `DailyVerse` JSON |

Falls back to latest `daily_verses` doc if client date mismatches timezone edge cases.

### 6.4 `streaks.recordActivity` (Callable or Firestore trigger)

| Property | Value |
|----------|-------|
| **Trigger** | Callable after `memorize_complete` **or** `onCreate` on `users/{uid}/sessions` |
| **Purpose** | Recompute streak server-side (source of truth) |

**Logic:**

1. Load user `timezone` and `settings.minSessionMinutesForStreak`
2. Verify session `completed == true` and `durationSeconds >= min * 60`
3. Compare `lastActivityDate` with today/yesterday in user TZ
4. Update `users/{uid}.streak` and `stats`
5. Return updated `StreakData`

### 6.5 `sync.mergeGuestData` (Callable)

| Property | Value |
|----------|-------|
| **Trigger** | HTTPS Callable |
| **Auth** | Required |
| **Input** | `GuestMergePayload` |

**Merge strategy (PRD: last-write-wins with timestamp):**

| Entity | Rule |
|--------|------|
| Favorites | Union by `verseId`; keep newer `addedAt` |
| Progress | Per `verseId`, keep row with newer `lastPracticedAt` |
| Streak | Keep higher `currentCount` / `longestCount`; reconcile dates |

Run as batched writes (max 500 ops per batch).

### 6.6 `progress.updateStats` (Firestore trigger, optional)

| Property | Value |
|----------|-------|
| **Trigger** | `onWrite` `users/{uid}/progress/{verseId}` |
| **Purpose** | Maintain `stats.versesMemorizedCount` and `versesInProgressCount` |

### 6.7 Functions NOT required for MVP

| Function | When to add |
|----------|-------------|
| RevenueCat webhook | Premium subscriptions launch |
| FCM `sendDailyVerseReminders` | Push notifications enabled |
| `exportUserData` / `deleteUserData` | GDPR/CCPA compliance |
| Speech/recite scoring | Phase 2 |

### Example: scheduled daily verse (TypeScript sketch)

```typescript
import * as functions from 'firebase-functions/v2';
import * as admin from 'firebase-admin';

admin.initializeApp();

export const publishDailyVerse = functions.scheduler.onSchedule(
  { schedule: '5 0 * * *', timeZone: 'UTC' },
  async () => {
    const db = admin.firestore();
    const now = new Date();
    const dateKey = now.toISOString().slice(0, 10);
    const docRef = db.collection('daily_verses').doc(dateKey);

    if ((await docRef.get()).exists) return;

    const config = (await db.doc('config/daily_verse').get()).data()!;
    const refs: string[] = config.curatedReferences ?? [];
    const start = new Date(now.getFullYear(), 0, 0);
    const dayOfYear = Math.floor((now.getTime() - start.getTime()) / 86400000);
    const reference = refs[dayOfYear % refs.length];

    // fetchVerseFromApi(reference) → verse object
    const verse = await fetchVerseFromApi(reference, config.defaultTranslation);

    await docRef.set({
      dateKey,
      verseId: verse.id,
      reference: verse.reference,
      text: verse.text,
      translation: verse.translation,
      book: verse.book,
      chapter: verse.chapter,
      verse: verse.verse,
      curatedListId: 'mvp_curated',
      publishedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }
);
```

---

## 7. Offline, Performance & Consistency

### 7.1 Offline support

| Data | Strategy |
|------|----------|
| **Firestore user data** | Enable persistence: `FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true)` |
| **Daily verse** | Read `daily_verses/{today}`; cache in local storage (existing `LocalStorageDatasource`) |
| **Favorites / progress** | Subcollection listeners + local repository mirror; write queue retries automatically |
| **Verse catalog** | Bundle JSON in app assets + Bible API; not dependent on Firestore for MVP |
| **TTS** | Platform TTS offline; optional Storage cache for premium later |

### 7.2 Performance

| Practice | Detail |
|----------|--------|
| **Prefer subcollections over giant arrays** | Avoid 1 MB document limit; enable paginated queries |
| **Denormalize display fields** | Store `reference`, `text` on favorites to avoid extra verse lookups offline |
| **Batch writes** | Merge guest data and multi-verse updates in single batch |
| **Listeners scoped by user** | `users/{uid}/favorites` not root collection queries |
| **Daily verse** | Single doc read by ID — O(1), cache-friendly |
| **Indexes** | Only create composites you query; avoid over-indexing |
| **Cold start** | Keep Cloud Functions warm only for critical callables (optional min instances post-MVP) |

### 7.3 Data consistency

| Concern | Approach |
|---------|----------|
| **Streak accuracy** | Server-side `recordActivity` as source of truth; client shows optimistic UI |
| **Sync conflicts** | Last-write-wins on `lastPracticedAt` / `updatedAt` per `verseId` |
| **Idempotent sessions** | Client sends `clientId`; reject duplicate `sessions` with same `clientId` |
| **Timestamps** | Use `FieldValue.serverTimestamp()` for `createdAt`/`updatedAt`; store user-facing dates as `yyyy-MM-dd` strings in user TZ |
| **Transactions** | Use when updating `stats` + `progress` atomically |
| **Guest merge** | Single callable; disable local guest ID after success |

### 7.4 Security & privacy (PRD §6.4)

- Minimize child PII; `ageGroup` only, no birthdate in MVP
- Account deletion: implement `deleteUserData` function (removes `users/{uid}` and subcollections)
- No PII in Analytics/Crashlytics custom keys
- Encrypt sensitive local storage (flutter_secure_storage for tokens)

### 7.5 Analytics events (server-side optional)

Mirror PRD §9.3 — primarily client Firebase Analytics; optionally log anonymized aggregates via BigQuery export later.

---

## 8. Migration Notes (Existing Flutter Code)

The app currently uses **embedded arrays** under `users/{uid}/data/`:

| Document | Structure |
|----------|-----------|
| `data/favorites` | `{ items: FavoriteVerse[], updatedAt }` |
| `data/progress` | `{ items: UserProgress[], updatedAt }` |
| `data/streak` | `StreakData` + `updatedAt` |

See `lib/data/datasources/firestore_user_datasource.dart`.

### Recommended path

1. **Phase A (MVP):** Keep `data/*` documents working; security rules already allow `users/{uid}/data/{docId}`.
2. **Phase B:** Add subcollections; dual-write from app during transition.
3. **Phase C:** Migrate with one-time Cloud Function; remove `data/*` reads.

### New `FirestoreUserDatasource` paths

| Method | New path |
|--------|----------|
| `getFavorites` | `users/{uid}/favorites` collection |
| `getProgress` | `users/{uid}/progress` collection |
| `getStreak` | `users/{uid}` document field `.streak` |
| `getDailyVerse` | `daily_verses/{yyyy-MM-dd}` |

---

## Appendix A: Canonical `verseId` format

```
{TRANSLATION}-{BookNormalized}-{chapter}-{verse}
```

Example: `WEB-John-3-16`, `KJV-Psalms-23-1`

Normalize book names (spaces → no spaces, consistent casing) in a shared Dart utility.

---

## Appendix B: MVP checklist

- [ ] Firebase project created; iOS/Android apps registered
- [ ] Auth providers: Email, Google, Apple
- [ ] Deploy `firestore.rules` and indexes
- [ ] Seed `config/daily_verse` with `curatedReferences` from `AppConstants`
- [ ] Deploy `publishDailyVerse` scheduled function
- [ ] Deploy `onUserCreate` profile initializer
- [ ] Implement `mergeGuestData` callable
- [ ] Update Flutter datasource to read `daily_verses` + subcollections
- [ ] Enable Firestore offline persistence
- [ ] Test guest → signup merge and security rule denial for other users’ data

---

*Document maintained alongside [PRD.md](../PRD.md). Version bump on schema-breaking changes.*
