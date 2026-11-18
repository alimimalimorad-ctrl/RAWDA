# Security checklist — before real children data

- [ ] Enable Supabase Auth and verify email/phone flows.
- [ ] Create server-side authorization helpers; never trust client-supplied tenant_id.
- [ ] Enable RLS on every tenant-owned table.
- [ ] Add automated tests proving tenant A cannot read/write tenant B.
- [ ] Add parent-child relationship tests.
- [ ] Restrict teacher access to assigned classrooms.
- [ ] Use private Storage buckets and short-lived signed URLs.
- [ ] Do not expose service-role keys in browser bundles.
- [ ] Collect only necessary child data.
- [ ] Obtain and record guardian consent where required.
- [ ] Define retention/deletion and data export processes.
- [ ] Audit sensitive administrative actions.
- [ ] Configure backups, monitoring and incident response.
- [ ] Review applicable child privacy and data protection laws in every launch market.
