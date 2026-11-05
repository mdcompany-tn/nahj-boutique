import { useEffect, useState } from "react";
import { api } from "../api";
import { useLoad, fmt, day, isoDay, Flash, Stat, Bars, EXPENSE_CATS } from "./ui";

const PRESETS: [string, () => [Date, Date]][] = [
  ["Ce mois", () => { const n = new Date(); return [new Date(n.getFullYear(), n.getMonth(), 1), n]; }],
  ["Mois dernier", () => { const n = new Date(); return [new Date(n.getFullYear(), n.getMonth() - 1, 1), new Date(n.getFullYear(), n.getMonth(), 0)]; }],
  ["30 jours", () => [new Date(Date.now() - 29 * 864e5), new Date()]],
  ["Cette année", () => { const n = new Date(); return [new Date(n.getFullYear(), 0, 1), n]; }],
];
const blankExpense = () => ({ label: "", category: "achat", amount: "", spent_at: isoDay(new Date()), note: "" });

function Line({ label, value, minus, strong, hint }: { label: string; value: number; minus?: boolean; strong?: boolean; hint?: string }) {
  return (
    <tr className={strong ? "adm-total" : ""}>
      <td>{label}{hint && <><br /><small className="adm-muted">{hint}</small></>}</td>
      <td className={`adm-num ${minus ? "adm-err" : ""}`}>{minus && value ? "− " : ""}{fmt(value)}</td>
    </tr>
  );
}

function Settings({ onSaved }: { onSaved: () => void }) {
  const { data, setData } = useLoad<any>("/api/admin/settings", (r) => ({ courierCost: 0, lowStock: 3, ...(r.settings.accounting || {}) }), null);
  const [msg, setMsg] = useState("");
  if (!data) return null;
  const save = async () => {
    try { await api("/api/admin/settings/accounting", { method: "PUT", json: { courierCost: Number(data.courierCost) || 0, lowStock: Number(data.lowStock) || 0 } }); setMsg("✓ Réglages enregistrés"); onSaved(); }
    catch (e) { setMsg((e as Error).message); }
  };
  return (
    <section className="adm-panel adm-form">
      <h2>Réglages de calcul</h2>
      <div className="adm-grid">
        <label>Coût payé au livreur par colis (DT)<input type="number" step="0.001" min={0} value={data.courierCost} onChange={(e) => setData({ ...data, courierCost: e.target.value })} /></label>
        <label>Seuil « stock faible » (pièces)<input type="number" min={0} value={data.lowStock} onChange={(e) => setData({ ...data, lowStock: e.target.value })} /></label>
      </div>
      <p className="adm-muted"><small>Le coût livreur est compté pour chaque commande expédiée, livrée ou retournée. Les frais de livraison payés par le client sont comptés dans le chiffre d’affaires.</small></p>
      <Flash msg={msg} />
      <div><button className="adm-btn" onClick={save}>Enregistrer</button></div>
    </section>
  );
}

export default function Accounting() {
  const [range, setRange] = useState(() => { const [a, b] = PRESETS[0][1](); return { from: isoDay(a), to: isoDay(b) }; });
  const { data, loading, error, reload } = useLoad<any>(`/api/admin/accounting?from=${range.from}&to=${range.to}`, (r) => r, null);
  const [exp, setExp] = useState<any>(null);
  const [msg, setMsg] = useState("");
  useEffect(() => setMsg(""), [range]);

  const saveExpense = async (e: React.FormEvent) => {
    e.preventDefault(); setMsg("");
    try {
      const payload = { ...exp, amount: Number(exp.amount) }; delete payload.id;
      if (exp.id) await api(`/api/admin/expenses/${exp.id}`, { method: "PUT", json: payload });
      else await api("/api/admin/expenses", { method: "POST", json: payload });
      setExp(null); setMsg("✓ Dépense enregistrée"); reload();
    } catch (x: any) { setMsg(x.issues?.join(" · ") || x.message); }
  };
  const delExpense = async (x: any) => {
    if (!confirm(`Supprimer la dépense « ${x.label} » ?`)) return;
    await api(`/api/admin/expenses/${x.id}`, { method: "DELETE" }); setMsg("✓ Dépense supprimée"); reload();
  };
  const exportCsv = () => {
    const rows = [["Mois", "Commandes", "Chiffre d’affaires", "Coût marchandises", "Livreur", "Dépenses", "Bénéfice net"],
      ...data.monthly.map((m: any) => [m.month, m.orders, m.revenue, m.cogs, m.courier, m.expenses, m.profit])];
    const csv = rows.map((r) => r.map((c: any) => `"${String(c ?? "").replace(/"/g, '""')}"`).join(";")).join("\n");
    const a = document.createElement("a"); a.href = URL.createObjectURL(new Blob(["﻿" + csv], { type: "text/csv" })); a.download = "comptabilite.csv"; a.click();
  };

  if (loading && !data) return <p>Chargement…</p>;
  if (error && !data) return <p className="adm-err">{error}</p>;
  const s = data.summary;
  const margin = s.revenue ? Math.round((s.profit / s.revenue) * 100) : 0;
  const goodsMargin = s.goods - s.discounts - s.cogs;
  const months = [...data.monthly].reverse();

  return (
    <div>
      <div className="adm-head">
        <div><h1>Comptabilité</h1><p className="adm-muted">Du {day(data.from)} au {day(data.to)}</p></div>
        <div className="adm-toolbar">
          {PRESETS.map(([label, fn]) => <button key={label} className="adm-btn ghost sm" onClick={() => { const [a, b] = fn(); setRange({ from: isoDay(a), to: isoDay(b) }); }}>{label}</button>)}
          <input type="date" value={range.from} onChange={(e) => e.target.value && setRange({ ...range, from: e.target.value })} />
          <input type="date" value={range.to} onChange={(e) => e.target.value && setRange({ ...range, to: e.target.value })} />
        </div>
      </div>
      <Flash msg={msg} />

      <div className="adm-stats">
        <Stat tone="accent" label="Chiffre d’affaires" value={fmt(s.revenue)} sub={`${s.orders} commande(s) valides`} />
        <Stat tone={s.profit >= 0 ? "good" : "bad"} label="Bénéfice net" value={fmt(s.profit)} sub={`Marge nette ${margin} %`} />
        <Stat label="Encaissé" value={fmt(s.collected)} />
        <Stat tone={s.to_collect ? "warn" : undefined} label="Reste à encaisser" value={fmt(s.to_collect)} />
        <Stat label="Dépenses" value={fmt(s.expenses)} />
        <Stat label="Annulées / retournées" value={s.lost_orders} sub={s.refunded ? `${fmt(s.refunded)} remboursés` : undefined} />
      </div>

      <div className="adm-two">
        <section className="adm-panel">
          <h2>Compte de résultat</h2>
          <table className="adm-table adm-pl"><tbody>
            <Line label="Ventes d’articles" value={s.goods} />
            <Line label="Remises (codes promo)" value={s.discounts} minus />
            <Line label="Frais de livraison facturés" value={s.delivery} hint="Payés par les clients" />
            <Line label="Chiffre d’affaires" value={s.revenue} strong />
            <Line label="Coût d’achat des articles vendus" value={s.cogs} minus />
            <Line label={`Livreur (${s.parcels} colis × ${fmt(data.courierCost)})`} value={s.courier} minus />
            <Line label="Dépenses" value={s.expenses} minus />
            <Line label="Bénéfice net" value={s.profit} strong />
          </tbody></table>
          <p className="adm-muted"><small>Marge sur articles : {fmt(goodsMargin)}. Les commandes annulées et retournées sont exclues.</small></p>
        </section>
        <section className="adm-panel">
          <h2>Valeur du stock actuel</h2>
          <table className="adm-table adm-pl"><tbody>
            <Line label={`Au prix d’achat (${data.inventory.units} pièces)`} value={data.inventory.at_cost} />
            <Line label="Au prix de vente" value={data.inventory.at_price} />
            <Line label="Marge potentielle" value={data.inventory.at_price - data.inventory.at_cost} strong />
          </tbody></table>
          {data.inventory.missing_cost > 0 && <p className="adm-err"><small>{data.inventory.missing_cost} variante(s) en stock n’ont pas de prix d’achat. Renseignez-le dans la fiche produit pour des chiffres justes.</small></p>}
          <h2>Dépenses par catégorie</h2>
          {data.byCategory.map((c: any) => <div key={c.category} className="adm-rank"><span>{EXPENSE_CATS[c.category] || c.category}</span><b>{fmt(c.total)}</b></div>)}
          {!data.byCategory.length && <p className="adm-muted">Aucune dépense sur la période.</p>}
        </section>
      </div>

      <section className="adm-panel">
        <h2>Dépenses de la période <button className="adm-btn sm" onClick={() => setExp(blankExpense())}>+ Ajouter une dépense</button></h2>
        {exp && (
          <form className="adm-form adm-box" onSubmit={saveExpense}>
            <div className="adm-grid">
              <label>Libellé<input required minLength={2} value={exp.label} onChange={(e) => setExp({ ...exp, label: e.target.value })} placeholder="Ex. Achat tissu, pub Instagram…" /></label>
              <label>Catégorie<select value={exp.category} onChange={(e) => setExp({ ...exp, category: e.target.value })}>{Object.entries(EXPENSE_CATS).map(([k, v]) => <option key={k} value={k}>{v}</option>)}</select></label>
              <label>Montant (DT)<input required type="number" step="0.001" min={0} value={exp.amount} onChange={(e) => setExp({ ...exp, amount: e.target.value })} /></label>
              <label>Date<input required type="date" value={exp.spent_at} onChange={(e) => setExp({ ...exp, spent_at: e.target.value })} /></label>
            </div>
            <label>Note<input value={exp.note} onChange={(e) => setExp({ ...exp, note: e.target.value })} /></label>
            <div className="adm-actions"><button className="adm-btn">{exp.id ? "Modifier" : "Ajouter"}</button><button type="button" className="adm-btn ghost" onClick={() => setExp(null)}>Annuler</button></div>
          </form>
        )}
        <table className="adm-table">
          <thead><tr><th>Date</th><th>Libellé</th><th>Catégorie</th><th className="adm-num">Montant</th><th /></tr></thead>
          <tbody>
            {data.expenses.map((x: any) => (
              <tr key={x.id}>
                <td className="adm-nowrap">{day(x.spent_at)}</td><td>{x.label}{x.note && <><br /><small className="adm-muted">{x.note}</small></>}</td>
                <td>{EXPENSE_CATS[x.category] || x.category}</td><td className="adm-num">{fmt(x.amount)}</td>
                <td className="adm-nowrap"><button className="adm-link" onClick={() => setExp({ ...x })}>Modifier</button><button className="adm-link danger" onClick={() => delExpense(x)}>Supprimer</button></td>
              </tr>
            ))}
            {!data.expenses.length && <tr><td colSpan={5}>Aucune dépense sur la période.</td></tr>}
          </tbody>
        </table>
      </section>

      <section className="adm-panel">
        <h2>Bénéfice net sur 12 mois <button className="adm-btn ghost sm" onClick={exportCsv}>Exporter CSV</button></h2>
        <Bars points={months} value={(m) => Math.max(0, m.revenue)} label={(m) => m.month.slice(0, 2)} format={fmt} />
        <table className="adm-table">
          <thead><tr><th>Mois</th><th className="adm-num">Cmd</th><th className="adm-num">Chiffre d’affaires</th><th className="adm-num">Coût articles</th><th className="adm-num">Livreur</th><th className="adm-num">Dépenses</th><th className="adm-num">Bénéfice</th></tr></thead>
          <tbody>
            {data.monthly.map((m: any) => (
              <tr key={m.month}><td>{m.month}</td><td className="adm-num">{m.orders}</td><td className="adm-num">{fmt(m.revenue)}</td><td className="adm-num">{fmt(m.cogs)}</td>
                <td className="adm-num">{fmt(m.courier)}</td><td className="adm-num">{fmt(m.expenses)}</td><td className={`adm-num ${m.profit < 0 ? "adm-err" : "adm-ok"}`}><b>{fmt(m.profit)}</b></td></tr>
            ))}
          </tbody>
        </table>
      </section>

      <Settings onSaved={reload} />
    </div>
  );
}
