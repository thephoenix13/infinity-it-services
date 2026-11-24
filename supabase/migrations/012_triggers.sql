-- ============================================================
-- 012_triggers.sql
-- Database triggers for automation
-- ============================================================

-- ============================================================
-- on_job_insert: fires after a new job row is created.
-- 1. Generates the job number using the branch prefix + sequence.
-- 2. Creates the portal token for the customer tracking URL.
-- ============================================================
CREATE OR REPLACE FUNCTION on_job_insert()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_job_number text;
  v_token      uuid;
BEGIN
  -- Generate job number
  v_job_number := generate_job_number(NEW.branch_id);
  v_token      := gen_random_uuid();

  -- Write back job number and portal token reference
  UPDATE jobs
  SET job_number = v_job_number, portal_token = v_token
  WHERE id = NEW.id;

  -- Create portal token record
  INSERT INTO portal_tokens (job_id, org_id, token)
  VALUES (NEW.id, NEW.org_id, v_token);

  -- Write the initial status log entry
  INSERT INTO job_status_log (job_id, org_id, from_status, to_status, changed_by, notes)
  VALUES (NEW.id, NEW.org_id, NULL, 'received', NEW.created_by, 'Job created');

  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_job_insert
  AFTER INSERT ON jobs
  FOR EACH ROW EXECUTE FUNCTION on_job_insert();

-- ============================================================
-- on_job_ready: fires when job status changes to 'ready'.
-- Auto-generates the invoice from job_parts.
-- ============================================================
CREATE OR REPLACE FUNCTION on_job_status_change()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  -- Auto-generate invoice when job becomes ready
  IF NEW.status = 'ready' AND OLD.status != 'ready' THEN
    PERFORM generate_invoice(NEW.id, NEW.assigned_tech_id);
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_job_status_change
  AFTER UPDATE OF status ON jobs
  FOR EACH ROW EXECUTE FUNCTION on_job_status_change();

-- ============================================================
-- Protect job_status_log from modification.
-- Any UPDATE or DELETE on this table raises an error.
-- ============================================================
CREATE OR REPLACE FUNCTION protect_status_log()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  RAISE EXCEPTION 'job_status_log is immutable — records cannot be modified or deleted';
END;
$$;

CREATE TRIGGER trg_protect_status_log_update
  BEFORE UPDATE ON job_status_log
  FOR EACH ROW EXECUTE FUNCTION protect_status_log();

CREATE TRIGGER trg_protect_status_log_delete
  BEFORE DELETE ON job_status_log
  FOR EACH ROW EXECUTE FUNCTION protect_status_log();

-- ============================================================
-- Protect job_notes from modification.
-- Notes are append-only — same immutability as status log.
-- ============================================================
CREATE OR REPLACE FUNCTION protect_job_notes()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  RAISE EXCEPTION 'job_notes are immutable — notes cannot be modified or deleted';
END;
$$;

CREATE TRIGGER trg_protect_notes_update
  BEFORE UPDATE ON job_notes
  FOR EACH ROW EXECUTE FUNCTION protect_job_notes();

CREATE TRIGGER trg_protect_notes_delete
  BEFORE DELETE ON job_notes
  FOR EACH ROW EXECUTE FUNCTION protect_job_notes();
