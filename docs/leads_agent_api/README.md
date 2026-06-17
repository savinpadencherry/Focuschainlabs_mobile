# Mr. Rex ↔ Leads Agent CRM — integration

The mobile app sends leads/updates to your **Focuschainlabs_Leads_Agent** CRM
and reads interaction history back. Because **Streamlit Community Cloud can't
host a REST API**, we run a tiny **FastAPI** service on **Render (free)** that
reuses the CRM's existing `utils.crm_store` (`load_crm` / `save_crm`) — so the
mobile app and the Streamlit UI share the same GitHub-backed data.

```
Mr. Rex (Flutter)  ──HTTPS──▶  FastAPI mobile_api (Render free)  ──▶  utils.crm_store (GitHub)
        │                                                                     ▲
        │  Trello REST (direct)                                               │
        ▼                                                            Streamlit CRM UI reads same store
   Trello board
```

## A. Stand up the CRM API (in the Leads Agent repo)

1. Copy **`mobile_api.py`** into the repo root (next to `whatsapp_webhook.py`).
2. Ensure `requirements.txt` includes: `fastapi`, `uvicorn[standard]`, `pydantic`
   (your webhook already uses FastAPI, so most are present).
3. Add the **`render.yaml`** service here (or merge into your existing one) and
   push. On render.com → **New +** → **Blueprint** → pick the repo.
4. Set the env vars in Render:
   - `MOBILE_API_KEY` — a long random string (this is the app's `CRM_API_TOKEN`).
   - `CRM_ORG` — your tenant id (default `fcl`).
   - `CRM_WEB_URL` — your Streamlit CRM URL (returned to the app for the webview).
   - plus whatever your `crm_store` needs to commit (e.g. `GH_TOKEN`).
5. Verify: open `https://<your-service>.onrender.com/healthz` → `{"ok": true}`.

> **Adjust one thing if needed:** `mobile_api.py` appends interactions under the
> contact's `comments` list. If your store uses a different key (e.g.
> `interactions`), tweak `_comments()` in that file to match.

## B. Trello (created directly from the app)

1. Get an API key + token: https://trello.com/power-ups/admin → API key, then
   generate a token.
2. Find your board's **list id**: open the board, append `.json` to the URL,
   and copy the `id` of the target list (e.g. "To do").
3. Note the board URL (e.g. `https://trello.com/b/abc123/sales`).

## C. Gemini

Create a key at https://aistudio.google.com/apikey (model `gemini-2.5-flash`).

## D. Run the mobile app wired to everything

```bash
flutter run \
  --dart-define=GEMINI_API_KEY=YOUR_GEMINI_KEY \
  --dart-define=CRM_API_BASE_URL=https://fcl-crm-mobile-api.onrender.com \
  --dart-define=CRM_API_TOKEN=YOUR_MOBILE_API_KEY \
  --dart-define=CRM_WEB_URL=https://your-crm.streamlit.app \
  --dart-define=TRELLO_KEY=YOUR_TRELLO_KEY \
  --dart-define=TRELLO_TOKEN=YOUR_TRELLO_TOKEN \
  --dart-define=TRELLO_LIST_ID=YOUR_LIST_ID \
  --dart-define=TRELLO_BOARD_URL=https://trello.com/b/xxxx/your-board
```

Any value you omit falls back to the offline mock, so partial wiring is fine
(e.g. add just `GEMINI_API_KEY` first to test real extraction).

### Tip: a launch script / VS Code config

Put the `--dart-define`s in `.vscode/launch.json` (`"args"` / `"toolArgs"`) or a
shell script so you don't paste them each run. **Don't commit real keys.**

## How the flow maps in the app

- **Lead / CRM update** (comment, interaction, stage change): written via
  `POST /api/leads`; the app then shows the contact's **interaction history**
  and an **Open CRM (desktop view)** button → in-app webview of `CRM_WEB_URL`.
- **Task** (a follow-up, or any action items): a **Trello card** is created via
  the Trello REST API; the app shows an **Open Trello board** button → in-app
  webview of `TRELLO_BOARD_URL`.

Security note: per your decision, the Gemini and Trello keys are injected into
the app build (`--dart-define`) for the MVP. That's fine for internal/dogfood
use; before any external release, move those calls behind the FastAPI so the
keys live only on the server.
