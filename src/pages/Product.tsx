import { useEffect, useMemo, useState } from "react";
import { Link, useNavigate, useParams } from "react-router-dom";
import Honeypot from "../components/Honeypot";
import { api, img as cdn, honeypot, money, colorImage as imageFor, productColors, type Product } from "../api";
import { useStore } from "../store";
import { useAuth } from "../auth";
import { t } from "../i18n";
import ProductCard from "../components/ProductCard";
import NotFound from "./NotFound";

type Review = { id: number; name: string; rating: number; body: string; created_at: string };

function Stars({ n, size = "" }: { n: number; size?: string }) {
  const full = Math.round(n);
  return <span className={`stars ${size}`} aria-label={`${n.toFixed(1)} sur 5`}>{"★★★★★".slice(0, full)}<i>{"★★★★★".slice(full)}</i></span>;
}

const AVATAR_TONES = ["#9C3B26", "#14224A", "#B08A4E", "#3F6B5A", "#6B4C7A"];
function ReviewCard({ r }: { r: Review }) {
  const initials = r.name.trim().split(/\s+/).map((w) => w[0]).slice(0, 2).join("").toUpperCase();
  const tone = AVATAR_TONES[r.name.length % AVATAR_TONES.length];
  return (
    <article className="review-card">
      <header>
        <span className="avatar" style={{ background: tone }} aria-hidden>{initials}</span>
        <div>
          <b>{r.name}</b>
          <small>{new Date(r.created_at).toLocaleDateString("fr-TN", { day: "numeric", month: "long", year: "numeric" })}</small>
        </div>
        <Stars n={r.rating} />
      </header>
      {r.body ? <p>{r.body}</p> : <p className="muted">Note sans commentaire.</p>}
    </article>
  );
}

function ReviewSummary({ reviews }: { reviews: Review[] }) {
  const avg = reviews.reduce((s, r) => s + r.rating, 0) / reviews.length;
  return (
    <div className="review-summary">
      <div className="review-score"><b>{avg.toFixed(1)}</b><Stars n={avg} size="lg" /><small>{reviews.length} avis</small></div>
      <ul>
        {[5, 4, 3, 2, 1].map((n) => {
          const c = reviews.filter((r) => r.rating === n).length;
          return <li key={n}><span>{n} ★</span><span className="bar"><i style={{ width: `${(c / reviews.length) * 100}%` }} /></span><span>{c}</span></li>;
        })}
      </ul>
    </div>
  );
}

function ReviewForm({ productId }: { productId: number }) {
  const [f, setF] = useState({ name: "", rating: 5, body: "" });
  const [state, setState] = useState<"idle" | "busy" | "done" | "error">("idle");
  const submit = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault(); setState("busy");
    try { await api("/api/reviews", { method: "POST", json: { productId, ...f, website: honeypot(e) } }); setState("done"); } catch { setState("error"); }
  };
  if (state === "done") return <p className="ok">Merci ! Votre avis sera publié après relecture.</p>;
  return (
    <form className="review-form" onSubmit={submit}>
      <Honeypot />
      <h3>Donnez votre avis</h3>
      <div className="rating-pick" role="radiogroup" aria-label="Note">
        {[1, 2, 3, 4, 5].map((n) => <button type="button" key={n} className={n <= f.rating ? "on" : ""} onClick={() => setF({ ...f, rating: n })} aria-label={`${n} étoiles`}>★</button>)}
      </div>
      <input required minLength={2} placeholder="Votre prénom" value={f.name} onChange={(e) => setF({ ...f, name: e.target.value })} />
      <textarea placeholder="Votre avis (taille, matière, coupe…)" value={f.body} onChange={(e) => setF({ ...f, body: e.target.value })} rows={3} />
      <button className="btn btn-outline" disabled={state === "busy"}>Publier mon avis</button>
      {state === "error" && <p className="err">Impossible d’envoyer l’avis.</p>}
    </form>
  );
}

export default function ProductPage() {
  const { slug } = useParams();
  const { addToCart, setCartOpen, wishlist, toggleWish, lang, notify } = useStore();
  const { user } = useAuth();
  const navigate = useNavigate();
  // Favorites require an account: guests are sent to the login page.
  const onWish = (id: number) => { if (user) toggleWish(id); else navigate("/account"); };
  const [res, setRes] = useState<{ product: Product; reviews: Review[]; related: Product[] } | null>(null);
  const [missing, setMissing] = useState(false);
  const [color, setColor] = useState("");
  const [size, setSize] = useState("");
  const [qty, setQty] = useState(1);
  const [img, setImg] = useState(0);
  const [err, setErr] = useState("");

  useEffect(() => {
    setRes(null); setMissing(false); setImg(0); setQty(1); setErr("");
    api(`/api/products/${slug}`).then((r) => {
      setRes(r);
      const first = r.product.variants.find((v: any) => v.stock > 0) || r.product.variants[0];
      setColor(first?.color || "");
      const ci = first ? imageFor(r.product, first.color) : "";
      if (ci) { const imgs = [...r.product.images, ...r.product.variants.map((v: any) => v.image).filter((x: string) => x && !r.product.images.includes(x))]; setImg(Math.max(0, imgs.indexOf(ci))); }
      setSize(r.product.variants.length === 1 ? first?.size : "");
    }).catch(() => setMissing(true));
  }, [slug]);

  const p = res?.product;
  const colors = useMemo(() => p ? productColors(p) : [], [p]);
  const sizes = useMemo(() => p ? p.variants.filter((v) => v.color === color) : [], [p, color]);
  const variant = p?.variants.find((v) => v.color === color && v.size === size);
  const colorImage = (c: string) => (p ? imageFor(p, c) : "");
  const gallery = useMemo(() => {
    if (!p) return [] as string[];
    const extra = p.variants.map((v) => v.image).filter((x): x is string => !!x && !p.images.includes(x));
    return [...p.images, ...new Set(extra)];
  }, [p]);
  const pickColor = (c: string) => {
    setColor(c);
    const ci = colorImage(c);
    if (ci) setImg(Math.max(0, gallery.indexOf(ci)));
  };

  if (missing) return <NotFound />;
  if (!p) return <div className="pdp skeleton-pdp" aria-busy="true"><div className="skeleton" /><div /></div>;

  const ar = lang === "ar";
  const onSale = p.compare_at_price && p.compare_at_price > p.price;
  const avg = res!.reviews.length ? res!.reviews.reduce((s, r) => s + r.rating, 0) / res!.reviews.length : 0;
  const wished = wishlist.includes(p.id);

  const add = () => {
    if (!variant) { setErr("Choisissez une taille"); return; }
    if (variant.stock < 1) return;
    addToCart({ variantId: variant.id, productId: p.id, slug: p.slug, name: p.name, size: variant.size, color: variant.color, image: colorImage(variant.color) || p.images[0], price: p.price, qty, stock: variant.stock });
    notify(`${p.name} ajouté au panier`);
    setCartOpen(true);
  };

  return (
    <div className="pdp-wrap">
      <nav className="crumbs"><Link to="/shop">Boutique</Link> / <span>{p.category}</span></nav>
      <div className="pdp">
        <div className="gallery">
          <div className="gallery-main"><img key={gallery[img]} className="fade-in" src={cdn(gallery[img] || gallery[0], 1200)} alt={`${p.name}${color ? " – " + color : ""}`} /></div>
          {gallery.length > 1 && (
            <div className="thumbs">{gallery.map((src, i) => <button key={src} className={i === img ? "on" : ""} onClick={() => setImg(i)}><img src={cdn(src, 200)} alt="" loading="lazy" /></button>)}</div>
          )}
        </div>
        <div className="buybox">
          <p className="eyebrow">{p.category}{p.is_new ? " · Nouveau" : ""}</p>
          <h1 className="display-lg">{ar && p.name_ar ? p.name_ar : p.name}</h1>
          {!ar && p.name_ar && <p className="name-ar">{p.name_ar}</p>}
          <p className="price-lg">{onSale && <s>{money(p.compare_at_price!)}</s>}<span>{money(p.price)}</span></p>
          {res!.reviews.length > 0 && <a href="#avis" className="rating-link"><Stars n={avg} /> <b>{avg.toFixed(1)}</b> · {res!.reviews.length} avis</a>}
          <p className="desc">{ar && p.description_ar ? p.description_ar : p.description}</p>

          {colors.length > 0 && colors[0][0] && (
            <div className="opt">
              <p className="opt-label">{t(lang, "color")} : <b>{color}</b></p>
              <div className="color-pick">
                {colors.map(([c, hex]) => (
                  <button key={c} className={c === color ? "on" : ""} onClick={() => { pickColor(c); setSize(p.variants.filter((v) => v.color === c).length === 1 ? p.variants.find((v) => v.color === c)!.size : ""); setErr(""); }} title={c} aria-label={c}>
                    <span style={{ background: hex || "#ccc" }} />
                  </button>
                ))}
              </div>
            </div>
          )}
          {!(sizes.length === 1 && sizes[0].size === "Unique") && (
            <div className="opt">
              <p className="opt-label">{t(lang, "size")}{size ? <> : <b>{size}</b></> : ""}</p>
              <div className="size-pick">
                {sizes.map((v) => (
                  <button key={v.id} disabled={v.stock < 1} className={v.size === size ? "on" : ""} onClick={() => { setSize(v.size); setErr(""); setQty(1); }}>{v.size}</button>
                ))}
              </div>
            </div>
          )}
          {variant && variant.stock > 0 && variant.stock <= 3 && <p className="low">{t(lang, "lowStock")} {variant.stock} {t(lang, "pieces")}</p>}
          {err && <p className="err">{err}</p>}
          <div className="buy-row">
            <div className="qty big">
              <button onClick={() => setQty(Math.max(1, qty - 1))} aria-label="Moins">−</button>
              <span>{qty}</span>
              <button onClick={() => setQty(Math.min(variant?.stock || 1, qty + 1))} aria-label="Plus">+</button>
            </div>
            <button className="btn btn-grow" onClick={add} disabled={!!variant && variant.stock < 1}>
              {variant && variant.stock < 1 ? t(lang, "soldOut") : t(lang, "addToBag")}
            </button>
            <button className={`wish-lg ${wished ? "on" : ""}`} onClick={() => onWish(p.id)} aria-label="Favori" aria-pressed={wished}>
              <svg viewBox="0 0 24 24"><path d="M12 20s-7-4.4-7-10a4 4 0 0 1 7-2.6A4 4 0 0 1 19 10c0 5.6-7 10-7 10Z" /></svg>
            </button>
          </div>
          <ul className="assurances">
            <li>Paiement en espèces à la livraison</li>
            <li>Livraison 24 – 72 h dans les 24 gouvernorats</li>
            <li>Échange sous 7 jours</li>
          </ul>
          {p.details && <details open><summary>Matières & coupe</summary><p>{p.details}</p></details>}
          {p.care && <details><summary>Entretien</summary><p>{p.care}</p></details>}
        </div>
      </div>

      <section className="section reviews" id="avis">
        <div className="section-head"><p className="eyebrow">Avis clients</p><h2 className="display-md">Ce qu’ils en disent</h2></div>
        <div className="reviews-grid">
          <div className="reviews-list">
            {res!.reviews.length === 0 ? <p className="reviews-empty">Pas encore d’avis. Soyez le premier à partager le vôtre.</p> : <>
              <ReviewSummary reviews={res!.reviews} />
              {res!.reviews.map((r) => <ReviewCard key={r.id} r={r} />)}
            </>}
          </div>
          <ReviewForm productId={p.id} />
        </div>
      </section>

      {res!.related.length > 0 && (
        <section className="section">
          <div className="section-head"><p className="eyebrow">À porter avec</p><h2 className="display-md">Vous aimerez aussi</h2></div>
          <div className="grid-4">{res!.related.map((r, i) => <ProductCard key={r.id} p={r} index={i} />)}</div>
        </section>
      )}
    </div>
  );
}
