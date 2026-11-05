/** Named colors used to sync the color name and its hex in the product editor. */
const PALETTE: [string, string, string[]][] = [
  ["Noir", "#111111", ["black", "اسود", "أسود", "ak7el", "aswed"]],
  ["Blanc", "#ffffff", ["white", "ابيض", "أبيض", "abyedh", "abyadh"]],
  ["Écru", "#f3ecd9", ["ecru", "off white", "cassé", "blanc casse"]],
  ["Beige", "#d9c3a0", ["بيج", "bej"]],
  ["Sable", "#c9ad85", ["sand", "رملي"]],
  ["Camel", "#b5824e", ["كاميل"]],
  ["Marron", "#6b4428", ["brown", "بني", "بنّي", "chocolat", "9ahwi", "قهوي"]],
  ["Kaki", "#7a7448", ["khaki", "كاكي"]],
  ["Olive", "#6b6b2f", ["زيتي", "zitouni"]],
  ["Vert", "#2e7d32", ["green", "اخضر", "أخضر", "akhdher", "akhdar"]],
  ["Vert sapin", "#1f4d3a", ["vert foncé", "dark green"]],
  ["Menthe", "#9ad5b6", ["mint", "vert d'eau"]],
  ["Bleu", "#1e5bb8", ["blue", "ازرق", "أزرق", "azre9", "azra9", "azrak"]],
  ["Bleu ciel", "#8cc4ec", ["sky blue", "light blue", "سماوي", "bleu clair"]],
  ["Marine", "#1b2a4a", ["bleu marine", "navy", "كحلي", "k7li"]],
  ["Indigo", "#2f3d73", ["نيلي"]],
  ["Turquoise", "#20b2aa", ["فيروزي"]],
  ["Rouge", "#c62828", ["red", "احمر", "أحمر", "a7mer", "ahmar"]],
  ["Bordeaux", "#6d1a2a", ["burgundy", "عنابي", "grenat"]],
  ["Rose", "#e98aa6", ["pink", "وردي", "roz", "rouz"]],
  ["Rose poudré", "#e8c4c4", ["nude", "rose pale"]],
  ["Fuchsia", "#c2185b", ["فوشيا"]],
  ["Orange", "#ef7d22", ["برتقالي", "bortou9ali"]],
  ["Terracotta", "#c3623f", ["brique", "rouille"]],
  ["Moutarde", "#d1a227", ["mustard", "خردلي"]],
  ["Jaune", "#f2c81f", ["yellow", "اصفر", "أصفر", "asfer", "sfar"]],
  ["Violet", "#6a3d9a", ["purple", "بنفسجي", "mauve"]],
  ["Lilas", "#b8a2d6", ["lilac", "lavande"]],
  ["Gris", "#8e8e8e", ["grey", "gray", "رمادي", "rmedi", "rmadi"]],
  ["Gris clair", "#cfcfcf", ["light grey", "gris perle"]],
  ["Anthracite", "#3a3d40", ["charcoal", "gris foncé"]],
  ["Argent", "#c0c0c0", ["silver", "فضي"]],
  ["Doré", "#c9a24a", ["gold", "or", "ذهبي"]],
];

const norm = (s: string) => s.normalize("NFD").replace(/[̀-ͯ]/g, "").toLowerCase().trim().replace(/\s+/g, " ");
const INDEX = new Map<string, string>();
for (const [name, hex, aliases] of PALETTE) for (const a of [name, ...aliases]) INDEX.set(norm(a), hex);

/** Hex for a typed color name (French, English, Arabic or Tunisian spelling), if known. */
export function hexForName(name: string): string | undefined {
  return INDEX.get(norm(name));
}

const rgb = (h: string) => { const n = parseInt(h.replace("#", "").padEnd(6, "0").slice(0, 6), 16); return [n >> 16, (n >> 8) & 255, n & 255]; };

/** Closest named color for a picked hex. */
export function nameForHex(hex: string): string {
  const [r, g, b] = rgb(hex);
  let best = PALETTE[0][0], dist = Infinity;
  for (const [name, h] of PALETTE) {
    const [r2, g2, b2] = rgb(h);
    const rm = (r + r2) / 2;
    const d = (2 + rm / 256) * (r - r2) ** 2 + 4 * (g - g2) ** 2 + (2 + (255 - rm) / 256) * (b - b2) ** 2;
    if (d < dist) { dist = d; best = name; }
  }
  return best;
}

/** Color name + round swatch. Typing a known name sets the swatch; picking a swatch color sets the name. */
export function ColorField({ name, hex, onChange }: { name: string; hex: string; onChange: (name: string, hex: string) => void }) {
  const shown = hex || "#cccccc";
  return (
    <div className="adm-color">
      <label className="adm-swatch" title="Choisir la teinte" style={{ background: hex || "repeating-conic-gradient(#ddd 0 25%, #fff 0 50%) 50% / 10px 10px" }}>
        <input type="color" value={shown} onChange={(e) => onChange(nameForHex(e.target.value), e.target.value)} aria-label="Teinte" />
      </label>
      <input list="adm-color-names" value={name} placeholder="ex. Rouge" onChange={(e) => { const v = e.target.value; onChange(v, hexForName(v) || hex); }} />
    </div>
  );
}

/** Suggestions for the color name field; render once per page. */
export function ColorNames() {
  return <datalist id="adm-color-names">{PALETTE.map(([n]) => <option key={n} value={n} />)}</datalist>;
}
