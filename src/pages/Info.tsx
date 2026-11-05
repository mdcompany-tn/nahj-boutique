import { useState } from "react";
import { api, img, honeypot } from "../api";
import Honeypot from "../components/Honeypot";
import { useStore } from "../store";

export function About() {
  const { data } = useStore();
  const a = data?.settings.about || {};
  const s = data?.settings.story || {};
  return (
    <div className="about">
      <header className="page-head"><p className="eyebrow">À propos</p><h1 className="display-xl">{a.title}</h1><p className="lead">{a.intro}</p></header>
      <div className="story section">
        <div className="story-imgs">{a.image && <img src={img(a.image, 1000)} alt="" />}</div>
        <div className="story-copy"><p>{a.body}</p><p>{s.body}</p>
          <dl className="stats">{(s.stats || []).map((st: any) => <div key={st.label}><dt>{st.value}</dt><dd>{st.label}</dd></div>)}</dl></div>
      </div>
    </div>
  );
}

export function Contact() {
  const { data } = useStore();
  const c = data?.settings.contact || {};
  const [f, setF] = useState({ name: "", email: "", phone: "", subject: "", body: "" });
  const [state, setState] = useState<"idle" | "busy" | "done" | "error">("idle");
  const submit = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault(); setState("busy");
    try { await api("/api/contact", { method: "POST", json: { ...f, website: honeypot(e) } }); setState("done"); } catch { setState("error"); }
  };
  const set = (k: keyof typeof f) => (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) => setF({ ...f, [k]: e.target.value });
  return (
    <div className="contact">
      <header className="page-head"><p className="eyebrow">Contact</p><h1 className="display-xl">Parlons-en.</h1></header>
      <div className="checkout-grid">
        {state === "done" ? <p className="ok">Merci, votre message est bien arrivé. Nous répondons sous 24 h.</p> : (
          <form className="co-form" onSubmit={submit}>
            <Honeypot />
            <label>Nom<input required minLength={2} value={f.name} onChange={set("name")} /></label>
            <div className="two"><label>Email<input type="email" value={f.email} onChange={set("email")} /></label><label>Téléphone<input value={f.phone} onChange={set("phone")} /></label></div>
            <label>Sujet<input value={f.subject} onChange={set("subject")} /></label>
            <label>Message<textarea required minLength={5} rows={5} value={f.body} onChange={set("body")} /></label>
            {state === "error" && <p className="err">Envoi impossible, vérifiez les champs.</p>}
            <button className="btn" disabled={state === "busy"}>Envoyer</button>
          </form>
        )}
        <aside className="co-summary">
          {c.phone && <p><b>Téléphone</b><br /><a href={`tel:${c.phone.replace(/\s/g, "")}`}>{c.phone}</a></p>}
          {c.whatsapp && <p><b>WhatsApp</b><br /><a href={`https://wa.me/${c.whatsapp.replace(/\D/g, "")}`}>{c.whatsapp}</a></p>}
          {c.email && <p><b>Email</b><br /><a href={`mailto:${c.email}`}>{c.email}</a></p>}
          {c.address && <p><b>Adresse</b><br />{c.address}</p>}
          {c.hours && <p><b>Horaires</b><br />{c.hours}</p>}
        </aside>
      </div>
    </div>
  );
}
