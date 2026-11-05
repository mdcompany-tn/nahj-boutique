import { useEffect, useRef, useState } from "react";
import { api, asset } from "../api";

export function useLoad<T>(path: string, pick: (r: any) => T, initial: T) {
  const [data, setData] = useState<T>(initial);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const load = () => { setLoading(true); api(path).then((r) => { setData(pick(r)); setError(""); }).catch((e) => setError(e.message)).finally(() => setLoading(false)); };
  // eslint-disable-next-line react-hooks/exhaustive-deps
  useEffect(load, [path]);
  return { data, setData, loading, error, reload: load };
}

export function Flash({ msg }: { msg: string }) {
  if (!msg) return null;
  return <p className={msg.startsWith("✓") ? "adm-ok" : "adm-err"}>{msg}</p>;
}

export async function uploadFile(file: File): Promise<string> {
  if (file.size > 5.5 * 1024 * 1024) throw new Error("Fichier trop lourd (5 Mo max). Compressez la vidéo en MP4 (720p, 15 à 30 secondes).");
  const fd = new FormData(); fd.append("file", file);
  const r = await api<{ url: string }>("/api/admin/upload", { method: "POST", body: fd });
  return r.url;
}

export function ImageInput({ value, onChange, accept = "image/*", label = "Image" }: { value: string; onChange: (v: string) => void; accept?: string; label?: string }) {
  const ref = useRef<HTMLInputElement>(null);
  const [busy, setBusy] = useState(false);
  const [err, setErr] = useState("");
  return (
    <div className="adm-image">
      <span className="adm-label">{label}</span>
      <div className="adm-image-row">
        {value && (accept.startsWith("video") ? <video src={asset(value)} muted /> : <img src={asset(value)} alt="" />)}
        <input value={value} onChange={(e) => onChange(e.target.value)} placeholder="URL ou téléverser" />
        <button type="button" className="adm-btn ghost" disabled={busy} onClick={() => ref.current?.click()}>{busy ? "…" : "Téléverser"}</button>
        <input ref={ref} type="file" accept={accept} hidden onChange={async (e) => {
          const f = e.target.files?.[0]; if (!f) return;
          setBusy(true); setErr("");
          try { onChange(await uploadFile(f)); } catch (x) { setErr((x as Error).message); } finally { setBusy(false); e.target.value = ""; }
        }} />
      </div>
      {err && <p className="adm-err">{err}</p>}
    </div>
  );
}

export const fmt = (n: number) => `${Number(n).toLocaleString("fr-TN", { maximumFractionDigits: 3 })} DT`;
export const date = (s: string) => new Date(s).toLocaleString("fr-TN", { dateStyle: "short", timeStyle: "short" });
export const STATUS: Record<string, string> = { pending: "En attente", confirmed: "Confirmée", preparing: "En préparation", shipped: "Expédiée", delivered: "Livrée", cancelled: "Annulée", returned: "Retournée" };
export const day = (s: string) => new Date(s).toLocaleDateString("fr-TN", { dateStyle: "medium" });
export const isoDay = (d: Date) => new Date(d.getTime() - d.getTimezoneOffset() * 6e4).toISOString().slice(0, 10);
export const REASONS: Record<string, string> = { manual: "Modification fiche", reception: "Réception", adjustment: "Ajustement inventaire", loss: "Perte / casse",
  return: "Retour client", cancelled: "Commande annulée", returned: "Commande retournée", reactivated: "Commande réactivée", order: "Vente" };
export const EXPENSE_CATS: Record<string, string> = { achat: "Achat marchandise", livraison: "Livraison", pub: "Publicité", emballage: "Emballage",
  loyer: "Loyer", salaire: "Salaires", shooting: "Shooting photo", logiciel: "Logiciels & abonnements", autre: "Autre" };

export function Stat({ label, value, sub, tone }: { label: string; value: React.ReactNode; sub?: React.ReactNode; tone?: "good" | "bad" | "warn" | "accent" }) {
  return <div className={`adm-stat ${tone || ""}`}><span>{label}</span><b>{value}</b>{sub && <small>{sub}</small>}</div>;
}

/** Simple vertical bar chart: one bar per point, label under every nth bar. */
export function Bars({ points, value, label, format, every = 1 }: { points: any[]; value: (p: any) => number; label: (p: any) => string; format: (n: number) => string; every?: number }) {
  const max = Math.max(1, ...points.map(value));
  return (
    <div className="adm-bars" role="img" aria-label="Graphique">
      {points.map((p, i) => (
        <div key={i} title={`${label(p)} : ${format(value(p))}`}>
          <span style={{ height: `${(value(p) / max) * 100}%` }} />
          <small>{i % every === 0 || i === points.length - 1 ? label(p) : " "}</small>
        </div>
      ))}
    </div>
  );
}

export function Meter({ value, max, tone }: { value: number; max: number; tone?: string }) {
  return <span className={`adm-meter ${tone || ""}`}><i style={{ width: `${Math.min(100, max ? (value / max) * 100 : 0)}%` }} /></span>;
}
