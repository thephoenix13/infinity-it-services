-- ============================================================
-- 004_users.sql
-- User profiles — extends Supabase auth.users
-- id matches auth.users.id exactly (no separate FK needed for auth)
-- ============================================================

CREATE TABLE users (
  id               uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  org_id           uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  full_name        text NOT NULL,
  role             user_role NOT NULL,
  -- branch_ids: which branches this user can access
  -- admin: [] means all branches in org
  -- manager/technician/front_desk: must have at least one branch
  branch_ids       uuid[] NOT NULL DEFAULT '{}',
  is_active        boolean NOT NULL DEFAULT true,
  -- Web Push subscription object for PWA push notifications
  push_subscription jsonb,
  created_at       timestamptz NOT NULL DEFAULT now(),
  updated_at       timestamptz NOT NULL DEFAULT now()
);

CREATE TRIGGER users_updated_at
  BEFORE UPDATE ON users
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- Indexes
CREATE INDEX idx_users_org_id   ON users(org_id);
CREATE INDEX idx_users_role     ON users(org_id, role);

-- ============================================================
-- RLS helper functions (in public schema — auth schema is owned by Supabase)
-- Used in RLS policies to avoid repeated subqueries.
-- SECURITY DEFINER so they run as the function owner (bypasses
-- RLS on the users table itself during the lookup).
-- STABLE so the query planner can cache them within a transaction.
-- ============================================================

CREATE OR REPLACE FUNCTION public.current_user_org_id()
RETURNS uuid
LANGUAGE sql SECURITY DEFINER STABLE AS $$
  SELECT org_id FROM public.users WHERE id = auth.uid()
$$;

CREATE OR REPLACE FUNCTION public.current_user_role()
RETURNS user_role
LANGUAGE sql SECURITY DEFINER STABLE AS $$
  SELECT role FROM public.users WHERE id = auth.uid()
$$;

CREATE OR REPLACE FUNCTION public.current_user_branch_ids()
RETURNS uuid[]
LANGUAGE sql SECURITY DEFINER STABLE AS $$
  SELECT branch_ids FROM public.users WHERE id = auth.uid()
$$;

-- Returns true if the current user is an admin for their org
CREATE OR REPLACE FUNCTION public.current_user_is_admin()
RETURNS boolean
LANGUAGE sql SECURITY DEFINER STABLE AS $$
  SELECT role = 'admin' FROM public.users WHERE id = auth.uid()
$$;

-- Returns true if the current user has access to the given branch
CREATE OR REPLACE FUNCTION public.current_user_has_branch_access(p_branch_id uuid)
RETURNS boolean
LANGUAGE sql SECURITY DEFINER STABLE AS $$
  SELECT
    CASE
      WHEN role = 'admin' THEN true
      ELSE p_branch_id = ANY(branch_ids)
    END
  FROM public.users
  WHERE id = auth.uid()
$$;
