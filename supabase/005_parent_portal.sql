-- RAWDA parent portal: parents can read only records connected to their linked children.
-- Run after 001 schema.sql through 004_attendance.sql.

-- Parents may only see classrooms where one of their linked children is enrolled.
drop policy if exists "classrooms_select" on public.classrooms;
create policy "classrooms_select_scoped" on public.classrooms for select using (
  public.is_platform_admin()
  or public.has_tenant_role(tenant_id, array['nursery_admin','academic_supervisor','teacher']::public.app_role[])
  or exists (
    select 1 from public.enrollments e
    join public.parent_children pc on pc.child_id=e.child_id and pc.tenant_id=e.tenant_id
    where e.tenant_id=classrooms.tenant_id and e.classroom_id=classrooms.id
      and pc.parent_user_id=auth.uid() and pc.can_view_reports=true
  )
);

drop policy if exists "enrollments_read" on public.enrollments;
create policy "enrollments_read_scoped" on public.enrollments for select using (
  public.is_platform_admin()
  or public.has_tenant_role(tenant_id, array['nursery_admin','academic_supervisor','teacher']::public.app_role[])
  or exists (
    select 1 from public.parent_children pc where pc.tenant_id=enrollments.tenant_id
      and pc.child_id=enrollments.child_id and pc.parent_user_id=auth.uid() and pc.can_view_reports=true
  )
);

-- Lessons are visible to staff in their tenant and to parents of children enrolled in that class.
drop policy if exists "lessons_read" on public.daily_lessons;
create policy "lessons_read_scoped" on public.daily_lessons for select using (
  public.is_platform_admin()
  or public.has_tenant_role(tenant_id, array['nursery_admin','academic_supervisor','teacher']::public.app_role[])
  or exists (
    select 1 from public.enrollments e
    join public.parent_children pc on pc.child_id=e.child_id and pc.tenant_id=e.tenant_id
    where e.tenant_id=daily_lessons.tenant_id and e.classroom_id=daily_lessons.classroom_id
      and e.status='active' and pc.parent_user_id=auth.uid() and pc.can_view_reports=true
  )
);

-- Assessment visibility is child-specific for parents.
drop policy if exists "assessments_read" on public.assessments;
create policy "assessments_read_scoped" on public.assessments for select using (
  public.is_platform_admin()
  or public.has_tenant_role(tenant_id, array['nursery_admin','academic_supervisor','teacher']::public.app_role[])
  or exists (
    select 1 from public.parent_children pc where pc.tenant_id=assessments.tenant_id
      and pc.child_id=assessments.child_id and pc.parent_user_id=auth.uid() and pc.can_view_reports=true
  )
);

-- Only published announcements are visible to parents; staff retain tenant access.
drop policy if exists "announcements_read" on public.announcements;
create policy "announcements_read_scoped" on public.announcements for select using (
  public.is_platform_admin()
  or public.has_tenant_role(tenant_id, array['nursery_admin','academic_supervisor','teacher']::public.app_role[])
  or (published_at is not null and public.has_tenant_role(tenant_id, array['parent']::public.app_role[]))
);

create index if not exists idx_parent_children_user_reports on public.parent_children(parent_user_id, can_view_reports, tenant_id);
create index if not exists idx_enrollments_child_active on public.enrollments(tenant_id, child_id, status, end_date);
