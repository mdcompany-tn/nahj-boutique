import { useEffect, useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import { api, ApiError, img, money } from "../api";
import { useStore } from "../store";

type Quote = { subtotal: number; deliveryFee: number; discount: number; total: number; code: string | null; codeError: string | null; problems: string[] };

export default function Checkout() {
  const { cart, data, clearCart, lang } = useStore();
  const nav = useNavigate();
  const [f, setF] = useState({ customerName: "", phone: "", email: "", governorate: "", city: "", address: "", notes: "" });
  const [code, setCode] = useState("");
  const [applied, setApplied] = useState("");
  const [quote, setQuote] = useState<Quote | null>(null);
  const [busy, setBusy] = useState(false);
  const [err, setErr] = useState<string[]>([]);
  const items = cart.map((i) => ({ variantId: i.variantId, qty: i.qty }));
  const key = JSON.stringify(items);

  useEffect(() => {
    if (!items.length) return;
    api<Quote>("/api/orders/quote", { method: "POST", json: { items, governorate: f.governorate || null, code: applied || null } })
      .then(setQuote).catch(() => setQuote(null));
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [key, f.governorate, applied]);

  if (!cart.length) return (
    <div className="state-block tall"><p className="display-sm">Votre panier est vide.</p><Link to="/shop" className="btn">Parcourir la boutique</Link></div>
  );

  const set = (k: keyof typeof f) => (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement>) => setF({ ...f, [k]: e.target.value });
  const submit = async (e: React.FormEvent) => {
    e.preventDefault(); setBusy(true); setErr([]);
    try {
      const r = await api("/api/orders", { method: "POST", json: { ...f, items, code: applied || null } });
      sessionStorage.setItem("nahj.lastPhone", f.phone);
      clearCart();
      nav(`/order/${r.order.number}?phone=${encodeURIComponent(f.phone)}&new=1`);
    } catch (x) {
      const a = x as ApiError;
      setErr(a.issues?.length ? a.issues : [a.message]);
    } finally { setBusy(false); }
  };

  return (
    <div className="checkout">
      <header className="page-head"><p className="eyebrow">Commande</p><h1 className="display-lg">Finaliser ma commande</h1></header>
      <div className="checkout-grid">
        <form onSubmit={submit} className="co-form">
          <h3>Vos coordonnées</h3>
          <label>Nom et prénom<input required minLength={3} value={f.customerName} onChange={set("customerName")} /></label>
          <div className="two">
            <label>Téléphone<input required inputMode="tel" placeholder="20 123 456" value={f.phone} onChange={set("phone")} /></label>
            <label>Email (facultatif)<input type="email" value={f.email} onChange={set("email")} /></label>
          </div>
          <h3>Livraison</h3>
          <div className="two">
            <label>Gouvernorat
              <select required value={f.governorate} onChange={set("governorate")}>
                <option value="">Choisir…</option>
                {data?.zones.map((z) => <option key={z.governorate} value={z.governorate}>{lang === "ar" ? z.name_ar : z.governorate} — {money(z.fee)} · {z.delay}</option>)}
              </select>
            </label>
            <label>Ville / Délégation<input value={f.city} onChange={set("city")} /></label>
          </div>
          <label>Adresse complète<input required minLength={5} value={f.address} onChange={set("address")} placeholder="Rue, numéro, repère…" /></label>
          <label>Remarque (facultatif)<textarea rows={2} value={f.notes} onChange={set("notes")} /></label>
          <div className="pay-box"><b>Paiement à la livraison</b><p className="muted small">{data?.settings.shipping?.note}</p></div>
          {err.length > 0 && <div className="err">{err.map((m) => <p key={m}>{m}</p>)}</div>}
          <button className="btn btn-block" disabled={busy || !quote || quote.problems.length > 0}>{busy ? "Envoi…" : `Confirmer la commande${quote ? " · " + money(quote.total) : ""}`}</button>
        </form>
        <aside className="co-summary">
          <h3>Récapitulatif</h3>
          {cart.map((i) => (
            <div className="line" key={i.variantId}>
              <img src={img(i.image, 200)} alt="" />
              <div><p className="line-name">{i.name}</p><p className="muted small">{[i.size !== "Unique" && i.size, i.color].filter(Boolean).join(" · ")} × {i.qty}</p></div>
              <p>{money(i.price * i.qty)}</p>
            </div>
          ))}
          <div className="code-row">
            <input value={code} onChange={(e) => setCode(e.target.value.toUpperCase())} placeholder="Code promo" aria-label="Code promo" />
            <button type="button" className="btn btn-outline" onClick={() => setApplied(code.trim())}>Appliquer</button>
          </div>
          {quote?.codeError && <p className="err small">{quote.codeError}</p>}
          {quote?.problems.map((p) => <p key={p} className="err small">{p}</p>)}
          {quote && (
            <div className="totals">
              <div className="row"><span>Sous-total</span><span>{money(quote.subtotal)}</span></div>
              <div className="row"><span>Livraison</span><span>{f.governorate ? (quote.deliveryFee ? money(quote.deliveryFee) : "Offerte") : "—"}</span></div>
              {quote.discount > 0 && <div className="row"><span>Remise {quote.code}</span><span>−{money(quote.discount)}</span></div>}
              <div className="row total"><span>Total</span><b>{money(quote.total)}</b></div>
            </div>
          )}
        </aside>
      </div>
    </div>
  );
}
