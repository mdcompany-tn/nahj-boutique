import { useMemo, useState } from "react";
import { Link, useParams } from "react-router-dom";
import { img, totalStock } from "../api";
import { useStore } from "../store";
import ProductCard from "../components/ProductCard";
import NotFound from "./NotFound";

type Mode = "all" | "new" | "best" | "offers" | "collection";
const TITLES: Record<Exclude<Mode, "collection">, [string, string, string]> = {
  all: ["La boutique", "Toutes les pièces", "Lin, indigo, cuir et halfa : la garde-robe complète de la maison."],
  new: ["Nouveautés", "Fraîchement sorties", "Les dernières pièces arrivées de nos ateliers."],
  best: ["Meilleures ventes", "Ce que Tunis porte", "Les pièces que nos clients recommandent le plus."],
  offers: ["Offres", "Prix doux", "Une sélection à prix réduit, tant que le stock dure."],
};

export default function Shop({ mode }: { mode: Mode }) {
  const { products, data, loading } = useStore();
  const { slug } = useParams();
  const [cat, setCat] = useState("");
  const [gender, setGender] = useState("");
  const [size, setSize] = useState("");
  const [sort, setSort] = useState(mode === "best" ? "best" : mode === "new" ? "new" : "featured");
  const [inStock, setInStock] = useState(false);

  const collection = mode === "collection" ? data?.collections.find((c) => c.slug === slug) : undefined;

  const base = useMemo(() => {
    switch (mode) {
      case "new": return products.filter((p) => p.is_new);
      case "offers": return products.filter((p) => p.compare_at_price && p.compare_at_price > p.price);
      case "collection": return collection ? products.filter((p) => p.collection_ids.includes(collection.id)) : [];
      default: return products;
    }
  }, [mode, products, collection]);

  const cats = [...new Set(base.map((p) => p.category).filter(Boolean))];
  const sizes = [...new Set(base.flatMap((p) => p.variants.map((v) => v.size)))].filter((s) => s !== "Unique");

  const list = useMemo(() => {
    const l = base.filter((p) =>
      (!cat || p.category === cat) &&
      (!gender || p.gender === gender || p.gender === "unisexe") &&
      (!size || p.variants.some((v) => v.size === size && v.stock > 0)) &&
      (!inStock || totalStock(p) > 0));
    const s = [...l];
    if (sort === "price-asc") s.sort((a, b) => a.price - b.price);
    else if (sort === "price-desc") s.sort((a, b) => b.price - a.price);
    else if (sort === "best") s.sort((a, b) => b.sold - a.sold || Number(b.featured) - Number(a.featured));
    else if (sort === "new") s.sort((a, b) => Number(b.is_new) - Number(a.is_new) || +new Date(b.created_at) - +new Date(a.created_at));
    else s.sort((a, b) => Number(b.featured) - Number(a.featured) || a.position - b.position);
    return s;
  }, [base, cat, gender, size, sort, inStock]);

  if (mode === "collection" && !loading && data && !collection) return <NotFound />;
  const [eyebrow, title, intro] = collection ? [collection.tagline, collection.name, collection.description] : TITLES[mode as Exclude<Mode, "collection">];

  return (
    <div className="shop">
      {collection ? (
        <header className="collection-hero">
          <img src={img(collection.image, 1800)} alt="" />
          <div><p className="eyebrow">{eyebrow}</p><h1 className="display-xl">{title}</h1><p>{intro}</p></div>
        </header>
      ) : (
        <header className="page-head">
          <p className="eyebrow">{eyebrow}</p>
          <h1 className="display-xl">{title}</h1>
          <p>{intro}</p>
        </header>
      )}
      <div className="filters" role="toolbar" aria-label="Filtres">
        <div className="chips">
          <button className={!cat ? "chip on" : "chip"} onClick={() => setCat("")}>Tout</button>
          {cats.map((c) => <button key={c} className={cat === c ? "chip on" : "chip"} onClick={() => setCat(c)}>{c}</button>)}
        </div>
        <div className="selects">
          <select value={gender} onChange={(e) => setGender(e.target.value)} aria-label="Pour">
            <option value="">Pour tous</option><option value="femme">Femme</option><option value="homme">Homme</option>
          </select>
          {sizes.length > 0 && (
            <select value={size} onChange={(e) => setSize(e.target.value)} aria-label="Taille">
              <option value="">Toutes tailles</option>{sizes.map((s) => <option key={s}>{s}</option>)}
            </select>
          )}
          <select value={sort} onChange={(e) => setSort(e.target.value)} aria-label="Trier">
            <option value="featured">Sélection</option><option value="new">Nouveautés</option><option value="best">Meilleures ventes</option>
            <option value="price-asc">Prix croissant</option><option value="price-desc">Prix décroissant</option>
          </select>
          <label className="check"><input type="checkbox" checked={inStock} onChange={(e) => setInStock(e.target.checked)} /> En stock</label>
        </div>
      </div>
      {loading && !products.length ? <div className="grid-4">{Array.from({ length: 8 }).map((_, i) => <div key={i} className="pcard skeleton" />)}</div>
        : list.length === 0 ? (
          <div className="state-block"><p className="display-sm">Aucune pièce ne correspond.</p><Link to="/shop" className="btn">Voir toute la boutique</Link></div>
        ) : (
          <>
            <p className="count muted">{list.length} pièce{list.length > 1 ? "s" : ""}</p>
            <div className="grid-4">{list.map((p, i) => <ProductCard key={p.id} p={p} index={i} />)}</div>
          </>
        )}
    </div>
  );
}
