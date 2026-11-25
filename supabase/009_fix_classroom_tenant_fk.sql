-- RAWDA migration 009: add the composite classroom key required by tenant-safe foreign keys.
-- Safe to run after the original schema and migrations 002-008.

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conrelid = 'public.classrooms'::regclass
      and conname = 'classrooms_id_tenant_id_key'
  ) then
    alter table public.classrooms
      add constraint classrooms_id_tenant_id_key unique (id, tenant_id);
  end if;
end
$$;
