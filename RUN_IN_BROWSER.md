# Run Scripture Memorizer in your browser

## What this machine needs (detected)

| Check | Status |
|--------|--------|
| Flutter SDK | **Not installed** (not on PATH) |
| `web/` folder | **Missing** — run `flutter create` after installing Flutter |
| Project code (`lib/`) | Ready |
| Node.js | v22 (unrelated to Flutter) |

This is a **Flutter** app, not a Node/React app. Use **Chrome** or **Edge** via `flutter run -d chrome`.

---

## Step 1 — Install Flutter (one time)

### Option A — Official installer (recommended)

1. Download: https://docs.flutter.dev/get-started/install/windows/mobile
2. Run the installer (or unzip Flutter to e.g. `C:\flutter`)
3. Add to PATH: `C:\flutter\bin` (or your install path)
4. **Close and reopen** PowerShell, then verify:

```powershell
flutter --version
flutter doctor
```

Fix anything `flutter doctor` flags (Android Studio optional for **browser-only**; enable web):

```powershell
flutter config --enable-web
flutter doctor --android-licenses
```

*(Skip Android licenses if you only use the browser.)*

### Option B — Git clone

```powershell
cd $env:USERPROFILE
git clone https://github.com/flutter/flutter.git -b stable
[Environment]::SetEnvironmentVariable("Path", $env:Path + ";$env:USERPROFILE\flutter\bin", "User")
```

Restart PowerShell, then `flutter doctor`.

---

## Step 2 — Generate platform files (one time per project)

```powershell
cd "c:\Users\User\Desktop\Scripture Memorizer App"
flutter create . --org com.scripturememorizer --project-name scripture_memorizer
flutter pub get
```

---

## Step 3 — Run in the browser

### Quick UI preview (no Firebase setup)

Browse, Daily Verse, TTS, favorites, and progress work **locally as guest**. Auth and cloud sync are disabled.

```powershell
cd "c:\Users\User\Desktop\Scripture Memorizer App"
flutter run -d chrome --dart-define=SKIP_FIREBASE=true
```

**Edge instead of Chrome:**

```powershell
flutter run -d edge --dart-define=SKIP_FIREBASE=true
```

**URL-only mode** (prints a link you can open manually):

```powershell
flutter run -d web-server --dart-define=SKIP_FIREBASE=true
```

When it starts, the terminal shows something like:

`http://127.0.0.1:xxxxx`

Open that URL in any browser.

---

### Full app (Firebase Auth + Google Sign-In)

1. Create a Firebase project: https://console.firebase.google.com
2. Configure FlutterFire:

```powershell
dart pub global activate flutterfire_cli
flutterfire configure
```

3. Enable **Email/Password** and **Google** in Firebase Authentication.
4. Run:

```powershell
flutter run -d chrome
```

---

## Useful commands

| Command | Purpose |
|---------|---------|
| `flutter devices` | List Chrome, Edge, web-server, etc. |
| `flutter run -d chrome` | Build and open Chrome |
| `r` in terminal | Hot reload |
| `R` in terminal | Hot restart |
| `q` in terminal | Quit |

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| `flutter` not recognized | Add Flutter `bin` to PATH; restart terminal |
| No supported devices / web | `flutter config --enable-web` then `flutter create .` |
| Firebase / API key errors | Use `--dart-define=SKIP_FIREBASE=true` for preview, or run `flutterfire configure` |
| CORS / Bible API in browser | bible-api.com allows browser requests; if blocked, test on Android/desktop |
| TTS silent on web | Web TTS is limited; use Chrome desktop for best results |
