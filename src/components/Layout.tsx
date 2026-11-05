import { useEffect, useState } from "react";
import { Link, NavLink, Outlet, useLocation } from "react-router-dom";
import { useStore } from "../store";
import { t } from "../i18n";
import CartDrawer from "./CartDrawer";
import SearchOverlay from "./SearchOverlay";
import Footer from "./Footer";
import Logo from "./Logo";
import { SiteLux } from "./LuxOrnaments";

function Announcements() {
  const { data, lang } = useStore();
  const list = (data?.settings.announcements || []).filter((a: any) => a.active);
  const [i, setI] = useState(0);
  useEffect(() => {
    if (list.length < 2) return;
    const id = setInterval(() => setI((x) => (x + 1) % list.length), 4200);
    return () => clearInterval(id);
  }, [list.length]);
  if (!list.length) {
    // Reserve the bar's height while the store data loads, otherwise the whole
    // page jumps down when the first announcement appears (large layout shift).
    return data ? null : <div className="announce" aria-hidden="true">&nbsp;</div>;
  }
  const a = list[i % list.length];
  const text = lang === "ar" && a.textAr ? a.textAr : a.text;
  return (
    <div className="announce" role="region" aria-label="Annonces">
      <span key={a.id} className="announce-text">{a.link ? <Link to={a.link}>{text}</Link> : text}</span>
    </div>
  );
}

export default function Layout() {
  const { lang, setLang, cartCount, setCartOpen, wishlist, loading, error, reload, toast } = useStore();
  const [menu, setMenu] = useState(false);
  const [search, setSearch] = useState(false);
  const [scrolled, setScrolled] = useState(false);
  const loc = useLocation();
  useEffect(() => setMenu(false), [loc.pathname]);
  useEffect(() => {
    if (!menu) return;
    const prev = document.body.style.overflow;
    document.body.style.overflow = "hidden";
    const onKey = (e: KeyboardEvent) => { if (e.key === "Escape") setMenu(false); };
    window.addEventListener("keydown", onKey);
    return () => { document.body.style.overflow = prev; window.removeEventListener("keydown", onKey); };
  }, [menu]);
  useEffect(() => {
    const on = () => setScrolled(window.scrollY > 40);
    on(); window.addEventListener("scroll", on, { passive: true });
    return () => window.removeEventListener("scroll", on);
  }, []);
  const links: [string, Parameters<typeof t>[1]][] = [["/shop", "shop"], ["/collections", "collections"], ["/new", "new"], ["/best-sellers", "best"], ["/offers", "offers"], ["/about", "about"], ["/contact", "contact"]];

  return (
    <>
      <SiteLux />
      <Announcements />
      <header className={`site-header ${scrolled ? "is-scrolled" : ""} ${loc.pathname === "/" && !scrolled ? "is-over-hero" : ""}`}>
        <button className="icon-btn menu-btn" aria-label="Menu" onClick={() => setMenu(true)}><span className="burger" /></button>
        <Link to="/" className="brand-link" aria-label="NAHJ — Accueil"><Logo /></Link>
        <nav className="main-nav" aria-label="Navigation principale">
          {links.map(([to, k]) => <NavLink key={to} to={to}>{t(lang, k)}</NavLink>)}
        </nav>
        <div className="header-actions">
          <button className="lang-btn" onClick={() => setLang(lang === "fr" ? "ar" : "fr")} aria-label="Langue">{lang === "fr" ? "ع" : "FR"}</button>
          <button className="icon-btn" aria-label={t(lang, "search")} onClick={() => setSearch(true)}>
            <svg viewBox="0 0 24 24"><circle cx="10.5" cy="10.5" r="6.5" /><path d="m20 20-4.8-4.8" /></svg>
          </button>
          <Link className="icon-btn hide-sm" to="/account" aria-label={t(lang, "account")}>
            <svg viewBox="0 0 24 24"><circle cx="12" cy="8" r="4" /><path d="M4 21c1.5-4 4.5-6 8-6s6.5 2 8 6" /></svg>
          </Link>
          <Link className="icon-btn hide-sm" to="/wishlist" aria-label={t(lang, "wishlist")}>
            <svg viewBox="0 0 24 24"><path d="M12 20s-7-4.4-7-10a4 4 0 0 1 7-2.6A4 4 0 0 1 19 10c0 5.6-7 10-7 10Z" /></svg>
            {wishlist.length > 0 && <span className="badge">{wishlist.length}</span>}
          </Link>
          <button className="icon-btn" aria-label={t(lang, "bag")} onClick={() => setCartOpen(true)}>
            <svg viewBox="0 0 24 24"><path d="M5 8h14l-1.2 12H6.2L5 8Z" /><path d="M9 8V6a3 3 0 0 1 6 0v2" /></svg>
            {cartCount > 0 && <span className="badge">{cartCount}</span>}
          </button>
        </div>
      </header>

      <div className={`mm-backdrop ${menu ? "open" : ""}`} onClick={() => setMenu(false)} aria-hidden="true" />
      <aside className={`mobile-menu ${menu ? "open" : ""}`} aria-hidden={!menu} aria-label="Menu">
        <div className="mm-head">
          <Link to="/" className="mm-brand" aria-label="NAHJ — Accueil"><Logo light /></Link>
          <button className="mm-close" onClick={() => setMenu(false)} aria-label="Fermer">
            <svg viewBox="0 0 24 24"><path d="M6 6l12 12M18 6 6 18" /></svg>
          </button>
        </div>
        <nav className="mm-nav" aria-label="Navigation mobile">
          {([["/", "home"], ...links] as [string, Parameters<typeof t>[1]][]).map(([to, k], i) => (
            <NavLink key={to} to={to} end={to === "/"} tabIndex={menu ? 0 : -1}>
              <span className="mm-num">{String(i + 1).padStart(2, "0")}</span>
              <span className="mm-label">{t(lang, k)}</span>
              <span className="mm-arrow" aria-hidden="true">→</span>
            </NavLink>
          ))}
        </nav>
        <div className="mm-quick">
          <Link to="/account" tabIndex={menu ? 0 : -1}>
            <svg viewBox="0 0 24 24"><circle cx="12" cy="8" r="4" /><path d="M4 21c1.5-4 4.5-6 8-6s6.5 2 8 6" /></svg>
            <span>{t(lang, "account")}</span>
          </Link>
          <Link to="/wishlist" tabIndex={menu ? 0 : -1}>
            <svg viewBox="0 0 24 24"><path d="M12 20s-7-4.4-7-10a4 4 0 0 1 7-2.6A4 4 0 0 1 19 10c0 5.6-7 10-7 10Z" /></svg>
            <span>{t(lang, "wishlist")}{wishlist.length > 0 && <b> ({wishlist.length})</b>}</span>
          </Link>
          <Link to="/track" tabIndex={menu ? 0 : -1}>
            <svg viewBox="0 0 24 24"><path d="M3 7h11v9H3zM14 10h4l3 3v3h-7z" /><circle cx="7" cy="18" r="1.6" /><circle cx="17" cy="18" r="1.6" /></svg>
            <span>{t(lang, "track")}</span>
          </Link>
        </div>
        <div className="mm-foot">
          <div className="mm-lang" role="group" aria-label="Langue">
            <button className={lang === "fr" ? "on" : ""} onClick={() => setLang("fr")} tabIndex={menu ? 0 : -1}>Français</button>
            <button className={lang === "ar" ? "on" : ""} onClick={() => setLang("ar")} tabIndex={menu ? 0 : -1}>العربية</button>
          </div>
        </div>
      </aside>

      <main id="main">
        {error && !loading ? (
          <div className="state-block">
            <p className="eyebrow">Connexion interrompue</p>
            <h1 className="display-md">La boutique ne répond pas.</h1>
            <p>{error}</p>
            <button className="btn" onClick={reload}>Réessayer</button>
          </div>
        ) : <Outlet />}
      </main>
      <Footer />
      <CartDrawer />
      {search && <SearchOverlay onClose={() => setSearch(false)} />}
      {toast && <div className="toast" role="status">{toast}</div>}
    </>
  );
}
