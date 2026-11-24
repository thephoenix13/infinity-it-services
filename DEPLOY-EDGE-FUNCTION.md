# Deploy Edge Function — One-time step

The `send-notification` Supabase Edge Function needs to be deployed from a browser session
authenticated as the TRP Organization account.

## Option A — Supabase Dashboard (easiest)

1. Go to https://supabase.com/dashboard/project/osztmrxyyrpbtnikwsps/functions
2. Click "New Function" → name it `send-notification`
3. Paste the contents of `supabase/functions/send-notification/index.ts`
4. Deploy

## Option B — CLI after re-authenticating

Open a terminal logged into the TRP Org account:

```bash
supabase logout
supabase login           # opens browser — log in as TRP org account
supabase functions deploy send-notification --project-ref osztmrxyyrpbtnikwsps
```

## Environment Variables for the function

After deploying, add these secrets in the dashboard:
Functions → send-notification → Secrets

These are auto-available in Edge Functions (no need to set):
- SUPABASE_URL
- SUPABASE_SERVICE_ROLE_KEY

No additional secrets needed until you configure a WhatsApp/SMS provider.
When you do, the provider credentials are read from org_settings at runtime — not from function env vars.
