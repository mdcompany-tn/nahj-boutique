import { useState } from "react";
import { Link } from "react-router-dom";
import { img, money, totalStock, colorImage as imageFor, type Product } from "../api";
import { useStore } from "../store";
import { t } from "../i18n";

export default function ProductCard({ p, index = 0 }: { p: Product; index?: number }) {
  const { wishlist, toggleWish, lang } = useStore();
  const stock = totalStock(p);
  const wished = wishlist.includes(p.id);
  const onSale = p.compare_at_price && p.compare_at_price > p.price;
  const colors = [...new Map(p.variants.filter((v) => v.color_hex).map((v) => [v.color, v.color_hex])).entries()];
  const [shown, setShown] = useState("");
  const colorImage = (c: string) => imageFor(p, c);
  return (
    <article className="pcard" style={{ animationDelay: `${Math.min(index, 8) * 60}ms` }}>
      <Link to={`/product/${p.slug}`} className="pcard-media">
        <img src={img(shown || p.images[0], 700)} alt={p.name} loading="lazy" />
        {p.images[1] && !shown && <img className="pcard-alt" src={img(p.images[1], 700)} alt="" loading="lazy" />}
        <span className="pcard-tags">
          {p.is_new && <span className="tag">Nouveau</span>}
          {onSale && <span className="tag tag-henna">-{Math.round((1 - p.price / p.compare_at_price!) * 100)}%</span>}
          {stock === 0 && <span className="tag tag-ink">{t(lang, "soldOut")}</span>}
        </span>
      </Link>
      <button className={`wish ${wished ? "on" : ""}`} onClick={() => toggleWish(p.id)} aria-label={wished ? "Retirer des favoris" : "Ajouter aux favoris"} aria-pressed={wished}>
        <svg viewBox="0 0 24 24"><path d="M12 20s-7-4.4-7-10a4 4 0 0 1 7-2.6A4 4 0 0 1 19 10c0 5.6-7 10-7 10Z" /></svg>
      </button>
      <div className="pcard-info">
        <div>
          <p className="pcard-cat">{p.category}</p>
          <h3><Link to={`/product/${p.slug}`}>{lang === "ar" && p.name_ar ? p.name_ar : p.name}</Link></h3>
          {colors.length > 1 && <div className="swatches">{colors.map(([c, hex]) => <button type="button" key={c} title={c} aria-label={c} className={shown && shown === colorImage(c) ? "on" : ""} style={{ background: hex }}
            onMouseEnter={() => setShown(colorImage(c))} onFocus={() => setShown(colorImage(c))} onClick={() => setShown(colorImage(c))} />)}</div>}
        </div>
        <p className="pcard-price">
          {onSale && <s>{money(p.compare_at_price!)}</s>}
          <span>{money(p.price)}</span>
        </p>
      </div>
    </article>
  );
}
