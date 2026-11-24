-- ============================================================
-- 005_customers_assets.sql
-- Customers and their assets (vertical-agnostic)
-- ============================================================

CREATE TABLE customers (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id      uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  full_name   text NOT NULL,
  phone       text NOT NULL,
  email       text,
  -- outstanding_balance is a computed view, not stored here.
  -- total_jobs and last_service_date are computed at query time.
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now(),
  -- phone is unique per org (not globally)
  CONSTRAINT unique_phone_per_org UNIQUE (org_id, phone)
);

CREATE TRIGGER customers_updated_at
  BEFORE UPDATE ON customers
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- Assets: the physical item being serviced.
-- field_values stores whatever fields the org configured in org_settings.asset.fields.
-- Example for laptop repair: { "brand": "Dell", "model": "Inspiron 15", "serial": "DL2024819" }
-- Example for bike service:  { "brand": "Honda", "model": "Activa 6G", "registration": "MH12AB1234", "year": "2022" }
-- The schema is fully flexible — no vertical-specific columns.
CREATE TABLE assets (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id        uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  customer_id   uuid NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
  -- primary_identifier: the value of the field marked is_primary_identifier in org config.
  -- Stored flat for efficient indexing and display (e.g. serial number, IMEI, reg. number).
  primary_identifier  text,
  field_values  jsonb NOT NULL DEFAULT '{}',
  created_at    timestamptz NOT NULL DEFAULT now(),
  updated_at    timestamptz NOT NULL DEFAULT now()
);

CREATE TRIGGER assets_updated_at
  BEFORE UPDATE ON assets
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- Indexes
CREATE INDEX idx_customers_org_id    ON customers(org_id);
CREATE INDEX idx_customers_phone     ON customers(org_id, phone);
CREATE INDEX idx_assets_org_id       ON assets(org_id);
CREATE INDEX idx_assets_customer_id  ON assets(customer_id);
CREATE INDEX idx_assets_identifier   ON assets(org_id, primary_identifier);
-- GIN index for JSONB field_values queries (e.g. searching by IMEI or serial)
CREATE INDEX idx_assets_field_values ON assets USING gin(field_values);
