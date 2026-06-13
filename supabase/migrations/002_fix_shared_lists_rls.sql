-- =============================================================================
-- Cronicle 2 — Fix RLS recursión en listas compartidas (002)
-- =============================================================================
-- Síntoma: REST API devuelve 500 en shared_lists, shared_list_items,
--           list_collaborators (infinite recursion en políticas RLS).
-- Cómo aplicar: Supabase Dashboard → SQL Editor → Run
-- =============================================================================

-- Helpers security definer (evitan que las políticas se llamen entre sí)
create or replace function public.is_list_owner(p_list_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.shared_lists sl
    where sl.id = p_list_id
      and sl.owner_id = auth.uid()
  );
$$;

create or replace function public.is_list_collaborator(p_list_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.list_collaborators lc
    where lc.list_id = p_list_id
      and lc.user_id = auth.uid()
  );
$$;

create or replace function public.can_view_shared_list(p_list_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.shared_lists sl
    where sl.id = p_list_id
      and not public.is_blocked_with(sl.owner_id)
      and (
        sl.visibility = 'public'
        or sl.owner_id = auth.uid()
        or (sl.visibility = 'followers' and public.is_following(sl.owner_id))
        or (
          sl.visibility = 'collaborative'
          and (sl.owner_id = auth.uid() or public.is_list_collaborator(p_list_id))
        )
      )
  );
$$;

create or replace function public.can_edit_shared_list(p_list_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select public.is_list_owner(p_list_id)
      or public.is_list_collaborator(p_list_id);
$$;

grant execute on function public.is_list_owner(uuid) to authenticated, anon;
grant execute on function public.is_list_collaborator(uuid) to authenticated, anon;
grant execute on function public.can_view_shared_list(uuid) to authenticated, anon;
grant execute on function public.can_edit_shared_list(uuid) to authenticated;

-- ─── shared_lists: reemplazar políticas ───────────────────────────────────────
drop policy if exists "shared_lists_select_visible" on public.shared_lists;
drop policy if exists "shared_lists_insert_own" on public.shared_lists;
drop policy if exists "shared_lists_update_own" on public.shared_lists;
drop policy if exists "shared_lists_delete_own" on public.shared_lists;

create policy "shared_lists_select_visible"
  on public.shared_lists for select
  using (
    not public.is_blocked_with(owner_id)
    and (
      visibility = 'public'
      or owner_id = auth.uid()
      or (visibility = 'followers' and public.is_following(owner_id))
      or (
        visibility = 'collaborative'
        and (owner_id = auth.uid() or public.is_list_collaborator(id))
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

-- ─── list_collaborators ─────────────────────────────────────────────────────
drop policy if exists "list_collaborators_select" on public.list_collaborators;
drop policy if exists "list_collaborators_manage_owner" on public.list_collaborators;

create policy "list_collaborators_select"
  on public.list_collaborators for select
  using (
    user_id = auth.uid()
    or public.is_list_owner(list_id)
    or public.can_view_shared_list(list_id)
  );

create policy "list_collaborators_insert_owner"
  on public.list_collaborators for insert
  with check (public.is_list_owner(list_id));

create policy "list_collaborators_update_owner"
  on public.list_collaborators for update
  using (public.is_list_owner(list_id))
  with check (public.is_list_owner(list_id));

create policy "list_collaborators_delete_owner"
  on public.list_collaborators for delete
  using (public.is_list_owner(list_id));

-- ─── shared_list_items ──────────────────────────────────────────────────────
drop policy if exists "shared_list_items_select" on public.shared_list_items;
drop policy if exists "shared_list_items_insert_editor" on public.shared_list_items;
drop policy if exists "shared_list_items_update_editor" on public.shared_list_items;
drop policy if exists "shared_list_items_delete_editor" on public.shared_list_items;

create policy "shared_list_items_select"
  on public.shared_list_items for select
  using (public.can_view_shared_list(list_id));

create policy "shared_list_items_insert_editor"
  on public.shared_list_items for insert
  with check (public.can_edit_shared_list(list_id));

create policy "shared_list_items_update_editor"
  on public.shared_list_items for update
  using (public.can_edit_shared_list(list_id));

create policy "shared_list_items_delete_editor"
  on public.shared_list_items for delete
  using (public.can_edit_shared_list(list_id));
