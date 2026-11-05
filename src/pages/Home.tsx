import { useEffect, useRef, useState } from "react";
import { Link } from "react-router-dom";
import { useStore } from "../store";
import { asset, img } from "../api";
import { t } from "../i18n";
import ProductCard from "../components/ProductCard";
import { Newsletter } from "../components/Footer";
import { LuxOrnaments } from "../components/LuxOrnaments";

/** Featured rail: a looping track that drifts slowly left-to-right by itself, with arrows and drag. Pauses on hover. */
function FeaturedRail({ products }: { products: any[] }) {
  const track = useRef<HTMLDivElement>(null);
  const off = useRef(0); // current translateX (px), kept in [-half, 0)
  const target = useRef<number | null>(null); // arrow-driven destination
  const hover = useRef(false);
  const drag = useRef<{ x: number; o: number } | null>(null);
  const hold = useRef(0);
  const loop = products.length > 0;
  // Repeat the list so the track is always wider than the screen and loops seamlessly.
  const reps = Math.max(2, Math.ceil(12 / Math.max(1, products.length)) * 2);
  const items = Array.from({ length: reps }, () => products).flat();

  useEffect(() => {
    const el = track.current;
    if (!el || !loop) return;
    const period = () => el.scrollWidth / 2; // width of half the repeated items
    off.current = -period();
    let raf = 0, last = performance.now();
    const step = (now: number) => {
      const dt = Math.min(now - last, 64); last = now;
      const P = period();
      if (target.current !== null) {
        const d = target.current - off.current;
        off.current += d * Math.min(1, dt / 120);
        if (Math.abs(d) < 0.5) { off.current = target.current; target.current = null; }
      } else if (!drag.current && now > hold.current) {
        // Always drift slowly to the right; just slow down (never stop) while hovered.
        off.current += dt * (hover.current ? 0.012 : 0.035);
      }
      if (P > 0) {
        while (off.current >= 0) { off.current -= P; if (target.current !== null) target.current -= P; }
        while (off.current < -P) { off.current += P; if (target.current !== null) target.current += P; }
      }
      el.style.transform = `translate3d(${off.current}px,0,0)`;
      raf = requestAnimationFrame(step);
    };
    raf = requestAnimationFrame(step);
    return () => cancelAnimationFrame(raf);
  }, [loop, products.length]);

  const go = (dir: 1 | -1) => {
    const card = track.current?.querySelector<HTMLElement>(".rail-item");
    const w = card ? card.offsetWidth + 19 : 300;
    target.current = (target.current ?? off.current) - dir * w;
    hold.current = performance.now() + 2500;
  };

  return (
    <div className="rail-wrap" onMouseEnter={() => (hover.current = true)} onMouseLeave={() => { hover.current = false; drag.current = null; }}>
      <button type="button" className="rail-arrow prev" onClick={() => go(-1)} aria-label="Précédent">
        <svg viewBox="0 0 24 24"><path d="M15 5l-7 7 7 7" /></svg>
      </button>
      <div className="rail-viewport" dir="ltr"
        onPointerDown={(e) => { if (e.pointerType !== "mouse") { drag.current = { x: e.clientX, o: off.current }; target.current = null; } }}
        onPointerMove={(e) => { if (drag.current) off.current = drag.current.o + (e.clientX - drag.current.x); }}
        onPointerUp={() => { if (drag.current) { drag.current = null; hold.current = performance.now() + 3000; } }}
        onPointerCancel={() => { drag.current = null; hold.current = performance.now() + 3000; }}>
        <div className="rail-track" ref={track}>
          {items.map((p, i) => (
            <div key={`${p.id}-${i}`} className="rail-item" aria-hidden={i >= products.length || undefined}>
              <ProductCard p={p} index={i % products.length} />
            </div>
          ))}
        </div>
      </div>
      <button type="button" className="rail-arrow next" onClick={() => go(1)} aria-label="Suivant">
        <svg viewBox="0 0 24 24"><path d="M9 5l7 7-7 7" /></svg>
      </button>
    </div>
  );
}

/** Presentation card over the hero: plays the admin-uploaded video, or a moving photo reel until one is uploaded. */
function HeroReel({ video, poster, photos, ar }: { video?: string; poster?: string; photos: string[]; ar: boolean }) {
  const [open, setOpen] = useState(false);
  const [i, setI] = useState(0);
  useEffect(() => {
    if (video || photos.length < 2) return;
    const t = setInterval(() => setI((x) => (x + 1) % photos.length), 3200);
    return () => clearInterval(t);
  }, [video, photos.length]);
  useEffect(() => {
    if (!open) return;
    const k = (e: KeyboardEvent) => e.key === "Escape" && setOpen(false);
    window.addEventListener("keydown", k);
    return () => window.removeEventListener("keydown", k);
  }, [open]);
  if (!video && photos.length === 0) return null;
  return (
    <>
      <button type="button" className="hero-reel rise" style={{ animationDelay: "650ms" }} onClick={() => video && setOpen(true)} aria-label={video ? (ar ? "شاهد الفيديو" : "Voir la vidéo") : undefined} disabled={!video}>
        <span className="hero-reel-media">
          {video
            ? <video src={asset(video)} poster={asset(poster)} autoPlay muted loop playsInline preload="metadata" />
            : photos.map((src, k) => <img key={src} src={img(src, 600)} alt="" className={k === i ? "on" : ""} />)}
        </span>
        <span className="hero-reel-cap">
          {video && <span className="hero-reel-play" aria-hidden="true"><svg viewBox="0 0 24 24"><path d="M8 5v14l11-7z" /></svg></span>}
          <span><small>{ar ? "تقديم" : "Présentation"}</small><b>{video ? (ar ? "شاهد الفيديو" : "Voir la vidéo") : (ar ? "المجموعة" : "La collection")}</b></span>
        </span>
      </button>
      {open && video && (
        <div className="video-modal" role="dialog" aria-modal="true" onClick={() => setOpen(false)}>
          <button type="button" className="video-modal-close" aria-label="Fermer" onClick={() => setOpen(false)}>×</button>
          <video src={asset(video)} poster={asset(poster)} controls autoPlay playsInline onClick={(e) => e.stopPropagation()} />
        </div>
      )}
    </>
  );
}

function Skeleton() {
  return <div className="hero hero-skeleton" aria-busy="true" />;
}

export default function Home() {
  const { data, products, loading, lang } = useStore();
  if (loading && !data) return <Skeleton />;
  if (!data) return null;
  const s = data.settings;
  const hero = s.hero || {};
  const home = s.home || {};
  const ar = lang === "ar";
  const featuredIds: number[] = home.featuredIds || [];
  const featured = featuredIds.length ? featuredIds.map((id) => products.find((p) => p.id === id)!).filter(Boolean) : products.filter((p) => p.featured);
  const fresh = products.filter((p) => p.is_new).slice(0, 4);
  const best = [...products].sort((a, b) => b.sold - a.sold || Number(b.featured) - Number(a.featured)).slice(0, 4);
  const cols = data.collections;

  return (
    <div className="home">
      <section className="hero">
        <div className="hero-media">
          <img className="hero-backdrop" src={img(hero.image, 1800)} alt="" aria-hidden="true" />
          <div className="hero-live">
            <img src={img(hero.image, 1800)} alt="" fetchPriority="high" />
          </div>
          <span className="hero-sun" />
          <span className="hero-shade" />
          <span className="hero-petals">
            {Array.from({ length: 12 }, (_, i) => <i key={i} />)}
          </span>
        </div>
        <div className="hero-copy">
          {hero.eyebrow && <p className="eyebrow rise" style={{ animationDelay: "100ms" }}>{hero.eyebrow}</p>}
          <h1 className="display-xl rise" style={{ animationDelay: "220ms" }}>{ar && hero.titleAr ? hero.titleAr : hero.title}</h1>
          <p className="hero-sub rise" style={{ animationDelay: "380ms" }}>{ar && hero.subtitleAr ? hero.subtitleAr : hero.subtitle}</p>
          <div className="hero-ctas rise" style={{ animationDelay: "520ms" }}>
            {hero.primaryLabel && <Link to={hero.primaryLink || "/shop"} className="btn btn-light">{hero.primaryLabel}</Link>}
            {hero.secondaryLabel && <Link to={hero.secondaryLink || "/collections"} className="btn btn-ghost-light">{hero.secondaryLabel}</Link>}
          </div>
        </div>
        <HeroReel video={hero.video} poster={hero.image} ar={ar} photos={Array.from(new Set(products.map((p) => p.images[0]).filter(Boolean))).slice(0, 6)} />
        <div className="hero-plate" aria-hidden="true">
          <span>نهج</span><small>Rue · 1956</small>
        </div>
      </section>

      {cols.length > 0 && (
        <section className="section collections-mosaic">
          <div className="section-head">
            <p className="eyebrow">Les collections</p>
            <h2 className="display-lg">Quatre rues,<br /><em>quatre humeurs.</em></h2>
            <Link to="/collections" className="link-arrow">{t(lang, "viewAll")}</Link>
          </div>
          <div className="mosaic">
            {cols.slice(0, 4).map((c, i) => (
              <Link key={c.id} to={`/collections/${c.slug}`} className={`mosaic-tile tile-${i}`}>
                <img src={img(c.image, 900)} alt="" loading="lazy" />
                <span className="tile-copy">
                  <small>{c.tagline}</small>
                  <b>{ar && c.name_ar ? c.name_ar : c.name}</b>
                  <em>{c.product_count} pièces →</em>
                </span>
              </Link>
            ))}
          </div>
        </section>
      )}

      {home.showNew !== false && fresh.length > 0 && (
        <section className="section">
          <div className="section-head row-head">
            <div><p className="eyebrow">Sortie d’atelier</p><h2 className="display-lg">{t(lang, "new")}</h2></div>
            <Link to="/new" className="link-arrow">{t(lang, "viewAll")}</Link>
          </div>
          <div className="grid-4">{fresh.map((p, i) => <ProductCard key={p.id} p={p} index={i} />)}</div>
        </section>
      )}

      {featured.length > 0 && (
        <section className="section featured-band">
          <div className="lux-bg" aria-hidden="true"><span className="orb o1" /><span className="orb o2" /><span className="orb o3" /><span className="lux-sheen" /><span className="lux-border top" /><span className="lux-border bottom" /><LuxOrnaments /></div>
          <div className="section-head">
            <p className="eyebrow">Sélection de la maison</p>
            <h2 className="display-lg">Les pièces <em>qu’on porte</em> nous-mêmes.</h2>
          </div>
          <FeaturedRail products={featured} />
        </section>
      )}

      {home.showStory !== false && s.story && (
        <section className="section story">
          <div className="story-imgs">
            <img src={img(s.story.image, 1000)} alt="" loading="lazy" className="story-a" />
            {s.story.image2 && <img src={img(s.story.image2, 800)} alt="" loading="lazy" className="story-b" />}
          </div>
          <div className="story-copy">
            <p className="eyebrow">Notre histoire</p>
            <h2 className="display-lg">{s.story.title}</h2>
            <p>{s.story.body}</p>
            <dl className="stats">
              {(s.story.stats || []).map((st: any) => <div key={st.label}><dt>{st.value}</dt><dd>{st.label}</dd></div>)}
            </dl>
            <Link to="/about" className="link-arrow">Lire la suite</Link>
          </div>
        </section>
      )}

      {home.showBest !== false && best.length > 0 && (
        <section className="section">
          <div className="section-head row-head">
            <div><p className="eyebrow">Ce que Tunis porte</p><h2 className="display-lg">{t(lang, "best")}</h2></div>
            <Link to="/best-sellers" className="link-arrow">{t(lang, "viewAll")}</Link>
          </div>
          <div className="grid-4">{best.map((p, i) => <ProductCard key={p.id} p={p} index={i} />)}</div>
        </section>
      )}

      {home.showOffer !== false && s.offer?.active && (
        <section className="offer-band">
          <img src={img(s.offer.image, 1400)} alt="" loading="lazy" />
          <div className="offer-copy">
            <p className="eyebrow">{s.offer.eyebrow}</p>
            <h2 className="display-lg">{s.offer.title}</h2>
            <p>{s.offer.body}</p>
            <Link to={s.offer.link || "/offers"} className="btn btn-light">{s.offer.label || "Voir"}</Link>
          </div>
        </section>
      )}

      <section className="promise">
        <div><b>Paiement à la livraison</b><span>Vous payez en espèces à la réception.</span></div>
        <div><b>24 gouvernorats</b><span>De Bizerte à Tataouine, 24 à 72 h.</span></div>
        <div><b>Échange 7 jours</b><span>Taille ou couleur, on s’arrange.</span></div>
        <div><b>Fait en Tunisie</b><span>Ateliers de Tunis, Nabeul et Ksar Hellal.</span></div>
      </section>

      {home.showNewsletter !== false && <Newsletter />}
    </div>
  );
}
