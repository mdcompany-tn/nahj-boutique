import { useEffect, useMemo, useState } from "react";
import { Link } from "react-router-dom";
import { img, money } from "../api";
import { useStore } from "../store";

const norm = (s: string) => s.normalize("NFD").replace(/[̀-ͯ]/g, "").toLowerCase();

export default function SearchOverlay({ onClose }: { onClose: () => void }) {
  const { products } = useStore();
  const [q, setQ] = useState("");
  useEffect(() => {
    const k = (e: KeyboardEvent) => e.key === "Escape" && onClose();
    window.addEventListener("keydown", k);
    return () => window.removeEventListener("keydown", k);
  }, [onClose]);
  const results = useMemo(() => {
    const n = norm(q.trim());
    if (!n) return [];
    return products.filter((p) => norm([p.name, p.name_ar, p.category, p.description, ...p.tags].join(" ")).includes(n)).slice(0, 8);
  }, [q, products]);
  return (
    <div className="search-overlay" role="dialog" aria-modal="true" aria-label="Recherche">
      <button className="close-x" onClick={onClose} aria-label="Fermer">×</button>
      <input autoFocus value={q} onChange={(e) => setQ(e.target.value)} placeholder="Lin, jebba, sandales…" aria-label="Rechercher un article" />
      <div className="search-results">
        {q && results.length === 0 && <p className="muted">Aucun article pour « {q} ».</p>}
        {results.map((p) => (
          <Link key={p.id} to={`/product/${p.slug}`} onClick={onClose} className="search-hit">
            <img src={img(p.images[0], 200)} alt="" />
            <span><b>{p.name}</b><small>{p.category}</small></span>
            <span>{money(p.price)}</span>
          </Link>
        ))}
      </div>
    </div>
  );
}
