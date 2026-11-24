-- ============================================================
-- 018_phase6.sql
-- Phase 6: Push Notifications & WhatsApp Webhook & Time Tracking
-- ============================================================

-- ── 1. push_subscriptions table ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS push_subscriptions (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  org_id     uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  endpoint   text NOT NULL,
  p256dh     text NOT NULL,
  auth       text NOT NULL,
  created_at timestamptz DEFAULT now(),
  UNIQUE(user_id, endpoint)
);

ALTER TABLE push_subscriptions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage own push subscriptions"
  ON push_subscriptions FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- ── 2. Time tracking columns on jobs ────────────────────────────────────────
ALTER TABLE jobs
  ADD COLUMN IF NOT EXISTS work_started_at   timestamptz,
  ADD COLUMN IF NOT EXISTS work_completed_at timestamptz;

-- ── 3. Update transition_job_status ─────────────────────────────────────────
-- Adds: work_started_at on in_service, work_completed_at on ready
-- Keeps: warranty_expires_at on delivered, approval on approved/decline paths
CREATE OR REPLACE FUNCTION transition_job_status(
  p_job_id        uuid,
  p_new_status    job_status,
  p_user_id       uuid,
  p_notes         text DEFAULT NULL,
  p_approved_via  text DEFAULT NULL
)
RETURNS json
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_current_status job_status;
  v_org_id         uuid;
  v_allowed        boolean := false;
  v_warranty_days  int;
BEGIN
  SELECT status, org_id INTO v_current_status, v_org_id
  FROM jobs WHERE id = p_job_id;

  IF NOT FOUND THEN
    RETURN json_build_object('success', false, 'error', 'Job not found');
  END IF;

  v_allowed := CASE
    WHEN v_current_status = 'received'      AND p_new_status = 'inspection'    THEN true
    WHEN v_current_status = 'inspection'    AND p_new_status = 'estimate_sent' THEN true
    WHEN v_current_status = 'estimate_sent' AND p_new_status = 'approved'      THEN true
    WHEN v_current_status = 'estimate_sent' AND p_new_status = 'inspection'    THEN true
    WHEN v_current_status = 'approved'      AND p_new_status = 'in_service'    THEN true
    WHEN v_current_status = 'approved'      AND p_new_status = 'parts'         THEN true
    WHEN v_current_status = 'parts'         AND p_new_status = 'in_service'    THEN true
    WHEN v_current_status = 'in_service'    AND p_new_status = 'ready'         THEN true
    WHEN v_current_status = 'ready'         AND p_new_status = 'delivered'     THEN true
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

  IF p_new_status = 'delivered' THEN
    IF (SELECT outstanding_balance FROM job_payment_summary WHERE job_id = p_job_id) > 0 THEN
      RETURN json_build_object('success', false, 'error', 'Cannot deliver — outstanding balance remaining');
    END IF;
  END IF;

  IF p_new_status = 'approved' THEN
    UPDATE jobs
    SET
      status = p_new_status,
      updated_at = now(),
      customer_approved_via = COALESCE(p_approved_via, 'staff_verbal'),
      customer_decline_reason = NULL
    WHERE id = p_job_id;

  ELSIF p_new_status = 'in_service' THEN
    UPDATE jobs
    SET
      status = p_new_status,
      updated_at = now(),
      work_started_at = COALESCE(work_started_at, now())
    WHERE id = p_job_id;

  ELSIF p_new_status = 'ready' THEN
    UPDATE jobs
    SET
      status = p_new_status,
      updated_at = now(),
      work_completed_at = now()
    WHERE id = p_job_id;

  ELSIF p_new_status = 'delivered' THEN
    SELECT COALESCE(
      (SELECT (os.settings->>'warranty_days')::int FROM org_settings os WHERE os.org_id = v_org_id),
      30
    ) INTO v_warranty_days;

    UPDATE jobs
    SET
      status = p_new_status,
      updated_at = now(),
      warranty_expires_at = now() + (v_warranty_days || ' days')::interval
    WHERE id = p_job_id;

  ELSIF p_new_status = 'inspection' AND v_current_status = 'estimate_sent' THEN
    UPDATE jobs
    SET
      status = p_new_status,
      updated_at = now(),
      customer_approved_via = NULL,
      customer_decline_reason = p_notes
    WHERE id = p_job_id;

  ELSE
    UPDATE jobs
    SET status = p_new_status, updated_at = now()
    WHERE id = p_job_id;
  END IF;

  INSERT INTO job_status_log (job_id, org_id, from_status, to_status, changed_by, notes)
  VALUES (p_job_id, v_org_id, v_current_status, p_new_status, p_user_id, p_notes);

  RETURN json_build_object(
    'success',     true,
    'from_status', v_current_status,
    'to_status',   p_new_status
  );
END;
$$;
