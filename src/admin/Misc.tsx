import { useState } from "react";
import { api } from "../api";
import { useLoad, Flash, fmt, date } from "./ui";

export function Zones() {
  const { data, setData } = useLoad<any[]>("/api/admin/zones", (r) => r.zones, []);
  const [msg, setMsg] = useState("");
  const upd = (i: number, k: string, v: any) => setData(data.map((z, j) => j === i ? { ...z, [k]: v } : z));
  const save = async () => { try { await api("/api/admin/zones", { method: "PUT", json: data.map((z) => ({ ...z, fee: Number(z.fee) })) }); setMsg("✓ Frais enregistrés"); } catch (e) { setMsg((e as Error).message); } };
  return (
    <div><h1>Livraison — 24 gouvernorats</h1><Flash msg={msg} />
      <table className="adm-table"><thead><tr><th>Gouvernorat</th><th>Frais (DT)</th><th>Délai</th><th>Actif</th></tr></thead><tbody>
        {data.map((z, i) => <tr key={z.governorate}><td>{z.governorate} <small>{z.name_ar}</small></td>
          <td><input type="number" step="0.5" value={z.fee} onChange={(e) => upd(i, "fee", e.target.value)} /></td>
          <td><input value={z.delay} onChange={(e) => upd(i, "delay", e.target.value)} /></td>
          <td><input type="checkbox" checked={z.active} onChange={(e) => upd(i, "active", e.target.checked)} /></td></tr>)}
      </tbody></table>
      <button className="adm-btn" onClick={save}>Enregistrer</button>
    </div>
  );
}

export function Codes() {
  const { data, reload } = useLoad<any[]>("/api/admin/codes", (r) => r.codes, []);
  const [f, setF] = useState<any>({ code: "", kind: "percent", value: 10, min_subtotal: 0, max_uses: "", ends_at: "", active: true });
  const [msg, setMsg] = useState("");
  const save = async (c: any) => {
    try { await api("/api/admin/codes", { method: "POST", json: { ...c, max_uses: c.max_uses ? Number(c.max_uses) : null, ends_at: c.ends_at || null, starts_at: c.starts_at || null } }); setMsg("✓ Code enregistré"); reload(); }
    catch (e: any) { setMsg(e.issues?.join(" · ") || e.message); }
  };
  return (
    <div><h1>Codes promo</h1><Flash msg={msg} />
      <div className="adm-panel adm-form"><div className="adm-grid">
        <label>Code<input value={f.code} onChange={(e) => setF({ ...f, code: e.target.value.toUpperCase() })} /></label>
        <label>Type<select value={f.kind} onChange={(e) => setF({ ...f, kind: e.target.value })}><option value="percent">Pourcentage</option><option value="fixed">Montant fixe (DT)</option><option value="shipping">Livraison offerte</option></select></label>
        <label>Valeur<input type="number" value={f.value} onChange={(e) => setF({ ...f, value: e.target.value })} /></label>
        <label>Minimum d’achat<input type="number" value={f.min_subtotal} onChange={(e) => setF({ ...f, min_subtotal: e.target.value })} /></label>
        <label>Utilisations max<input type="number" value={f.max_uses} onChange={(e) => setF({ ...f, max_uses: e.target.value })} /></label>
        <label>Expire le<input type="date" value={f.ends_at} onChange={(e) => setF({ ...f, ends_at: e.target.value })} /></label>
      </div><button className="adm-btn" onClick={() => save(f)}>Créer / mettre à jour</button></div>
      <table className="adm-table"><thead><tr><th>Code</th><th>Remise</th><th>Utilisé</th><th>Expire</th><th>Actif</th><th /></tr></thead><tbody>
        {data.map((c) => <tr key={c.code}><td><b>{c.code}</b></td><td>{c.kind === "percent" ? `${c.value}%` : c.kind === "fixed" ? fmt(c.value) : "Livraison"}{c.min_subtotal > 0 && ` dès ${fmt(c.min_subtotal)}`}</td>
          <td>{c.uses}{c.max_uses ? ` / ${c.max_uses}` : ""}</td><td>{c.ends_at ? date(c.ends_at) : "—"}</td>
          <td><input type="checkbox" checked={c.active} onChange={(e) => save({ ...c, active: e.target.checked })} /></td>
          <td><button className="adm-link danger" onClick={async () => { if (confirm("Supprimer ce code ?")) { await api(`/api/admin/codes/${encodeURIComponent(c.code)}`, { method: "DELETE" }); reload(); } }}>Supprimer</button></td></tr>)}
      </tbody></table>
    </div>
  );
}

export function Reviews() {
  const { data, reload } = useLoad<any[]>("/api/admin/reviews", (r) => r.reviews, []);
  const act = async (id: number, m: string, json?: any) => { await api(`/api/admin/reviews/${id}`, { method: m, json }); reload(); };
  return (
    <div><h1>Avis clients</h1>
      <table className="adm-table"><tbody>{data.map((r) => <tr key={r.id}><td>{"★".repeat(r.rating)}</td><td><b>{r.name}</b> sur {r.product}<br />{r.body}</td><td>{date(r.created_at)}</td>
        <td className="adm-nowrap"><button className="adm-link" onClick={() => act(r.id, "PUT", { approved: !r.approved })}>{r.approved ? "Masquer" : "Approuver"}</button>
          <button className="adm-link danger" onClick={() => act(r.id, "DELETE")}>Supprimer</button></td></tr>)}
        {!data.length && <tr><td>Aucun avis.</td></tr>}</tbody></table>
    </div>
  );
}

export function Messages() {
  const { data, reload } = useLoad<any[]>("/api/admin/messages", (r) => r.messages, []);
  const act = async (id: number, m: string) => { await api(`/api/admin/messages/${id}`, { method: m }); reload(); };
  return (
    <div><h1>Messages</h1>
      {data.map((m) => <div key={m.id} className={`adm-panel ${m.read ? "" : "unread"}`}>
        <p><b>{m.name}</b> · {m.email} {m.phone} · <small>{date(m.created_at)}</small></p>
        {m.subject && <p><b>{m.subject}</b></p>}<p>{m.body}</p>
        {!m.read && <button className="adm-link" onClick={() => act(m.id, "PUT")}>Marquer lu</button>}
        <button className="adm-link danger" onClick={() => act(m.id, "DELETE")}>Supprimer</button>
      </div>)}
      {!data.length && <p>Aucun message.</p>}
    </div>
  );
}

export function Subscribers() {
  const { data } = useLoad<any[]>("/api/admin/subscribers", (r) => r.subscribers, []);
  return (
    <div><h1>Abonnés newsletter ({data.length})</h1>
      <button className="adm-btn ghost" onClick={() => navigator.clipboard.writeText(data.map((s) => s.email).join(", "))}>Copier les emails</button>
      <table className="adm-table"><tbody>{data.map((s) => <tr key={s.email}><td>{s.email}</td><td>{date(s.created_at)}</td></tr>)}</tbody></table>
    </div>
  );
}
