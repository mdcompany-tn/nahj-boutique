import { createContext, useCallback, useContext, useEffect, useMemo, useState, type ReactNode } from "react";
import { useNavigate } from "react-router-dom";
import type { User } from "@supabase/supabase-js";
import { sitePath } from "./api";
import { authMessage } from "./authMessages";
import { AUTH_LINK_ARRIVAL, supabase } from "./supabase";

/**
 * Customer accounts (separate from the owner's /admin login).
 *
 * - Guests can still order: the account is only needed for favorites and order history.
 * - The session is stored by supabase-js in localStorage and refreshed automatically.
 * - The password-recovery link redirects to /account, where `recovery` switches the
 *   page to the "new password" form.
 * - `captchaToken` is only sent when Cloudflare Turnstile is configured.
 */

type Ctx = {
  user: User | null;
  ready: boolean;
  recovery: boolean;
  clearRecovery: () => void;
  signIn: (email: string, password: string, captchaToken?: string) => Promise<void>;
  signUp: (email: string, password: string, captchaToken?: string) => Promise<{ needsConfirm: boolean }>;
  signOut: () => Promise<void>;
  resetPassword: (email: string, captchaToken?: string) => Promise<void>;
  updatePassword: (password: string) => Promise<void>;
};

const AuthCtx = createContext<Ctx>(null as any);
export const useAuth = () => useContext(AuthCtx);

const accountUrl = () => `${window.location.origin}${sitePath("account")}`;

export { authMessage };

export function AuthProvider({ children }: { children: ReactNode }) {
  const navigate = useNavigate();
  const [user, setUser] = useState<User | null>(null);
  const [ready, setReady] = useState(false);
  const [recovery, setRecovery] = useState(false);

  // Confirmation / recovery emails can land on the site root when Supabase falls
  // back to its Site URL. Once the session is restored, put the customer on
  // /account (new password screen included) instead of leaving them on the home page.
  useEffect(() => {
    if (!ready || !AUTH_LINK_ARRIVAL) return;
    const target = sitePath("account").replace(/\/+$/, "");
    if (window.location.pathname.replace(/\/+$/, "") !== target) {
      navigate("/account", { replace: true });
    }
  }, [ready, navigate]);

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

  const signIn = useCallback(async (email: string, password: string, captchaToken?: string) => {
    const { error } = await supabase.auth.signInWithPassword({
      email: email.trim(),
      password,
      options: captchaToken ? { captchaToken } : undefined,
    });
    if (error) throw new Error(authMessage(error.message));
  }, []);

  const signUp = useCallback(async (email: string, password: string, captchaToken?: string) => {
    const { data, error } = await supabase.auth.signUp({
      email: email.trim(),
      password,
      options: { emailRedirectTo: accountUrl(), ...(captchaToken ? { captchaToken } : {}) },
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

  const resetPassword = useCallback(async (email: string, captchaToken?: string) => {
    const { error } = await supabase.auth.resetPasswordForEmail(email.trim(), {
      redirectTo: accountUrl(),
      ...(captchaToken ? { captchaToken } : {}),
    });
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
