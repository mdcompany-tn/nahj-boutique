-- ============================================================================
-- NAHJ Boutique — API Supabase (RPC)
-- Replaces the Netlify Functions. Every call from the site goes through
-- public.api(), which is SECURITY DEFINER and enforces admin access itself.
-- Safe to run several times.
-- ============================================================================

-- Admin allowlist. Declared here because public.is_admin() references it; 03
-- adds the auth trigger, policies and storage rules that use it.
create table if not exists public.admin_emails (
  email text primary key
);

alter table public.admin_emails enable row level security;
revoke all on public.admin_emails from anon, authenticated;

-- Add the real owner address from the SQL Editor, for example:
--   insert into public.admin_emails (email) values ('ton-email@exemple.com');
-- Never seed a placeholder here: with "Confirm email" disabled, anyone could
-- sign up with that address and become admin.

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

create or replace function public.slugify(s text)
returns text
language sql
immutable
as $$
  select coalesce(
    nullif(
      left(
        trim(both '-' from regexp_replace(
          translate(lower(coalesce(s, '')),
            'àáâãäåçèéêëìíîïñòóôõöùúûüýÿœæ',
            'aaaaaaceeeeiiiinooooouuuuyyoa'),
          '[^a-z0-9]+', '-', 'g')),
        80),
      ''),
    'item');
$$;

create or replace function public.client_ip()
returns text
language sql
stable
as $$
  select coalesce(
    btrim(split_part(
      coalesce(nullif(current_setting('request.headers', true), '')::jsonb ->> 'x-forwarded-for', ''),
      ',', 1)),
    '');
$$;

-- ---------------------------------------------------------------------------
-- Product / order JSON shapes (same keys as the old API)
-- ---------------------------------------------------------------------------

create or replace function public.product_json(p public.products)
returns jsonb
language sql
stable
as $$
  select jsonb_build_object(
    'id', p.id,
    'slug', p.slug,
    'name', p.name,
    'name_ar', p.name_ar,
    'description', p.description,
    'description_ar', p.description_ar,
    'details', p.details,
    'care', p.care,
    'price', p.price::float8,
    'compare_at_price', p.compare_at_price::float8,
    'category', p.category,
    'gender', p.gender,
    'collection_ids', to_jsonb(p.collection_ids),
    'images', to_jsonb(p.images),
    'tags', to_jsonb(p.tags),
    'status', p.status,
    'featured', p.featured,
    'is_new', p.is_new,
    'position', p.position,
    'created_at', p.created_at,
    'updated_at', p.updated_at,
    'variants', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', v.id, 'size', v.size, 'color', v.color, 'color_hex', v.color_hex,
        'sku', v.sku, 'stock', v.stock, 'image', v.image, 'position', v.position)
        order by v.position, v.id)
      from variants v where v.product_id = p.id), '[]'::jsonb),
    'sold', coalesce((
      select sum((it ->> 'qty')::int)
      from orders o, jsonb_array_elements(o.items) it
      where (it ->> 'product_id')::int = p.id
        and o.status not in ('cancelled', 'returned')), 0)::int
  );
$$;

create or replace function public.product_json_admin(p public.products)
returns jsonb
language sql
stable
as $$
  select public.product_json(p) || jsonb_build_object('cost_price', p.cost_price::float8);
$$;

create or replace function public.order_public_json(o public.orders)
returns jsonb
language sql
stable
as $$
  select jsonb_build_object(
    'number', o.number,
    'customer_name', o.customer_name,
    'governorate', o.governorate,
    'city', o.city,
    'items', coalesce((
      select jsonb_agg(it - 'unit_cost')
      from jsonb_array_elements(o.items) it), '[]'::jsonb),
    'subtotal', o.subtotal::float8,
    'delivery_fee', o.delivery_fee::float8,
    'discount', o.discount::float8,
    'discount_code', o.discount_code,
    'total', o.total::float8,
    'payment_method', o.payment_method,
    'payment_status', o.payment_status,
    'status', o.status,
    'history', coalesce((
      select jsonb_agg(h - 'by')
      from jsonb_array_elements(coalesce(o.history, '[]'::jsonb)) h), '[]'::jsonb),
    'created_at', o.created_at
  );
$$;

-- ---------------------------------------------------------------------------
-- Public storefront
-- ---------------------------------------------------------------------------

create or replace function public.store_data()
returns jsonb
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select jsonb_build_object(
    'settings', coalesce((
      select jsonb_object_agg(key, value) from settings
      where key = any (array['brand','announcements','hero','story','offer','shipping','contact','about','home'])), '{}'::jsonb),
    'collections', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', c.id, 'slug', c.slug, 'name', c.name, 'name_ar', c.name_ar,
        'tagline', c.tagline, 'description', c.description, 'image', c.image,
        'position', c.position, 'visible', c.visible,
        'product_count', (select count(*)::int from products p
                          where p.status = 'published' and c.id = any (p.collection_ids)))
        order by c.position, c.id)
      from collections c where c.visible), '[]'::jsonb),
    'zones', coalesce((
      select jsonb_agg(jsonb_build_object(
        'governorate', z.governorate, 'name_ar', z.name_ar,
        'fee', z.fee::float8, 'delay', z.delay)
        order by z.position)
      from delivery_zones z where z.active), '[]'::jsonb)
  );
$$;

create or replace function public.product_list()
returns jsonb
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select jsonb_build_object('products', coalesce(jsonb_agg(public.product_json(p) order by p.position, p.id), '[]'::jsonb))
  from products p
  where p.status = 'published';
$$;

create or replace function public.product_get(p_slug text)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_product products;
  v_reviews jsonb;
  v_related jsonb;
begin
  select * into v_product from products
  where slug = p_slug and status = 'published';
  if not found then
    raise exception 'Produit introuvable' using errcode = 'P0001';
  end if;

  select coalesce(jsonb_agg(jsonb_build_object(
    'id', r.id, 'name', r.name, 'rating', r.rating, 'body', r.body, 'created_at', r.created_at)
    order by r.created_at desc), '[]'::jsonb)
  into v_reviews
  from reviews r
  where r.product_id = v_product.id and r.approved;

  select coalesce(jsonb_agg(public.product_json(q) order by q.featured desc, q.position), '[]'::jsonb)
  into v_related
  from (
    select * from products x
    where x.status = 'published'
      and x.id <> v_product.id
      and (x.collection_ids && v_product.collection_ids or x.category = v_product.category)
    order by x.featured desc, x.position
    limit 4
  ) q;

  return jsonb_build_object(
    'product', public.product_json(v_product),
    'reviews', v_reviews,
    'related', v_related
  );
end;
$$;

-- ---------------------------------------------------------------------------
-- Pricing (never trusts client prices)
-- ---------------------------------------------------------------------------

create or replace function public.price_cart(
  p_items jsonb,
  p_governorate text,
  p_code text,
  p_lock boolean default false)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_items jsonb := '[]'::jsonb;
  v_problems text[] := '{}';
  v_subtotal numeric := 0;
  v_delivery numeric := 0;
  v_discount numeric := 0;
  v_code text := null;
  v_code_error text := null;
  v_total numeric := 0;
  v_threshold numeric := 0;
  v_gov text := nullif(btrim(coalesce(p_governorate, '')), '');
  v_promo text := nullif(btrim(coalesce(p_code, '')), '');
  rec record;
  dz record;
  dc record;
  v_qty int;
begin
  if p_items is null or jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items) = 0 then
    raise exception 'Votre panier est vide' using errcode = 'P0001';
  end if;

  -- merge duplicate variant lines
  for rec in
    select (x ->> 'variantId')::int as variant_id, sum((x ->> 'qty')::int)::int as qty
    from jsonb_array_elements(p_items) x
    group by 1
    order by 1
  loop
    v_qty := rec.qty;
    if v_qty is null or v_qty < 1 then
      continue;
    end if;

    if p_lock then
      select v.id, v.size, v.color, v.stock, p.id as product_id, p.name, p.slug,
             coalesce(nullif(v.image, ''), p.images[1], '') as image, p.price, p.cost_price
      into rec
      from variants v join products p on p.id = v.product_id
      where v.id = rec.variant_id and p.status = 'published'
      for update of v;
    else
      select v.id, v.size, v.color, v.stock, p.id as product_id, p.name, p.slug,
             coalesce(nullif(v.image, ''), p.images[1], '') as image, p.price, p.cost_price
      into rec
      from variants v join products p on p.id = v.product_id
      where v.id = rec.variant_id and p.status = 'published';
    end if;

    if not found then
      v_problems := array_append(v_problems, 'Un article n''est plus disponible');
      continue;
    end if;

    if rec.stock < v_qty then
      v_problems := array_append(v_problems,
        rec.name || ' (' || rec.size || case when rec.color <> '' then ' · ' || rec.color else '' end
        || ') : ' || rec.stock || ' en stock');
    end if;

    v_items := v_items || jsonb_build_array(jsonb_build_object(
      'variant_id', rec.id,
      'product_id', rec.product_id,
      'slug', rec.slug,
      'name', rec.name,
      'size', rec.size,
      'color', rec.color,
      'image', rec.image,
      'unit_price', rec.price::float8,
      'unit_cost', rec.cost_price::float8,
      'qty', v_qty,
      'line_total', round(rec.price * v_qty, 3)::float8,
      'stock', rec.stock));

    v_subtotal := v_subtotal + round(rec.price * v_qty, 3);
  end loop;

  if jsonb_array_length(v_items) = 0 then
    raise exception 'Votre panier est vide' using errcode = 'P0001';
  end if;

  select coalesce((value ->> 'freeThreshold')::numeric, 0) into v_threshold
  from settings where key = 'shipping';
  v_threshold := coalesce(v_threshold, 0);

  if v_gov is not null then
    select fee into dz from delivery_zones where governorate = v_gov and active;
    if not found then
      raise exception 'Gouvernorat non desservi' using errcode = 'P0001';
    end if;
    v_delivery := case when v_threshold > 0 and v_subtotal >= v_threshold then 0 else dz.fee end;
  end if;

  if v_promo is not null then
    if p_lock then
      select code, kind, value, min_subtotal, max_uses, uses into dc
      from discount_codes
      where upper(code) = upper(v_promo) and active
        and (starts_at is null or starts_at <= now())
        and (ends_at is null or ends_at >= now())
      for update;
    else
      select code, kind, value, min_subtotal, max_uses, uses into dc
      from discount_codes
      where upper(code) = upper(v_promo) and active
        and (starts_at is null or starts_at <= now())
        and (ends_at is null or ends_at >= now());
    end if;

    if not found then
      v_code_error := 'Code invalide ou expiré';
    elsif dc.max_uses is not null and dc.uses >= dc.max_uses then
      v_code_error := 'Ce code a atteint sa limite d''utilisation';
    elsif v_subtotal < dc.min_subtotal then
      v_code_error := 'Minimum d''achat : ' || dc.min_subtotal || ' DT';
    else
      v_code := dc.code;
      if dc.kind = 'percent' then
        v_discount := round((v_subtotal * least(dc.value, 100)) / 100, 3);
      elsif dc.kind = 'fixed' then
        v_discount := least(dc.value, v_subtotal);
      elsif dc.kind = 'shipping' then
        v_discount := v_delivery;
      end if;
    end if;
  end if;

  v_total := round(greatest(0, v_subtotal + v_delivery - v_discount), 3);

  return jsonb_build_object(
    'items', v_items,
    'subtotal', v_subtotal::float8,
    'deliveryFee', v_delivery::float8,
    'discount', v_discount::float8,
    'code', v_code,
    'codeError', v_code_error,
    'total', v_total::float8,
    'freeThreshold', v_threshold::float8,
    'problems', to_jsonb(v_problems)
  );
end;
$$;

create or replace function public.order_quote(p_body jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v jsonb;
begin
  v := public.price_cart(
    p_body -> 'items',
    nullif(btrim(coalesce(p_body ->> 'governorate', '')), ''),
    nullif(btrim(coalesce(p_body ->> 'code', '')), ''),
    false);

  return v || jsonb_build_object(
    'items', coalesce((
      select jsonb_agg(it - 'unit_cost') from jsonb_array_elements(v -> 'items') it), '[]'::jsonb));
end;
$$;

-- ---------------------------------------------------------------------------
-- Orders
-- ---------------------------------------------------------------------------

create or replace function public.order_create(p_body jsonb, p_ip text default '')
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_items jsonb := p_body -> 'items';
  v_name text := btrim(coalesce(p_body ->> 'customerName', ''));
  v_phone text := btrim(coalesce(p_body ->> 'phone', ''));
  v_email text := btrim(coalesce(p_body ->> 'email', ''));
  v_gov text := btrim(coalesce(p_body ->> 'governorate', ''));
  v_city text := btrim(coalesce(p_body ->> 'city', ''));
  v_address text := btrim(coalesce(p_body ->> 'address', ''));
  v_notes text := btrim(coalesce(p_body ->> 'notes', ''));
  v_phone_key text;
  v_pieces int := 0;
  v_priced jsonb;
  v_order_items jsonb;
  v_history jsonb;
  v_order_id int;
  v_user text := auth.uid()::text;
  v_n int;
  rec record;
begin
  -- honeypot
  if btrim(coalesce(p_body ->> 'website', '')) <> '' then
    raise exception 'Commande refusée' using errcode = 'P0001';
  end if;

  if jsonb_typeof(v_items) <> 'array' or jsonb_array_length(v_items) < 1 or jsonb_array_length(v_items) > 50 then
    raise exception 'Panier invalide' using errcode = 'P0001';
  end if;
  if exists (
    select 1 from jsonb_array_elements(v_items) x
    where coalesce((x ->> 'qty')::int, 0) not between 1 and 20
       or coalesce((x ->> 'variantId')::int, 0) <= 0
  ) then
    raise exception 'Panier invalide' using errcode = 'P0001';
  end if;
  select coalesce(sum((x ->> 'qty')::int), 0) into v_pieces from jsonb_array_elements(v_items) x;
  if v_pieces > 30 then
    raise exception 'Maximum 30 pièces par commande. Contactez-nous pour une commande plus importante.' using errcode = 'P0001';
  end if;

  if length(v_name) < 3 or length(v_name) > 120 then
    raise exception 'Nom requis' using errcode = 'P0001';
  end if;
  if v_phone !~ '^(\+?216)?[[:space:]]?[2-9][0-9]([[:space:]]?[0-9]){6}$' then
    raise exception 'Numéro tunisien invalide (8 chiffres)' using errcode = 'P0001';
  end if;
  if v_email <> '' and v_email !~ '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$' then
    raise exception 'Email invalide' using errcode = 'P0001';
  end if;
  if length(v_gov) < 2 or length(v_gov) > 60 then
    raise exception 'Gouvernorat requis' using errcode = 'P0001';
  end if;
  if length(v_address) < 5 or length(v_address) > 400 then
    raise exception 'Adresse requise' using errcode = 'P0001';
  end if;
  if length(v_city) > 120 or length(v_notes) > 1000 then
    raise exception 'Données invalides' using errcode = 'P0001';
  end if;

  v_phone_key := right(regexp_replace(v_phone, '[^0-9]', '', 'g'), 8);

  -- serialize orders from the same visitor / phone
  perform pg_advisory_xact_lock(hashtext('ip:' || coalesce(p_ip, '')));
  perform pg_advisory_xact_lock(hashtext('tel:' || v_phone_key));

  if coalesce(p_ip, '') <> '' then
    select count(*) into v_n from orders
    where client_ip = p_ip and created_at > now() - interval '1 hour';
    if v_n >= 5 then
      raise exception 'Trop de commandes en peu de temps. Réessayez plus tard ou contactez-nous.' using errcode = 'P0001';
    end if;
  end if;

  select count(*) into v_n from orders
  where status = 'pending'
    and right(regexp_replace(phone, '[^0-9]', '', 'g'), 8) = v_phone_key;
  if v_n >= 3 then
    raise exception 'Vous avez déjà des commandes en attente de confirmation. Notre équipe vous appelle très vite.' using errcode = 'P0001';
  end if;

  v_priced := public.price_cart(v_items, v_gov, nullif(btrim(coalesce(p_body ->> 'code', '')), ''), true);

  if jsonb_array_length(v_priced -> 'problems') > 0 then
    raise exception 'Stock insuffisant : %', (
      select string_agg(value, ', ') from jsonb_array_elements_text(v_priced -> 'problems'));
  end if;

  for rec in select value as it from jsonb_array_elements(v_priced -> 'items') loop
    update variants set stock = stock - (rec.it ->> 'qty')::int
    where id = (rec.it ->> 'variant_id')::int;
  end loop;

  if v_priced ->> 'code' is not null then
    update discount_codes set uses = uses + 1 where code = v_priced ->> 'code';
  end if;

  select coalesce(jsonb_agg(it - 'stock'), '[]'::jsonb)
  into v_order_items
  from jsonb_array_elements(v_priced -> 'items') it;

  v_history := jsonb_build_array(jsonb_build_object(
    'status', 'pending',
    'at', to_char(now() at time zone 'utc', 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"'),
    'note', 'Commande passée en ligne'));

  insert into orders (
    number, customer_name, phone, email, governorate, city, address, notes, items,
    subtotal, delivery_fee, discount, discount_code, total, payment_method, user_id, history, client_ip)
  values (
    'NJ-' || nextval('order_number_seq'), v_name, v_phone, v_email, v_gov, v_city, v_address, v_notes, v_order_items,
    (v_priced ->> 'subtotal')::numeric, (v_priced ->> 'deliveryFee')::numeric, (v_priced ->> 'discount')::numeric,
    v_priced ->> 'code', (v_priced ->> 'total')::numeric, 'cod', v_user, v_history, coalesce(p_ip, ''))
  returning id into v_order_id;

  for rec in select value as it from jsonb_array_elements(v_priced -> 'items') loop
    insert into stock_movements (variant_id, product_id, delta, reason, order_id)
    values ((rec.it ->> 'variant_id')::int, (rec.it ->> 'product_id')::int, -((rec.it ->> 'qty')::int), 'order', v_order_id);
  end loop;

  return jsonb_build_object('order', (
    select public.order_public_json(o) from orders o where o.id = v_order_id));
end;
$$;

create or replace function public.order_track(p_number text, p_phone text)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_phone text := right(regexp_replace(coalesce(p_phone, ''), '[^0-9]', '', 'g'), 8);
  v_order jsonb;
begin
  if length(v_phone) <> 8 then
    raise exception 'Téléphone requis' using errcode = 'P0001';
  end if;

  select public.order_public_json(o) into v_order
  from orders o
  where upper(o.number) = upper(p_number)
    and right(regexp_replace(o.phone, '[^0-9]', '', 'g'), 8) = v_phone;

  if v_order is null then
    raise exception 'Commande introuvable' using errcode = 'P0001';
  end if;
  return jsonb_build_object('order', v_order);
end;
$$;

create or replace function public.my_orders()
returns jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_user text := auth.uid()::text;
begin
  if v_user is null or v_user = '' then
    raise exception 'Connexion requise' using errcode = 'P0001';
  end if;

  return jsonb_build_object('orders', coalesce((
    select jsonb_agg(public.order_public_json(o) order by o.created_at desc)
    from (select * from orders where user_id = v_user order by created_at desc limit 50) o), '[]'::jsonb));
end;
$$;

-- ---------------------------------------------------------------------------
-- Forms (contact / reviews / newsletter)
-- ---------------------------------------------------------------------------

create or replace function public.submit_form(p_kind text, p_body jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_name text;
  v_email text;
  v_rating int;
  v_product_id int;
begin
  -- honeypot: invisible to people, so only bots fill it. Pretend it worked.
  if btrim(coalesce(p_body ->> 'website', '')) <> '' then
    return jsonb_build_object('ok', true);
  end if;

  if p_kind = 'contact' then
    v_name := btrim(coalesce(p_body ->> 'name', ''));
    if length(v_name) < 2 or length(v_name) > 100 then
      raise exception 'Nom requis' using errcode = 'P0001';
    end if;
    if length(btrim(coalesce(p_body ->> 'body', ''))) < 5 then
      raise exception 'Message trop court' using errcode = 'P0001';
    end if;
    insert into messages (name, email, phone, subject, body)
    values (
      v_name,
      left(btrim(coalesce(p_body ->> 'email', '')), 200),
      left(btrim(coalesce(p_body ->> 'phone', '')), 30),
      left(btrim(coalesce(p_body ->> 'subject', '')), 150),
      left(btrim(p_body ->> 'body'), 4000));
    return jsonb_build_object('ok', true);
  end if;

  if p_kind = 'reviews' then
    v_product_id := coalesce((p_body ->> 'productId')::int, 0);
    v_name := btrim(coalesce(p_body ->> 'name', ''));
    v_rating := coalesce((p_body ->> 'rating')::int, 0);
    if v_product_id <= 0 or length(v_name) < 2 or length(v_name) > 60 or v_rating < 1 or v_rating > 5 then
      raise exception 'Avis invalide' using errcode = 'P0001';
    end if;
    if not exists (select 1 from products where id = v_product_id and status = 'published') then
      raise exception 'Produit introuvable' using errcode = 'P0001';
    end if;
    insert into reviews (product_id, name, rating, body)
    values (v_product_id, v_name, v_rating, left(coalesce(p_body ->> 'body', ''), 1000));
    return jsonb_build_object('ok', true);
  end if;

  if p_kind = 'newsletter' then
    v_email := lower(btrim(coalesce(p_body ->> 'email', '')));
    if v_email !~ '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$' then
      raise exception 'Email invalide' using errcode = 'P0001';
    end if;
    insert into subscribers (email) values (left(v_email, 200))
    on conflict (email) do nothing;
    return jsonb_build_object('ok', true);
  end if;

  raise exception 'Route inconnue' using errcode = 'P0001';
end;
$$;

-- ---------------------------------------------------------------------------
-- Admin helpers
-- ---------------------------------------------------------------------------

create or replace function public.save_variants(p_product_id int, p_variants jsonb, p_by text)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_keep int[] := '{}';
  v_id int;
  v_stock int;
  v_old int;
  v_i int := 0;
  rec record;
  v_size text;
  v_color text;
  v_color_hex text;
  v_sku text;
  v_image text;
begin
  if p_variants is null or jsonb_typeof(p_variants) <> 'array' or jsonb_array_length(p_variants) < 1 then
    raise exception 'Au moins une variante est requise' using errcode = 'P0001';
  end if;

  select coalesce(array_agg((x ->> 'id')::int), '{}')
  into v_keep
  from jsonb_array_elements(p_variants) x
  where coalesce(x ->> 'id', '') <> '';

  delete from variants
  where product_id = p_product_id and not (id = any (v_keep));

  for rec in select value as it from jsonb_array_elements(p_variants) loop
    v_id := nullif(rec.it ->> 'id', '')::int;
    v_size := left(btrim(coalesce(rec.it ->> 'size', 'Unique')), 20);
    v_color := left(btrim(coalesce(rec.it ->> 'color', '')), 40);
    v_color_hex := left(btrim(coalesce(rec.it ->> 'color_hex', '')), 9);
    v_sku := left(btrim(coalesce(rec.it ->> 'sku', '')), 60);
    v_stock := coalesce((rec.it ->> 'stock')::int, 0);
    v_image := left(btrim(coalesce(rec.it ->> 'image', '')), 500);

    if v_size = '' then
      raise exception 'Taille requise' using errcode = 'P0001';
    end if;
    if v_stock < 0 then
      raise exception 'Stock invalide' using errcode = 'P0001';
    end if;

    if v_id is not null then
      select stock into v_old from variants where id = v_id and product_id = p_product_id;
      if not found then
        raise exception 'Variante invalide' using errcode = 'P0001';
      end if;
      update variants
      set size = v_size, color = v_color, color_hex = v_color_hex, sku = v_sku,
          stock = v_stock, position = v_i, image = v_image
      where id = v_id;
      if v_old <> v_stock then
        insert into stock_movements (variant_id, product_id, delta, reason, by_email)
        values (v_id, p_product_id, v_stock - v_old, 'manual', coalesce(p_by, ''));
      end if;
    else
      insert into variants (product_id, size, color, color_hex, sku, stock, position, image)
      values (p_product_id, v_size, v_color, v_color_hex, v_sku, v_stock, v_i, v_image)
      returning id into v_id;
      if v_stock <> 0 then
        insert into stock_movements (variant_id, product_id, delta, reason, by_email)
        values (v_id, p_product_id, v_stock, 'manual', coalesce(p_by, ''));
      end if;
    end if;

    v_i := v_i + 1;
  end loop;
end;
$$;

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (
      select 1 from admins where user_id::text = auth.uid()::text)
    or exists (
      select 1 from admin_emails ae
      where lower(ae.email) = lower(coalesce(auth.jwt() ->> 'email', '')));
$$;

-- ---------------------------------------------------------------------------
-- Admin API
-- ---------------------------------------------------------------------------

create or replace function public.admin_api(
  p_res text, p_id text, p_method text, p_query jsonb, p_body jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_method text := upper(coalesce(p_method, 'GET'));
  v_query jsonb := coalesce(p_query, '{}'::jsonb);
  v_body jsonb := coalesce(p_body, '{}'::jsonb);
  v_email text := coalesce(auth.jwt() ->> 'email', '');
  v_admin admins;
  v_id int;
  v_result jsonb;
begin
  if not public.is_admin() then
    raise exception 'Accès réservé aux administrateurs' using errcode = 'P0001';
  end if;

  select * into v_admin from admins where user_id::text = auth.uid()::text;
  -- ids are numeric everywhere except discount codes (text) and setting keys.
  v_id := case when coalesce(p_id, '') ~ '^[0-9]+$' then p_id::int end;

  if p_res = 'me' then
    return jsonb_build_object(
      'email', v_email,
      'name', coalesce(auth.jwt() -> 'user_metadata' ->> 'full_name', split_part(v_email, '@', 1)),
      'owner', coalesce(v_admin.is_owner, false));
  end if;

  if p_res = 'dashboard' then
    declare
      v_low int;
      v_stats jsonb;
      v_recent jsonb;
      v_low_list jsonb;
      v_daily jsonb;
      v_statuses jsonb;
      v_top jsonb;
      v_regions jsonb;
      v_valid text := 'not in (''cancelled'',''returned'')';
    begin
      select coalesce((value ->> 'lowStock')::int, 3) into v_low from settings where key = 'accounting';
      v_low := coalesce(v_low, 3);

      select jsonb_build_object(
        'orders', (select count(*)::int from orders),
        'pending', (select count(*)::int from orders where status = 'pending'),
        'to_ship', (select count(*)::int from orders where status in ('confirmed','preparing')),
        'revenue', (select coalesce(sum(total),0)::float8 from orders where status not in ('cancelled','returned')),
        'revenue30', (select coalesce(sum(total),0)::float8 from orders where status not in ('cancelled','returned') and created_at > now() - interval '30 days'),
        'revenue_prev30', (select coalesce(sum(total),0)::float8 from orders where status not in ('cancelled','returned') and created_at > now() - interval '60 days' and created_at <= now() - interval '30 days'),
        'revenue_today', (select coalesce(sum(total),0)::float8 from orders where status not in ('cancelled','returned') and created_at::date = current_date),
        'orders30', (select count(*)::int from orders where status not in ('cancelled','returned') and created_at > now() - interval '30 days'),
        'avg_basket', (select coalesce(avg(total),0)::float8 from orders where status not in ('cancelled','returned')),
        'to_collect', (select coalesce(sum(total),0)::float8 from orders where status not in ('cancelled','returned') and payment_status = 'pending'),
        'products', (select count(*)::int from products where status = 'published'),
        'units', (select coalesce(sum(stock),0)::int from variants),
        'out_of_stock', (select count(*)::int from variants where stock = 0),
        'low_stock', (select count(*)::int from variants where stock > 0 and stock <= v_low),
        'unread', (select count(*)::int from messages where not read),
        'reviews_pending', (select count(*)::int from reviews where not approved),
        'subscribers', (select count(*)::int from subscribers)
      ) into v_stats;

      select coalesce(jsonb_agg(to_jsonb(o) order by o.created_at desc), '[]'::jsonb) into v_recent
      from (
        select number, customer_name, governorate, subtotal::float8 as subtotal,
               delivery_fee::float8 as delivery_fee, total::float8 as total, status, created_at
        from orders order by created_at desc limit 8) o;

      select coalesce(jsonb_agg(jsonb_build_object(
        'id', x.id, 'name', x.name, 'size', x.size, 'color', x.color, 'stock', x.stock, 'image', x.image)
        order by x.stock, x.name), '[]'::jsonb) into v_low_list
      from (
        select v.id, p.name, v.size, v.color, v.stock,
               coalesce(nullif(v.image, ''), p.images[1], '') as image
        from variants v join products p on p.id = v.product_id
        where v.stock <= v_low
        order by v.stock, p.name limit 10) x;

      select coalesce(jsonb_agg(jsonb_build_object(
        'day', to_char(d, 'DD/MM'),
        'total', coalesce(s.total, 0)::float8,
        'count', coalesce(s.cnt, 0)) order by d), '[]'::jsonb) into v_daily
      from generate_series(current_date - 29, current_date, interval '1 day') d
      left join (
        select created_at::date as day, sum(total) as total, count(*)::int as cnt
        from orders where status not in ('cancelled','returned') group by 1) s
        on s.day = d::date;

      select coalesce(jsonb_agg(jsonb_build_object('status', x.status, 'count', x.count) order by x.status), '[]'::jsonb)
      into v_statuses
      from (select status, count(*)::int as count from orders group by status) x;

      select coalesce(jsonb_agg(jsonb_build_object(
        'name', x.name, 'qty', x.qty, 'revenue', x.revenue) order by x.qty desc), '[]'::jsonb) into v_top
      from (
        select it ->> 'name' as name, sum((it ->> 'qty')::int)::int as qty,
               sum((it ->> 'line_total')::numeric)::float8 as revenue
        from orders o, jsonb_array_elements(o.items) it
        where o.status not in ('cancelled','returned')
        group by 1 order by qty desc limit 5) x;

      select coalesce(jsonb_agg(jsonb_build_object(
        'governorate', x.governorate, 'count', x.count, 'total', x.total) order by x.total desc), '[]'::jsonb) into v_regions
      from (
        select governorate, count(*)::int as count, sum(total)::float8 as total
        from orders where status not in ('cancelled','returned')
        group by 1 order by total desc limit 6) x;

      return jsonb_build_object(
        'stats', v_stats, 'recent', v_recent, 'low', v_low_list, 'daily', v_daily,
        'statuses', v_statuses, 'top', v_top, 'regions', v_regions, 'lowThreshold', v_low);
    end;
  end if;

  if p_res = 'stock' then
    if v_method = 'GET' then
      declare
        v_variants jsonb;
        v_movements jsonb;
      begin
        select coalesce(jsonb_agg(jsonb_build_object(
          'id', x.id, 'product_id', x.product_id, 'name', x.name, 'category', x.category,
          'status', x.status, 'size', x.size, 'color', x.color, 'color_hex', x.color_hex,
          'sku', x.sku, 'stock', x.stock, 'price', x.price, 'cost_price', x.cost_price,
          'image', x.image, 'sold30', x.sold30) order by x.pp, x.pid, x.vp, x.id), '[]'::jsonb)
        into v_variants
        from (
          select v.id, v.product_id, p.name, p.category, p.status, v.size, v.color, v.color_hex,
                 v.sku, v.stock, p.price::float8 as price, p.cost_price::float8 as cost_price,
                 coalesce(nullif(v.image, ''), p.images[1], '') as image,
                 p.position as pp, p.id as pid, v.position as vp,
                 coalesce((select sum((it ->> 'qty')::int)
                   from orders o, jsonb_array_elements(o.items) it
                   where (it ->> 'variant_id')::int = v.id
                     and o.status not in ('cancelled','returned')
                     and o.created_at > now() - interval '30 days'), 0)::int as sold30
          from variants v join products p on p.id = v.product_id) x;

        select coalesce(jsonb_agg(jsonb_build_object(
          'id', m.id, 'delta', m.delta, 'reason', m.reason, 'note', m.note,
          'by_email', m.by_email, 'created_at', m.created_at, 'order_number', m.order_number,
          'name', m.name, 'size', m.size, 'color', m.color) order by m.created_at desc, m.id desc), '[]'::jsonb)
        into v_movements
        from (
          select sm.id, sm.delta, sm.reason, sm.note, sm.by_email, sm.created_at,
                 o.number as order_number, p.name, v.size, v.color
          from stock_movements sm
          left join variants v on v.id = sm.variant_id
          left join products p on p.id = sm.product_id
          left join orders o on o.id = sm.order_id
          order by sm.created_at desc, sm.id desc limit 200) m;

        return jsonb_build_object('variants', v_variants, 'movements', v_movements);
      end;
    end if;

    if v_method = 'POST' and v_id is not null then
      declare
        v_delta int := coalesce((v_body ->> 'delta')::int, 0);
        v_reason text := coalesce(v_body ->> 'reason', '');
        v_note text := left(coalesce(v_body ->> 'note', ''), 300);
        v_stock int;
        v_product_id int;
      begin
        if v_delta = 0 then
          raise exception 'Quantité requise' using errcode = 'P0001';
        end if;
        if v_reason not in ('reception', 'adjustment', 'loss', 'return') then
          raise exception 'Motif invalide' using errcode = 'P0001';
        end if;

        update variants set stock = stock + v_delta
        where id = v_id and stock + v_delta >= 0
        returning stock, product_id into v_stock, v_product_id;

        if not found then
          raise exception 'Stock insuffisant pour ce retrait' using errcode = 'P0001';
        end if;

        insert into stock_movements (variant_id, product_id, delta, reason, note, by_email)
        values (v_id, v_product_id, v_delta, v_reason, v_note, v_email);

        return jsonb_build_object('stock', v_stock);
      end;
    end if;
  end if;

  if p_res = 'accounting' then
    declare
      v_from date := coalesce((v_query ->> 'from')::date, current_date - 29);
      v_to date := coalesce((v_query ->> 'to')::date, current_date);
      v_courier numeric := 0;
      v_sum jsonb;
      v_exp numeric := 0;
      v_profit numeric := 0;
      v_parcels int := 0;
      v_cogs numeric := 0;
      v_revenue numeric := 0;
      v_by_category jsonb;
      v_expenses jsonb;
      v_inventory jsonb;
      v_monthly jsonb;
    begin
      select coalesce((value ->> 'courierCost')::numeric, 0) into v_courier
      from settings where key = 'accounting';
      v_courier := coalesce(v_courier, 0);

      select jsonb_build_object(
        'orders', count(*) filter (where o.status not in ('cancelled','returned'))::int,
        'lost_orders', count(*) filter (where o.status in ('cancelled','returned'))::int,
        'goods', coalesce(sum(o.subtotal) filter (where o.status not in ('cancelled','returned')), 0)::float8,
        'delivery', coalesce(sum(o.delivery_fee) filter (where o.status not in ('cancelled','returned')), 0)::float8,
        'discounts', coalesce(sum(o.discount) filter (where o.status not in ('cancelled','returned')), 0)::float8,
        'revenue', coalesce(sum(o.total) filter (where o.status not in ('cancelled','returned')), 0)::float8,
        'collected', coalesce(sum(o.total) filter (where o.status not in ('cancelled','returned') and o.payment_status = 'paid'), 0)::float8,
        'to_collect', coalesce(sum(o.total) filter (where o.status not in ('cancelled','returned') and o.payment_status = 'pending'), 0)::float8,
        'refunded', coalesce(sum(o.total) filter (where o.payment_status = 'refunded'), 0)::float8,
        'cogs', coalesce(sum(
          coalesce((select sum((it ->> 'qty')::int * coalesce((it ->> 'unit_cost')::numeric, pp.cost_price, 0))
            from jsonb_array_elements(o.items) it
            left join products pp on pp.id = (it ->> 'product_id')::int), 0)
        ) filter (where o.status not in ('cancelled','returned')), 0)::float8,
        'parcels', count(*) filter (where o.status in ('shipped','delivered','returned'))::int
      ) into v_sum
      from orders o
      where o.created_at::date between v_from and v_to;

      select coalesce(sum(amount), 0)::numeric into v_exp
      from expenses where spent_at between v_from and v_to;

      select coalesce(jsonb_agg(jsonb_build_object('category', x.category, 'total', x.total) order by x.total desc), '[]'::jsonb)
      into v_by_category
      from (select category, sum(amount)::float8 as total from expenses
            where spent_at between v_from and v_to group by 1 order by 2 desc) x;

      select coalesce(jsonb_agg(jsonb_build_object(
        'id', e.id, 'label', e.label, 'category', e.category, 'amount', e.amount::float8,
        'spent_at', to_char(e.spent_at, 'YYYY-MM-DD'), 'note', e.note) order by e.spent_at desc, e.id desc), '[]'::jsonb)
      into v_expenses
      from expenses e where e.spent_at between v_from and v_to;

      select jsonb_build_object(
        'at_cost', coalesce(sum(v.stock * p.cost_price), 0)::float8,
        'at_price', coalesce(sum(v.stock * p.price), 0)::float8,
        'units', coalesce(sum(v.stock), 0)::int,
        'missing_cost', count(*) filter (where p.cost_price = 0 and v.stock > 0)::int
      ) into v_inventory
      from variants v join products p on p.id = v.product_id;

      select coalesce(jsonb_agg(jsonb_build_object(
        'month', x.month, 'revenue', x.revenue, 'net_goods', x.net_goods, 'cogs', x.cogs,
        'parcels', x.parcels, 'expenses', x.expenses, 'orders', x.orders,
        'profit', x.revenue - x.cogs - x.parcels * v_courier - x.expenses,
        'courier', x.parcels * v_courier) order by x.m desc), '[]'::jsonb)
      into v_monthly
      from (
        with months as (
          select generate_series(date_trunc('month', current_date) - interval '11 months',
                                date_trunc('month', current_date), interval '1 month') as m)
        select to_char(m, 'MM/YYYY') as month, m,
          coalesce((select sum(o.total) from orders o where o.status not in ('cancelled','returned') and date_trunc('month', o.created_at) = m), 0)::float8 as revenue,
          coalesce((select sum(o.subtotal - o.discount) from orders o where o.status not in ('cancelled','returned') and date_trunc('month', o.created_at) = m), 0)::float8 as net_goods,
          coalesce((select sum(coalesce((select sum((it ->> 'qty')::int * coalesce((it ->> 'unit_cost')::numeric, pp.cost_price, 0))
              from jsonb_array_elements(o.items) it left join products pp on pp.id = (it ->> 'product_id')::int), 0))
            from orders o where o.status not in ('cancelled','returned') and date_trunc('month', o.created_at) = m), 0)::float8 as cogs,
          coalesce((select count(*) from orders o where o.status in ('shipped','delivered','returned') and date_trunc('month', o.created_at) = m), 0)::int as parcels,
          coalesce((select sum(amount) from expenses e where date_trunc('month', e.spent_at) = m), 0)::float8 as expenses,
          coalesce((select count(*) from orders o where o.status not in ('cancelled','returned') and date_trunc('month', o.created_at) = m), 0)::int as orders
        from months) x;

      v_revenue := (v_sum ->> 'revenue')::numeric;
      v_cogs := (v_sum ->> 'cogs')::numeric;
      v_parcels := (v_sum ->> 'parcels')::int;
      v_profit := v_revenue - v_cogs - v_parcels * v_courier - v_exp;

      return jsonb_build_object(
        'from', to_char(v_from, 'YYYY-MM-DD'),
        'to', to_char(v_to, 'YYYY-MM-DD'),
        'courierCost', v_courier::float8,
        'summary', v_sum || jsonb_build_object(
          'courier', (v_parcels * v_courier)::float8,
          'expenses', v_exp::float8,
          'profit', v_profit::float8),
        'byCategory', v_by_category,
        'expenses', v_expenses,
        'inventory', v_inventory,
        'monthly', v_monthly);
    end;
  end if;

  if p_res = 'expenses' then
    if v_method = 'DELETE' and v_id is not null then
      delete from expenses where id = v_id;
      return jsonb_build_object('ok', true);
    end if;

    declare
      v_label text := btrim(coalesce(v_body ->> 'label', ''));
      v_category text := left(coalesce(v_body ->> 'category', 'autre'), 40);
      v_amount numeric := coalesce((v_body ->> 'amount')::numeric, 0);
      v_spent text := coalesce(v_body ->> 'spent_at', '');
      v_note text := left(coalesce(v_body ->> 'note', ''), 500);
      v_row jsonb;
    begin
      if length(v_label) < 2 or length(v_label) > 160 then
        raise exception 'Libellé requis' using errcode = 'P0001';
      end if;
      if v_amount < 0 then
        raise exception 'Montant invalide' using errcode = 'P0001';
      end if;
      if v_spent !~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' then
        raise exception 'Date invalide' using errcode = 'P0001';
      end if;

      if v_method = 'POST' then
        insert into expenses (label, category, amount, spent_at, note)
        values (v_label, v_category, v_amount, v_spent::date, v_note)
        returning to_jsonb(expenses) - 'created_at' into v_row;
        return jsonb_build_object('expense', v_row);
      elsif v_method = 'PUT' and v_id is not null then
        update expenses set label = v_label, category = v_category, amount = v_amount,
          spent_at = v_spent::date, note = v_note
        where id = v_id
        returning to_jsonb(expenses) - 'created_at' into v_row;
        if v_row is null then
          raise exception 'Dépense introuvable' using errcode = 'P0001';
        end if;
        return jsonb_build_object('expense', v_row);
      end if;
    end;
  end if;

  if p_res = 'products' then
    if v_method = 'GET' then
      return jsonb_build_object('products', coalesce((
        select jsonb_agg(public.product_json_admin(p) order by p.position, p.id)
        from products p), '[]'::jsonb));
    end if;

    if v_method = 'DELETE' and v_id is not null then
      delete from products where id = v_id;
      return jsonb_build_object('ok', true);
    end if;

    declare
      v_name text := btrim(coalesce(v_body ->> 'name', ''));
      v_slug text;
      v_gender text := coalesce(v_body ->> 'gender', 'unisexe');
      v_status text := coalesce(v_body ->> 'status', 'draft');
      v_pid int;
      v_vals text[];
      v_cols int[];
      v_imgs text[];
      v_tags text[];
      v_compare numeric;
      v_price numeric := coalesce((v_body ->> 'price')::numeric, 0);
      v_cost numeric := coalesce((v_body ->> 'cost_price')::numeric, 0);
    begin
      if length(v_name) < 2 or length(v_name) > 160 then
        raise exception 'Nom requis' using errcode = 'P0001';
      end if;
      if v_gender not in ('femme', 'homme', 'unisexe') then
        raise exception 'Genre invalide' using errcode = 'P0001';
      end if;
      if v_status not in ('published', 'draft', 'hidden') then
        raise exception 'Statut invalide' using errcode = 'P0001';
      end if;

      v_slug := public.slugify(coalesce(nullif(btrim(coalesce(v_body ->> 'slug', '')), ''), v_name));
      v_compare := nullif(v_body ->> 'compare_at_price', '')::numeric;
      v_cols := coalesce((select array_agg(value::int) from jsonb_array_elements_text(coalesce(v_body -> 'collection_ids', '[]'::jsonb))), '{}');
      v_imgs := coalesce((select array_agg(left(value, 500)) from jsonb_array_elements_text(coalesce(v_body -> 'images', '[]'::jsonb))), '{}');
      v_tags := coalesce((select array_agg(left(value, 40)) from jsonb_array_elements_text(coalesce(v_body -> 'tags', '[]'::jsonb))), '{}');

      if v_method = 'POST' then
        if exists (select 1 from products where slug = v_slug) then
          v_slug := v_slug || '-' || substr(md5(random()::text), 1, 4);
        end if;

        insert into products (
          name, name_ar, slug, description, description_ar, details, care, price, compare_at_price,
          category, gender, collection_ids, images, tags, status, featured, is_new, position, cost_price)
        values (
          v_name, left(coalesce(v_body ->> 'name_ar', ''), 160), v_slug,
          left(coalesce(v_body ->> 'description', ''), 4000),
          left(coalesce(v_body ->> 'description_ar', ''), 4000),
          left(coalesce(v_body ->> 'details', ''), 2000),
          left(coalesce(v_body ->> 'care', ''), 1000),
          v_price, v_compare,
          left(coalesce(v_body ->> 'category', ''), 60), v_gender,
          v_cols, v_imgs, v_tags, v_status,
          coalesce((v_body ->> 'featured')::boolean, false),
          coalesce((v_body ->> 'is_new')::boolean, false),
          coalesce((v_body ->> 'position')::int, 0), v_cost)
        returning id into v_pid;
      elsif v_method = 'PUT' and v_id is not null then
        v_pid := v_id;
        update products set
          name = v_name, name_ar = left(coalesce(v_body ->> 'name_ar', ''), 160), slug = v_slug,
          description = left(coalesce(v_body ->> 'description', ''), 4000),
          description_ar = left(coalesce(v_body ->> 'description_ar', ''), 4000),
          details = left(coalesce(v_body ->> 'details', ''), 2000),
          care = left(coalesce(v_body ->> 'care', ''), 1000),
          price = v_price, compare_at_price = v_compare,
          category = left(coalesce(v_body ->> 'category', ''), 60), gender = v_gender,
          collection_ids = v_cols, images = v_imgs, tags = v_tags, status = v_status,
          featured = coalesce((v_body ->> 'featured')::boolean, false),
          is_new = coalesce((v_body ->> 'is_new')::boolean, false),
          position = coalesce((v_body ->> 'position')::int, 0),
          cost_price = v_cost, updated_at = now()
        where id = v_pid;
        if not found then
          raise exception 'Produit introuvable' using errcode = 'P0001';
        end if;
      else
        raise exception 'Méthode non autorisée' using errcode = 'P0001';
      end if;

      perform public.save_variants(v_pid, v_body -> 'variants', v_email);

      return jsonb_build_object('product', (
        select public.product_json_admin(p) from products p where p.id = v_pid));
    end;
  end if;

  if p_res = 'collections' then
    if v_method = 'GET' then
      return jsonb_build_object('collections', coalesce((
        select jsonb_agg(to_jsonb(c) order by c.position, c.id) from collections c), '[]'::jsonb));
    end if;

    if v_method = 'DELETE' and v_id is not null then
      update products set collection_ids = array_remove(collection_ids, v_id);
      delete from collections where id = v_id;
      return jsonb_build_object('ok', true);
    end if;

    declare
      v_name text := btrim(coalesce(v_body ->> 'name', ''));
      v_slug text;
      v_row collections;
    begin
      if length(v_name) < 2 or length(v_name) > 120 then
        raise exception 'Nom requis' using errcode = 'P0001';
      end if;
      v_slug := public.slugify(coalesce(nullif(btrim(coalesce(v_body ->> 'slug', '')), ''), v_name));

      if v_method = 'POST' then
        insert into collections (slug, name, name_ar, tagline, description, image, position, visible)
        values (v_slug, v_name, left(coalesce(v_body ->> 'name_ar', ''), 120),
          left(coalesce(v_body ->> 'tagline', ''), 160),
          left(coalesce(v_body ->> 'description', ''), 2000),
          left(coalesce(v_body ->> 'image', ''), 500),
          coalesce((v_body ->> 'position')::int, 0),
          coalesce((v_body ->> 'visible')::boolean, true))
        returning * into v_row;
      elsif v_method = 'PUT' and v_id is not null then
        update collections set
          slug = v_slug, name = v_name, name_ar = left(coalesce(v_body ->> 'name_ar', ''), 120),
          tagline = left(coalesce(v_body ->> 'tagline', ''), 160),
          description = left(coalesce(v_body ->> 'description', ''), 2000),
          image = left(coalesce(v_body ->> 'image', ''), 500),
          position = coalesce((v_body ->> 'position')::int, 0),
          visible = coalesce((v_body ->> 'visible')::boolean, true)
        where id = v_id
        returning * into v_row;
        if v_row.id is null then
          raise exception 'Collection introuvable' using errcode = 'P0001';
        end if;
      else
        raise exception 'Méthode non autorisée' using errcode = 'P0001';
      end if;

      return jsonb_build_object('collection', to_jsonb(v_row));
    end;
  end if;

  if p_res = 'orders' then
    if v_method = 'GET' and v_id is null then
      declare
        v_status text := nullif(v_query ->> 'status', '');
        v_search text := nullif(btrim(coalesce(v_query ->> 'q', '')), '');
        v_orders jsonb;
      begin
        select coalesce(jsonb_agg(to_jsonb(o) order by o.created_at desc), '[]'::jsonb)
        into v_orders
        from (
          select id, number, customer_name, phone, email, governorate, city, address, notes, items,
                 subtotal::float8 as subtotal, delivery_fee::float8 as delivery_fee,
                 discount::float8 as discount, discount_code, total::float8 as total,
                 payment_method, payment_status, status, internal_note, history, created_at
          from orders
          where (v_status is null or status = v_status)
            and (v_search is null or number ilike '%' || v_search || '%'
                 or customer_name ilike '%' || v_search || '%'
                 or phone ilike '%' || v_search || '%')
          order by created_at desc
          limit 300) o;
        return jsonb_build_object('orders', v_orders);
      end;
    end if;

    if v_method = 'DELETE' and v_id is not null then
      declare
        v_number text;
      begin
        delete from orders where id = v_id returning number into v_number;
        if v_number is null then
          raise exception 'Commande introuvable' using errcode = 'P0001';
        end if;
        update stock_movements
        set note = case when note = '' then 'Commande ' || v_number || ' supprimée'
                        else note || ' · Commande ' || v_number || ' supprimée' end,
            order_id = null
        where order_id = v_id;
        return jsonb_build_object('ok', true, 'number', v_number);
      end;
    end if;

    if v_method = 'PUT' and v_id is not null then
      declare
        v_order orders;
        v_status text := nullif(v_body ->> 'status', '');
        v_payment text := nullif(v_body ->> 'payment_status', '');
        v_note text := v_body ->> 'note';
        v_internal text := v_body ->> 'internal_note';
        v_history jsonb;
        v_was_out boolean;
        v_now_out boolean;
        rec record;
      begin
        select * into v_order from orders where id = v_id for update;
        if not found then
          raise exception 'Commande introuvable' using errcode = 'P0001';
        end if;
        if v_status is not null and v_status not in ('pending','confirmed','preparing','shipped','delivered','cancelled','returned') then
          raise exception 'Statut invalide' using errcode = 'P0001';
        end if;
        if v_payment is not null and v_payment not in ('pending','paid','refunded') then
          raise exception 'Statut de paiement invalide' using errcode = 'P0001';
        end if;

        v_history := coalesce(v_order.history, '[]'::jsonb);

        if v_status is not null and v_status <> v_order.status then
          v_was_out := v_order.status in ('cancelled','returned');
          v_now_out := v_status in ('cancelled','returned');

          if not v_was_out and v_now_out then
            for rec in select value as it from jsonb_array_elements(v_order.items) loop
              update variants set stock = stock + (rec.it ->> 'qty')::int
              where id = (rec.it ->> 'variant_id')::int;
              insert into stock_movements (variant_id, product_id, delta, reason, order_id, by_email)
              values ((rec.it ->> 'variant_id')::int, (rec.it ->> 'product_id')::int,
                      (rec.it ->> 'qty')::int, v_status, v_order.id, v_email);
            end loop;
          end if;

          if v_was_out and not v_now_out then
            for rec in select value as it from jsonb_array_elements(v_order.items) loop
              update variants set stock = stock - (rec.it ->> 'qty')::int
              where id = (rec.it ->> 'variant_id')::int
                and stock >= (rec.it ->> 'qty')::int;
              if not found then
                raise exception 'Stock insuffisant pour réactiver : %', rec.it ->> 'name' using errcode = 'P0001';
              end if;
              insert into stock_movements (variant_id, product_id, delta, reason, order_id, by_email)
              values ((rec.it ->> 'variant_id')::int, (rec.it ->> 'product_id')::int,
                      -((rec.it ->> 'qty')::int), 'reactivated', v_order.id, v_email);
            end loop;
          end if;

          v_history := v_history || jsonb_build_array(jsonb_build_object(
            'status', v_status,
            'at', to_char(now() at time zone 'utc', 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"'),
            'note', coalesce(v_note, ''),
            'by', v_email));
        end if;

        update orders set
          status = coalesce(v_status, v_order.status),
          payment_status = coalesce(v_payment, v_order.payment_status),
          internal_note = coalesce(v_internal, v_order.internal_note),
          history = v_history,
          updated_at = now()
        where id = v_order.id;

        return jsonb_build_object('ok', true);
      end;
    end if;
  end if;

  if p_res = 'settings' then
    if v_method = 'GET' then
      return jsonb_build_object('settings', coalesce((
        select jsonb_object_agg(key, value) from settings), '{}'::jsonb));
    end if;
    if v_method = 'PUT' and p_id is not null and p_id = any (array['accounting','brand','announcements','hero','story','offer','shipping','contact','about','home']) then
      insert into settings (key, value, updated_at) values (p_id, v_body, now())
      on conflict (key) do update set value = excluded.value, updated_at = now();
      return jsonb_build_object('ok', true);
    end if;
  end if;

  if p_res = 'zones' then
    if v_method = 'GET' then
      return jsonb_build_object('zones', coalesce((
        select jsonb_agg(jsonb_build_object(
          'governorate', z.governorate, 'name_ar', z.name_ar, 'fee', z.fee::float8,
          'delay', z.delay, 'active', z.active) order by z.position)
        from delivery_zones z), '[]'::jsonb));
    end if;
    if v_method = 'PUT' then
      declare
        rec2 record;
      begin
        for rec2 in select value as z from jsonb_array_elements(coalesce(v_body, '[]'::jsonb)) loop
          update delivery_zones set
            fee = coalesce((rec2.z ->> 'fee')::numeric, fee),
            delay = left(coalesce(rec2.z ->> 'delay', delay), 40),
            active = coalesce((rec2.z ->> 'active')::boolean, active)
          where governorate = rec2.z ->> 'governorate';
        end loop;
        return jsonb_build_object('ok', true);
      end;
    end if;
  end if;

  if p_res = 'codes' then
    if v_method = 'GET' then
      return jsonb_build_object('codes', coalesce((
        select jsonb_agg(jsonb_build_object(
          'code', c.code, 'kind', c.kind, 'value', c.value::float8,
          'min_subtotal', c.min_subtotal::float8, 'max_uses', c.max_uses,
          'uses', c.uses, 'starts_at', c.starts_at, 'ends_at', c.ends_at, 'active', c.active)
          order by c.created_at desc)
        from discount_codes c), '[]'::jsonb));
    end if;
    if v_method = 'DELETE' and p_id is not null then
      delete from discount_codes where code = p_id;
      return jsonb_build_object('ok', true);
    end if;
    if v_method = 'POST' then
      declare
        v_code text := upper(btrim(coalesce(v_body ->> 'code', '')));
        v_kind text := coalesce(v_body ->> 'kind', 'percent');
        v_value numeric := coalesce((v_body ->> 'value')::numeric, 0);
        v_min numeric := coalesce((v_body ->> 'min_subtotal')::numeric, 0);
        v_max int := nullif(v_body ->> 'max_uses', '')::int;
        v_starts timestamptz := nullif(v_body ->> 'starts_at', '')::timestamptz;
        v_ends timestamptz := nullif(v_body ->> 'ends_at', '')::timestamptz;
      begin
        if length(v_code) < 2 or length(v_code) > 40 then
          raise exception 'Code requis' using errcode = 'P0001';
        end if;
        if v_kind not in ('percent','fixed','shipping') then
          raise exception 'Type invalide' using errcode = 'P0001';
        end if;
        if v_value < 0 or v_min < 0 then
          raise exception 'Valeur invalide' using errcode = 'P0001';
        end if;

        insert into discount_codes (code, kind, value, min_subtotal, max_uses, starts_at, ends_at, active)
        values (v_code, v_kind, v_value, v_min, v_max, v_starts, v_ends, coalesce((v_body ->> 'active')::boolean, true))
        on conflict (code) do update set
          kind = excluded.kind, value = excluded.value, min_subtotal = excluded.min_subtotal,
          max_uses = excluded.max_uses, starts_at = excluded.starts_at,
          ends_at = excluded.ends_at, active = excluded.active;
        return jsonb_build_object('ok', true);
      end;
    end if;
  end if;

  if p_res = 'reviews' then
    if v_method = 'GET' then
      return jsonb_build_object('reviews', coalesce((
        select jsonb_agg(to_jsonb(r) order by r.approved, r.created_at desc) from (
          select rr.*, p.name as product from reviews rr join products p on p.id = rr.product_id
          order by rr.approved, rr.created_at desc limit 300) r), '[]'::jsonb));
    end if;
    if v_method = 'PUT' and v_id is not null then
      update reviews set approved = coalesce((v_body ->> 'approved')::boolean, false) where id = v_id;
      return jsonb_build_object('ok', true);
    end if;
    if v_method = 'DELETE' and v_id is not null then
      delete from reviews where id = v_id;
      return jsonb_build_object('ok', true);
    end if;
  end if;

  if p_res = 'messages' then
    if v_method = 'GET' then
      return jsonb_build_object('messages', coalesce((
        select jsonb_agg(to_jsonb(m) order by m.created_at desc) from (
          select * from messages order by created_at desc limit 300) m), '[]'::jsonb));
    end if;
    if v_method = 'PUT' and v_id is not null then
      update messages set read = true where id = v_id;
      return jsonb_build_object('ok', true);
    end if;
    if v_method = 'DELETE' and v_id is not null then
      delete from messages where id = v_id;
      return jsonb_build_object('ok', true);
    end if;
  end if;

  if p_res = 'subscribers' then
    if v_method = 'GET' then
      return jsonb_build_object('subscribers', coalesce((
        select jsonb_agg(jsonb_build_object('email', s.email, 'created_at', s.created_at)
          order by s.created_at desc) from subscribers s), '[]'::jsonb));
    end if;
  end if;

  raise exception 'Route inconnue' using errcode = 'P0001';
end;
$$;

-- ---------------------------------------------------------------------------
-- Dispatcher: the only function the website calls
-- ---------------------------------------------------------------------------

create or replace function public.api(
  p_path text,
  p_method text default 'GET',
  p_query jsonb default '{}'::jsonb,
  p_body jsonb default '{}'::jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_path text := regexp_replace(coalesce(p_path, ''), '^/api/?', '');
  v_method text := upper(coalesce(p_method, 'GET'));
  v_query jsonb := coalesce(p_query, '{}'::jsonb);
  v_body jsonb := coalesce(p_body, '{}'::jsonb);
  v_parts text[];
  v_rest text;
begin
  if v_path = 'store' and v_method = 'GET' then
    return public.store_data();
  end if;

  if v_path = 'products' and v_method = 'GET' then
    return public.product_list();
  end if;

  if v_path like 'products/%' and v_method = 'GET' then
    return public.product_get(replace(v_path, 'products/', ''));
  end if;

  if v_path = 'orders/quote' and v_method = 'POST' then
    return public.order_quote(v_body);
  end if;

  if v_path = 'orders' and v_method = 'POST' then
    return public.order_create(v_body, public.client_ip());
  end if;

  if v_path = 'orders' and v_method = 'GET' then
    return public.my_orders();
  end if;

  if v_path like 'orders/%' and v_method = 'GET' then
    return public.order_track(replace(v_path, 'orders/', ''), v_query ->> 'phone');
  end if;

  -- Favorites: account only (see 04-accounts.sql).
  if v_path = 'wishlist' and v_method = 'GET' then
    return public.wish_list();
  end if;

  if v_path = 'wishlist' and v_method = 'POST' then
    return public.wish_toggle((v_body ->> 'productId')::int);
  end if;

  if v_path in ('contact', 'reviews', 'newsletter') and v_method = 'POST' then
    return public.submit_form(v_path, v_body);
  end if;

  if v_path like 'admin/%' then
    v_rest := substr(v_path, 7);
    v_parts := string_to_array(v_rest, '/');
    return public.admin_api(
      v_parts[1],
      case when array_length(v_parts, 1) > 1 then v_parts[2] end,
      v_method, v_query, v_body);
  end if;

  raise exception 'Route inconnue' using errcode = 'P0001';
end;
$$;

-- ---------------------------------------------------------------------------
-- Permissions: the public site may only call public.api()
-- Everything else is internal.
-- ---------------------------------------------------------------------------

revoke all on function public.api(text, text, jsonb, jsonb) from public;
grant execute on function public.api(text, text, jsonb, jsonb) to anon, authenticated;

-- Supabase also grants EXECUTE on new functions directly to anon and
-- authenticated, so revoking from "public" alone is not enough: every
-- internal function must be revoked from all three roles explicitly.
-- handle_new_user() and the wishlist helpers are revoked again in 03 and 04
-- right after their creation; they are listed here too so this file also
-- protects an existing database when it is re-run on its own.
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
        'admin_api','is_admin','slugify','client_ip','product_json',
        'product_json_admin','order_public_json',
        'handle_new_user','wish_list','wish_toggle')
  loop
    execute format('revoke all on function %s from public, anon, authenticated', f.sig);
  end loop;
end $$;

-- Storage policies in 03 call public.is_admin(): RLS runs as the caller's
-- role, so authenticated needs EXECUTE on that single helper.
grant execute on function public.is_admin() to authenticated;
