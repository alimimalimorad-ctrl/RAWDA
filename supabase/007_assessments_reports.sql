-- RAWDA v0.8: restrict assessment visibility and writing by role and child/classroom.
-- Run after schema.sql and migrations 002-006.

-- Skills are visible to tenant members; only nursery admins/supervisors manage them.
drop policy if exists "skills_read" on public.skills;
drop policy if exists "skills_write" on public.skills;
drop policy if exists "skills_admin_write" on public.skills;
create policy "skills_read_tenant" on public.skills for select
using (public.is_tenant_member(tenant_id) or public.is_platform_admin());
create policy "skills_admin_write" on public.skills for all
using (public.has_tenant_role(tenant_id, array['nursery_admin','academic_supervisor']::public.app_role[]) or public.is_platform_admin())
with check (public.has_tenant_role(tenant_id, array['nursery_admin','academic_supervisor']::public.app_role[]) or public.is_platform_admin());

-- Remove broad tenant-wide assessment access from the initial schema.
drop policy if exists "assessments_read" on public.assessments;
drop policy if exists "assessments_write" on public.assessments;
drop policy if exists "assessments_read_authorized_scope" on public.assessments;
drop policy if exists "assessments_insert_authorized_scope" on public.assessments;
drop policy if exists "assessments_update_authorized_scope" on public.assessments;
drop policy if exists "assessments_read_scoped" on public.assessments;
drop policy if exists "assessments_select_scoped" on public.assessments;
drop policy if exists "assessments_insert_scoped" on public.assessments;
drop policy if exists "assessments_update_scoped" on public.assessments;
drop policy if exists "assessments_delete_admin" on public.assessments;

create policy "assessments_select_scoped" on public.assessments for select
using (
  public.is_platform_admin()
  or public.has_tenant_role(tenant_id, array['nursery_admin','academic_supervisor']::public.app_role[])
  or exists (
    select 1
    from public.teachers t
    join public.classroom_teachers ct on ct.teacher_id = t.id and ct.tenant_id = t.tenant_id
    join public.enrollments e on e.classroom_id = ct.classroom_id and e.tenant_id = ct.tenant_id
    where t.tenant_id = assessments.tenant_id and t.user_id = auth.uid()
      and t.employment_status = 'active' and e.child_id = assessments.child_id
      and e.status = 'active' and e.end_date is null
  )
  or exists (
    select 1 from public.parent_children pc
    where pc.tenant_id = assessments.tenant_id
      and pc.child_id = assessments.child_id
      and pc.parent_user_id = auth.uid()
      and pc.can_view_reports = true
  )
);

create policy "assessments_insert_scoped" on public.assessments for insert
with check (
  exists (select 1 from public.skills s where s.id = assessments.skill_id and s.tenant_id = assessments.tenant_id)
  and (
  public.is_platform_admin()
  or public.has_tenant_role(tenant_id, array['nursery_admin','academic_supervisor']::public.app_role[])
  or (
    public.has_tenant_role(tenant_id, array['teacher']::public.app_role[])
    and exists (
      select 1
      from public.teachers t
      join public.classroom_teachers ct on ct.teacher_id = t.id and ct.tenant_id = t.tenant_id
      join public.enrollments e on e.classroom_id = ct.classroom_id and e.tenant_id = ct.tenant_id
      where t.tenant_id = assessments.tenant_id
        and t.user_id = auth.uid()
        and t.employment_status = 'active'
        and e.child_id = assessments.child_id
        and e.status = 'active'
        and e.end_date is null
    )
  )
  )
);

create policy "assessments_update_scoped" on public.assessments for update
using (
  public.is_platform_admin()
  or public.has_tenant_role(tenant_id, array['nursery_admin','academic_supervisor']::public.app_role[])
  or (
    public.has_tenant_role(tenant_id, array['teacher']::public.app_role[])
    and exists (
      select 1 from public.teachers t
      join public.classroom_teachers ct on ct.teacher_id = t.id and ct.tenant_id = t.tenant_id
      join public.enrollments e on e.classroom_id = ct.classroom_id and e.tenant_id = ct.tenant_id
      where t.tenant_id = assessments.tenant_id and t.user_id = auth.uid()
        and t.employment_status = 'active' and e.child_id = assessments.child_id
        and e.status = 'active' and e.end_date is null
    )
  )
)
with check (
  exists (select 1 from public.skills s where s.id = assessments.skill_id and s.tenant_id = assessments.tenant_id)
  and (
  public.is_platform_admin()
  or public.has_tenant_role(tenant_id, array['nursery_admin','academic_supervisor']::public.app_role[])
  or (
    public.has_tenant_role(tenant_id, array['teacher']::public.app_role[])
    and exists (
      select 1 from public.teachers t
      join public.classroom_teachers ct on ct.teacher_id = t.id and ct.tenant_id = t.tenant_id
      join public.enrollments e on e.classroom_id = ct.classroom_id and e.tenant_id = ct.tenant_id
      where t.tenant_id = assessments.tenant_id and t.user_id = auth.uid()
        and t.employment_status = 'active' and e.child_id = assessments.child_id
        and e.status = 'active' and e.end_date is null
    )
  )
  )
);

create policy "assessments_delete_admin" on public.assessments for delete
using (public.is_platform_admin() or public.has_tenant_role(tenant_id, array['nursery_admin']::public.app_role[]));

create index if not exists idx_assessments_tenant_date on public.assessments(tenant_id, observed_on desc);
create index if not exists idx_skills_tenant_name on public.skills(tenant_id, name);
