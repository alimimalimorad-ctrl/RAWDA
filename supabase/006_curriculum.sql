-- RAWDA curriculum and daily lesson access rules.
-- Run after 001-005 migrations (or after schema.sql and existing migrations).

-- Keep curriculum metadata tenant-scoped. A null tenant_id is reserved for platform-wide catalog entries.
drop policy if exists "subjects_read" on public.subjects;
drop policy if exists "subjects_admin_write" on public.subjects;
create policy "subjects_read" on public.subjects for select
using (tenant_id is null or public.is_tenant_member(tenant_id) or public.is_platform_admin());
create policy "subjects_admin_write" on public.subjects for all
using (tenant_id is not null and (public.has_tenant_role(tenant_id, array['nursery_admin','academic_supervisor']::public.app_role[]) or public.is_platform_admin()))
with check (tenant_id is not null and (public.has_tenant_role(tenant_id, array['nursery_admin','academic_supervisor']::public.app_role[]) or public.is_platform_admin()));

drop policy if exists "books_read" on public.books;
drop policy if exists "books_admin_write" on public.books;
create policy "books_read" on public.books for select
using ((tenant_id is null and is_published) or (tenant_id is not null and public.is_tenant_member(tenant_id)) or public.is_platform_admin());
create policy "books_admin_write" on public.books for all
using (tenant_id is not null and (public.has_tenant_role(tenant_id, array['nursery_admin','academic_supervisor']::public.app_role[]) or public.is_platform_admin()))
with check (tenant_id is not null and (public.has_tenant_role(tenant_id, array['nursery_admin','academic_supervisor']::public.app_role[]) or public.is_platform_admin()));

-- Staff can read lessons within their tenant; parents can read only lessons for a classroom
-- in which one of their linked children has an active enrollment.
drop policy if exists "lessons_read" on public.daily_lessons;
drop policy if exists "lessons_write" on public.daily_lessons;
create policy "lessons_staff_parent_read" on public.daily_lessons for select
using (
  public.has_tenant_role(tenant_id, array['nursery_admin','academic_supervisor','teacher']::public.app_role[])
  or public.is_platform_admin()
  or exists (
    select 1 from public.enrollments e
    join public.parent_children pc on pc.child_id = e.child_id and pc.tenant_id = e.tenant_id
    where e.tenant_id = daily_lessons.tenant_id
      and e.classroom_id = daily_lessons.classroom_id
      and e.status = 'active'
      and (e.end_date is null or e.end_date >= daily_lessons.lesson_date)
      and e.start_date <= daily_lessons.lesson_date
      and pc.parent_user_id = auth.uid()
      and pc.can_view_reports = true
  )
);
create policy "lessons_staff_write_assigned" on public.daily_lessons for insert
with check (
  public.has_tenant_role(tenant_id, array['nursery_admin','academic_supervisor']::public.app_role[])
  or public.is_platform_admin()
  or (
    public.has_tenant_role(tenant_id, array['teacher']::public.app_role[])
    and exists (
      select 1 from public.teachers t
      join public.classroom_teachers ct on ct.teacher_id = t.id and ct.tenant_id = t.tenant_id
      where t.tenant_id = daily_lessons.tenant_id
        and t.user_id = auth.uid()
        and t.employment_status = 'active'
        and ct.classroom_id = daily_lessons.classroom_id
    )
  )
);
create policy "lessons_staff_update_assigned" on public.daily_lessons for update
using (
  public.has_tenant_role(tenant_id, array['nursery_admin','academic_supervisor']::public.app_role[])
  or public.is_platform_admin()
  or exists (
    select 1 from public.teachers t
    join public.classroom_teachers ct on ct.teacher_id = t.id and ct.tenant_id = t.tenant_id
    where t.tenant_id = daily_lessons.tenant_id and t.user_id = auth.uid()
      and t.employment_status = 'active' and ct.classroom_id = daily_lessons.classroom_id
  )
)
with check (
  public.has_tenant_role(tenant_id, array['nursery_admin','academic_supervisor']::public.app_role[])
  or public.is_platform_admin()
  or exists (
    select 1 from public.teachers t
    join public.classroom_teachers ct on ct.teacher_id = t.id and ct.tenant_id = t.tenant_id
    where t.tenant_id = daily_lessons.tenant_id and t.user_id = auth.uid()
      and t.employment_status = 'active' and ct.classroom_id = daily_lessons.classroom_id
  )
);
create policy "lessons_admin_delete" on public.daily_lessons for delete
using (public.has_tenant_role(tenant_id, array['nursery_admin','academic_supervisor']::public.app_role[]) or public.is_platform_admin());

create index if not exists idx_books_tenant_level on public.books(tenant_id, level_name);
create index if not exists idx_subjects_tenant_name on public.subjects(tenant_id, name);
