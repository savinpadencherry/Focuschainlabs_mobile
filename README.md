# FocusChain Labs Mobile

Flutter client for **Mr. Rex — Sales Companion**.

## Product direction

This mobile skeleton follows the functional specification:

- conversation-first client and product lookup
- voice-first CRM updates
- post-meeting capture
- pending capture queue
- lightweight role-aware home
- future Supabase, FCM and integration-adapter seams

## Run locally

```bash
flutter pub get
flutter run
```

## Run in GitHub Codespaces as Flutter Web

```bash
flutter config --enable-web
flutter pub get
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 3000
```

Open forwarded port `3000` from the Codespaces **Ports** panel.

## Build Android APK

```bash
flutter build apk --debug
```

APK output:

```text
build/app/outputs/flutter-apk/app-debug.apk
```

## Architecture

The current screens use placeholder data. Supabase, authentication, FCM, transcription and CRM adapters will be added behind repositories/services rather than called directly from widgets.
