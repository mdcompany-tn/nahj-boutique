import { createContext, useCallback, useContext, useEffect, useMemo, useState, type ReactNode } from "react";
import { api, type Product, type StoreData } from "./api";
import { useAuth } from "./auth";
import type { Lang } from "./i18n";

export type CartItem = { variantId: number; productId: number; slug: string; name: string; size: string; color: string; image: string; price: number; qty: number; stock: number };

type Ctx = {
  data: StoreData | null; products: Product[]; loading: boolean; error: string | null; reload: () => void;
  cart: CartItem[]; addToCart: (i: CartItem) => void; setQty: (variantId: number, qty: number) => void; removeFromCart: (variantId: number) => void; clearCart: () => void;
  cartOpen: boolean; setCartOpen: (b: boolean) => void; cartCount: number;
  wishlist: number[]; toggleWish: (id: number) => void;
  lang: Lang; setLang: (l: Lang) => void;
  toast: string | null; notify: (m: string) => void;
};
const StoreCtx = createContext<Ctx>(null as any);
export const useStore = () => useContext(StoreCtx);

function useLocal<T>(key: string, initial: T) {
  const [v, setV] = useState<T>(() => {
    try { const raw = localStorage.getItem(key); return raw ? JSON.parse(raw) : initial; } catch { return initial; }
  });
  useEffect(() => { try { localStorage.setItem(key, JSON.stringify(v)); } catch { /* ignore */ } }, [key, v]);
  return [v, setV] as const;
}

export function StoreProvider({ children }: { children: ReactNode }) {
  const { user, ready: authReady } = useAuth();
  const [data, setData] = useState<StoreData | null>(null);
  const [products, setProducts] = useState<Product[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [cart, setCart] = useLocal<CartItem[]>("nahj.cart", []);
  // Favorites require an account: they live in Supabase, never in localStorage,
  // so a guest cannot build a favorites list without signing in.
  const [wishlist, setWishlist] = useState<number[]>([]);
  const [lang, setLang] = useLocal<Lang>("nahj.lang", "fr");
  const [cartOpen, setCartOpen] = useState(false);
  const [toast, setToast] = useState<string | null>(null);

  const reload = useCallback(() => {
    setLoading(true);
    Promise.all([api<StoreData>("/api/store"), api<{ products: Product[] }>("/api/products")])
      .then(([d, p]) => { setData(d); setProducts(p.products); setError(null); })
      .catch((e) => setError(e.message))
      .finally(() => setLoading(false));
  }, []);
  useEffect(reload, [reload]);

  useEffect(() => {
    document.documentElement.lang = lang;
    document.documentElement.dir = lang === "ar" ? "rtl" : "ltr";
  }, [lang]);

  // Apply brand colours from admin settings
  useEffect(() => {
    const c = data?.settings.brand?.colors;
    if (!c) return;
    const r = document.documentElement.style;
    if (c.lime) r.setProperty("--chalk", c.lime);
    if (c.ink) r.setProperty("--ink", c.ink);
    if (c.henna) r.setProperty("--henna", c.henna);
    if (c.brass) r.setProperty("--brass", c.brass);
    if (c.sand) r.setProperty("--sand", c.sand);
  }, [data]);

  const notify = useCallback((m: string) => {
    setToast(m);
    window.clearTimeout((notify as any)._t);
    (notify as any)._t = window.setTimeout(() => setToast(null), 2600);
  }, []);

  // Load the signed-in customer's favorites. A guest always has an empty list.
  useEffect(() => {
    if (!authReady) return;
    if (!user) {
      setWishlist([]);
      // Drop favorites saved by the old guest-only version of the site.
      try { localStorage.removeItem("nahj.wish"); } catch { /* ignore */ }
      return;
    }
    let alive = true;
    api<{ ids: number[] }>("/api/wishlist")
      .then((r) => { if (alive) setWishlist(Array.isArray(r.ids) ? r.ids : []); })
      .catch(() => { if (alive) setWishlist([]); });
    return () => { alive = false; };
  }, [user, authReady]);

  const toggleWish = useCallback((id: number) => {
    if (!user) {
      notify(lang === "ar" ? "سجّل الدخول لإضافة المنتجات إلى المفضلة." : "Connectez-vous pour ajouter aux favoris.");
      return;
    }
    // Optimistic, then reconcile with the server (and revert if the call fails).
    setWishlist((w) => (w.includes(id) ? w.filter((x) => x !== id) : [...w, id]));
    api<{ wished: boolean }>("/api/wishlist", { method: "POST", json: { productId: id } })
      .then((r) => setWishlist((w) => (r.wished ? (w.includes(id) ? w : [...w, id]) : w.filter((x) => x !== id))))
      .catch(() => setWishlist((w) => (w.includes(id) ? w.filter((x) => x !== id) : [...w, id])));
  }, [user, lang, notify]);

  const value = useMemo<Ctx>(() => ({
    data, products, loading, error, reload,
    cart,
    addToCart: (i) => setCart((c) => {
      const ex = c.find((x) => x.variantId === i.variantId);
      if (ex) return c.map((x) => x.variantId === i.variantId ? { ...x, qty: Math.min(x.qty + i.qty, i.stock) } : x);
      return [...c, { ...i, qty: Math.min(i.qty, i.stock) }];
    }),
    setQty: (id, qty) => setCart((c) => c.map((x) => x.variantId === id ? { ...x, qty: Math.max(1, Math.min(qty, x.stock || 20)) } : x)),
    removeFromCart: (id) => setCart((c) => c.filter((x) => x.variantId !== id)),
    clearCart: () => setCart([]),
    cartOpen, setCartOpen,
    cartCount: cart.reduce((s, i) => s + i.qty, 0),
    wishlist,
    toggleWish,
    lang, setLang, toast, notify,
  }), [data, products, loading, error, reload, cart, cartOpen, wishlist, toggleWish, lang, setLang, toast, notify, setCart]);

  return <StoreCtx.Provider value={value}>{children}</StoreCtx.Provider>;
}
