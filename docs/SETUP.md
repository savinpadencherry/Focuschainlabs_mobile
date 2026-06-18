# Mr. Rex — Setup, Hosting & Go-Live Guide

This is the practical companion to the functional spec. It covers **what the app
does today**, **how to run it**, **what you (Savin) need to do from your side**,
and **how to take it from demo mode to a real backend** — using free/cheap
infrastructure available on the **GitHub Student Developer Pack**.

---

## 1. What's built (MVP, this PR)

A fully navigable, production-shaped Flutter app that runs **with no backend and
no API keys** (`demoMode = true`). It exercises the whole core loop end-to-end so
you can feel how the product should work:

| Spec | Built in this MVP |
|------|-------------------|
| F1 Instant lookup | Conversational "Ask Rex" — client 360 + grounded product answers with **citations** |
| F2 Conversational CRM updates | Speak/type a note → entity resolution → editable draft → confirm |
| F4 Voice-first capture & extraction | Mic UI → transcript → **structured extraction** (the spec's exact JSON schema) → glance/edit |
| F3 Post-meeting capture | Meetings list flags just-ended meetings; "Pending captures" queue (never lost) |
| F5 CRM write + undo | One-tap **Confirm & write** with a short-window **Undo**; idempotent per capture |
| F6/F7 Task + calendar fan-out | Action items (deselectable) + follow-up date routed; **partial-failure** surfaced |
| F9/F10 Auth, roles, home, connections | Splash → sign-in → role-aware home; connections/integration status screen |
| Non-functional | Responsive **phone / tablet / web**, isolation messaging, reversibility, ~realistic latency |

> Everything the AI/voice/CRM layers do is behind interfaces, served by mock
> implementations. Going live = swapping those implementations. Nothing in the
> UI/feature code changes.

---

## 2. Run it locally

```bash
flutter pub get
flutter run                 # mobile (emulator/device)
# or web:
flutter config --enable-web
flutter run -d chrome
```

Build artifacts:

```bash
flutter build apk --debug                 # Android APK
flutter build web --release               # Web (deploy /build/web)
```

> First run downloads the Google Fonts used by the theme. If you're fully
> offline it silently falls back to the system font — the app still works.

---

## 3. ✅ What YOU need to do (from your side)

These are the accounts/keys to create. The ones marked **Free** need no card.
Most are on the **GitHub Student Developer Pack** (education.github.com/pack).

### 3.1 Backend, database, auth, vectors — **Supabase** (Free)
- [ ] Create a project at supabase.com (free tier: Postgres + Auth + pgvector + Edge Functions, no card).
- [ ] Enable the `vector` extension (Database → Extensions → `vector`) for the `kb_chunk` table (F1 RAG).
- [ ] Turn on **Row Level Security** and add an `org_id = auth.jwt() ->> 'org_id'` policy on every business table (spec D2 — the hard isolation requirement).
- [ ] Note your **Project URL** and **anon key** (client) and **service-role key** (server only — never in the app).

### 3.2 The AI layer — **Anthropic Claude API** (paid, cheap at your volume)
- [ ] Create a key at console.anthropic.com. Use a current model id (e.g. `claude-sonnet-4-6` for extraction, or the latest available).
- [ ] **Keep the key server-side** in a Supabase Edge Function — never ship it in the Flutter client.
- [ ] Reuse PIKU's JSON-only prompting discipline; the response must match `Extraction` (see `lib/core/models/extraction.dart`).

### 3.3 Push notifications — **Firebase Cloud Messaging** (Free)
- [ ] Create a Firebase project, add Android/iOS/Web apps, drop in the config files.
- [ ] FCM powers the F3 "How did the meeting with {client} go?" prompt.

### 3.4 Server-side trigger — **Supabase Edge Functions + cron** (Free)
- [ ] One scheduled function (every 10–15 min, spec D6) reads connected calendars, finds just-ended eligible meetings, and sends an FCM push. **Do not** use mobile background tasks (spec §9).

### 3.5 Integrations (per spec D1/D4 — start narrow)
- [ ] **Built-in CRM** (Supabase tables) as system-of-record — covers FCL + the spreadsheet long tail.
- [ ] **Google Calendar** (read) for meeting detection.
- [ ] **Trello** (write) for action items + "task-in-CRM" fallback.
- [ ] Gmail read + a Zoho adapter are fast-follows, not v1.

### 3.6 Hosting the web build — pick one (all Free)
- [ ] **GitHub Pages** (you already have GitHub Pro via the Student Pack) — deploy `build/web` with a GitHub Action. Simplest.
- [ ] or **Cloudflare Pages** / **Netlify** free tier — nicer custom-domain + SSL story.

### 3.7 Nice-to-haves on the Student Pack (Free / credit)
- [ ] **Namecheap** — free `.me` domain for a year (+ Cloudflare for free DNS/SSL).
- [ ] **Microsoft Azure for Students** — $100 credit, no card; an alternative home for the cron/API as **Azure Functions** if you outgrow Supabase Edge Functions.
- [ ] **DigitalOcean** ($200) / **MongoDB Atlas** ($50) — backup options; not needed if you stay on Supabase.
- [ ] **Sentry** — free error monitoring for the Flutter app.
- [ ] **GitHub Actions** — CI (analyze + test + build) on every push; you get generous minutes with Student Pro.

> On Copilot: even if the in-IDE Copilot perk changed, your day-to-day AI coding
> is unaffected — you're using **Claude Code** here, and the Student Pack's value
> for shipping is the **infra** above (free DB, hosting, functions, CI), not the
> autocomplete.

### Recommended free stack (matches the spec, lowest cost)
```
Flutter (this repo)
   → Supabase  : Postgres + RLS + pgvector + Auth + Edge Functions   [Free]
   → Edge Fn   : cron meeting-detection + Claude calls + adapters     [Free compute]
   → Claude API: extraction + grounded answers                        [usage-based, low]
   → FCM       : post-meeting push                                    [Free]
   → On-device STT (speech_to_text)                                   [Free, spec D5]
   → GitHub Pages / Cloudflare Pages: Flutter web                     [Free]
   → GitHub Actions: CI/CD                                            [Free]
```

---

## 3.8 Leads Agent CRM + Gemini + Trello (implemented)

These integrations are **already wired** behind interfaces and activate
automatically when you fill in **`.env`** (copy from `.env.example`); otherwise
the offline mocks run.

| Integration | App service (this repo) | What you provide in `.env` |
|-------------|-------------------------|----------------------------|
| **Gemini 2.5 Flash** (extraction, routing, lookup) | `GeminiAiService` | `GEMINI_API_KEY` |
| **CRM = the Leads Agent repo** (`data/crm/contacts.json`, read + write) | `GithubCrmService` | `GITHUB_TOKEN` (PAT, Contents r/w), `GITHUB_CRM_REPO/PATH/BRANCH`, `CRM_WEB_URL` |
| **Trello** (action items → board) | `HttpTrelloService` | `TRELLO_KEY/TOKEN/LIST_ID/BOARD_URL` |

**How it flows:** the rep types or speaks a note → **Gemini** structures it and
**decides the destination**. A **CRM update** is written straight into the
repo's `contacts.json` (same store the Streamlit CRM reads), then the app shows
the interaction history and opens the CRM in a **desktop-view webview**. A
**task** becomes a **Trello card** and opens the **board webview**.

> The GitHub PAT needs **Contents: read and write** on the Leads Agent repo.
> `.env` is bundled into the build, so treat keys as client-visible for the MVP
> (fine for dogfooding; move them server-side before any public release).
>
> Prefer a server instead of a PAT in the app? The paste-ready FastAPI
> (`mobile_api.py` + `render.yaml`) in
> **[docs/leads_agent_api/](leads_agent_api/)** is an optional alternative.

---

## 4. Going from demo mode to live

The whole point of the architecture: **flip one flag and replace mock classes.**

1. Set `AppConstants.demoMode = false` (`lib/core/constants/app_constants.dart`).
2. Add packages (`supabase_flutter`, `http`, `speech_to_text`, `firebase_messaging`).
3. Implement the interfaces and register them in `lib/core/get.dart`:

| Interface | Demo impl (today) | Live impl (you add) |
|-----------|-------------------|---------------------|
| `AiService` | `MockAiService` | `ClaudeAiService` → calls a Supabase Edge Function that calls Claude |
| `VoiceService` | `MockVoiceService` | `SpeechToTextService` (on-device) |
| `AuthRepository` | seeded session | Supabase Auth (Google OAuth + email) |
| `*Repository` | seed data | Supabase queries scoped by `org_id` |
| `LocalStore` | shared_preferences | Supabase tables (keep prefs for cache) |

Only `lib/core/services/**` and `lib/core/repository/**` change. **No feature or
UI file is touched** — that's the modular payoff.

---

## 5. Suggested order (mirrors spec §13)

1. **P0 Spine** — Supabase Auth + Google Calendar read + cron + FCM (real "meeting ended" push).
2. **P1 Engine** — wire `ClaudeAiService` + on-device STT; lookup + capture write to the built-in CRM.
3. **P2 Fan-out** — Trello + calendar writes, real undo, partial-failure retries.
4. **P3 Knowledge** — pgvector index + grounded RAG lookup.
5. **P4 Multi-tenant** — RLS hardening, org onboarding, field mapping, a 2nd CRM adapter.

See `docs/ARCHITECTURE.md` for the code map.
