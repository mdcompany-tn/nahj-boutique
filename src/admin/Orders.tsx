import { Fragment, useState } from "react";
import { api } from "../api";
import { useLoad, fmt, date, STATUS, Flash } from "./ui";

export default function Orders() {
  const [status, setStatus] = useState("");
  const [search, setSearch] = useState("");
  const [qq, setQq] = useState("");
  const path = `/api/admin/orders?${new URLSearchParams({ ...(status && { status }), ...(qq && { q: qq }) })}`;
  const { data, loading, error, reload } = useLoad<any[]>(path, (r) => r.orders, []);
  const [open, setOpen] = useState<number | null>(null);
  const [msg, setMsg] = useState("");
  const [note, setNote] = useState<Record<number, string>>({});

  const update = async (id: number, patch: any) => {
    setMsg("");
    try { await api(`/api/admin/orders/${id}`, { method: "PUT", json: patch }); setMsg("✓ Commande mise à jour"); reload(); }
    catch (e) { setMsg((e as Error).message); }
  };
  const remove = async (o: any) => {
    if (!confirm(`Supprimer définitivement la commande ${o.number} ?\n\nLe stock ne sera PAS modifié.`)) return;
    setMsg("");
    try { await api(`/api/admin/orders/${o.id}`, { method: "DELETE" }); setOpen(null); setMsg(`✓ Commande ${o.number} supprimée (stock inchangé)`); reload(); }
    catch (e) { setMsg((e as Error).message); }
  };
  const exportCsv = () => {
    const rows = [["Numéro", "Date", "Client", "Téléphone", "Gouvernorat", "Ville", "Adresse", "Articles", "Montant articles", "Remise", "Livraison", "Total", "Statut", "Paiement"],
      ...data.map((o) => [o.number, date(o.created_at), o.customer_name, o.phone, o.governorate, o.city, o.address,
        o.items.map((i: any) => `${i.qty}x ${i.name} ${i.size} ${i.color}`).join(" | "), o.subtotal, o.discount, o.delivery_fee, o.total, STATUS[o.status], o.payment_status])];
    const csv = rows.map((r) => r.map((c) => `"${String(c ?? "").replace(/"/g, '""')}"`).join(";")).join("\n");
    const a = document.createElement("a"); a.href = URL.createObjectURL(new Blob(["﻿" + csv], { type: "text/csv" })); a.download = "commandes.csv"; a.click();
  };

  return (
    <div>
      <h1>Commandes</h1>
      <div className="adm-toolbar">
        <select value={status} onChange={(e) => setStatus(e.target.value)}><option value="">Tous les statuts</option>{Object.entries(STATUS).map(([k, v]) => <option key={k} value={k}>{v}</option>)}</select>
        <form onSubmit={(e) => { e.preventDefault(); setQq(search); }}><input placeholder="N°, nom ou téléphone" value={search} onChange={(e) => setSearch(e.target.value)} /></form>
        <button className="adm-btn ghost" onClick={exportCsv} disabled={!data.length}>Exporter CSV</button>
      </div>
      <Flash msg={msg} />
      {error && <p className="adm-err">{error}</p>}
      {loading && <p>Chargement…</p>}
      <table className="adm-table">
        <thead><tr><th>N°</th><th>Date</th><th>Client</th><th>Gouvernorat</th><th className="adm-num">Articles</th><th className="adm-num">Livraison</th><th className="adm-num">Total</th><th>Statut</th><th>Paiement</th><th></th></tr></thead>
        <tbody>
          {data.map((o) => (
            <Fragment key={o.id}>
              <tr className="adm-click" onClick={() => setOpen(open === o.id ? null : o.id)}>
                <td><b>{o.number}</b></td><td>{date(o.created_at)}</td><td>{o.customer_name}<br /><small>{o.phone}</small></td><td>{o.governorate}</td>
                <td className="adm-num">{fmt(o.subtotal - (o.discount || 0))}{o.discount > 0 && <><br /><small className="adm-muted">remise −{fmt(o.discount)}</small></>}</td>
                <td className="adm-num">{fmt(o.delivery_fee)}</td><td className="adm-num"><b>{fmt(o.total)}</b></td><td><span className={`st st-${o.status}`}>{STATUS[o.status]}</span></td><td>{o.payment_status === "paid" ? "Payé" : o.payment_status === "refunded" ? "Remboursé" : "À encaisser"}</td>
                <td><button type="button" className="adm-link danger" onClick={(e) => { e.stopPropagation(); remove(o); }} title="Supprimer sans toucher au stock">Supprimer</button></td>
              </tr>
              {open === o.id && (
                <tr className="adm-detail"><td colSpan={10}>
                  <div className="adm-two">
                    <div>
                      <h3>Articles</h3>
                      {o.items.map((i: any) => <p key={i.variant_id}>{i.qty} × {i.name} — {i.size} {i.color} · {fmt(i.line_total)}</p>)}
                      <table className="adm-table adm-pl"><tbody>
                        <tr><td>Articles</td><td className="adm-num">{fmt(o.subtotal)}</td></tr>
                        {o.discount > 0 && <tr><td>Remise {o.discount_code}</td><td className="adm-num adm-err">− {fmt(o.discount)}</td></tr>}
                        <tr><td>Livraison ({o.governorate})</td><td className="adm-num">{fmt(o.delivery_fee)}</td></tr>
                        <tr className="adm-total"><td>Total à encaisser</td><td className="adm-num">{fmt(o.total)}</td></tr>
                      </tbody></table>
                      <h3>Livraison</h3>
                      <p>{o.customer_name} · <a href={`tel:${o.phone}`}>{o.phone}</a>{o.email && ` · ${o.email}`}<br />{o.address}, {o.city} — {o.governorate}</p>
                      {o.notes && <p><i>Note client : {o.notes}</i></p>}
                      <h3>Historique</h3>
                      {o.history.map((h: any, i: number) => <p key={i}><small>{date(h.at)} — {STATUS[h.status]} {h.note && `· ${h.note}`} {h.by && `(${h.by})`}</small></p>)}
                    </div>
                    <div className="adm-form">
                      <label>Changer le statut
                        <select value={o.status} onChange={(e) => update(o.id, { status: e.target.value, note: note[o.id] || "" })}>
                          {Object.entries(STATUS).map(([k, v]) => <option key={k} value={k}>{v}</option>)}
                        </select>
                      </label>
                      <label>Note pour l’historique (avant de changer le statut)<input value={note[o.id] || ""} onChange={(e) => setNote({ ...note, [o.id]: e.target.value })} /></label>
                      <label>Paiement
                        <select value={o.payment_status} onChange={(e) => update(o.id, { payment_status: e.target.value })}>
                          <option value="pending">À encaisser</option><option value="paid">Payé</option><option value="refunded">Remboursé</option>
                        </select>
                      </label>
                      <label>Note interne<textarea defaultValue={o.internal_note} onBlur={(e) => e.target.value !== o.internal_note && update(o.id, { internal_note: e.target.value })} /></label>
                      <p><small>Annuler ou marquer « retournée » remet automatiquement les articles en stock.</small></p>
                      <div className="adm-danger">
                        <button type="button" className="adm-btn danger" onClick={() => remove(o)}>Supprimer la commande</button>
                        <p><small>Supprime la commande de la liste, du tableau de bord et de la comptabilité. Le stock n’est pas touché : aucun article n’est remis ni retiré.</small></p>
                      </div>
                    </div>
                  </div>
                </td></tr>
              )}
            </Fragment>
          ))}
          {!loading && !data.length && <tr><td colSpan={10}>Aucune commande.</td></tr>}
        </tbody>
      </table>
    </div>
  );
}
