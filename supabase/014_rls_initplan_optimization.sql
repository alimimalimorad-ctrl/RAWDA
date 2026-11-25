-- Optimize RLS policy evaluation by evaluating auth.uid() once per statement.
-- This preserves each policy's existing predicates and only wraps auth.uid()
-- in a scalar subquery, as recommended by Supabase's RLS performance guidance.
DO $migration$
DECLARE
  policy_row record;
  using_sql text;
  check_sql text;
  alter_sql text;
BEGIN
  FOR policy_row IN
    SELECT schemaname, tablename, policyname, qual, with_check
    FROM pg_policies
    WHERE schemaname = 'public'
      AND (
        coalesce(qual, '') LIKE '%auth.uid()%'
        OR coalesce(with_check, '') LIKE '%auth.uid()%'
      )
  LOOP
    using_sql := CASE
      WHEN policy_row.qual IS NULL THEN ''
      ELSE ' USING (' || replace(policy_row.qual, 'auth.uid()', '(select auth.uid())') || ')'
    END;
    check_sql := CASE
      WHEN policy_row.with_check IS NULL THEN ''
      ELSE ' WITH CHECK (' || replace(policy_row.with_check, 'auth.uid()', '(select auth.uid())') || ')'
    END;

    alter_sql := format(
      'ALTER POLICY %I ON %I.%I%s%s',
      policy_row.policyname,
      policy_row.schemaname,
      policy_row.tablename,
      using_sql,
      check_sql
    );
    EXECUTE alter_sql;
  END LOOP;
END
$migration$;
