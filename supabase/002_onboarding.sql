-- RAWDA onboarding migration.
-- Run AFTER schema.sql in the Supabase SQL Editor.
-- A nursery and its first nursery_admin membership are created atomically.
-- The function only allows a newly authenticated user with no existing memberships.

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, full_name, phone)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'full_name', split_part(coalesce(new.email, 'مستخدم'), '@', 1)),
    new.phone
  )
  on conflict (id) do update
    set full_name = excluded.full_name,
        phone = excluded.phone;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created_rawda on auth.users;
create trigger on_auth_user_created_rawda
after insert on auth.users
for each row execute procedure public.handle_new_user();

create or replace function public.create_nursery_with_admin(
  nursery_name text,
  nursery_slug text,
  nursery_city text default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  current_user_id uuid := auth.uid();
  new_tenant_id uuid;
begin
  if current_user_id is null then
    raise exception 'يجب تسجيل الدخول أولاً';
  end if;

  if length(trim(coalesce(nursery_name, ''))) < 3 then
    raise exception 'اسم الحضانة يجب أن يتكون من 3 أحرف على الأقل';
  end if;

  if nursery_slug !~ '^[a-z0-9-]{3,40}$' then
    raise exception 'المعرّف المختصر غير صالح';
  end if;

  if exists (select 1 from public.memberships where user_id = current_user_id and is_active = true) then
    raise exception 'هذا الحساب مرتبط بالفعل بحضانة أو بصلاحية أخرى';
  end if;

  insert into public.tenants (name, slug, status, country_code)
  values (trim(nursery_name), lower(nursery_slug), 'demo', 'KW')
  returning id into new_tenant_id;

  insert into public.memberships (tenant_id, user_id, role, is_active)
  values (new_tenant_id, current_user_id, 'nursery_admin', true);

  insert into public.subscriptions (tenant_id, plan_name, status)
  values (new_tenant_id, 'demo', 'trial');

  return new_tenant_id;
end;
$$;

revoke all on function public.create_nursery_with_admin(text, text, text) from public;
grant execute on function public.create_nursery_with_admin(text, text, text) to authenticated;

-- Important: profile rows are created only by the auth trigger.
-- Users must not be able to assign themselves platform_admin or nursery_admin roles
-- through direct table writes. Membership creation for the first nursery is via RPC.


-- Scope child/classroom records to assigned teachers and linked guardians.
-- These SECURITY DEFINER helpers avoid recursive RLS evaluation while checking relationships.
create or replace function public.can_access_child(target_tenant uuid, target_child uuid)
returns boolean
language sql stable security definer
set search_path = public
as $$
  select
    public.is_platform_admin()
    or public.has_tenant_role(target_tenant, array['nursery_admin','academic_supervisor']::public.app_role[])
    or exists (
      select 1 from public.parent_children pc
      where pc.tenant_id = target_tenant
        and pc.child_id = target_child
        and pc.parent_user_id = auth.uid()
        and pc.can_view_reports = true
    )
    or exists (
      select 1
      from public.enrollments e
      join public.classroom_teachers ct
        on ct.tenant_id = e.tenant_id
       and ct.classroom_id = e.classroom_id
      join public.teachers t
        on t.id = ct.teacher_id
       and t.tenant_id = ct.tenant_id
      where e.tenant_id = target_tenant
        and e.child_id = target_child
        and t.user_id = auth.uid()
        and e.status = 'active'
    );
$$;

create or replace function public.can_access_classroom(target_tenant uuid, target_classroom uuid)
returns boolean
language sql stable security definer
set search_path = public
as $$
  select
    public.is_platform_admin()
    or public.has_tenant_role(target_tenant, array['nursery_admin','academic_supervisor']::public.app_role[])
    or exists (
      select 1 from public.classroom_teachers ct
      join public.teachers t on t.id = ct.teacher_id and t.tenant_id = ct.tenant_id
      where ct.tenant_id = target_tenant
        and ct.classroom_id = target_classroom
        and t.user_id = auth.uid()
    )
    or exists (
      select 1 from public.enrollments e
      join public.parent_children pc
        on pc.tenant_id = e.tenant_id and pc.child_id = e.child_id
      where e.tenant_id = target_tenant
        and e.classroom_id = target_classroom
        and pc.parent_user_id = auth.uid()
        and pc.can_view_reports = true
        and e.status = 'active'
    );
$$;

-- Replace broad tenant-member read policies for sensitive child/classroom learning data.
drop policy if exists "children_select_staff_or_linked_parent" on public.children;
create policy "children_select_authorized_scope" on public.children
for select using (public.can_access_child(tenant_id, id));

drop policy if exists "enrollments_read" on public.enrollments;
create policy "enrollments_read_authorized_scope" on public.enrollments
for select using (public.can_access_child(tenant_id, child_id));

drop policy if exists "lessons_read" on public.daily_lessons;
create policy "lessons_read_authorized_scope" on public.daily_lessons
for select using (public.can_access_classroom(tenant_id, classroom_id));

drop policy if exists "lessons_write" on public.daily_lessons;
create policy "lessons_insert_authorized_scope" on public.daily_lessons
for insert with check (
  public.has_tenant_role(tenant_id, array['nursery_admin','academic_supervisor']::public.app_role[])
  or (
    public.has_tenant_role(tenant_id, array['teacher']::public.app_role[])
    and public.can_access_classroom(tenant_id, classroom_id)
  )
  or public.is_platform_admin()
);
create policy "lessons_update_authorized_scope" on public.daily_lessons
for update using (
  public.has_tenant_role(tenant_id, array['nursery_admin','academic_supervisor']::public.app_role[])
  or (
    public.has_tenant_role(tenant_id, array['teacher']::public.app_role[])
    and public.can_access_classroom(tenant_id, classroom_id)
  )
  or public.is_platform_admin()
) with check (
  public.has_tenant_role(tenant_id, array['nursery_admin','academic_supervisor']::public.app_role[])
  or (
    public.has_tenant_role(tenant_id, array['teacher']::public.app_role[])
    and public.can_access_classroom(tenant_id, classroom_id)
  )
  or public.is_platform_admin()
);
create policy "lessons_delete_admin" on public.daily_lessons
for delete using (
  public.has_tenant_role(tenant_id, array['nursery_admin','academic_supervisor']::public.app_role[])
  or public.is_platform_admin()
);

drop policy if exists "assessments_read" on public.assessments;
create policy "assessments_read_authorized_scope" on public.assessments
for select using (public.can_access_child(tenant_id, child_id));

drop policy if exists "assessments_write" on public.assessments;
create policy "assessments_insert_authorized_scope" on public.assessments
for insert with check (
  public.has_tenant_role(tenant_id, array['nursery_admin','academic_supervisor']::public.app_role[])
  or (
    public.has_tenant_role(tenant_id, array['teacher']::public.app_role[])
    and public.can_access_child(tenant_id, child_id)
  )
  or public.is_platform_admin()
);
create policy "assessments_update_authorized_scope" on public.assessments
for update using (
  public.has_tenant_role(tenant_id, array['nursery_admin','academic_supervisor']::public.app_role[])
  or (
    public.has_tenant_role(tenant_id, array['teacher']::public.app_role[])
    and public.can_access_child(tenant_id, child_id)
  )
  or public.is_platform_admin()
) with check (
  public.has_tenant_role(tenant_id, array['nursery_admin','academic_supervisor']::public.app_role[])
  or (
    public.has_tenant_role(tenant_id, array['teacher']::public.app_role[])
    and public.can_access_child(tenant_id, child_id)
  )
  or public.is_platform_admin()
);
create policy "assessments_delete_admin" on public.assessments
for delete using (
  public.has_tenant_role(tenant_id, array['nursery_admin','academic_supervisor']::public.app_role[])
  or public.is_platform_admin()
);

drop policy if exists "attendance_read" on public.attendance;
create policy "attendance_read_authorized_scope" on public.attendance
for select using (public.can_access_child(tenant_id, child_id));

drop policy if exists "attendance_write" on public.attendance;
create policy "attendance_insert_authorized_scope" on public.attendance
for insert with check (
  public.has_tenant_role(tenant_id, array['nursery_admin','academic_supervisor']::public.app_role[])
  or (
    public.has_tenant_role(tenant_id, array['teacher']::public.app_role[])
    and public.can_access_classroom(tenant_id, classroom_id)
  )
  or public.is_platform_admin()
);
create policy "attendance_update_authorized_scope" on public.attendance
for update using (
  public.has_tenant_role(tenant_id, array['nursery_admin','academic_supervisor']::public.app_role[])
  or (
    public.has_tenant_role(tenant_id, array['teacher']::public.app_role[])
    and public.can_access_classroom(tenant_id, classroom_id)
  )
  or public.is_platform_admin()
) with check (
  public.has_tenant_role(tenant_id, array['nursery_admin','academic_supervisor']::public.app_role[])
  or (
    public.has_tenant_role(tenant_id, array['teacher']::public.app_role[])
    and public.can_access_classroom(tenant_id, classroom_id)
  )
  or public.is_platform_admin()
);
create policy "attendance_delete_admin" on public.attendance
for delete using (
  public.has_tenant_role(tenant_id, array['nursery_admin']::public.app_role[])
  or public.is_platform_admin()
);
