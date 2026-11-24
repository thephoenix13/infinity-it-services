import { createClient } from 'npm:@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface Payload {
  job_id: string
  org_id: string
  trigger_key: string
  customer_phone: string
  customer_name: string
  job_number: string
  status_label: string
  branch_name: string
  branch_phone?: string
  override_message?: string  // if set, skips template lookup and uses this message directly
}

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const payload: Payload = await req.json()
    const {
      job_id, org_id, trigger_key,
      customer_phone, customer_name, job_number,
      status_label, branch_name, branch_phone,
      override_message,
    } = payload

    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const supabase = createClient(supabaseUrl, serviceKey)

    // Fetch org settings
    const { data: settingsRow, error: settingsErr } = await supabase
      .from('org_settings')
      .select('settings')
      .eq('org_id', org_id)
      .single()

    if (settingsErr || !settingsRow) {
      return new Response(JSON.stringify({ error: 'Org settings not found' }), {
        status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const settings = settingsRow.settings as any
    const triggers: Record<string, { enabled: boolean; channels: string[] }> = settings.notification_triggers ?? {}
    const templates: Record<string, string> = settings.notification_templates ?? {}
    const integrations = settings.integrations ?? {}

    const trigger = triggers[trigger_key]
    if (!trigger?.enabled) {
      return new Response(JSON.stringify({ sent: 0, failed: 0, reason: 'trigger_disabled' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // Use override_message if provided (e.g. estimate with line-item breakdown),
    // otherwise interpolate the stored template.
    const message = override_message ?? (() => {
      const rawTemplate = templates[trigger_key] ?? ''
      return rawTemplate
        .replace(/\{\{customer_name\}\}/g, customer_name)
        .replace(/\{\{job_number\}\}/g, job_number)
        .replace(/\{\{status\}\}/g, status_label)
        .replace(/\{\{branch_name\}\}/g, branch_name)
        .replace(/\{\{branch_phone\}\}/g, branch_phone ?? '')
    })()

    let sent = 0
    let failed = 0

    for (const channel of (trigger.channels ?? [])) {
      let success = false
      let providerResponse: unknown = null

      try {
        if (channel === 'whatsapp') {
          const provider = integrations.whatsapp_provider
          const apiKey = integrations.whatsapp_api_key

          if (provider === 'twilio' && apiKey) {
            const [accountSid, authToken] = apiKey.split(':')
            const body = new URLSearchParams({
              From: 'whatsapp:+14155238886',
              To: `whatsapp:+91${customer_phone}`,
              Body: message,
            })
            const resp = await fetch(
              `https://api.twilio.com/2010-04-01/Accounts/${accountSid}/Messages.json`,
              {
                method: 'POST',
                headers: {
                  Authorization: `Basic ${btoa(`${accountSid}:${authToken}`)}`,
                  'Content-Type': 'application/x-www-form-urlencoded',
                },
                body,
              }
            )
            providerResponse = await resp.json()
            success = resp.ok

          } else if (provider === '2factor' && apiKey) {
            const encoded = encodeURIComponent(message)
            const resp = await fetch(
              `https://2factor.in/API/V1/${apiKey}/WHATSAPP/${customer_phone}/AUTOGEN/${encoded}`
            )
            providerResponse = await resp.json()
            success = resp.ok
          }

        } else if (channel === 'sms') {
          const provider = integrations.sms_provider
          const apiKey = integrations.sms_api_key

          if (provider === 'twilio' && apiKey) {
            const [accountSid, authToken] = apiKey.split(':')
            const body = new URLSearchParams({
              From: Deno.env.get('TWILIO_SMS_FROM') ?? '',
              To: `+91${customer_phone}`,
              Body: message,
            })
            const resp = await fetch(
              `https://api.twilio.com/2010-04-01/Accounts/${accountSid}/Messages.json`,
              {
                method: 'POST',
                headers: {
                  Authorization: `Basic ${btoa(`${accountSid}:${authToken}`)}`,
                  'Content-Type': 'application/x-www-form-urlencoded',
                },
                body,
              }
            )
            providerResponse = await resp.json()
            success = resp.ok

          } else if (provider === '2factor' && apiKey) {
            const encoded = encodeURIComponent(message)
            const resp = await fetch(
              `https://2factor.in/API/V1/${apiKey}/SMS/${customer_phone}/${encoded}`
            )
            providerResponse = await resp.json()
            success = resp.ok
          }
        }
      } catch (e) {
        providerResponse = { error: String(e) }
        success = false
      }

      // Log to notifications_log
      await supabase.from('notifications_log').insert({
        job_id,
        org_id,
        channel,
        recipient_phone: customer_phone,
        template_key: trigger_key,
        message_body: message,
        status: success ? 'sent' : 'failed',
        provider_response: providerResponse,
        sent_at: success ? new Date().toISOString() : null,
      })

      if (success) sent++; else failed++
    }

    return new Response(JSON.stringify({ sent, failed }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })

  } catch (err) {
    return new Response(JSON.stringify({ error: String(err) }), {
      status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})
