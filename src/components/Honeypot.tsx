/** Hidden field that only bots fill in. The server silently drops submissions where it has a value. */
export default function Honeypot() {
  return (
    <div className="hp" aria-hidden="true">
      <label>Website<input type="text" name="website" tabIndex={-1} autoComplete="off" defaultValue="" /></label>
    </div>
  );
}
