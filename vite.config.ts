import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

/**
 * VITE_BASE_PATH is set by the GitHub Pages workflow to `/<repo>/`.
 * Locally it defaults to `/`. Supabase credentials are injected at build time
 * through VITE_SUPABASE_URL and VITE_SUPABASE_ANON_KEY.
 */
export default defineConfig({
  base: process.env.VITE_BASE_PATH || "/",
  plugins: [react()],
  server: {
    // Allow accessing the dev server through a tunnel (e.g. trycloudflare.com).
    allowedHosts: true,
  },
});
