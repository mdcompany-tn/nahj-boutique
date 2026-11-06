/**
 * Cloudflare Turnstile (anti-robot) — optional.
 *
 * The site key is a public build-time value (GitHub Actions variable
 * VITE_TURNSTILE_SITE_KEY). When it is absent the widget is not rendered and
 * no token is sent, so the site keeps working with captcha disabled in
 * Supabase (Authentication > Attack Protection).
 */

type TurnstileApi = {
  render: (el: HTMLElement, options: Record<string, unknown>) => string;
  getResponse: (widgetId?: string) => string | undefined;
  reset: (widgetId?: string) => void;
  remove: (widgetId?: string) => void;
};

declare global {
  interface Window {
    turnstile?: TurnstileApi;
    __onTurnstileLoad?: () => void;
  }
}

const RAW_SITE_KEY = (import.meta.env.VITE_TURNSTILE_SITE_KEY || "").trim();

export const TURNSTILE_SITE_KEY = RAW_SITE_KEY;
export const TURNSTILE_ENABLED = RAW_SITE_KEY.length > 0;

const SCRIPT_ID = "cf-turnstile-script";
let loader: Promise<TurnstileApi> | null = null;

/** Loads the Turnstile script once and resolves with its global API. */
export function loadTurnstile(): Promise<TurnstileApi> {
  if (typeof window === "undefined") return Promise.reject(new Error("no window"));
  if (window.turnstile) return Promise.resolve(window.turnstile);
  if (loader) return loader;

  loader = new Promise<TurnstileApi>((resolve, reject) => {
    const existing = document.getElementById(SCRIPT_ID) as HTMLScriptElement | null;
    const script = existing ?? document.createElement("script");

    const done = () => {
      if (window.turnstile) resolve(window.turnstile);
      else reject(new Error("Turnstile indisponible"));
    };

    if (window.turnstile) { done(); return; }
    window.__onTurnstileLoad = done;

    if (!existing) {
      script.id = SCRIPT_ID;
      script.src = "https://challenges.cloudflare.com/turnstile/v0/api.js?render=explicit&onload=__onTurnstileLoad";
      script.async = true;
      script.defer = true;
      script.onerror = () => { loader = null; reject(new Error("Turnstile indisponible")); };
      document.head.appendChild(script);
    }

    // Safety net in case the onload callback never fires (blocked script).
    window.setTimeout(() => {
      if (window.turnstile) resolve(window.turnstile);
      else { loader = null; reject(new Error("Turnstile indisponible")); }
    }, 8000);
  });

  return loader;
}
