import { Link } from "react-router-dom";

/** Customer accounts are not used: checkout is guest-only and orders are tracked by number + phone. */
export default function Account() {
  return (
    <div className="account">
      <header className="page-head">
        <p className="eyebrow">Compte</p>
        <h1 className="display-lg">Pas besoin de compte</h1>
      </header>
      <section className="section">
        <p className="muted">
          Vous pouvez commander en tant qu’invité. Pour suivre votre commande, gardez le
          numéro reçu après l’achat et le téléphone utilisé lors de la commande.
        </p>
        <div style={{ display: "flex", gap: "0.75rem", flexWrap: "wrap", marginTop: "1.5rem" }}>
          <Link to="/track" className="btn">Suivre ma commande</Link>
          <Link to="/shop" className="btn btn-outline">Parcourir la boutique</Link>
        </div>
      </section>
    </div>
  );
}
