import { Link } from "react-router-dom";
import { useEffect } from "react";
import { img, money } from "../api";
import { useStore } from "../store";
import { t } from "../i18n";

export default function CartDrawer() {
  const { cart, cartOpen, setCartOpen, setQty, removeFromCart, lang, data } = useStore();
  const subtotal = cart.reduce((s, i) => s + i.price * i.qty, 0);
  const free = Number(data?.settings.shipping?.freeThreshold || 0);
  const left = Math.max(0, free - subtotal);
  useEffect(() => {
    const k = (e: KeyboardEvent) => e.key === "Escape" && setCartOpen(false);
    window.addEventListener("keydown", k);
    return () => window.removeEventListener("keydown", k);
  }, [setCartOpen]);
  return (
    <>
      <div className={`scrim ${cartOpen ? "show" : ""}`} onClick={() => setCartOpen(false)} />
      <aside className={`drawer ${cartOpen ? "open" : ""}`} aria-hidden={!cartOpen} aria-label={t(lang, "bag")}>
        <div className="drawer-head">
          <h2>{t(lang, "bag")} <sup>{cart.reduce((s, i) => s + i.qty, 0)}</sup></h2>
          <button className="close-x" onClick={() => setCartOpen(false)} aria-label="Fermer">×</button>
        </div>
        {free > 0 && cart.length > 0 && (
          <div className="free-meter">
            <p>{left > 0 ? <>Encore <b>{money(left)}</b> pour la livraison offerte</> : <>Livraison offerte débloquée</>}</p>
            <div className="meter"><span style={{ width: `${Math.min(100, (subtotal / free) * 100)}%` }} /></div>
          </div>
        )}
        <div className="drawer-body">
          {cart.length === 0 ? (
            <div className="drawer-empty">
              <p className="display-sm">{t(lang, "emptyBag")}</p>
              <Link className="btn" to="/shop" onClick={() => setCartOpen(false)}>{t(lang, "shop")}</Link>
            </div>
          ) : cart.map((i) => (
            <div className="line" key={i.variantId}>
              <Link to={`/product/${i.slug}`} onClick={() => setCartOpen(false)}><img src={img(i.image, 200)} alt="" /></Link>
              <div className="line-info">
                <p className="line-name">{i.name}</p>
                <p className="muted">{[i.size !== "Unique" && i.size, i.color].filter(Boolean).join(" · ")}</p>
                <div className="qty">
                  <button onClick={() => setQty(i.variantId, i.qty - 1)} aria-label="Moins">−</button>
                  <span>{i.qty}</span>
                  <button onClick={() => setQty(i.variantId, i.qty + 1)} aria-label="Plus" disabled={i.qty >= i.stock}>+</button>
                </div>
              </div>
              <div className="line-end">
                <p>{money(i.price * i.qty)}</p>
                <button className="link-btn" onClick={() => removeFromCart(i.variantId)}>Retirer</button>
              </div>
            </div>
          ))}
        </div>
        {cart.length > 0 && (
          <div className="drawer-foot">
            <div className="row"><span>{t(lang, "subtotal")}</span><b>{money(subtotal)}</b></div>
            <p className="muted small">Livraison et code promo calculés à l’étape suivante. {t(lang, "cod")}.</p>
            <Link to="/checkout" className="btn btn-block" onClick={() => setCartOpen(false)}>{t(lang, "checkout")}</Link>
          </div>
        )}
      </aside>
    </>
  );
}
