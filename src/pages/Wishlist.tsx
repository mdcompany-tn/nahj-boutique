import { Link } from "react-router-dom";
import { useAuth } from "../auth";
import { useStore } from "../store";
import ProductCard from "../components/ProductCard";

export default function Wishlist() {
  const { products, wishlist } = useStore();
  const { user } = useAuth();
  const list = products.filter((p) => wishlist.includes(p.id));

  if (!user) {
    return (
      <div className="shop">
        <header className="page-head"><p className="eyebrow">Favoris</p><h1 className="display-xl">Vos coups de cœur</h1></header>
        <div className="state-block">
          <p className="display-sm">Connectez-vous pour enregistrer vos favoris</p>
          <p className="muted">
            Les favoris sont liés à votre compte. Vous pouvez toujours commander en invité,
            sans créer de compte.
          </p>
          <div style={{ display: "flex", gap: "0.75rem", flexWrap: "wrap", justifyContent: "center", marginTop: "1.5rem" }}>
            <Link to="/account" className="btn">Se connecter</Link>
            <Link to="/shop" className="btn btn-outline">Parcourir la boutique</Link>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="shop">
      <header className="page-head"><p className="eyebrow">Favoris</p><h1 className="display-xl">Vos coups de cœur</h1></header>
      {list.length === 0 ? (
        <div className="state-block"><p className="display-sm">Aucun favori pour l’instant.</p><Link to="/shop" className="btn">Parcourir la boutique</Link></div>
      ) : <div className="grid-4">{list.map((p, i) => <ProductCard key={p.id} p={p} index={i} />)}</div>}
    </div>
  );
}
