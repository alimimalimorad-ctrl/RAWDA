"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { Baby, GraduationCap, Users, CalendarCheck, BookOpen, Star, ClipboardList, RefreshCw, CheckCircle2 } from "lucide-react";
import ManagementShell from "@/components/management-shell";
import { createClient } from "@/lib/supabase/client";

type Summary = { children:number; classrooms:number; teachers:number; attendance:number };

export default function Home() {
  const router=useRouter();
  const [name,setName]=useState("حضانتي");
  const [summary,setSummary]=useState<Summary>({children:0,classrooms:0,teachers:0,attendance:0});
  const [loading,setLoading]=useState(true),[error,setError]=useState(""),[role,setRole]=useState("");

  async function load() {
    setLoading(true); setError("");
    try {
      const supabase=createClient();
      const {data:{user},error:authError}=await supabase.auth.getUser();
      if(authError||!user){router.replace("/login");return;}
      const {data:memberships,error:membershipError}=await supabase.from("memberships").select("tenant_id,role").eq("user_id",user.id).eq("is_active",true).order("created_at",{ascending:true}).limit(1);
      if(membershipError)throw membershipError;
      const membership=memberships?.[0];
      if(!membership){router.replace("/onboarding");return;}
      if(membership.role==="parent"){router.replace("/portal");return;}
      setRole(membership.role);
      const [{data:tenant,error:tenantError},children,rooms,teachers,attendance]=await Promise.all([
        supabase.from("tenants").select("name").eq("id",membership.tenant_id).maybeSingle(),
        supabase.from("children").select("id",{count:"exact",head:true}).eq("tenant_id",membership.tenant_id),
        supabase.from("classrooms").select("id",{count:"exact",head:true}).eq("tenant_id",membership.tenant_id),
        supabase.from("teachers").select("id",{count:"exact",head:true}).eq("tenant_id",membership.tenant_id),
        supabase.from("attendance").select("id",{count:"exact",head:true}).eq("tenant_id",membership.tenant_id).eq("attendance_date",new Date().toLocaleDateString("en-CA"))
      ]);
      if(tenantError)throw tenantError;
      for(const result of [children,rooms,teachers,attendance])if(result.error)throw result.error;
      setName(tenant?.name||"حضانتي");
      setSummary({children:children.count||0,classrooms:rooms.count||0,teachers:teachers.count||0,attendance:attendance.count||0});
    } catch(e) { setError(e instanceof Error?e.message:"تعذر تحميل لوحة التحكم."); }
    finally { setLoading(false); }
  }
  useEffect(()=>{void load();},[]);
  const cards=[
    {label:"الأطفال المسجلون",value:summary.children,icon:Baby,href:"/children",note:"ملفات الأطفال"},
    {label:"الفصول الدراسية",value:summary.classrooms,icon:GraduationCap,href:"/classrooms",note:"الفصول والمجموعات"},
    {label:"المعلمات",value:summary.teachers,icon:Users,href:"/staff",note:"فريق الحضانة"},
    {label:"سجلات حضور اليوم",value:summary.attendance,icon:CalendarCheck,href:"/attendance",note:"الحضور والغياب"}
  ];
  return <ManagementShell title="لوحة التحكم" subtitle={`مرحباً بك في ${name}، هذه مؤشرات مباشرة من قاعدة بيانات الحضانة.`}>
    <div className="notice"><div className="notice-icon"><CheckCircle2 size={19}/></div><div><b>قاعدة البيانات متصلة</b><p>الأرقام التالية تُقرأ مباشرة من سجلات حضانتك، ولا تُستخدم بيانات تجريبية.</p></div></div>
    {error&&<p className="form-error">{error}</p>}
    <div className="section-heading"><div><h2>ملخص الحضانة</h2><p>إحصاءات محدثة عند فتح الصفحة</p></div><button className="outline-btn" onClick={()=>void load()} disabled={loading}><RefreshCw size={15}/> تحديث البيانات</button></div>
    <div className="stats-grid">{cards.map((card,index)=>{const Icon=card.icon;return <Link className="stat-card" href={card.href} key={card.label} style={{textDecoration:"none",color:"inherit"}}><div className={`stat-icon tone-${index}`}><Icon size={20}/></div><div className="stat-label">{card.label}</div><div className="stat-bottom"><strong>{loading?"—":card.value}</strong></div><div className="stat-foot">{card.note}</div></Link>;})}</div>
    <div className="two-col">
      <section className="panel"><div className="panel-head"><div><h2>إدارة الحضانة</h2><p>انتقل مباشرة إلى القسم المطلوب</p></div></div><div className="simple-list">
        <Link href="/children"><Baby size={18}/> ملفات الأطفال والتسجيل</Link><Link href="/attendance"><CalendarCheck size={18}/> الحضور والغياب اليومي</Link><Link href="/staff"><Users size={18}/> المعلمات وأولياء الأمور</Link><Link href="/classrooms"><GraduationCap size={18}/> الفصول وتوزيع الأطفال</Link>
      </div></section>
      <section className="panel"><div className="panel-head"><div><h2>التعليم والمتابعة</h2><p>المناهج وقياس تقدم الطفل</p></div></div><div className="simple-list">
        <Link href="/curriculum"><BookOpen size={18}/> المناهج والكتب</Link><Link href="/assessments"><Star size={18}/> التقييمات والمهارات</Link><Link href="/reports"><ClipboardList size={18}/> تقارير تقدم الأطفال</Link><Link href="/portal"><Users size={18}/> بوابة ولي الأمر</Link>
      </div></section>
    </div>
    <p className="stat-foot" style={{marginTop:18}}>الصلاحيات تُطبّق من قاعدة البيانات عبر RLS. دور الحساب: {role||"—"}.</p>
  </ManagementShell>;
}
