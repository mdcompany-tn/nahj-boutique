import { Link } from "react-router-dom";
import { useStore } from "../store";
import ProductCard from "../components/ProductCard";

export default function Wishlist() {
  const { products, wishlist } = useStore();
  const list = products.filter((p) => wishlist.includes(p.id));
  return (
    <div className="shop">
      <header className="page-head"><p className="eyebrow">Favoris</p><h1 className="display-xl">Vos coups de cœur</h1></header>
      {list.length === 0 ? (
        <div className="state-block"><p className="display-sm">Aucun favori pour l’instant.</p><Link to="/shop" className="btn">Parcourir la boutique</Link></div>
      ) : <div className="grid-4">{list.map((p, i) => <ProductCard key={p.id} p={p} index={i} />)}</div>}
    </div>
  );
}
