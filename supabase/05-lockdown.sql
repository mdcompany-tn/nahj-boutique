-- ===========================================================================
-- 05 — Lockdown: the browser may only call public.api()
-- ===========================================================================
-- Run AFTER 01, 02, 03 and 04. Safe to run several times.
--
-- Why this file exists: Supabase grants EXECUTE on new functions directly to
-- the `anon` and `authenticated` roles. `revoke ... from public` (used in 02
-- and 04) does NOT remove those direct grants, so internal SECURITY DEFINER
-- functions such as save_variants() stayed callable through
-- /rest/v1/rpc/<name> with the public anon key. Revoke them explicitly.
--
-- public.api() is SECURITY DEFINER and owned by postgres, so it keeps calling
-- the internal functions below without any grant to anon/authenticated.
-- ===========================================================================

do $$
declare
  f record;
begin
  for f in
    select p.oid::regprocedure as sig
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.proname in (
        'store_data','product_list','product_get','order_quote','order_create',
        'order_track','my_orders','submit_form','price_cart','save_variants',
        'wish_list','wish_toggle','admin_api','handle_new_user',
        'is_admin','slugify','client_ip',
        'product_json','product_json_admin','order_public_json')
  loop
    execute format('revoke all on function %s from public, anon, authenticated', f.sig);
  end loop;
end $$;

-- The only function the website calls.
revoke all on function public.api(text, text, jsonb, jsonb) from public;
grant execute on function public.api(text, text, jsonb, jsonb) to anon, authenticated;

-- Used by Storage policies for signed-in users only.
revoke all on function public.is_admin() from public, anon;
grant execute on function public.is_admin() to authenticated;

-- ---------------------------------------------------------------------------
-- Safety: 02 and 03 insert the placeholder 'owner@example.com' into
-- admin_emails. If that row survived, anyone could sign up with that address
-- and become admin (especially with "Confirm email" disabled). Remove it.
-- Then add YOUR real owner email (see README "Changer l'email propriétaire").
-- ---------------------------------------------------------------------------
delete from public.admin_emails where lower(email) = 'owner@example.com';
delete from public.admins       where lower(email) = 'owner@example.com';
