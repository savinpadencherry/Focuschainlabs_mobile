# Firebase / Google setup — Mr. Rex

The Flutter integration layer is in place and **guarded**: Firebase services
(Auth, Analytics, Performance, FCM) and Google Calendar activate automatically
once Firebase initialises; until then the app runs on mocks. No Crashlytics.

What you do (mostly console + the config files you mentioned). The app package
id is **`labs.focuschain.focuschainlabs_mobile`** (project number `749976057554`).

---

## 1. Create apps & drop in config

In the [Firebase console](https://console.firebase.google.com) for your project:

- **Add Android app** → package name `labs.focuschain.focuschainlabs_mobile` →
  download **`google-services.json`** → place at `android/app/google-services.json`.
- **Add iOS app** → your iOS bundle id → download **`GoogleService-Info.plist`**
  → add it to `ios/Runner/` **via Xcode** (so it's in the Runner target).

> The iOS Google Sign-In URL scheme (`com.googleusercontent.apps.749976057554-…`)
> is already in `ios/Runner/Info.plist`. If your real reversed client id differs,
> update it there.

## 2. Wire the native build (easiest: FlutterFire CLI)

```bash
dart pub global activate flutterfire_cli
flutterfire configure        # registers apps, adds the Gradle plugin,
                             # and generates lib/firebase_options.dart
```

Then switch on options-based init (one line) in
`lib/core/services/firebase/firebase_bootstrap.dart`:

```dart
import '../../../firebase_options.dart';
// ...
await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
```

This also gives you **web** Firebase support.

**Manual alternative** (if not using the CLI) — apply the Google Services plugin:
- `android/build.gradle.kts` (top-level `plugins {}`):
  `id("com.google.gms.google-services") version "4.4.2" apply false`
- `android/app/build.gradle.kts` (`plugins {}`):
  `id("com.google.gms.google-services")`

## 3. Authentication (Google)

- **Build → Authentication → Sign-in method → enable Google** (set a support email).
- **Android needs SHA fingerprints** for Google Sign-In. Add both to the Android
  app in Firebase (Project settings → your Android app → Add fingerprint):
  ```bash
  # debug (for UAT sideload builds)
  keytool -list -v -keystore ~/.android/debug.keystore \
    -alias androiddebugkey -storepass android -keypass android
  # release (from your production keystore)
  keytool -list -v -keystore <your-release.keystore> -alias <alias>
  ```
  Add the SHA-1 **and** SHA-256. Re-download `google-services.json` after adding.

## 4. Google Calendar (real events)

After Google login the app requests `calendar.events.readonly` and pulls the
day's meetings. Enable it in the linked Google Cloud project:

- [Google Cloud Console](https://console.cloud.google.com) → same project →
  **APIs & Services → Library → enable "Google Calendar API"**.
- **OAuth consent screen**: app name, support email, scopes
  `email`, `profile`, `…/auth/calendar.events.readonly`. While in *Testing*,
  add your UAT testers under **Test users** (otherwise sign-in is blocked).

## 5. Analytics & Performance

No code needed — both auto-collect once Firebase initialises. Just open
**Analytics** and **Performance** in the console to confirm data flows. The app
already logs events: `sign_in_success`, `calendar_connected`,
`capture_confirmed`, `crm_write_success/failed`, `trello_write_success`,
`undo_used` (no transcripts/tokens/PII are ever sent).

## 6. Cloud Messaging (push) — for post-meeting reminders

- **Cloud Messaging** is enabled by default; the app registers a device token on
  mobile.
- **iOS**: upload an **APNs auth key (.p8)** under Project settings → Cloud
  Messaging, and in Xcode add the **Push Notifications** capability +
  **Background Modes → Remote notifications**.
- The **meeting-ended detection stays server-side** (your Leads Agent cron sends
  the push) — the app only receives it. That server job is a separate task.

## 7. Data Connect (replaces the GitHub CRM later)

You're generating the schema in the **SQL Connect** screen. Once it's deployed:

```bash
firebase init dataconnect:sdk
firebase dataconnect:sdk:generate     # generates Dart query/mutation classes
```

Add `firebase_data_connect:` and implement `DataConnectCrmService` /
`DataConnect*Repository` behind the existing repository interfaces, then retire
`GithubCrmService` and remove `GITHUB_TOKEN` from `.env`. (Next milestone — the
current `GithubCrmService` keeps you running until then.)

## 8. iOS / Android housekeeping

- iOS deployment target **13.0+** (Firebase/Google Sign-In). In `ios/Podfile`:
  `platform :ios, '13.0'`.
- Android `minSdk` 21+ (already via Flutter default).
- The release build currently uses the **debug signing key** — create a real
  keystore before Play Store distribution and add its SHA to Firebase.

---

### Order that gets you to a real demo fastest
1. `flutterfire configure` (+ drop in the two config files)
2. Enable Google sign-in + add SHA-1/256
3. Enable Calendar API + add testers to the consent screen
4. Build → **Google login → real calendar events** light up immediately;
   Analytics/Performance start reporting; CRM/Trello still run via `.env`.
