-- OAuth / session secrets for third-party accounts, scoped to Cronicle user.
-- RLS: only the owner can read/write. Use with Supabase Auth session.

create table public.connected_account_secrets (
  user_id     uuid not null references public.profiles (id) on delete cascade,
  provider    text not null check (provider in ('anilist', 'trakt', 'steam', 'twitch')),
  secrets     jsonb not null default '{}',
  updated_at  timestamptz not null default now(),
  primary key (user_id, provider)
);

create index connected_account_secrets_user_idx
  on public.connected_account_secrets (user_id);

alter table public.connected_account_secrets enable row level security;

create policy "connected_secrets_select_own"
  on public.connected_account_secrets for select
  using (auth.uid() = user_id);

create policy "connected_secrets_insert_own"
  on public.connected_account_secrets for insert
  with check (auth.uid() = user_id);

create policy "connected_secrets_update_own"
  on public.connected_account_secrets for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "connected_secrets_delete_own"
  on public.connected_account_secrets for delete
  using (auth.uid() = user_id);

-- Allow twitch in external_account_links metadata (optional future use).
alter table public.external_account_links
  drop constraint if exists external_account_links_provider_check;

alter table public.external_account_links
  add constraint external_account_links_provider_check
  check (provider in ('anilist', 'trakt', 'steam', 'twitch'));
