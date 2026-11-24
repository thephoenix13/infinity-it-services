# ServiceDesk — Product Requirements Document

**Version:** 1.1  
**Date:** August 2026  
**Status:** Approved for development  
**Pilot customer:** Infinity IT Services, Pune (7 branches, laptop repair)  
**Change from v1.0:** Platform redesigned as vertical-agnostic. Any repair/service business can onboard. Laptop repair is the pilot vertical, not the product definition.

---

## 1. Product Vision

> **ServiceDesk is the operating system for any business that receives a physical item, services it, and returns it** — a multi-tenant platform that replaces spreadsheets, WhatsApp threads, and tribal knowledge with a single source of truth across every branch, every technician, and every customer interaction.

Any repair or service business — laptop repair, mobile repair, AC servicing, bike service, CCTV maintenance, medical equipment, generators, watches — should be able to sign up, configure their org in under an hour, and run their entire operation from customer intake to invoice, without custom development.

The workflow is universal: **receive → inspect → estimate → approve → service → pay → return.** The platform is configured, not customised, for each vertical.

### The Problem We're Solving

Multi-branch repair and service businesses at the 3–15 branch scale are operationally blind. Jobs live in Excel. Customer updates happen over personal WhatsApp. Branch managers call each other to find out what's open. Head office compiles reports manually at end of month. There is no audit trail, no visibility, and no accountability.

This pattern holds across every service vertical — laptop repair, phone repair, appliance service, vehicle workshops. The operational problem is identical. The platform solves it once for all of them.

### Target Verticals

| Vertical | Item serviced | Example customers |
|---|---|---|
| Laptop / PC repair | Laptop, desktop | Infinity IT Services (pilot) |
| Mobile phone repair | Smartphone, tablet | Phone repair chains |
| AC / appliance service | AC unit, washing machine, refrigerator | Authorised service centres |
| Two-wheeler service | Scooter, motorcycle | Workshop chains |
| CCTV / security systems | Camera, DVR, access control | Security integrators |
| Generator / UPS | Generator, inverter, UPS | Industrial service cos. |
| Medical equipment | Diagnostic devices, hospital equipment | Biomedical companies |
| Watch / jewellery | Timepiece, jewellery | Premium repair boutiques |

### The Outcome We're Building Toward

- A front desk person can intake a job in under 2 minutes regardless of what's being serviced
- A technician can update job status and upload photos from their phone without training
- A customer never has to call to ask "what's the status of my item"
- A branch manager can see the live state of every open job at 8am without asking anyone
- Head office can compare branch performance without a single Excel sheet
- A new vertical can be supported by changing configuration — not code

---

## 2. Target Users (Personas)

### 2.1 Org Admin — "The Owner"
**Who:** Business owner or operations head. Has visibility across all branches. Vertical agnostic — could run a laptop repair chain or an AC service network.  
**Goal:** Know what's happening across the business without being on calls all day.  
**Frustration:** Gets status updates only when things go wrong. No data to make staffing or capacity decisions.  
**Jobs to be done:**
- See open jobs, revenue, and overdue counts across all branches at a glance
- Identify which branch or technician is underperforming
- Set up and configure the platform for their org — including their specific item types, categories, and terminology — without needing IT help

### 2.2 Branch Manager — "The Operator"
**Who:** Manages one branch, 3–8 staff. Accountable for that branch's numbers. Works in whatever vertical their business is in.  
**Goal:** Keep jobs moving, nothing slips through the cracks.  
**Frustration:** Has to chase technicians for updates. Doesn't know a job is overdue until the customer calls.  
**Jobs to be done:**
- See all open jobs at their branch and their current status in one view
- Reassign jobs when a technician is overloaded or absent
- Know which jobs are at risk (overdue, awaiting parts too long) before they become a problem

### 2.3 Front Desk — "The Gatekeeper"
**Who:** First contact when a customer walks in. Not technical. May be working at a laptop repair shop today and an AC service centre tomorrow — the interface should feel purpose-built for their business.  
**Goal:** Get the customer in and out quickly, accurately.  
**Frustration:** Has to ask colleagues for the job sheet number. Fills the same customer details in every time. Manually sends WhatsApp updates.  
**Jobs to be done:**
- Create a job sheet fast, without forgetting anything (item details, accessories, issue)
- Find a returning customer instantly by phone number
- Record payment and close the job when the item is picked up
- Never have to send a status update manually — it just happens

### 2.4 Technician — "The Doer"
**Who:** Hands-on engineer or service person. Works from a workbench, workshop floor, or field site. Not always at a desk. Could be a laptop technician, an AC mechanic, or a CCTV installer.  
**Goal:** Know what to work on, document the work, move on.  
**Frustration:** Unclear priorities. Paper job sheets get lost. Has to walk to a desk to update status.  
**Jobs to be done:**
- See their personal job queue sorted by priority
- Update job status from their phone, wherever they are
- Fill the inspection form and upload photos without friction
- Know when new jobs are assigned to them without checking a board

### 2.5 Customer — "The Recipient"
**Who:** End user whose item is in for service. No knowledge of the repair process. Could have left a laptop, a scooter, an AC unit, or a medical device.  
**Goal:** Know their item is being looked after and when they can collect it.  
**Frustration:** Has to call the service centre to find out anything. Doesn't know what they're being charged for until pickup.  
**Jobs to be done:**
- Know the job was received and is being tracked (not lost)
- See the repair estimate with a breakdown before approving it
- Know when the item is ready without calling
- Approve the estimate without having to go to the shop

---

## 3. Design Principles

These principles govern every product decision — feature scope, interaction design, and information hierarchy.

### 3.1 Enforce, Don't Trust
The system enforces business rules at the data layer, not through UI reminders. Delivery is locked until payment is recorded. "In Service" requires approval. This makes the system reliable, not aspirational.

### 3.2 The Floor Has No Desk
Technicians update jobs from the floor on a phone. Every technician-facing interaction must work on a 390px wide screen, one-handed, without a keyboard. If it requires typing more than a status update, it's the wrong design.

### 3.3 Front Desk Speed Over Comprehensiveness
A customer is standing at the counter. Intake should take 90 seconds. Don't surface everything — surface the required fields first, optionals collapsed. Returning customer detection by phone number must happen before they finish entering the number.

### 3.4 Silence Is a Feature for Customers
Customers get notified at the right moments automatically. They should never need to call. The notification content should answer the questions they would have asked: where is it, what will it cost, when is it ready, how much do I owe.

### 3.5 Multi-Tenant, Single Codebase
Every org runs on the same code. Org-specific behaviour is driven by configuration, not branching logic. If a feature requires an `if (org_id === 'x')` check in application code, the feature is designed wrong.

### 3.6 Config Over Code for Orgs
An org admin configuring their account should never need to contact support. The onboarding wizard and settings panel should cover everything they need to go live. New orgs should require zero platform-owner intervention.

### 3.7 Vertical-Neutral Terminology in Code, Vertical-Fluent in UI
The codebase uses neutral terms (`asset`, `asset_fields`, `item`). The UI renders whatever the org has configured (`device`, `vehicle`, `appliance`, `instrument`, `unit`). No hardcoded vertical language anywhere in the application layer. A laptop repair org sees "device". A bike workshop sees "vehicle". Same code, same component, different config.

---

## 4. Functional Requirements

### 4.1 Authentication & Multi-Tenancy

**FR-AUTH-01:** Users authenticate with email + password via Supabase Auth.  
**FR-AUTH-02:** On login, the system loads the user's org context (org_id, role, branch assignments) and stores it in a React context provider accessible to the entire app.  
**FR-AUTH-03:** All database queries are automatically scoped to the authenticated user's org_id via Row-Level Security — no application-layer org filtering required.  
**FR-AUTH-04:** A user can belong to one org only. Cross-org access does not exist.  
**FR-AUTH-05:** Branch-scoped roles (Manager, Front Desk, Technician) can only access data from their assigned branch(es). Admin sees all branches in their org.  
**FR-AUTH-06:** Session tokens expire after 8 hours. Users are redirected to login on expiry.  
**FR-AUTH-07:** Password reset via email is supported.

### 4.2 Org Onboarding & Configuration

**FR-ORG-01:** A new org is created via a public signup page. Fields: org name, admin full name, email, password.  
**FR-ORG-02:** After signup, the admin is guided through a 5-step setup wizard before accessing the main app. Steps are persisted — the admin can exit and return.  
**FR-ORG-03:** Setup wizard steps:
  1. Vertical — select service type (from preset list or "Other"); pre-populates smart defaults for steps 2–6
  2. Brand — logo upload, primary colour picker, app display name
  3. Contact — support phone, email, physical address
  4. Branches — add at least one branch (name, address, job sheet prefix, business hours)
  5. Staff — invite staff by email, assign role and branch
  6. Notifications — WhatsApp API key, SMS key, send a test message

**FR-ORG-03a:** Vertical selector (Step 1) options and their pre-populated defaults:

| Vertical | Asset label | Asset fields | Sample categories |
|---|---|---|---|
| Laptop / PC repair | Device | Brand, Model, Serial No. | Screen, Battery, Keyboard, Charging port, Motherboard, Software |
| Mobile phone repair | Device | Brand, Model, IMEI | Screen, Battery, Charging port, Speaker, Camera, Water damage |
| AC / appliance service | Appliance | Brand, Model, Type, Capacity | Gas recharge, Compressor, PCB, Motor, Fan, Cleaning |
| Two-wheeler service | Vehicle | Brand, Model, Registration No., Year | Oil change, Tyres, Brakes, Engine, Electrical, Body work |
| CCTV / security | Unit | Brand, Model, Type, Location | Camera replacement, DVR fault, Cabling, Power supply, Software |
| Generator / UPS | Unit | Brand, Model, KVA rating, Serial No. | Battery, Alternator, Fuel system, Control panel, Wiring |
| Medical equipment | Instrument | Brand, Model, Serial No., Asset tag | Calibration, Sensor, Power unit, Display, Sterilisation |
| Other (custom) | Item | Name, Identifier | (blank — org fills in) |

Selecting a vertical pre-fills categories, asset fields, accessories checklist, and notification template language with sensible defaults. The org can edit all of these in settings.

**FR-ORG-04:** Org settings panel (post-onboarding) allows editing all wizard config plus:
  - **Vertical / asset config:**
    - Asset label (what the item is called: "device", "vehicle", "appliance", "unit", "instrument", "item" — free text, singular)
    - Asset fields (which fields appear at intake for the asset: name, type — text/select/number, required/optional, options if select)
    - Accessories checklist items (add, rename, reorder, deactivate)
  - Issue categories (add, rename, reorder, deactivate)
  - Status labels (rename any status — the pipeline order is fixed)
  - Payment modes (enable/disable: Cash, UPI, Card, NEFT, Other)
  - Notification templates (edit message text per trigger, using placeholders)
  - Overdue threshold (hours after estimated delivery before flagging)

**FR-ORG-05:** Notification template placeholders available:
  `{{customer_name}}`, `{{asset_label}}`, `{{asset_identifier}}`, `{{job_id}}`, `{{branch_name}}`, `{{branch_phone}}`, `{{estimate_amount}}`, `{{amount_due}}`, `{{org_name}}`

  `{{asset_label}}` resolves to whatever the org configured (e.g. "laptop", "AC unit", "scooter"). `{{asset_identifier}}` resolves to the primary identifier field value (e.g. serial number, registration number, IMEI).

**FR-ORG-06:** All org config is stored as structured JSON in `org_settings` and loaded into the React org context at login. UI renders from config — no hardcoded vertical-specific labels anywhere in the application.

### 4.3 Job Intake

**FR-INT-01:** Front Desk and Manager roles can create new jobs.  
**FR-INT-02:** Phone number lookup on the customer phone field — if a matching customer exists in the org, their name and email auto-populate. The field triggers lookup after 10 digits are entered.  
**FR-INT-03:** Required fields: customer name, phone number, all asset fields marked required in org config, issue category, estimated delivery date, branch.  
**FR-INT-04:** Optional fields: email, any asset fields marked optional, issue description (free text), accessories checklist (items from org config), technician assignment, advance payment amount.  
**FR-INT-05:** The asset section of the intake form is rendered dynamically from `org_settings.asset_fields`. Each field definition specifies: label, type (text / select / number), required/optional, and options (if select). The form does not hardcode any asset fields.  
**FR-INT-06:** Job sheet number is auto-generated on save: `{BRANCH_PREFIX}-{YYYY}-{MM}-{6-digit-sequence}`. Sequence resets per branch per year.  
**FR-INT-07:** On job creation, a WhatsApp/SMS notification fires automatically to the customer (using the org's configured "job created" template).  
**FR-INT-08:** Job is created in `Received` status.  
**FR-INT-09:** A printable/shareable job receipt is generated on creation (customer copy). The receipt uses the org's asset label and configured field names — not hardcoded "device" or "serial number".

### 4.4 Inspection & Estimation

**FR-INS-01:** Technician or Manager opens the inspection form against a job in `Received` status.  
**FR-INS-02:** Inspection form fields: parts/components list (item name, description, unit cost, quantity), labour charges (description, amount), damage photos (multi-upload), inspection notes.  
**FR-INS-03:** Total estimate is auto-calculated from parts + labour with line-item breakdown. Technician cannot manually enter a total.  
**FR-INS-04:** Submitting the inspection form moves the job to `Inspection` status.  
**FR-INS-05:** Estimate is shared with the customer via a "Send Estimate" action — fires WhatsApp/SMS with the configured template and a link to the customer portal where they can view the full breakdown.  
**FR-INS-06:** Sending the estimate moves the job to `Estimate Sent` status.  
**FR-INS-07:** Customer approval can be recorded two ways: (a) staff marks it manually ("Customer approved verbally"), (b) customer approves via the self-service portal link.  
**FR-INS-08:** Recording approval moves the job to `Approved` status.  
**FR-INS-09:** A job cannot move to `In Service` or `Awaiting Parts` without being in `Approved` status. This is enforced server-side.

### 4.5 Job & Technician Management

**FR-JOB-01:** Jobs can be assigned to a technician at intake or at any point before completion.  
**FR-JOB-02:** Technicians see only their assigned jobs in their default view.  
**FR-JOB-03:** Internal notes can be added to any job by any staff member. Notes are timestamped and attributed. Notes are not visible to customers.  
**FR-JOB-04:** Parts used log can be updated after inspection — actual quantities used vs estimated.  
**FR-JOB-05:** Post-service photos can be uploaded when marking a job ready — photos of parts fixed, replaced, or modified.  
**FR-JOB-06:** "Awaiting Parts" status requires an expected parts arrival date. This date is used for overdue calculations during the wait period.  
**FR-JOB-07:** Manager can reassign any job at their branch to a different technician.  
**FR-JOB-08:** Admin can reassign or transfer jobs across branches.  
**FR-JOB-09:** Technician workload view shows open job count per technician at a branch.

### 4.6 Status Lifecycle

**FR-STA-01:** Job statuses in fixed pipeline order:
  `Received → Inspection → Estimate Sent → Approved → [Awaiting Parts] → In Service → Ready for Pickup → Delivered`

**FR-STA-02:** `Awaiting Parts` is optional — jobs can move from `Approved` directly to `In Service`.  
**FR-STA-03:** Every status transition is recorded: new status, previous status, user who made the change, timestamp. This log is immutable.  
**FR-STA-04:** Jobs are flagged `Overdue` when the current timestamp exceeds the estimated delivery date and the job is not in `Delivered` status. Overdue is a computed flag, not a status — jobs retain their actual status.  
**FR-STA-05:** Status transitions trigger the configured customer notification automatically (for configured trigger points).  
**FR-STA-06:** All status changes are reflected in real-time across all connected sessions via Supabase Realtime — no page refresh required.  
**FR-STA-07:** Status transitions are validated server-side via a Postgres function. Invalid transitions (e.g. skipping Approved) return an error.

### 4.7 Payment & Invoicing

**FR-PAY-01:** Payment is recorded against a job: mode (Cash/UPI/Card/NEFT/Other), amount, reference number (optional), date.  
**FR-PAY-02:** Partial payments are supported. Outstanding balance is tracked.  
**FR-PAY-03:** An advance payment can be recorded at intake.  
**FR-PAY-04:** Invoice is auto-generated from the approved estimate (parts + labour) when the job is marked ready. The invoice is a structured record, not just a PDF.  
**FR-PAY-05:** Invoice PDF can be downloaded and shared via WhatsApp from the job detail panel.  
**FR-PAY-06:** The "Mark as Delivered" action is locked until total payments recorded equal or exceed the invoice total. Enforced server-side.  
**FR-PAY-07:** Payment history (all transactions against a job) is visible on the job detail panel.

### 4.8 Customer Portal

**FR-CUS-01:** Each job has a unique, token-based public URL. No login required.  
**FR-CUS-02:** The portal shows: current status, status history timeline, device details, branch contact, estimate breakdown (once sent), invoice (once generated).  
**FR-CUS-03:** The estimate approval button is available on the portal when the job is in `Estimate Sent` status. Clicking it records approval and moves the job to `Approved`.  
**FR-CUS-04:** Post-service photos are visible on the portal once uploaded.  
**FR-CUS-05:** The portal is branded with the org's logo and primary colour.  
**FR-CUS-06:** Invoice PDF is downloadable from the portal once the job is in `Ready for Pickup` or `Delivered` status.  
**FR-CUS-07:** Portal URL is sent in the job creation WhatsApp message and in the estimate message.

### 4.9 Customer History

**FR-CHI-01:** A customer profile is created automatically on first intake, keyed by phone number.  
**FR-CHI-02:** On subsequent intakes with the same phone number, the existing profile is matched and details pre-filled.  
**FR-CHI-03:** Customer profile shows: all past jobs (any branch, any item), total spend, last service date, outstanding balance across all jobs.  
**FR-CHI-04:** Asset history: all past services for a specific asset, identified by the primary identifier field configured for the org (serial number, IMEI, registration number, asset tag, etc.). The history label uses the org's configured asset label.  
**FR-CHI-05:** Outstanding balance flag surfaces at intake if the customer has an unpaid invoice on a previous job.

### 4.10 Branch Management

**FR-BRN-01:** Each branch has: name, address, phone, job sheet prefix, business hours (per day of week), holiday overrides.  
**FR-BRN-02:** Staff see only their assigned branch's jobs by default. Branch selector in the nav allows Managers with multi-branch access to switch context.  
**FR-BRN-03:** Admin sees all branches simultaneously in the dashboard. Branch filter narrows the view.  
**FR-BRN-04:** Branch-specific job numbering uses the configured prefix.

### 4.11 Reports & Analytics

**FR-REP-01:** Dashboard stats (real-time): open jobs count, today's intake count, jobs ready for pickup, today's revenue.  
**FR-REP-02:** Branch overview (real-time): per-branch open jobs, status breakdown bar, overdue count.  
**FR-REP-03:** Revenue report: by branch, by date range (daily / weekly / monthly / custom). Breakdowns by payment mode.  
**FR-REP-04:** Technician performance: jobs completed, average turnaround time, revenue attributed — per person, filterable by branch and date range.  
**FR-REP-05:** Overdue jobs report: all overdue jobs, sorted by days overdue, with aging column.  
**FR-REP-06:** Branch comparison: side-by-side volume and revenue across all branches.  
**FR-REP-07:** All reports exportable to CSV. Invoice-level data exportable to PDF.

### 4.12 Notifications

**FR-NOT-01:** Notification triggers (each configurable on/off per org):
  - Job created → confirmation to customer
  - Estimate sent → estimate + approval link to customer
  - Job approved → confirmation to customer (optional)
  - In Service → work started notification to customer
  - Awaiting Parts → parts delay notification to customer
  - Ready for Pickup → pickup notification with amount due to customer
  - Delivered → closure confirmation + warranty notice to customer

**FR-NOT-02:** Notifications are sent asynchronously via Supabase Edge Functions — UI does not wait for delivery.  
**FR-NOT-03:** Every notification attempt is logged: job_id, trigger, channel (WA/SMS), status (sent/failed), timestamp.  
**FR-NOT-04:** Failed notifications are surfaced in the job detail panel with a "Retry" option.  
**FR-NOT-05:** WhatsApp is primary. SMS is fallback (configurable: always send both, or SMS only on WA failure).

---

## 5. Non-Functional Requirements

### 5.1 Performance
- **NFR-P01:** Job list page must render within 1.5s on a standard 4G connection (India mobile benchmark).
- **NFR-P02:** Intake form submission (job creation) must complete in under 2s including notification trigger.
- **NFR-P03:** Status update from job detail panel must reflect in all open sessions within 3s via Realtime.
- **NFR-P04:** Customer portal must be fully rendered within 2s — it is public-facing and often opened on mobile.

### 5.2 Reliability
- **NFR-R01:** The platform must function for core workflows (intake, status update, payment) even if the notification service is unavailable.
- **NFR-R02:** Notification failures must not block or error the primary job action. They fail silently to the user, are logged, and surfaced separately.
- **NFR-R03:** Supabase Realtime disconnection must be handled gracefully — the app falls back to a polling refresh and displays a "reconnecting" indicator.

### 5.3 Security
- **NFR-S01:** All data access enforced via Supabase RLS. No org can access another org's data under any circumstances.
- **NFR-S02:** Customer portal tokens are UUIDs (v4) — not guessable, not sequential.
- **NFR-S03:** Staff passwords must be at least 8 characters. Password reset via email only.
- **NFR-S04:** File uploads (photos) are stored in Supabase Storage with signed URLs. Direct public access is disabled.
- **NFR-S05:** WhatsApp and SMS API keys are stored encrypted in the org settings — never exposed in client-side responses.

### 5.4 Accessibility & Responsiveness
- **NFR-A01:** The technician-facing views (job queue, status update, inspection form) must be fully functional at 390px width (iPhone SE baseline).
- **NFR-A02:** Admin and manager views are optimised for desktop (1280px+) but usable at tablet width (768px).
- **NFR-A03:** Colour contrast must meet WCAG AA for all text on brand-coloured surfaces.
- **NFR-A04:** All interactive elements must have focus states visible without a mouse.

### 5.5 Internationalisation
- **NFR-I01:** All currency displays use `en-IN` locale formatting (₹1,23,456).
- **NFR-I02:** All dates display in DD-MM-YYYY format across the platform.
- **NFR-I03:** The platform is English-only for v1. Multi-language support is out of scope.

---

## 6. Information Architecture

```
app/
├── (public)/
│   ├── login/                    # Email + password login
│   ├── signup/                   # Org creation
│   └── track/[token]/            # Customer portal (public, no auth)
│
├── (onboarding)/
│   └── setup/
│       ├── brand/                # Step 1: Logo, colour, app name
│       ├── contact/              # Step 2: Phone, email, address
│       ├── branches/             # Step 3: Branch setup
│       ├── staff/                # Step 4: Invite staff
│       └── notifications/        # Step 5: API keys + test
│
└── (app)/                        # Protected — requires auth + org context
    ├── dashboard/                # Stats + branch overview + recent jobs
    ├── jobs/
    │   ├── page                  # All jobs table with filter bar
    │   └── [id]/                 # Job detail (slide panel or full page on mobile)
    ├── intake/                   # New job form
    ├── customers/
    │   ├── page                  # Customer list
    │   └── [id]/                 # Customer profile + job history
    ├── reports/
    │   ├── overview/             # Cross-branch summary
    │   ├── revenue/              # Revenue by branch + date
    │   ├── technicians/          # Technician performance
    │   └── overdue/              # Overdue aging report
    └── settings/
        ├── org/                  # Org name, logo, colour, contact
        ├── branches/             # Add/edit branches
        ├── staff/                # User management
        ├── workflow/             # Categories, checklist, status labels, payment modes
        └── notifications/        # API keys, templates, triggers
```

---

## 7. Data Model (Conceptual)

### Core tables

```
organizations           — tenant root; one row per org
org_settings            — JSON config per org (see structure below)
branches                — belong to org; have prefix, hours, address
users                   — belong to org; have role; assigned to 1+ branches
customers               — belong to org; keyed by phone number
assets                  — belong to customer + org; stores field values as JSONB

jobs                    — core entity; belongs to org, branch, customer, asset
job_status_log          — immutable audit log of every status transition
job_parts               — line items (parts + labour) against a job
job_photos              — inspection and post-service photos against a job
job_notes               — internal staff notes against a job

invoices                — generated from job_parts at job completion
payments                — transactions against a job; supports partial
notifications_log       — every WA/SMS attempt; status, timestamp, error

portal_tokens           — UUID tokens for customer portal URLs; linked to job
```

### `org_settings` JSON structure

```json
{
  "branding": {
    "logo_url": "",
    "primary_color": "#1a56db",
    "app_name": "ServiceDesk"
  },
  "contact": {
    "phone": "", "email": "", "address": ""
  },
  "vertical": "laptop_repair",
  "asset": {
    "label": "device",
    "label_plural": "devices",
    "fields": [
      { "key": "brand",  "label": "Brand",        "type": "select",  "required": true,  "options": ["Dell","HP","Lenovo","Apple","Other"] },
      { "key": "model",  "label": "Model",         "type": "text",    "required": false },
      { "key": "serial", "label": "Serial Number", "type": "text",    "required": false, "is_primary_identifier": true }
    ]
  },
  "issue_categories": ["Screen / Display", "Battery", "Keyboard", "Charging Port", "Motherboard", "Software", "Other"],
  "accessories": ["Charger", "Bag", "Mouse", "External HDD", "Other"],
  "status_labels": {
    "received":   "Received",
    "inspection": "Inspection",
    "estimate_sent": "Estimate Sent",
    "approved":   "Approved",
    "parts":      "Awaiting Parts",
    "in_service": "In Service",
    "ready":      "Ready for Pickup",
    "delivered":  "Delivered"
  },
  "payment_modes": ["Cash", "UPI", "Card", "NEFT"],
  "overdue_threshold_hours": 1,
  "notification_triggers": {
    "job_created":   { "enabled": true,  "channels": ["whatsapp"] },
    "estimate_sent": { "enabled": true,  "channels": ["whatsapp"] },
    "in_service":    { "enabled": true,  "channels": ["whatsapp"] },
    "ready":         { "enabled": true,  "channels": ["whatsapp", "sms"] },
    "delivered":     { "enabled": true,  "channels": ["whatsapp"] }
  },
  "notification_templates": {
    "job_created": "Hi {{customer_name}}, your {{asset_label}} has been received at our {{branch_name}} branch. Job ID: {{job_id}}. — {{org_name}}",
    "estimate_sent": "Hi {{customer_name}}, inspection of your {{asset_label}} ({{job_id}}) is complete. Estimated cost: ₹{{estimate_amount}}. Reply YES to approve. — {{org_name}}",
    "in_service": "Hi {{customer_name}}, we've started working on your {{asset_label}} ({{job_id}}). We'll notify you when it's ready. — {{org_name}}",
    "ready": "Hi {{customer_name}}, your {{asset_label}} is ready for pickup. Amount due: ₹{{amount_due}}. Job ID: {{job_id}}. — {{org_name}}",
    "delivered": "Your {{asset_label}} has been delivered. Thank you for choosing {{org_name}}. Job ID: {{job_id}} for warranty reference."
  },
  "integrations": {
    "whatsapp_provider": "interakt",
    "whatsapp_api_key": "",
    "sms_provider": "msg91",
    "sms_api_key": ""
  },
  "setup_progress": {
    "vertical": true, "brand": false, "contact": false,
    "branches": false, "staff": false, "notifications": false
  },
  "is_live": false
}
```

### Key relationships
- `jobs` → `organizations`, `branches`, `customers`, `assets`, `users` (assigned tech)
- `job_parts`, `job_photos`, `job_notes`, `job_status_log`, `payments` → `jobs`
- `assets` → `customers`, `organizations`; stores field values as JSONB keyed by `asset.fields[].key`
- `invoices` → `jobs` (one-to-one once generated)
- `portal_tokens` → `jobs` (one-to-one, generated at job creation)
- `customers` → `organizations` (phone number unique per org, not globally)

### RLS policy shape (all tables follow this pattern)
```sql
-- Users can only access rows belonging to their org
USING (org_id = auth.jwt() ->> 'org_id')

-- Branch-scoped roles further restricted to their branch
USING (
  org_id = auth.jwt() ->> 'org_id'
  AND (
    auth.jwt() ->> 'role' IN ('admin', 'manager_all')
    OR branch_id = ANY((auth.jwt() ->> 'branch_ids')::uuid[])
  )
)
```

---

## 8. PWA & Mobile Wrapper Specification

### PWA Requirements
- `manifest.json`: name, short_name, icons (192px + 512px), theme_color (from org config — generated at request time), display: standalone, start_url, orientation: portrait
- Service worker: cache app shell + static assets; network-first for API calls; offline fallback page for non-cached routes
- Web Push: subscribe technicians to push on login; send push on new job assignment (via Supabase Edge Function → Web Push)

### Android (Bubblewrap / TWA)
- Wrapper points to the production PWA URL
- `assetlinks.json` served at `/.well-known/assetlinks.json` to verify domain ownership
- Signed APK generated via Bubblewrap CLI in GitHub Actions
- Option A: single generic wrapper → one Play Store listing ("ServiceDesk Platform")
- Option B (premium): per-org wrapper with their app name + icons; CI pipeline triggered by org setup

### iOS (Capacitor)
- Capacitor project wraps the PWA in WKWebView
- Camera, file picker, and push notification native plugins configured
- IPA built via GitHub Actions with Xcode Cloud or fastlane
- Option A: single IPA, one App Store listing
- Option B (premium): per-org IPA with custom bundle ID + metadata

---

## 9. Development Plan for Claude Code

This plan is written for implementation by Claude Code (Claude Sonnet). Each phase is self-contained and produces a shippable increment. Work within a phase proceeds top-to-bottom. Do not skip phases — later phases depend on earlier ones being complete and tested.

---

### Phase 0 — Database & Auth Foundation
*Deliverable: Supabase project fully configured; all tables, RLS, functions, and seed data in place. Nothing is built on an assumption about the schema — every later phase can reference this.*

**Tasks:**
- [ ] Create Supabase project; store `SUPABASE_URL` and `SUPABASE_ANON_KEY` in `.env.local`
- [ ] Write migration: `organizations`, `org_settings` (JSONB column with full typed default matching the `org_settings` JSON structure in Section 7), `branches`
- [ ] Write migration: `users` table extending Supabase auth; columns: org_id, role (enum), branch_ids (uuid[]), full_name, is_active
- [ ] Write migration: `customers`; write migration: `assets` (JSONB `field_values` column — stores any vertical's asset fields without schema changes)
- [ ] Write migration: `jobs` with status enum, all foreign keys (references `assets` not `devices`)
- [ ] Write migration: `job_status_log` (immutable — no UPDATE/DELETE RLS)
- [ ] Write migration: `job_parts`, `job_photos`, `job_notes`
- [ ] Write migration: `invoices`, `payments`
- [ ] Write migration: `notifications_log`, `portal_tokens`
- [ ] Write all RLS policies for every table
- [ ] Write Postgres function: `transition_job_status(job_id, new_status, user_id)` — validates allowed transitions, inserts to status_log, updates job.status atomically
- [ ] Write Postgres function: `generate_job_number(branch_id)` — returns next sequential number with branch prefix
- [ ] Write Postgres trigger: on job INSERT → call `generate_job_number`, create `portal_token`
- [ ] Write seed data: one demo org, two branches, five users (one per role), ten sample jobs across statuses
- [ ] Validate all RLS policies: confirm cross-org queries return zero rows

---

### Phase 1 — Next.js Project Scaffold
*Deliverable: Running Next.js 15 app with auth, org context, dynamic theming, and layout in place. No features yet — just the skeleton every feature will be built on.*

**Tasks:**
- [ ] Scaffold Next.js 15 app with App Router, TypeScript, Tailwind CSS
- [ ] Install and configure: `@supabase/supabase-js`, `@supabase/ssr`, `@tanstack/react-query`
- [ ] Set up Supabase client: server client (for Server Components + Route Handlers), browser client (for Client Components)
- [ ] Implement auth middleware: redirect unauthenticated users to `/login`; redirect authenticated users away from `/login`
- [ ] Build `OrgContext` provider: loads org_settings, user profile, and branch assignments on login; makes them available app-wide via `useOrg()` hook
- [ ] Build `ThemeProvider`: reads `primary_color` from org context; injects CSS custom properties on mount; updates on org config change
- [ ] Build app shell layout: sidebar nav (role-aware — Admin sees Reports, Technician does not), topbar with branch picker and avatar
- [ ] Build branch picker: Admin sees all branches; branch-scoped roles see only their assigned branches; selection stored in context and passed to all queries
- [ ] Implement role-based route guards: Technician cannot access `/settings/*`; Front Desk cannot access `/reports/*`
- [ ] Set up React Query: global client, dev tools, default stale time 30s
- [ ] Set up error boundary and global 404/500 pages
- [ ] Confirm: login → org context loads → themed layout renders → logout clears session

---

### Phase 2 — Core Job Workflow (Web)
*Deliverable: The primary staff workflow is functional end-to-end. Jobs can be created, updated through the full status pipeline, and closed. This is the beating heart of the product.*

**Tasks:**
- [ ] Build intake form (`/intake`): all fields per FR-INT; phone lookup (debounced, 10-digit trigger); asset fields section rendered dynamically from `org_settings.asset.fields` — no hardcoded field names; accessories checklist from org config; issue categories from org config; asset label used in all headings and labels (e.g. "Device Details" vs "Vehicle Details" vs "Appliance Details")
- [ ] Wire intake form submission: insert job, trigger job number generation, navigate to job detail on success
- [ ] Build job list page (`/jobs`): table with columns (job ID, customer, device, branch, technician, status chip, due date); filter bar (status filters from org config labels); search by job ID, customer name, phone
- [ ] Build job detail slide panel: all job fields, status chip, activity timeline from `job_status_log`, parts list, payment summary, internal notes
- [ ] Build status action buttons in panel: context-aware actions per current status (e.g. "Received" shows "Start Inspection"; "In Service" shows "Mark Ready"); calls `transition_job_status` server function
- [ ] Build inspection form: parts line items (add/remove rows), labour charges, notes; validates at least one part or labour line before submit
- [ ] Build photo upload: multi-file upload to Supabase Storage; thumbnails in job detail panel; supports camera capture on mobile
- [ ] Build "Send Estimate" action: previews WhatsApp message template with values substituted; confirm → fires Edge Function → logs to notifications_log
- [ ] Build customer approval flow (staff-side): "Mark as Approved" button with confirmation
- [ ] Build payment recording modal: mode, amount, reference, date; shows running balance; warns if amount exceeds outstanding
- [ ] Build "Mark Delivered" action: disabled with tooltip if payment is outstanding (enforce FR-PAY-06)
- [ ] Build internal notes: add note form in panel; note list with author + timestamp
- [ ] Build overdue flagging: computed in query (due_date < now() AND status ≠ delivered); red due date cell; overdue chip on job row
- [ ] Wire Supabase Realtime: subscribe to job status changes; update job list and open panel without refresh
- [ ] Build dashboard (`/dashboard`): four stat cards (open jobs, today's intake, ready for pickup, today's revenue); branch overview grid; recent jobs table
- [ ] Confirm: full lifecycle — intake → inspection → estimate → approved → in service → ready → payment → delivered — works without errors

---

### Phase 3 — Customer Portal
*Deliverable: A customer can track their job, view their estimate, approve it, and download their invoice — all without a login.*

**Tasks:**
- [ ] Build public route `/track/[token]`: fetch job by portal token (no auth required); render org branding from job's org config
- [ ] Build status timeline component: visual pipeline showing current status highlighted; all past transitions listed with timestamps
- [ ] Build estimate view: parts + labour line-item breakdown; total; approve button (only shown when status is `Estimate Sent`)
- [ ] Wire estimate approval: POST to Route Handler → validates token + status → calls `transition_job_status` → returns updated status
- [ ] Build device info section: brand, model, serial, reported issue
- [ ] Build photo gallery: inspection photos and post-service photos, accessible once uploaded
- [ ] Build invoice download: generates PDF from invoice record; available when status ≥ `Ready for Pickup`
- [ ] Apply dynamic org branding: logo, primary colour, org name, support contact
- [ ] Confirm: send a portal link, open in incognito, approve estimate, verify job status updates in staff app in real-time

---

### Phase 4 — Notifications (Edge Functions)
*Deliverable: WhatsApp and SMS messages fire automatically at configured trigger points. Failures are logged and retryable.*

**Tasks:**
- [ ] Create Supabase Edge Function: `send-notification` — accepts job_id, trigger name; loads org's API keys from org_settings; loads template for trigger; substitutes placeholders; calls WhatsApp API (Interakt/AiSensy) or SMS API (MSG91); logs result to notifications_log
- [ ] Create Supabase Edge Function: `on-status-change` — triggered by Postgres webhook on `job_status_log` INSERT; calls `send-notification` for the relevant trigger
- [ ] Create Postgres webhook: fires `on-status-change` edge function on INSERT to `job_status_log`
- [ ] Build notification log view in job detail panel: list of all sends (trigger, channel, status, timestamp); "Retry" button for failed sends
- [ ] Build notification settings page (`/settings/notifications`): API key fields (masked), template editor per trigger with placeholder reference, enable/disable toggle per trigger, "Send Test Message" button
- [ ] Validate: create a job → WA fires; send estimate → WA fires with estimate amount; mark ready → WA fires with branch and amount due

---

### Phase 5 — Onboarding Wizard & Org Settings
*Deliverable: A new org can sign up and go live without any help. An existing org can fully configure their account from the settings panel.*

**Tasks:**
- [ ] Build public signup page (`/signup`): org name, admin name, email, password; creates org record + admin user via Route Handler; `org_settings` initialised with full default JSON structure
- [ ] Build onboarding wizard layout: step indicator (6 steps), step persistence in `org_settings.setup_progress`, "Continue Later" exits to wizard home
- [ ] Build Step 1 — Vertical: card-based selector (Laptop repair, Mobile repair, AC/appliance, Two-wheeler, CCTV/security, Generator/UPS, Medical equipment, Other); selecting a vertical writes the matching defaults into `org_settings` (asset label, asset fields, issue categories, accessories, notification template language); "Other" shows blank custom setup
- [ ] Build Step 2 — Brand: logo upload (to Supabase Storage), primary colour picker (with live preview of themed elements), app display name
- [ ] Build Step 3 — Contact: support phone, email, address fields
- [ ] Build Step 4 — Branches: add branch form (name, address, prefix, business hours per day); list of added branches; at least one required to proceed
- [ ] Build Step 5 — Staff: invite by email (sends Supabase auth invite email); role selector; branch assignment; list of pending + active invites
- [ ] Build Step 6 — Notifications: WhatsApp API key, SMS API key, send test message button; skip option with warning
- [ ] Build go-live checklist: shows completion status of each wizard step; "Launch" button activates the org (sets `org_settings.is_live = true`)
- [ ] Build settings — Vertical / Asset: asset label editor, asset fields CRUD (add field, set type, mark required, add options for selects, mark primary identifier), accessories CRUD
- [ ] Build settings — Org: edit logo, colour, app name, contact details
- [ ] Build settings — Branches: edit existing branches, add new branches
- [ ] Build settings — Staff: list all users, change role, change branch assignment, deactivate user, resend invite
- [ ] Build settings — Workflow: issue categories CRUD, accessories CRUD, status label editing, payment mode toggles, overdue threshold input
- [ ] Build settings — Notifications: (as built in Phase 4, exposed here)
- [ ] Confirm: fresh signup → complete wizard → create a test job → close job → org is fully operational

---

### Phase 6 — Reports & Invoicing
*Deliverable: Managers and admins have full reporting. Invoices are generated as PDFs and shareable.*

**Tasks:**
- [ ] Build reports layout with sub-nav (Overview, Revenue, Technicians, Overdue)
- [ ] Build Overview report: stat tiles (total jobs, revenue, avg turnaround, open jobs) for selected date range; filterable by branch
- [ ] Build Revenue report: bar chart (revenue by branch); table with daily/weekly/monthly toggle; payment mode breakdown
- [ ] Build Technician Performance report: table — technician, branch, jobs completed, avg turnaround, revenue; sortable columns
- [ ] Build Overdue Aging report: table of all overdue jobs with days overdue column; link to job detail
- [ ] Build CSV export for all reports: generates download from current filter state
- [ ] Build invoice PDF: uses a server-side route handler to render HTML → PDF (using `@react-pdf/renderer` or puppeteer); includes org logo, address, line items, payment status, job ID, warranty notice
- [ ] Wire invoice PDF to job detail panel: "Download Invoice" button; "Share via WhatsApp" button (opens WA deep link with invoice PDF)
- [ ] Confirm: generate a complete job with parts and payment; download invoice PDF; verify all line items and totals correct

---

### Phase 7 — PWA & Mobile Wrappers
*Deliverable: The app installs as a PWA. Bubblewrap APK is generated and installable. Capacitor iOS project builds.*

**Tasks:**
- [ ] Configure `next-pwa` (or `@ducanh2912/next-pwa`): manifest, service worker, offline fallback
- [ ] Write `manifest.json`: all required fields; icons at 192px, 512px, maskable; theme_color and background_color
- [ ] Build service worker caching strategy: app shell cached on install; API responses use network-first with stale-while-revalidate; offline page for unresolvable navigations
- [ ] Implement Web Push: subscribe technician on login (with permission prompt); store subscription in `users.push_subscription`; fire push from Edge Function on job assignment
- [ ] Serve `/.well-known/assetlinks.json` from Next.js for Android TWA domain verification
- [ ] Set up Bubblewrap project: configure with production URL, app name, icons; generate signed APK via GitHub Actions
- [ ] Set up Capacitor project: `capacitor.config.json` pointing to production URL; configure Camera plugin, Push Notifications plugin, Filesystem plugin
- [ ] Set up GitHub Actions workflow for Capacitor iOS build
- [ ] Test PWA install on Android Chrome; test APK install; test Capacitor build on iOS simulator
- [ ] Confirm: technician opens app on phone, installs to home screen, receives push notification on new assignment, updates job status, uploads photo — all functional

---

### Phase 8 — Platform Admin Dashboard
*Deliverable: You (the platform owner) can see all orgs, usage, and support any tenant.*

**Tasks:**
- [ ] Create separate Next.js route group `(platform-admin)` behind a separate auth check (platform admin flag on user record)
- [ ] Build org list: all orgs, created date, branch count, user count, job count (30d), active/inactive status
- [ ] Build org detail: all org settings, all branches, all users, recent jobs (read-only view)
- [ ] Build usage stats: jobs created (all orgs), notifications sent, storage used
- [ ] Build impersonation: platform admin can assume any org's admin context to provide support (logged + time-limited)
- [ ] Confirm: platform admin can view any org's data; regular org admin cannot access platform admin routes

---

## 10. Out of Scope (v1)

The following are explicitly excluded from v1. They are good ideas — they are not this version.

- Multi-language support
- Inventory / parts procurement management
- Customer loyalty / points system
- Accounting software integration (Tally, Zoho Books)
- Online payment collection (UPI payment links to customers)
- AI-powered diagnosis suggestions
- Per-org white-label APK/IPA (Option B — deferred to post-launch)
- Customer app (native or PWA) — v1 customer experience is notifications + portal only
- API access for orgs (webhook/API for their own integrations)
- Bulk import of existing job data
- Field service / on-site job mode (where the technician goes to the customer — out of scope for v1 which assumes item is brought in)
- Multi-item jobs (one job = one asset; servicing multiple items in one job is not supported in v1)

---

## 11. Success Metrics

| Metric | Target (90 days post-launch) |
|---|---|
| Pilot org (Infinity IT) daily active staff | ≥ 80% of staff logging in daily |
| Avg job intake time | ≤ 2 minutes |
| Customer inbound "status?" calls (pilot) | ≥ 60% reduction vs baseline |
| Notification delivery rate | ≥ 97% |
| Jobs with complete audit trail | 100% (enforced by system) |
| Time from signup to first job created | ≤ 45 minutes |

---

## 12. Open Questions (resolve before Phase 0 begins)

1. **WhatsApp BSP choice:** Interakt vs AiSensy vs direct Meta API. Need to confirm which the pilot org already has or prefers — affects the Edge Function implementation.
2. **Invoice PDF library:** `@react-pdf/renderer` (client-renderable, no puppeteer) vs server-side HTML-to-PDF. Recommend `@react-pdf/renderer` for simpler infra.
3. **Org slug format:** `app.servicedesk.in/[org-slug]` (subdirectory) vs `[org-slug].servicedesk.in` (subdomain). Subdomain requires wildcard SSL and Vercel Pro. Subdirectory is simpler for v1.
4. **Custom domain support:** Defer to post-launch (requires Vercel Edge Config + DNS verification flow). Not in v1.
5. **Pilot pricing:** Confirm whether Infinity IT Services is paying from day one or getting a free pilot period.
6. ~~**Vertical defaults maintenance:**~~ **RESOLVED.** Platform owner maintains vertical preset defaults in a config file in the codebase (`/config/verticals.ts`). Fast to update, version-controlled, no admin UI needed for v1.
7. ~~**Product name:**~~ **RESOLVED.** Each subscribing org owns and sets their own app name during the onboarding wizard (Step 2 — Brand). The platform-level name ("ServiceDesk") is the platform owner's decision and can be set before launch. Org-facing app name is fully white-labeled — customers of Infinity IT Services will see "Infinity ServiceDesk" or whatever the org configures, never the platform name.

---

*ServiceDesk PRD v1.0 · August 2026 · Platform team*
