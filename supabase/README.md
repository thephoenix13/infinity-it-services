# Supabase — Phase 0 Setup

## Migration order

Run these in sequence in the Supabase SQL editor (Dashboard → SQL Editor → New query):

| File | What it creates |
|---|---|
| `001_enums.sql` | All enum types (user_role, job_status, payment_mode, etc.) |
| `002_organizations.sql` | organizations, org_settings tables + updated_at trigger |
| `003_branches.sql` | branches, job_number_sequences tables |
| `004_users.sql` | users profile table + auth helper functions |
| `005_customers_assets.sql` | customers, assets tables |
| `006_jobs.sql` | jobs, job_status_log tables |
| `007_job_details.sql` | job_parts, job_photos, job_notes tables |
| `008_invoices_payments.sql` | invoices, payments tables + job_payment_summary view |
| `009_notifications_portal.sql` | notifications_log, portal_tokens tables |
| `010_rls.sql` | All Row-Level Security policies |
| `011_functions.sql` | Business logic functions |
| `012_triggers.sql` | Database triggers |
| `013_seed.sql` | Demo data (DEV ONLY — do not run in production) |

## Running migrations

1. Open your Supabase project dashboard
2. Go to **SQL Editor** → **New query**
3. Copy and paste each file in order, run each one individually
4. Verify no errors before moving to the next

## Before running 013_seed.sql

The seed file uses placeholder UUIDs for auth users. You must:

1. Create the 5 seed users via **Authentication → Users → Invite user** in the dashboard
   - `admin@infinityit.test` — password: `ServiceDesk@2026`
   - `manager@infinityit.test`
   - `tech1@infinityit.test`
   - `tech2@infinityit.test`
   - `frontdesk@infinityit.test`

2. Copy the UUIDs Supabase generates for each user

3. Replace the placeholder UUIDs at the top of `013_seed.sql`:
   ```sql
   uid_admin     uuid := '00000000-0000-0000-0000-000000000001';  -- replace
   uid_manager   uuid := '00000000-0000-0000-0000-000000000002';  -- replace
   ...
   ```

4. Then run the seed file

## Storage buckets

After running migrations, create these buckets in **Storage**:

| Bucket name | Public | Notes |
|---|---|---|
| `job-photos` | No | Inspection and post-service photos. Signed URLs only. |
| `org-assets` | No | Org logos. Served via signed URL in the app. |

## Environment variables needed (for Next.js app)

```env
NEXT_PUBLIC_SUPABASE_URL=https://[your-project-ref].supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=[your anon key]
SUPABASE_SERVICE_ROLE_KEY=[your service role key]
```

Get these from: **Settings → API** in your project dashboard.
