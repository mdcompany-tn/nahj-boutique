# NAHJ Boutique — GitHub Pages + Supabase

Boutique statique (Vite + React) hébergée gratuitement sur **GitHub Pages**, avec
**Supabase** pour la base de données, l’authentification et les images.

- Vitrine publique : catalogue, collections, panier, commande (paiement à la livraison), suivi de commande.
- Administration : `/admin`, réservée à **un seul email propriétaire** (allowlist Supabase).
- Aucune fonction Netlify : tout le backend est dans des fonctions SQL Supabase.
- Les clés Supabase utilisées par le site sont **publiques** (anon / publishable key). La sécurité
  repose sur les fonctions SQL et le Row Level Security, pas sur la clé.

---

## 1. Créer le projet Supabase

1. Ouvrez <https://supabase.com/dashboard> et créez un projet (gratuit).
2. Dans **Project Settings → API**, copiez :
   - **Project URL** (`https://xxxx.supabase.co`)
   - **anon public** key (ou **publishable** key)
3. Dans **SQL Editor**, exécutez les fichiers dans cet ordre :
   - `supabase/01-schema-data.sql` — tables + données (produits, variantes, collections, réglages, zones). **Uniquement sur un projet vide.**
   - `supabase/02-api.sql` — API (fonctions SQL) appelée par le site.
   - `supabase/03-auth-storage.sql` — allowlist admin, verrouillage RLS, bucket `media`.

   Ou, pour un projet vide, exécutez une seule fois `supabase/setup.sql`
   (les trois fichiers concaténés).

   > Si les tables existent déjà, ne relancez **pas** `01` : exécutez seulement
   > `02-api.sql` puis `03-auth-storage.sql` (les deux sont ré-exécutables).

4. **Authentication → Providers → Email** :
   - Désactivez **Allow new users to sign up** (inscription publique fermée).
   - Laissez la confirmation d’email activée si vous voulez, mais créez le compte
     propriétaire manuellement pour éviter tout blocage.

5. **Authentication → Users → Add user** :
   - Email : `***********@gmail.com` (ou celui défini dans `admin_emails`)
   - Mot de passe : choisissez-en un solide
   - Cochez **Auto Confirm User**
   - Le trigger SQL ajoute automatiquement ce compte à la table `admins`.

6. **Authentication → URL Configuration** :
   - **Site URL** : `https://<utilisateur>.github.io/<repo>/`
   - **Redirect URLs** : ajoutez
     - `https://<utilisateur>.github.io/<repo>/admin`
     - `http://localhost:5173/admin` (développement local)

7. Vérifiez dans **Storage** que le bucket public **`media`** existe (créé par `03`).

### Changer l’email propriétaire

Dans le SQL Editor :

```sql
delete from public.admin_emails;
insert into public.admin_emails (email) values ('nouvel-email@example.com');
```

Puis créez ce compte dans **Authentication → Users** (Auto Confirm). Pour retirer
l’ancien accès, supprimez aussi sa ligne dans `public.admins` si elle existe.

---

## 2. Publier sur GitHub Pages

1. Créez un dépôt **public** sur GitHub, par exemple `nahj-boutique`.
2. Poussez ce dossier sur la branche `main`.
3. Dans le dépôt : **Settings → Pages** → **Build and deployment** →
   **Source : GitHub Actions**.
4. Dans **Settings → Secrets and variables → Actions → Variables**, ajoutez :
   - `VITE_SUPABASE_URL` = Project URL
   - `VITE_SUPABASE_ANON_KEY` = anon / publishable key

   (Ce ne sont pas des secrets : ces valeurs sont visibles dans le site.)
5. Poussez sur `main` (ou lancez **Actions → Deploy to GitHub Pages → Run workflow**).
6. Le site est publié sur `https://<utilisateur>.github.io/<repo>/`.
   L’admin est sur `https://<utilisateur>.github.io/<repo>/admin`.

Le workflow `.github/workflows/deploy.yml` construit le site avec le bon préfixe
`/<repo>/`, copie `index.html` en `404.html` (pour les liens directs) et ajoute
`.nojekyll`.

---

## 3. Développement local

```bash
npm install
cp .env.example .env     # puis remplir VITE_SUPABASE_URL et VITE_SUPABASE_ANON_KEY
npm run dev
```

- Site : <http://localhost:5173>
- Admin : <http://localhost:5173/admin>

Autres commandes :

```bash
npm run typecheck
npm run build
npm run preview
```

---

## 4. Comment ça marche

### API

Le site appelle toujours `api("/api/...")`, mais `src/api.ts` exécute maintenant
un seul RPC Postgres : `public.api(p_path, p_method, p_query, p_body)`.
Le dispatcher SQL reproduit les anciennes routes :

| Route | Rôle |
| --- | --- |
| `GET /api/store` | marque, contenu, collections, zones |
| `GET /api/products` | catalogue publié |
| `GET /api/products/:slug` | fiche + avis approuvés + similaires |
| `POST /api/orders/quote` | calcul panier, livraison, code promo |
| `POST /api/orders` | création de commande (stock décrémenté) |
| `GET /api/orders/:number?phone=` | suivi public |
| `POST /api/contact` / `reviews` / `newsletter` | formulaires |
| `/api/admin/*` | réservé à `public.is_admin()` |

### Images

- Images fournies avec le site : `public/img/...`, servies avec le préfixe GitHub Pages.
- Images uploadées depuis l’admin : bucket Supabase `media`, stockées en base sous
  la forme `/media/<clé>`. Le préfixe est résolu automatiquement par `asset()`.

### Polices et performance (CLS)

- Les polices Google (Bodoni Moda, Familjen Grotesk, Reem Kufi, Noto Kufi Arabic)
  sont **auto-hébergées** dans `public/fonts/` et déclarées dans `src/fonts.css`.
  Aucun appel à `fonts.googleapis.com`, et les fichiers critiques sont
  `preload` dans `index.html`.
- La barre d’annonces réserve sa hauteur pendant le chargement des données
  (`Announcements` dans `src/components/Layout.tsx`), sinon toute la page
  descendait de 36 px quand elle apparaissait (CLS 0.92 → 0).
- `index.html` n’inclut plus qu’une seule image de héros (l’ancienne copie cachée
  était téléchargée pour rien).

### Sécurité

- `public.api` est la seule fonction exécutable par `anon` / `authenticated`.
- Toutes les tables ont RLS activé **sans policy** : accès direct bloqué.
- `/admin` vérifie `public.is_admin()` côté serveur (email dans `admin_emails`
  ou ligne dans `admins`), pas seulement côté navigateur.
- Upload/suppression Storage réservés aux admins ; lecture publique.

### Sauvegarde

Le dossier parent `netlify-db-backup-2026-11-05` contient l’export complet de
l’ancienne base (`full-backup.sql`, `data.sql`, etc.). **Ne le publiez jamais** :
il contient les anciennes données d’administration. Conservez-le hors du dépôt.

---

## 5. Dépannage

| Problème | Solution |
| --- | --- |
| Page blanche / erreur Supabase dans la console | Vérifiez les variables `VITE_SUPABASE_*` (locale `.env`, ou Variables GitHub Actions), puis relancez le build. |
| `Accès refusé` sur `/admin` | L’email du compte n’est pas dans `admin_emails` ; vérifiez la table et reconnectez-vous. |
| `Email ou mot de passe incorrect` | Compte créé dans Supabase Auth ? Email confirmé ? |
| Lien de réinitialisation invalide | Ajoutez l’URL `/admin` du site dans **Authentication → URL Configuration → Redirect URLs**. |
| Images `/media/...` cassées | Bucket `media` manquant ou policy de lecture absente : relancez `03-auth-storage.sql`. |
| Liens directs 404 sur GitHub Pages | Vérifiez que le workflow copie `index.html` en `404.html` (étape « Prepare GitHub Pages files »). |
| Le site s’ouvre sans styles | Le build n’a pas le bon préfixe : `VITE_BASE_PATH=/<repo>/`. |
| Erreur `relation "admins" already exists` | Vous avez relancé `01-schema-data.sql` : ne l’exécutez qu’une fois, sur un projet vide. |
