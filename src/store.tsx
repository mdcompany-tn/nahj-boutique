import { createContext, useCallback, useContext, useEffect, useMemo, useState, type ReactNode } from "react";
import { api, type Product, type StoreData } from "./api";
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
  const [data, setData] = useState<StoreData | null>(null);
  const [products, setProducts] = useState<Product[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [cart, setCart] = useLocal<CartItem[]>("nahj.cart", []);
  const [wishlist, setWishlist] = useLocal<number[]>("nahj.wish", []);
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
    toggleWish: (id) => setWishlist((w) => w.includes(id) ? w.filter((x) => x !== id) : [...w, id]),
    lang, setLang, toast, notify,
  }), [data, products, loading, error, reload, cart, cartOpen, wishlist, lang, toast, notify, setCart, setWishlist, setLang]);

  return <StoreCtx.Provider value={value}>{children}</StoreCtx.Provider>;
}
