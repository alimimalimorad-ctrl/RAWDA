-- Remove overlapping policies and scope attendance and lessons by classroom and enrollment dates.
drop policy if exists attendance_read_authorized_scope on public.attendance;
drop policy if exists attendance_read_scoped on public.attendance;
drop policy if exists attendance_insert_authorized_scope on public.attendance;
drop policy if exists attendance_insert_scoped on public.attendance;
drop policy if exists attendance_update_authorized_scope on public.attendance;
drop policy if exists attendance_update_scoped on public.attendance;
drop policy if exists attendance_delete_admin on public.attendance;

create policy attendance_select_scoped on public.attendance for select using (
  public.is_platform_admin()
  or public.has_tenant_role(tenant_id, array['nursery_admin','academic_supervisor']::public.app_role[])
  or exists (
    select 1 from public.teachers t
    join public.classroom_teachers ct on ct.teacher_id=t.id and ct.tenant_id=t.tenant_id
    join public.enrollments e on e.tenant_id=attendance.tenant_id and e.classroom_id=attendance.classroom_id
      and e.child_id=attendance.child_id and e.status='active' and e.start_date<=attendance.attendance_date
      and (e.end_date is null or e.end_date>=attendance.attendance_date)
    where t.tenant_id=attendance.tenant_id and t.user_id=auth.uid()
      and t.employment_status='active' and ct.classroom_id=attendance.classroom_id
  )
  or exists (select 1 from public.parent_children pc where pc.tenant_id=attendance.tenant_id
    and pc.child_id=attendance.child_id and pc.parent_user_id=auth.uid() and pc.can_view_reports=true)
);
create policy attendance_insert_scoped on public.attendance for insert with check (
  public.is_platform_admin()
  or public.has_tenant_role(tenant_id, array['nursery_admin','academic_supervisor']::public.app_role[])
  or exists (
    select 1 from public.teachers t
    join public.classroom_teachers ct on ct.teacher_id=t.id and ct.tenant_id=t.tenant_id
    join public.enrollments e on e.tenant_id=attendance.tenant_id and e.classroom_id=attendance.classroom_id
      and e.child_id=attendance.child_id and e.status='active' and e.start_date<=attendance.attendance_date
      and (e.end_date is null or e.end_date>=attendance.attendance_date)
    where t.tenant_id=attendance.tenant_id and t.user_id=auth.uid()
      and t.employment_status='active' and ct.classroom_id=attendance.classroom_id
  )
);
create policy attendance_update_scoped on public.attendance for update
using (
  public.is_platform_admin()
  or public.has_tenant_role(tenant_id, array['nursery_admin','academic_supervisor']::public.app_role[])
  or exists (
    select 1 from public.teachers t
    join public.classroom_teachers ct on ct.teacher_id=t.id and ct.tenant_id=t.tenant_id
    join public.enrollments e on e.tenant_id=attendance.tenant_id and e.classroom_id=attendance.classroom_id
      and e.child_id=attendance.child_id and e.status='active' and e.start_date<=attendance.attendance_date
      and (e.end_date is null or e.end_date>=attendance.attendance_date)
    where t.tenant_id=attendance.tenant_id and t.user_id=auth.uid()
      and t.employment_status='active' and ct.classroom_id=attendance.classroom_id
  )
)
with check (
  public.is_platform_admin()
  or public.has_tenant_role(tenant_id, array['nursery_admin','academic_supervisor']::public.app_role[])
  or exists (
    select 1 from public.teachers t
    join public.classroom_teachers ct on ct.teacher_id=t.id and ct.tenant_id=t.tenant_id
    join public.enrollments e on e.tenant_id=attendance.tenant_id and e.classroom_id=attendance.classroom_id
      and e.child_id=attendance.child_id and e.status='active' and e.start_date<=attendance.attendance_date
      and (e.end_date is null or e.end_date>=attendance.attendance_date)
    where t.tenant_id=attendance.tenant_id and t.user_id=auth.uid()
      and t.employment_status='active' and ct.classroom_id=attendance.classroom_id
  )
);
create policy attendance_delete_admin on public.attendance for delete
using (public.is_platform_admin() or public.has_tenant_role(tenant_id, array['nursery_admin']::public.app_role[]));

drop policy if exists lessons_read_authorized_scope on public.daily_lessons;
drop policy if exists lessons_read_scoped on public.daily_lessons;
drop policy if exists lessons_insert_authorized_scope on public.daily_lessons;
drop policy if exists lessons_update_authorized_scope on public.daily_lessons;
drop policy if exists lessons_delete_admin on public.daily_lessons;
drop policy if exists lessons_admin_delete on public.daily_lessons;
drop policy if exists lessons_staff_parent_read on public.daily_lessons;
drop policy if exists lessons_staff_write_assigned on public.daily_lessons;
drop policy if exists lessons_staff_update_assigned on public.daily_lessons;

create policy lessons_select_scoped on public.daily_lessons for select using (
  public.is_platform_admin()
  or public.has_tenant_role(tenant_id, array['nursery_admin','academic_supervisor']::public.app_role[])
  or exists (select 1 from public.teachers t join public.classroom_teachers ct
    on ct.teacher_id=t.id and ct.tenant_id=t.tenant_id
    where t.tenant_id=daily_lessons.tenant_id and t.user_id=auth.uid()
      and t.employment_status='active' and ct.classroom_id=daily_lessons.classroom_id)
  or exists (select 1 from public.enrollments e join public.parent_children pc
    on pc.child_id=e.child_id and pc.tenant_id=e.tenant_id
    where e.tenant_id=daily_lessons.tenant_id and e.classroom_id=daily_lessons.classroom_id
      and e.status='active' and e.start_date<=daily_lessons.lesson_date
      and (e.end_date is null or e.end_date>=daily_lessons.lesson_date)
      and pc.parent_user_id=auth.uid() and pc.can_view_reports=true)
);
create policy lessons_insert_scoped on public.daily_lessons for insert with check (
  public.is_platform_admin()
  or public.has_tenant_role(tenant_id, array['nursery_admin','academic_supervisor']::public.app_role[])
  or exists (select 1 from public.teachers t join public.classroom_teachers ct
    on ct.teacher_id=t.id and ct.tenant_id=t.tenant_id
    where t.tenant_id=daily_lessons.tenant_id and t.user_id=auth.uid()
      and t.employment_status='active' and ct.classroom_id=daily_lessons.classroom_id)
);
create policy lessons_update_scoped on public.daily_lessons for update
using (
  public.is_platform_admin()
  or public.has_tenant_role(tenant_id, array['nursery_admin','academic_supervisor']::public.app_role[])
  or exists (select 1 from public.teachers t join public.classroom_teachers ct
    on ct.teacher_id=t.id and ct.tenant_id=t.tenant_id
    where t.tenant_id=daily_lessons.tenant_id and t.user_id=auth.uid()
      and t.employment_status='active' and ct.classroom_id=daily_lessons.classroom_id)
)
with check (
  public.is_platform_admin()
  or public.has_tenant_role(tenant_id, array['nursery_admin','academic_supervisor']::public.app_role[])
  or exists (select 1 from public.teachers t join public.classroom_teachers ct
    on ct.teacher_id=t.id and ct.tenant_id=t.tenant_id
    where t.tenant_id=daily_lessons.tenant_id and t.user_id=auth.uid()
      and t.employment_status='active' and ct.classroom_id=daily_lessons.classroom_id)
);
create policy lessons_delete_admin on public.daily_lessons for delete
using (public.is_platform_admin() or public.has_tenant_role(tenant_id, array['nursery_admin','academic_supervisor']::public.app_role[]));

drop policy if exists enrollments_read_scoped on public.enrollments;
