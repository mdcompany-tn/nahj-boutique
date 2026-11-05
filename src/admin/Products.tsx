import { useRef, useState } from "react";
import { api, asset, sitePath, type Product } from "../api";
import { useLoad, fmt, Flash, ImageInput, uploadFile } from "./ui";
import { ColorField, ColorNames } from "./colors";

const blank = (): any => ({ name: "", name_ar: "", slug: "", description: "", description_ar: "", details: "", care: "", price: 0, cost_price: 0, compare_at_price: null,
  category: "", gender: "unisexe", collection_ids: [], images: [], tags: [], status: "draft", featured: false, is_new: true, position: 0,
  variants: [{ size: "M", color: "", color_hex: "", sku: "", stock: 0, image: "" }] });

function VariantPhoto({ value, images, onChange }: { value: string; images: string[]; onChange: (v: string) => void }) {
  const ref = useRef<HTMLInputElement>(null);
  const [busy, setBusy] = useState(false);
  const options = Array.from(new Set([...images, ...(value ? [value] : [])]));
  return (
    <div className="adm-vphoto">
      {value ? <img src={asset(value)} alt="" /> : <span className="adm-vphoto-empty">-</span>}
      <select value={value} onChange={(e) => onChange(e.target.value)}>
        <option value="">Photo principale</option>
        {options.map((src, k) => <option key={src} value={src}>{images.includes(src) ? `Photo ${images.indexOf(src) + 1}` : `Photo dédiée ${k + 1}`}</option>)}
      </select>
      <button type="button" className="adm-link" disabled={busy} onClick={() => ref.current?.click()}>{busy ? "…" : "Téléverser"}</button>
      <input ref={ref} type="file" accept="image/*" hidden onChange={async (e) => {
        const f = e.target.files?.[0]; if (!f) return;
        setBusy(true);
        try { onChange(await uploadFile(f)); } catch (x) { alert((x as Error).message); } finally { setBusy(false); e.target.value = ""; }
      }} />
    </div>
  );
}

function Editor({ initial, collections, onDone }: { initial: any; collections: any[]; onDone: (msg: string) => void }) {
  const [p, setP] = useState<any>(initial);
  const [msg, setMsg] = useState("");
  const [busy, setBusy] = useState(false);
  const set = (k: string, v: any) => setP({ ...p, [k]: v });
  const setV = (i: number, k: string, v: any) => set("variants", p.variants.map((x: any, j: number) => j === i ? { ...x, [k]: v } : x));
  const save = async () => {
    setBusy(true); setMsg("");
    try {
      const payload = { ...p, price: Number(p.price), cost_price: Number(p.cost_price) || 0, position: Number(p.position) || 0, compare_at_price: p.compare_at_price ? Number(p.compare_at_price) : null,
        images: p.images.filter(Boolean), variants: p.variants.map((v: any) => ({ ...v, image: v.image || "", stock: Number(v.stock) })) };
      delete payload.sold; delete payload.created_at; delete payload.updated_at; delete payload.id;
      if (p.id) await api(`/api/admin/products/${p.id}`, { method: "PUT", json: payload });
      else await api("/api/admin/products", { method: "POST", json: payload });
      onDone("✓ Produit enregistré");
    } catch (e: any) { setMsg(e.issues?.join(" · ") || e.message); } finally { setBusy(false); }
  };
  /** A color's photo applies to every size of that color. */
  const setColorImage = (color: string, i: number, img: string) =>
    set("variants", p.variants.map((x: any, j: number) => (j === i || (color && x.color === color) ? { ...x, image: img } : x)));
  const addSizes = (sizes: string[]) => {
    const color = p.variants[0]?.color || ""; const hex = p.variants[0]?.color_hex || "";
    set("variants", [...p.variants.filter((v: any) => v.id || v.stock > 0 || v.color), ...sizes.filter((s) => !p.variants.some((v: any) => v.size === s && v.color === color)).map((s) => ({ size: s, color, color_hex: hex, sku: "", stock: 0, image: p.variants[0]?.image || "" }))]);
  };
  return (
    <div className="adm-panel adm-form">
      <h2>{p.id ? `Modifier « ${initial.name} »` : "Nouveau produit"}</h2>
      <div className="adm-grid">
        <label>Nom<input value={p.name} onChange={(e) => set("name", e.target.value)} /></label>
        <label>Nom (arabe)<input dir="rtl" value={p.name_ar} onChange={(e) => set("name_ar", e.target.value)} /></label>
        <label>Prix (DT)<input type="number" step="0.001" value={p.price} onChange={(e) => set("price", e.target.value)} /></label>
        <label>Prix barré (promo)<input type="number" step="0.001" value={p.compare_at_price ?? ""} onChange={(e) => set("compare_at_price", e.target.value || null)} /></label>
        <label>Prix d’achat / coût (DT)<input type="number" step="0.001" min={0} value={p.cost_price ?? 0} onChange={(e) => set("cost_price", e.target.value)} /></label>
        <div className="adm-margin"><span className="adm-label">Marge par pièce</span>{Number(p.cost_price) > 0
          ? <b className={Number(p.price) - Number(p.cost_price) > 0 ? "adm-ok" : "adm-err"}>{fmt(Number(p.price) - Number(p.cost_price))} · {Math.round(((Number(p.price) - Number(p.cost_price)) / Math.max(0.001, Number(p.price))) * 100)} %</b>
          : <small className="adm-muted">Saisissez le coût pour voir la marge</small>}</div>
        <label>Catégorie<input list="cats" value={p.category} onChange={(e) => set("category", e.target.value)} /></label>
        <label>Pour<select value={p.gender} onChange={(e) => set("gender", e.target.value)}><option value="unisexe">Unisexe</option><option value="femme">Femme</option><option value="homme">Homme</option></select></label>
        <label>Statut<select value={p.status} onChange={(e) => set("status", e.target.value)}><option value="published">Publié</option><option value="draft">Brouillon</option><option value="hidden">Masqué</option></select></label>
        <label>Ordre d’affichage<input type="number" value={p.position} onChange={(e) => set("position", e.target.value)} /></label>
      </div>
      <datalist id="cats">{["Chemises", "Vestes", "Sweats", "Robes", "Pantalons", "T-shirts", "Accessoires", "Chaussures"].map((c) => <option key={c} value={c} />)}</datalist>
      <div className="adm-checks">
        <label><input type="checkbox" checked={p.featured} onChange={(e) => set("featured", e.target.checked)} /> Mis en avant</label>
        <label><input type="checkbox" checked={p.is_new} onChange={(e) => set("is_new", e.target.checked)} /> Nouveauté</label>
        {collections.map((c) => <label key={c.id}><input type="checkbox" checked={p.collection_ids.includes(c.id)} onChange={(e) => set("collection_ids", e.target.checked ? [...p.collection_ids, c.id] : p.collection_ids.filter((x: number) => x !== c.id))} /> {c.name}</label>)}
      </div>
      <label>Description<textarea rows={3} value={p.description} onChange={(e) => set("description", e.target.value)} /></label>
      <label>Description (arabe)<textarea dir="rtl" rows={2} value={p.description_ar} onChange={(e) => set("description_ar", e.target.value)} /></label>
      <div className="adm-grid">
        <label>Matières & coupe<input value={p.details} onChange={(e) => set("details", e.target.value)} /></label>
        <label>Entretien<input value={p.care} onChange={(e) => set("care", e.target.value)} /></label>
        <label>Mots-clés (virgules)<input value={p.tags.join(", ")} onChange={(e) => set("tags", e.target.value.split(",").map((s) => s.trim()).filter(Boolean))} /></label>
      </div>
      <h3>Photos</h3>
      {p.images.map((src: string, i: number) => (
        <div key={i} className="adm-row">
          <ImageInput label={i === 0 ? "Photo principale" : `Photo ${i + 1}`} value={src} onChange={(v) => set("images", p.images.map((x: string, j: number) => j === i ? v : x))} />
          <button type="button" className="adm-link" onClick={() => set("images", p.images.filter((_: any, j: number) => j !== i))}>Retirer</button>
        </div>
      ))}
      <button type="button" className="adm-btn ghost" onClick={() => set("images", [...p.images, ""])}>+ Ajouter une photo</button>
      <h3>Tailles, couleurs & stock</h3>
      <p><small>Raccourcis : <button type="button" className="adm-link" onClick={() => addSizes(["XS", "S", "M", "L", "XL"])}>XS → XL</button> · <button type="button" className="adm-link" onClick={() => addSizes(["Unique"])}>Taille unique</button> · <button type="button" className="adm-link" onClick={() => addSizes(["36", "37", "38", "39", "40", "41", "42"])}>Pointures 36 → 42</button></small></p>
      <table className="adm-table"><thead><tr><th>Taille</th><th>Couleur & teinte</th><th>Photo de la couleur</th><th>SKU</th><th>Stock</th><th /></tr></thead><tbody>
        {p.variants.map((v: any, i: number) => (
          <tr key={v.id ?? `n${i}`}>
            <td><input value={v.size} onChange={(e) => setV(i, "size", e.target.value)} /></td>
            <td><ColorField name={v.color} hex={v.color_hex || ""} onChange={(color, color_hex) => set("variants", p.variants.map((x: any, j: number) => j === i ? { ...x, color, color_hex } : x))} /></td>
            <td><VariantPhoto value={v.image || ""} images={p.images.filter(Boolean)} onChange={(img) => setColorImage(v.color, i, img)} /></td>
            <td><input value={v.sku} onChange={(e) => setV(i, "sku", e.target.value)} /></td>
            <td><input type="number" min={0} value={v.stock} onChange={(e) => setV(i, "stock", e.target.value)} /></td>
            <td><button type="button" className="adm-link" disabled={p.variants.length < 2} onClick={() => set("variants", p.variants.filter((_: any, j: number) => j !== i))}>×</button></td>
          </tr>
        ))}
      </tbody></table>
      <ColorNames />
      <p className="adm-muted"><small>Tapez le nom de la couleur (rouge, bleu, noir…) et le rond prend la teinte tout seul ; ou cliquez sur le rond pour choisir une teinte, et le nom se remplit tout seul. La photo choisie pour une couleur s’applique à toutes les tailles de cette couleur. Sur la boutique, cliquer sur la couleur affiche cette photo.</small></p>
      <button type="button" className="adm-btn ghost" onClick={() => set("variants", [...p.variants, { ...p.variants[p.variants.length - 1], id: undefined, stock: 0 }])}>+ Variante</button>
      <Flash msg={msg} />
      <div className="adm-actions">
        <button className="adm-btn" onClick={save} disabled={busy}>{busy ? "Enregistrement…" : "Enregistrer"}</button>
        <button className="adm-btn ghost" onClick={() => onDone("")}>Annuler</button>
      </div>
    </div>
  );
}

export default function Products() {
  const { data, loading, reload } = useLoad<Product[]>("/api/admin/products", (r) => r.products, []);
  const { data: cols } = useLoad<any[]>("/api/admin/collections", (r) => r.collections, []);
  const [edit, setEdit] = useState<any>(null);
  const [msg, setMsg] = useState("");
  const [filter, setFilter] = useState("");
  const del = async (p: Product) => {
    if (!confirm(`Supprimer « ${p.name} » ? Cette action est définitive.`)) return;
    await api(`/api/admin/products/${p.id}`, { method: "DELETE" }); setMsg("✓ Produit supprimé"); reload();
  };
  if (edit) return <Editor initial={edit} collections={cols} onDone={(m) => { setEdit(null); setMsg(m); if (m) reload(); }} />;
  const list = data.filter((p) => !filter || p.name.toLowerCase().includes(filter.toLowerCase()) || p.category.toLowerCase().includes(filter.toLowerCase()));
  return (
    <div>
      <h1>Produits</h1>
      <div className="adm-toolbar">
        <input placeholder="Filtrer…" value={filter} onChange={(e) => setFilter(e.target.value)} />
        <button className="adm-btn" onClick={() => setEdit(blank())}>+ Nouveau produit</button>
      </div>
      <Flash msg={msg} />
      {loading && <p>Chargement…</p>}
      <table className="adm-table">
        <thead><tr><th /><th>Produit</th><th>Prix</th><th>Stock</th><th>Vendus</th><th>Statut</th><th /></tr></thead>
        <tbody>{list.map((p) => {
          const stock = p.variants.reduce((s, v) => s + v.stock, 0);
          return (
            <tr key={p.id}>
              <td>{p.images[0] && <img className="adm-thumb" src={asset(p.images[0])} alt="" />}</td>
              <td><b>{p.name}</b><br /><small>{p.category} · {p.variants.length} variantes</small></td>
              <td>{fmt(p.price)}{p.cost_price ? <><br /><small className="adm-muted">coût {fmt(p.cost_price)} · marge {Math.round(((p.price - p.cost_price) / Math.max(0.001, p.price)) * 100)} %</small></> : <><br /><small className="adm-err">coût non renseigné</small></>}{p.compare_at_price ? <><br /><s><small>{fmt(p.compare_at_price)}</small></s></> : null}</td>
              <td className={stock === 0 ? "adm-err" : ""}>{stock}</td>
              <td>{p.sold}</td>
              <td><span className={`st st-${p.status}`}>{p.status === "published" ? "Publié" : p.status === "draft" ? "Brouillon" : "Masqué"}</span></td>
              <td className="adm-nowrap">
                <button className="adm-link" onClick={() => setEdit(structuredClone(p))}>Modifier</button>
                <button className="adm-link" onClick={() => setEdit({ ...structuredClone(p), id: undefined, slug: "", name: p.name + " (copie)", status: "draft", variants: p.variants.map((v) => ({ ...v, id: undefined })) })}>Dupliquer</button>
                <a className="adm-link" href={sitePath(`product/${p.slug}`)} target="_blank" rel="noreferrer">Voir</a>
                <button className="adm-link danger" onClick={() => del(p)}>Supprimer</button>
              </td>
            </tr>
          );
        })}</tbody>
      </table>
    </div>
  );
}
