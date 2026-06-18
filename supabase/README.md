# Supabase CRM — setup & migration

The mobile app and the Leads Agent website now share one database: **Supabase**
(Postgres). Auth stays on **Firebase/Google**; data lives in Supabase.

## 1. Create the tables
In the Supabase dashboard → **SQL Editor**, paste and run
[`schema.sql`](schema.sql). It creates `contacts` + `interactions` with
permissive **UAT** RLS policies (the publishable key can read/write).

> Harden before production: verify a Firebase JWT (or move auth to Supabase) and
> scope every row by organisation. The UAT policies allow any anon access.

## 2. Migrate the existing CRM data
Move `data/crm/contacts.json` from the Leads Agent repo into Supabase:

```bash
export SUPABASE_URL=https://jptltprlzbcidkpbjipo.supabase.co
export SUPABASE_KEY=<service_role key>     # publishable key also works (UAT)
python3 supabase/migrate_contacts.py       # idempotent; re-runnable
```

It reads the repo's `contacts.json` (or a local path via `CONTACTS_JSON`) and
upserts contacts + their comments → `interactions`.

## 3. Point the app at Supabase
In `.env`:

```
SUPABASE_URL=https://jptltprlzbcidkpbjipo.supabase.co
SUPABASE_ANON_KEY=sb_publishable_...      # your publishable key
```

The app auto-selects `SupabaseCrmService` when these are set (else falls back to
the GitHub repo, else mock). The **Leads** tab, capture writes and interaction
history all run against Supabase.
