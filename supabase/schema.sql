-- RAWDA initial multi-tenant schema.
-- Run in a fresh Supabase project. Review policies before production use.

create extension if not exists pgcrypto;

create type public.app_role as enum ('platform_admin','nursery_admin','academic_supervisor','teacher','parent');
create type public.assessment_level as enum ('not_started','learning','mastered_with_help','mastered_independently');
create type public.attendance_status as enum ('present','absent','late','excused');

create table public.tenants (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text not null unique,
  status text not null default 'demo' check (status in ('demo','active','suspended')),
  country_code text,
  timezone text not null default 'Asia/Kuwait',
  created_at timestamptz not null default now()
);

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null,
  phone text,
  created_at timestamptz not null default now()
);

create table public.memberships (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  role public.app_role not null,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  unique (tenant_id, user_id, role)
);

create table public.classrooms (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  name text not null,
  level_name text,
  age_min_months int,
  age_max_months int,
  created_at timestamptz not null default now(),
  unique (tenant_id, name),
  unique (id, tenant_id)
);

create table public.children (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  child_code text not null,
  full_name text not null,
  birth_date date,
  status text not null default 'pending' check (status in ('pending','active','inactive','graduated')),
  created_at timestamptz not null default now(),
  unique (tenant_id, child_code),
  unique (id, tenant_id)
);

create table public.parent_children (
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  parent_user_id uuid not null references public.profiles(id) on delete cascade,
  child_id uuid not null,
  relationship text not null default 'guardian',
  can_view_reports boolean not null default true,
  created_at timestamptz not null default now(),
  primary key (tenant_id, parent_user_id, child_id),
  foreign key (child_id, tenant_id) references public.children(id, tenant_id) on delete cascade
);

create table public.teachers (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  employment_status text not null default 'active',
  unique (tenant_id, user_id),
  unique (id, tenant_id)
);

create table public.classroom_teachers (
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  classroom_id uuid not null,
  teacher_id uuid not null,
  primary key (tenant_id, classroom_id, teacher_id),
  foreign key (classroom_id, tenant_id) references public.classrooms(id, tenant_id) on delete cascade,
  foreign key (teacher_id, tenant_id) references public.teachers(id, tenant_id) on delete cascade
);

create table public.enrollments (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  child_id uuid not null,
  classroom_id uuid not null,
  start_date date not null default current_date,
  end_date date,
  status text not null default 'active',
  foreign key (child_id, tenant_id) references public.children(id, tenant_id) on delete cascade,
  foreign key (classroom_id, tenant_id) references public.classrooms(id, tenant_id) on delete restrict
);

create table public.subjects (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid references public.tenants(id) on delete cascade,
  name text not null,
  description text
);

create table public.books (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid references public.tenants(id) on delete cascade,
  title text not null,
  level_name text,
  subject_id uuid references public.subjects(id) on delete set null,
  storage_path text,
  is_published boolean not null default false,
  created_at timestamptz not null default now()
);

create table public.curriculum_units (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  classroom_id uuid references public.classrooms(id) on delete set null,
  title text not null,
  sequence_no int not null default 1
);

create table public.daily_lessons (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  classroom_id uuid not null,
  subject_id uuid references public.subjects(id) on delete set null,
  teacher_id uuid references public.teachers(id) on delete set null,
  lesson_date date not null default current_date,
  title text not null,
  summary text,
  created_at timestamptz not null default now(),
  foreign key (classroom_id, tenant_id) references public.classrooms(id, tenant_id) on delete cascade
);

create table public.skills (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid references public.tenants(id) on delete cascade,
  subject_id uuid references public.subjects(id) on delete set null,
  name text not null,
  age_band text,
  description text
);

create table public.assessments (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  child_id uuid not null,
  skill_id uuid not null references public.skills(id) on delete restrict,
  teacher_id uuid references public.teachers(id) on delete set null,
  level public.assessment_level not null,
  observation text,
  observed_on date not null default current_date,
  created_at timestamptz not null default now(),
  foreign key (child_id, tenant_id) references public.children(id, tenant_id) on delete cascade
);

create table public.attendance (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  child_id uuid not null,
  classroom_id uuid not null,
  attendance_date date not null default current_date,
  status public.attendance_status not null,
  note text,
  recorded_by uuid references public.profiles(id) on delete set null,
  unique (tenant_id, child_id, attendance_date),
  foreign key (child_id, tenant_id) references public.children(id, tenant_id) on delete cascade,
  foreign key (classroom_id, tenant_id) references public.classrooms(id, tenant_id) on delete cascade
);

create table public.announcements (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  title text not null,
  body text not null,
  published_at timestamptz,
  created_at timestamptz not null default now()
);

create table public.subscriptions (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null unique references public.tenants(id) on delete cascade,
  plan_name text not null default 'demo',
  status text not null default 'trial',
  starts_at timestamptz,
  ends_at timestamptz,
  created_at timestamptz not null default now()
);

-- Security helper functions. SECURITY DEFINER functions use a fixed search_path.
create or replace function public.is_platform_admin()
returns boolean language sql stable security definer
set search_path = public
as $$
  select exists (
    select 1 from public.memberships m
    where m.user_id = auth.uid()
      and m.role = 'platform_admin'
      and m.is_active = true
  );
$$;

create or replace function public.is_tenant_member(target_tenant uuid)
returns boolean language sql stable security definer
set search_path = public
as $$
  select exists (
    select 1 from public.memberships m
    where m.user_id = auth.uid()
      and m.tenant_id = target_tenant
      and m.is_active = true
  );
$$;

create or replace function public.has_tenant_role(target_tenant uuid, allowed_roles public.app_role[])
returns boolean language sql stable security definer
set search_path = public
as $$
  select exists (
    select 1 from public.memberships m
    where m.user_id = auth.uid()
      and m.tenant_id = target_tenant
      and m.is_active = true
      and m.role = any(allowed_roles)
  );
$$;

alter table public.tenants enable row level security;
alter table public.profiles enable row level security;
alter table public.memberships enable row level security;
alter table public.classrooms enable row level security;
alter table public.children enable row level security;
alter table public.parent_children enable row level security;
alter table public.teachers enable row level security;
alter table public.classroom_teachers enable row level security;
alter table public.enrollments enable row level security;
alter table public.subjects enable row level security;
alter table public.books enable row level security;
alter table public.curriculum_units enable row level security;
alter table public.daily_lessons enable row level security;
alter table public.skills enable row level security;
alter table public.assessments enable row level security;
alter table public.attendance enable row level security;
alter table public.announcements enable row level security;
alter table public.subscriptions enable row level security;

-- Profiles: users may see/update their own profile; platform admins may inspect.
create policy "profiles_select_self_or_platform" on public.profiles
for select using (id = auth.uid() or public.is_platform_admin());
create policy "profiles_update_self" on public.profiles
for update using (id = auth.uid()) with check (id = auth.uid());

-- Tenant and membership visibility.
create policy "tenants_select_member_or_platform" on public.tenants
for select using (public.is_tenant_member(id) or public.is_platform_admin());
create policy "memberships_select_self_or_admin" on public.memberships
for select using (user_id = auth.uid() or public.is_platform_admin()
  or public.has_tenant_role(tenant_id, array['nursery_admin','academic_supervisor']::public.app_role[]));

-- Tenant-owned tables: tenant members can read; authorized staff can write.
create policy "classrooms_select" on public.classrooms for select
using (public.is_tenant_member(tenant_id) or public.is_platform_admin());
create policy "classrooms_write" on public.classrooms for all
using (public.has_tenant_role(tenant_id, array['nursery_admin','academic_supervisor']::public.app_role[]) or public.is_platform_admin())
with check (public.has_tenant_role(tenant_id, array['nursery_admin','academic_supervisor']::public.app_role[]) or public.is_platform_admin());

create policy "children_select_staff_or_linked_parent" on public.children for select
using (
  public.has_tenant_role(tenant_id, array['nursery_admin','academic_supervisor','teacher']::public.app_role[])
  or public.is_platform_admin()
  or exists (select 1 from public.parent_children pc where pc.tenant_id = children.tenant_id and pc.child_id = children.id and pc.parent_user_id = auth.uid() and pc.can_view_reports)
);
create policy "children_write_admin" on public.children for all
using (public.has_tenant_role(tenant_id, array['nursery_admin']::public.app_role[]) or public.is_platform_admin())
with check (public.has_tenant_role(tenant_id, array['nursery_admin']::public.app_role[]) or public.is_platform_admin());

create policy "parent_children_select_related_or_admin" on public.parent_children for select
using (parent_user_id = auth.uid() or public.has_tenant_role(tenant_id, array['nursery_admin','academic_supervisor']::public.app_role[]) or public.is_platform_admin());
create policy "parent_children_write_admin" on public.parent_children for all
using (public.has_tenant_role(tenant_id, array['nursery_admin']::public.app_role[]) or public.is_platform_admin())
with check (public.has_tenant_role(tenant_id, array['nursery_admin']::public.app_role[]) or public.is_platform_admin());

create policy "teachers_tenant_read" on public.teachers for select
using (public.is_tenant_member(tenant_id) or public.is_platform_admin());
create policy "teachers_admin_write" on public.teachers for all
using (public.has_tenant_role(tenant_id, array['nursery_admin']::public.app_role[]) or public.is_platform_admin())
with check (public.has_tenant_role(tenant_id, array['nursery_admin']::public.app_role[]) or public.is_platform_admin());

create policy "tenant_read_classroom_teachers" on public.classroom_teachers for select
using (public.is_tenant_member(tenant_id) or public.is_platform_admin());
create policy "tenant_admin_write_classroom_teachers" on public.classroom_teachers for all
using (public.has_tenant_role(tenant_id, array['nursery_admin','academic_supervisor']::public.app_role[]) or public.is_platform_admin())
with check (public.has_tenant_role(tenant_id, array['nursery_admin','academic_supervisor']::public.app_role[]) or public.is_platform_admin());

create policy "enrollments_read" on public.enrollments for select
using (public.is_tenant_member(tenant_id) or public.is_platform_admin());
create policy "enrollments_admin_write" on public.enrollments for all
using (public.has_tenant_role(tenant_id, array['nursery_admin']::public.app_role[]) or public.is_platform_admin())
with check (public.has_tenant_role(tenant_id, array['nursery_admin']::public.app_role[]) or public.is_platform_admin());

-- Generic policies for remaining tenant tables; refine teacher and parent scopes before production.
create policy "subjects_read" on public.subjects for select
using (tenant_id is null or public.is_tenant_member(tenant_id) or public.is_platform_admin());
create policy "subjects_admin_write" on public.subjects for all
using (tenant_id is not null and (public.has_tenant_role(tenant_id, array['nursery_admin','academic_supervisor']::public.app_role[]) or public.is_platform_admin()))
with check (tenant_id is not null and (public.has_tenant_role(tenant_id, array['nursery_admin','academic_supervisor']::public.app_role[]) or public.is_platform_admin()));

create policy "books_read" on public.books for select
using ((tenant_id is null and is_published) or (tenant_id is not null and public.is_tenant_member(tenant_id)) or public.is_platform_admin());
create policy "books_admin_write" on public.books for all
using (tenant_id is not null and (public.has_tenant_role(tenant_id, array['nursery_admin','academic_supervisor']::public.app_role[]) or public.is_platform_admin()))
with check (tenant_id is not null and (public.has_tenant_role(tenant_id, array['nursery_admin','academic_supervisor']::public.app_role[]) or public.is_platform_admin()));

create policy "curriculum_read" on public.curriculum_units for select
using (public.is_tenant_member(tenant_id) or public.is_platform_admin());
create policy "curriculum_write" on public.curriculum_units for all
using (public.has_tenant_role(tenant_id, array['nursery_admin','academic_supervisor']::public.app_role[]) or public.is_platform_admin())
with check (public.has_tenant_role(tenant_id, array['nursery_admin','academic_supervisor']::public.app_role[]) or public.is_platform_admin());

create policy "lessons_read" on public.daily_lessons for select
using (public.is_tenant_member(tenant_id) or public.is_platform_admin());
create policy "lessons_write" on public.daily_lessons for all
using (public.has_tenant_role(tenant_id, array['nursery_admin','academic_supervisor','teacher']::public.app_role[]) or public.is_platform_admin())
with check (public.has_tenant_role(tenant_id, array['nursery_admin','academic_supervisor','teacher']::public.app_role[]) or public.is_platform_admin());

create policy "skills_read" on public.skills for select
using (tenant_id is null or public.is_tenant_member(tenant_id) or public.is_platform_admin());
create policy "skills_write" on public.skills for all
using (tenant_id is not null and (public.has_tenant_role(tenant_id, array['nursery_admin','academic_supervisor']::public.app_role[]) or public.is_platform_admin()))
with check (tenant_id is not null and (public.has_tenant_role(tenant_id, array['nursery_admin','academic_supervisor']::public.app_role[]) or public.is_platform_admin()));

create policy "assessments_read" on public.assessments for select
using (public.is_tenant_member(tenant_id) or public.is_platform_admin());
create policy "assessments_write" on public.assessments for all
using (public.has_tenant_role(tenant_id, array['nursery_admin','academic_supervisor','teacher']::public.app_role[]) or public.is_platform_admin())
with check (public.has_tenant_role(tenant_id, array['nursery_admin','academic_supervisor','teacher']::public.app_role[]) or public.is_platform_admin());

create policy "attendance_read" on public.attendance for select
using (public.is_tenant_member(tenant_id) or public.is_platform_admin());
create policy "attendance_write" on public.attendance for all
using (public.has_tenant_role(tenant_id, array['nursery_admin','academic_supervisor','teacher']::public.app_role[]) or public.is_platform_admin())
with check (public.has_tenant_role(tenant_id, array['nursery_admin','academic_supervisor','teacher']::public.app_role[]) or public.is_platform_admin());

create policy "announcements_read" on public.announcements for select
using (public.is_tenant_member(tenant_id) or public.is_platform_admin());
create policy "announcements_admin_write" on public.announcements for all
using (public.has_tenant_role(tenant_id, array['nursery_admin']::public.app_role[]) or public.is_platform_admin())
with check (public.has_tenant_role(tenant_id, array['nursery_admin']::public.app_role[]) or public.is_platform_admin());

create policy "subscriptions_admin_read" on public.subscriptions for select
using (public.is_platform_admin() or public.has_tenant_role(tenant_id, array['nursery_admin']::public.app_role[]));
create policy "subscriptions_platform_write" on public.subscriptions for all
using (public.is_platform_admin()) with check (public.is_platform_admin());

-- Indexes for common tenant-scoped lookups.
create index idx_memberships_user on public.memberships(user_id, tenant_id);
create index idx_children_tenant on public.children(tenant_id);
create index idx_lessons_class_date on public.daily_lessons(tenant_id, classroom_id, lesson_date desc);
create index idx_assessments_child_date on public.assessments(tenant_id, child_id, observed_on desc);
create index idx_attendance_class_date on public.attendance(tenant_id, classroom_id, attendance_date desc);
