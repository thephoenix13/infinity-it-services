-- ============================================================
-- 014_phase1_inspection.sql
-- Phase 1: Inspection & Estimation
-- - Adds diagnosis/resolution fields to jobs
-- - Adds approval tracking fields to jobs
-- - Creates job-photos storage bucket + policies
-- - Adds approve_estimate_via_portal() RPC
-- - Adds backward transition: estimate_sent → inspection (decline)
-- - Modifies transition_job_status to record approval_via on forward transitions
-- ============================================================

-- ── 1. New columns on jobs ─────────────────────────────────────────────────

ALTER TABLE jobs
  ADD COLUMN IF NOT EXISTS diagnosis_notes      text,
  ADD COLUMN IF NOT EXISTS resolution_summary   text,
  ADD COLUMN IF NOT EXISTS customer_approved_via text,   -- 'staff_verbal' | 'portal' | 'whatsapp'
  ADD COLUMN IF NOT EXISTS customer_decline_reason text;

-- ── 2. Storage bucket for job photos ──────────────────────────────────────

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'job-photos',
  'job-photos',
  false,
  10485760,  -- 10 MB per file
  ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/heic', 'image/heif']
)
ON CONFLICT (id) DO NOTHING;

-- Storage RLS: authenticated users can upload/read photos for their own org
-- Path convention: {org_id}/{job_id}/{photo_type}/{uuid}.{ext}
CREATE POLICY "Org members can upload job photos"
ON storage.objects FOR INSERT TO authenticated
WITH CHECK (
  bucket_id = 'job-photos'
  AND (storage.foldername(name))[1] = (
    SELECT org_id::text FROM users WHERE id = auth.uid()
  )
);

CREATE POLICY "Org members can view job photos"
ON storage.objects FOR SELECT TO authenticated
USING (
  bucket_id = 'job-photos'
  AND (storage.foldername(name))[1] = (
    SELECT org_id::text FROM users WHERE id = auth.uid()
  )
);

CREATE POLICY "Org members can delete job photos"
ON storage.objects FOR DELETE TO authenticated
USING (
  bucket_id = 'job-photos'
  AND (storage.foldername(name))[1] = (
    SELECT org_id::text FROM users WHERE id = auth.uid()
  )
);

-- ── 3. Modify transition_job_status ────────────────────────────────────────
-- Adds:
--   - estimate_sent → inspection (decline path — manager/admin correction)
--   - Records customer_approved_via when transitioning to 'approved'
--   - Clears decline reason when re-approving

CREATE OR REPLACE FUNCTION transition_job_status(
  p_job_id        uuid,
  p_new_status    job_status,
  p_user_id       uuid,
  p_notes         text DEFAULT NULL,
  p_approved_via  text DEFAULT NULL   -- 'staff_verbal' | 'portal' | 'whatsapp'
)
RETURNS json
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_current_status job_status;
  v_org_id         uuid;
  v_allowed        boolean := false;
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
    WHEN v_current_status = 'estimate_sent' AND p_new_status = 'inspection'    THEN true  -- decline path
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

  -- Gate: delivered requires full payment
  IF p_new_status = 'delivered' THEN
    IF (SELECT outstanding_balance FROM job_payment_summary WHERE job_id = p_job_id) > 0 THEN
      RETURN json_build_object('success', false, 'error', 'Cannot deliver — outstanding balance remaining');
    END IF;
  END IF;

  -- Update job — track approval metadata when transitioning to 'approved'
  IF p_new_status = 'approved' THEN
    UPDATE jobs
    SET
      status = p_new_status,
      updated_at = now(),
      customer_approved_via = COALESCE(p_approved_via, 'staff_verbal'),
      customer_decline_reason = NULL
    WHERE id = p_job_id;
  ELSIF p_new_status = 'inspection' AND v_current_status = 'estimate_sent' THEN
    -- Decline path: clear approval fields, keep decline reason in notes
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

  -- Audit log
  INSERT INTO job_status_log (job_id, org_id, from_status, to_status, changed_by, notes)
  VALUES (p_job_id, v_org_id, v_current_status, p_new_status, p_user_id, p_notes);

  RETURN json_build_object(
    'success',     true,
    'from_status', v_current_status,
    'to_status',   p_new_status
  );
END;
$$;

-- ── 4. approve_estimate_via_portal(token, approved, decline_reason) ────────
-- Public function — no auth required (uses portal token as credential).
-- Called from the customer-facing tracking page.

CREATE OR REPLACE FUNCTION approve_estimate_via_portal(
  p_token          uuid,
  p_approved       boolean,
  p_decline_reason text DEFAULT NULL
)
RETURNS json
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_job_id    uuid;
  v_org_id    uuid;
  v_status    job_status;
  v_system_user uuid;
BEGIN
  -- Resolve job from token
  SELECT pt.job_id, pt.org_id INTO v_job_id, v_org_id
  FROM portal_tokens pt
  WHERE pt.token = p_token
    AND (pt.expires_at IS NULL OR pt.expires_at > now());

  IF NOT FOUND THEN
    RETURN json_build_object('success', false, 'error', 'Invalid or expired token');
  END IF;

  SELECT status INTO v_status FROM jobs WHERE id = v_job_id;

  IF v_status != 'estimate_sent' THEN
    RETURN json_build_object(
      'success', false,
      'error', 'Estimate is no longer pending — current status: ' || v_status
    );
  END IF;

  -- Use the org's admin user as the "changed_by" for portal actions
  SELECT id INTO v_system_user FROM users
  WHERE org_id = v_org_id AND role = 'admin'
  ORDER BY created_at LIMIT 1;

  IF p_approved THEN
    UPDATE jobs
    SET
      status = 'approved',
      updated_at = now(),
      customer_approved_via = 'portal',
      customer_decline_reason = NULL
    WHERE id = v_job_id;

    INSERT INTO job_status_log (job_id, org_id, from_status, to_status, changed_by, notes)
    VALUES (v_job_id, v_org_id, 'estimate_sent', 'approved', v_system_user, 'Customer approved via tracking portal');
  ELSE
    UPDATE jobs
    SET
      status = 'inspection',
      updated_at = now(),
      customer_approved_via = NULL,
      customer_decline_reason = COALESCE(p_decline_reason, 'Declined via portal')
    WHERE id = v_job_id;

    INSERT INTO job_status_log (job_id, org_id, from_status, to_status, changed_by, notes)
    VALUES (v_job_id, v_org_id, 'estimate_sent', 'inspection', v_system_user,
      'Customer declined via tracking portal' ||
      CASE WHEN p_decline_reason IS NOT NULL THEN ': ' || p_decline_reason ELSE '' END
    );
  END IF;

  RETURN json_build_object('success', true, 'approved', p_approved);
END;
$$;

-- ── 5. Update get_job_by_portal_token to include approval fields ───────────

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
    'parts',       (SELECT json_agg(row_to_json(p) ORDER BY p.created_at) FROM job_parts p WHERE p.job_id = j.id),
    'photos',      (SELECT json_agg(row_to_json(ph) ORDER BY ph.created_at) FROM job_photos ph WHERE ph.job_id = j.id),
    'status_log',  (SELECT json_agg(row_to_json(sl) ORDER BY sl.changed_at ASC) FROM job_status_log sl WHERE sl.job_id = j.id),
    'invoice',     (SELECT row_to_json(i) FROM invoices i WHERE i.job_id = j.id)
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
