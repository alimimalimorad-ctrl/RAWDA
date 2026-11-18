# RAWDA onboarding flow

## First nursery owner
1. Visitor opens `/onboarding`.
2. Supabase Auth creates the user.
3. `handle_new_user` creates the profile from trusted auth metadata.
4. Authenticated user calls `create_nursery_with_admin`.
5. The SQL function validates input, ensures the user has no existing active membership, and atomically creates:
   - tenant in demo status
   - nursery_admin membership
   - demo subscription
6. User is redirected to the dashboard.

## Important setup
- Run `schema.sql`, then `002_onboarding.sql`.
- Set Supabase Auth Site URL and allowed redirect URLs for local and deployed domains.
- For local development, use `http://localhost:3000`.
- Configure email confirmation. When confirmation is enabled, signUp may return no session; user confirms email and then signs in. The current starter displays this state and does not create the nursery until a session exists. A production-grade continuation page should finish onboarding after confirmation.
- Configure SMTP before public launch.
- Keep the service role key server-side only; this starter does not need it.

## Known limitations
- No invitation workflow for additional staff yet.
- No password reset UI yet.
- No multi-factor authentication yet.
- No production audit log yet.
- No production tenant-switching UX yet.
