import { createClient } from "@supabase/supabase-js";

/**
 * Supabase project connection.
 *
 * Both values are public (they ship inside the JS bundle). Security comes from
 * the SQL functions and Row Level Security in supabase/*.sql, never from the key.
 * Set them in .env locally and in the GitHub repository variables for Pages.
 */
const rawUrl = (import.meta.env.VITE_SUPABASE_URL || "").trim();
const rawKey = (import.meta.env.VITE_SUPABASE_ANON_KEY || "").trim();

export const SUPABASE_URL = rawUrl.replace(/\/+$/, "") || "https://placeholder.supabase.co";
export const SUPABASE_ANON_KEY = rawKey || "placeholder-anon-key";
export const SUPABASE_CONFIGURED = Boolean(rawUrl && rawKey);
export const MEDIA_BUCKET = "media";

if (!SUPABASE_CONFIGURED) {
  console.error(
    "Supabase n'est pas configuré : définissez VITE_SUPABASE_URL et VITE_SUPABASE_ANON_KEY (voir README.md).",
  );
}

export const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
  auth: {
    persistSession: true,
    autoRefreshToken: true,
    detectSessionInUrl: true,
  },
});

/** Public URL of a file stored in the `media` bucket (admin uploads). */
export function mediaPublicUrl(key: string): string {
  const encoded = key
    .replace(/^\/+/, "")
    .split("/")
    .map(encodeURIComponent)
    .join("/");
  return `${SUPABASE_URL}/storage/v1/object/public/${MEDIA_BUCKET}/${encoded}`;
}
