/** French, human-readable messages for the common Supabase Auth errors. */
export function authMessage(raw: string): string {
  // Cloudflare Turnstile (Supabase > Attack Protection).
  if (/captcha/i.test(raw)) return "La vérification anti-robot a échoué. Rechargez la page et réessayez.";
  // SMTP down / not configured: Supabase cannot deliver the confirmation or reset email.
  if (/error sending (confirmation|recovery|invite|magic link|email)|error sending email|unable to send email/i.test(raw)) {
    return "Impossible d’envoyer l’email pour le moment. Réessayez dans quelques minutes.";
  }
  if (/invalid login credentials/i.test(raw)) return "Email ou mot de passe incorrect.";
  if (/email not confirmed/i.test(raw)) return "Confirmez votre email avant de vous connecter (vérifiez vos spams).";
  if (/user already registered|already been registered/i.test(raw)) return "Un compte existe déjà avec cet email. Connectez-vous.";
  if (/password should be at least/i.test(raw)) return "Le mot de passe doit contenir au moins 6 caractères.";
  // Supabase enforces a cooldown per email address and an hourly cap per project.
  const after = raw.match(/after (\d+) seconds?/i);
  if (after) return `Trop de tentatives. Réessayez dans ${after[1]} seconde${after[1] === "1" ? "" : "s"}.`;
  if (/email rate limit exceeded|rate limit.*email/i.test(raw)) return "Trop d’emails envoyés pour le moment. Réessayez dans une heure.";
  if (/over_request_rate_limit|request rate limit|too many requests|\b429\b/i.test(raw)) return "Trop de tentatives en peu de temps. Réessayez dans quelques minutes.";
  if (/rate limit|too many|security purposes/i.test(raw)) return "Trop de tentatives. Réessayez dans quelques minutes.";
  if (/invalid email|unable to validate email/i.test(raw)) return "Adresse email invalide.";
  if (/signups? not allowed|signup is disabled/i.test(raw)) return "La création de compte est momentanément fermée.";
  return raw;
}

/** Message shown when Turnstile is enabled but the visitor has no token yet. */
export const CAPTCHA_PENDING = "Merci de valider la vérification anti-robot avant de continuer.";
