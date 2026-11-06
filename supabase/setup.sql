-- ============================================================================
-- NAHJ Boutique — installation complète sur un projet Supabase VIDE
-- Exécuter ce fichier UNE SEULE FOIS dans le SQL Editor de Supabase.
-- Si les tables existent déjà, exécuter seulement 02-api.sql,
-- puis 03-auth-storage.sql, puis 04-accounts.sql.
-- ============================================================================

-- ############################################################################
-- ## 01-schema-data.sql
-- ############################################################################

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

-- ############################################################################
-- ## 02-api.sql
-- ############################################################################

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

-- Replace with YOUR owner email before running this file.
insert into public.admin_emails (email)
values ('owner@example.com')
on conflict (email) do nothing;

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
        'wish_list','wish_toggle',
        'is_admin','slugify','client_ip','product_json','product_json_admin','order_public_json')
  loop
    execute format('revoke all on function %s from public', f.sig);
  end loop;
end $$;

grant execute on function public.is_admin() to authenticated;
grant execute on function public.slugify(text) to anon, authenticated;
grant execute on function public.client_ip() to anon, authenticated;

-- ############################################################################
-- ## 03-auth-storage.sql
-- ############################################################################

-- ============================================================================
-- NAHJ Boutique — Auth, admin allowlist, RLS and Storage
-- Run after 01 (schema) and 02 (API). Safe to run several times.
--
-- SECURITY MODEL
--   * The public site can only execute public.api(...).
--   * Direct table access is blocked by RLS (no policies at all).
--   * /admin works only for accounts whose email is in admin_emails.
--   * Public sign-up is disabled in Supabase (Authentication > Providers > Email).
-- ============================================================================

-- ---------------------------------------------------------------------------
-- Owner allowlist — CHANGE THIS EMAIL if needed, then sign in once with it.
-- ---------------------------------------------------------------------------

create table if not exists public.admin_emails (
  email text primary key
);

alter table public.admin_emails enable row level security;
revoke all on public.admin_emails from anon, authenticated;

-- Replace with YOUR owner email before running this file.
insert into public.admin_emails (email)
values ('owner@example.com')
on conflict (email) do nothing;

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

-- ############################################################################
-- ## 04-accounts.sql
-- ############################################################################

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
revoke all on function public.wish_list() from public;
revoke all on function public.wish_toggle(int) from public;

-- ---------------------------------------------------------------------------
-- Orders placed while signed in are already linked by 02 (orders.user_id) and
-- read back by public.my_orders(). Nothing else to change here.
-- ---------------------------------------------------------------------------
