-- Store the city collected during nursery onboarding.
alter table public.tenants add column if not exists city text;
create or replace function public.create_nursery_with_admin(
  nursery_name text, nursery_slug text, nursery_city text default null
)
returns uuid language plpgsql security definer set search_path = public
as $$
declare
  current_user_id uuid := auth.uid();
  new_tenant_id uuid;
begin
  if current_user_id is null then raise exception 'يجب تسجيل الدخول أولاً'; end if;
  if length(trim(coalesce(nursery_name, ''))) < 3 then raise exception 'اسم الحضانة يجب أن يتكون من 3 أحرف على الأقل'; end if;
  if nursery_slug !~ '^[a-z0-9-]{3,40}$' then raise exception 'المعرّف المختصر غير صالح'; end if;
  if exists (select 1 from public.memberships where user_id = current_user_id and is_active = true) then
    raise exception 'هذا الحساب مرتبط بالفعل بحضانة أو بصلاحية أخرى';
  end if;
  insert into public.tenants (name, slug, status, country_code, city)
  values (trim(nursery_name), lower(nursery_slug), 'demo', 'KW', nullif(trim(nursery_city), ''))
  returning id into new_tenant_id;
  insert into public.memberships (tenant_id, user_id, role, is_active)
  values (new_tenant_id, current_user_id, 'nursery_admin', true);
  insert into public.subscriptions (tenant_id, plan_name, status)
  values (new_tenant_id, 'demo', 'trial');
  return new_tenant_id;
end;
$$;
revoke all on function public.create_nursery_with_admin(text,text,text) from public, anon;
grant execute on function public.create_nursery_with_admin(text,text,text) to authenticated;
