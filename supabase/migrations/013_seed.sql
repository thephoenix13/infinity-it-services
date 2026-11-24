-- ============================================================
-- 013_seed.sql
-- Demo data for development and testing.
-- Represents Infinity IT Services (laptop repair, pilot org).
-- Run ONLY in development — never in production.
-- ============================================================

-- NOTE: auth.users entries must be created via Supabase Auth API
-- (dashboard or CLI) before running this seed.
-- Replace the UUIDs below with the actual auth.users IDs after creation.
-- Default password for all seed users: ServiceDesk@2026

-- Placeholder UUIDs — replace before running
DO $$
DECLARE
  -- Auth user IDs (replace with real auth.users IDs)
  uid_admin     uuid := '00000000-0000-0000-0000-000000000001';
  uid_manager   uuid := '00000000-0000-0000-0000-000000000002';
  uid_tech1     uuid := '00000000-0000-0000-0000-000000000003';
  uid_tech2     uuid := '00000000-0000-0000-0000-000000000004';
  uid_frontdesk uuid := '00000000-0000-0000-0000-000000000005';

  -- Org and branch IDs
  v_org_id      uuid;
  v_branch_kth  uuid;  -- Kothrud
  v_branch_wak  uuid;  -- Wakad

  -- Customer IDs
  v_cust1 uuid; v_cust2 uuid; v_cust3 uuid;
  -- Asset IDs
  v_asset1 uuid; v_asset2 uuid; v_asset3 uuid;
  -- Job IDs
  v_job1 uuid; v_job2 uuid; v_job3 uuid;

BEGIN

-- ============================================================
-- Organization
-- ============================================================
INSERT INTO organizations (id, name, slug)
VALUES (gen_random_uuid(), 'Infinity IT Services', 'infinity-it')
RETURNING id INTO v_org_id;

-- Org settings — laptop repair vertical with full config
UPDATE org_settings SET settings = '{
  "branding": {
    "logo_url": null,
    "primary_color": "#0f1f3d",
    "app_name": "Infinity ServiceDesk"
  },
  "contact": {
    "phone": "9876543210",
    "email": "service@infinityit.in",
    "address": "Pune, Maharashtra"
  },
  "vertical": "laptop_repair",
  "asset": {
    "label": "device",
    "label_plural": "devices",
    "fields": [
      { "key": "brand",  "label": "Brand",         "type": "select", "required": true,  "is_primary_identifier": false, "options": ["Dell","HP","Lenovo","Asus","Acer","Apple","MSI","Samsung","Other"] },
      { "key": "model",  "label": "Model",          "type": "text",   "required": false, "is_primary_identifier": false },
      { "key": "serial", "label": "Serial Number",  "type": "text",   "required": false, "is_primary_identifier": true  }
    ]
  },
  "issue_categories": ["Screen / Display","Battery","Keyboard","Charging Port","Motherboard","Storage (HDD/SSD)","RAM","Hinge / Physical Damage","Software / OS","Overheating","Other"],
  "accessories": ["Charger","Laptop Bag","Mouse","External HDD","USB Dongle","Other"],
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
  "payment_modes": ["cash","upi","card"],
  "overdue_threshold_hours": 1,
  "notification_triggers": {
    "job_created":   { "enabled": true,  "channels": ["whatsapp"] },
    "estimate_sent": { "enabled": true,  "channels": ["whatsapp"] },
    "approved":      { "enabled": false, "channels": ["whatsapp"] },
    "in_service":    { "enabled": true,  "channels": ["whatsapp"] },
    "parts":         { "enabled": true,  "channels": ["whatsapp"] },
    "ready":         { "enabled": true,  "channels": ["whatsapp","sms"] },
    "delivered":     { "enabled": true,  "channels": ["whatsapp"] }
  },
  "notification_templates": {
    "job_created":   "Hi {{customer_name}}, your {{asset_label}} has been received at our {{branch_name}} branch. Job ID: {{job_id}}. — Infinity IT Services",
    "estimate_sent": "Hi {{customer_name}}, inspection of your {{asset_label}} ({{job_id}}) is complete. Estimated cost: ₹{{estimate_amount}}. Approve here: {{portal_url}} — Infinity IT Services",
    "in_service":    "Hi {{customer_name}}, our technician has started working on your {{asset_label}} ({{job_id}}). We will notify you when it is ready. — Infinity IT Services",
    "parts":         "Hi {{customer_name}}, we are waiting for parts for your {{asset_label}} ({{job_id}}). We will update you once they arrive. — Infinity IT Services",
    "ready":         "Great news, {{customer_name}}! Your {{asset_label}} is ready for pickup at our {{branch_name}} branch. Amount due: ₹{{amount_due}}. Job ID: {{job_id}}. — Infinity IT Services",
    "delivered":     "Your {{asset_label}} has been delivered. Thank you for choosing Infinity IT Services. Quote Job ID {{job_id}} for warranty queries."
  },
  "integrations": {
    "whatsapp_provider": null,
    "whatsapp_api_key":  null,
    "sms_provider":      null,
    "sms_api_key":       null
  },
  "setup_progress": {
    "vertical": true, "brand": true, "contact": true,
    "branches": true, "staff": true, "notifications": false
  },
  "is_live": true
}'
WHERE org_id = v_org_id;

-- ============================================================
-- Branches
-- ============================================================
INSERT INTO branches (id, org_id, name, address, phone, job_prefix)
VALUES (gen_random_uuid(), v_org_id, 'Kothrud', 'Kothrud, Pune - 411038', '9876543210', 'KTH')
RETURNING id INTO v_branch_kth;

INSERT INTO branches (id, org_id, name, address, phone, job_prefix)
VALUES (gen_random_uuid(), v_org_id, 'Wakad', 'Wakad, Pune - 411057', '9876543211', 'WAK')
RETURNING id INTO v_branch_wak;

-- ============================================================
-- Users (assumes auth.users already created with these IDs)
-- ============================================================
INSERT INTO users (id, org_id, full_name, role, branch_ids) VALUES
  (uid_admin,     v_org_id, 'Rajesh Kumar',   'admin',      '{}'),
  (uid_manager,   v_org_id, 'Priya Sharma',   'manager',    ARRAY[v_branch_kth]),
  (uid_tech1,     v_org_id, 'Suresh Patil',   'technician', ARRAY[v_branch_kth]),
  (uid_tech2,     v_org_id, 'Amit Deshpande', 'technician', ARRAY[v_branch_wak]),
  (uid_frontdesk, v_org_id, 'Sneha More',     'front_desk', ARRAY[v_branch_kth]);

-- ============================================================
-- Customers
-- ============================================================
INSERT INTO customers (id, org_id, full_name, phone, email)
VALUES (gen_random_uuid(), v_org_id, 'Ramesh Patil',    '9876543220', 'ramesh@email.com') RETURNING id INTO v_cust1;
INSERT INTO customers (id, org_id, full_name, phone, email)
VALUES (gen_random_uuid(), v_org_id, 'Sunita Deshmukh', '9823456781', null) RETURNING id INTO v_cust2;
INSERT INTO customers (id, org_id, full_name, phone, email)
VALUES (gen_random_uuid(), v_org_id, 'Arjun Mehta',     '9011223344', 'arjun@email.com') RETURNING id INTO v_cust3;

-- ============================================================
-- Assets
-- ============================================================
INSERT INTO assets (id, org_id, customer_id, primary_identifier, field_values)
VALUES (gen_random_uuid(), v_org_id, v_cust1, 'DL2024819',
  '{"brand":"Dell","model":"Inspiron 15 3520","serial":"DL2024819"}') RETURNING id INTO v_asset1;

INSERT INTO assets (id, org_id, customer_id, primary_identifier, field_values)
VALUES (gen_random_uuid(), v_org_id, v_cust2, 'HP2023441',
  '{"brand":"HP","model":"Pavilion x360","serial":"HP2023441"}') RETURNING id INTO v_asset2;

INSERT INTO assets (id, org_id, customer_id, primary_identifier, field_values)
VALUES (gen_random_uuid(), v_org_id, v_cust3, 'LN20231102',
  '{"brand":"Lenovo","model":"ThinkPad E14","serial":"LN20231102"}') RETURNING id INTO v_asset3;

-- ============================================================
-- Jobs (created via direct insert — triggers will auto-generate
-- job numbers and portal tokens)
-- ============================================================
INSERT INTO jobs (id, org_id, branch_id, customer_id, asset_id, assigned_tech_id, created_by,
  status, issue_category, issue_description, accessories_received, estimated_delivery, estimate_total, advance_payment)
VALUES (
  gen_random_uuid(), v_org_id, v_branch_kth, v_cust1, v_asset1, uid_tech1, uid_frontdesk,
  'in_service', 'Screen / Display', 'Screen flickering above 90 degrees',
  ARRAY['Charger'], '2026-08-12', 3500, 500
) RETURNING id INTO v_job1;

INSERT INTO jobs (id, org_id, branch_id, customer_id, asset_id, assigned_tech_id, created_by,
  status, issue_category, issue_description, accessories_received, estimated_delivery, estimate_total, advance_payment)
VALUES (
  gen_random_uuid(), v_org_id, v_branch_kth, v_cust2, v_asset2, uid_tech1, uid_frontdesk,
  'ready', 'Battery', 'Battery draining in under 1 hour',
  ARRAY['Charger','Laptop Bag'], '2026-08-10', 2800, 0
) RETURNING id INTO v_job2;

INSERT INTO jobs (id, org_id, branch_id, customer_id, asset_id, assigned_tech_id, created_by,
  status, issue_category, issue_description, accessories_received, estimated_delivery, estimate_total, advance_payment)
VALUES (
  gen_random_uuid(), v_org_id, v_branch_wak, v_cust3, v_asset3, uid_tech2, uid_frontdesk,
  'parts', 'Keyboard', 'Keyboard dead after water spill',
  '{}', '2026-08-14', 4200, 1000
) RETURNING id INTO v_job3;

-- Parts for job1
INSERT INTO job_parts (job_id, org_id, item_name, unit_cost, quantity, is_labour, created_by) VALUES
  (v_job1, v_org_id, 'Laptop Screen (15.6" FHD)', 2800, 1, false, uid_tech1),
  (v_job1, v_org_id, 'Screen Replacement Labour',  700, 1, true,  uid_tech1);

-- Parts for job2 (battery replaced — job is ready)
INSERT INTO job_parts (job_id, org_id, item_name, unit_cost, quantity, is_labour, created_by) VALUES
  (v_job2, v_org_id, 'Replacement Battery (HP Pavilion)', 2200, 1, false, uid_tech1),
  (v_job2, v_org_id, 'Battery Replacement Labour',         600, 1, true,  uid_tech1);

-- Parts for job3 (awaiting parts)
INSERT INTO job_parts (job_id, org_id, item_name, unit_cost, quantity, is_labour, created_by) VALUES
  (v_job3, v_org_id, 'Keyboard (Lenovo ThinkPad E14)', 3500, 1, false, uid_tech2),
  (v_job3, v_org_id, 'Keyboard Replacement Labour',     700, 1, true,  uid_tech2);

-- Generate invoice for job2 (it's ready for pickup)
PERFORM generate_invoice(v_job2, uid_tech1);

-- Notes
INSERT INTO job_notes (job_id, org_id, note, created_by) VALUES
  (v_job1, v_org_id, 'Hinges slightly loose — checked ribbon cable, replacing screen.', uid_tech1),
  (v_job3, v_org_id, 'Corrosion on lower PCB. Ordered keyboard — ETA 2 days.', uid_tech2);

END;
$$;
