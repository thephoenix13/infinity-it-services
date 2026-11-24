-- ============================================================
-- 003_branches.sql
-- Branches within an organization
-- ============================================================

CREATE TABLE branches (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id           uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  name             text NOT NULL,
  address          text,
  phone            text,
  job_prefix       text NOT NULL,   -- e.g. "KTH", "WAK" — used in job numbers
  -- business_hours: { mon: { open: "09:00", close: "19:00", closed: false }, ... }
  business_hours   jsonb NOT NULL DEFAULT '{
    "mon": { "open": "09:00", "close": "19:00", "closed": false },
    "tue": { "open": "09:00", "close": "19:00", "closed": false },
    "wed": { "open": "09:00", "close": "19:00", "closed": false },
    "thu": { "open": "09:00", "close": "19:00", "closed": false },
    "fri": { "open": "09:00", "close": "19:00", "closed": false },
    "sat": { "open": "09:00", "close": "17:00", "closed": false },
    "sun": { "open": "09:00", "close": "17:00", "closed": true  }
  }',
  is_active        boolean NOT NULL DEFAULT true,
  created_at       timestamptz NOT NULL DEFAULT now(),
  updated_at       timestamptz NOT NULL DEFAULT now(),
  -- job_prefix must be unique within an org
  CONSTRAINT unique_prefix_per_org UNIQUE (org_id, job_prefix)
);

CREATE TRIGGER branches_updated_at
  BEFORE UPDATE ON branches
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- Sequence table for job number generation (one row per branch per year)
CREATE TABLE job_number_sequences (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  branch_id   uuid NOT NULL REFERENCES branches(id) ON DELETE CASCADE,
  org_id      uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  year        int NOT NULL,
  last_seq    int NOT NULL DEFAULT 0,
  CONSTRAINT unique_branch_year UNIQUE (branch_id, year)
);

CREATE INDEX idx_branches_org_id ON branches(org_id);
