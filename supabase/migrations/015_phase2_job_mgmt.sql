-- ============================================================
-- 015_phase2_job_mgmt.sql
-- Phase 2: Job Management Completeness
-- - Index for overdue jobs query
-- - customer_outstanding_balance view helper
-- ============================================================

-- Fast overdue lookup: jobs where estimated_delivery < today, status not terminal
CREATE INDEX IF NOT EXISTS idx_jobs_overdue
  ON jobs(org_id, estimated_delivery)
  WHERE status NOT IN ('ready', 'delivered');

-- View: outstanding balance per customer across all their jobs
-- Used at intake to warn staff about unpaid invoices
CREATE OR REPLACE VIEW customer_outstanding AS
SELECT
  j.customer_id,
  j.org_id,
  SUM(jps.outstanding_balance) AS total_outstanding,
  STRING_AGG(j.job_number, ', ' ORDER BY j.created_at DESC) FILTER (WHERE jps.outstanding_balance > 0) AS unpaid_job_numbers
FROM jobs j
JOIN job_payment_summary jps ON jps.job_id = j.id
WHERE jps.outstanding_balance > 0
  AND j.status != 'received'   -- exclude jobs not yet invoiced
GROUP BY j.customer_id, j.org_id;
