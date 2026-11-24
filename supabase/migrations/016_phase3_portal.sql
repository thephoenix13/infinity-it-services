-- ============================================================
-- 016_phase3_portal.sql
-- Phase 3: Customer Portal Enhancements
-- - warranty_expires_at on jobs
-- - auto-set warranty on delivery via transition_job_status
-- - device history in get_job_by_portal_token
-- ============================================================

-- ── 1. Warranty column ─────────────────────────────────────────────────────
ALTER TABLE jobs
  ADD COLUMN IF NOT EXISTS warranty_expires_at timestamptz;

-- ── 2. Update transition_job_status to auto-set warranty on delivery ────────
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
  ELSIF p_new_status = 'inspection' AND v_current_status = 'estimate_sent' THEN
    UPDATE jobs
    SET
      status = p_new_status,
      updated_at = now(),
      customer_approved_via = NULL,
      customer_decline_reason = p_notes
    WHERE id = p_job_id;
  ELSIF p_new_status = 'delivered' THEN
    -- Auto-set warranty expiry from org settings (default 30 days)
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

-- ── 3. get_job_by_portal_token — add device_history ────────────────────────
CREATE OR REPLACE FUNCTION get_job_by_portal_token(p_token uuid)
RETURNS json
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_result json;
BEGIN
  SELECT json_build_object(
    'job',            row_to_json(j),
    'customer',       row_to_json(c),
    'asset',          row_to_json(a),
    'branch',         row_to_json(b),
    'org_name',       o.name,
    'org_settings',   os.settings,
    'parts',          (SELECT json_agg(row_to_json(p) ORDER BY p.created_at) FROM job_parts p WHERE p.job_id = j.id),
    'photos',         (SELECT json_agg(row_to_json(ph) ORDER BY ph.created_at) FROM job_photos ph WHERE ph.job_id = j.id),
    'status_log',     (SELECT json_agg(row_to_json(sl) ORDER BY sl.changed_at ASC) FROM job_status_log sl WHERE sl.job_id = j.id),
    'invoice',        (SELECT row_to_json(i) FROM invoices i WHERE i.job_id = j.id),
    'device_history', (
      SELECT json_agg(
        json_build_object(
          'job_number',      dj.job_number,
          'status',          dj.status,
          'issue_category',  dj.issue_category,
          'created_at',      dj.created_at,
          'updated_at',      dj.updated_at
        )
        ORDER BY dj.created_at DESC
      )
      FROM jobs dj
      WHERE dj.asset_id = j.asset_id
        AND dj.id != j.id
      LIMIT 10
    )
  ) INTO v_result
  FROM portal_tokens pt
  JOIN jobs j          ON j.id = pt.job_id
  JOIN customers c     ON c.id = j.customer_id
  JOIN assets a        ON a.id = j.asset_id
  JOIN branches b      ON b.id = j.branch_id
  JOIN organizations o ON o.id = j.org_id
  JOIN org_settings os ON os.org_id = j.org_id
  WHERE pt.token = p_token
    AND (pt.expires_at IS NULL OR pt.expires_at > now());

  RETURN v_result;
END;
$$;
