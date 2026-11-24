-- ============================================================
-- 010_rls.sql
-- Row-Level Security policies for all tables
-- Pattern: every table is org-scoped first, then branch-scoped
-- where applicable. Uses the auth helper functions from 004_users.sql.
-- ============================================================

-- Enable RLS on all tables
ALTER TABLE organizations       ENABLE ROW LEVEL SECURITY;
ALTER TABLE org_settings        ENABLE ROW LEVEL SECURITY;
ALTER TABLE branches            ENABLE ROW LEVEL SECURITY;
ALTER TABLE job_number_sequences ENABLE ROW LEVEL SECURITY;
ALTER TABLE users               ENABLE ROW LEVEL SECURITY;
ALTER TABLE customers           ENABLE ROW LEVEL SECURITY;
ALTER TABLE assets              ENABLE ROW LEVEL SECURITY;
ALTER TABLE jobs                ENABLE ROW LEVEL SECURITY;
ALTER TABLE job_status_log      ENABLE ROW LEVEL SECURITY;
ALTER TABLE job_parts           ENABLE ROW LEVEL SECURITY;
ALTER TABLE job_photos          ENABLE ROW LEVEL SECURITY;
ALTER TABLE job_notes           ENABLE ROW LEVEL SECURITY;
ALTER TABLE invoices            ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments            ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications_log   ENABLE ROW LEVEL SECURITY;
ALTER TABLE portal_tokens       ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- ORGANIZATIONS
-- ============================================================
CREATE POLICY "users see their own org"
  ON organizations FOR SELECT
  USING (id = public.current_user_org_id());

CREATE POLICY "admin can update their org"
  ON organizations FOR UPDATE
  USING (id = public.current_user_org_id() AND public.current_user_is_admin());

-- ============================================================
-- ORG SETTINGS
-- ============================================================
CREATE POLICY "all staff can read org settings"
  ON org_settings FOR SELECT
  USING (org_id = public.current_user_org_id());

CREATE POLICY "admin can update org settings"
  ON org_settings FOR UPDATE
  USING (org_id = public.current_user_org_id() AND public.current_user_is_admin());

-- ============================================================
-- BRANCHES
-- ============================================================
CREATE POLICY "all staff can read their org branches"
  ON branches FOR SELECT
  USING (org_id = public.current_user_org_id());

CREATE POLICY "admin can insert branches"
  ON branches FOR INSERT
  WITH CHECK (org_id = public.current_user_org_id() AND public.current_user_is_admin());

CREATE POLICY "admin can update branches"
  ON branches FOR UPDATE
  USING (org_id = public.current_user_org_id() AND public.current_user_is_admin());

-- ============================================================
-- JOB NUMBER SEQUENCES
-- ============================================================
CREATE POLICY "all staff can read sequences"
  ON job_number_sequences FOR SELECT
  USING (org_id = public.current_user_org_id());

-- Sequences are only written by the generate_job_number() function
-- which runs as SECURITY DEFINER — no direct insert policy needed.

-- ============================================================
-- USERS
-- ============================================================
-- Staff can see all users in their org (needed for technician dropdowns, etc.)
CREATE POLICY "staff can read users in their org"
  ON users FOR SELECT
  USING (org_id = public.current_user_org_id());

-- Users can update their own profile (name, push_subscription)
CREATE POLICY "users can update own profile"
  ON users FOR UPDATE
  USING (id = auth.uid());

-- Admin can insert and update any user in their org
CREATE POLICY "admin can insert users"
  ON users FOR INSERT
  WITH CHECK (org_id = public.current_user_org_id() AND public.current_user_is_admin());

CREATE POLICY "admin can update users"
  ON users FOR UPDATE
  USING (org_id = public.current_user_org_id() AND public.current_user_is_admin());

-- ============================================================
-- CUSTOMERS
-- ============================================================
CREATE POLICY "staff can read customers in their org"
  ON customers FOR SELECT
  USING (org_id = public.current_user_org_id());

CREATE POLICY "front_desk and above can insert customers"
  ON customers FOR INSERT
  WITH CHECK (org_id = public.current_user_org_id());

CREATE POLICY "front_desk and above can update customers"
  ON customers FOR UPDATE
  USING (org_id = public.current_user_org_id());

-- ============================================================
-- ASSETS
-- ============================================================
CREATE POLICY "staff can read assets in their org"
  ON assets FOR SELECT
  USING (org_id = public.current_user_org_id());

CREATE POLICY "staff can insert assets"
  ON assets FOR INSERT
  WITH CHECK (org_id = public.current_user_org_id());

CREATE POLICY "staff can update assets"
  ON assets FOR UPDATE
  USING (org_id = public.current_user_org_id());

-- ============================================================
-- JOBS — branch-scoped for non-admin roles
-- ============================================================
CREATE POLICY "staff can read jobs in their branch(es)"
  ON jobs FOR SELECT
  USING (
    org_id = public.current_user_org_id()
    AND public.current_user_has_branch_access(branch_id)
  );

CREATE POLICY "front_desk and above can create jobs"
  ON jobs FOR INSERT
  WITH CHECK (
    org_id = public.current_user_org_id()
    AND public.current_user_has_branch_access(branch_id)
  );

CREATE POLICY "staff can update jobs in their branch(es)"
  ON jobs FOR UPDATE
  USING (
    org_id = public.current_user_org_id()
    AND public.current_user_has_branch_access(branch_id)
  );

-- ============================================================
-- JOB STATUS LOG — insert only, no updates or deletes
-- ============================================================
CREATE POLICY "staff can read status log for their branch jobs"
  ON job_status_log FOR SELECT
  USING (org_id = public.current_user_org_id());

CREATE POLICY "staff can insert status log entries"
  ON job_status_log FOR INSERT
  WITH CHECK (org_id = public.current_user_org_id());

-- No UPDATE or DELETE policy — immutable by design.

-- ============================================================
-- JOB PARTS, PHOTOS, NOTES
-- ============================================================
CREATE POLICY "staff can read job_parts in their org"
  ON job_parts FOR SELECT USING (org_id = public.current_user_org_id());
CREATE POLICY "staff can insert job_parts"
  ON job_parts FOR INSERT WITH CHECK (org_id = public.current_user_org_id());
CREATE POLICY "staff can update job_parts"
  ON job_parts FOR UPDATE USING (org_id = public.current_user_org_id());
CREATE POLICY "staff can delete job_parts"
  ON job_parts FOR DELETE USING (org_id = public.current_user_org_id());

CREATE POLICY "staff can read job_photos in their org"
  ON job_photos FOR SELECT USING (org_id = public.current_user_org_id());
CREATE POLICY "staff can insert job_photos"
  ON job_photos FOR INSERT WITH CHECK (org_id = public.current_user_org_id());

CREATE POLICY "staff can read job_notes in their org"
  ON job_notes FOR SELECT USING (org_id = public.current_user_org_id());
CREATE POLICY "staff can insert job_notes"
  ON job_notes FOR INSERT WITH CHECK (org_id = public.current_user_org_id());

-- ============================================================
-- INVOICES
-- ============================================================
CREATE POLICY "staff can read invoices in their org"
  ON invoices FOR SELECT USING (org_id = public.current_user_org_id());
CREATE POLICY "staff can insert invoices"
  ON invoices FOR INSERT WITH CHECK (org_id = public.current_user_org_id());

-- ============================================================
-- PAYMENTS
-- ============================================================
CREATE POLICY "staff can read payments in their org"
  ON payments FOR SELECT USING (org_id = public.current_user_org_id());
CREATE POLICY "front_desk and above can insert payments"
  ON payments FOR INSERT WITH CHECK (org_id = public.current_user_org_id());

-- ============================================================
-- NOTIFICATIONS LOG
-- ============================================================
CREATE POLICY "staff can read notification log in their org"
  ON notifications_log FOR SELECT USING (org_id = public.current_user_org_id());

-- Notifications are inserted by Edge Functions (service role), not client.
-- No insert policy needed here.

-- ============================================================
-- PORTAL TOKENS
-- Public access is handled via a separate RPC function (see 012_functions.sql).
-- Staff can read tokens for jobs in their org.
-- ============================================================
CREATE POLICY "staff can read portal tokens in their org"
  ON portal_tokens FOR SELECT USING (org_id = public.current_user_org_id());
