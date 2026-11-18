-- Synthetic demo tenant and sample data. Does not create auth users.
insert into public.tenants (id, name, slug, status, country_code)
values ('10000000-0000-4000-8000-000000000001', 'حضانة البراعم التجريبية', 'al-baraem-demo', 'demo', 'KW')
on conflict (slug) do nothing;

insert into public.classrooms (tenant_id, name, level_name, age_min_months, age_max_months)
values
('10000000-0000-4000-8000-000000000001', 'الفصل الأزرق', 'المستوى الأول', 36, 48),
('10000000-0000-4000-8000-000000000001', 'الفصل الأخضر', 'المستوى الثاني', 48, 60)
on conflict (tenant_id, name) do nothing;

insert into public.subjects (tenant_id, name, description)
values
('10000000-0000-4000-8000-000000000001', 'اللغة العربية', 'الحروف والمفردات والتعبير'),
('10000000-0000-4000-8000-000000000001', 'الرياضيات', 'الأعداد والأشكال والأنماط'),
('10000000-0000-4000-8000-000000000001', 'اللغة الإنجليزية', 'الحروف والمفردات الأساسية');
