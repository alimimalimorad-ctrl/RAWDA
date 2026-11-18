-- RAWDA: parent self-linking using nursery slug + child code.
-- Run AFTER 007_assessments_reports.sql. A request is created as pending;
-- a nursery administrator must approve it before parent_children is granted.

create table if not exists public.parent_link_requests (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  child_id uuid not null,
  parent_user_id uuid not null references public.profiles(id) on delete cascade,
  status text not null default 'pending' check (status in ('pending','approved','rejected')),
  created_at timestamptz not null default now(),
  reviewed_at timestamptz,
  reviewed_by uuid references public.profiles(id) on delete set null,
  foreign key (child_id, tenant_id) references public.children(id, tenant_id) on delete cascade,
  unique (tenant_id, child_id, parent_user_id)
);

alter table public.parent_link_requests enable row level security;
drop policy if exists parent_link_requests_parent_read on public.parent_link_requests;
create policy parent_link_requests_parent_read on public.parent_link_requests
for select using (parent_user_id = auth.uid() or public.has_tenant_role(tenant_id, array['nursery_admin','academic_supervisor']::public.app_role[]) or public.is_platform_admin());
drop policy if exists parent_link_requests_admin_update on public.parent_link_requests;
create policy parent_link_requests_admin_update on public.parent_link_requests
for update using (public.has_tenant_role(tenant_id, array['nursery_admin']::public.app_role[]) or public.is_platform_admin())
with check (public.has_tenant_role(tenant_id, array['nursery_admin']::public.app_role[]) or public.is_platform_admin());

create or replace function public.link_child_by_code(nursery_slug_input text, child_code_input text)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  current_user_id uuid := auth.uid();
  target_tenant uuid;
  target_child uuid;
  request_id uuid;
begin
  if current_user_id is null then raise exception 'يجب تسجيل الدخول أولاً'; end if;
  if length(trim(coalesce(nursery_slug_input,''))) < 3 or length(trim(coalesce(child_code_input,''))) < 4 then
    raise exception 'يرجى إدخال معرّف الحضانة وكود الطفل بشكل صحيح';
  end if;
  select t.id, c.id into target_tenant, target_child
  from public.tenants t join public.children c on c.tenant_id = t.id
  where t.slug = lower(trim(nursery_slug_input))
    and c.child_code = trim(child_code_input)
    and c.status = 'active'
  limit 1;
  if target_child is null then raise exception 'لم يتم العثور على طفل نشط بهذه البيانات'; end if;
  if exists (select 1 from public.parent_children pc where pc.tenant_id = target_tenant and pc.child_id = target_child and pc.parent_user_id = current_user_id) then
    raise exception 'هذا الطفل مرتبط بحسابك بالفعل';
  end if;
  insert into public.parent_link_requests (tenant_id, child_id, parent_user_id)
  values (target_tenant, target_child, current_user_id)
  on conflict (tenant_id, child_id, parent_user_id) do update set status = 'pending', created_at = now(), reviewed_at = null, reviewed_by = null
  returning id into request_id;
  return request_id;
end;
$$;
revoke all on function public.link_child_by_code(text,text) from public;
grant execute on function public.link_child_by_code(text,text) to authenticated;

-- Approval is deliberately explicit. Admin approval inserts the authorized relationship.
create or replace function public.review_parent_link_request(request_id_input uuid, approve_input boolean)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare r public.parent_link_requests%rowtype;
begin
  select * into r from public.parent_link_requests where id = request_id_input for update;
  if not found then raise exception 'طلب الربط غير موجود'; end if;
  if not (public.has_tenant_role(r.tenant_id, array['nursery_admin']::public.app_role[]) or public.is_platform_admin()) then
    raise exception 'ليس لديك صلاحية مراجعة هذا الطلب';
  end if;
  if r.status <> 'pending' then raise exception 'تمت مراجعة هذا الطلب مسبقاً'; end if;
  if approve_input then
    insert into public.parent_children (tenant_id, parent_user_id, child_id, relationship, can_view_reports)
    values (r.tenant_id, r.parent_user_id, r.child_id, 'guardian', true)
    on conflict (tenant_id, parent_user_id, child_id) do update set can_view_reports = true;
    update public.parent_link_requests set status = 'approved', reviewed_at = now(), reviewed_by = auth.uid() where id = r.id;
  else
    update public.parent_link_requests set status = 'rejected', reviewed_at = now(), reviewed_by = auth.uid() where id = r.id;
  end if;
end;
$$;
revoke all on function public.review_parent_link_request(uuid,boolean) from public;
grant execute on function public.review_parent_link_request(uuid,boolean) to authenticated;
