import {
  Activity, Bell, BookOpen, Building2, CalendarDays, ChevronLeft,
  ClipboardList, GraduationCap, LayoutDashboard, Settings, ShieldCheck,
  Users, Wallet, TrendingUp, UserRoundCheck, FileText
} from "lucide-react";
import { demoStats, demoNurseries, demoActivities } from "@/lib/demo-data";
import Link from "next/link";

const nav = [
  { label: "الرئيسية", icon: LayoutDashboard, active: true },
  { label: "الحضانات", icon: Building2 },
  { label: "المستخدمون والصلاحيات", icon: ShieldCheck },
  { label: "الأطفال وأولياء الأمور", icon: Users, href: "/children" },
  { label: "الفصول والمعلمات", icon: GraduationCap, href: "/classrooms" },
  { label: "المناهج والكتب", icon: BookOpen },
  { label: "طلبات التقديم", icon: ClipboardList },
  { label: "الاشتراكات والفوترة", icon: Wallet },
  { label: "التقارير", icon: FileText },
  { label: "الإعدادات", icon: Settings },
];

const icons = [Building2, Users, GraduationCap, ClipboardList];

export default function Home() {
  return (
    <main className="app-shell">
      <aside className="sidebar">
        <div className="brand">
          <div className="brand-mark">ر</div>
          <div><div className="brand-name">روضة</div><div className="brand-sub">RAWDA PLATFORM</div></div>
        </div>
        <div className="side-label">القائمة الرئيسية</div>
        <nav>
          {nav.map((item) => {
            const Icon = item.icon;
            return <Link key={item.label} className={`nav-item ${item.active ? "active" : ""}`} href={("href" in item && item.href) || "#"}>
              <Icon size={18} /><span>{item.label}</span>{item.active && <i />}
            </Link>;
          })}
        </nav>
        <div className="sidebar-bottom">
          <div className="support-card"><div className="support-icon"><Activity size={18}/></div>
            <strong>مركز المساعدة</strong><span>نحن هنا لمساعدتك</span>
          </div>
          <div className="user-mini"><div className="avatar">م</div><div><b>مدير المنصة</b><small>مالك روضة</small></div><ChevronLeft size={16}/></div>
        </div>
      </aside>

      <section className="main-area">
        <header className="topbar">
          <div className="breadcrumbs">روضة <ChevronLeft size={14}/> <b>لوحة التحكم</b></div>
          <div className="top-actions"><span className="demo-pill">بيئة تجريبية</span><button className="icon-btn" aria-label="الإشعارات"><Bell size={19}/><i/></button><div className="top-avatar">م</div></div>
        </header>

        <div className="content">
          <div className="welcome-row">
            <div><div className="eyebrow">الثلاثاء، 17 نوفمبر 2026</div><h1>مرحباً بك في روضة <span>👋</span></h1><p>إليك نظرة عامة على أداء المنصة اليوم.</p></div>
            <Link className="primary-btn" href="/onboarding"><Building2 size={17}/> إضافة حضانة جديدة</Link>
          </div>

          <div className="notice"><div className="notice-icon"><ShieldCheck size={19}/></div><div><b>أنت تتصفح النسخة التجريبية</b><p>الأرقام والبيانات المعروضة افتراضية للتوضيح فقط، ولا تمثل سجلات حضانات فعلية.</p></div></div>

          <div className="section-heading"><div><h2>مؤشرات المنصة</h2><p>ملخص سريع للنشاط العام</p></div><button className="filter-btn"><CalendarDays size={16}/> آخر 30 يوماً</button></div>

          <div className="stats-grid">
            {demoStats.map((s, i) => {
              const Icon = icons[i];
              return <article className="stat-card" key={s.label}><div className={`stat-icon tone-${i}`}><Icon size={20}/></div><div className="stat-label">{s.label}</div><div className="stat-bottom"><strong>{s.value}</strong><span className="stat-change"><TrendingUp size={14}/> {s.change}</span></div><div className="stat-foot">{s.note}</div></article>;
            })}
          </div>

          <div className="two-col">
            <section className="panel">
              <div className="panel-head"><div><h2>أحدث الحضانات</h2><p>الحضانات المسجلة في المنصة</p></div><a href="#">عرض الكل <ChevronLeft size={14}/></a></div>
              <div className="table-wrap"><table><thead><tr><th>الحضانة</th><th>عدد الأطفال</th><th>الحالة</th></tr></thead><tbody>
                {demoNurseries.map((n) => <tr key={n.name}><td><div className="nursery-cell"><div className="nursery-logo">{n.initial}</div><div><b>{n.name}</b><small>{n.city}</small></div></div></td><td>{n.children}</td><td><span className={`status ${n.status === "نشطة" ? "status-on" : "status-pending"}`}>{n.status}</span></td></tr>)}
              </tbody></table></div>
            </section>
            <section className="panel">
              <div className="panel-head"><div><h2>آخر الأنشطة</h2><p>مستجدات المنصة</p></div><button className="dots">•••</button></div>
              <div className="activity-list">{demoActivities.map((a, i) => <div className="activity-item" key={a.title}><div className={`activity-icon activity-${i}`}><a.icon size={17}/></div><div><b>{a.title}</b><p>{a.detail}</p><small>{a.time}</small></div></div>)}</div>
            </section>
          </div>

          <section className="quick-panel"><div><div className="quick-icon"><UserRoundCheck size={21}/></div><div><h2>ابدأ إعداد منصتك</h2><p>أكمل إعداد بيانات أول حضانة تجريبية، ثم أضف الفصول والمستخدمين.</p></div></div><Link className="outline-btn" href="/classrooms">إدارة الفصول <ChevronLeft size={16}/></Link></section>
          <footer>© 2026 روضة RAWDA · منصة إدارة الحضانات والتعليم المبكر <span>نسخة تجريبية 0.1</span></footer>
        </div>
      </section>
    </main>
  );
}
