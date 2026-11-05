import { Link } from "react-router-dom";
import { asset } from "../api";
import { useLoad, fmt, date, STATUS, Stat, Bars, Meter } from "./ui";

const trend = (now: number, prev: number) => {
  if (!prev) return now ? "Nouveau sur la période" : "—";
  const p = Math.round(((now - prev) / prev) * 100);
  return `${p >= 0 ? "▲" : "▼"} ${Math.abs(p)} % vs 30 j précédents`;
};

export default function Dashboard() {
  const { data, loading, error, reload } = useLoad<any>("/api/admin/dashboard", (r) => r, null);
  if (loading && !data) return <p>Chargement…</p>;
  if (error) return <p className="adm-err">{error}</p>;
  const s = data.stats;
  const up = s.revenue30 >= s.revenue_prev30;
  const totalOrders = data.statuses.reduce((a: number, x: any) => a + x.count, 0);
  const topMax = Math.max(1, ...data.top.map((t: any) => t.qty));
  const regMax = Math.max(1, ...data.regions.map((r: any) => r.total));
  return (
    <div>
      <div className="adm-head">
        <div><h1>Tableau de bord</h1><p className="adm-muted">Vue d’ensemble de la boutique</p></div>
        <button className="adm-btn ghost" onClick={reload}>Actualiser</button>
      </div>

      <div className="adm-stats">
        <Stat tone="accent" label="Ventes aujourd’hui" value={fmt(s.revenue_today)} />
        <Stat label="Chiffre d’affaires (30 j)" value={fmt(s.revenue30)} sub={<span className={up ? "adm-ok" : "adm-err"}>{trend(s.revenue30, s.revenue_prev30)}</span>} />
        <Stat label="Commandes (30 j)" value={s.orders30} sub={`${s.orders} au total`} />
        <Stat label="Panier moyen" value={fmt(s.avg_basket)} />
        <Stat tone="warn" label="Reste à encaisser" value={fmt(s.to_collect)} sub="Paiement à la livraison" />
        <Stat label="Chiffre d’affaires total" value={fmt(s.revenue)} />
      </div>

      <div className="adm-alerts">
        <Link to="/admin/orders" className={s.pending ? "on" : ""}><b>{s.pending}</b> commande(s) à confirmer</Link>
        <Link to="/admin/orders" className={s.to_ship ? "on" : ""}><b>{s.to_ship}</b> à préparer / expédier</Link>
        <Link to="/admin/stock" className={s.out_of_stock ? "on bad" : ""}><b>{s.out_of_stock}</b> variante(s) en rupture</Link>
        <Link to="/admin/stock" className={s.low_stock ? "on" : ""}><b>{s.low_stock}</b> en stock faible (≤ {data.lowThreshold})</Link>
        <Link to="/admin/reviews" className={s.reviews_pending ? "on" : ""}><b>{s.reviews_pending}</b> avis à modérer</Link>
        <Link to="/admin/messages" className={s.unread ? "on" : ""}><b>{s.unread}</b> message(s) non lu(s)</Link>
      </div>

      <section className="adm-panel">
        <h2>Ventes des 30 derniers jours <small className="adm-muted">{fmt(s.revenue30)}</small></h2>
        <Bars points={data.daily} value={(d) => d.total} label={(d) => d.day} format={fmt} every={5} />
      </section>

      <div className="adm-two">
        <section className="adm-panel">
          <h2>Meilleures ventes</h2>
          {data.top.map((t: any) => (
            <div key={t.name} className="adm-rank"><span>{t.name}</span><Meter value={t.qty} max={topMax} /><b>{t.qty} vendus</b><small>{fmt(t.revenue)}</small></div>
          ))}
          {!data.top.length && <p className="adm-muted">Pas encore de ventes.</p>}
        </section>
        <section className="adm-panel">
          <h2>Gouvernorats les plus actifs</h2>
          {data.regions.map((r: any) => (
            <div key={r.governorate} className="adm-rank"><span>{r.governorate}</span><Meter value={r.total} max={regMax} /><b>{fmt(r.total)}</b><small>{r.count} cmd</small></div>
          ))}
          {!data.regions.length && <p className="adm-muted">Pas encore de commandes.</p>}
        </section>
      </div>

      <div className="adm-two">
        <section className="adm-panel">
          <h2>Dernières commandes <Link to="/admin/orders">tout voir</Link></h2>
          <table className="adm-table">
            <thead><tr><th>N°</th><th>Client</th><th>Articles</th><th>Livraison</th><th>Total</th><th>Statut</th></tr></thead>
            <tbody>
              {data.recent.map((o: any) => <tr key={o.number}><td><b>{o.number}</b><br /><small>{date(o.created_at)}</small></td><td>{o.customer_name}<br /><small>{o.governorate}</small></td>
                <td>{fmt(o.subtotal)}</td><td>{fmt(o.delivery_fee)}</td><td><b>{fmt(o.total)}</b></td><td><span className={`st st-${o.status}`}>{STATUS[o.status]}</span></td></tr>)}
              {!data.recent.length && <tr><td colSpan={6}>Aucune commande pour l’instant.</td></tr>}
            </tbody>
          </table>
        </section>
        <section className="adm-panel">
          <h2>Stock à surveiller <Link to="/admin/stock">gérer le stock</Link></h2>
          <table className="adm-table"><tbody>
            {data.low.map((v: any) => <tr key={v.id}><td>{v.image && <img className="adm-thumb sm" src={asset(v.image)} alt="" />}</td><td>{v.name}<br /><small>{v.size} {v.color}</small></td>
              <td><span className={`st ${v.stock === 0 ? "st-cancelled" : "st-pending"}`}>{v.stock === 0 ? "Rupture" : `${v.stock} restant(s)`}</span></td></tr>)}
            {!data.low.length && <tr><td>Tout est bien en stock.</td></tr>}
          </tbody></table>
          <p className="adm-muted"><small>{s.units} pièces en stock · {s.products} produits en ligne · {s.subscribers} abonnés newsletter</small></p>
        </section>
      </div>

      <section className="adm-panel">
        <h2>Commandes par statut</h2>
        <div className="adm-statusbar">
          {data.statuses.map((x: any) => <span key={x.status} className={`st-${x.status}`} style={{ flex: x.count }} title={`${STATUS[x.status]} : ${x.count}`} />)}
        </div>
        <div className="adm-legend">
          {data.statuses.map((x: any) => <span key={x.status}><i className={`st-${x.status}`} />{STATUS[x.status]} <b>{x.count}</b> ({Math.round((x.count / Math.max(1, totalOrders)) * 100)} %)</span>)}
        </div>
      </section>
    </div>
  );
}
