# Mr. Rex — Sales Companion

Flutter client for **Mr. Rex** by **FocusChain Labs**: a conversation-first
sales companion. Client context in seconds, CRM updates without forms, and
follow-ups that never slip.

> **MVP runs out of the box — no backend, no API keys.** The app ships in
> *demo mode* with seeded data so the full loop (lookup → capture → extract →
> review → write → undo) is usable immediately. Wiring the real Supabase +
> Claude backend is a registration swap — see **[docs/SETUP.md](docs/SETUP.md)**.

## What's inside

- 🔎 **Ask Rex** — conversational client 360 + grounded product answers with citations (F1)
- 🎙️ **Talk to Rex** — voice/typed note → structured extraction → glance, edit, confirm (F2/F4)
- 📅 **Meetings & pending captures** — post-meeting prompts that are never lost (F3)
- ✍️ **One-tap write + undo** — CRM / task / calendar fan-out with partial-failure surfacing (F5–F7)
- 👤 **Auth, roles, connections** — role-aware home and integration status (F9/F10)
- 📱 **Responsive** — phone, tablet and web from one codebase

## Run

```bash
flutter pub get
flutter run                         # mobile
flutter run -d chrome               # web
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 3000  # Codespaces
```

```bash
flutter analyze && flutter test     # quality gate
flutter build apk --debug           # Android → build/app/outputs/flutter-apk/app-debug.apk
flutter build web --release         # Web → build/web
```

## Internal UAT (demo-direct mode)

By default `DEMO_DIRECT_INTEGRATIONS=true` bundles a `.env` asset so Gemini,
GitHub CRM, and Trello are called **directly from the client**. This is fine
for private tester builds only — credentials can be extracted from the APK or
web bundle. For UAT:

1. Copy `.env.example` → `.env` and fill keys (never commit real tokens).
2. Use a **narrow, expiring** GitHub fine-grained PAT scoped to
   `Focuschainlabs_Leads_Agent` with Contents read/write only.
3. Run on device for real microphone (`DeviceVoiceService` on Android/iOS;
   `MockVoiceService` on web).
4. CI (`.github/workflows/ci.yml`) generates `.env` from repository secrets and
   uploads web + debug APK artifacts on each push/PR.

Production must move writes behind a backend proxy / Edge Function and set
`DEMO_DIRECT_INTEGRATIONS=false`.

## Project layout

A clean, layered architecture (BLoC + repositories + service interfaces, DI via
`get_it`). Every file is kept ≤500 lines and feature-scoped.

```
lib/app        root + theming + auth gate
lib/core       constants · theme · models · services · repositories · DI
lib/features   auth · home · lookup · capture · meetings · pending · client · profile · shell
lib/shared     reusable widgets
```

See **[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)** for the full map and
**[docs/SETUP.md](docs/SETUP.md)** for hosting (free via the GitHub Student
Pack) and the demo-mode → live checklist.
