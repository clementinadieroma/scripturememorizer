# Scripture Memorizer App (MVP)

Flutter MVP for memorizing Bible verses — built from `PRD.md` and `ARCHITECTURE.md`.

## Features

- Email/password and Google Sign-In (Firebase Auth)
- Browse curated verses and search by reference or keyword
- Daily Verse on Home
- Verse Detail with TTS (male/female, speed) and Repeat/Loop (5×, 10×, 25×, Unlimited)
- Favorites (per user, local + Firestore when signed in)
- Progress tracking and streaks

## Quick start

### 1. Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (stable, >=3.16)
- Firebase project with Auth (Email + Google) and Firestore

### 2. Generate platform folders (if missing)

From this directory:

```powershell
cd "c:\Users\User\Desktop\Scripture Memorizer App"
flutter create . --org com.scripturememorizer --project-name scripture_memorizer
flutter pub get
```

### 3. Configure Firebase

```powershell
dart pub global activate flutterfire_cli
flutterfire configure
```

This replaces `lib/firebase_options.dart` with real keys.

Enable in Firebase Console:

- **Authentication:** Email/Password, Google
- **Firestore:** start in test mode, then deploy rules from `firestore.rules`

### 4. Google Sign-In

- **Android:** Add SHA-1 to Firebase; download `google-services.json` into `android/app/`
- **iOS:** Add `GoogleService-Info.plist` to `ios/Runner/`

### 5. Run

```powershell
flutter run
```

## Bible API

Uses free [bible-api.com](https://bible-api.com) (World English Bible by default). No API key required.

## Project structure

See `ARCHITECTURE.md` — feature-first layout under `lib/`.

## MVP scope note

All premium limits are disabled for this MVP build (unlimited favorites, all loop counts, full TTS options).
