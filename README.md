# Secona — the CRM on your phone

Flutter client for **Secona** by **FocusChain Labs**. It is not a companion app
with its own data: it is a second front end onto the *same* Cloud SQL database
the Streamlit web app renders from. A stage moved on a phone is on a colleague's
screen the moment they refresh, because there is nothing to sync.

```
Flutter ──HTTPS + Google ID token──▶ mobile-api (Cloud Run) ─┐
                                                             ├─▶ Cloud SQL
Streamlit CRM (Cloud Run) ───────────────────────────────────┘
```

The API lives in the **Focuschainlabs_Leads_Agent** repo under `mobile_api/`.
It imports the web app's own modules — `utils.ona_planner` and
`rex.plan_runner` for Ona, `rex.pipeline` for the board, `utils.listings_store`
for inventory — so "3 BHK in Whitefield under 4 Cr" resolves to the same intent
and the same answer on both surfaces. A second implementation would be a second
opinion, and the two would drift within a week.

## The three surfaces

- **Ona** — the assistant. Opens on the morning brief, answers in components
  rather than paragraphs, and never writes without being asked twice: it
  proposes, you confirm, then it shows the record as stored.
- **Pipeline** — the board, scored and ranked by the same `rex.intelligence`
  scoring the web app uses. Stage moves, notes and edits are audited.
- **Listings** — inventory search with removable filter chips, and a share
  composer that records what went to whom.

## Access

Sign-in is Google, and membership is the CRM's invite list
(`org_config.resolve_membership`). An address that is not on it gets a clear
"no access" message rather than an empty app. Your role decides what you see —
a rep's own book, an admin's whole org — enforced on the server, not here.

## Run

```bash
flutter pub get
flutter run --dart-define=API_BASE_URL=https://<mobile-api-url>
```

```bash
flutter analyze && flutter test     # the quality gate CI runs
flutter build apk --release
```

Without `API_BASE_URL` the app builds and starts, then says it cannot reach the
CRM. There is deliberately no demo mode: a rep cannot tell seeded data from
their real pipeline until they have acted on it.

## Builds

Every push to `main` runs analyze + test and publishes a signed APK to the
rolling [`android-latest`](../../releases/tag/android-latest) pre-release.
`Actions → Release APK` cuts a specific tagged build when you need one to keep.

The APK is signed with the committed UAT keystore on purpose: Google Sign-In
binds to a certificate SHA-1, and a per-build key would break sign-in on every
install.

### Repo secrets

| Secret | Why |
|---|---|
| `API_BASE_URL` | the mobile API's Cloud Run URL |
| `CRM_WEB_URL` | the Streamlit app, for the in-app webview |

## Layout

```
lib/core/models        Lead · Listing · Ona turns, and the JSON coercions
lib/core/services/api  the single HTTP door (SeconaApi)
lib/core/repository    CrmRepository — one repository, because the surfaces
                       are not independent
lib/features/ona       chat, chips, deal cards, receipts
lib/features/pipeline  board, filters, lead sheet
lib/features/listings  search, cards, share composer
lib/shared/widgets     chips, cards, empty and error states
```
