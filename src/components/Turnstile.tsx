import { forwardRef, useEffect, useImperativeHandle, useRef } from "react";
import { loadTurnstile, TURNSTILE_ENABLED, TURNSTILE_SITE_KEY } from "../turnstile";

export type TurnstileHandle = {
  /** Current token, or "" while the widget is loading / unsolved. */
  token: () => string;
  /** Clears the widget (tokens are single-use). */
  reset: () => void;
};

/**
 * Renders a Cloudflare Turnstile widget only when VITE_TURNSTILE_SITE_KEY is
 * set. The widget mode (managed / non-interactive) is chosen in the Cloudflare
 * dashboard; nothing secret is needed in the bundle.
 */
export const Turnstile = forwardRef<TurnstileHandle, { theme?: "light" | "dark" | "auto" }>(
  function Turnstile({ theme = "light" }, ref) {
    const box = useRef<HTMLDivElement>(null);
    const widgetId = useRef<string | null>(null);

    useEffect(() => {
      if (!TURNSTILE_ENABLED) return;
      let alive = true;

      loadTurnstile()
        .then((api) => {
          if (!alive || !box.current) return;
          if (widgetId.current) api.remove(widgetId.current);
          widgetId.current = api.render(box.current, {
            sitekey: TURNSTILE_SITE_KEY,
            theme,
            language: "fr",
            appearance: "always",
            retry: "auto",
            "refresh-expired": "auto",
          });
        })
        .catch(() => {
          // Script blocked (ad-blocker, offline): leave the slot empty. The form
          // shows a clear message if a token is required.
        });

      return () => {
        alive = false;
        if (window.turnstile && widgetId.current) {
          try { window.turnstile.remove(widgetId.current); } catch { /* already gone */ }
        }
        widgetId.current = null;
      };
    }, [theme]);

    useImperativeHandle(
      ref,
      () => ({
        token: () => {
          if (!TURNSTILE_ENABLED || !window.turnstile || !widgetId.current) return "";
          return window.turnstile.getResponse(widgetId.current) || "";
        },
        reset: () => {
          if (window.turnstile && widgetId.current) {
            try { window.turnstile.reset(widgetId.current); } catch { /* widget removed */ }
          }
        },
      }),
      [],
    );

    if (!TURNSTILE_ENABLED) return null;
    return <div className="ts-slot" ref={box} />;
  },
);
