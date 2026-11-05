import { useEffect, useState } from "react";
import { NavLink, Route, Routes, Link } from "react-router-dom";
import type { User } from "@supabase/supabase-js";
import { api, sitePath } from "../api";
import { supabase } from "../supabase";
import Dashboard from "./Dashboard";
import Orders from "./Orders";
import Products from "./Products";
import Stock from "./Stock";
import Accounting from "./Accounting";
import Collections from "./Collections";
import Content from "./Content";
import { Zones, Codes, Reviews, Messages, Subscribers } from "./Misc";
import "./admin.css";

function authMessage(message: string): string {
  if (/invalid login credentials/i.test(message)) return "Email ou mot de passe incorrect.";
  if (/email not confirmed/i.test(message)) return "Email pas encore confirmé. Ouvrez le lien reçu par email.";
  if (/rate limit|too many/i.test(message)) return "Trop de tentatives. Réessayez dans quelques minutes.";
  return message;
}

function AuthScreen({ onUser }: { onUser: (u: User) => void }) {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [msg, setMsg] = useState("");
  const [busy, setBusy] = useState(false);

  const submit = async (e: React.FormEvent) => {
    e.preventDefault(); setMsg(""); setBusy(true);
    try {
      const { data, error } = await supabase.auth.signInWithPassword({ email: email.trim(), password });
      if (error) throw error;
      if (data.user) onUser(data.user);
    } catch (x) {
      setMsg(authMessage((x as Error).message));
    } finally {
      setBusy(false);
    }
  };

  const forgot = async () => {
    setMsg("");
    if (!email.trim()) { setMsg("Entrez d'abord votre email."); return; }
    const { error } = await supabase.auth.resetPasswordForEmail(email.trim(), {
      redirectTo: `${window.location.origin}${sitePath("admin")}`,
    });
    setMsg(error ? authMessage(error.message) : "Email de réinitialisation envoyé. Ouvrez le lien reçu.");
  };

  return (
    <div className="adm-auth">
      <form onSubmit={submit} className="adm-card">
        <p className="adm-brand">NAHJ <span>نهج</span></p>
        <h1>Espace administrateur</h1>
        <label>Email<input type="email" autoComplete="username" required value={email} onChange={(e) => setEmail(e.target.value)} /></label>
        <label>Mot de passe<input type="password" autoComplete="current-password" required value={password} onChange={(e) => setPassword(e.target.value)} /></label>
        {msg && <p className={msg.startsWith("Email de réinitialisation") ? "adm-ok" : "adm-err"}>{msg}</p>}
        <button className="adm-btn" disabled={busy}>{busy ? "Connexion…" : "Se connecter"}</button>
        <button type="button" className="adm-link" onClick={forgot}>Mot de passe oublié</button>
        <Link to="/" className="adm-link">← Retour à la boutique</Link>
      </form>
    </div>
  );
}

function NewPasswordScreen({ onDone }: { onDone: () => void }) {
  const [password, setPassword] = useState("");
  const [confirm, setConfirm] = useState("");
  const [msg, setMsg] = useState("");
  const [busy, setBusy] = useState(false);

  const submit = async (e: React.FormEvent) => {
    e.preventDefault(); setMsg("");
    if (password.length < 8) { setMsg("8 caractères minimum."); return; }
    if (password !== confirm) { setMsg("Les deux mots de passe ne correspondent pas."); return; }
    setBusy(true);
    const { error } = await supabase.auth.updateUser({ password });
    setBusy(false);
    if (error) setMsg(authMessage(error.message));
    else { setMsg("Mot de passe mis à jour."); setTimeout(onDone, 800); }
  };

  return (
    <div className="adm-auth">
      <form onSubmit={submit} className="adm-card">
        <p className="adm-brand">NAHJ <span>نهج</span></p>
        <h1>Nouveau mot de passe</h1>
        <label>Mot de passe<input type="password" autoComplete="new-password" required value={password} onChange={(e) => setPassword(e.target.value)} /></label>
        <label>Confirmer<input type="password" autoComplete="new-password" required value={confirm} onChange={(e) => setConfirm(e.target.value)} /></label>
        {msg && <p className={msg.startsWith("Mot de passe mis") ? "adm-ok" : "adm-err"}>{msg}</p>}
        <button className="adm-btn" disabled={busy}>{busy ? "Enregistrement…" : "Valider"}</button>
      </form>
    </div>
  );
}

const NAV: [string, string][] = [["", "Tableau de bord"], ["orders", "Commandes"], ["products", "Produits"], ["stock", "Stock"], ["accounting", "Comptabilité"], ["collections", "Collections"], ["content", "Contenu & marque"],
  ["zones", "Livraison"], ["codes", "Codes promo"], ["reviews", "Avis"], ["messages", "Messages"], ["subscribers", "Abonnés"]];

export default function Admin() {
  const [user, setUser] = useState<User | null>(null);
  const [ready, setReady] = useState(false);
  const [access, setAccess] = useState<"unknown" | "ok" | "denied">("unknown");
  const [recovery, setRecovery] = useState(false);
  const [open, setOpen] = useState(false);

  useEffect(() => { document.documentElement.dir = "ltr"; }, []);

  useEffect(() => {
    let alive = true;
    supabase.auth.getSession().then(({ data }) => {
      if (!alive) return;
      setUser(data.session?.user ?? null);
      setReady(true);
    });
    const { data } = supabase.auth.onAuthStateChange((event, session) => {
      if (event === "PASSWORD_RECOVERY") setRecovery(true);
      if (event === "SIGNED_OUT") setUser(null);
      else if (session?.user) setUser(session.user);
    });
    return () => { alive = false; data.subscription.unsubscribe(); };
  }, []);

  useEffect(() => {
    if (!user) { setAccess("unknown"); return; }
    if (recovery) return;
    let alive = true;
    setAccess("unknown");
    api("/api/admin/me")
      .then(() => { if (alive) setAccess("ok"); })
      .catch(() => { if (alive) setAccess("denied"); });
    return () => { alive = false; };
  }, [user, recovery]);

  const signOut = async () => {
    await supabase.auth.signOut();
    setUser(null);
    setAccess("unknown");
    setRecovery(false);
  };

  if (!ready) return <div className="admin-loading">Chargement…</div>;
  if (recovery && user) return <NewPasswordScreen onDone={() => setRecovery(false)} />;
  if (!user) return <AuthScreen onUser={setUser} />;
  if (access === "unknown") return <div className="admin-loading">Vérification des droits…</div>;
  if (access === "denied") return (
    <div className="adm-auth"><div className="adm-card">
      <h1>Accès refusé</h1>
      <p>Le compte {user.email} n’est pas administrateur. Seul l’email propriétaire, autorisé dans la table <code>admin_emails</code> du projet Supabase, peut accéder à l’administration.</p>
      <button className="adm-btn" onClick={signOut}>Se déconnecter</button>
    </div></div>
  );

  return (
    <div className="adm">
      <aside className={`adm-side ${open ? "open" : ""}`}>
        <p className="adm-brand">NAHJ <span>admin</span></p>
        <nav>{NAV.map(([to, label]) => <NavLink key={to} end={to === ""} to={`/admin/${to}`} onClick={() => setOpen(false)}>{label}</NavLink>)}</nav>
        <div className="adm-side-foot">
          <a href={sitePath("")} target="_blank" rel="noreferrer">Voir la boutique ↗</a>
          <span>{user.email}</span>
          <button className="adm-link" onClick={signOut}>Déconnexion</button>
        </div>
      </aside>
      <button className="adm-menu" onClick={() => setOpen(!open)}>☰ Menu</button>
      <main className="adm-main">
        <Routes>
          <Route index element={<Dashboard />} />
          <Route path="orders" element={<Orders />} />
          <Route path="products" element={<Products />} />
          <Route path="stock" element={<Stock />} />
          <Route path="accounting" element={<Accounting />} />
          <Route path="collections" element={<Collections />} />
          <Route path="content" element={<Content />} />
          <Route path="zones" element={<Zones />} />
          <Route path="codes" element={<Codes />} />
          <Route path="reviews" element={<Reviews />} />
          <Route path="messages" element={<Messages />} />
          <Route path="subscribers" element={<Subscribers />} />
        </Routes>
      </main>
    </div>
  );
}
