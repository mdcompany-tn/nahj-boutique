import { Fragment, useMemo, useState } from "react";
import { api, asset } from "../api";
import { useLoad, fmt, date, Flash, Stat, REASONS } from "./ui";

type V = { id: number; product_id: number; name: string; category: string; status: string; size: string; color: string; color_hex: string; sku: string;
  stock: number; price: number; cost_price: number; image: string; sold30: number };

function Adjust({ v, onDone }: { v: V; onDone: (msg: string) => void }) {
  const [reason, setReason] = useState("reception");
  const [qty, setQty] = useState("");
  const [note, setNote] = useState("");
  const [busy, setBusy] = useState(false);
  const [err, setErr] = useState("");
  const out = reason === "loss";
  const setExact = reason === "adjustment";
  const delta = setExact ? Number(qty) - v.stock : (out ? -1 : 1) * Math.abs(Number(qty));
  const submit = async (e: React.FormEvent) => {
    e.preventDefault(); setErr("");
    if (!qty || !Number.isInteger(Number(qty)) || delta === 0) { setErr("Indiquez une quantité qui change le stock."); return; }
    setBusy(true);
    try { await api(`/api/admin/stock/${v.id}`, { method: "POST", json: { delta, reason, note } }); onDone(`✓ Stock mis à jour : ${v.name} ${v.size} ${v.color}`); }
    catch (x) { setErr((x as Error).message); } finally { setBusy(false); }
  };
  return (
    <form className="adm-adjust" onSubmit={submit}>
      <select value={reason} onChange={(e) => setReason(e.target.value)}>
        <option value="reception">+ Réception fournisseur</option>
        <option value="return">+ Retour client</option>
        <option value="loss">− Perte / casse</option>
        <option value="adjustment">= Inventaire (stock réel)</option>
      </select>
      <input type="number" min={0} placeholder={setExact ? "Stock compté" : "Quantité"} value={qty} onChange={(e) => setQty(e.target.value)} autoFocus />
      <input placeholder="Note (fournisseur, raison…)" value={note} onChange={(e) => setNote(e.target.value)} />
      <button className="adm-btn" disabled={busy}>{busy ? "…" : "Valider"}</button>
      <button type="button" className="adm-link" onClick={() => onDone("")}>Annuler</button>
      {qty && delta !== 0 && <small>{v.stock} → <b>{v.stock + delta}</b></small>}
      {err && <span className="adm-err">{err}</span>}
    </form>
  );
}

export default function Stock() {
  const { data, loading, error, reload } = useLoad<{ variants: V[]; movements: any[] }>("/api/admin/stock", (r) => r, { variants: [], movements: [] });
  const [tab, setTab] = useState<"stock" | "journal">("stock");
  const [filter, setFilter] = useState("");
  const [only, setOnly] = useState("");
  const [open, setOpen] = useState<number | null>(null);
  const [msg, setMsg] = useState("");
  const { data: acc } = useLoad<any>("/api/admin/settings", (r) => r.settings.accounting || {}, {});
  const low = Number(acc.lowStock ?? 3);

  const totals = useMemo(() => {
    const vs = data.variants;
    return { units: vs.reduce((s, v) => s + v.stock, 0), cost: vs.reduce((s, v) => s + v.stock * v.cost_price, 0), retail: vs.reduce((s, v) => s + v.stock * v.price, 0),
      out: vs.filter((v) => v.stock === 0).length, low: vs.filter((v) => v.stock > 0 && v.stock <= low).length, missing: vs.filter((v) => !v.cost_price && v.stock > 0).length };
  }, [data.variants, low]);

  const f = filter.toLowerCase();
  const list = data.variants.filter((v) => (!f || `${v.name} ${v.category} ${v.size} ${v.color} ${v.sku}`.toLowerCase().includes(f))
    && (!only || (only === "out" ? v.stock === 0 : only === "low" ? v.stock > 0 && v.stock <= low : v.stock > low)));

  const exportCsv = () => {
    const rows = [["Produit", "Catégorie", "Taille", "Couleur", "SKU", "Stock", "Vendus 30 j", "Prix", "Coût", "Valeur au coût"],
      ...list.map((v) => [v.name, v.category, v.size, v.color, v.sku, v.stock, v.sold30, v.price, v.cost_price, v.stock * v.cost_price])];
    const csv = rows.map((r) => r.map((c) => `"${String(c ?? "").replace(/"/g, '""')}"`).join(";")).join("\n");
    const a = document.createElement("a"); a.href = URL.createObjectURL(new Blob(["﻿" + csv], { type: "text/csv" })); a.download = "stock.csv"; a.click();
  };

  return (
    <div>
      <div className="adm-head">
        <div><h1>Gestion du stock</h1><p className="adm-muted">Chaque entrée et sortie est enregistrée dans le journal.</p></div>
        <button className="adm-btn ghost" onClick={exportCsv} disabled={!list.length}>Exporter CSV</button>
      </div>
      <div className="adm-stats">
        <Stat label="Pièces en stock" value={totals.units} />
        <Stat label="Valeur au prix d’achat" value={fmt(totals.cost)} sub={totals.missing ? <span className="adm-err">{totals.missing} variante(s) sans coût d’achat</span> : "Coûts renseignés"} />
        <Stat label="Valeur au prix de vente" value={fmt(totals.retail)} sub={`Marge potentielle ${fmt(totals.retail - totals.cost)}`} />
        <Stat tone={totals.out ? "bad" : undefined} label="En rupture" value={totals.out} />
        <Stat tone={totals.low ? "warn" : undefined} label={`Stock faible (≤ ${low})`} value={totals.low} />
      </div>

      <div className="adm-tabs">
        <button className={tab === "stock" ? "on" : ""} onClick={() => setTab("stock")}>Inventaire</button>
        <button className={tab === "journal" ? "on" : ""} onClick={() => setTab("journal")}>Journal des mouvements</button>
      </div>
      <Flash msg={msg} />
      {error && <p className="adm-err">{error}</p>}
      {loading && <p>Chargement…</p>}

      {tab === "stock" && <>
        <div className="adm-toolbar">
          <input placeholder="Produit, taille, couleur, SKU…" value={filter} onChange={(e) => setFilter(e.target.value)} />
          <select value={only} onChange={(e) => setOnly(e.target.value)}>
            <option value="">Toutes les variantes</option><option value="out">En rupture</option><option value="low">Stock faible</option><option value="ok">En stock</option>
          </select>
        </div>
        <table className="adm-table">
          <thead><tr><th /><th>Produit</th><th>Variante</th><th>SKU</th><th>Vendus 30 j</th><th>Coût / Prix</th><th>Stock</th><th /></tr></thead>
          <tbody>
            {list.map((v) => (
              <Fragment key={v.id}>
                <tr>
                  <td>{v.image && <img className="adm-thumb sm" src={asset(v.image)} alt="" />}</td>
                  <td><b>{v.name}</b><br /><small>{v.category}{v.status !== "published" && " · non publié"}</small></td>
                  <td>{v.color_hex && <i className="adm-dot" style={{ background: v.color_hex }} />}{v.size} {v.color}</td>
                  <td><small>{v.sku || "—"}</small></td>
                  <td>{v.sold30}{v.sold30 > 0 && v.stock > 0 && <><br /><small className="adm-muted">≈ {Math.max(1, Math.round((v.stock / v.sold30) * 30))} j de stock</small></>}</td>
                  <td><small>{v.cost_price ? fmt(v.cost_price) : <span className="adm-err">coût ?</span>} / {fmt(v.price)}</small></td>
                  <td><span className={`adm-qty ${v.stock === 0 ? "out" : v.stock <= low ? "low" : ""}`}>{v.stock}</span></td>
                  <td><button className="adm-link" onClick={() => setOpen(open === v.id ? null : v.id)}>Mouvement</button></td>
                </tr>
                {open === v.id && <tr className="adm-detail"><td colSpan={8}><Adjust v={v} onDone={(m) => { setOpen(null); setMsg(m); if (m) reload(); }} /></td></tr>}
              </Fragment>
            ))}
            {!loading && !list.length && <tr><td colSpan={8}>Aucune variante.</td></tr>}
          </tbody>
        </table>
      </>}

      {tab === "journal" && (
        <table className="adm-table">
          <thead><tr><th>Date</th><th>Article</th><th>Mouvement</th><th>Motif</th><th>Note</th><th>Par</th></tr></thead>
          <tbody>
            {data.movements.map((m) => (
              <tr key={m.id}>
                <td className="adm-nowrap">{date(m.created_at)}</td>
                <td>{m.name || <i>Article supprimé</i>}<br /><small>{m.size} {m.color}</small></td>
                <td><b className={m.delta > 0 ? "adm-ok" : "adm-err"}>{m.delta > 0 ? `+${m.delta}` : m.delta}</b></td>
                <td>{REASONS[m.reason] || m.reason}{m.order_number && <><br /><small>Cmd {m.order_number}</small></>}</td>
                <td><small>{m.note}</small></td>
                <td><small>{m.by_email || (m.order_number ? "Commande client" : "—")}</small></td>
              </tr>
            ))}
            {!data.movements.length && <tr><td colSpan={6}>Aucun mouvement enregistré.</td></tr>}
          </tbody>
        </table>
      )}
    </div>
  );
}
