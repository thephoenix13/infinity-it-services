-- ============================================================
-- 002_organizations.sql
-- Tenant root + org configuration
-- ============================================================

CREATE TABLE organizations (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name        text NOT NULL,
  slug        text NOT NULL UNIQUE,  -- used in URLs: app.servicedesk.in/[slug]
  is_active   boolean NOT NULL DEFAULT true,
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now()
);

-- Full org config stored as JSONB. Shape is enforced at the app layer.
-- See PRD Section 7 for the complete structure.
CREATE TABLE org_settings (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id     uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  settings   jsonb NOT NULL DEFAULT '{
    "branding": {
      "logo_url": null,
      "primary_color": "#1a56db",
      "app_name": "ServiceDesk"
    },
    "contact": {
      "phone": null,
      "email": null,
      "address": null
    },
    "vertical": null,
    "asset": {
      "label": "item",
      "label_plural": "items",
      "fields": []
    },
    "issue_categories": [],
    "accessories": [],
    "status_labels": {
      "received":      "Received",
      "inspection":    "Inspection",
      "estimate_sent": "Estimate Sent",
      "approved":      "Approved",
      "parts":         "Awaiting Parts",
      "in_service":    "In Service",
      "ready":         "Ready for Pickup",
      "delivered":     "Delivered"
    },
    "payment_modes": ["cash", "upi", "card"],
    "overdue_threshold_hours": 1,
    "notification_triggers": {
      "job_created":   { "enabled": true,  "channels": ["whatsapp"] },
      "estimate_sent": { "enabled": true,  "channels": ["whatsapp"] },
      "approved":      { "enabled": false, "channels": ["whatsapp"] },
      "in_service":    { "enabled": true,  "channels": ["whatsapp"] },
      "parts":         { "enabled": true,  "channels": ["whatsapp"] },
      "ready":         { "enabled": true,  "channels": ["whatsapp", "sms"] },
      "delivered":     { "enabled": true,  "channels": ["whatsapp"] }
    },
    "notification_templates": {
      "job_created":   "Hi {{customer_name}}, your {{asset_label}} has been received at our {{branch_name}} branch. Job ID: {{job_id}}. — {{org_name}}",
      "estimate_sent": "Hi {{customer_name}}, inspection of your {{asset_label}} ({{job_id}}) is complete. Estimated cost: ₹{{estimate_amount}}. Approve here: {{portal_url}} — {{org_name}}",
      "approved":      "Hi {{customer_name}}, we have received your approval for Job ID: {{job_id}}. We will begin work shortly. — {{org_name}}",
      "in_service":    "Hi {{customer_name}}, our technician has started working on your {{asset_label}} ({{job_id}}). We will notify you when it is ready. — {{org_name}}",
      "parts":         "Hi {{customer_name}}, we are waiting for parts for your {{asset_label}} ({{job_id}}). We will update you once they arrive. — {{org_name}}",
      "ready":         "Great news, {{customer_name}}! Your {{asset_label}} is ready for pickup at our {{branch_name}} branch. Amount due: ₹{{amount_due}}. Job ID: {{job_id}}. — {{org_name}}",
      "delivered":     "Your {{asset_label}} has been delivered. Thank you for choosing {{org_name}}. Quote Job ID {{job_id}} for any warranty queries."
    },
    "integrations": {
      "whatsapp_provider": null,
      "whatsapp_api_key":  null,
      "sms_provider":      null,
      "sms_api_key":       null
    },
    "setup_progress": {
      "vertical":      false,
      "brand":         false,
      "contact":       false,
      "branches":      false,
      "staff":         false,
      "notifications": false
    },
    "is_live": false
  }',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT one_settings_per_org UNIQUE (org_id)
);

-- Trigger: keep updated_at current on organizations
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

CREATE TRIGGER organizations_updated_at
  BEFORE UPDATE ON organizations
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER org_settings_updated_at
  BEFORE UPDATE ON org_settings
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- Index: slug lookups on login
CREATE INDEX idx_organizations_slug ON organizations(slug);
