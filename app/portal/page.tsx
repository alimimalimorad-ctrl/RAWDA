"use client";
import { useEffect, useState } from "react";
import Link from "next/link";
import { createClient } from "@/lib/supabase/client";
import { CalendarCheck, BookOpen, Star, Megaphone, Baby, LogOut, RefreshCw } from "lucide-react";

type Child = { id:string; full_name:string; child_code:string; birth_date:string|null; tenant_id:string };
type Attendance = { id:string; attendance_date:string; status:string; note:string|null };
type Lesson = { id:string; lesson_date:string; title:string; summary:string|null; classrooms?:{name:string}|null };
type Assessment = { id:string; observed_on:string; level:string; observation:string|null; skills?:{name:string}|null };
type Announcement = { id:string; title:string; body:string; published_at:string|null };
const statusLabels:Record<string,string>={present:"حاضر",absent:"غائب",late:"متأخر",excused:"بعذر"};
const levelLabels:Record<string,string>={not_started:"لم يبدأ",learning:"قيد التعلم",mastered_with_help:"أتقن بمساعدة",mastered_independently:"أتقن باستقلالية"};
export default function ParentPortal(){
 const supabase=createClient(); const [loading,setLoading]=useState(true); const [error,setError]=useState(""); const [parentName,setParentName]=useState("");
 const [children,setChildren]=useState<Child[]>([]); const [selected,setSelected]=useState(""); const [attendance,setAttendance]=useState<Attendance[]>([]); const [lessons,setLessons]=useState<Lesson[]>([]); const [assessments,setAssessments]=useState<Assessment[]>([]); const [announcements,setAnnouncements]=useState<Announcement[]>([]);
 async function init(){setLoading(true);setError("");const {data:{user}}=await supabase.auth.getUser();if(!user){setError("يرجى تسجيل الدخول بحساب ولي الأمر.");setLoading(false);return;}
  const {data:profile}=await supabase.from("profiles").select("full_name").eq("id",user.id).maybeSingle();setParentName(profile?.full_name||"ولي الأمر");
  const {data:links,error:e}=await supabase.from("parent_children").select("child_id,tenant_id,children(id,full_name,child_code,birth_date,tenant_id)").eq("parent_user_id",user.id).eq("can_view_reports",true);
  if(e){setError(e.message);setLoading(false);return;}const kids=(links||[]).map((x:any)=>Array.isArray(x.children)?x.children[0]:x.children).filter(Boolean) as Child[];setChildren(kids);if(kids.length){setSelected(old=>kids.some(k=>k.id===old)?old:kids[0].id);}setLoading(false);
 }
 async function loadChild(id:string){const child=children.find(c=>c.id===id);if(!child)return;setError("");
  const [{data:a,error:ae},{data:en,error:ee},{data:as,error:ase},{data:an,error:ane}]=await Promise.all([
   supabase.from("attendance").select("id,attendance_date,status,note").eq("child_id",id).eq("tenant_id",child.tenant_id).order("attendance_date",{ascending:false}).limit(20),
   supabase.from("enrollments").select("classroom_id,classrooms(id,name)").eq("child_id",id).eq("tenant_id",child.tenant_id).eq("status","active").is("end_date",null),
   supabase.from("assessments").select("id,observed_on,level,observation,skills(name)").eq("child_id",id).eq("tenant_id",child.tenant_id).order("observed_on",{ascending:false}).limit(20),
   supabase.from("announcements").select("id,title,body,published_at").eq("tenant_id",child.tenant_id).not("published_at","is",null).order("published_at",{ascending:false}).limit(10)
  ]);
  if(ae||ee||ase||ane){setError([ae,ee,ase,ane].filter(Boolean).map(x=>x!.message).join(" · "));}
  setAttendance(a||[]);setAssessments((as||[]) as any);setAnnouncements(an||[]);
  const roomIds=(en||[]).map((x:any)=>x.classroom_id).filter(Boolean);if(roomIds.length){const {data:l,error:le}=await supabase.from("daily_lessons").select("id,lesson_date,title,summary,classrooms(name)").eq("tenant_id",child.tenant_id).in("classroom_id",roomIds).order("lesson_date",{ascending:false}).limit(20);if(le)setError(le.message);setLessons((l||[]) as any);}else setLessons([]);
 }
 useEffect(()=>{void init();},[]);useEffect(()=>{if(selected)void loadChild(selected);},[selected,children.length]);
 const current=children.find(c=>c.id===selected);const signOut=async()=>{await supabase.auth.signOut();location.href="/login";};
 return <main className="portal-page"><header className="portal-top"><Link href="/" className="brand"><span className="brand-mark">ر</span><span><b>روضة</b><small>RAWDA · بوابة الأسرة</small></span></Link><div className="portal-user"><span>مرحباً، {parentName}</span><button className="icon-btn" onClick={signOut} title="تسجيل الخروج"><LogOut size={17}/></button></div></header>
 <section className="portal-content"><div className="portal-heading"><div><div className="eyebrow">بوابة ولي الأمر</div><h1>متابعة طفلك</h1><p>الحضور والتعلم والتقييمات في مكان واحد.</p></div><button className="outline-btn" onClick={()=>void init()}><RefreshCw size={15}/> تحديث البيانات</button></div>
 {error&&<div className="form-error">{error}</div>}{loading?<div className="panel empty-state">جارٍ تحميل بيانات الأسرة...</div>:children.length===0?<div className="panel empty-state">لا توجد أطفال مرتبطون بحسابك بعد. يمكنك طلب الربط باستخدام معرّف الحضانة وكود الطفل، وستراجع الحضانة الطلب.<Link className="secondary-link" href="/login">فتح خيار ربط الطفل</Link></div>:<>
 <div className="panel child-picker"><label htmlFor="child-select">اختر الطفل</label><select id="child-select" value={selected} onChange={e=>setSelected(e.target.value)}>{children.map(c=><option key={c.id} value={c.id}>{c.full_name} — {c.child_code}</option>)}</select>{current&&<div className="child-summary"><div className="child-avatar"><Baby size={23}/></div><div><b>{current.full_name}</b><small>كود الطفل: <strong>{current.child_code}</strong>{current.birth_date?` · تاريخ الميلاد: ${current.birth_date}`:""}</small></div></div>}</div>
 <div className="portal-grid"><section className="panel"><div className="portal-section-title"><CalendarCheck/><div><h2>الحضور والغياب</h2><p>آخر السجلات المسجلة</p></div></div>{attendance.length?<div className="portal-records">{attendance.map(a=><div className="portal-record" key={a.id}><span>{a.attendance_date}</span><b className={`attendance-badge ${a.status}`}>{statusLabels[a.status]||a.status}</b>{a.note&&<small>{a.note}</small>}</div>)}</div>:<p className="empty-state">لا توجد سجلات حضور حتى الآن.</p>}</section>
 <section className="panel"><div className="portal-section-title"><BookOpen/><div><h2>ماذا تعلم اليوم؟</h2><p>الدروس والأنشطة المسجلة للفصل</p></div></div>{lessons.length?<div className="portal-records">{lessons.map(l=><article className="portal-lesson" key={l.id}><small>{l.lesson_date}{l.classrooms?.name?` · ${l.classrooms.name}`:""}</small><b>{l.title}</b>{l.summary&&<p>{l.summary}</p>}</article>)}</div>:<p className="empty-state">لا توجد دروس منشورة لهذا الطفل بعد.</p>}</section>
 <section className="panel"><div className="portal-section-title"><Star/><div><h2>التقييم والتقدم</h2><p>مستوى اكتساب المهارات</p></div></div>{assessments.length?<div className="portal-records">{assessments.map(a=><article className="portal-lesson" key={a.id}><small>{a.observed_on}</small><b>{a.skills?.name||"مهارة تعليمية"}</b><span className="level-chip">{levelLabels[a.level]||a.level}</span>{a.observation&&<p>{a.observation}</p>}</article>)}</div>:<p className="empty-state">لم تُسجل تقييمات بعد.</p>}</section>
 <section className="panel"><div className="portal-section-title"><Megaphone/><div><h2>إعلانات الحضانة</h2><p>آخر التحديثات المنشورة</p></div></div>{announcements.length?<div className="portal-records">{announcements.map(a=><article className="portal-lesson" key={a.id}><small>{a.published_at?new Date(a.published_at).toLocaleDateString("ar-KW"):""}</small><b>{a.title}</b><p>{a.body}</p></article>)}</div>:<p className="empty-state">لا توجد إعلانات حالياً.</p>}</section></div></>}
 <p className="portal-foot">تُعرض المعلومات المرتبطة بالأطفال الذين منحتك الحضانة صلاحية متابعتهم فقط.</p></section></main>;
}
