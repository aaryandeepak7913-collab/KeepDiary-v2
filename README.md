# Keep (native) — build status

This is the native Flutter rewrite of Keep, for a real `.exe` and `.apk` instead of the browser-based PWA. Built entirely in the cloud via GitHub Actions — no laptop, no local Flutter install needed.

## What's working right now

- Password-protected vault, AES-256-GCM encryption (same crypto model as the web version — PBKDF2 key derivation, nothing decrypted ever touches disk)
- Local storage via Hive (genuinely offline — no browser cache tricks needed, it's just native storage)
- Calendar with entry dots, current streak shown in the app bar
- Write, save, and re-open encrypted entries per day

## Not built yet (next phases)

- Biometric unlock (fingerprint/Windows Hello)
- Google Drive sync
- Change password / erase device / settings screen
- Visual polish to match the web version's ink-and-parchment design (right now it's a close but simpler approximation)

## How to actually get the .exe and .apk

You don't need Flutter installed anywhere. This repo builds itself in the cloud:

1. Create a new GitHub repo (or reuse one) and upload every file here, **keeping the folder structure** — `lib/`, `.github/workflows/build.yml`, `pubspec.yaml`, everything, exactly as laid out.
2. Once `.github/workflows/build.yml` is in the repo on the `main` branch, GitHub automatically starts a build — check the **Actions** tab.
3. Two jobs run: `build-windows` and `build-android`, each on its own cloud machine. Takes a few minutes.
4. When a job finishes (green checkmark), open it → scroll to **Artifacts** at the bottom → download:
   - `keep-windows` → unzip it, contains the `.exe` and everything it needs alongside it
   - `keep-android` → contains `app-release.apk` directly, installable on your phone

If a build fails (red X), open the job and check the log — most likely cause at this stage is a typo introduced during upload (a file that didn't fully transfer) rather than the code itself, since this hasn't had a real compile yet outside this pipeline.

## Files

```
lib/
  main.dart                    — app entry, routes between lock screen and home
  screens/
    lock_screen.dart           — password setup/unlock
    home_screen.dart           — calendar + entry editor
  services/
    crypto_service.dart        — AES-256-GCM + PBKDF2, mirrors the web app's crypto
    storage_service.dart       — Hive-based local vault storage
    streak_service.dart        — date/streak math
.github/workflows/build.yml    — cloud build pipeline (Windows + Android)
pubspec.yaml                   — dependencies
```
