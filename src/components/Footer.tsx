import { useState } from "react";
import { Link } from "react-router-dom";
import { api, honeypot } from "../api";
import Honeypot from "./Honeypot";
import { useStore } from "../store";
import { t } from "../i18n";
import Logo from "./Logo";

export function Newsletter() {
  const { lang } = useStore();
  const [email, setEmail] = useState("");
  const [state, setState] = useState<"idle" | "busy" | "done" | "error">("idle");
  const submit = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    setState("busy");
    try { await api("/api/newsletter", { method: "POST", json: { email, website: honeypot(e) } }); setState("done"); setEmail(""); }
    catch { setState("error"); }
  };
  return (
    <section className="newsletter">
      <p className="eyebrow">{t(lang, "newsletter")}</p>
      <h2 className="display-md">Les sorties d’atelier, avant tout le monde.</h2>
      {state === "done" ? <p className="ok">Merci, vous êtes inscrit·e. À très vite dans votre boîte.</p> : (
        <form onSubmit={submit} className="nl-form">
          <Honeypot />
          <input type="email" required value={email} onChange={(e) => setEmail(e.target.value)} placeholder="votre@email.tn" aria-label="Adresse email" />
          <button className="btn btn-light" disabled={state === "busy"}>{t(lang, "subscribe")}</button>
        </form>
      )}
      {state === "error" && <p className="err">Adresse invalide, réessayez.</p>}
    </section>
  );
}

export default function Footer() {
  const { data, lang } = useStore();
  const c = data?.settings.contact || {};
  return (
    <footer className="site-footer">
      <div className="footer-grid">
        <div className="footer-brand">
          <Logo light />
          <p>{data?.settings.brand?.tagline}</p>
          <p className="cod-pill">{t(lang, "cod")} · 24 gouvernorats</p>
        </div>
        <div>
          <h4>Boutique</h4>
          <Link to="/shop">Tout voir</Link><Link to="/new">Nouveautés</Link><Link to="/best-sellers">Meilleures ventes</Link><Link to="/offers">Offres</Link><Link to="/collections">Collections</Link>
        </div>
        <div>
          <h4>Aide</h4>
          <Link to="/track">Suivre une commande</Link><Link to="/contact">Contact</Link><Link to="/about">Notre histoire</Link><Link to="/account">Mon compte</Link>
        </div>
        <div>
          <h4>Nous joindre</h4>
          {c.phone && <a href={`tel:${c.phone.replace(/\s/g, "")}`}>{c.phone}</a>}
          {c.email && <a href={`mailto:${c.email}`}>{c.email}</a>}
          {c.address && <span>{c.address}</span>}
          {c.hours && <span>{c.hours}</span>}
          <div className="socials">
            {c.instagram && <a href={c.instagram} target="_blank" rel="noreferrer">Instagram</a>}
            {c.facebook && <a href={c.facebook} target="_blank" rel="noreferrer">Facebook</a>}
            {c.tiktok && <a href={c.tiktok} target="_blank" rel="noreferrer">TikTok</a>}
          </div>
        </div>
      </div>
      <div className="footer-base">
        <span>© {new Date().getFullYear()} {data?.settings.brand?.name || "NAHJ"} — Tunis</span>
        <span className="footer-ar">الاستقامة والجمال</span>
      </div>
    </footer>
  );
}
