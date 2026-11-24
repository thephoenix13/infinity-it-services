// Seed demo data: auth user + org + branch + users table row
// Run: node seed-demo.js
const fs = require('fs')
const envFile = fs.readFileSync('./servicedesk-app/.env.local', 'utf8')
const env = Object.fromEntries(envFile.split('\n').filter(l => l.includes('=')).map(l => l.split('=').map((p, i) => i === 0 ? p.trim() : l.split('=').slice(1).join('=').trim())))

const SUPABASE_URL = env.NEXT_PUBLIC_SUPABASE_URL
const SERVICE_KEY  = env.SUPABASE_SERVICE_ROLE_KEY

const headers = {
  'Content-Type': 'application/json',
  'Authorization': `Bearer ${SERVICE_KEY}`,
  'apikey': SERVICE_KEY,
}

async function api(method, path, body) {
  const res = await fetch(`${SUPABASE_URL}${path}`, {
    method,
    headers: { ...headers, 'Prefer': 'return=representation' },
    body: body ? JSON.stringify(body) : undefined,
  })
  const text = await res.text()
  const json = text ? JSON.parse(text) : null
  if (!res.ok) throw new Error(`${path} → ${res.status}: ${text}`)
  return json
}

async function rpc(fn, params) {
  const res = await fetch(`${SUPABASE_URL}/rest/v1/rpc/${fn}`, {
    method: 'POST',
    headers: { ...headers, 'Prefer': 'return=representation' },
    body: JSON.stringify(params),
  })
  const json = await res.json()
  if (!res.ok) throw new Error(`rpc/${fn} → ${res.status}: ${JSON.stringify(json)}`)
  return json
}

async function main() {
  console.log('Seeding demo data...\n')

  // 1. Create auth user (admin)
  console.log('1. Creating auth user pratikgade@perfectskills.in ...')
  let adminUser
  try {
    adminUser = await api('POST', '/auth/v1/admin/users', {
      email: 'pratikgade@perfectskills.in',
      password: 'ServiceDesk@2026',
      email_confirm: true,
      user_metadata: { full_name: 'Pratik Gade' },
    })
    console.log(`   ✓ Auth user created: ${adminUser.id}`)
  } catch (e) {
    if (e.message.includes('already been registered') || e.message.includes('duplicate')) {
      // Fetch existing user
      const list = await api('GET', '/auth/v1/admin/users?email=pratikgade%40perfectskills.in')
      adminUser = list.users?.[0]
      if (!adminUser) throw new Error('Could not find existing user')
      console.log(`   ↩ User already exists: ${adminUser.id}`)
    } else throw e
  }

  // 2. Create org + org_settings + admin users row via RPC
  console.log('\n2. Creating org via create_org RPC ...')
  let orgId
  try {
    orgId = await rpc('create_org', {
      p_org_name: 'Infinity IT Services',
      p_slug: 'infinity-it',
      p_admin_user_id: adminUser.id,
      p_admin_name: 'Pratik Gade',
    })
    console.log(`   ✓ Org created: ${orgId}`)
  } catch (e) {
    // If org already exists, look it up
    if (e.message.includes('duplicate') || e.message.includes('unique')) {
      const rows = await api('GET', `/rest/v1/organizations?slug=eq.infinity-it&select=id`)
      orgId = rows[0]?.id
      if (!orgId) throw new Error('Org exists but could not find it')
      console.log(`   ↩ Org already exists: ${orgId}`)
    } else throw e
  }

  // 3. Apply laptop_repair vertical defaults to org_settings
  console.log('\n3. Applying laptop_repair vertical settings ...')
  const settings = {
    branding: {
      logo_url: null,
      primary_color: '#1a56db',
      app_name: 'Infinity IT',
    },
    contact: { phone: '9876543210', email: 'service@infinityit.in', address: 'Pune, Maharashtra' },
    vertical: 'laptop_repair',
    asset: {
      label: 'Laptop',
      label_plural: 'Laptops',
      fields: [
        { key: 'serial', label: 'Serial Number', type: 'text', required: true, is_primary_identifier: true, placeholder: 'e.g. DL2024819' },
        { key: 'brand', label: 'Brand', type: 'select', required: true, options: ['Dell', 'HP', 'Lenovo', 'Apple', 'Asus', 'Acer', 'MSI', 'Other'] },
        { key: 'model', label: 'Model', type: 'text', required: false },
      ],
    },
    issue_categories: ['Screen Damage', 'Battery Issue', 'Keyboard', 'Charging Port', 'Motherboard', 'RAM/Storage', 'Hinge', 'Software/OS', 'Overheating', 'Other'],
    accessories: ['Charger', 'Bag', 'Mouse', 'USB Hub', 'Warranty Card'],
    status_labels: {
      received: 'Received', inspection: 'Inspection', estimate_sent: 'Estimate Sent',
      approved: 'Approved', parts: 'Waiting Parts', in_service: 'In Service',
      ready: 'Ready for Pickup', delivered: 'Delivered',
    },
    payment_modes: ['cash', 'upi', 'card', 'neft', 'other'],
    overdue_threshold_hours: 72,
    notification_triggers: {
      received: { enabled: true, channels: ['whatsapp'] },
      estimate_sent: { enabled: true, channels: ['whatsapp'] },
      ready: { enabled: true, channels: ['whatsapp'] },
      delivered: { enabled: false, channels: [] },
    },
    notification_templates: {
      received: 'Hi {{customer_name}}, your laptop has been received at {{branch_name}}. Job ID: {{job_number}}. We\'ll share an estimate soon.',
      estimate_sent: 'Hi {{customer_name}}, estimate for job {{job_number}} is ready. Please contact us at {{branch_phone}} to approve.',
      ready: 'Great news {{customer_name}}! Your laptop ({{job_number}}) is ready for pickup at {{branch_name}}. Contact: {{branch_phone}}',
    },
    integrations: { whatsapp_provider: null, whatsapp_api_key: null, sms_provider: null, sms_api_key: null },
    setup_progress: { org_created: true, branch_added: true, branding_set: false, team_invited: false },
    is_live: true,
  }
  await api('PATCH', `/rest/v1/org_settings?org_id=eq.${orgId}`, { settings })
  console.log('   ✓ Settings applied')

  // 4. Create main branch
  console.log('\n4. Creating Kothrud branch ...')
  let branch
  try {
    const branches = await api('POST', '/rest/v1/branches?select=id', {
      org_id: orgId,
      name: 'Kothrud Branch',
      address: 'Shop 4, FC Road, Kothrud, Pune 411038',
      phone: '9876543210',
      job_prefix: 'INF',
      is_active: true,
      business_hours: {
        mon: { open: '10:00', close: '19:00', closed: false },
        tue: { open: '10:00', close: '19:00', closed: false },
        wed: { open: '10:00', close: '19:00', closed: false },
        thu: { open: '10:00', close: '19:00', closed: false },
        fri: { open: '10:00', close: '19:00', closed: false },
        sat: { open: '10:00', close: '17:00', closed: false },
        sun: { open: '10:00', close: '14:00', closed: false },
      },
    })
    branch = branches[0] ?? branches
    console.log(`   ✓ Branch created: ${branch.id}`)
  } catch (e) {
    if (e.message.includes('unique') || e.message.includes('duplicate')) {
      const rows = await api('GET', `/rest/v1/branches?org_id=eq.${orgId}&select=id&limit=1`)
      branch = rows[0]
      console.log(`   ↩ Branch exists: ${branch.id}`)
    } else throw e
  }

  // 5. Update admin user's branch_ids
  console.log('\n5. Assigning admin to branch ...')
  await api('PATCH', `/rest/v1/users?id=eq.${adminUser.id}`, {
    branch_ids: [branch.id],
  })
  console.log('   ✓ Done')

  // 6. Create a second user — technician
  console.log('\n6. Creating technician user ...')
  let techUser
  try {
    techUser = await api('POST', '/auth/v1/admin/users', {
      email: 'tech@infinityit.in',
      password: 'Tech@2026!',
      email_confirm: true,
      user_metadata: { full_name: 'Rajan Mehta' },
    })
    console.log(`   ✓ Tech auth user: ${techUser.id}`)
  } catch (e) {
    if (e.message.includes('already') || e.message.includes('duplicate')) {
      const list = await api('GET', '/auth/v1/admin/users?email=tech%40infinityit.in')
      techUser = list.users?.[0]
      console.log(`   ↩ Tech user exists: ${techUser?.id}`)
    } else throw e
  }

  if (techUser) {
    try {
      await api('POST', '/rest/v1/users', {
        id: techUser.id,
        org_id: orgId,
        full_name: 'Rajan Mehta',
        role: 'technician',
        branch_ids: [branch.id],
        is_active: true,
      })
      console.log('   ✓ Tech users row created')
    } catch (e) {
      console.log(`   ↩ Tech users row: ${e.message.slice(0, 60)}`)
    }
  }

  // 7. Create a front desk user
  console.log('\n7. Creating front desk user ...')
  let fdUser
  try {
    fdUser = await api('POST', '/auth/v1/admin/users', {
      email: 'frontdesk@infinityit.in',
      password: 'Desk@2026!',
      email_confirm: true,
      user_metadata: { full_name: 'Sneha Patil' },
    })
    console.log(`   ✓ FD auth user: ${fdUser.id}`)
  } catch (e) {
    if (e.message.includes('already') || e.message.includes('duplicate')) {
      const list = await api('GET', '/auth/v1/admin/users?email=frontdesk%40infinityit.in')
      fdUser = list.users?.[0]
      console.log(`   ↩ FD user exists: ${fdUser?.id}`)
    } else throw e
  }

  if (fdUser) {
    try {
      await api('POST', '/rest/v1/users', {
        id: fdUser.id,
        org_id: orgId,
        full_name: 'Sneha Patil',
        role: 'front_desk',
        branch_ids: [branch.id],
        is_active: true,
      })
      console.log('   ✓ FD users row created')
    } catch (e) {
      console.log(`   ↩ FD users row: ${e.message.slice(0, 60)}`)
    }
  }

  console.log('\n─────────────────────────────────────────')
  console.log('✓ SEED COMPLETE\n')
  console.log('Login credentials:')
  console.log('  Admin  → pratikgade@perfectskills.in  / ServiceDesk@2026')
  console.log('  Tech   → tech@infinityit.in           / Tech@2026!')
  console.log('  Desk   → frontdesk@infinityit.in      / Desk@2026!')
  console.log('\nApp: http://localhost:3000')
  console.log('─────────────────────────────────────────\n')
}

main().catch(e => { console.error('\n✗ Error:', e.message); process.exit(1) })
