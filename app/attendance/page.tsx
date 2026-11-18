"use client";
import { useEffect, useMemo, useState } from "react";
import { createClient } from "@/lib/supabase/client";
import ManagementShell from "@/components/management-shell";
import { CalendarDays, Check, Clock3, Search, Save, Users, X } from "lucide-react";

type Room={id:string;name:string};
type Child={id:string;full_name:string;child_code:string};
type Mark="present"|"absent"|"late"|"excused";
type Row=Child & {status:Mark;note:string;existing:boolean};
const labels:Record<Mark,string>={present:"حاضر",absent:"غائب",late:"متأخر",excused:"بعذر"};
const icons:Record<Mark,any>={present:Check,absent:X,late:Clock3,excused:CalendarDays};
export default function AttendancePage(){
 const supabase=createClient();
 const [tenant,setTenant]=useState(""); const [rooms,setRooms]=useState<Room[]>([]);
 const [room,setRoom]=useState(""); const [date,setDate]=useState(new Date().toLocaleDateString("en-CA"));
 const [rows,setRows]=useState<Row[]>([]); const [loading,setLoading]=useState(true); const [saving,setSaving]=useState(false);
 const [error,setError]=useState(""); const [notice,setNotice]=useState(""); const [search,setSearch]=useState("");
 const [role,setRole]=useState("");
 async function init(){
  setLoading(true);setError("");
  const {data:u}=await supabase.auth.getUser(); if(!u.user){setError("يرجى تسجيل الدخول أولاً.");setLoading(false);return;}
  const {data:m,error:me}=await supabase.from("memberships").select("tenant_id,role").eq("user_id",u.user.id).eq("is_active",true).in("role",["nursery_admin","academic_supervisor","teacher"]).limit(1).maybeSingle();
  if(me||!m){setError("لا يوجد حساب موظف مرتبط بحضانة.");setLoading(false);return;}
  setTenant(m.tenant_id);setRole(m.role);
  let roomQuery=supabase.from("classrooms").select("id,name").eq("tenant_id",m.tenant_id).order("name");
  if(m.role==="teacher"){
   const {data:t}=await supabase.from("teachers").select("id").eq("tenant_id",m.tenant_id).eq("user_id",u.user.id).eq("employment_status","active").maybeSingle();
   if(!t){setError("لم يتم تسجيلك كمعلمة نشطة.");setLoading(false);return;}
   const {data:ct}=await supabase.from("classroom_teachers").select("classroom_id").eq("tenant_id",m.tenant_id).eq("teacher_id",t.id);
   const ids=(ct||[]).map(x=>x.classroom_id); roomQuery=roomQuery.in("id",ids.length?ids:["00000000-0000-0000-0000-000000000000"]);
  }
  const {data:r,error:re}=await roomQuery;if(re)setError(re.message);
  setRooms(r||[]); if(r?.length)setRoom(r[0].id); setLoading(false);
 }
 async function loadMarks(roomId:string,day:string){
  if(!tenant||!roomId)return;
  setLoading(true);setError("");setNotice("");
  const {data:en,error:ee}=await supabase.from("enrollments").select("child_id,children(id,full_name,child_code)").eq("tenant_id",tenant).eq("classroom_id",roomId).eq("status","active").or(`end_date.is.null,end_date.gte.${day}`).lte("start_date",day);
  if(ee){setError(ee.message);setLoading(false);return;}
  const children=(en||[]).map((x:any)=>Array.isArray(x.children)?x.children[0]:x.children).filter(Boolean) as Child[];
  const {data:a,error:ae}=await supabase.from("attendance").select("child_id,status,note").eq("tenant_id",tenant).eq("classroom_id",roomId).eq("attendance_date",day);
  if(ae)setError(ae.message);
  const map=new Map((a||[]).map(x=>[x.child_id,x]));
  setRows(children.map(c=>{const old=map.get(c.id);return {...c,status:(old?.status||"present") as Mark,note:old?.note||"",existing:!!old};}));
  setLoading(false);
 }
 useEffect(()=>{void init();},[]);
 useEffect(()=>{if(tenant&&room)void loadMarks(room,date);},[tenant,room,date]);
 const filtered=useMemo(()=>rows.filter(x=>`${x.full_name} ${x.child_code}`.toLowerCase().includes(search.toLowerCase())),[rows,search]);
 const counts=useMemo(()=>({present:rows.filter(x=>x.status==="present").length,absent:rows.filter(x=>x.status==="absent").length,late:rows.filter(x=>x.status==="late").length,excused:rows.filter(x=>x.status==="excused").length}),[rows]);
 function setStatus(id:string,status:Mark){setRows(old=>old.map(x=>x.id===id?{...x,status}:x));}
 async function save(){
  if(!tenant||!room)return;setSaving(true);setError("");setNotice("");
  const {data:u}=await supabase.auth.getUser();
  const payload=rows.map(x=>({tenant_id:tenant,child_id:x.id,classroom_id:room,attendance_date:date,status:x.status,note:x.note.trim()||null,recorded_by:u.user?.id||null}));
  if(payload.length){
   const {error:e}=await supabase.from("attendance").upsert(payload,{onConflict:"tenant_id,child_id,attendance_date"});
   if(e)setError(e.message);else{setNotice("تم حفظ سجل الحضور والغياب بنجاح.");await loadMarks(room,date);}
  }else setNotice("لا يوجد أطفال مسجلون في هذا الفصل لهذا اليوم.");
  setSaving(false);
 }
 return <ManagementShell title="الحضور والغياب" subtitle="سجل يومي للأطفال مع صلاحيات للمعلمات حسب الفصول المسندة إليهن.">
 <div className="panel">
  <div className="panel-head"><div><h2>سجل الحضور اليومي</h2><p>اختر الفصل والتاريخ ثم حدّد حالة كل طفل واحفظ السجل.</p></div><button className="primary-btn" onClick={save} disabled={saving||loading||!rows.length}><Save size={16}/>{saving?"جارٍ الحفظ...":"حفظ السجل"}</button></div>
  <div className="attendance-filters">
   <label>الفصل<select value={room} onChange={e=>setRoom(e.target.value)}><option value="">اختر الفصل</option>{rooms.map(r=><option key={r.id} value={r.id}>{r.name}</option>)}</select></label>
   <label>التاريخ<input type="date" value={date} onChange={e=>setDate(e.target.value)}/></label>
   <div className="attendance-count"><Users size={17}/><b>{rows.length}</b><span>طفل مسجل</span></div>
  </div>
  <div className="attendance-stats">{(["present","absent","late","excused"] as Mark[]).map(k=><div className={`attendance-stat ${k}`} key={k}><b>{counts[k]}</b><span>{labels[k]}</span></div>)}</div>
  {error&&<p className="form-error">{error}</p>}{notice&&<p className="form-success">{notice}</p>}
  <div className="search-line"><Search size={16}/><input value={search} onChange={e=>setSearch(e.target.value)} placeholder="ابحث باسم الطفل أو كوده"/></div>
  {loading?<p className="empty-state">جارٍ تحميل السجل...</p>:filtered.length===0?<p className="empty-state">لا يوجد أطفال نشطون في هذا الفصل بهذا التاريخ.</p>:
   <div className="attendance-list">{filtered.map(c=><article className="attendance-row" key={c.id}><div className="child-mark"><b>{c.full_name}</b><small>{c.child_code}</small></div><div className="attendance-options">{(["present","absent","late","excused"] as Mark[]).map(k=><button type="button" key={k} onClick={()=>setStatus(c.id,k)} className={`attendance-choice ${c.status===k?"selected "+k:""}`}>{labels[k]}</button>)}</div><input className="attendance-note" value={c.note} onChange={e=>setRows(old=>old.map(x=>x.id===c.id?{...x,note:e.target.value}:x))} placeholder="ملاحظة (اختياري)"/></article>)}</div>}
  <p className="attendance-hint">الحالات: حاضر، غائب، متأخر، بعذر. لا تُرسل إشعارات تلقائية لولي الأمر في هذه النسخة.</p>
 </div></ManagementShell>;
}
