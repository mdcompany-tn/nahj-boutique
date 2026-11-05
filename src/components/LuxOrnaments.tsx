/** Gold ornaments that float slowly from left to right across the featured band, forever. */
const ORNAMENTS = Array.from({ length: 16 }, (_, i) => ({
  top: (i * 37) % 92 + 3,
  size: 14 + ((i * 13) % 5) * 9,
  dur: 26 + ((i * 7) % 6) * 6,
  delay: -((i * 11) % 40) * 1.7,
  kind: i % 3,
}));
export function LuxOrnaments() {
  return (
    <>
      {ORNAMENTS.map((o, i) => (
        <span key={i} className="lux-fly" style={{ top: `${o.top}%`, animationDuration: `${o.dur}s`, animationDelay: `${o.delay}s` }}>
          <span className={`lux-orn k${o.kind}`} style={{ width: o.size, height: o.size, animationDelay: `${o.delay / 3}s` }}>
            <svg viewBox="0 0 40 40">
              {o.kind === 0 && <><rect x="8" y="8" width="24" height="24" /><rect x="8" y="8" width="24" height="24" transform="rotate(45 20 20)" /></>}
              {o.kind === 1 && <path d="M20 1l6 13 13 6-13 6-6 13-6-13L1 20l13-6z" />}
              {o.kind === 2 && <><path d="M20 4l16 16-16 16L4 20z" /><circle cx="20" cy="20" r="4" /></>}
            </svg>
          </span>
        </span>
      ))}
    </>
  );
}

/** Site-wide luxury background: a fixed layer behind every page with drifting gold pattern, glows and ornaments. */
export function SiteLux() {
  return (
    <div className="site-lux" aria-hidden="true">
      <span className="sl-orb s1" /><span className="sl-orb s2" /><span className="sl-orb s3" />
      <LuxOrnaments />
    </div>
  );
}
