#!/usr/bin/env python3
"""One-shot migration: Leads Agent data/crm/contacts.json -> Supabase.

Run AFTER applying supabase/schema.sql.

    # easiest: put the service_role key in a file (no shell-quote pitfalls)
    echo 'PASTE_SERVICE_ROLE_KEY' > supabase/service_key.txt
    python3 supabase/migrate_contacts.py

    # or via env vars (use straight quotes!):
    export SUPABASE_KEY="PASTE_SERVICE_ROLE_KEY"
    python3 supabase/migrate_contacts.py

Idempotent: upserts on the contact/interaction id (re-runnable).
"""
import json
import os
import urllib.request

URL = os.environ.get(
    "SUPABASE_URL", "https://jptltprlzbcidkpbjipo.supabase.co"
).rstrip("/")


def _key():
    key = os.environ.get("SUPABASE_KEY", "").strip()
    if key:
        return key
    here = os.path.dirname(os.path.abspath(__file__))
    path = os.path.join(here, "service_key.txt")
    if os.path.exists(path):
        return open(path).read().strip()
    raise SystemExit(
        "No key. Set SUPABASE_KEY or create supabase/service_key.txt with the "
        "service_role key."
    )


KEY = _key()
SOURCE = os.environ.get(
    "CONTACTS_JSON",
    "https://raw.githubusercontent.com/savinpadencherry/"
    "Focuschainlabs_Leads_Agent/main/data/crm/contacts.json",
)


def load():
    if SOURCE.startswith("http"):
        with urllib.request.urlopen(SOURCE) as r:
            return json.load(r)
    with open(SOURCE) as f:
        return json.load(f)


def upsert(table, rows):
    if not rows:
        return
    req = urllib.request.Request(
        f"{URL}/rest/v1/{table}",
        data=json.dumps(rows).encode(),
        method="POST",
        headers={
            "apikey": KEY,
            "Authorization": f"Bearer {KEY}",
            "Content-Type": "application/json",
            "Prefer": "resolution=merge-duplicates,return=minimal",
        },
    )
    with urllib.request.urlopen(req) as r:
        print(f"{table}: HTTP {r.status} ({len(rows)} rows)")


db = load()
contacts, interactions = [], []
for c in db.get("contacts", []):
    contacts.append({
        "id": c.get("id"),
        "name": c.get("name") or "Unknown",
        "company": c.get("company"),
        "industry": c.get("industry"),
        "phone": c.get("phone"),
        "email": c.get("email"),
        "status": c.get("status") or "new",
        "deal_status": c.get("deal_status") or "open",
        "value": str(c.get("value") or ""),
        "owner": c.get("owner"),
        "source": c.get("source"),
        "next_follow_up": c.get("next_follow_up") or None,
        "notes": c.get("notes"),
        "tags": c.get("tags") or [],
    })
    for cm in c.get("comments", []):
        interactions.append({
            "id": cm.get("id"),
            "contact_id": c.get("id"),
            "author": cm.get("author"),
            "body": cm.get("body"),
            "kind": cm.get("type") or "comment",
            "subject": cm.get("subject"),
            "meeting_link": cm.get("meeting_link"),
            "source": cm.get("source"),
        })

upsert("contacts", contacts)
upsert("interactions", interactions)
print(f"done: {len(contacts)} contacts, {len(interactions)} interactions")
