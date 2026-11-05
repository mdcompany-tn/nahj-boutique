import { Link } from "react-router-dom";
export default function NotFound() {
  return (
    <div className="state-block tall">
      <p className="eyebrow">Impasse</p>
      <h1 className="display-xl">Cette rue n’existe pas.</h1>
      <Link to="/" className="btn">Revenir à l’accueil</Link>
    </div>
  );
}
