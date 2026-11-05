import { useEffect, useState } from "react";
import { Link, useNavigate, useParams, useSearchParams } from "react-router-dom";
import { api, img, money } from "../api";
import { useStore } from "../store";

export const STATUS: Record<string, string> = { pending: "En attente de confirmation", confirmed: "Confirmée", preparing: "En préparation", shipped: "Expédiée", delivered: "Livrée", cancelled: "Annulée", returned: "Retournée" };
const STEPS = ["pending", "confirmed", "preparing", "shipped", "delivered"];

/** Customer-facing wording and icon for each delivery step. */
const STEP_INFO: Record<string, { title: string; done: string; now: string; icon: string }> = {
  pending: { title: "Commande reçue", done: "Nous avons bien reçu votre commande.", now: "Un conseiller va vous appeler pour confirmer votre commande.", icon: "M9 12l2 2 4-4M7 3h10a2 2 0 012 2v14a2 2 0 01-2 2H7a2 2 0 01-2-2V5a2 2 0 012-2z" },
  confirmed: { title: "Confirmée", done: "Votre commande a été confirmée par téléphone.", now: "Votre commande est confirmée, elle passe bientôt en préparation.", icon: "M22 16.9v3a2 2 0 01-2.2 2 19.8 19.8 0 01-8.6-3.1 19.5 19.5 0 01-6-6A19.8 19.8 0 012.1 4.2 2 2 0 014.1 2h3a2 2 0 012 1.7c.1.9.4 1.8.7 2.7a2 2 0 01-.5 2.1L8 9.8a16 16 0 006 6l1.3-1.3a2 2 0 012.1-.4c.9.3 1.8.6 2.7.7a2 2 0 011.7 2z" },
  preparing: { title: "En préparation", done: "Vos articles ont été préparés et emballés.", now: "Nous préparons et emballons vos articles avec soin.", icon: "M21 8l-9-5-9 5 9 5 9-5zM3 8v8l9 5 9-5V8M12 13v8" },
  shipped: { title: "En route", done: "Votre colis a été remis au livreur.", now: "Votre colis est chez le livreur et arrive bientôt chez vous.", icon: "M1 3h15v13H1zM16 8h4l3 3v5h-7M5.5 21a2.5 2.5 0 100-5 2.5 2.5 0 000 5zM18.5 21a2.5 2.5 0 100-5 2.5 2.5 0 000 5z" },
  delivered: { title: "Livrée", done: "Votre colis a été livré. Merci pour votre confiance !", now: "Votre colis a été livré. Merci pour votre confiance !", icon: "M3 9.5L12 3l9 6.5V20a1 1 0 01-1 1h-5v-6H9v6H4a1 1 0 01-1-1z" },
};

const when = (at?: string) => at ? new Date(at).toLocaleString("fr-TN", { weekday: "short", day: "numeric", month: "short", hour: "2-digit", minute: "2-digit" }) : "";

function Icon({ d }: { d: string }) {
  return <svg viewBox="0 0 24 24" aria-hidden="true"><path d={d} /></svg>;
}

function Tracker({ order }: { order: any }) {
  const history: any[] = order.history || [];
  const reached = (s: string) => history.find((h) => h.status === s)?.at as string | undefined;
  const step = STEPS.indexOf(order.status);
  const pct = step < 0 ? 0 : (step / (STEPS.length - 1)) * 100;
  if (step < 0) {
    const last = [...history].reverse().find((h) => h.status === order.status);
    return (
      <section className="tracker tracker-stopped">
        <div className="tracker-alert">
          <Icon d="M12 22a10 10 0 100-20 10 10 0 000 20zM15 9l-6 6M9 9l6 6" />
          <div><b>Commande {STATUS[order.status]?.toLowerCase()}</b><p>{order.status === "returned" ? "Le colis nous a été retourné." : "Cette commande a été annulée et ne sera pas livrée."}{last?.note ? ` ${last.note}` : ""}</p>{last && <small>{when(last.at)}</small>}</div>
        </div>
      </section>
    );
  }
  const cur = STEP_INFO[order.status];
  return (
    <section className="tracker">
      <div className="tracker-now">
        <span className="tracker-now-icon"><Icon d={cur.icon} /></span>
        <div>
          <p className="eyebrow">Étape {step + 1} sur {STEPS.length}</p>
          <h2>{cur.title}</h2>
          <p>{cur.now}</p>
        </div>
      </div>
      <div className="tracker-bar" role="progressbar" aria-valuenow={Math.round(pct)} aria-valuemin={0} aria-valuemax={100}><span style={{ width: `${pct}%` }} /></div>
      <ol className="tracker-steps">
        {STEPS.map((s, i) => {
          const info = STEP_INFO[s];
          const state = i < step ? "done" : i === step ? "current" : "todo";
          const at = reached(s) || (s === "pending" ? order.created_at : undefined);
          return (
            <li key={s} className={state}>
              <span className="tracker-dot">{state === "done" ? <Icon d="M5 12l5 5L20 7" /> : <Icon d={info.icon} />}</span>
              <div className="tracker-txt">
                <b>{info.title}</b>
                <p>{state === "todo" ? "À venir" : state === "current" ? info.now : info.done}</p>
                {state !== "todo" && at && <small>{when(at)}</small>}
              </div>
            </li>
          );
        })}
      </ol>
    </section>
  );
}

/** Full order view (tracker, delivery, items, history). Shared by the order page and the account page. */
export function OrderDetails({ order }: { order: any }) {
  const { data } = useStore();
  const contact = data?.settings?.contact || {};
  const hist = [...(order.history || [])].reverse();
  return (
    <>
    <div className="track-wrap">
      <Tracker order={order} />
      <div className="track-side">
        <div className="track-card">
          <h3>Livraison</h3>
          <p><b>{order.customer_name}</b><br />{[order.city, order.governorate].filter(Boolean).join(", ")}</p>
          <p className="muted small">Paiement à la livraison : <b>{money(order.total)}</b></p>
        </div>
        {(contact.whatsapp || contact.phone) && (
          <div className="track-card">
            <h3>Une question ?</h3>
            <p className="small">Notre équipe vous répond pour toute question sur votre livraison.</p>
            <div className="track-help">
              {contact.whatsapp && <a className="btn" href={`https://wa.me/${String(contact.whatsapp).replace(/\D/g, "")}?text=${encodeURIComponent(`Bonjour, commande ${order.number}`)}`} target="_blank" rel="noreferrer">WhatsApp</a>}
              {contact.phone && <a className="btn btn-outline" href={`tel:${String(contact.phone).replace(/\s/g, "")}`}>Appeler</a>}
            </div>
          </div>
        )}
      </div>
    </div>
    <div className="checkout-grid">
      <div className="co-summary">
        <h3>Mes articles</h3>
        {order.items.map((i: any) => (
          <div className="line" key={i.variant_id}><img src={img(i.image, 200)} alt="" /><div><p className="line-name">{i.name}</p><p className="muted small">{[i.size !== "Unique" && i.size, i.color].filter(Boolean).join(" · ")} × {i.qty}</p></div><p>{money(i.line_total)}</p></div>
        ))}
        <div className="totals">
          <div className="row"><span>Sous-total</span><span>{money(order.subtotal)}</span></div>
          <div className="row"><span>Livraison ({order.governorate})</span><span>{order.delivery_fee ? money(order.delivery_fee) : "Offerte"}</span></div>
          {order.discount > 0 && <div className="row"><span>Remise {order.discount_code}</span><span>−{money(order.discount)}</span></div>}
          <div className="row total"><span>À payer à la livraison</span><b>{money(order.total)}</b></div>
        </div>
      </div>
      <div className="track-history"><h3>Historique</h3>
        <ul>{hist.map((h: any, i: number) => <li key={i}><b>{STATUS[h.status] || h.status}</b><small>{when(h.at)}</small>{h.note && <p>{h.note}</p>}</li>)}</ul>
        <Link to="/shop" className="btn btn-outline">Continuer mes achats</Link></div>
    </div>
    </>
  );
}

export default function OrderPage() {
  const { number } = useParams();
  const [sp] = useSearchParams();
  const nav = useNavigate();
  const [num, setNum] = useState(number || "");
  const [phone, setPhone] = useState(sp.get("phone") || "");
  const [order, setOrder] = useState<any>(null);
  const [err, setErr] = useState("");
  useEffect(() => {
    if (!number || !phone) return;
    api(`/api/orders/${encodeURIComponent(number)}?phone=${encodeURIComponent(phone)}`).then((r) => { setOrder(r.order); setErr(""); }).catch((e) => setErr(e.message));
    // Refresh every minute so the customer sees each new step without reloading.
    const t = setInterval(() => api(`/api/orders/${encodeURIComponent(number)}?phone=${encodeURIComponent(phone)}`).then((r) => setOrder(r.order)).catch(() => {}), 60000);
    return () => clearInterval(t);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [number]);

  const lookup = (e: React.FormEvent) => { e.preventDefault(); nav(`/order/${num.trim()}?phone=${encodeURIComponent(phone)}`); if (num.trim() === number) window.location.reload(); };

  if (!order) return (
    <div className="track">
      <header className="page-head"><p className="eyebrow">Suivi</p><h1 className="display-lg">Suivre ma commande</h1></header>
      <form className="co-form narrow" onSubmit={lookup}>
        <label>Numéro de commande<input required placeholder="NJ-1001" value={num} onChange={(e) => setNum(e.target.value)} /></label>
        <label>Téléphone utilisé<input required value={phone} onChange={(e) => setPhone(e.target.value)} /></label>
        {err && <p className="err">{err}</p>}
        <button className="btn">Rechercher</button>
      </form>
    </div>
  );

  return (
    <div className="track">
      <header className="page-head">
        {sp.get("new") && <p className="ok">Merci {order.customer_name.split(" ")[0]} ! Votre commande est enregistrée. Un conseiller vous appelle pour la confirmer.</p>}
        <p className="eyebrow">Commande {order.number} · passée le {new Date(order.created_at).toLocaleDateString("fr-TN")}</p>
        <h1 className="display-lg">Suivi de ma livraison</h1>
      </header>
      <OrderDetails order={order} />
    </div>
  );
}
