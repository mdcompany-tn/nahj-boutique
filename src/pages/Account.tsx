import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { api, money } from "../api";
import { useAuth } from "../auth";
import { useStore } from "../store";
import ProductCard from "../components/ProductCard";
import { OrderDetails, STATUS } from "./Order";
import "./account.css";

const fmtDate = (s: string) =>
  new Date(s).toLocaleDateString("fr-TN", { day: "numeric", month: "long", year: "numeric" });

export default function Account() {
  const { user, ready, recovery } = useAuth();
  if (!ready) return <div className="acc-loading">Chargement…</div>;
  if (recovery && user) return <NewPassword />;
  return (
    <div className="account">
      <header className="page-head">
        <p className="eyebrow">Compte</p>
        <h1 className="display-lg">{user ? "Mon compte" : "Se connecter"}</h1>
      </header>
      {user ? <Profile /> : <AuthPanel />}
    </div>
  );
}

/* ------------------------------------------------------------------ */
/* Signed out: login / signup / forgot password                        */
/* ------------------------------------------------------------------ */

type Mode = "login" | "signup" | "forgot";

function AuthPanel() {
  const { signIn, signUp, resetPassword } = useAuth();
  const [mode, setMode] = useState<Mode>("login");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [confirm, setConfirm] = useState("");
  const [msg, setMsg] = useState("");
  const [good, setGood] = useState(false);
  const [busy, setBusy] = useState(false);

  const switchTo = (m: Mode) => { setMode(m); setMsg(""); setGood(false); setPassword(""); setConfirm(""); };

  const submit = async (e: React.FormEvent) => {
    e.preventDefault();
    setMsg(""); setGood(false); setBusy(true);
    try {
      if (mode === "login") {
        await signIn(email, password);
      } else if (mode === "signup") {
        if (password.length < 8) throw new Error("8 caractères minimum.");
        if (password !== confirm) throw new Error("Les deux mots de passe ne correspondent pas.");
        const r = await signUp(email, password);
        if (r.needsConfirm) {
          switchTo("login");
          setGood(true);
          setMsg("Compte créé. Vérifiez votre email pour confirmer votre adresse, puis connectez-vous.");
        }
      } else {
        await resetPassword(email);
        setGood(true);
        setMsg("Email de réinitialisation envoyé. Ouvrez le lien reçu (vérifiez aussi les spams).");
      }
    } catch (x) {
      setMsg((x as Error).message);
    } finally {
      setBusy(false);
    }
  };

  return (
    <div className="acc-wrap acc-wrap-auth">
      <div className="acc-card">
        <div className="acc-tabs" role="tablist">
          <button type="button" role="tab" aria-selected={mode === "login"} className={mode === "login" ? "on" : ""} onClick={() => switchTo("login")}>Connexion</button>
          <button type="button" role="tab" aria-selected={mode === "signup"} className={mode === "signup" ? "on" : ""} onClick={() => switchTo("signup")}>Créer un compte</button>
        </div>

        <form className="co-form" onSubmit={submit}>
          {mode === "forgot" && <p className="muted small">Entrez votre email : nous vous envoyons un lien pour choisir un nouveau mot de passe.</p>}

          <label>Email
            <input type="email" autoComplete="email" required value={email} onChange={(e) => setEmail(e.target.value)} placeholder="vous@exemple.tn" />
          </label>

          {mode !== "forgot" && (
            <label>Mot de passe
              <input type="password" autoComplete={mode === "login" ? "current-password" : "new-password"} required minLength={mode === "signup" ? 8 : undefined} value={password} onChange={(e) => setPassword(e.target.value)} />
            </label>
          )}

          {mode === "signup" && (
            <label>Confirmer le mot de passe
              <input type="password" autoComplete="new-password" required minLength={8} value={confirm} onChange={(e) => setConfirm(e.target.value)} />
            </label>
          )}

          {msg && <p className={good ? "ok" : "err"}>{msg}</p>}

          <button className="btn" disabled={busy}>
            {busy ? "Un instant…" : mode === "login" ? "Se connecter" : mode === "signup" ? "Créer mon compte" : "Envoyer le lien"}
          </button>

          {mode === "login" && <button type="button" className="acc-link" onClick={() => switchTo("forgot")}>Mot de passe oublié ?</button>}
          {mode === "forgot" && <button type="button" className="acc-link" onClick={() => switchTo("login")}>← Revenir à la connexion</button>}
        </form>
      </div>

      <div className="acc-guest">
        <h2 className="display-sm">Pas besoin de compte pour commander</h2>
        <p className="muted">
          Le paiement se fait à la livraison. Vous pouvez commander en invité et suivre votre
          commande avec son numéro et le téléphone utilisé.
        </p>
        <p className="muted small">
          Un compte sert seulement à enregistrer vos <b>favoris</b> et à retrouver vos <b>commandes</b>.
        </p>
        <div className="acc-guest-cta">
          <Link to="/shop" className="btn btn-outline">Parcourir la boutique</Link>
          <Link to="/track" className="btn">Suivre une commande</Link>
        </div>
      </div>
    </div>
  );
}

/* ------------------------------------------------------------------ */
/* Signed in: profile, orders, favorites                               */
/* ------------------------------------------------------------------ */

function Profile() {
  const { user, signOut } = useAuth();
  const { products, wishlist } = useStore();
  const [orders, setOrders] = useState<any[] | null>(null);
  const [err, setErr] = useState("");
  const [open, setOpen] = useState<string | null>(null);

  useEffect(() => {
    let alive = true;
    api<{ orders: any[] }>("/api/orders")
      .then((r) => { if (alive) setOrders(r.orders || []); })
      .catch((e) => { if (alive) { setErr(e.message); setOrders([]); } });
    return () => { alive = false; };
  }, []);

  const favorites = products.filter((p) => wishlist.includes(p.id));

  return (
    <div className="acc-wrap">
      <section className="acc-card acc-me">
        <div>
          <p className="eyebrow">Connecté</p>
          <p className="acc-email">{user?.email}</p>
          <p className="muted small">Vos favoris et vos commandes sont enregistrés sur ce compte.</p>
        </div>
        <button className="btn btn-outline" onClick={() => signOut()}>Se déconnecter</button>
      </section>

      <section className="acc-section">
        <div className="acc-sec-head">
          <h2 className="display-sm">Mes commandes</h2>
          {orders && orders.length > 0 && <span className="muted small">{orders.length} commande{orders.length > 1 ? "s" : ""}</span>}
        </div>

        {orders === null && <p className="muted small">Chargement…</p>}
        {err && <p className="err">{err}</p>}
        {orders && orders.length === 0 && (
          <p className="muted">
            Aucune commande sur ce compte. <Link to="/shop" className="acc-link inline">Découvrir la boutique →</Link>
          </p>
        )}

        <ul className="acc-orders">
          {(orders || []).map((o) => (
            <li key={o.number} className="acc-order">
              <button type="button" className="acc-order-head" onClick={() => setOpen(open === o.number ? null : o.number)} aria-expanded={open === o.number}>
                <span className="acc-order-num">{o.number}</span>
                <span className="muted small">{fmtDate(o.created_at)}</span>
                <span className="muted small">{(o.items || []).length} article{(o.items || []).length > 1 ? "s" : ""}</span>
                <span className="acc-order-total">{money(o.total)}</span>
                <span className={`acc-pill s-${o.status}`}>{STATUS[o.status] || o.status}</span>
              </button>
              {open === o.number && <div className="acc-order-body"><OrderDetails order={o} /></div>}
            </li>
          ))}
        </ul>
      </section>

      <section className="acc-section">
        <div className="acc-sec-head">
          <h2 className="display-sm">Mes favoris</h2>
          {favorites.length > 0 && <span className="muted small">{favorites.length} article{favorites.length > 1 ? "s" : ""}</span>}
        </div>
        {favorites.length === 0 ? (
          <p className="muted">
            Aucun favori pour l’instant. Touchez le cœur sur un article pour l’enregistrer ici.{" "}
            <Link to="/shop" className="acc-link inline">Parcourir la boutique →</Link>
          </p>
        ) : (
          <div className="grid-4 acc-grid">{favorites.map((p, i) => <ProductCard key={p.id} p={p} index={i} />)}</div>
        )}
      </section>
    </div>
  );
}

/* ------------------------------------------------------------------ */
/* Password recovery (link from the reset email)                      */
/* ------------------------------------------------------------------ */

function NewPassword() {
  const { updatePassword, clearRecovery } = useAuth();
  const [password, setPassword] = useState("");
  const [confirm, setConfirm] = useState("");
  const [msg, setMsg] = useState("");
  const [good, setGood] = useState(false);
  const [busy, setBusy] = useState(false);
  const [done, setDone] = useState(false);

  const submit = async (e: React.FormEvent) => {
    e.preventDefault();
    setMsg(""); setGood(false);
    if (password.length < 8) { setMsg("8 caractères minimum."); return; }
    if (password !== confirm) { setMsg("Les deux mots de passe ne correspondent pas."); return; }
    setBusy(true);
    try {
      await updatePassword(password);
      setGood(true);
      setDone(true);
      setMsg("Mot de passe mis à jour. Vous êtes connecté.");
    } catch (x) {
      setMsg((x as Error).message);
    } finally {
      setBusy(false);
    }
  };

  return (
    <div className="account">
      <header className="page-head"><p className="eyebrow">Compte</p><h1 className="display-lg">Nouveau mot de passe</h1></header>
      <div className="acc-wrap">
        <div className="acc-card">
          {done ? (
            <>
              <p className="ok">{msg}</p>
              <button type="button" className="btn" onClick={clearRecovery}>Continuer vers mon compte</button>
            </>
          ) : (
            <form className="co-form" onSubmit={submit}>
              <label>Nouveau mot de passe<input type="password" autoComplete="new-password" required minLength={8} value={password} onChange={(e) => setPassword(e.target.value)} /></label>
              <label>Confirmer<input type="password" autoComplete="new-password" required minLength={8} value={confirm} onChange={(e) => setConfirm(e.target.value)} /></label>
              {msg && <p className={good ? "ok" : "err"}>{msg}</p>}
              <button className="btn" disabled={busy}>{busy ? "Enregistrement…" : "Valider"}</button>
            </form>
          )}
        </div>
      </div>
    </div>
  );
}
