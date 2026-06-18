-- Mr. Rex CRM schema for Supabase (shared with the Leads Agent website).
-- Run this in the Supabase SQL editor, then run supabase/migrate_contacts.py
-- to import the existing data/crm/contacts.json.

create extension if not exists pgcrypto;

create table if not exists public.contacts (
  id              text primary key default gen_random_uuid()::text,
  name            text not null,
  company         text,
  industry        text,
  phone           text,
  email           text,
  status          text default 'new',
  deal_status     text default 'open',
  value           text,
  owner           text,
  source          text,
  sentiment       text,
  next_follow_up  date,
  notes           text,
  tags            text[] default '{}',
  created_at      timestamptz default now(),
  updated_at      timestamptz default now()
);

create table if not exists public.interactions (
  id            text primary key default gen_random_uuid()::text,
  contact_id    text references public.contacts(id) on delete cascade,
  author        text,
  body          text,
  kind          text default 'comment',  -- comment | email
  subject       text,
  meeting_link  text,
  source        text,
  created_at    timestamptz default now()
);

create index if not exists interactions_contact_idx on public.interactions(contact_id);

-- UAT access policies: the publishable (anon) key may read/write.
-- HARDEN before production — verify a Firebase JWT (or move auth to Supabase)
-- and scope every row by organisation.
alter table public.contacts enable row level security;
alter table public.interactions enable row level security;

create policy "uat contacts read"     on public.contacts     for select using (true);
create policy "uat contacts insert"   on public.contacts     for insert with check (true);
create policy "uat contacts update"   on public.contacts     for update using (true) with check (true);
create policy "uat interactions read" on public.interactions for select using (true);
create policy "uat interactions insert" on public.interactions for insert with check (true);
