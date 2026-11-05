import { Link } from "react-router-dom";
import { useStore } from "../store";
import { img } from "../api";

export default function Collections() {
  const { data, lang } = useStore();
  return (
    <div className="collections-page">
      <header className="page-head">
        <p className="eyebrow">Collections</p>
        <h1 className="display-xl">Chaque collection<br /><em>porte le nom d’une rue.</em></h1>
      </header>
      <div className="col-list">
        {data?.collections.map((c, i) => (
          <Link key={c.id} to={`/collections/${c.slug}`} className={`col-row ${i % 2 ? "rev" : ""}`}>
            <img src={img(c.image, 900)} alt="" loading="lazy" />
            <div>
              <span className="col-num">0{i + 1}</span>
              <p className="eyebrow">{c.tagline}</p>
              <h2 className="display-lg">{lang === "ar" && c.name_ar ? c.name_ar : c.name}</h2>
              <p>{c.description}</p>
              <span className="link-arrow">{c.product_count} pièces — découvrir</span>
            </div>
          </Link>
        ))}
      </div>
    </div>
  );
}
