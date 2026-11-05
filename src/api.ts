import { MEDIA_BUCKET, mediaPublicUrl, supabase } from "./supabase";

export type Variant = { id: number; size: string; color: string; color_hex: string; sku: string; stock: number; position: number; image?: string };
export type Product = {
  id: number; slug: string; name: string; name_ar: string; description: string; description_ar: string; details: string; care: string;
  price: number; compare_at_price: number | null; category: string; gender: string; collection_ids: number[]; images: string[];
  tags: string[]; status: string; featured: boolean; is_new: boolean; position: number; created_at: string; variants: Variant[]; sold: number; cost_price?: number;
};
export type Collection = { id: number; slug: string; name: string; name_ar: string; tagline: string; description: string; image: string; position: number; product_count: number; visible?: boolean };
export type Zone = { governorate: string; name_ar: string; fee: number; delay: string };
export type StoreData = { settings: Record<string, any>; collections: Collection[]; zones: Zone[] };

export class ApiError extends Error {
  constructor(public status: number, message: string, public issues?: string[]) { super(message); }
}

/** `/api/orders?phone=…` -> path + query object (the SQL dispatcher expects both separately). */
function splitPath(input: string) {
  const [rawPath, rawQuery = ""] = input.split("?");
  const query: Record<string, string> = {};
  new URLSearchParams(rawQuery).forEach((value, key) => { query[key] = value; });
  return { path: rawPath, query };
}

function friendlyError(error: { message?: string; code?: string }): ApiError {
  const message = error.message || "Une erreur est survenue";
  const unauthorized = /connexion requise|accès réservé|jwt|token/i.test(message);
  return new ApiError(unauthorized ? 401 : 400, message);
}

/**
 * Upload an image/video to the public `media` bucket. The database only stores
 * the `/media/<key>` path, so the same row works locally and in production.
 */
async function uploadToStorage(file: File): Promise<string> {
  if (file.size > 5.5 * 1024 * 1024) {
    throw new ApiError(400, "Fichier trop lourd (5,5 Mo max). Compressez la vidéo en MP4 (720p, 15 à 30 secondes).");
  }
  const ext = (file.name.match(/\.[a-z0-9]+$/i)?.[0] || "").toLowerCase();
  const key = `${new Date().toISOString().slice(0, 10)}/${crypto.randomUUID()}${ext}`;
  const { error } = await supabase.storage.from(MEDIA_BUCKET).upload(key, file, {
    contentType: file.type || "application/octet-stream",
    cacheControl: "31536000",
    upsert: false,
  });
  if (error) throw friendlyError(error);
  return `/media/${key}`;
}

/**
 * Every backend call goes through the single Postgres function `public.api`.
 * The path/method/body shape is unchanged, so components did not need editing.
 */
export async function api<T = any>(path: string, init: RequestInit & { json?: unknown } = {}): Promise<T> {
  const { json, ...rest } = init;
  const method = (rest.method || (json !== undefined || rest.body ? "POST" : "GET")).toUpperCase();

  if (path === "/api/admin/upload" && rest.body instanceof FormData) {
    const file = rest.body.get("file");
    if (!(file instanceof File)) throw new ApiError(400, "Fichier manquant");
    return { url: await uploadToStorage(file) } as T;
  }

  if (!json && rest.body) {
    throw new ApiError(400, "Corps de requête non pris en charge");
  }

  const { path: pathname, query } = splitPath(path);
  const { data, error } = await supabase.rpc("api", {
    p_path: pathname,
    p_method: method,
    p_query: query,
    p_body: json ?? {},
  });

  if (error) throw friendlyError(error);
  return data as T;
}

export const money = (n: number) => `${Number(n).toLocaleString("fr-TN", { minimumFractionDigits: 0, maximumFractionDigits: 3 })} DT`;
export const totalStock = (p: Product) => p.variants.reduce((s, v) => s + v.stock, 0);

/** Distinct colors of a product, in variant order. */
export function productColors(p: Product): [string, string][] {
  return [...new Map(p.variants.filter((v) => v.color).map((v) => [v.color, v.color_hex] as [string, string])).entries()];
}

/**
 * Photo to show for a color. Uses the photo assigned to that color in the admin; when no color of the
 * product has an assigned photo, falls back to matching colors to product photos in order
 * (1st color → 1st photo, 2nd color → 2nd photo…).
 */
export function colorImage(p: Product, color: string): string {
  const own = p.variants.find((v) => v.color === color && v.image)?.image;
  if (own) return own;
  if (p.variants.some((v) => v.image)) return "";
  const colors = productColors(p);
  if (colors.length < 2) return "";
  const i = colors.findIndex(([c]) => c === color);
  return (i >= 0 && p.images[i]) || "";
}

const BASE = import.meta.env.BASE_URL || "/";

/** Absolute path inside the site, honouring the GitHub Pages repository prefix (`/<repo>/`). */
export function sitePath(path = ""): string {
  return `${BASE.replace(/\/+$/, "")}/${String(path).replace(/^\/+/, "")}`;
}

/**
 * Resolve a stored image path:
 *  - `/media/...` -> Supabase Storage public URL (admin uploads)
 *  - `/img/...`   -> bundled file, prefixed with the site base path
 *  - http(s)/data/blob URLs are left untouched
 */
export function asset(src: string | undefined): string {
  if (!src) return "";
  if (/^(?:[a-z][a-z0-9+.-]*:|\/\/)/i.test(src)) return src;
  if (src.startsWith("/media/")) return mediaPublicUrl(src.slice("/media/".length));
  return sitePath(src);
}

/** Kept for the existing call sites. Images are now served directly (no Netlify CDN). */
export function img(src: string | undefined, _width: number): string {
  return asset(src);
}

/** Reads the hidden honeypot field from a submitted form. Real visitors never see it, so it stays empty. */
export const honeypot = (e: React.FormEvent<HTMLFormElement>) =>
  ((e.currentTarget.elements.namedItem("website") as HTMLInputElement | null)?.value || "");
