-- RAWDA staff and guardian management.
-- Run AFTER 001 schema.sql and 002_onboarding.sql.
-- Staff/guardian accounts must first exist in Supabase Auth (invite/sign-up).
-- Nursery admins can then attach those existing accounts to their tenant.

alter table public.profiles add column if not exists email text;
create index if not exists idx_profiles_email_lower on public.profiles (lower(email));

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, full_name, phone, email)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'full_name', split_part(coalesce(new.email, 'مستخدم'), '@', 1)),
    new.phone,
    lower(new.email)
  )
  on conflict (id) do update
    set full_name = excluded.full_name,
        phone = excluded.phone,
        email = excluded.email;
  return new;
end;
$$;

update public.profiles p
set email = lower(u.email)
from auth.users u
where u.id = p.id and p.email is distinct from lower(u.email);

drop policy if exists "profiles_select_self_or_platform" on public.profiles;
create policy "profiles_select_self_admin_or_platform" on public.profiles
for select using (
  id = auth.uid()
  or public.is_platform_admin()
  or exists (
    select 1 from public.memberships m
    where m.user_id = auth.uid()
      and m.tenant_id in (
        select own.tenant_id from public.memberships own
        where own.user_id = profiles.id and own.is_active = true
      )
      and m.role in ('nursery_admin','academic_supervisor')
      and m.is_active = true
  )
);

create or replace function public.add_existing_teacher(
  target_tenant uuid,
  teacher_email text,
  teacher_name text default null,
  teacher_phone text default null,
  target_classroom uuid default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  target_user uuid;
  new_teacher uuid;
begin
  if not public.has_tenant_role(target_tenant, array['nursery_admin']::public.app_role[]) then
    raise exception 'غير مصرح: يلزم حساب مدير الحضانة';
  end if;
  if nullif(trim(teacher_email), '') is null then
    raise exception 'البريد الإلكتروني مطلوب';
  end if;

  select id into target_user from public.profiles
  where lower(email) = lower(trim(teacher_email))
  limit 1;
  if target_user is null then
    raise exception 'لا يوجد حساب بهذا البريد. يجب على المعلمة إنشاء حساب أو قبول الدعوة أولاً';
  end if;

  if exists (
    select 1 from public.memberships
    where tenant_id = target_tenant and user_id = target_user and is_active = true
      and role <> 'teacher'
  ) then
    raise exception 'هذا الحساب مرتبط بدور آخر داخل الحضانة';
  end if;

  insert into public.profiles(id, full_name, phone, email)
  values(target_user, coalesce(nullif(trim(teacher_name), ''), 'معلمة'), nullif(trim(teacher_phone), ''), lower(trim(teacher_email)))
  on conflict (id) do update set
    full_name = coalesce(nullif(trim(teacher_name), ''), public.profiles.full_name),
    phone = coalesce(nullif(trim(teacher_phone), ''), public.profiles.phone);

  insert into public.memberships(tenant_id, user_id, role, is_active)
  values(target_tenant, target_user, 'teacher', true)
  on conflict (tenant_id, user_id, role) do update set is_active = true;

  insert into public.teachers(tenant_id, user_id, employment_status)
  values(target_tenant, target_user, 'active')
  on conflict (tenant_id, user_id) do update set employment_status = 'active'
  returning id into new_teacher;

  if target_classroom is not null then
    if not exists(select 1 from public.classrooms where id = target_classroom and tenant_id = target_tenant) then
      raise exception 'الفصل المحدد لا يتبع هذه الحضانة';
    end if;
    insert into public.classroom_teachers(tenant_id, classroom_id, teacher_id)
    values(target_tenant, target_classroom, new_teacher)
    on conflict do nothing;
  end if;
  return new_teacher;
end;
$$;

create or replace function public.link_existing_parent(
  target_tenant uuid,
  target_child uuid,
  parent_email text,
  relation_name text default 'ولي أمر'
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  target_user uuid;
begin
  if not public.has_tenant_role(target_tenant, array['nursery_admin']::public.app_role[]) then
    raise exception 'غير مصرح: يلزم حساب مدير الحضانة';
  end if;
  if not exists(select 1 from public.children where id = target_child and tenant_id = target_tenant) then
    raise exception 'الطفل غير موجود في هذه الحضانة';
  end if;
  select id into target_user from public.profiles
  where lower(email) = lower(trim(parent_email))
  limit 1;
  if target_user is null then
    raise exception 'لا يوجد حساب بهذا البريد. يجب على ولي الأمر إنشاء حساب أو قبول الدعوة أولاً';
  end if;
  if exists (
    select 1 from public.memberships
    where tenant_id = target_tenant and user_id = target_user and is_active = true
      and role not in ('parent')
  ) then
    raise exception 'هذا الحساب مرتبط بدور موظف داخل الحضانة';
  end if;
  insert into public.memberships(tenant_id, user_id, role, is_active)
  values(target_tenant, target_user, 'parent', true)
  on conflict (tenant_id, user_id, role) do update set is_active = true;
  insert into public.parent_children(tenant_id, parent_user_id, child_id, relationship)
  values(target_tenant, target_user, target_child, coalesce(nullif(trim(relation_name), ''), 'ولي أمر'))
  on conflict (tenant_id, parent_user_id, child_id) do update
    set relationship = excluded.relationship;
  return target_user;
end;
$$;

revoke all on function public.add_existing_teacher(uuid,text,text,text,uuid) from public;
revoke all on function public.link_existing_parent(uuid,uuid,text,text) from public;
grant execute on function public.add_existing_teacher(uuid,text,text,text,uuid) to authenticated;
grant execute on function public.link_existing_parent(uuid,uuid,text,text) to authenticated;

create index if not exists idx_teachers_tenant on public.teachers(tenant_id);
create index if not exists idx_parent_children_child on public.parent_children(tenant_id, child_id);
