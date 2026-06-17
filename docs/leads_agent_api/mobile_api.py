# mobile_api.py — REST API for the Mr. Rex mobile app
#
# Drop this file into the ROOT of the Focuschainlabs_Leads_Agent repo (next to
# whatsapp_webhook.py) and deploy it on Render's free tier (see README.md in
# this folder). It reuses the CRM's existing GitHub-backed store
# (utils.crm_store.load_crm / save_crm) so the mobile app and the Streamlit UI
# read/write the SAME data.
#
# Endpoints (all under /api, secured by the X-API-Key header):
#   POST /api/leads                       -> upsert a contact + append a comment
#   GET  /api/contacts/{ref}/interactions -> a contact's interaction history
#   GET  /api/contacts?q=...              -> search contacts
#   GET  /healthz                         -> health check
#
# NOTE: this mirrors the find-or-create + append-comment flow already used in
# whatsapp_webhook.py. If your crm_store keeps interactions under a different
# key than "comments" (e.g. "interactions"), adjust _comments() below.

import os
import uuid
from datetime import datetime, timezone

from fastapi import Depends, FastAPI, Header, HTTPException, Query
from pydantic import BaseModel

# Reuse the CRM's real persistence layer (GitHub-backed).
from utils.crm_store import load_crm, save_crm  # type: ignore

API_KEY = os.environ.get("MOBILE_API_KEY", "")
DEFAULT_ORG = os.environ.get("CRM_ORG", "fcl")

app = FastAPI(title="FocusChain CRM — Mr. Rex mobile API")


# --- auth --------------------------------------------------------------------
def require_key(x_api_key: str = Header(default="")) -> None:
    if not API_KEY or x_api_key != API_KEY:
        raise HTTPException(status_code=401, detail="Invalid API key")


# --- models ------------------------------------------------------------------
class Comment(BaseModel):
    author: str = "Mr. Rex (mobile)"
    body: str = ""


class LeadIn(BaseModel):
    name: str
    company: str | None = None
    phone: str | None = None
    email: str | None = None
    status: str | None = None
    source: str = "mobile"
    value: str | None = None
    next_follow_up: str | None = None
    sentiment: str | None = None
    notes: str | None = None
    tags: list[str] = ["mobile"]
    comment: Comment | None = None


# --- helpers -----------------------------------------------------------------
def _now() -> str:
    return datetime.now(timezone.utc).isoformat()


def _contacts(db: dict) -> list:
    return db.setdefault("contacts", [])


def _comments(contact: dict) -> list:
    # Interactions live under "comments" in the CRM store; adjust if yours
    # uses a different key.
    return contact.setdefault("comments", [])


def _find(db: dict, ref: str) -> dict | None:
    ref_l = ref.strip().lower()
    for c in _contacts(db):
        if str(c.get("id", "")).lower() == ref_l:
            return c
        if str(c.get("name", "")).lower() == ref_l:
            return c
        if ref_l and ref_l == str(c.get("phone", "")).lower():
            return c
    return None


def _find_or_create(db: dict, lead: LeadIn) -> tuple[str, dict]:
    existing = _find(db, lead.name) or (
        _find(db, lead.phone) if lead.phone else None
    )
    if existing:
        return "merged", existing
    contact = {
        "id": uuid.uuid4().hex[:12],
        "name": lead.name,
        "company": lead.company or lead.name,
        "phone": lead.phone or "",
        "email": lead.email or "",
        "status": lead.status or "new",
        "deal_status": "open",
        "source": lead.source,
        "value": lead.value or "",
        "owner": "",
        "tags": lead.tags,
        "comments": [],
        "created_at": _now(),
    }
    _contacts(db).append(contact)
    return "created", contact


# --- routes ------------------------------------------------------------------
@app.get("/healthz")
def healthz() -> dict:
    return {"ok": True, "api_key_configured": bool(API_KEY)}


@app.post("/api/leads", dependencies=[Depends(require_key)])
def upsert_lead(lead: LeadIn, org: str = Query(default=DEFAULT_ORG)) -> dict:
    db, meta = load_crm(org=org)
    action, contact = _find_or_create(db, lead)

    # Update mutable fields when provided.
    if lead.status:
        contact["status"] = lead.status
    if lead.value:
        contact["value"] = lead.value
    if lead.next_follow_up:
        contact["next_follow_up"] = lead.next_follow_up
    if lead.sentiment:
        contact["sentiment"] = lead.sentiment
    for tag in lead.tags:
        if tag not in contact.setdefault("tags", []):
            contact["tags"].append(tag)
    contact["updated_at"] = _now()

    # Append the spoken update as a comment/interaction.
    if lead.comment and lead.comment.body:
        _comments(contact).append(
            {
                "id": uuid.uuid4().hex[:12],
                "created_at": _now(),
                "author": lead.comment.author,
                "body": lead.comment.body,
                "meeting_link": "",
            }
        )

    save_crm(db, sha=meta.get("sha"), message=f"mobile: {action} {contact['name']}", org=org)
    return {
        "id": contact["id"],
        "name": contact["name"],
        "action": action,
        "web_url": os.environ.get("CRM_WEB_URL", ""),
    }


@app.get("/api/contacts/{ref}/interactions", dependencies=[Depends(require_key)])
def interactions(ref: str, org: str = Query(default=DEFAULT_ORG)) -> list:
    db, _ = load_crm(org=org)
    contact = _find(db, ref)
    if not contact:
        return []
    items = list(_comments(contact))
    # Include email events if present.
    items += list(contact.get("emails", []))
    items.sort(key=lambda x: x.get("created_at") or x.get("sent_at") or "", reverse=True)
    return items


@app.get("/api/contacts", dependencies=[Depends(require_key)])
def search_contacts(q: str = Query(default=""), org: str = Query(default=DEFAULT_ORG)) -> list:
    db, _ = load_crm(org=org)
    ql = q.strip().lower()
    out = []
    for c in _contacts(db):
        if not ql or ql in str(c.get("name", "")).lower() or ql in str(c.get("company", "")).lower():
            out.append({k: c.get(k) for k in ("id", "name", "company", "status", "deal_status", "value", "owner")})
    return out
