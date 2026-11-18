"use client";

import { FormEvent, useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";
import { Building2, MapPin, UserRound, Mail, LockKeyhole, ArrowLeft, ChevronRight } from "lucide-react";

export default function OnboardingPage() {
  const router = useRouter();
  const [nursery, setNursery] = useState("حضانة البراعم التجريبية");
  const [slug, setSlug] = useState("al-baraem-demo");
  const [city, setCity] = useState("الكويت");
  const [manager, setManager] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const [success, setSuccess] = useState("");
  const [loading, setLoading] = useState(false);

  async function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setError(""); setSuccess(""); setLoading(true);
    try {
      const supabase = createClient();
      const { data: sessionData } = await supabase.auth.getSession();
      if (!sessionData.session) {
        const { data: signUpData, error: signUpError } = await supabase.auth.signUp({
          email, password,
          options: { data: { full_name: manager } }
        });
        if (signUpError) throw signUpError;
        if (!signUpData.session) {
          setSuccess("تم إنشاء طلب الحساب. أكّد بريدك الإلكتروني، ثم سجّل الدخول وافتح إعداد الحضانة مرة أخرى لإكمال التسجيل.");
          return;
        }
      }
      const { error: rpcError } = await supabase.rpc("create_nursery_with_admin", {
        nursery_name: nursery,
        nursery_slug: slug,
        nursery_city: city
      });
      if (rpcError) throw rpcError;
      setSuccess("تم إنشاء الحضانة وربط حسابك بصفة مدير. سيتم تحويلك إلى لوحة المنصة.");
      setTimeout(() => router.push("/"), 1200);
    } catch (e) {
      setError(e instanceof Error ? e.message : "تعذر إكمال الإعداد.");
    } finally {
      setLoading(false);
    }
  }

  return <main className="auth-page onboarding-page">
    <section className="auth-card onboarding-card">
      <Link href="/" className="back-link"><ChevronRight size={16}/> العودة إلى الرئيسية</Link>
      <div className="auth-brand"><span className="brand-mark">ر</span><span><b>روضة</b><small>RAWDA PLATFORM</small></span></div>
      <div className="auth-title"><div className="auth-symbol"><Building2 size={22}/></div><h1>إعداد حضانة جديدة</h1><p>أنشئ حساب المدير واربطه بحضانته التجريبية</p></div>
      <form onSubmit={submit} className="auth-form">
        <div className="form-section-title">بيانات الحضانة</div>
        <label>اسم الحضانة</label>
        <div className="field-wrap"><Building2 size={17}/><input required value={nursery} onChange={e=>setNursery(e.target.value)} /></div>
        <label>المعرّف المختصر (بالإنجليزية)</label>
        <div className="field-wrap"><span className="slug-prefix">rawda/</span><input required pattern="[a-z0-9-]+" value={slug} onChange={e=>setSlug(e.target.value.toLowerCase())} /></div>
        <label>المدينة</label>
        <div className="field-wrap"><MapPin size={17}/><input required value={city} onChange={e=>setCity(e.target.value)} /></div>
        <div className="form-section-title">بيانات مدير الحضانة</div>
        <label>اسم المدير</label>
        <div className="field-wrap"><UserRound size={17}/><input required value={manager} onChange={e=>setManager(e.target.value)} placeholder="الاسم الكامل"/></div>
        <label>البريد الإلكتروني</label>
        <div className="field-wrap"><Mail size={17}/><input type="email" required value={email} onChange={e=>setEmail(e.target.value)} placeholder="name@example.com"/></div>
        <label>كلمة المرور (8 أحرف على الأقل)</label>
        <div className="field-wrap"><LockKeyhole size={17}/><input type="password" minLength={8} required value={password} onChange={e=>setPassword(e.target.value)} placeholder="كلمة مرور قوية"/></div>
        {error && <div className="form-error">{error}</div>}
        {success && <div className="form-success">{success}</div>}
        <button className="primary-btn auth-submit" disabled={loading}>{loading ? "جارٍ إنشاء الحضانة..." : "إنشاء الحضانة والحساب"} <ArrowLeft size={17}/></button>
      </form>
      <p className="auth-foot">هذه شاشة تأسيس أولية. فعّل تأكيد البريد وإعدادات المصادقة في Supabase قبل الاختبار العام.</p>
    </section>
  </main>;
}
