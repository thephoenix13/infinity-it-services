-- ============================================================
-- 008_invoices_payments.sql
-- Invoices generated from job_parts + payment transactions
-- ============================================================

-- One invoice per job. Generated when job moves to 'ready'.
-- Snapshot of parts + labour at the time of generation.
CREATE TABLE invoices (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  job_id          uuid NOT NULL REFERENCES jobs(id) ON DELETE CASCADE,
  org_id          uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  -- Snapshot totals (calculated from job_parts at generation time)
  parts_total     numeric(10,2) NOT NULL DEFAULT 0,
  labour_total    numeric(10,2) NOT NULL DEFAULT 0,
  subtotal        numeric(10,2) NOT NULL DEFAULT 0,
  -- tax_amount: reserved for future GST support, 0 for v1
  tax_amount      numeric(10,2) NOT NULL DEFAULT 0,
  total           numeric(10,2) NOT NULL DEFAULT 0,
  generated_by    uuid NOT NULL REFERENCES users(id),
  generated_at    timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT one_invoice_per_job UNIQUE (job_id)
);

-- Payment transactions against a job.
-- Supports multiple partial payments; balance = invoice.total - SUM(payments.amount).
CREATE TABLE payments (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  job_id        uuid NOT NULL REFERENCES jobs(id) ON DELETE CASCADE,
  org_id        uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  invoice_id    uuid REFERENCES invoices(id) ON DELETE SET NULL,
  amount        numeric(10,2) NOT NULL,
  mode          payment_mode NOT NULL,
  reference     text,           -- UPI transaction ID, card last 4, NEFT ref, etc.
  notes         text,
  recorded_by   uuid NOT NULL REFERENCES users(id),
  created_at    timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT positive_amount CHECK (amount > 0)
);

-- View: outstanding balance per job
-- Used in: job detail panel, customer profile, intake repeat-customer check
CREATE OR REPLACE VIEW job_payment_summary AS
SELECT
  j.id                                            AS job_id,
  j.org_id,
  j.branch_id,
  COALESCE(i.total, j.estimate_total, 0)          AS invoice_total,
  COALESCE(SUM(p.amount), 0) + j.advance_payment  AS total_paid,
  GREATEST(
    COALESCE(i.total, j.estimate_total, 0)
    - COALESCE(SUM(p.amount), 0)
    - j.advance_payment,
    0
  )                                               AS outstanding_balance,
  i.id IS NOT NULL                                AS invoice_generated
FROM jobs j
LEFT JOIN invoices i ON i.job_id = j.id
LEFT JOIN payments p ON p.job_id = j.id
GROUP BY j.id, j.org_id, j.branch_id, j.estimate_total, j.advance_payment, i.id, i.total;

-- Indexes
CREATE INDEX idx_invoices_job_id   ON invoices(job_id);
CREATE INDEX idx_invoices_org_id   ON invoices(org_id);
CREATE INDEX idx_payments_job_id   ON payments(job_id);
CREATE INDEX idx_payments_org_id   ON payments(org_id, created_at DESC);
