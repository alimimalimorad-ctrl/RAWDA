import Link from "next/link";
import { LayoutDashboard, Users, GraduationCap, BookOpen, ChevronLeft, Baby, UserRoundCog, CalendarDays, Heart, Star, FileText } from "lucide-react";

export default function ManagementShell({ title, subtitle, children }: { title: string; subtitle: string; children: React.ReactNode }) {
  return <main className="app-shell"><aside className="sidebar"><Link href="/" className="brand"><div className="brand-mark">ر</div><div><div className="brand-name">روضة</div><div className="brand-sub">RAWDA PLATFORM</div></div></Link><div className="side-label">القائمة الرئيسية</div><nav>
    <Link className="nav-item" href="/"><LayoutDashboard size={18}/><span>الرئيسية</span></Link>
    <Link className="nav-item" href="/children"><Baby size={18}/><span>الأطفال وأولياء الأمور</span></Link>
    <Link className="nav-item" href="/classrooms"><GraduationCap size={18}/><span>الفصول</span></Link>
    <Link className="nav-item" href="/attendance"><CalendarDays size={18}/><span>الحضور والغياب</span></Link>
    <Link className="nav-item" href="/staff"><UserRoundCog size={18}/><span>المعلمات وأولياء الأمور</span></Link>
    <Link className="nav-item" href="/curriculum"><BookOpen size={18}/><span>المناهج والكتب</span></Link>
    <Link className="nav-item" href="/assessments"><Star size={18}/><span>التقييمات</span></Link>
    <Link className="nav-item" href="/reports"><FileText size={18}/><span>تقارير التقدم</span></Link>
    <Link className="nav-item" href="/portal"><Heart size={18}/><span>بوابة ولي الأمر</span></Link>
  </nav></aside><section className="main-area"><header className="topbar"><div className="breadcrumbs"><Link href="/">روضة</Link><ChevronLeft size={14}/><b>{title}</b></div><span className="demo-pill">إدارة روضة</span></header><div className="content"><div className="welcome-row"><div><div className="eyebrow">إدارة الحضانة</div><h1>{title}</h1><p>{subtitle}</p></div></div>{children}<footer>© 2026 روضة RAWDA <span>نسخة تجريبية</span></footer></div></section></main>;
}
