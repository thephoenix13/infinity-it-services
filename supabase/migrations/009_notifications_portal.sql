-- ============================================================
-- 009_notifications_portal.sql
-- Notification delivery log + customer portal tokens
-- ============================================================

-- Every WhatsApp/SMS send attempt is logged here.
-- Used for: retry UI in job panel, delivery analytics, debugging.
CREATE TABLE notifications_log (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  job_id        uuid NOT NULL REFERENCES jobs(id) ON DELETE CASCADE,
  org_id        uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  trigger_name  text NOT NULL,              -- e.g. 'job_created', 'ready'
  channel       notification_channel NOT NULL,
  recipient     text NOT NULL,              -- phone number
  message_body  text NOT NULL,              -- the actual message sent (after placeholder substitution)
  status        notification_status NOT NULL DEFAULT 'pending',
  provider_ref  text,                       -- provider's message ID for delivery tracking
  error_message text,
  sent_at       timestamptz,
  created_at    timestamptz NOT NULL DEFAULT now()
);

-- Customer portal access tokens.
-- One token per job, created at job creation.
-- UUID v4 — not guessable, not sequential.
-- Token never expires in v1 (expires_at = null).
CREATE TABLE portal_tokens (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  job_id      uuid NOT NULL REFERENCES jobs(id) ON DELETE CASCADE,
  org_id      uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  token       uuid NOT NULL UNIQUE DEFAULT gen_random_uuid(),
  expires_at  timestamptz,   -- null = never expires
  created_at  timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT one_token_per_job UNIQUE (job_id)
);

-- Indexes
CREATE INDEX idx_notifications_job_id  ON notifications_log(job_id);
CREATE INDEX idx_notifications_org_id  ON notifications_log(org_id, created_at DESC);
CREATE INDEX idx_notifications_status  ON notifications_log(status) WHERE status = 'failed';
CREATE INDEX idx_portal_tokens_token   ON portal_tokens(token);
CREATE INDEX idx_portal_tokens_job_id  ON portal_tokens(job_id);
