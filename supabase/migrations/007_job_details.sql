-- ============================================================
-- 007_job_details.sql
-- Parts, photos, and internal notes against a job
-- ============================================================

-- Parts and labour line items from the inspection estimate.
-- is_labour = true for labour charges, false for parts/components.
CREATE TABLE job_parts (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  job_id        uuid NOT NULL REFERENCES jobs(id) ON DELETE CASCADE,
  org_id        uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  item_name     text NOT NULL,
  description   text,
  unit_cost     numeric(10,2) NOT NULL DEFAULT 0,
  quantity      int NOT NULL DEFAULT 1,
  is_labour     boolean NOT NULL DEFAULT false,
  -- actual_quantity: updated post-service if actual differs from estimate
  actual_quantity int,
  created_by    uuid NOT NULL REFERENCES users(id),
  created_at    timestamptz NOT NULL DEFAULT now(),
  updated_at    timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT positive_unit_cost CHECK (unit_cost >= 0),
  CONSTRAINT positive_quantity  CHECK (quantity > 0)
);

CREATE TRIGGER job_parts_updated_at
  BEFORE UPDATE ON job_parts
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- Photos uploaded during inspection or after service completion.
CREATE TABLE job_photos (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  job_id        uuid NOT NULL REFERENCES jobs(id) ON DELETE CASCADE,
  org_id        uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  storage_path  text NOT NULL,   -- Supabase Storage path (used to generate signed URL)
  photo_type    photo_type NOT NULL,
  caption       text,
  uploaded_by   uuid NOT NULL REFERENCES users(id),
  created_at    timestamptz NOT NULL DEFAULT now()
);

-- Internal staff notes — not visible to customers.
CREATE TABLE job_notes (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  job_id      uuid NOT NULL REFERENCES jobs(id) ON DELETE CASCADE,
  org_id      uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  note        text NOT NULL,
  created_by  uuid NOT NULL REFERENCES users(id),
  created_at  timestamptz NOT NULL DEFAULT now()
  -- Notes are never updated or deleted — immutable by design
);

-- Indexes
CREATE INDEX idx_job_parts_job_id   ON job_parts(job_id);
CREATE INDEX idx_job_photos_job_id  ON job_photos(job_id);
CREATE INDEX idx_job_notes_job_id   ON job_notes(job_id);
