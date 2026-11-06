-- ============================================================================
-- NAHJ Boutique — Auth, admin allowlist, RLS and Storage
-- Run after 01 (schema) and 02 (API). Safe to run several times.
--
-- SECURITY MODEL
--   * The public site can only execute public.api(...).
--   * Direct table access is blocked by RLS (no policies at all).
--   * /admin works only for accounts whose email is in admin_emails.
--   * Customer sign-up is open; admin access is limited to admin_emails.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- Owner allowlist — add the real owner email from the SQL Editor, e.g.
--   insert into public.admin_emails (email) values ('ton-email@exemple.com');
-- then sign in once with it. No placeholder is seeded on purpose: with
-- "Confirm email" disabled, anyone could sign up with it and become admin.
-- ---------------------------------------------------------------------------

create table if not exists public.admin_emails (
  email text primary key
);

alter table public.admin_emails enable row level security;
revoke all on public.admin_emails from anon, authenticated;

-- Accept both text and uuid ids from older imports: the API compares as text.
alter table public.admins alter column user_id type text using user_id::text;

-- Create an admins row automatically for allowlisted accounts.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if exists (select 1 from public.admin_emails ae where lower(ae.email) = lower(new.email)) then
    insert into public.admins (user_id, email, is_owner)
    values (new.id::text, new.email, true)
    on conflict (user_id) do update set email = excluded.email, is_owner = true;
  end if;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Internal trigger function: nobody may call it through the REST API.
revoke all on function public.handle_new_user() from public, anon, authenticated;

-- Backfill: allowlisted accounts that already exist.
insert into public.admins (user_id, email, is_owner)
select u.id::text, u.email, true
from auth.users u
join public.admin_emails ae on lower(ae.email) = lower(u.email)
on conflict (user_id) do update set email = excluded.email, is_owner = true;

-- ---------------------------------------------------------------------------
-- Lock down every table. The API functions run as the table owner and keep
-- working; anon/authenticated cannot read or write tables directly.
-- ---------------------------------------------------------------------------

do $$
declare
  t record;
begin
  for t in
    select tablename from pg_tables where schemaname = 'public'
  loop
    execute format('alter table public.%I enable row level security', t.tablename);
  end loop;
end $$;

revoke all on all tables in schema public from anon, authenticated;
revoke all on all sequences in schema public from anon, authenticated;

grant usage on schema public to anon, authenticated;

-- ---------------------------------------------------------------------------
-- Storage: public bucket "media", only admins can upload/replace/delete.
-- ---------------------------------------------------------------------------

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'media', 'media', true,
  5767168, -- 5.5 MB
  array['image/jpeg','image/png','image/webp','image/gif','image/avif','video/mp4','video/webm']
)
on conflict (id) do update
set public = true,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "nahj media public read" on storage.objects;
drop policy if exists "nahj media admin insert" on storage.objects;
drop policy if exists "nahj media admin update" on storage.objects;
drop policy if exists "nahj media admin delete" on storage.objects;

create policy "nahj media public read"
  on storage.objects for select
  using (bucket_id = 'media');

create policy "nahj media admin insert"
  on storage.objects for insert
  to authenticated
  with check (bucket_id = 'media' and public.is_admin());

create policy "nahj media admin update"
  on storage.objects for update
  to authenticated
  using (bucket_id = 'media' and public.is_admin());

create policy "nahj media admin delete"
  on storage.objects for delete
  to authenticated
  using (bucket_id = 'media' and public.is_admin());
