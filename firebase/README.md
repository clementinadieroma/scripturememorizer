# Firebase — Scripture Memorizer

Project: **scripture-memorizer-app** (Spark / free plan)

## Deployed services

| Service | Status |
|---------|--------|
| Firestore rules + indexes | Deployed |
| Email/Password Auth | Enabled via `firebase deploy --only auth` |
| `config/daily_verse` seed | In Firestore |
| Flutter apps (web, android, ios, windows) | Registered + `lib/firebase_options.dart` |
| `android/app/google-services.json` | Generated |
| `ios/Runner/GoogleService-Info.plist` | Generated |
| Cloud Functions | Requires Blaze plan (optional) |
| Storage rules | Requires Storage init (see below) |

## Quick deploy (free tier)

```bash
cd firebase
firebase use scripture-memorizer-app
firebase deploy --only firestore:rules,firestore:indexes,auth
node scripts/seed-config.js   # optional if config missing
```

## Auth (Email/Password)

Configured in `firebase.json`:

```json
"auth": {
  "providers": {
    "emailPassword": true
  }
}
```

Deploy with:

```bash
firebase deploy --only auth
```

## FlutterFire (mobile + web)

From project root:

```bash
dart pub global activate flutterfire_cli
flutterfire configure --project=scripture-memorizer-app --platforms=android,ios,web,windows --yes
```

## Storage (optional — one manual step on free plan)

Storage bucket creation requires clicking **Get Started** once in the console (Spark plan):

[Open Firebase Storage setup](https://console.firebase.google.com/project/scripture-memorizer-app/storage)

Then deploy rules:

```bash
firebase deploy --only storage
```

Storage is **not required** for MVP (no file uploads yet).

## Cloud Functions (optional — Blaze plan)

Functions need Blaze (pay-as-you-go; often $0 for small usage):

```bash
cd functions && npm run build && cd ..
firebase deploy --only functions
```

Full schema: [../docs/BACKEND_ARCHITECTURE.md](../docs/BACKEND_ARCHITECTURE.md)

## App branding & OAuth icon

Launcher icons and splash screens are generated from `assets/images/app_logo.png`:

```bash
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

**Google Sign-In OAuth consent screen** (one-time manual upload):

1. Open [Google Cloud Console → OAuth consent screen](https://console.cloud.google.com/apis/credentials/consent?project=scripture-memorizer-app)
2. Upload `firebase/branding/oauth_app_icon.png` as the **App logo** (120×120 px minimum; square PNG)
3. Set app name to **Scripture Memorizer** and support email as needed

Firebase Auth uses the same Google Cloud OAuth client; updating the consent screen logo updates what users see on the Google sign-in popup.
