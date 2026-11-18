import { Building2, Users, GraduationCap, ClipboardList } from "lucide-react";

export const demoStats = [
  { label: "الحضانات", value: "12", change: "+2.4%", note: "إجمالي الحضانات المسجلة" },
  { label: "الأطفال", value: "1,250", change: "+8.1%", note: "ضمن جميع الحضانات" },
  { label: "المعلمات", value: "86", change: "+3.2%", note: "حسابات المعلمات النشطة" },
  { label: "طلبات التقديم", value: "34", change: "+12%", note: "طلبات بانتظار المراجعة" },
];

export const demoNurseries = [
  { name: "حضانة البراعم", initial: "ب", city: "الكويت", children: 128, status: "نشطة" },
  { name: "حضانة عالم الصغار", initial: "ع", city: "حولي", children: 96, status: "نشطة" },
  { name: "حضانة خطوات", initial: "خ", city: "الفروانية", children: 74, status: "بانتظار التفعيل" },
];

export const demoActivities = [
  { icon: Building2, title: "تم تسجيل حضانة جديدة", detail: "حضانة خطوات · الفروانية", time: "منذ 20 دقيقة" },
  { icon: Users, title: "تم إضافة مجموعة أطفال", detail: "حضانة البراعم · 8 أطفال", time: "منذ ساعة" },
  { icon: GraduationCap, title: "تم تحديث بيانات معلمة", detail: "حضانة عالم الصغار", time: "منذ 3 ساعات" },
  { icon: ClipboardList, title: "طلبات تقديم جديدة", detail: "5 طلبات تحتاج إلى مراجعة", time: "اليوم، 09:30 ص" },
];
