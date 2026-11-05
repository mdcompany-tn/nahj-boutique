import { asset } from "../api";
import { useStore } from "../store";

/** NAHJ wordmark: a street-sign plaque (the enamel "nahj" plates of Tunis). Name and image are editable in /admin. */
export default function Logo({ light = false }: { light?: boolean }) {
  const { data } = useStore();
  const b = data?.settings.brand || {};
  if (b.logoImage) return <img src={asset(b.logoImage)} alt={b.name || "NAHJ"} className="logo-img" />;
  return (
    <span className={`logo ${light ? "light" : ""}`}>
      <span className="logo-plaque"><span className="logo-ar">{b.nameAr || "نهج"}</span></span>
      <span className="logo-name">{b.name || "NAHJ"}</span>
    </span>
  );
}
