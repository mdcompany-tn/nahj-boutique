import { useState } from "react";
import { api } from "../api";
import { useLoad, Flash, ImageInput } from "./ui";

const FIELDS: Record<string, [string, string, ("text" | "area" | "image" | "video" | "bool" | "color")?][]> = {
  brand: [["name", "Nom"], ["nameAr", "Nom arabe"], ["tagline", "Slogan"], ["logoImage", "Logo (image)", "image"]],
  hero: [["eyebrow", "Sur-titre"], ["title", "Titre"], ["titleAr", "Titre arabe"], ["subtitle", "Texte", "area"], ["subtitleAr", "Texte arabe", "area"], ["image", "Image", "image"], ["video", "Vidéo de présentation (MP4, 5 Mo max)", "video"], ["primaryLabel", "Bouton 1"], ["primaryLink", "Lien 1"], ["secondaryLabel", "Bouton 2"], ["secondaryLink", "Lien 2"]],
  story: [["title", "Titre"], ["body", "Texte", "area"], ["image", "Image 1", "image"], ["image2", "Image 2", "image"]],
  offer: [["active", "Afficher", "bool"], ["eyebrow", "Sur-titre"], ["title", "Titre"], ["body", "Texte", "area"], ["label", "Bouton"], ["link", "Lien"], ["image", "Image", "image"]],
  about: [["title", "Titre"], ["intro", "Introduction", "area"], ["body", "Texte", "area"], ["image", "Image", "image"]],
  contact: [["phone", "Téléphone"], ["whatsapp", "WhatsApp"], ["email", "Email"], ["address", "Adresse"], ["hours", "Horaires"], ["instagram", "Instagram (URL)"], ["facebook", "Facebook (URL)"], ["tiktok", "TikTok (URL)"]],
  home: [["showNew", "Section Nouveautés", "bool"], ["showBest", "Section Meilleures ventes", "bool"], ["showStory", "Section Histoire", "bool"], ["showOffer", "Section Offre", "bool"], ["showNewsletter", "Newsletter", "bool"]],
};
const TITLES: Record<string, string> = { brand: "Marque", announcements: "Bandeau d’annonces", hero: "Hero", story: "Histoire (accueil)", offer: "Offre", about: "À propos", contact: "Contact", shipping: "Livraison & paiement", home: "Sections de l’accueil" };

export default function Content() {
  const { data, setData, loading } = useLoad<Record<string, any>>("/api/admin/settings", (r) => r.settings, {});
  const [msg, setMsg] = useState("");
  if (loading) return <p>Chargement…</p>;
  const set = (key: string, v: any) => setData({ ...data, [key]: v });
  const save = async (key: string) => {
    try { await api(`/api/admin/settings/${key}`, { method: "PUT", json: data[key] }); setMsg(`✓ ${TITLES[key]} enregistré`); } catch (e) { setMsg((e as Error).message); }
  };
  const ann: any[] = data.announcements || [];
  const brand = data.brand || {};
  return (
    <div>
      <h1>Contenu & marque</h1>
      <Flash msg={msg} />
      <section className="adm-panel adm-form">
        <h2>{TITLES.announcements}</h2>
        {ann.map((a, i) => (
          <div key={a.id} className="adm-grid">
            <label>Texte<input value={a.text} onChange={(e) => set("announcements", ann.map((x, j) => j === i ? { ...x, text: e.target.value } : x))} /></label>
            <label>Texte arabe<input dir="rtl" value={a.textAr || ""} onChange={(e) => set("announcements", ann.map((x, j) => j === i ? { ...x, textAr: e.target.value } : x))} /></label>
            <label>Lien<input value={a.link || ""} onChange={(e) => set("announcements", ann.map((x, j) => j === i ? { ...x, link: e.target.value } : x))} /></label>
            <label className="adm-inline"><input type="checkbox" checked={a.active} onChange={(e) => set("announcements", ann.map((x, j) => j === i ? { ...x, active: e.target.checked } : x))} /> Active <button type="button" className="adm-link danger" onClick={() => set("announcements", ann.filter((_, j) => j !== i))}>Supprimer</button></label>
          </div>
        ))}
        <div className="adm-actions">
          <button className="adm-btn ghost" onClick={() => set("announcements", [...ann, { id: Date.now().toString(36), text: "", textAr: "", link: "", active: true }])}>+ Annonce</button>
          <button className="adm-btn" onClick={() => save("announcements")}>Enregistrer</button>
        </div>
      </section>

      <section className="adm-panel adm-form">
        <h2>Couleurs de la marque</h2>
        <div className="adm-checks">
          {Object.entries({ lime: "Fond", ink: "Encre", henna: "Accent", brass: "Laiton", sand: "Sable" }).map(([k, label]) => (
            <label key={k}>{label} <input type="color" value={brand.colors?.[k] || "#000000"} onChange={(e) => set("brand", { ...brand, colors: { ...brand.colors, [k]: e.target.value } })} /></label>
          ))}
        </div>
        <button className="adm-btn" onClick={() => save("brand")}>Enregistrer les couleurs</button>
      </section>

      {Object.entries(FIELDS).map(([key, fields]) => {
        const v = data[key] || {};
        return (
          <section key={key} className="adm-panel adm-form">
            <h2>{TITLES[key]}</h2>
            {fields.map(([f, label, kind]) => kind === "image" || kind === "video"
              ? <ImageInput key={f} label={label} accept={kind === "video" ? "video/*" : "image/*"} value={v[f] || ""} onChange={(x) => set(key, { ...v, [f]: x })} />
              : kind === "bool" ? <label key={f} className="adm-inline"><input type="checkbox" checked={v[f] !== false} onChange={(e) => set(key, { ...v, [f]: e.target.checked })} /> {label}</label>
              : kind === "area" ? <label key={f}>{label}<textarea rows={3} dir={f.endsWith("Ar") ? "rtl" : undefined} value={v[f] || ""} onChange={(e) => set(key, { ...v, [f]: e.target.value })} /></label>
              : <label key={f}>{label}<input dir={f.endsWith("Ar") ? "rtl" : undefined} value={v[f] || ""} onChange={(e) => set(key, { ...v, [f]: e.target.value })} /></label>)}
            <button className="adm-btn" onClick={() => save(key)}>Enregistrer</button>
          </section>
        );
      })}

      <section className="adm-panel adm-form">
        <h2>{TITLES.shipping}</h2>
        <label>Livraison offerte dès (DT, 0 = jamais)<input type="number" value={data.shipping?.freeThreshold ?? 0} onChange={(e) => set("shipping", { ...data.shipping, freeThreshold: Number(e.target.value) })} /></label>
        <label>Note paiement<textarea rows={2} value={data.shipping?.note || ""} onChange={(e) => set("shipping", { ...data.shipping, note: e.target.value })} /></label>
        <button className="adm-btn" onClick={() => save("shipping")}>Enregistrer</button>
      </section>
    </div>
  );
}
