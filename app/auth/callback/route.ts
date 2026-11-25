import { NextResponse, type NextRequest } from "next/server";
import { createServerClient } from "@supabase/ssr";

type CookieOptions = {
  domain?: string;
  expires?: Date;
  httpOnly?: boolean;
  maxAge?: number;
  path?: string;
  sameSite?: boolean | "lax" | "strict" | "none";
  secure?: boolean;
  priority?: "low" | "medium" | "high";
  partitioned?: boolean;
};

export async function GET(request: NextRequest) {
  const { searchParams, origin } = new URL(request.url);
  const code = searchParams.get("code");
  const requestedNext = searchParams.get("next") ?? "/";
  const next = requestedNext.startsWith("/") && !requestedNext.startsWith("//") ? requestedNext : "/";
  if (!code) return NextResponse.redirect(`${origin}/login?error=oauth_callback_missing_code`);

  let response = NextResponse.redirect(`${origin}${next}`);
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const key = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
  if (!url || !key) return NextResponse.redirect(`${origin}/login?error=supabase_not_configured`);

  const supabase = createServerClient(url, key, {
    cookies: {
      getAll: () => request.cookies.getAll(),
      setAll(cookies: { name: string; value: string; options?: CookieOptions }[]) {
        cookies.forEach(({ name, value, options }) => request.cookies.set(name, value));
        response = NextResponse.redirect(`${origin}${next}`);
        cookies.forEach(({ name, value, options }) => response.cookies.set(name, value, options));
      },
    },
  });
  const { error } = await supabase.auth.exchangeCodeForSession(code);
  if (error) return NextResponse.redirect(`${origin}/login?error=oauth_exchange_failed`);
  if (!searchParams.has("next")) {
    const { data: userData } = await supabase.auth.getUser();
    if (userData.user) {
      const { data: membership } = await supabase.from("memberships").select("role").eq("user_id", userData.user.id).eq("is_active", true).order("created_at", { ascending: true }).limit(1).maybeSingle();
      response.headers.set("Location", `${origin}${membership?.role === "parent" ? "/portal" : membership ? "/" : "/onboarding"}`);
    }
  }
  return response;
}
