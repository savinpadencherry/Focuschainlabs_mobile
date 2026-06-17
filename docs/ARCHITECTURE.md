# Architecture

A thin, modular Flutter client structured for the multi-tenant Supabase backend
described in the spec. Strict layering keeps every file small (≤500 lines) and
swappable.

```
lib/
├── main.dart                      # bootstrap: DI + runApp
├── app/                           # root widget, theming, auth gate (routing)
│   ├── app.dart
│   └── auth_gate.dart
├── core/                          # cross-cutting, framework-agnostic
│   ├── constants/                 # app constants + copy
│   ├── theme/                     # colours, spacing, typography, ThemeData
│   ├── utils/                     # responsive breakpoints, formatters
│   ├── models/                    # domain entities + the extraction schema
│   ├── data/                      # seed data (demo mode only)
│   ├── services/                  # AiService, VoiceService, LocalStore, Nav  (← swap to go live)
│   ├── repository/                # data access; the only callers of services/data (← swap to go live)
│   └── get.dart                   # get_it service locator (single wiring point)
├── features/                      # one folder per feature, self-contained
│   ├── <feature>/bloc/            # BLoC: events + states + bloc
│   ├── <feature>/view/            # page (DI) + view (UI) + widgets/
│   └── ...                        # auth, home, lookup, capture, meetings,
│                                  # pending, client, profile, shell
└── shared/widgets/                # reusable UI (cards, logo, mic, chips, states)
```

## Principles

- **Unidirectional data flow.** UI → event → BLoC → repository → service/DB →
  state → UI. Widgets never call services directly.
- **Dependency inversion.** Features depend on *interfaces* (`AiService`,
  `VoiceService`). Implementations are registered once in `core/get.dart`.
  Demo ↔ live is a registration swap.
- **Page vs View.** `*Page` wires the BLoC and provides it; `*View` is a pure
  function of state. This keeps views testable and short.
- **Responsive by construction.** `core/utils/responsive.dart` exposes
  breakpoints, `ResponsiveLayout` and `ContentBounds`. The shell renders a
  bottom bar on phones and a navigation rail on tablet/web; content is centred
  and width-capped on large screens.
- **Reversibility & validation.** Extractions are validated before any write
  (`Extraction.isValid`); every write produces an `ActivityEntry` with per-
  destination success so partial failures surface and undo is one tap.

## The extraction contract

`core/models/extraction.dart` mirrors the spec's JSON exactly:

```json
{ "client": "...", "update_type": "comment|interaction|stage_change|follow_up",
  "summary": "...", "sentiment": "positive|neutral|negative|at_risk",
  "deal_stage_change": null, "next_steps": [],
  "action_items": [{ "title": "...", "due": null, "owner": null }],
  "follow_up_date": null, "notes": null }
```

`MockAiService` produces this from a transcript today; `ClaudeAiService` will
return it from the API. Both pass through the same validation and UI.

## Where to plug in the backend

Touch only these to go live (see `docs/SETUP.md` §4):

- `core/services/ai/` — `ClaudeAiService implements AiService`
- `core/services/voice/` — `SpeechToTextService implements VoiceService`
- `core/repository/` — replace seed reads with Supabase queries (scoped by `org_id`)
- `core/get.dart` — register the live implementations
