# Cloud Functions — Scripture Memorizer

TypeScript Firebase Cloud Functions for auth profiles, daily verse, favorites, progress, and stats.

## Folder structure

```
functions/
├── package.json
├── tsconfig.json
├── tsconfig.dev.json
├── .eslintrc.js
├── .gitignore
└── src/
    ├── index.ts                 # Exports all functions
    ├── admin.ts                 # Firebase Admin init
    ├── config/
    │   └── constants.ts
    ├── types/
    │   └── index.ts
    ├── utils/
    │   ├── dates.ts
    │   ├── errors.ts
    │   └── verse.ts
    ├── services/
    │   ├── userService.ts
    │   ├── dailyVerseService.ts
    │   ├── favoritesService.ts
    │   ├── progressService.ts
    │   └── statsService.ts
    └── functions/
        ├── createUserProfile.ts
        ├── getDailyVerse.ts
        ├── publishDailyVerse.ts
        ├── updateMemorizationProgress.ts
        ├── toggleFavorite.ts
        └── getUserStats.ts
```

## Exported functions

| Export | Type | Auth |
|--------|------|------|
| `createUserProfile` | Auth onCreate | — |
| `getDailyVerse` | Callable | Optional |
| `publishDailyVerse` | Scheduled (00:05 UTC) | — |
| `updateMemorizationProgress` | Callable | Required |
| `toggleFavorite` | Callable | Required |
| `getUserStats` | Callable | Required |

## Setup & deploy

From the **`firebase/`** directory (parent of `functions/`):

```bash
# 1. Install Firebase CLI (once)
npm install -g firebase-tools

# 2. Login and select project
firebase login
firebase use your-firebase-project-id

# 3. Install function dependencies
cd functions
npm install

# 4. Build TypeScript
npm run build

# 5. Deploy (from firebase/ root)
cd ..
firebase deploy --only functions

# Or deploy everything (rules + functions)
firebase deploy
```

## Local emulators

```bash
cd firebase/functions && npm run build && cd ..
firebase emulators:start --only functions,firestore,auth
```

## Flutter callable examples

```dart
final functions = FirebaseFunctions.instance;

// Daily verse (guest OK)
final daily = await functions.httpsCallable('getDailyVerse').call({
  'timezone': 'America/New_York',
});

// Toggle favorite
await functions.httpsCallable('toggleFavorite').call({
  'verseId': 'WEB-John-3-16',
  'reference': 'John 3:16',
  'text': '...',
  'translation': 'WEB',
  'add': true,
});

// Update progress after loop session
await functions.httpsCallable('updateMemorizationProgress').call({
  'verseId': 'WEB-John-3-16',
  'reference': 'John 3:16',
  'percent': 100,
  'status': 'memorized',
  'repeatCountDelta': 10,
  'loopsCompleted': 10,
  'lastMode': 'repeat',
  'durationSeconds': 420,
  'completed': true,
  'clientId': 'unique-session-id',
});

// Dashboard stats
final stats = await functions.httpsCallable('getUserStats').call({
  'recalculate': true,
});
```

See [../docs/BACKEND_ARCHITECTURE.md](../docs/BACKEND_ARCHITECTURE.md) for the full Firestore schema.
