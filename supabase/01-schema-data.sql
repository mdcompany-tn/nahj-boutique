-- ============================================================================
-- NAHJ Boutique — schema + data for Supabase
-- Generated from the Netlify database export (2026-11-05).
-- Run this ONCE in an EMPTY Supabase project (SQL Editor).
-- If the tables already exist, run 02-api.sql and 03-auth-storage.sql instead.
-- ============================================================================

-- PostgreSQL schema dump
-- Database : netlifydb
-- Exported : 2026-11-05T06:26:26.166Z
-- Server   : PostgreSQL 18.6

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

CREATE SCHEMA IF NOT EXISTS "public";

CREATE SEQUENCE IF NOT EXISTS "public"."collections_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    MINVALUE 1
    MAXVALUE 2147483647
    CACHE 1 NO CYCLE;

CREATE SEQUENCE IF NOT EXISTS "public"."expenses_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    MINVALUE 1
    MAXVALUE 2147483647
    CACHE 1 NO CYCLE;

CREATE SEQUENCE IF NOT EXISTS "public"."messages_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    MINVALUE 1
    MAXVALUE 2147483647
    CACHE 1 NO CYCLE;

CREATE SEQUENCE IF NOT EXISTS "public"."order_number_seq"
    AS bigint
    START WITH 1001
    INCREMENT BY 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    CACHE 1 NO CYCLE;

CREATE SEQUENCE IF NOT EXISTS "public"."orders_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    MINVALUE 1
    MAXVALUE 2147483647
    CACHE 1 NO CYCLE;

CREATE SEQUENCE IF NOT EXISTS "public"."products_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    MINVALUE 1
    MAXVALUE 2147483647
    CACHE 1 NO CYCLE;

CREATE SEQUENCE IF NOT EXISTS "public"."reviews_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    MINVALUE 1
    MAXVALUE 2147483647
    CACHE 1 NO CYCLE;

CREATE SEQUENCE IF NOT EXISTS "public"."stock_movements_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    MINVALUE 1
    MAXVALUE 2147483647
    CACHE 1 NO CYCLE;

CREATE SEQUENCE IF NOT EXISTS "public"."subscribers_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    MINVALUE 1
    MAXVALUE 2147483647
    CACHE 1 NO CYCLE;

CREATE SEQUENCE IF NOT EXISTS "public"."variants_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    MINVALUE 1
    MAXVALUE 2147483647
    CACHE 1 NO CYCLE;

CREATE TABLE "public"."admins" (
    "user_id" text NOT NULL,
    "email" text NOT NULL,
    "is_owner" boolean DEFAULT false NOT NULL,
    "created_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE "public"."collections" (
    "id" integer DEFAULT nextval('collections_id_seq'::regclass) NOT NULL,
    "slug" text NOT NULL,
    "name" text NOT NULL,
    "name_ar" text DEFAULT ''::text NOT NULL,
    "tagline" text DEFAULT ''::text NOT NULL,
    "description" text DEFAULT ''::text NOT NULL,
    "image" text DEFAULT ''::text NOT NULL,
    "position" integer DEFAULT 0 NOT NULL,
    "visible" boolean DEFAULT true NOT NULL,
    "created_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE "public"."delivery_zones" (
    "governorate" text NOT NULL,
    "name_ar" text DEFAULT ''::text NOT NULL,
    "fee" numeric(10,3) DEFAULT 8 NOT NULL,
    "delay" text DEFAULT '48-72h'::text NOT NULL,
    "active" boolean DEFAULT true NOT NULL,
    "position" integer DEFAULT 0 NOT NULL
);

CREATE TABLE "public"."discount_codes" (
    "code" text NOT NULL,
    "kind" text DEFAULT 'percent'::text NOT NULL,
    "value" numeric(10,3) DEFAULT 0 NOT NULL,
    "min_subtotal" numeric(10,3) DEFAULT 0 NOT NULL,
    "max_uses" integer,
    "uses" integer DEFAULT 0 NOT NULL,
    "starts_at" timestamp with time zone,
    "ends_at" timestamp with time zone,
    "active" boolean DEFAULT true NOT NULL,
    "created_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE "public"."expenses" (
    "id" integer DEFAULT nextval('expenses_id_seq'::regclass) NOT NULL,
    "label" text NOT NULL,
    "category" text DEFAULT 'autre'::text NOT NULL,
    "amount" numeric(10,3) NOT NULL,
    "spent_at" date DEFAULT CURRENT_DATE NOT NULL,
    "note" text DEFAULT ''::text NOT NULL,
    "created_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE "public"."messages" (
    "id" integer DEFAULT nextval('messages_id_seq'::regclass) NOT NULL,
    "name" text NOT NULL,
    "email" text DEFAULT ''::text NOT NULL,
    "phone" text DEFAULT ''::text NOT NULL,
    "subject" text DEFAULT ''::text NOT NULL,
    "body" text NOT NULL,
    "read" boolean DEFAULT false NOT NULL,
    "created_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE "public"."orders" (
    "id" integer DEFAULT nextval('orders_id_seq'::regclass) NOT NULL,
    "number" text NOT NULL,
    "customer_name" text NOT NULL,
    "phone" text NOT NULL,
    "email" text DEFAULT ''::text NOT NULL,
    "governorate" text NOT NULL,
    "city" text DEFAULT ''::text NOT NULL,
    "address" text NOT NULL,
    "notes" text DEFAULT ''::text NOT NULL,
    "items" jsonb NOT NULL,
    "subtotal" numeric(10,3) NOT NULL,
    "delivery_fee" numeric(10,3) DEFAULT 0 NOT NULL,
    "discount" numeric(10,3) DEFAULT 0 NOT NULL,
    "discount_code" text,
    "total" numeric(10,3) NOT NULL,
    "payment_method" text DEFAULT 'cod'::text NOT NULL,
    "payment_status" text DEFAULT 'pending'::text NOT NULL,
    "status" text DEFAULT 'pending'::text NOT NULL,
    "internal_note" text DEFAULT ''::text NOT NULL,
    "user_id" text,
    "history" jsonb DEFAULT '[]'::jsonb NOT NULL,
    "created_at" timestamp with time zone DEFAULT now() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
    "client_ip" text DEFAULT ''::text NOT NULL
);

CREATE TABLE "public"."products" (
    "id" integer DEFAULT nextval('products_id_seq'::regclass) NOT NULL,
    "slug" text NOT NULL,
    "name" text NOT NULL,
    "name_ar" text DEFAULT ''::text NOT NULL,
    "description" text DEFAULT ''::text NOT NULL,
    "description_ar" text DEFAULT ''::text NOT NULL,
    "details" text DEFAULT ''::text NOT NULL,
    "care" text DEFAULT ''::text NOT NULL,
    "price" numeric(10,3) NOT NULL,
    "compare_at_price" numeric(10,3),
    "category" text DEFAULT ''::text NOT NULL,
    "gender" text DEFAULT 'unisexe'::text NOT NULL,
    "collection_ids" integer[] DEFAULT '{}'::integer[] NOT NULL,
    "images" text[] DEFAULT '{}'::text[] NOT NULL,
    "tags" text[] DEFAULT '{}'::text[] NOT NULL,
    "status" text DEFAULT 'draft'::text NOT NULL,
    "featured" boolean DEFAULT false NOT NULL,
    "is_new" boolean DEFAULT false NOT NULL,
    "position" integer DEFAULT 0 NOT NULL,
    "created_at" timestamp with time zone DEFAULT now() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
    "cost_price" numeric(10,3) DEFAULT 0 NOT NULL
);

CREATE TABLE "public"."reviews" (
    "id" integer DEFAULT nextval('reviews_id_seq'::regclass) NOT NULL,
    "product_id" integer NOT NULL,
    "name" text NOT NULL,
    "rating" integer NOT NULL,
    "body" text DEFAULT ''::text NOT NULL,
    "approved" boolean DEFAULT false NOT NULL,
    "created_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE "public"."settings" (
    "key" text NOT NULL,
    "value" jsonb NOT NULL,
    "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE "public"."stock_movements" (
    "id" integer DEFAULT nextval('stock_movements_id_seq'::regclass) NOT NULL,
    "variant_id" integer,
    "product_id" integer,
    "delta" integer NOT NULL,
    "reason" text NOT NULL,
    "order_id" integer,
    "created_at" timestamp with time zone DEFAULT now() NOT NULL,
    "note" text DEFAULT ''::text NOT NULL,
    "by_email" text DEFAULT ''::text NOT NULL
);

CREATE TABLE "public"."subscribers" (
    "id" integer DEFAULT nextval('subscribers_id_seq'::regclass) NOT NULL,
    "email" text NOT NULL,
    "created_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE "public"."variants" (
    "id" integer DEFAULT nextval('variants_id_seq'::regclass) NOT NULL,
    "product_id" integer NOT NULL,
    "size" text DEFAULT 'Unique'::text NOT NULL,
    "color" text DEFAULT ''::text NOT NULL,
    "color_hex" text DEFAULT ''::text NOT NULL,
    "sku" text DEFAULT ''::text NOT NULL,
    "stock" integer DEFAULT 0 NOT NULL,
    "position" integer DEFAULT 0 NOT NULL,
    "image" text DEFAULT ''::text NOT NULL
);

-- PostgreSQL data dump (INSERT statements)
-- Database : netlifydb
-- Exported : 2026-11-05T06:26:26.166Z

SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET client_min_messages = warning;

-- public.collections: 4 row(s)
INSERT INTO "public"."collections" ("id", "slug", "name", "name_ar", "tagline", "description", "image", "position", "visible", "created_at") VALUES ('1', 'nouvelle-collection', 'Nouvelle Collection', 'المجموعة الجديدة', 'Nahj el Jedid', 'Les dernières pièces sorties de l’atelier : lin brut, indigo profond et coupes amples.', '/img/col-nouvelle.jpg', '1', 'true', '2026-11-04 23:17:04.076948+00');
INSERT INTO "public"."collections" ("id", "slug", "name", "name_ar", "tagline", "description", "image", "position", "visible", "created_at") VALUES ('2', 'ete-sidi-bou', 'Été à Sidi Bou', 'صيف سيدي بوسعيد', 'Nahj Sidi Bou Saïd', 'Blanc chaux, bleu des portes, lumière de fin d’après-midi. La garde-robe des terrasses.', '/img/col-ete.jpg', '2', 'true', '2026-11-04 23:17:04.076948+00');
INSERT INTO "public"."collections" ("id", "slug", "name", "name_ar", "tagline", "description", "image", "position", "visible", "created_at") VALUES ('3', 'edition-limitee', 'Édition Limitée', 'إصدار محدود', 'Nahj el Medina', 'Des séries numérotées brodées à la main. Quand c’est parti, c’est parti.', '/img/col-limitee.jpg', '3', 'true', '2026-11-04 23:17:04.076948+00');
INSERT INTO "public"."collections" ("id", "slug", "name", "name_ar", "tagline", "description", "image", "position", "visible", "created_at") VALUES ('4', 'exclusivites', 'Exclusivités', 'حصريات', 'Nahj el Bahr', 'Des pièces que vous ne trouverez qu’ici, en ligne et en quantité restreinte.', '/img/col-exclusive.jpg', '4', 'true', '2026-11-04 23:17:04.076948+00');

-- public.delivery_zones: 24 row(s)
INSERT INTO "public"."delivery_zones" ("governorate", "name_ar", "fee", "delay", "active", "position") VALUES ('Tunis', 'تونس', '7.000', '24-48h', 'true', '1');
INSERT INTO "public"."delivery_zones" ("governorate", "name_ar", "fee", "delay", "active", "position") VALUES ('Ariana', 'أريانة', '7.000', '24-48h', 'true', '2');
INSERT INTO "public"."delivery_zones" ("governorate", "name_ar", "fee", "delay", "active", "position") VALUES ('Ben Arous', 'بن عروس', '7.000', '24-48h', 'true', '3');
INSERT INTO "public"."delivery_zones" ("governorate", "name_ar", "fee", "delay", "active", "position") VALUES ('Manouba', 'منوبة', '7.000', '24-48h', 'true', '4');
INSERT INTO "public"."delivery_zones" ("governorate", "name_ar", "fee", "delay", "active", "position") VALUES ('Nabeul', 'نابل', '8.000', '48h', 'true', '5');
INSERT INTO "public"."delivery_zones" ("governorate", "name_ar", "fee", "delay", "active", "position") VALUES ('Zaghouan', 'زغوان', '8.000', '48h', 'true', '6');
INSERT INTO "public"."delivery_zones" ("governorate", "name_ar", "fee", "delay", "active", "position") VALUES ('Bizerte', 'بنزرت', '8.000', '48h', 'true', '7');
INSERT INTO "public"."delivery_zones" ("governorate", "name_ar", "fee", "delay", "active", "position") VALUES ('Béja', 'باجة', '9.000', '48-72h', 'true', '8');
INSERT INTO "public"."delivery_zones" ("governorate", "name_ar", "fee", "delay", "active", "position") VALUES ('Jendouba', 'جندوبة', '9.000', '48-72h', 'true', '9');
INSERT INTO "public"."delivery_zones" ("governorate", "name_ar", "fee", "delay", "active", "position") VALUES ('Le Kef', 'الكاف', '9.000', '48-72h', 'true', '10');
INSERT INTO "public"."delivery_zones" ("governorate", "name_ar", "fee", "delay", "active", "position") VALUES ('Siliana', 'سليانة', '9.000', '48-72h', 'true', '11');
INSERT INTO "public"."delivery_zones" ("governorate", "name_ar", "fee", "delay", "active", "position") VALUES ('Sousse', 'سوسة', '8.000', '48h', 'true', '12');
INSERT INTO "public"."delivery_zones" ("governorate", "name_ar", "fee", "delay", "active", "position") VALUES ('Monastir', 'المنستير', '8.000', '48h', 'true', '13');
INSERT INTO "public"."delivery_zones" ("governorate", "name_ar", "fee", "delay", "active", "position") VALUES ('Mahdia', 'المهدية', '8.000', '48-72h', 'true', '14');
INSERT INTO "public"."delivery_zones" ("governorate", "name_ar", "fee", "delay", "active", "position") VALUES ('Sfax', 'صفاقس', '8.000', '48h', 'true', '15');
INSERT INTO "public"."delivery_zones" ("governorate", "name_ar", "fee", "delay", "active", "position") VALUES ('Kairouan', 'القيروان', '9.000', '48-72h', 'true', '16');
INSERT INTO "public"."delivery_zones" ("governorate", "name_ar", "fee", "delay", "active", "position") VALUES ('Kasserine', 'القصرين', '10.000', '72h', 'true', '17');
INSERT INTO "public"."delivery_zones" ("governorate", "name_ar", "fee", "delay", "active", "position") VALUES ('Sidi Bouzid', 'سيدي بوزيد', '10.000', '72h', 'true', '18');
INSERT INTO "public"."delivery_zones" ("governorate", "name_ar", "fee", "delay", "active", "position") VALUES ('Gabès', 'قابس', '9.000', '48-72h', 'true', '19');
INSERT INTO "public"."delivery_zones" ("governorate", "name_ar", "fee", "delay", "active", "position") VALUES ('Médenine', 'مدنين', '10.000', '72h', 'true', '20');
INSERT INTO "public"."delivery_zones" ("governorate", "name_ar", "fee", "delay", "active", "position") VALUES ('Tataouine', 'تطاوين', '10.000', '72h', 'true', '21');
INSERT INTO "public"."delivery_zones" ("governorate", "name_ar", "fee", "delay", "active", "position") VALUES ('Gafsa', 'قفصة', '10.000', '72h', 'true', '22');
INSERT INTO "public"."delivery_zones" ("governorate", "name_ar", "fee", "delay", "active", "position") VALUES ('Tozeur', 'توزر', '10.000', '72h', 'true', '23');
INSERT INTO "public"."delivery_zones" ("governorate", "name_ar", "fee", "delay", "active", "position") VALUES ('Kébili', 'قبلي', '10.000', '72h', 'true', '24');

-- public.discount_codes: 1 row(s)
INSERT INTO "public"."discount_codes" ("code", "kind", "value", "min_subtotal", "max_uses", "uses", "starts_at", "ends_at", "active", "created_at") VALUES ('BIENVENUE', 'percent', '10.000', '0.000', NULL, '0', NULL, NULL, 'true', '2026-11-04 23:17:04.076948+00');

-- public.expenses: 0 row(s)

-- public.messages: 0 row(s)

-- public.orders: 0 row(s)

-- public.products: 12 row(s)
INSERT INTO "public"."products" ("id", "slug", "name", "name_ar", "description", "description_ar", "details", "care", "price", "compare_at_price", "category", "gender", "collection_ids", "images", "tags", "status", "featured", "is_new", "position", "created_at", "updated_at", "cost_price") VALUES ('1', 'jebba-bhar', 'Surchemise Jebba Bhar', 'قميص جبّة البحر', 'Une jebba repensée en surchemise : col officier, lin lavé et galons brodés ton sur ton qui courent le long de la patte.', '', 'Lin et coton 70/30 — Broderie mécanique ton sur ton — Coupe ample', 'Lavage à 30°, séchage à plat', '289.000', NULL, 'Chemises', 'homme', '{1,3}', '{/img/p-jebba.jpg}', '{lin,broderie}', 'published', 'true', 'true', '1', '2026-11-04 23:17:04.076948+00', '2026-11-04 23:17:04.076948+00', '0.000');
INSERT INTO "public"."products" ("id", "slug", "name", "name_ar", "description", "description_ar", "details", "care", "price", "compare_at_price", "category", "gender", "collection_ids", "images", "tags", "status", "featured", "is_new", "position", "created_at", "updated_at", "cost_price") VALUES ('3', 'hoodie-el-jamal', 'Hoodie El Jamal', 'هودي الجمال', 'Molleton épais 420 g, coupe boxy et calligraphie « الاستقامة والجمال » brodée sur le cœur.', '', 'Coton bio 420 g/m² — Broderie calligraphique — Coupe boxy', 'Lavage à 30° à l’envers', '189.000', NULL, 'Sweats', 'unisexe', '{1}', '{/img/p-hoodie.jpg,/img/p-hoodie-2.jpg}', '{streetwear}', 'published', 'true', 'true', '3', '2026-11-04 23:17:04.076948+00', '2026-11-04 23:17:04.076948+00', '0.000');
INSERT INTO "public"."products" ("id", "slug", "name", "name_ar", "description", "description_ar", "details", "care", "price", "compare_at_price", "category", "gender", "collection_ids", "images", "tags", "status", "featured", "is_new", "position", "created_at", "updated_at", "cost_price") VALUES ('4', 'chemise-la-goulette', 'Chemise Rayée La Goulette', 'قميص حلق الوادي المخطط', 'Chemise à col cubain et manches courtes, fines rayures marine sur fond blanc, poche poitrine. La chemise des dîners de poisson à La Goulette.', '', 'Coton et lin — Col cubain — Manches courtes', 'Lavage à 30°, repassage léger', '159.000', NULL, 'Chemises', 'homme', '{2}', '{/img/p-chemise.jpg}', '{lin}', 'published', 'false', 'false', '4', '2026-11-04 23:17:04.076948+00', '2026-11-04 23:17:04.076948+00', '0.000');
INSERT INTO "public"."products" ("id", "slug", "name", "name_ar", "description", "description_ar", "details", "care", "price", "compare_at_price", "category", "gender", "collection_ids", "images", "tags", "status", "featured", "is_new", "position", "created_at", "updated_at", "cost_price") VALUES ('5', 'chemise-kerkennah', 'Chemise Rayures Kerkennah', 'قميص قرقنة المخطط', 'Rayures irrégulières tissées comme les voiles de felouque de Kerkennah. Col cubain, manches longues à retrousser.', '', 'Lin et coton — Col cubain — Boutons nacre', 'Lavage à 30°', '169.000', '199.000', 'Chemises', 'homme', '{2,4}', '{/img/p-chemise-2.jpg}', '{lin,rayures}', 'published', 'true', 'false', '5', '2026-11-04 23:17:04.076948+00', '2026-11-04 23:17:04.076948+00', '0.000');
INSERT INTO "public"."products" ("id", "slug", "name", "name_ar", "description", "description_ar", "details", "care", "price", "compare_at_price", "category", "gender", "collection_ids", "images", "tags", "status", "featured", "is_new", "position", "created_at", "updated_at", "cost_price") VALUES ('6', 'robe-yasmine', 'Robe Yasmine', 'فستان ياسمين', 'Robe nuisette longue en lin blanc, ourlet festonné et brodé de fleurs de jasmin.', '', 'Lin 100% — Broderie anglaise — Bretelles fines', 'Lavage délicat à 30°', '259.000', NULL, 'Robes', 'femme', '{2,3}', '{/img/p-robe.jpg}', '{lin,broderie}', 'published', 'true', 'true', '6', '2026-11-04 23:17:04.076948+00', '2026-11-04 23:17:04.076948+00', '0.000');
INSERT INTO "public"."products" ("id", "slug", "name", "name_ar", "description", "description_ar", "details", "care", "price", "compare_at_price", "category", "gender", "collection_ids", "images", "tags", "status", "featured", "is_new", "position", "created_at", "updated_at", "cost_price") VALUES ('7', 'pantalon-medina', 'Pantalon Plissé Médina', 'سروال المدينة', 'Pantalon large en lin écru, double pince et cordon de serrage. Aussi juste en ville qu’au bord de l’eau.', '', 'Lin lourd — Double pince — Jambe large', 'Lavage à 30°', '179.000', NULL, 'Pantalons', 'unisexe', '{2}', '{/img/p-pantalon.jpg}', '{lin}', 'published', 'false', 'false', '7', '2026-11-04 23:17:04.076948+00', '2026-11-04 23:17:04.076948+00', '0.000');
INSERT INTO "public"."products" ("id", "slug", "name", "name_ar", "description", "description_ar", "details", "care", "price", "compare_at_price", "category", "gender", "collection_ids", "images", "tags", "status", "featured", "is_new", "position", "created_at", "updated_at", "cost_price") VALUES ('8', 'tshirt-arche', 'T-shirt Arche', 'تيشرت القوس', 'Le t-shirt signature : coton épais écru et une arche de Sidi Bou Saïd tracée à l’encre indigo.', '', 'Coton 240 g — Sérigraphie à l’eau — Coupe oversize', 'Lavage à 30° à l’envers', '79.000', NULL, 'T-shirts', 'unisexe', '{1}', '{/img/p-tshirt.jpg}', '{streetwear}', 'published', 'false', 'true', '8', '2026-11-04 23:17:04.076948+00', '2026-11-04 23:17:04.076948+00', '0.000');
INSERT INTO "public"."products" ("id", "slug", "name", "name_ar", "description", "description_ar", "details", "care", "price", "compare_at_price", "category", "gender", "collection_ids", "images", "tags", "status", "featured", "is_new", "position", "created_at", "updated_at", "cost_price") VALUES ('9', 'bob-sidi-bou', 'Bob Lin Sidi Bou', 'قبعة سيدي بوسعيد', 'Le bob des après-midis au café des Délices : lin naturel surpiqué, galon indigo brodé au point sellier.', '', 'Lin naturel — Galon indigo — Taille unique', 'Lavage à la main', '59.000', '75.000', 'Accessoires', 'unisexe', '{2}', '{/img/p-bob.jpg}', '{ete}', 'published', 'false', 'false', '9', '2026-11-04 23:17:04.076948+00', '2026-11-04 23:17:04.076948+00', '0.000');
INSERT INTO "public"."products" ("id", "slug", "name", "name_ar", "description", "description_ar", "details", "care", "price", "compare_at_price", "category", "gender", "collection_ids", "images", "tags", "status", "featured", "is_new", "position", "created_at", "updated_at", "cost_price") VALUES ('10', 'casquette-chechia', 'Casquette Chéchia', 'قبعة الشاشية', 'Le rouge et le gland noir de la chéchia tunisienne, transposés sur une casquette en feutre de laine.', '', 'Feutre de laine — Gland en soie — Fermoir laiton', 'Brosser, ne pas laver', '55.000', '69.000', 'Accessoires', 'unisexe', '{2}', '{/img/p-casquette.jpg}', '{ete}', 'published', 'false', 'false', '10', '2026-11-04 23:17:04.076948+00', '2026-11-04 23:17:04.076948+00', '0.000');
INSERT INTO "public"."products" ("id", "slug", "name", "name_ar", "description", "description_ar", "details", "care", "price", "compare_at_price", "category", "gender", "collection_ids", "images", "tags", "status", "featured", "is_new", "position", "created_at", "updated_at", "cost_price") VALUES ('11', 'cabas-halfa', 'Cabas Halfa', 'قفة الحلفاء', 'Le couffin tunisien tressé en halfa par des artisanes de Kasserine, anses en cuir.', '', 'Halfa tressé main — Anses cuir — 45 × 35 cm', 'Brosser à sec', '89.000', NULL, 'Accessoires', 'femme', '{3,4}', '{/img/p-cabas.jpg}', '{artisanat}', 'published', 'true', 'false', '11', '2026-11-04 23:17:04.076948+00', '2026-11-04 23:17:04.076948+00', '0.000');
INSERT INTO "public"."products" ("id", "slug", "name", "name_ar", "description", "description_ar", "details", "care", "price", "compare_at_price", "category", "gender", "collection_ids", "images", "tags", "status", "featured", "is_new", "position", "created_at", "updated_at", "cost_price") VALUES ('12', 'sandales-nabeul', 'Sandales Cuir Nabeul', 'صندل نابل الجلدي', 'Sandales plates en cuir tanné végétal, cousues à Nabeul.', '', 'Cuir tanné végétal — Semelle cuir — Fabriqué à Nabeul', 'Nourrir le cuir régulièrement', '149.000', NULL, 'Chaussures', 'femme', '{2,4}', '{/img/p-sandales.jpg}', '{cuir,artisanat}', 'published', 'false', 'true', '12', '2026-11-04 23:17:04.076948+00', '2026-11-04 23:17:04.076948+00', '0.000');
INSERT INTO "public"."products" ("id", "slug", "name", "name_ar", "description", "description_ar", "details", "care", "price", "compare_at_price", "category", "gender", "collection_ids", "images", "tags", "status", "featured", "is_new", "position", "created_at", "updated_at", "cost_price") VALUES ('2', 'veste-bab-bhar', 'Veste de travail Bab Bhar', 'سترة باب بحر', 'La veste de chantier des artisans de la médina, en denim indigo 13 oz, avec quatre poches plaquées et boutons en laiton.', '', 'Denim 100% coton 13 oz — Teinture indigo — Boutons laiton', 'Laver à l’envers, à froid', '349.000', NULL, 'Vestes', 'unisexe', '{1,4}', '{/img/p-veste.jpg}', '{denim,indigo}', 'published', 'true', 'true', '2', '2026-11-04 23:17:04.076948+00', '2026-11-05 01:41:30.229407+00', '0.000');

-- public.reviews: 0 row(s)

-- public.settings: 10 row(s)
INSERT INTO "public"."settings" ("key", "value", "updated_at") VALUES ('brand', '{"name": "NAHJ", "fonts": "bodoni", "colors": {"ink": "#14224A", "lime": "#F1ECE2", "sand": "#E3D6BF", "brass": "#B08A4E", "henna": "#9C3B26"}, "nameAr": "نهج", "tagline": "Maison de vêtements contemporains — Tunis", "logoImage": ""}', '2026-11-04 23:17:04.076948+00');
INSERT INTO "public"."settings" ("key", "value", "updated_at") VALUES ('announcements', '[{"id": "a1", "link": "/shop", "text": "Livraison offerte dès 250 DT partout en Tunisie", "active": true, "textAr": "توصيل مجاني ابتداءً من 250 د.ت في كامل تونس"}, {"id": "a2", "link": "", "text": "Paiement à la livraison — 24 gouvernorats", "active": true, "textAr": "الدفع عند الاستلام — 24 ولاية"}, {"id": "a3", "link": "/offers", "text": "Code BIENVENUE : -10% sur votre première commande", "active": true, "textAr": "رمز BIENVENUE : تخفيض 10% على طلبك الأول"}]', '2026-11-04 23:17:04.076948+00');
INSERT INTO "public"."settings" ("key", "value", "updated_at") VALUES ('hero', '{"image": "/img/hero.jpg", "title": "La rue est notre atelier.", "video": "", "eyebrow": "Collection Été 26 — Sidi Bou Saïd", "titleAr": "الشارع ورشتنا.", "subtitle": "Lin lavé à la chaux, indigo de Bab Bhar et broderies de la médina. Des pièces pensées à Tunis pour vivre dehors.", "subtitleAr": "كتان، نيلة وتطريز المدينة. قطع صُمّمت في تونس لتعيش في الخارج.", "primaryLink": "/shop", "primaryLabel": "Découvrir la boutique", "secondaryLink": "/collections", "secondaryLabel": "Explorer les collections"}', '2026-11-04 23:17:04.076948+00');
INSERT INTO "public"."settings" ("key", "value", "updated_at") VALUES ('story', '{"body": "Nahj, c’est le mot qu’on lit sur chaque plaque émaillée de Tunis. Nous dessinons pour ces rues-là : des coupes nettes, des matières naturelles, des détails empruntés aux portes cloutées, au halfa tressé et aux jebbas de nos grands-pères. Chaque pièce est produite en petites séries avec des ateliers de Ksar Hellal, Nabeul et Tunis.", "image": "/img/story.jpg", "stats": [{"label": "fabriqué en Tunisie", "value": "100%"}, {"label": "ateliers partenaires", "value": "3"}, {"label": "gouvernorats livrés", "value": "24"}], "title": "Un nom de rue, une façon de s’habiller.", "image2": "/img/story-2.jpg"}', '2026-11-04 23:17:04.076948+00');
INSERT INTO "public"."settings" ("key", "value", "updated_at") VALUES ('offer', '{"body": "Une sélection de chemises, bobs et accessoires à prix doux, tant que le stock dure.", "link": "/offers", "image": "/img/col-ete.jpg", "label": "Voir les offres", "title": "Jusqu’à -25% sur les pièces d’été", "active": true, "eyebrow": "Offre de saison"}', '2026-11-04 23:17:04.076948+00');
INSERT INTO "public"."settings" ("key", "value", "updated_at") VALUES ('shipping', '{"note": "Paiement en espèces à la livraison. Un conseiller vous appelle pour confirmer la commande.", "codEnabled": true, "freeThreshold": 250}', '2026-11-04 23:17:04.076948+00');
INSERT INTO "public"."settings" ("key", "value", "updated_at") VALUES ('contact', '{"email": "bonjour@nahj.tn", "hours": "Lun – Sam, 9h – 19h", "phone": "+216 00 000 000", "tiktok": "", "address": "Tunis, Tunisie", "facebook": "", "whatsapp": "", "instagram": ""}', '2026-11-04 23:17:04.076948+00');
INSERT INTO "public"."settings" ("key", "value", "updated_at") VALUES ('about', '{"body": "Nous travaillons le lin, le coton lourd et le denim avec des ateliers tunisiens que nous connaissons par leur prénom. Nos séries restent courtes pour éviter les invendus. Chaque collection porte le nom d’une rue, d’un quartier ou d’un souvenir.", "image": "/img/story-2.jpg", "intro": "NAHJ est une maison tunisienne de vêtements contemporains. Nous croyons qu’un vêtement peut porter un lieu : la lumière de Sidi Bou Saïd, la rigueur du tailleur de la rue des Teinturiers, l’énergie des terrasses de La Marsa.", "title": "Une maison née dans la médina"}', '2026-11-04 23:17:04.076948+00');
INSERT INTO "public"."settings" ("key", "value", "updated_at") VALUES ('home', '{"showNew": true, "showBest": true, "showOffer": true, "showStory": true, "featuredIds": [], "showNewsletter": true}', '2026-11-04 23:17:04.076948+00');
INSERT INTO "public"."settings" ("key", "value", "updated_at") VALUES ('accounting', '{"lowStock": 3, "courierCost": 0}', '2026-11-05 01:08:54.530516+00');

-- public.stock_movements: 12 row(s)
INSERT INTO "public"."stock_movements" ("id", "variant_id", "product_id", "delta", "reason", "order_id", "created_at", "note", "by_email") VALUES ('5', '1', '1', '4', 'reception', NULL, '2026-11-05 01:18:52.054326+00', '', 'owner@example.com');
INSERT INTO "public"."stock_movements" ("id", "variant_id", "product_id", "delta", "reason", "order_id", "created_at", "note", "by_email") VALUES ('6', '12', '3', '-1', 'order', NULL, '2026-11-05 01:21:27.56547+00', 'Commande NJ-1003 supprimée', '');
INSERT INTO "public"."stock_movements" ("id", "variant_id", "product_id", "delta", "reason", "order_id", "created_at", "note", "by_email") VALUES ('7', '12', '3', '1', 'returned', NULL, '2026-11-05 01:22:38.201081+00', 'Commande NJ-1003 supprimée', 'owner@example.com');
INSERT INTO "public"."stock_movements" ("id", "variant_id", "product_id", "delta", "reason", "order_id", "created_at", "note", "by_email") VALUES ('2', '33', '6', '-1', 'order', NULL, '2026-11-05 00:56:11.005905+00', 'Commande NJ-1002 supprimée', '');
INSERT INTO "public"."stock_movements" ("id", "variant_id", "product_id", "delta", "reason", "order_id", "created_at", "note", "by_email") VALUES ('4', '33', '6', '1', 'cancelled', NULL, '2026-11-05 01:17:38.511586+00', 'Commande NJ-1002 supprimée', 'owner@example.com');
INSERT INTO "public"."stock_movements" ("id", "variant_id", "product_id", "delta", "reason", "order_id", "created_at", "note", "by_email") VALUES ('1', '23', '4', '-1', 'order', NULL, '2026-11-05 00:22:11.28813+00', 'Commande NJ-1001 supprimée', '');
INSERT INTO "public"."stock_movements" ("id", "variant_id", "product_id", "delta", "reason", "order_id", "created_at", "note", "by_email") VALUES ('3', '23', '4', '1', 'cancelled', NULL, '2026-11-05 01:17:20.626232+00', 'Commande NJ-1001 supprimée', 'owner@example.com');
INSERT INTO "public"."stock_movements" ("id", "variant_id", "product_id", "delta", "reason", "order_id", "created_at", "note", "by_email") VALUES ('8', '54', '12', '7', 'reception', NULL, '2026-11-05 01:35:47.162865+00', '', 'owner@example.com');
INSERT INTO "public"."stock_movements" ("id", "variant_id", "product_id", "delta", "reason", "order_id", "created_at", "note", "by_email") VALUES ('10', '2', '1', '-1', 'order', NULL, '2026-11-05 02:18:00.398846+00', 'Commande NJ-1005 supprimée', '');
INSERT INTO "public"."stock_movements" ("id", "variant_id", "product_id", "delta", "reason", "order_id", "created_at", "note", "by_email") VALUES ('9', '6', '2', '-1', 'order', NULL, '2026-11-05 02:12:49.405753+00', 'Commande NJ-1004 supprimée', '');
INSERT INTO "public"."stock_movements" ("id", "variant_id", "product_id", "delta", "reason", "order_id", "created_at", "note", "by_email") VALUES ('11', '6', '2', '-2', 'order', NULL, '2026-11-05 05:47:43.436108+00', 'Commande NJ-1006 supprimée', '');
INSERT INTO "public"."stock_movements" ("id", "variant_id", "product_id", "delta", "reason", "order_id", "created_at", "note", "by_email") VALUES ('12', '6', '2', '3', 'adjustment', NULL, '2026-11-05 05:51:37.65362+00', '', 'owner@example.com');

-- public.subscribers: 0 row(s)

-- public.variants: 54 row(s)
INSERT INTO "public"."variants" ("id", "product_id", "size", "color", "color_hex", "sku", "stock", "position", "image") VALUES ('3', '1', 'M', 'Chaux', '#EFE9DC', 'JEBBA--M-Cha', '10', '3', '');
INSERT INTO "public"."variants" ("id", "product_id", "size", "color", "color_hex", "sku", "stock", "position", "image") VALUES ('4', '1', 'L', 'Chaux', '#EFE9DC', 'JEBBA--L-Cha', '8', '4', '');
INSERT INTO "public"."variants" ("id", "product_id", "size", "color", "color_hex", "sku", "stock", "position", "image") VALUES ('5', '1', 'XL', 'Chaux', '#EFE9DC', 'JEBBA--XL-Cha', '2', '5', '');
INSERT INTO "public"."variants" ("id", "product_id", "size", "color", "color_hex", "sku", "stock", "position", "image") VALUES ('21', '4', 'XS', 'Rayé marine', '#3A4E78', 'CHEMIS-XS-Ray', '3', '1', '');
INSERT INTO "public"."variants" ("id", "product_id", "size", "color", "color_hex", "sku", "stock", "position", "image") VALUES ('22', '4', 'S', 'Rayé marine', '#3A4E78', 'CHEMIS-S-Ray', '8', '2', '');
INSERT INTO "public"."variants" ("id", "product_id", "size", "color", "color_hex", "sku", "stock", "position", "image") VALUES ('24', '4', 'L', 'Rayé marine', '#3A4E78', 'CHEMIS-L-Ray', '8', '4', '');
INSERT INTO "public"."variants" ("id", "product_id", "size", "color", "color_hex", "sku", "stock", "position", "image") VALUES ('25', '4', 'XL', 'Rayé marine', '#3A4E78', 'CHEMIS-XL-Ray', '2', '5', '');
INSERT INTO "public"."variants" ("id", "product_id", "size", "color", "color_hex", "sku", "stock", "position", "image") VALUES ('26', '5', 'XS', 'Rayé indigo', '#3C5A8C', 'CHEMIS-XS-Ray', '3', '1', '');
INSERT INTO "public"."variants" ("id", "product_id", "size", "color", "color_hex", "sku", "stock", "position", "image") VALUES ('27', '5', 'S', 'Rayé indigo', '#3C5A8C', 'CHEMIS-S-Ray', '8', '2', '');
INSERT INTO "public"."variants" ("id", "product_id", "size", "color", "color_hex", "sku", "stock", "position", "image") VALUES ('28', '5', 'M', 'Rayé indigo', '#3C5A8C', 'CHEMIS-M-Ray', '10', '3', '');
INSERT INTO "public"."variants" ("id", "product_id", "size", "color", "color_hex", "sku", "stock", "position", "image") VALUES ('29', '5', 'L', 'Rayé indigo', '#3C5A8C', 'CHEMIS-L-Ray', '8', '4', '');
INSERT INTO "public"."variants" ("id", "product_id", "size", "color", "color_hex", "sku", "stock", "position", "image") VALUES ('30', '5', 'XL', 'Rayé indigo', '#3C5A8C', 'CHEMIS-XL-Ray', '2', '5', '');
INSERT INTO "public"."variants" ("id", "product_id", "size", "color", "color_hex", "sku", "stock", "position", "image") VALUES ('31', '6', 'XS', 'Blanc', '#F6F3EC', 'ROBE-Y-XS-Bla', '3', '1', '');
INSERT INTO "public"."variants" ("id", "product_id", "size", "color", "color_hex", "sku", "stock", "position", "image") VALUES ('32', '6', 'S', 'Blanc', '#F6F3EC', 'ROBE-Y-S-Bla', '8', '2', '');
INSERT INTO "public"."variants" ("id", "product_id", "size", "color", "color_hex", "sku", "stock", "position", "image") VALUES ('34', '6', 'L', 'Blanc', '#F6F3EC', 'ROBE-Y-L-Bla', '8', '4', '');
INSERT INTO "public"."variants" ("id", "product_id", "size", "color", "color_hex", "sku", "stock", "position", "image") VALUES ('35', '6', 'XL', 'Blanc', '#F6F3EC', 'ROBE-Y-XL-Bla', '2', '5', '');
INSERT INTO "public"."variants" ("id", "product_id", "size", "color", "color_hex", "sku", "stock", "position", "image") VALUES ('36', '7', 'XS', 'Écru', '#EDE6D6', 'PANTAL-XS-Écr', '3', '1', '');
INSERT INTO "public"."variants" ("id", "product_id", "size", "color", "color_hex", "sku", "stock", "position", "image") VALUES ('37', '7', 'S', 'Écru', '#EDE6D6', 'PANTAL-S-Écr', '8', '2', '');
INSERT INTO "public"."variants" ("id", "product_id", "size", "color", "color_hex", "sku", "stock", "position", "image") VALUES ('38', '7', 'M', 'Écru', '#EDE6D6', 'PANTAL-M-Écr', '10', '3', '');
INSERT INTO "public"."variants" ("id", "product_id", "size", "color", "color_hex", "sku", "stock", "position", "image") VALUES ('39', '7', 'L', 'Écru', '#EDE6D6', 'PANTAL-L-Écr', '8', '4', '');
INSERT INTO "public"."variants" ("id", "product_id", "size", "color", "color_hex", "sku", "stock", "position", "image") VALUES ('40', '7', 'XL', 'Écru', '#EDE6D6', 'PANTAL-XL-Écr', '2', '5', '');
INSERT INTO "public"."variants" ("id", "product_id", "size", "color", "color_hex", "sku", "stock", "position", "image") VALUES ('41', '8', 'XS', 'Écru', '#EFE9DC', 'TSHIRT-XS-Écr', '3', '1', '');
INSERT INTO "public"."variants" ("id", "product_id", "size", "color", "color_hex", "sku", "stock", "position", "image") VALUES ('42', '8', 'S', 'Écru', '#EFE9DC', 'TSHIRT-S-Écr', '8', '2', '');
INSERT INTO "public"."variants" ("id", "product_id", "size", "color", "color_hex", "sku", "stock", "position", "image") VALUES ('43', '8', 'M', 'Écru', '#EFE9DC', 'TSHIRT-M-Écr', '10', '3', '');
INSERT INTO "public"."variants" ("id", "product_id", "size", "color", "color_hex", "sku", "stock", "position", "image") VALUES ('44', '8', 'L', 'Écru', '#EFE9DC', 'TSHIRT-L-Écr', '8', '4', '');
INSERT INTO "public"."variants" ("id", "product_id", "size", "color", "color_hex", "sku", "stock", "position", "image") VALUES ('45', '8', 'XL', 'Écru', '#EFE9DC', 'TSHIRT-XL-Écr', '2', '5', '');
INSERT INTO "public"."variants" ("id", "product_id", "size", "color", "color_hex", "sku", "stock", "position", "image") VALUES ('46', '9', 'Unique', 'Lin naturel', '#CFC4AE', 'BOB-SI-U', '14', '1', '');
INSERT INTO "public"."variants" ("id", "product_id", "size", "color", "color_hex", "sku", "stock", "position", "image") VALUES ('47', '10', 'Unique', 'Brique', '#A63E2A', 'CASQUE-U', '12', '1', '');
INSERT INTO "public"."variants" ("id", "product_id", "size", "color", "color_hex", "sku", "stock", "position", "image") VALUES ('48', '11', 'Unique', 'Naturel', '#C8A970', 'CABAS--U', '6', '1', '');
INSERT INTO "public"."variants" ("id", "product_id", "size", "color", "color_hex", "sku", "stock", "position", "image") VALUES ('49', '12', '36', 'Cognac', '#8A5A33', 'SANDAL-36', '2', '1', '');
INSERT INTO "public"."variants" ("id", "product_id", "size", "color", "color_hex", "sku", "stock", "position", "image") VALUES ('50', '12', '37', 'Cognac', '#8A5A33', 'SANDAL-37', '4', '2', '');
INSERT INTO "public"."variants" ("id", "product_id", "size", "color", "color_hex", "sku", "stock", "position", "image") VALUES ('51', '12', '38', 'Cognac', '#8A5A33', 'SANDAL-38', '5', '3', '');
INSERT INTO "public"."variants" ("id", "product_id", "size", "color", "color_hex", "sku", "stock", "position", "image") VALUES ('52', '12', '39', 'Cognac', '#8A5A33', 'SANDAL-39', '5', '4', '');
INSERT INTO "public"."variants" ("id", "product_id", "size", "color", "color_hex", "sku", "stock", "position", "image") VALUES ('53', '12', '40', 'Cognac', '#8A5A33', 'SANDAL-40', '3', '5', '');
INSERT INTO "public"."variants" ("id", "product_id", "size", "color", "color_hex", "sku", "stock", "position", "image") VALUES ('23', '4', 'M', 'Rayé marine', '#3A4E78', 'CHEMIS-M-Ray', '10', '3', '');
INSERT INTO "public"."variants" ("id", "product_id", "size", "color", "color_hex", "sku", "stock", "position", "image") VALUES ('33', '6', 'M', 'Blanc', '#F6F3EC', 'ROBE-Y-M-Bla', '10', '3', '');
INSERT INTO "public"."variants" ("id", "product_id", "size", "color", "color_hex", "sku", "stock", "position", "image") VALUES ('1', '1', 'XS', 'Chaux', '#EFE9DC', 'JEBBA--XS-Cha', '7', '1', '');
INSERT INTO "public"."variants" ("id", "product_id", "size", "color", "color_hex", "sku", "stock", "position", "image") VALUES ('16', '3', 'XS', 'Sable', '#CDBB9C', 'HOODIE-XS-Sab', '3', '1', '/img/p-hoodie.jpg');
INSERT INTO "public"."variants" ("id", "product_id", "size", "color", "color_hex", "sku", "stock", "position", "image") VALUES ('17', '3', 'S', 'Sable', '#CDBB9C', 'HOODIE-S-Sab', '8', '2', '/img/p-hoodie.jpg');
INSERT INTO "public"."variants" ("id", "product_id", "size", "color", "color_hex", "sku", "stock", "position", "image") VALUES ('18', '3', 'M', 'Sable', '#CDBB9C', 'HOODIE-M-Sab', '10', '3', '/img/p-hoodie.jpg');
INSERT INTO "public"."variants" ("id", "product_id", "size", "color", "color_hex", "sku", "stock", "position", "image") VALUES ('19', '3', 'L', 'Sable', '#CDBB9C', 'HOODIE-L-Sab', '8', '4', '/img/p-hoodie.jpg');
INSERT INTO "public"."variants" ("id", "product_id", "size", "color", "color_hex", "sku", "stock", "position", "image") VALUES ('20', '3', 'XL', 'Sable', '#CDBB9C', 'HOODIE-XL-Sab', '2', '5', '/img/p-hoodie.jpg');
INSERT INTO "public"."variants" ("id", "product_id", "size", "color", "color_hex", "sku", "stock", "position", "image") VALUES ('11', '3', 'XS', 'Indigo', '#1E3358', 'HOODIE-XS-Ind', '3', '1', '/img/p-hoodie-2.jpg');
INSERT INTO "public"."variants" ("id", "product_id", "size", "color", "color_hex", "sku", "stock", "position", "image") VALUES ('13', '3', 'M', 'Indigo', '#1E3358', 'HOODIE-M-Ind', '10', '3', '/img/p-hoodie-2.jpg');
INSERT INTO "public"."variants" ("id", "product_id", "size", "color", "color_hex", "sku", "stock", "position", "image") VALUES ('14', '3', 'L', 'Indigo', '#1E3358', 'HOODIE-L-Ind', '8', '4', '/img/p-hoodie-2.jpg');
INSERT INTO "public"."variants" ("id", "product_id", "size", "color", "color_hex", "sku", "stock", "position", "image") VALUES ('15', '3', 'XL', 'Indigo', '#1E3358', 'HOODIE-XL-Ind', '2', '5', '/img/p-hoodie-2.jpg');
INSERT INTO "public"."variants" ("id", "product_id", "size", "color", "color_hex", "sku", "stock", "position", "image") VALUES ('12', '3', 'S', 'Indigo', '#1E3358', 'HOODIE-S-Ind', '8', '2', '/img/p-hoodie-2.jpg');
INSERT INTO "public"."variants" ("id", "product_id", "size", "color", "color_hex", "sku", "stock", "position", "image") VALUES ('54', '12', '41', 'Cognac', '#8A5A33', 'SANDAL-41', '7', '6', '');
INSERT INTO "public"."variants" ("id", "product_id", "size", "color", "color_hex", "sku", "stock", "position", "image") VALUES ('7', '2', 'S', 'rouge', '#df1111', 'VESTE--S-Ind', '8', '1', '');
INSERT INTO "public"."variants" ("id", "product_id", "size", "color", "color_hex", "sku", "stock", "position", "image") VALUES ('8', '2', 'M', 'Indigo', '#4a4d54', 'VESTE--M-Ind', '10', '2', '');
INSERT INTO "public"."variants" ("id", "product_id", "size", "color", "color_hex", "sku", "stock", "position", "image") VALUES ('9', '2', 'L', 'Indigo', '#24396B', 'VESTE--L-Ind', '8', '3', '');
INSERT INTO "public"."variants" ("id", "product_id", "size", "color", "color_hex", "sku", "stock", "position", "image") VALUES ('10', '2', 'XL', 'Indigo', '#24396B', 'VESTE--XL-Ind', '2', '4', '');
INSERT INTO "public"."variants" ("id", "product_id", "size", "color", "color_hex", "sku", "stock", "position", "image") VALUES ('2', '1', 'S', 'Chaux', '#EFE9DC', 'JEBBA--S-Cha', '7', '2', '');
INSERT INTO "public"."variants" ("id", "product_id", "size", "color", "color_hex", "sku", "stock", "position", "image") VALUES ('6', '2', 'XS', 'bleu', '#0f48cc', 'VESTE--XS-Ind', '3', '0', '');

-- Sync sequences
SELECT pg_catalog.setval('public.collections_id_seq', 4, true);
SELECT pg_catalog.setval('public.expenses_id_seq', 1, false);
SELECT pg_catalog.setval('public.messages_id_seq', 1, false);
SELECT pg_catalog.setval('public.order_number_seq', 1001, false);
SELECT pg_catalog.setval('public.orders_id_seq', 1, false);
SELECT pg_catalog.setval('public.products_id_seq', 12, true);
SELECT pg_catalog.setval('public.reviews_id_seq', 1, false);
SELECT pg_catalog.setval('public.stock_movements_id_seq', 12, true);
SELECT pg_catalog.setval('public.subscribers_id_seq', 1, false);
SELECT pg_catalog.setval('public.variants_id_seq', 54, true);

ALTER TABLE ONLY "public"."admins"
    ADD CONSTRAINT "admins_pkey" PRIMARY KEY (user_id);
ALTER TABLE ONLY "public"."collections"
    ADD CONSTRAINT "collections_pkey" PRIMARY KEY (id);
ALTER TABLE ONLY "public"."collections"
    ADD CONSTRAINT "collections_slug_key" UNIQUE (slug);
ALTER TABLE ONLY "public"."delivery_zones"
    ADD CONSTRAINT "delivery_zones_pkey" PRIMARY KEY (governorate);
ALTER TABLE ONLY "public"."discount_codes"
    ADD CONSTRAINT "discount_codes_pkey" PRIMARY KEY (code);
ALTER TABLE ONLY "public"."discount_codes"
    ADD CONSTRAINT "discount_codes_kind_check" CHECK ((kind = ANY (ARRAY['percent'::text, 'fixed'::text, 'shipping'::text])));
ALTER TABLE ONLY "public"."expenses"
    ADD CONSTRAINT "expenses_pkey" PRIMARY KEY (id);
ALTER TABLE ONLY "public"."expenses"
    ADD CONSTRAINT "expenses_amount_check" CHECK ((amount >= (0)::numeric));
ALTER TABLE ONLY "public"."messages"
    ADD CONSTRAINT "messages_pkey" PRIMARY KEY (id);
ALTER TABLE ONLY "public"."orders"
    ADD CONSTRAINT "orders_pkey" PRIMARY KEY (id);
ALTER TABLE ONLY "public"."orders"
    ADD CONSTRAINT "orders_number_key" UNIQUE (number);
ALTER TABLE ONLY "public"."orders"
    ADD CONSTRAINT "orders_payment_status_check" CHECK ((payment_status = ANY (ARRAY['pending'::text, 'paid'::text, 'refunded'::text])));
ALTER TABLE ONLY "public"."orders"
    ADD CONSTRAINT "orders_status_check" CHECK ((status = ANY (ARRAY['pending'::text, 'confirmed'::text, 'preparing'::text, 'shipped'::text, 'delivered'::text, 'cancelled'::text, 'returned'::text])));
ALTER TABLE ONLY "public"."products"
    ADD CONSTRAINT "products_pkey" PRIMARY KEY (id);
ALTER TABLE ONLY "public"."products"
    ADD CONSTRAINT "products_slug_key" UNIQUE (slug);
ALTER TABLE ONLY "public"."products"
    ADD CONSTRAINT "products_cost_price_check" CHECK ((cost_price >= (0)::numeric));
ALTER TABLE ONLY "public"."products"
    ADD CONSTRAINT "products_price_check" CHECK ((price >= (0)::numeric));
ALTER TABLE ONLY "public"."products"
    ADD CONSTRAINT "products_status_check" CHECK ((status = ANY (ARRAY['published'::text, 'draft'::text, 'hidden'::text])));
ALTER TABLE ONLY "public"."reviews"
    ADD CONSTRAINT "reviews_pkey" PRIMARY KEY (id);
ALTER TABLE ONLY "public"."reviews"
    ADD CONSTRAINT "reviews_rating_check" CHECK (((rating >= 1) AND (rating <= 5)));
ALTER TABLE ONLY "public"."settings"
    ADD CONSTRAINT "settings_pkey" PRIMARY KEY (key);
ALTER TABLE ONLY "public"."stock_movements"
    ADD CONSTRAINT "stock_movements_pkey" PRIMARY KEY (id);
ALTER TABLE ONLY "public"."subscribers"
    ADD CONSTRAINT "subscribers_pkey" PRIMARY KEY (id);
ALTER TABLE ONLY "public"."subscribers"
    ADD CONSTRAINT "subscribers_email_key" UNIQUE (email);
ALTER TABLE ONLY "public"."variants"
    ADD CONSTRAINT "variants_pkey" PRIMARY KEY (id);
ALTER TABLE ONLY "public"."variants"
    ADD CONSTRAINT "variants_stock_check" CHECK ((stock >= 0));
ALTER TABLE ONLY "public"."reviews"
    ADD CONSTRAINT "reviews_product_id_fkey" FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE;
ALTER TABLE ONLY "public"."stock_movements"
    ADD CONSTRAINT "stock_movements_variant_id_fkey" FOREIGN KEY (variant_id) REFERENCES variants(id) ON DELETE SET NULL;
ALTER TABLE ONLY "public"."variants"
    ADD CONSTRAINT "variants_product_id_fkey" FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE;

CREATE INDEX expenses_spent_idx ON public.expenses USING btree (spent_at DESC);
CREATE INDEX orders_client_ip_idx ON public.orders USING btree (client_ip, created_at DESC);
CREATE INDEX orders_created_idx ON public.orders USING btree (created_at DESC);
CREATE INDEX orders_phone_idx ON public.orders USING btree (phone);
CREATE INDEX orders_user_idx ON public.orders USING btree (user_id);
CREATE INDEX products_status_idx ON public.products USING btree (status);
CREATE INDEX stock_movements_created_idx ON public.stock_movements USING btree (created_at DESC);
CREATE INDEX variants_product_idx ON public.variants USING btree (product_id);

ALTER SEQUENCE "public"."collections_id_seq" OWNED BY "public"."collections"."id";
ALTER SEQUENCE "public"."expenses_id_seq" OWNED BY "public"."expenses"."id";
ALTER SEQUENCE "public"."messages_id_seq" OWNED BY "public"."messages"."id";
ALTER SEQUENCE "public"."orders_id_seq" OWNED BY "public"."orders"."id";
ALTER SEQUENCE "public"."products_id_seq" OWNED BY "public"."products"."id";
ALTER SEQUENCE "public"."reviews_id_seq" OWNED BY "public"."reviews"."id";
ALTER SEQUENCE "public"."stock_movements_id_seq" OWNED BY "public"."stock_movements"."id";
ALTER SEQUENCE "public"."subscribers_id_seq" OWNED BY "public"."subscribers"."id";
ALTER SEQUENCE "public"."variants_id_seq" OWNED BY "public"."variants"."id";
