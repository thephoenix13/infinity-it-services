-- ============================================================
-- 006_jobs.sql
-- Core job entity + immutable status audit log
-- ============================================================

CREATE TABLE jobs (
  id                    uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id                uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  branch_id             uuid NOT NULL REFERENCES branches(id),
  customer_id           uuid NOT NULL REFERENCES customers(id),
  asset_id              uuid NOT NULL REFERENCES assets(id),
  assigned_tech_id      uuid REFERENCES users(id) ON DELETE SET NULL,
  created_by            uuid NOT NULL REFERENCES users(id),

  -- Auto-generated: {PREFIX}-{YYYY}-{MM}-{000001}
  -- Set by trigger on INSERT via generate_job_number()
  job_number            text UNIQUE,

  status                job_status NOT NULL DEFAULT 'received',

  issue_category        text NOT NULL,
  issue_description     text,

  -- accessories_received: array of checklist item labels that were ticked at intake
  accessories_received  text[] NOT NULL DEFAULT '{}',

  estimated_delivery    date NOT NULL,
  -- parts_arrival_date: set when status = 'parts', used for overdue calculation during wait
  parts_arrival_date    date,

  -- Estimate total — set when inspection is submitted
  estimate_total        numeric(10,2),
  -- Whether customer approved via portal (true) or staff recorded verbally (false)
  approved_via_portal   boolean,

  -- Advance payment recorded at intake
  advance_payment       numeric(10,2) NOT NULL DEFAULT 0,

  -- Portal token is stored on portal_tokens table; this is a convenience FK
  -- populated by trigger so the app can get the URL without a join
  portal_token          uuid,

  created_at            timestamptz NOT NULL DEFAULT now(),
  updated_at            timestamptz NOT NULL DEFAULT now()
);

CREATE TRIGGER jobs_updated_at
  BEFORE UPDATE ON jobs
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ============================================================
-- Job status log — IMMUTABLE audit trail
-- No UPDATE or DELETE ever touches this table.
-- Every status transition writes one row here.
-- ============================================================

CREATE TABLE job_status_log (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  job_id        uuid NOT NULL REFERENCES jobs(id) ON DELETE CASCADE,
  org_id        uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  from_status   job_status,         -- null on first entry (job created)
  to_status     job_status NOT NULL,
  changed_by    uuid NOT NULL REFERENCES users(id),
  notes         text,               -- optional context (e.g. "Customer approved verbally")
  changed_at    timestamptz NOT NULL DEFAULT now()
);

-- Indexes
CREATE INDEX idx_jobs_org_id          ON jobs(org_id);
CREATE INDEX idx_jobs_branch_id       ON jobs(branch_id);
CREATE INDEX idx_jobs_customer_id     ON jobs(customer_id);
CREATE INDEX idx_jobs_assigned_tech   ON jobs(assigned_tech_id);
CREATE INDEX idx_jobs_status          ON jobs(org_id, status);
CREATE INDEX idx_jobs_created_at      ON jobs(org_id, created_at DESC);
CREATE INDEX idx_jobs_estimated_del   ON jobs(org_id, estimated_delivery);
CREATE INDEX idx_job_status_log_job   ON job_status_log(job_id);
CREATE INDEX idx_job_status_log_org   ON job_status_log(org_id, changed_at DESC);
