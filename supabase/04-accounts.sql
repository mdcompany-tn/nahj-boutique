-- ===========================================================================
-- 04 — Customer accounts: favorites (wishlist)
-- ===========================================================================
-- Run AFTER 01-schema-data.sql, 02-api.sql and 03-auth-storage.sql.
--
-- Guests can still order without an account. Favorites, however, belong to an
-- account: they are stored here, keyed by auth.uid(), and never in localStorage.
--
-- The table has RLS enabled with NO policies, and anon/authenticated have no
-- table privileges. The only way in is through public.api('wishlist', ...)
-- which calls the SECURITY DEFINER functions below. Both functions raise
-- 'Connexion requise' when there is no session, so a guest cannot build a list.
-- ===========================================================================

create table if not exists public.wishlist (
  user_id    uuid not null references auth.users(id) on delete cascade,
  product_id int  not null references public.products(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, product_id)
);

create index if not exists wishlist_product_idx on public.wishlist (product_id);

alter table public.wishlist enable row level security;
-- No policies on purpose: the table is private, functions do the work.
revoke all on table public.wishlist from anon, authenticated;

-- ---------------------------------------------------------------------------
-- GET /api/wishlist -> { ids: number[] } (most recent first)
-- ---------------------------------------------------------------------------
create or replace function public.wish_list()
returns jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_user uuid := auth.uid();
begin
  if v_user is null then
    raise exception 'Connexion requise' using errcode = 'P0001';
  end if;

  return jsonb_build_object('ids', coalesce((
    select jsonb_agg(w.product_id order by w.created_at desc)
    from public.wishlist w
    where w.user_id = v_user), '[]'::jsonb));
end;
$$;

-- ---------------------------------------------------------------------------
-- POST /api/wishlist { productId } -> { wished: boolean }
-- Adds when absent, removes when present.
-- ---------------------------------------------------------------------------
create or replace function public.wish_toggle(p_product_id int)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user uuid := auth.uid();
  v_deleted int := 0;
begin
  if v_user is null then
    raise exception 'Connexion requise' using errcode = 'P0001';
  end if;

  if p_product_id is null then
    raise exception 'Produit invalide' using errcode = 'P0001';
  end if;

  if not exists (select 1 from public.products where id = p_product_id) then
    raise exception 'Produit introuvable' using errcode = 'P0001';
  end if;

  delete from public.wishlist
   where user_id = v_user and product_id = p_product_id;
  get diagnostics v_deleted = row_count;

  if v_deleted > 0 then
    return jsonb_build_object('wished', false);
  end if;

  insert into public.wishlist (user_id, product_id)
  values (v_user, p_product_id)
  on conflict do nothing;

  return jsonb_build_object('wished', true);
end;
$$;

-- Internal only: the public site reaches these through public.api().
-- Supabase grants EXECUTE directly to anon/authenticated, so revoke there too.
revoke all on function public.wish_list() from public, anon, authenticated;
revoke all on function public.wish_toggle(int) from public, anon, authenticated;

-- ---------------------------------------------------------------------------
-- Orders placed while signed in are already linked by 02 (orders.user_id) and
-- read back by public.my_orders(). Nothing else to change here.
-- ---------------------------------------------------------------------------
