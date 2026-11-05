import { useState } from "react";
import { api, asset } from "../api";
import { useLoad, Flash, ImageInput } from "./ui";

export default function Collections() {
  const { data, reload } = useLoad<any[]>("/api/admin/collections", (r) => r.collections, []);
  const [edit, setEdit] = useState<any>(null);
  const [msg, setMsg] = useState("");
  const save = async () => {
    try {
      const { id, created_at, ...payload } = edit;
      await api(id ? `/api/admin/collections/${id}` : "/api/admin/collections", { method: id ? "PUT" : "POST", json: { ...payload, position: Number(payload.position) } });
      setEdit(null); setMsg("✓ Collection enregistrée"); reload();
    } catch (e: any) { setMsg(e.issues?.join(" · ") || e.message); }
  };
  const del = async (c: any) => {
    if (!confirm(`Supprimer la collection « ${c.name} » ? Les produits restent en ligne.`)) return;
    await api(`/api/admin/collections/${c.id}`, { method: "DELETE" }); setMsg("✓ Collection supprimée"); reload();
  };
  return (
    <div>
      <h1>Collections</h1>
      <Flash msg={msg} />
      {edit ? (
        <div className="adm-panel adm-form">
          <div className="adm-grid">
            <label>Nom<input value={edit.name} onChange={(e) => setEdit({ ...edit, name: e.target.value })} /></label>
            <label>Nom (arabe)<input dir="rtl" value={edit.name_ar} onChange={(e) => setEdit({ ...edit, name_ar: e.target.value })} /></label>
            <label>Accroche<input value={edit.tagline} onChange={(e) => setEdit({ ...edit, tagline: e.target.value })} /></label>
            <label>Ordre<input type="number" value={edit.position} onChange={(e) => setEdit({ ...edit, position: e.target.value })} /></label>
          </div>
          <label>Description<textarea rows={3} value={edit.description} onChange={(e) => setEdit({ ...edit, description: e.target.value })} /></label>
          <ImageInput value={edit.image} onChange={(v) => setEdit({ ...edit, image: v })} />
          <label className="adm-inline"><input type="checkbox" checked={edit.visible} onChange={(e) => setEdit({ ...edit, visible: e.target.checked })} /> Visible sur la boutique</label>
          <div className="adm-actions"><button className="adm-btn" onClick={save}>Enregistrer</button><button className="adm-btn ghost" onClick={() => setEdit(null)}>Annuler</button></div>
        </div>
      ) : (
        <>
          <div className="adm-toolbar"><button className="adm-btn" onClick={() => setEdit({ name: "", name_ar: "", tagline: "", description: "", image: "", position: data.length + 1, visible: true })}>+ Nouvelle collection</button></div>
          <div className="adm-cards">
            {data.map((c) => (
              <div key={c.id} className="adm-panel">
                {c.image && <img src={asset(c.image)} alt="" />}
                <h3>{c.name} {!c.visible && <small>(masquée)</small>}</h3>
                <p><small>{c.tagline}</small></p>
                <button className="adm-link" onClick={() => setEdit({ ...c })}>Modifier</button>
                <button className="adm-link danger" onClick={() => del(c)}>Supprimer</button>
              </div>
            ))}
          </div>
        </>
      )}
    </div>
  );
}
