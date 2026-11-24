-- ============================================================
-- 011_functions.sql
-- Business logic functions
-- ============================================================

-- ============================================================
-- generate_job_number(branch_id)
-- Returns the next job number string for a branch.
-- Called by trigger on jobs INSERT.
-- Runs as SECURITY DEFINER to bypass RLS on job_number_sequences.
-- ============================================================
CREATE OR REPLACE FUNCTION generate_job_number(p_branch_id uuid)
RETURNS text
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_prefix  text;
  v_year    int;
  v_month   text;
  v_seq     int;
BEGIN
  SELECT job_prefix INTO v_prefix
  FROM branches WHERE id = p_branch_id;

  v_year  := EXTRACT(YEAR FROM now())::int;
  v_month := TO_CHAR(now(), 'MM');

  -- Upsert sequence row and increment atomically
  INSERT INTO job_number_sequences (branch_id, org_id, year, last_seq)
  VALUES (
    p_branch_id,
    (SELECT org_id FROM branches WHERE id = p_branch_id),
    v_year,
    1
  )
  ON CONFLICT (branch_id, year)
  DO UPDATE SET last_seq = job_number_sequences.last_seq + 1
  RETURNING last_seq INTO v_seq;

  RETURN v_prefix || '-' || v_year || '-' || v_month || '-' || LPAD(v_seq::text, 6, '0');
END;
$$;

-- ============================================================
-- transition_job_status(job_id, new_status, user_id, notes)
-- Validates the status transition, updates the job, and writes
-- the audit log entry — all in one atomic transaction.
-- Called from the application layer (not client-side directly).
-- ============================================================
CREATE OR REPLACE FUNCTION transition_job_status(
  p_job_id    uuid,
  p_new_status job_status,
  p_user_id   uuid,
  p_notes     text DEFAULT NULL
)
RETURNS json
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_current_status job_status;
  v_org_id         uuid;
  v_allowed        boolean := false;
BEGIN
  -- Fetch current state
  SELECT status, org_id INTO v_current_status, v_org_id
  FROM jobs WHERE id = p_job_id;

  IF NOT FOUND THEN
    RETURN json_build_object('success', false, 'error', 'Job not found');
  END IF;

  -- Validate allowed transitions
  v_allowed := CASE
    WHEN v_current_status = 'received'      AND p_new_status = 'inspection'    THEN true
    WHEN v_current_status = 'inspection'    AND p_new_status = 'estimate_sent' THEN true
    WHEN v_current_status = 'estimate_sent' AND p_new_status = 'approved'      THEN true
    WHEN v_current_status = 'approved'      AND p_new_status = 'in_service'    THEN true
    WHEN v_current_status = 'approved'      AND p_new_status = 'parts'         THEN true
    WHEN v_current_status = 'parts'         AND p_new_status = 'in_service'    THEN true
    WHEN v_current_status = 'in_service'    AND p_new_status = 'ready'         THEN true
    WHEN v_current_status = 'ready'         AND p_new_status = 'delivered'     THEN true
    -- Allow manager/admin to move backward for corrections (not forward-skipping)
    WHEN v_current_status = 'in_service'    AND p_new_status = 'approved'      THEN true
    WHEN v_current_status = 'parts'         AND p_new_status = 'approved'      THEN true
    ELSE false
  END;

  IF NOT v_allowed THEN
    RETURN json_build_object(
      'success', false,
      'error', 'Invalid status transition from ' || v_current_status || ' to ' || p_new_status
    );
  END IF;

  -- Gate: 'delivered' requires full payment
  IF p_new_status = 'delivered' THEN
    IF (SELECT outstanding_balance FROM job_payment_summary WHERE job_id = p_job_id) > 0 THEN
      RETURN json_build_object('success', false, 'error', 'Cannot deliver — outstanding balance remaining');
    END IF;
  END IF;

  -- Update job status
  UPDATE jobs SET status = p_new_status, updated_at = now()
  WHERE id = p_job_id;

  -- Write audit log
  INSERT INTO job_status_log (job_id, org_id, from_status, to_status, changed_by, notes)
  VALUES (p_job_id, v_org_id, v_current_status, p_new_status, p_user_id, p_notes);

  RETURN json_build_object(
    'success',     true,
    'from_status', v_current_status,
    'to_status',   p_new_status
  );
END;
$$;

-- ============================================================
-- get_job_by_portal_token(token)
-- Public function — no auth required.
-- Returns job data for the customer portal.
-- Returns NULL if token not found or expired.
-- ============================================================
CREATE OR REPLACE FUNCTION get_job_by_portal_token(p_token uuid)
RETURNS json
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_result json;
BEGIN
  SELECT json_build_object(
    'job',         row_to_json(j),
    'customer',    row_to_json(c),
    'asset',       row_to_json(a),
    'branch',      row_to_json(b),
    'org_name',    o.name,
    'org_settings', os.settings,
    'parts',       (SELECT json_agg(row_to_json(p)) FROM job_parts p WHERE p.job_id = j.id),
    'photos',      (SELECT json_agg(row_to_json(ph)) FROM job_photos ph WHERE ph.job_id = j.id),
    'status_log',  (SELECT json_agg(row_to_json(sl) ORDER BY sl.changed_at ASC) FROM job_status_log sl WHERE sl.job_id = j.id),
    'invoice',     (SELECT row_to_json(i) FROM invoices i WHERE i.job_id = j.id)
  ) INTO v_result
  FROM portal_tokens pt
  JOIN jobs j         ON j.id = pt.job_id
  JOIN customers c    ON c.id = j.customer_id
  JOIN assets a       ON a.id = j.asset_id
  JOIN branches b     ON b.id = j.branch_id
  JOIN organizations o ON o.id = j.org_id
  JOIN org_settings os ON os.org_id = j.org_id
  WHERE pt.token = p_token
    AND (pt.expires_at IS NULL OR pt.expires_at > now());

  RETURN v_result;
END;
$$;

-- ============================================================
-- generate_invoice(job_id, user_id)
-- Snapshots job_parts totals into an invoice record.
-- Called when job moves to 'ready'.
-- ============================================================
CREATE OR REPLACE FUNCTION generate_invoice(p_job_id uuid, p_user_id uuid)
RETURNS uuid
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_org_id       uuid;
  v_parts_total  numeric(10,2);
  v_labour_total numeric(10,2);
  v_invoice_id   uuid;
BEGIN
  SELECT org_id INTO v_org_id FROM jobs WHERE id = p_job_id;

  SELECT
    COALESCE(SUM(CASE WHEN NOT is_labour THEN unit_cost * quantity ELSE 0 END), 0),
    COALESCE(SUM(CASE WHEN is_labour     THEN unit_cost * quantity ELSE 0 END), 0)
  INTO v_parts_total, v_labour_total
  FROM job_parts WHERE job_id = p_job_id;

  INSERT INTO invoices (job_id, org_id, parts_total, labour_total, subtotal, total, generated_by)
  VALUES (
    p_job_id, v_org_id,
    v_parts_total, v_labour_total,
    v_parts_total + v_labour_total,
    v_parts_total + v_labour_total,
    p_user_id
  )
  ON CONFLICT (job_id) DO NOTHING
  RETURNING id INTO v_invoice_id;

  -- Also update estimate_total on the job to keep in sync
  UPDATE jobs SET estimate_total = v_parts_total + v_labour_total
  WHERE id = p_job_id;

  RETURN v_invoice_id;
END;
$$;

-- ============================================================
-- create_org(org_name, slug, admin_user_id, admin_full_name)
-- Called from the Next.js signup Route Handler (service role).
-- Creates org + org_settings + admin user record atomically.
-- ============================================================
CREATE OR REPLACE FUNCTION create_org(
  p_org_name      text,
  p_slug          text,
  p_admin_user_id uuid,
  p_admin_name    text
)
RETURNS uuid
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_org_id uuid;
BEGIN
  INSERT INTO organizations (name, slug)
  VALUES (p_org_name, p_slug)
  RETURNING id INTO v_org_id;

  INSERT INTO org_settings (org_id) VALUES (v_org_id);

  INSERT INTO users (id, org_id, full_name, role, branch_ids)
  VALUES (p_admin_user_id, v_org_id, p_admin_name, 'admin', '{}');

  RETURN v_org_id;
END;
$$;
