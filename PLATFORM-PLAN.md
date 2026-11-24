# Laptop Service Management Platform — Build Plan

**Client (pilot):** Infinity IT Services — 7-branch laptop servicing, Pune  
**Product vision:** Generic, multi-tenant SaaS framework for laptop/electronics service businesses  
**Date:** August 2026

---

## What We're Building

A multi-tenant service desk platform that any laptop service business can sign up for, configure with their own branding and branch structure, and go live — without any custom development.

Infinity IT Services (laptop repair, Pune) is the pilot customer who validates the workflow. The platform is **vertical-agnostic** — the same codebase serves laptop repair, mobile repair, AC/appliance service, two-wheeler workshops, CCTV/security, generators, medical equipment, and any other business that receives a physical item, services it, and returns it. Vertical-specific behaviour (asset fields, categories, terminology, notification language) is driven entirely by configuration at the org level.

---

## The Three App Surfaces

| Surface | Users | Purpose |
|---|---|---|
| Web app (PWA) | Front desk, Manager, Admin | Job intake, status management, reports, branch dashboard |
| Mobile (PWA wrapper) | Technicians | View assigned jobs, update status, upload photos |
| Customer tracking portal | End customers | Live job status, estimate approval, invoice download |

---

## Technology Stack

### Backend — Supabase
- **Postgres** — all job, customer, branch, user, and org config data
- **Auth** — role-based login with org context (admin / manager / technician / front-desk)
- **Realtime** — live job status updates across branches without polling
- **Storage** — inspection photos, post-service photos, invoice PDFs
- **Edge Functions** — WhatsApp/SMS triggers on status changes, invoice PDF generation
- **Row-Level Security** — branch and org data isolation enforced at DB level

### Frontend — Next.js (deployed on Vercel)
- PWA-ready (manifest + service worker via `@ducanh2912/next-pwa`)
- Dynamic theming via CSS variables loaded from org config at login
- Server-side rendering for reports and invoice PDFs
- Single deployment serves all orgs

### Mobile — PWA + Wrappers
- **Android APK:** Bubblewrap (Trusted Web Activity) → Play Store  
  Google's official method for shipping a PWA as a Play Store app. No native code.
- **iOS IPA:** Capacitor (WKWebView wrapper) → App Store  
  Minimal native shell around the PWA URL. Enables App Store listing.
- All app updates deploy to the web and are immediately live in both wrappers — no store release needed for feature updates.

### Notifications
- **WhatsApp:** Interakt or AiSensy (Indian BSPs — cheaper than direct Meta API)
- **SMS fallback:** MSG91 / Textlocal
- Triggered via Supabase Edge Functions on job status changes
- Each org uses their own API credentials

---

## Mobile App Strategy: PWA vs Native

| Concern | PWA approach |
|---|---|
| Camera (photo upload) | Supported via browser MediaDevices API |
| Push notifications | Supported via Web Push API |
| Offline mode | Service worker caches job list and forms |
| Performance | Adequate for a service desk app |
| App Store presence | Achieved via Bubblewrap (Android) + Capacitor (iOS) |
| Updates | Deploy to web → instant in both wrappers |
| Maintenance | One codebase for web + mobile |

### APK/iOS Build — Two Tiers

**Option A — Generic wrapper (MVP, included in base)**  
One APK + one IPA pointing to `app.platform.com`. Org slug entered at login.  
Single Play Store listing + single App Store listing ("ServiceDesk Platform").

**Option B — White-label per org (premium tier, charged extra)**  
Each org gets their own APK/IPA with their logo, app name, and store listing.  
Built via GitHub Actions CI — org uploads assets → pipeline builds signed wrapper → delivered as download.

> Start with Option A. Offer Option B as a paid upgrade.

---

## Multi-Tenant Architecture

### Tenant Model

```
Organization (tenant root)
    ├── Branding (logo, colors, app name)
    ├── Settings (notification config, payment modes, categories, etc.)
    ├── Branches (1–N, each with prefix, address, hours)
    ├── Users (staff with roles assigned per branch)
    └── Jobs, Customers, Invoices (all scoped to org_id)
```

All data isolated via Supabase RLS on `org_id`. A user at Org A cannot access Org B's data — enforced at the database level, not application code.

### Architecture Layers

```
┌─────────────────────────────────────────────────────┐
│  PLATFORM LAYER (product owner)                     │
│  · Tenant management, billing, onboarding           │
│  · Shared infrastructure (Supabase, Vercel)         │
│  · Platform admin dashboard (see all orgs, usage)   │
└─────────────────────┬───────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────┐
│  CONFIG LAYER (per org)                             │
│  · org_settings table (JSON config per org)         │
│  · Loaded at app init, cached client-side           │
│  · Drives branding, labels, features, limits        │
└─────────────────────┬───────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────┐
│  APP LAYER (same code for all orgs)                 │
│  · All features, all roles                          │
│  · Data scoped by org_id via RLS                    │
│  · UI themed dynamically from org config            │
└─────────────────────────────────────────────────────┘
```

### Dynamic Theming

At login, the app fetches the org config and injects CSS variables — no rebuild required:

```js
const { primary_color, logo_url, app_name } = org.settings
document.documentElement.style.setProperty('--brand', primary_color)
document.title = app_name
```

Every org gets a branded experience from the same deployed codebase.

---

## What Orgs Can Configure

### Tier 1 — Basic Setup (onboarding wizard, required)

| Setting | Description |
|---|---|
| Org name + logo | Displayed in app header, notifications, invoices |
| Primary brand color | Applied to buttons, highlights, chips |
| App display name | e.g. "ServiceDesk by Infinity" |
| Support phone + email | Shown in customer-facing notifications |
| Branches | Names, addresses, job sheet number prefix (KTH-, WAK-...) |
| Business hours | Per branch — used for overdue calculations |

### Tier 2 — Workflow Config (settings panel)

| Setting | Description |
|---|---|
| Issue categories | Default list + add/remove custom categories |
| Accessories checklist | Items shown at intake — fully editable |
| Status labels | Rename statuses (e.g. "Diagnosing" → "Assessment") |
| Payment modes | Enable/disable Cash, UPI, Card, others |
| Notification triggers | Choose which status changes fire WhatsApp/SMS |
| Overdue threshold | Hours after estimated delivery before flagging |

### Tier 3 — Notification Templates (per trigger)

Each org writes their own message text with system placeholders:

```
Hi {{customer_name}}, your {{device_brand}} has been received at our 
{{branch_name}} branch. Job ID: {{job_id}}. We'll keep you updated.
— {{org_name}}
```

Available triggers: job created, estimate sent, work started, ready for pickup, delivered.

### Tier 4 — Integration Credentials (per org)

- WhatsApp Business API key (their own account or platform sub-account)
- SMS provider key (MSG91 / Textlocal)
- Custom domain mapping (optional — `desk.infinityit.in` → their org)

---

## Self-Serve Onboarding Flow

```
Step 1: Signup
        → Org name, admin name, email, password
        → Creates org record + admin user + default config

Step 2: Org Setup Wizard
        2a. Logo, brand color, app display name
        2b. Contact details (phone, email, address)
        2c. Add branches (name, prefix, address, hours)
        2d. Invite staff (email → role → branch assignment)
        2e. Notification setup (API keys + send test message)

Step 3: Go Live
        → Web app live at app.platform.com/[org-slug]
        → APK download link (Option A: pre-built generic wrapper)
        → iOS install guide (PWA install + App Store link)
        → Go-live checklist (branches added ✓, staff invited ✓, test job created ✓)
```

---

## Core Workflow (all orgs)

Eight steps from intake to closure. Enforced server-side — no step can be skipped.

```
Customer Intake → Job Sheet Created → Inspection → Estimate & Approval
→ Service in Progress → Work Complete → Payment Collected → Device Handed Over
```

**Hard gates enforced in DB:**
- Job cannot move to "In Service" without a recorded customer approval
- Job cannot be marked "Delivered" until payment is fully recorded

### Job Status Lifecycle

`Received → Inspection → Estimate Sent → Approved → [Awaiting Parts] → In Service → Ready for Pickup → Delivered`

Every status change is timestamped, attributed to a staff member, and triggers the configured customer notification.

---

## Roles & Access

| Role | Scope | Key permissions |
|---|---|---|
| **Admin** | All branches in org | Full access, user management, branch config, all reports |
| **Manager** | Their branch | All jobs at branch, reassign technicians, branch reports |
| **Technician** | Assigned jobs | View queue, update status, upload photos, fill inspection |
| **Front Desk** | Their branch | Intake, payment recording, job closure, receipt printing |
| **Customer** | Their own jobs | Track status, approve estimate, download invoice (no login required — token URL) |

---

## Modules

1. **Customer Intake** — name, phone, device details, issue, accessories checklist, auto job sheet number, WA confirmation on creation
2. **Inspection & Estimation** — parts list with costs, damage photos, auto-calculated total, estimate sent to customer via WA, approval gate
3. **Job & Technician Management** — assignment, status updates, internal notes, parts used log, post-service photos, workload view
4. **Job Status Tracking** — status pipeline, timestamped transitions, overdue flagging, search and filter
5. **Payment & Invoicing** — invoice from parts + labour, cash/UPI/card, advance payment, balance tracking, PDF invoice, delivery gate
6. **Branch Management** — branch-scoped views, manager reassignment, head office cross-branch view, per-branch config
7. **Customer History** — profile by phone number, all past jobs across branches, device history, outstanding balance flag
8. **Reports** — revenue by branch, technician performance, overdue aging, branch comparison, Excel/PDF export

---

## Build Phases

| Phase | Deliverable | Effort |
|---|---|---|
| **0 — Framework foundation** | Multi-tenant DB schema, RLS policies, org config table, auth with org context, dynamic theming | 1 week |
| **1 — Core web app** | All 4 staff roles, full intake → delivery workflow, branch dashboard, per-org config applied | 4 weeks |
| **2 — Onboarding wizard** | Self-serve signup, 5-step setup wizard, branch + staff management, go-live checklist | 1.5 weeks |
| **3 — Notifications** | WhatsApp/SMS triggers via Edge Functions, org-specific templates, delivery log | 1.5 weeks |
| **4 — Customer portal** | Token-based tracking page, estimate approval, invoice download, org-branded | 1 week |
| **5 — PWA + wrappers** | PWA manifest + service worker, Bubblewrap APK build, Capacitor iOS shell | 1.5 weeks |
| **6 — Reports + invoicing** | PDF invoice generation, full reports dashboard, Excel export | 2 weeks |
| **7 — Platform admin** | Internal dashboard: all orgs, usage stats, billing hooks, support tools | 1 week |

**Total: ~13–14 weeks to a fully shippable, sellable platform**

---

## Infrastructure Costs (per org/tenant)

### Annual Recurring (org pays)

| Service | Cost | Notes |
|---|---|---|
| Cloud hosting (Vercel) | ₹36,000 / yr | Shared across all orgs on one deployment — this cost is yours as platform owner |
| Database + Auth + Realtime (Supabase) | ₹30,000 / yr | Shared — scales with total usage |
| WhatsApp Business API platform | ₹18,000–24,000 / yr | Per org (their own account) or metered via your account |
| WhatsApp per-conversation | ₹0.30–0.85 / msg | Utility ~₹0.30, marketing ~₹0.85, usage-based |
| Domain name | ₹800–1,500 / yr | Org's own domain if they want custom mapping |
| iOS App Store (Option B only) | ₹8,200 / yr | Only if org wants their own App Store listing |
| Android Play Store (Option B only) | ₹2,100 one-time | Only if org wants their own Play Store listing |

### Platform Infrastructure (your cost, amortised across tenants)

| Item | Cost |
|---|---|
| Vercel Pro | ~₹4,000 / mo |
| Supabase Pro | ~₹2,500 / mo |
| Total platform overhead | ~₹6,500 / mo |

At 10+ paying tenants, infrastructure cost per tenant drops below ₹700/month.

---

## Commercial Model

| Tier | Price | What's included |
|---|---|---|
| **Starter** | ₹1,500 / branch / mo | Up to 3 branches, web app, generic PWA wrapper |
| **Growth** | ₹1,200 / branch / mo | 4–10 branches, all features, generic PWA wrapper |
| **Enterprise** | ₹1,000 / branch / mo + ₹25,000 setup | 10+ branches, white-label APK/IPA (Option B), custom domain, priority support |

**Example — Infinity IT Services (7 branches):**  
7 × ₹1,200 = **₹8,400 / month**

**At 20 similar customers:**  
20 × ₹8,400 = **₹1,68,000 / month recurring**

---

## Next Steps

1. **Supabase schema** — design the multi-tenant DB schema (foundation for everything)
2. **Lovable prompt** — convert the existing UI mockup into a Lovable scaffold for the web app
3. **Pilot agreement** — lock in Infinity IT Services as a paying pilot (even at a discount)
4. **Onboarding flow wireframe** — design the 5-step wizard before building it

---

*Platform Plan · Laptop Service Management · August 2026*
