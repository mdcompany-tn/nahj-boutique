import { createContext, useCallback, useContext, useEffect, useMemo, useState, type ReactNode } from "react";
import type { User } from "@supabase/supabase-js";
import { sitePath } from "./api";
import { supabase } from "./supabase";

/**
 * Customer accounts (separate from the owner's /admin login).
 *
 * - Guests can still order: the account is only needed for favorites and order history.
 * - The session is stored by supabase-js in localStorage and refreshed automatically.
 * - The password-recovery link redirects to /account, where `recovery` switches the
 *   page to the "new password" form.
 */

type Ctx = {
  user: User | null;
  ready: boolean;
  recovery: boolean;
  clearRecovery: () => void;
  signIn: (email: string, password: string) => Promise<void>;
  signUp: (email: string, password: string) => Promise<{ needsConfirm: boolean }>;
  signOut: () => Promise<void>;
  resetPassword: (email: string) => Promise<void>;
  updatePassword: (password: string) => Promise<void>;
};

const AuthCtx = createContext<Ctx>(null as any);
export const useAuth = () => useContext(AuthCtx);

const accountUrl = () => `${window.location.origin}${sitePath("account")}`;

/** French, human-readable messages for the common Supabase Auth errors. */
export function authMessage(raw: string): string {
  if (/invalid login credentials/i.test(raw)) return "Email ou mot de passe incorrect.";
  if (/email not confirmed/i.test(raw)) return "Confirmez votre email avant de vous connecter (vérifiez vos spams).";
  if (/user already registered|already been registered/i.test(raw)) return "Un compte existe déjà avec cet email. Connectez-vous.";
  if (/password should be at least/i.test(raw)) return "Le mot de passe doit contenir au moins 6 caractères.";
  // Supabase enforces a cooldown per email address and an hourly cap per project.
  const after = raw.match(/after (\d+) seconds?/i);
  if (after) return `Trop de tentatives. Réessayez dans ${after[1]} seconde${after[1] === "1" ? "" : "s"}.`;
  if (/email rate limit exceeded|rate limit.*email/i.test(raw)) return "Trop d’emails envoyés pour le moment. Réessayez dans une heure (ou configurez un SMTP).";
  if (/rate limit|too many|security purposes/i.test(raw)) return "Trop de tentatives. Réessayez dans quelques minutes.";
  if (/invalid email|unable to validate email/i.test(raw)) return "Adresse email invalide.";
  if (/signups? not allowed|signup is disabled/i.test(raw)) return "La création de compte est momentanément fermée.";
  return raw;
}

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [ready, setReady] = useState(false);
  const [recovery, setRecovery] = useState(false);

  useEffect(() => {
    let alive = true;
    supabase.auth.getSession().then(({ data }) => {
      if (!alive) return;
      setUser(data.session?.user ?? null);
      setReady(true);
    });
    const { data } = supabase.auth.onAuthStateChange((event, session) => {
      if (event === "PASSWORD_RECOVERY") setRecovery(true);
      setUser(session?.user ?? null);
    });
    return () => {
      alive = false;
      data.subscription.unsubscribe();
    };
  }, []);

  const signIn = useCallback(async (email: string, password: string) => {
    const { error } = await supabase.auth.signInWithPassword({ email: email.trim(), password });
    if (error) throw new Error(authMessage(error.message));
  }, []);

  const signUp = useCallback(async (email: string, password: string) => {
    const { data, error } = await supabase.auth.signUp({
      email: email.trim(),
      password,
      options: { emailRedirectTo: accountUrl() },
    });
    if (error) throw new Error(authMessage(error.message));
    // Supabase returns an empty identities array when the email is already used
    // (email enumeration protection), instead of an explicit error.
    const exists = Array.isArray(data.user?.identities) && data.user!.identities!.length === 0;
    if (exists) throw new Error("Un compte existe déjà avec cet email. Connectez-vous.");
    return { needsConfirm: !data.session };
  }, []);

  const signOut = useCallback(async () => {
    await supabase.auth.signOut();
    setRecovery(false);
  }, []);

  const resetPassword = useCallback(async (email: string) => {
    const { error } = await supabase.auth.resetPasswordForEmail(email.trim(), { redirectTo: accountUrl() });
    if (error) throw new Error(authMessage(error.message));
  }, []);

  const updatePassword = useCallback(async (password: string) => {
    const { error } = await supabase.auth.updateUser({ password });
    if (error) throw new Error(authMessage(error.message));
  }, []);

  const value = useMemo<Ctx>(
    () => ({ user, ready, recovery, clearRecovery: () => setRecovery(false), signIn, signUp, signOut, resetPassword, updatePassword }),
    [user, ready, recovery, signIn, signUp, signOut, resetPassword, updatePassword],
  );

  return <AuthCtx.Provider value={value}>{children}</AuthCtx.Provider>;
}
