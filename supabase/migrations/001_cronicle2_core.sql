-- =============================================================================
-- Cronicle 2 — Migración inicial (social nativo)
-- =============================================================================
-- Cómo aplicar:
--   1) Supabase Dashboard → SQL Editor → New query → pegar todo → Run
--   2) O con CLI: supabase db push
--
-- Proyecto: pidlodpgabmgguzzwksn
-- Rama: cronicle-2
-- =============================================================================

-- ─── Extensiones ──────────────────────────────────────────────────────────────
create extension if not exists "pgcrypto";

-- ─── Utilidad: updated_at automático ────────────────────────────────────────
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- ─── Perfiles ───────────────────────────────────────────────────────────────
create table public.profiles (
  id                    uuid primary key references auth.users (id) on delete cascade,
  username              text unique not null,
  display_name          text not null default '',
  avatar_url            text,
  banner_url            text,
  bio                   text not null default '' check (char_length(bio) <= 500),
  privacy_default       text not null default 'followers'
    check (privacy_default in ('public', 'followers', 'private')),
  needs_username_setup  boolean not null default false,
  created_at            timestamptz not null default now(),
  updated_at            timestamptz not null default now()
);

create index profiles_username_lower_idx on public.profiles (lower(username));

create trigger profiles_set_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();

-- ─── Follows ─────────────────────────────────────────────────────────────────
create table public.follows (
  follower_id   uuid not null references public.profiles (id) on delete cascade,
  following_id  uuid not null references public.profiles (id) on delete cascade,
  created_at    timestamptz not null default now(),
  primary key (follower_id, following_id),
  check (follower_id <> following_id)
);

create index follows_following_idx on public.follows (following_id);
create index follows_follower_idx on public.follows (follower_id);

-- ─── Actividades (feed) ──────────────────────────────────────────────────────
create table public.activities (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid not null references public.profiles (id) on delete cascade,
  kind          text not null
    check (kind in (
      'added', 'started', 'progress', 'completed', 'dropped', 'paused',
      'rated', 'reviewed', 'favorited', 'list_created', 'list_item_added',
      'status_text'
    )),
  media_kind    smallint,  -- 0=anime, 1=movie, 2=tv, 3=game, 4=manga, 5=book
  external_id   text,
  title         text not null default '',
  poster_url    text,
  payload       jsonb not null default '{}',
  visibility    text not null default 'followers'
    check (visibility in ('public', 'followers', 'private')),
  created_at    timestamptz not null default now()
);

create index activities_feed_idx on public.activities (created_at desc);
create index activities_user_idx on public.activities (user_id, created_at desc);

-- ─── Biblioteca sincronizada ─────────────────────────────────────────────────
create table public.library_entries_sync (
  user_id          uuid not null references public.profiles (id) on delete cascade,
  media_kind       smallint not null,
  external_id      text not null,
  title            text not null,
  poster_url       text,
  status           text not null default 'PLANNING',
  score            integer,
  progress         integer,
  total_episodes   integer,
  notes            text,
  visibility       text not null default 'followers'
    check (visibility in ('public', 'followers', 'private')),
  updated_at       timestamptz not null default now(),
  primary key (user_id, media_kind, external_id)
);

create index library_sync_user_updated_idx
  on public.library_entries_sync (user_id, updated_at desc);

create trigger library_entries_sync_set_updated_at
  before update on public.library_entries_sync
  for each row execute function public.set_updated_at();

-- ─── Listas compartidas ──────────────────────────────────────────────────────
create table public.shared_lists (
  id            uuid primary key default gen_random_uuid(),
  owner_id      uuid not null references public.profiles (id) on delete cascade,
  title         text not null,
  description   text not null default '',
  visibility    text not null default 'public'
    check (visibility in ('public', 'followers', 'private', 'collaborative')),
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

create index shared_lists_owner_idx on public.shared_lists (owner_id);

create trigger shared_lists_set_updated_at
  before update on public.shared_lists
  for each row execute function public.set_updated_at();

create table public.list_collaborators (
  list_id       uuid not null references public.shared_lists (id) on delete cascade,
  user_id       uuid not null references public.profiles (id) on delete cascade,
  role          text not null default 'editor'
    check (role in ('viewer', 'editor')),
  created_at    timestamptz not null default now(),
  primary key (list_id, user_id)
);

create table public.shared_list_items (
  list_id       uuid not null references public.shared_lists (id) on delete cascade,
  media_kind    smallint not null,
  external_id   text not null,
  title         text not null,
  poster_url    text,
  added_by      uuid references public.profiles (id) on delete set null,
  note          text,
  position      integer not null default 0,
  created_at    timestamptz not null default now(),
  primary key (list_id, media_kind, external_id)
);

create index shared_list_items_list_idx on public.shared_list_items (list_id, position);

-- ─── Vínculos externos (sin tokens OAuth) ────────────────────────────────────
create table public.external_account_links (
  user_id           uuid not null references public.profiles (id) on delete cascade,
  provider          text not null check (provider in ('anilist', 'trakt', 'steam')),
  external_user_id  text not null,
  display_name      text,
  avatar_url        text,
  linked_at         timestamptz not null default now(),
  primary key (user_id, provider)
);

-- ─── Notificaciones in-app ───────────────────────────────────────────────────
create table public.notifications (
  id            uuid primary key default gen_random_uuid(),
  recipient_id  uuid not null references public.profiles (id) on delete cascade,
  actor_id      uuid references public.profiles (id) on delete set null,
  kind          text not null
    check (kind in ('follow', 'activity_like', 'list_invite', 'mention')),
  entity_id     uuid,
  payload       jsonb not null default '{}',
  read_at       timestamptz,
  created_at    timestamptz not null default now()
);

create index notifications_recipient_idx
  on public.notifications (recipient_id, created_at desc);

-- ─── Bloqueos ────────────────────────────────────────────────────────────────
create table public.blocks (
  blocker_id    uuid not null references public.profiles (id) on delete cascade,
  blocked_id    uuid not null references public.profiles (id) on delete cascade,
  created_at    timestamptz not null default now(),
  primary key (blocker_id, blocked_id),
  check (blocker_id <> blocked_id)
);

create index blocks_blocked_idx on public.blocks (blocked_id);

-- =============================================================================
-- Helpers
-- =============================================================================

-- ¿El usuario autenticado sigue a [target_id]?
create or replace function public.is_following(target_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.follows f
    where f.follower_id = auth.uid()
      and f.following_id = target_id
  );
$$;

-- ¿Hay bloqueo entre auth.uid() y [other_id]?
create or replace function public.is_blocked_with(other_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.blocks b
    where (b.blocker_id = auth.uid() and b.blocked_id = other_id)
       or (b.blocker_id = other_id and b.blocked_id = auth.uid())
  );
$$;

-- Perfil al registrarse (username temporal hasta onboarding)
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_username text;
  v_display  text;
  v_avatar   text;
begin
  v_username := 'u_' || substr(replace(new.id::text, '-', ''), 1, 12);
  v_display := coalesce(
    nullif(trim(new.raw_user_meta_data->>'full_name'), ''),
    nullif(trim(new.raw_user_meta_data->>'name'), ''),
    nullif(split_part(coalesce(new.email, ''), '@', 1), ''),
    'Usuario'
  );
  v_avatar := coalesce(
    nullif(new.raw_user_meta_data->>'avatar_url', ''),
    nullif(new.raw_user_meta_data->>'picture', '')
  );

  insert into public.profiles (
    id, username, display_name, avatar_url, needs_username_setup
  ) values (
    new.id, v_username, v_display, v_avatar, true
  );

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Comprobar si un username está libre (para onboarding)
create or replace function public.is_username_available(candidate text)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select not exists (
    select 1
    from public.profiles p
    where lower(p.username) = lower(trim(candidate))
  );
$$;

grant execute on function public.is_username_available(text) to anon, authenticated;
grant execute on function public.is_following(uuid) to authenticated;

-- =============================================================================
-- Row Level Security
-- =============================================================================

alter table public.profiles enable row level security;
alter table public.follows enable row level security;
alter table public.activities enable row level security;
alter table public.library_entries_sync enable row level security;
alter table public.shared_lists enable row level security;
alter table public.list_collaborators enable row level security;
alter table public.shared_list_items enable row level security;
alter table public.external_account_links enable row level security;
alter table public.notifications enable row level security;
alter table public.blocks enable row level security;

-- ─── profiles ────────────────────────────────────────────────────────────────
create policy "profiles_select_public"
  on public.profiles for select
  using (not public.is_blocked_with(id));

create policy "profiles_insert_own"
  on public.profiles for insert
  with check (auth.uid() = id);

create policy "profiles_update_own"
  on public.profiles for update
  using (auth.uid() = id)
  with check (auth.uid() = id);

-- ─── follows ─────────────────────────────────────────────────────────────────
create policy "follows_select_public"
  on public.follows for select
  using (true);

create policy "follows_insert_own"
  on public.follows for insert
  with check (
    auth.uid() = follower_id
    and follower_id <> following_id
    and not public.is_blocked_with(following_id)
  );

create policy "follows_delete_own"
  on public.follows for delete
  using (auth.uid() = follower_id);

-- ─── activities ──────────────────────────────────────────────────────────────
create policy "activities_select_visible"
  on public.activities for select
  using (
    not public.is_blocked_with(user_id)
    and (
      visibility = 'public'
      or user_id = auth.uid()
      or (
        visibility = 'followers'
        and public.is_following(user_id)
      )
    )
  );

create policy "activities_insert_own"
  on public.activities for insert
  with check (auth.uid() = user_id);

create policy "activities_update_own"
  on public.activities for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "activities_delete_own"
  on public.activities for delete
  using (auth.uid() = user_id);

-- ─── library_entries_sync ────────────────────────────────────────────────────
create policy "library_sync_select_visible"
  on public.library_entries_sync for select
  using (
    not public.is_blocked_with(user_id)
    and (
      visibility = 'public'
      or user_id = auth.uid()
      or (
        visibility = 'followers'
        and public.is_following(user_id)
      )
    )
  );

create policy "library_sync_insert_own"
  on public.library_entries_sync for insert
  with check (auth.uid() = user_id);

create policy "library_sync_update_own"
  on public.library_entries_sync for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "library_sync_delete_own"
  on public.library_entries_sync for delete
  using (auth.uid() = user_id);

-- ─── shared_lists ────────────────────────────────────────────────────────────
create policy "shared_lists_select_visible"
  on public.shared_lists for select
  using (
    not public.is_blocked_with(owner_id)
    and (
      visibility = 'public'
      or owner_id = auth.uid()
      or (
        visibility = 'followers'
        and public.is_following(owner_id)
      )
      or (
        visibility = 'collaborative'
        and (
          owner_id = auth.uid()
          or exists (
            select 1 from public.list_collaborators lc
            where lc.list_id = id and lc.user_id = auth.uid()
          )
        )
      )
    )
  );

create policy "shared_lists_insert_own"
  on public.shared_lists for insert
  with check (auth.uid() = owner_id);

create policy "shared_lists_update_own"
  on public.shared_lists for update
  using (auth.uid() = owner_id)
  with check (auth.uid() = owner_id);

create policy "shared_lists_delete_own"
  on public.shared_lists for delete
  using (auth.uid() = owner_id);

-- ─── list_collaborators ──────────────────────────────────────────────────────
create policy "list_collaborators_select"
  on public.list_collaborators for select
  using (
    exists (
      select 1 from public.shared_lists sl
      where sl.id = list_id
        and (
          sl.owner_id = auth.uid()
          or user_id = auth.uid()
          or sl.visibility in ('public', 'followers')
        )
    )
  );

create policy "list_collaborators_manage_owner"
  on public.list_collaborators for all
  using (
    exists (
      select 1 from public.shared_lists sl
      where sl.id = list_id and sl.owner_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1 from public.shared_lists sl
      where sl.id = list_id and sl.owner_id = auth.uid()
    )
  );

-- ─── shared_list_items ───────────────────────────────────────────────────────
create policy "shared_list_items_select"
  on public.shared_list_items for select
  using (
    exists (
      select 1 from public.shared_lists sl
      where sl.id = list_id
        and not public.is_blocked_with(sl.owner_id)
        and (
          sl.visibility = 'public'
          or sl.owner_id = auth.uid()
          or (sl.visibility = 'followers' and public.is_following(sl.owner_id))
          or (
            sl.visibility = 'collaborative'
            and (
              sl.owner_id = auth.uid()
              or exists (
                select 1 from public.list_collaborators lc
                where lc.list_id = sl.id and lc.user_id = auth.uid()
              )
            )
          )
        )
    )
  );

create policy "shared_list_items_insert_editor"
  on public.shared_list_items for insert
  with check (
    exists (
      select 1 from public.shared_lists sl
      where sl.id = list_id
        and (
          sl.owner_id = auth.uid()
          or exists (
            select 1 from public.list_collaborators lc
            where lc.list_id = sl.id
              and lc.user_id = auth.uid()
              and lc.role = 'editor'
          )
        )
    )
  );

create policy "shared_list_items_update_editor"
  on public.shared_list_items for update
  using (
    exists (
      select 1 from public.shared_lists sl
      where sl.id = list_id
        and (
          sl.owner_id = auth.uid()
          or exists (
            select 1 from public.list_collaborators lc
            where lc.list_id = sl.id
              and lc.user_id = auth.uid()
              and lc.role = 'editor'
          )
        )
    )
  );

create policy "shared_list_items_delete_editor"
  on public.shared_list_items for delete
  using (
    exists (
      select 1 from public.shared_lists sl
      where sl.id = list_id
        and (
          sl.owner_id = auth.uid()
          or exists (
            select 1 from public.list_collaborators lc
            where lc.list_id = sl.id
              and lc.user_id = auth.uid()
              and lc.role = 'editor'
          )
        )
    )
  );

-- ─── external_account_links ──────────────────────────────────────────────────
create policy "external_links_select_own"
  on public.external_account_links for select
  using (auth.uid() = user_id);

create policy "external_links_select_public_metadata"
  on public.external_account_links for select
  using (true);

create policy "external_links_insert_own"
  on public.external_account_links for insert
  with check (auth.uid() = user_id);

create policy "external_links_update_own"
  on public.external_account_links for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "external_links_delete_own"
  on public.external_account_links for delete
  using (auth.uid() = user_id);

-- ─── notifications ───────────────────────────────────────────────────────────
create policy "notifications_select_own"
  on public.notifications for select
  using (auth.uid() = recipient_id);

create policy "notifications_update_own"
  on public.notifications for update
  using (auth.uid() = recipient_id)
  with check (auth.uid() = recipient_id);

create policy "notifications_insert_actor"
  on public.notifications for insert
  with check (auth.uid() = actor_id);

-- ─── blocks ──────────────────────────────────────────────────────────────────
create policy "blocks_select_own"
  on public.blocks for select
  using (auth.uid() = blocker_id);

create policy "blocks_insert_own"
  on public.blocks for insert
  with check (auth.uid() = blocker_id and blocker_id <> blocked_id);

create policy "blocks_delete_own"
  on public.blocks for delete
  using (auth.uid() = blocker_id);

-- =============================================================================
-- Realtime (opcional: feed social)
-- =============================================================================
alter publication supabase_realtime add table public.activities;
alter publication supabase_realtime add table public.notifications;

-- =============================================================================
-- Fin migración 001
-- =============================================================================
