"use client";

import { FormEvent, useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";
import { LockKeyhole, Mail, ArrowLeft, Sprout, Chrome, UserRound, Baby } from "lucide-react";

type Mode = "login" | "signup" | "link";
type EmailMode = "password" | "otp";

export default function LoginPage() {
  const router = useRouter();
  const [mode, setMode] = useState<Mode>("login");
  const [emailMode, setEmailMode] = useState<EmailMode>("password");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [fullName, setFullName] = useState("");
  const [nurserySlug, setNurserySlug] = useState("");
  const [childCode, setChildCode] = useState("");
  const [error, setError] = useState("");
  const [success, setSuccess] = useState("");
  const [loading, setLoading] = useState(false);

  async function routeUser(userId: string) {
    const supabase = createClient();
    const { data: membership } = await supabase.from("memberships").select("role").eq("user_id", userId).eq("is_active", true).order("created_at", { ascending: true }).limit(1).maybeSingle();
    router.replace(membership?.role === "parent" ? "/portal" : membership ? "/" : "/onboarding");
    router.refresh();
  }

  async function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault(); setError(""); setSuccess(""); setLoading(true);
    try {
      const supabase = createClient();
      if (mode === "link") {
        const { data: userData, error: userError } = await supabase.auth.getUser();
        if (userError || !userData.user) throw new Error("سجّل الدخول أولاً قبل ربط كود الطفل.");
        const { error: linkError } = await supabase.rpc("link_child_by_code", { nursery_slug_input: nurserySlug.trim().toLowerCase(), child_code_input: childCode.trim() });
        if (linkError) throw linkError;
        setSuccess("تم إرسال طلب ربط الطفل. إذا كانت الحضانة تشترط الموافقة، فسيظهر الربط بعد اعتمادها.");
        return;
      }
      if (mode === "signup") {
        const { data, error: signUpError } = await supabase.auth.signUp({ email, password, options: { data: { full_name: fullName }, emailRedirectTo: `${window.location.origin}/auth/callback?next=/onboarding` } });
        if (signUpError) throw signUpError;
        if (data.session) await routeUser(data.user!.id);
        else setSuccess("أرسلنا رسالة تأكيد إلى بريدك. افتحها لإكمال إنشاء الحساب ثم سجّل الدخول.");
        return;
      }
      if (emailMode === "otp") {
        const { error: otpError } = await supabase.auth.signInWithOtp({ email, options: { shouldCreateUser: false, emailRedirectTo: `${window.location.origin}/auth/callback` } });
        if (otpError) throw otpError;
        setSuccess("تم إرسال رابط تسجيل الدخول إلى بريدك الإلكتروني.");
        return;
      }
      const { data, error: signInError } = await supabase.auth.signInWithPassword({ email, password });
      if (signInError) throw signInError;
      await routeUser(data.user.id);
    } catch (e) {
      setError(e instanceof Error ? e.message : "تعذر إكمال العملية. تحقق من البيانات وحاول مجدداً.");
    } finally { setLoading(false); }
  }

  async function googleLogin() {
    setError(""); setLoading(true);
    try {
      const supabase = createClient();
      const next = new URLSearchParams(window.location.search).get("next") || "/";
      const { error: oauthError } = await supabase.auth.signInWithOAuth({ provider: "google", options: { redirectTo: `${window.location.origin}/auth/callback?next=${encodeURIComponent(next)}` } });
      if (oauthError) throw oauthError;
    } catch (e) { setError(e instanceof Error ? e.message : "تعذر بدء الدخول باستخدام Google."); setLoading(false); }
  }

  return <main className="auth-page"><section className="auth-card">
    <Link href="/" className="auth-brand"><span className="brand-mark">ر</span><span><b>روضة</b><small>RAWDA PLATFORM</small></span></Link>
    <div className="auth-title"><div className="auth-symbol"><LockKeyhole size={22}/></div><h1>{mode === "signup" ? "إنشاء حساب جديد" : mode === "link" ? "ربط حساب ولي الأمر" : "تسجيل الدخول"}</h1><p>دخول آمن إلى منصة روضة</p></div>
    <div className="auth-tabs"><button type="button" className={mode === "login" ? "selected" : ""} onClick={()=>{setMode("login");setError("");setSuccess("")}}>دخول</button><button type="button" className={mode === "signup" ? "selected" : ""} onClick={()=>{setMode("signup");setError("");setSuccess("")}}>حساب جديد</button><button type="button" className={mode === "link" ? "selected" : ""} onClick={()=>{setMode("link");setError("");setSuccess("")}}>كود الطفل</button></div>
    {mode !== "link" && <button type="button" className="google-btn" disabled={loading} onClick={googleLogin}><Chrome size={18}/> المتابعة باستخدام Google</button>}
    {mode === "login" && <div className="email-mode"><button type="button" className={emailMode === "password" ? "active" : ""} onClick={()=>setEmailMode("password")}>كلمة المرور</button><button type="button" className={emailMode === "otp" ? "active" : ""} onClick={()=>setEmailMode("otp")}>رابط إلى البريد</button></div>}
    <form onSubmit={submit} className="auth-form">
      {mode === "signup" && <><label>الاسم الكامل</label><div className="field-wrap"><UserRound size={17}/><input required value={fullName} onChange={e=>setFullName(e.target.value)} placeholder="الاسم الكامل"/></div></>}
      {mode !== "link" ? <><label>البريد الإلكتروني</label><div className="field-wrap"><Mail size={17}/><input type="email" autoComplete="email" required value={email} onChange={e=>setEmail(e.target.value)} placeholder="name@example.com"/></div>
      {(mode === "signup" || (mode === "login" && emailMode === "password")) && <><label>كلمة المرور</label><div className="field-wrap"><LockKeyhole size={17}/><input type="password" minLength={8} autoComplete={mode === "signup" ? "new-password" : "current-password"} required value={password} onChange={e=>setPassword(e.target.value)} placeholder="8 أحرف على الأقل"/></div></>}</> : <>
        <label>معرّف الحضانة</label><div className="field-wrap"><Sprout size={17}/><input required value={nurserySlug} onChange={e=>setNurserySlug(e.target.value)} placeholder="مثال: al-baraem"/></div>
        <label>كود الطفل</label><div className="field-wrap"><Baby size={17}/><input required value={childCode} onChange={e=>setChildCode(e.target.value)} placeholder="أدخل الكود الذي زودتك به الحضانة"/></div>
        <p className="auth-foot">يجب تسجيل الدخول أولاً، ثم استخدام بيانات الحضانة وكود الطفل لطلب الربط.</p>
      </>}
      {error && <div className="form-error">{error}</div>}{success && <div className="form-success">{success}</div>}
      <button className="primary-btn auth-submit" disabled={loading}>{loading ? "جارٍ التنفيذ..." : mode === "signup" ? "إنشاء الحساب" : mode === "link" ? "ربط الطفل بحسابي" : emailMode === "otp" ? "إرسال رابط الدخول" : "دخول إلى المنصة"}<ArrowLeft size={17}/></button>
    </form>
    {mode === "login" && <><div className="auth-divider"><span>أو</span></div><Link className="secondary-link" href="/onboarding"><Sprout size={17}/> إعداد حضانة جديدة</Link></>}
    <p className="auth-foot">تسجيل ولي الأمر يتطلب ربط الحساب بالطفل والتحقق من موافقة الحضانة.</p>
  </section></main>;
}
