"use client";

import { useCallback, useEffect, useMemo, useState } from "react";
import { Check, RefreshCw, UserRound, X } from "lucide-react";
import { createClient } from "@/lib/supabase/client";
import ManagementShell from "@/components/management-shell";

type RequestRow = {
  id: string;
  created_at: string;
  parent: { full_name: string | null; email: string | null } | null;
  child: { full_name: string; child_code: string } | null;
};

export default function ParentRequestsPage() {
  const supabase = useMemo(() => createClient(), []);
  const [requests, setRequests] = useState<RequestRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [busyId, setBusyId] = useState("");
  const [error, setError] = useState("");
  const [notice, setNotice] = useState("");

  const load = useCallback(async () => {
    setLoading(true);
    setError("");
    const { data: auth } = await supabase.auth.getUser();
    if (!auth.user) {
      setError("يرجى تسجيل الدخول أولاً.");
      setLoading(false);
      return;
    }
    const { data: membership, error: membershipError } = await supabase
      .from("memberships").select("tenant_id").eq("user_id", auth.user.id)
      .eq("is_active", true).eq("role", "nursery_admin").limit(1).maybeSingle();
    if (membershipError || !membership) {
      setError("هذه الصفحة متاحة لمدير الحضانة فقط.");
      setLoading(false);
      return;
    }
    const { data, error: queryError } = await supabase
      .from("parent_link_requests")
      .select("id,created_at,profiles(full_name,email),children(full_name,child_code)")
      .eq("tenant_id", membership.tenant_id).eq("status", "pending")
      .order("created_at", { ascending: true });
    if (queryError) {
      setError(queryError.message);
      setRequests([]);
    } else {
      setRequests((data || []).map((row: any) => ({
        id: row.id,
        created_at: row.created_at,
        parent: Array.isArray(row.profiles) ? row.profiles[0] || null : row.profiles,
        child: Array.isArray(row.children) ? row.children[0] || null : row.children,
      })));
    }
    setLoading(false);
  }, [supabase]);

  useEffect(() => { void load(); }, [load]);

  async function review(id: string, approve: boolean) {
    setBusyId(id);
    setError("");
    setNotice("");
    const { error: rpcError } = await supabase.rpc("review_parent_link_request", {
      request_id_input: id, approve_input: approve,
    });
    if (rpcError) setError(rpcError.message);
    else {
      setNotice(approve ? "تمت الموافقة على طلب ربط ولي الأمر." : "تم رفض طلب الربط.");
      await load();
    }
    setBusyId("");
  }

  return (
    <ManagementShell title="طلبات ربط أولياء الأمور" subtitle="مراجعة طلبات ربط حساب ولي الأمر بالطفل قبل إتاحة بياناته.">
      <section className="panel">
        <div className="panel-head">
          <div><h2>الطلبات المعلقة</h2><p>لا تظهر بيانات الطفل لولي الأمر إلا بعد موافقة الإدارة.</p></div>
          <button className="outline-btn" onClick={() => void load()} disabled={loading}><RefreshCw size={15}/> تحديث</button>
        </div>
        {error && <p className="form-error">{error}</p>}
        {notice && <p className="form-success">{notice}</p>}
        {loading ? <p className="empty-state">جارٍ تحميل الطلبات...</p> :
          requests.length === 0 ? <p className="empty-state"><UserRound size={22}/> لا توجد طلبات ربط معلقة حالياً.</p> :
          <div className="staff-list">
            {requests.map((request) => (
              <article className="staff-card" key={request.id}>
                <div className="staff-avatar"><UserRound size={19}/></div>
                <div className="staff-info">
                  <b>{request.parent?.full_name || "ولي أمر"}</b>
                  <span>{request.parent?.email || "لا يوجد بريد مسجل"}</span>
                  <small>الطفل: {request.child?.full_name || "غير متاح"} · كود الطفل: {request.child?.child_code || "—"}</small>
                  <small>تاريخ الطلب: {new Date(request.created_at).toLocaleString("ar-KW")}</small>
                </div>
                <div className="staff-actions">
                  <button className="primary-btn" disabled={busyId === request.id} onClick={() => void review(request.id, true)}><Check size={15}/> موافقة</button>
                  <button className="outline-btn" disabled={busyId === request.id} onClick={() => void review(request.id, false)}><X size={15}/> رفض</button>
                </div>
              </article>
            ))}
          </div>}
        <p className="stat-foot" style={{marginTop:16}}>تُنفّذ الموافقة أو الرفض عبر دالة قاعدة البيانات التي تتحقق من صلاحية مدير الحضانة.</p>
      </section>
    </ManagementShell>
  );
}
