-- RAWDA attendance: restrict access to assigned teachers and linked parents.
drop policy if exists "attendance_read" on public.attendance;
drop policy if exists "attendance_write" on public.attendance;

create policy "attendance_read_scoped" on public.attendance
for select using (
  public.is_platform_admin()
  or public.has_tenant_role(tenant_id, array['nursery_admin','academic_supervisor']::public.app_role[])
  or exists (
    select 1
    from public.teachers t
    join public.classroom_teachers ct on ct.teacher_id = t.id and ct.tenant_id = t.tenant_id
    where t.tenant_id = attendance.tenant_id
      and t.user_id = auth.uid()
      and ct.classroom_id = attendance.classroom_id
      and t.employment_status = 'active'
  )
  or exists (
    select 1 from public.parent_children pc
    where pc.tenant_id = attendance.tenant_id
      and pc.child_id = attendance.child_id
      and pc.parent_user_id = auth.uid()
      and pc.can_view_reports = true
  )
);

create policy "attendance_insert_scoped" on public.attendance
for insert with check (
  public.is_platform_admin()
  or public.has_tenant_role(tenant_id, array['nursery_admin','academic_supervisor']::public.app_role[])
  or exists (
    select 1
    from public.teachers t
    join public.classroom_teachers ct on ct.teacher_id = t.id and ct.tenant_id = t.tenant_id
    where t.tenant_id = attendance.tenant_id
      and t.user_id = auth.uid()
      and ct.classroom_id = attendance.classroom_id
      and t.employment_status = 'active'
  )
);

create policy "attendance_update_scoped" on public.attendance
for update using (
  public.is_platform_admin()
  or public.has_tenant_role(tenant_id, array['nursery_admin','academic_supervisor']::public.app_role[])
  or exists (
    select 1
    from public.teachers t
    join public.classroom_teachers ct on ct.teacher_id = t.id and ct.tenant_id = t.tenant_id
    where t.tenant_id = attendance.tenant_id
      and t.user_id = auth.uid()
      and ct.classroom_id = attendance.classroom_id
      and t.employment_status = 'active'
  )
) with check (
  public.is_platform_admin()
  or public.has_tenant_role(tenant_id, array['nursery_admin','academic_supervisor']::public.app_role[])
  or exists (
    select 1
    from public.teachers t
    join public.classroom_teachers ct on ct.teacher_id = t.id and ct.tenant_id = t.tenant_id
    where t.tenant_id = attendance.tenant_id
      and t.user_id = auth.uid()
      and ct.classroom_id = attendance.classroom_id
      and t.employment_status = 'active'
  )
);

create index if not exists idx_attendance_tenant_date_class
on public.attendance(tenant_id, attendance_date, classroom_id);
