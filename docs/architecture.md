# RAWDA Architecture Decision Record

## Approved decisions
- Product: multi-tenant SaaS for nurseries.
- Interface: Arabic-first, RTL, responsive web.
- Hosting target: Cloud.
- Domain label: `rawda` (exact TLD availability and trademark clearance remain to be checked).
- First release: Demo with synthetic data.

## Proposed deployment
- Next.js application on Vercel.
- Supabase managed PostgreSQL, Auth and private Storage.
- DNS/domain provider selected after domain availability and jurisdiction review.
- Separate development, staging/demo, and production environments.

## Request flow
Browser -> Next.js UI -> authenticated server/API layer -> PostgreSQL (RLS enforced).
Private media -> signed URLs issued only after authorization.

## Tenant model
Every tenant-owned row contains `tenant_id`.
A membership maps a user to a tenant and role.
A user may have multiple memberships.
Parent-child access is represented explicitly in `parent_children`.
Never trust a tenant identifier supplied by the browser without verifying membership server-side.

## Release gates
1. Schema and RLS tests pass.
2. Auth and invitation flow implemented.
3. Cross-tenant isolation tests pass.
4. Parent-child authorization tests pass.
5. Private storage policies reviewed.
6. Backups, logging, error monitoring and incident procedure configured.
7. Privacy notice and parental consent process reviewed for launch jurisdictions.
