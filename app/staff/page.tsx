"use client";
import { useEffect, useMemo, useState, FormEvent } from "react";
import { createClient } from "@/lib/supabase/client";
import ManagementShell from "@/components/management-shell";
import { Plus, Search, Users, UserRound, GraduationCap, Link2, RefreshCw } from "lucide-react";

type Room = { id: string; name: string };
type Child = { id: string; full_name: string; child_code: string };
type Teacher = { id: string; user_id: string; employment_status: string; profile: { full_name: string; email: string | null; phone: string | null } | null; rooms: string[] };
type Guardian = { parent_user_id: string; child_id: string; relationship: string; profile: { full_name: string; email: string | null; phone: string | null } | null; child: { full_name: string; child_code: string } | null };

export default function StaffPage() {
  const supabase = createClient();
  const [tenant, setTenant] = useState("");
  const [teachers, setTeachers] = useState<Teacher[]>([]);
  const [guardians, setGuardians] = useState<Guardian[]>([]);
  const [rooms, setRooms] = useState<Room[]>([]);
  const [children, setChildren] = useState<Child[]>([]);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState("");
  const [notice, setNotice] = useState("");
  const [search, setSearch] = useState("");
  const [mode, setMode] = useState<"teacher" | "parent">("teacher");
  const [show, setShow] = useState(false);
  const [email, setEmail] = useState("");
  const [name, setName] = useState("");
  const [phone, setPhone] = useState("");
  const [room, setRoom] = useState("");
  const [child, setChild] = useState("");
  const [relationship, setRelationship] = useState("ولي أمر");

  async function load() {
    setLoading(true); setError("");
    const { data: auth } = await supabase.auth.getUser();
    if (!auth.user) { setError("يرجى تسجيل الدخول أولاً."); setLoading(false); return; }
    const { data: membership, error: mErr } = await supabase.from("memberships").select("tenant_id").eq("user_id", auth.user.id).eq("is_active", true).eq("role", "nursery_admin").limit(1).maybeSingle();
    if (mErr || !membership) { setError("هذه الصفحة متاحة لمدير الحضانة بعد إكمال إعداد الحضانة."); setLoading(false); return; }
    const tenantId = membership.tenant_id; setTenant(tenantId);
    const [t, p, r, c] = await Promise.all([
      supabase.from("teachers").select("id,user_id,employment_status,profiles(full_name,email,phone),classroom_teachers(classroom_id,classrooms(name))").eq("tenant_id", tenantId).order("id"),
      supabase.from("parent_children").select("parent_user_id,child_id,relationship,profiles(full_name,email,phone),children(full_name,child_code)").eq("tenant_id", tenantId).order("created_at", { ascending: false }),
      supabase.from("classrooms").select("id,name").eq("tenant_id", tenantId).order("name"),
      supabase.from("children").select("id,full_name,child_code").eq("tenant_id", tenantId).order("full_name")
    ]);
    if (t.error) setError(t.error.message);
    const teacherRows = (t.data || []) as any[];
    setTeachers(teacherRows.map(x => ({ id: x.id, user_id: x.user_id, employment_status: x.employment_status, profile: Array.isArray(x.profiles) ? x.profiles[0] : x.profiles, rooms: (x.classroom_teachers || []).map((a: any) => a.classrooms?.name).filter(Boolean) })));
    const parentRows = (p.data || []) as any[];
    setGuardians(parentRows.map(x => ({ parent_user_id: x.parent_user_id, child_id: x.child_id, relationship: x.relationship, profile: Array.isArray(x.profiles) ? x.profiles[0] : x.profiles, child: Array.isArray(x.children) ? x.children[0] : x.children })));
    setRooms(r.data || []); setChildren(c.data || []); setLoading(false);
  }
  useEffect(() => { void load(); }, []);

  async function save(e: FormEvent) {
    e.preventDefault(); setSaving(true); setError(""); setNotice("");
    const rpc = mode === "teacher"
      ? await supabase.rpc("add_existing_teacher", { target_tenant: tenant, teacher_email: email.trim(), teacher_name: name.trim() || null, teacher_phone: phone.trim() || null, target_classroom: room || null })
      : await supabase.rpc("link_existing_parent", { target_tenant: tenant, target_child: child, parent_email: email.trim(), relation_name: relationship });
    if (rpc.error) setError(rpc.error.message);
    else { setNotice(mode === "teacher" ? "تم ربط حساب المعلمة بالحضانة بنجاح." : "تم ربط ولي الأمر بالطفل بنجاح."); setEmail(""); setName(""); setPhone(""); setRoom(""); setChild(""); setShow(false); await load(); }
    setSaving(false);
  }

  const filteredTeachers = useMemo(() => teachers.filter(x => `${x.profile?.full_name || ""} ${x.profile?.email || ""}`.toLowerCase().includes(search.toLowerCase())), [teachers, search]);
  const filteredParents = useMemo(() => guardians.filter(x => `${x.profile?.full_name || ""} ${x.profile?.email || ""} ${x.child?.full_name || ""}`.toLowerCase().includes(search.toLowerCase())), [guardians, search]);

  return <ManagementShell title="المعلمات وأولياء الأمور" subtitle="إدارة حسابات فريق الحضانة وربط أولياء الأمور بالأطفال.">
    <div className="panel">
      <div className="panel-head"><div><h2>إدارة الأشخاص</h2><p>أضيفي حسابات مسجلة مسبقاً، ثم اربطيها بالحضانة أو بالطفل.</p></div><button className="primary-btn" onClick={() => { setMode("teacher"); setShow(!show); setError(""); }}><Plus size={16}/> إضافة شخص</button></div>
      <div className="notice staff-notice"><div className="notice-icon"><Users size={18}/></div><div><b>قبل الإضافة</b><p>يجب أن يكون للمعلمة أو ولي الأمر حساب مسجل في روضة بنفس البريد الإلكتروني. هذه الصفحة تربط الحساب الموجود ولا تنشئ كلمة مرور أو حساب دخول نيابةً عنه.</p></div></div>
      {show && <form className="management-form" onSubmit={save}>
        <label>نوع الحساب<select value={mode} onChange={e => { setMode(e.target.value as "teacher" | "parent"); setError(""); }}><option value="teacher">معلمة</option><option value="parent">ولي أمر</option></select></label>
        <label>البريد الإلكتروني للحساب<input type="email" required value={email} onChange={e => setEmail(e.target.value)} placeholder="name@example.com"/></label>
        {mode === "teacher" ? <>
          <label>اسم المعلمة (اختياري)<input value={name} onChange={e => setName(e.target.value)} placeholder="الاسم الكامل"/></label>
          <label>رقم الهاتف (اختياري)<input value={phone} onChange={e => setPhone(e.target.value)} placeholder="+965 ..."/></label>
          <label>إسناد إلى فصل<select value={room} onChange={e => setRoom(e.target.value)}><option value="">بدون فصل حالياً</option>{rooms.map(r => <option key={r.id} value={r.id}>{r.name}</option>)}</select></label>
        </> : <>
          <label>الطفل<select required value={child} onChange={e => setChild(e.target.value)}><option value="">اختر الطفل</option>{children.map(c => <option key={c.id} value={c.id}>{c.full_name} — {c.child_code}</option>)}</select></label>
          <label>صلة القرابة<input value={relationship} onChange={e => setRelationship(e.target.value)} placeholder="أب، أم، وصي..."/></label>
        </>}
        <button className="primary-btn" disabled={saving}>{saving ? "جارٍ الحفظ..." : mode === "teacher" ? "ربط حساب المعلمة" : "ربط ولي الأمر بالطفل"}</button>
      </form>}
      {error && <p className="form-error">{error}</p>}{notice && <p className="form-success">{notice}</p>}
      <div className="staff-tabs"><button className={mode === "teacher" ? "staff-tab active" : "staff-tab"} onClick={() => { setMode("teacher"); setSearch(""); }}>المعلمات ({teachers.length})</button><button className={mode === "parent" ? "staff-tab active" : "staff-tab"} onClick={() => { setMode("parent"); setSearch(""); }}>أولياء الأمور ({guardians.length})</button></div>
      <div className="search-line"><Search size={16}/><input value={search} onChange={e => setSearch(e.target.value)} placeholder="ابحث بالاسم أو البريد أو اسم الطفل"/></div>
      {loading ? <p className="empty-state">جارٍ تحميل البيانات...</p> : mode === "teacher" ? filteredTeachers.length === 0 ? <p className="empty-state"><GraduationCap size={22}/> لا توجد معلمات مرتبطة بعد.</p> :
        <div className="staff-list">{filteredTeachers.map(t => <article className="staff-card" key={t.id}><div className="staff-avatar"><GraduationCap size={19}/></div><div className="staff-info"><b>{t.profile?.full_name || "معلمة بدون اسم"}</b><span>{t.profile?.email || "لا يوجد بريد مسجل"}</span><small>{t.rooms.length ? `الفصول: ${t.rooms.join("، ")}` : "لم يتم إسناد فصل بعد"}</small></div><span className="status status-on">نشطة</span></article>)}</div>
        : filteredParents.length === 0 ? <p className="empty-state"><UserRound size={22}/> لا توجد روابط لأولياء الأمور بعد.</p> :
        <div className="table-wrap"><table><thead><tr><th>ولي الأمر</th><th>البريد الإلكتروني</th><th>الطفل</th><th>صلة القرابة</th></tr></thead><tbody>{filteredParents.map((p, i) => <tr key={`${p.parent_user_id}-${p.child_id}-${i}`}><td><b>{p.profile?.full_name || "ولي أمر"}</b></td><td>{p.profile?.email || "—"}</td><td>{p.child?.full_name || "—"} <span className="code-chip">{p.child?.child_code || ""}</span></td><td>{p.relationship}</td></tr>)}</tbody></table></div>}
      <div className="staff-footnote"><RefreshCw size={14}/> تتحدث القائمة بعد كل عملية ربط ناجحة.</div>
    </div>
  </ManagementShell>;
}
