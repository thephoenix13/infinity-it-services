// Full demo seed: branches, customers, assets, jobs, parts, notes, payments
// Run: node seed-demo-data.js
const fs = require('fs')
const envFile = fs.readFileSync('./servicedesk-app/.env.local', 'utf8')
const env = Object.fromEntries(
  envFile.split('\n').filter(l => l.includes('=')).map(l => {
    const idx = l.indexOf('=')
    return [l.slice(0, idx).trim(), l.slice(idx + 1).trim().replace(/^"(.*)"$/, '$1')]
  })
)

const SUPABASE_URL = env.NEXT_PUBLIC_SUPABASE_URL
const SERVICE_KEY  = env.SUPABASE_SERVICE_ROLE_KEY

const headers = {
  'Content-Type': 'application/json',
  'Authorization': `Bearer ${SERVICE_KEY}`,
  'apikey': SERVICE_KEY,
  'Prefer': 'return=representation',
}

async function api(method, path, body) {
  const res = await fetch(`${SUPABASE_URL}${path}`, {
    method,
    headers,
    body: body ? JSON.stringify(body) : undefined,
  })
  const text = await res.text()
  const json = text ? JSON.parse(text) : null
  if (!res.ok) throw new Error(`${path} → ${res.status}: ${text}`)
  return json
}

async function rpc(fn, params) {
  const res = await fetch(`${SUPABASE_URL}/rest/v1/rpc/${fn}`, {
    method: 'POST', headers,
    body: JSON.stringify(params),
  })
  const json = await res.json()
  if (!res.ok) throw new Error(`rpc/${fn} → ${res.status}: ${JSON.stringify(json)}`)
  return json
}

function pick(arr) { return arr[Math.floor(Math.random() * arr.length)] }
function randInt(min, max) { return Math.floor(Math.random() * (max - min + 1)) + min }
function daysAgo(n) { const d = new Date(); d.setDate(d.getDate() - n); return d.toISOString() }
function daysFromNow(n) { const d = new Date(); d.setDate(d.getDate() + n); return d.toISOString() }

async function main() {
  console.log('=== Full Demo Seed ===\n')

  // ── 1. Get org ───────────────────────────────────────────────────────────
  const orgs = await api('GET', '/rest/v1/organizations?slug=eq.infinity-it&select=id')
  const orgId = orgs[0]?.id
  if (!orgId) throw new Error('Org not found — run seed-demo.js first')
  console.log(`Org: ${orgId}`)

  // Get admin user
  const adminUsers = await api('GET', `/rest/v1/users?org_id=eq.${orgId}&role=eq.admin&select=id&limit=1`)
  const adminId = adminUsers[0]?.id
  if (!adminId) throw new Error('Admin user not found')

  // Get tech user
  const techUsers = await api('GET', `/rest/v1/users?org_id=eq.${orgId}&role=eq.technician&select=id&limit=1`)
  const techId = techUsers[0]?.id

  // ── 2. Branches ──────────────────────────────────────────────────────────
  console.log('\n1. Creating branches...')
  const branchDefs = [
    { name: 'Kothrud Branch',    address: 'Shop 4, FC Road, Kothrud, Pune 411038',          phone: '9876543210', job_prefix: 'INF' },
    { name: 'Shivajinagar',      address: 'Office 12, JM Road, Shivajinagar, Pune 411005',  phone: '9823456701', job_prefix: 'SHV' },
    { name: 'Viman Nagar',       address: 'Shop 7, Viman Nagar Main Rd, Pune 411014',        phone: '9823456702', job_prefix: 'VIM' },
    { name: 'Hinjewadi',         address: 'Phase 1, IT Park Lane, Hinjewadi, Pune 411057',  phone: '9823456703', job_prefix: 'HIN' },
  ]

  const branchIds = []
  const existingBranches = await api('GET', `/rest/v1/branches?org_id=eq.${orgId}&select=id,name`)
  const existingNames = existingBranches.map(b => b.name)

  for (const b of branchDefs) {
    const existing = existingBranches.find(e => e.name === b.name)
    if (existing) {
      branchIds.push(existing.id)
      console.log(`  ↩ ${b.name}: ${existing.id}`)
    } else {
      const rows = await api('POST', '/rest/v1/branches?select=id', {
        org_id: orgId, ...b, is_active: true,
        business_hours: {
          mon: { open: '10:00', close: '19:00', closed: false },
          tue: { open: '10:00', close: '19:00', closed: false },
          wed: { open: '10:00', close: '19:00', closed: false },
          thu: { open: '10:00', close: '19:00', closed: false },
          fri: { open: '10:00', close: '19:00', closed: false },
          sat: { open: '10:00', close: '17:00', closed: false },
          sun: { open: '10:00', close: '14:00', closed: true  },
        },
      })
      const id = rows[0]?.id ?? rows?.id
      branchIds.push(id)
      console.log(`  ✓ ${b.name}: ${id}`)
    }
  }

  // Update admin + tech to all branches
  await api('PATCH', `/rest/v1/users?id=eq.${adminId}`, { branch_ids: branchIds })
  if (techId) await api('PATCH', `/rest/v1/users?id=eq.${techId}`, { branch_ids: branchIds })

  // Also add job_number_sequences rows for each branch prefix
  console.log('  ✓ Branches assigned to admin & tech')

  // ── 3. Customers ─────────────────────────────────────────────────────────
  console.log('\n2. Creating customers...')
  const customerDefs = [
    { full_name: 'Rahul Sharma',    phone: '9812345001', email: 'rahul.sharma@gmail.com'    },
    { full_name: 'Priya Kulkarni',  phone: '9812345002', email: 'priya.kulkarni@gmail.com'  },
    { full_name: 'Amit Joshi',      phone: '9812345003', email: 'amit.joshi@yahoo.com'       },
    { full_name: 'Neha Desai',      phone: '9812345004', email: 'neha.desai@gmail.com'       },
    { full_name: 'Vikram Pawar',    phone: '9812345005', email: 'vikram.pawar@outlook.com'   },
    { full_name: 'Ananya Nair',     phone: '9812345006', email: 'ananya.nair@gmail.com'      },
    { full_name: 'Rohan Mehta',     phone: '9812345007', email: 'rohan.mehta@gmail.com'      },
    { full_name: 'Sunita Rao',      phone: '9812345008', email: 'sunita.rao@rediffmail.com'  },
    { full_name: 'Kiran Patil',     phone: '9812345009', email: 'kiran.patil@gmail.com'      },
    { full_name: 'Deepak Gupta',    phone: '9812345010', email: 'deepak.gupta@gmail.com'     },
    { full_name: 'Meera Iyer',      phone: '9812345011', email: 'meera.iyer@gmail.com'       },
    { full_name: 'Sanjay Kadam',    phone: '9812345012', email: 'sanjay.kadam@yahoo.com'     },
  ]

  const customerIds = []
  for (const c of customerDefs) {
    try {
      const rows = await api('POST', '/rest/v1/customers?select=id', {
        org_id: orgId, ...c,
      })
      const id = rows[0]?.id ?? rows?.id
      customerIds.push(id)
      console.log(`  ✓ ${c.full_name}`)
    } catch (e) {
      if (e.message.includes('unique') || e.message.includes('duplicate')) {
        const rows = await api('GET', `/rest/v1/customers?phone=eq.${c.phone}&org_id=eq.${orgId}&select=id`)
        customerIds.push(rows[0]?.id)
        console.log(`  ↩ ${c.full_name}`)
      } else throw e
    }
  }

  // ── 4. Assets ────────────────────────────────────────────────────────────
  console.log('\n3. Creating assets (laptops)...')
  const assetDefs = [
    { serial: 'SN-DELL-001', brand: 'Dell',   model: 'Inspiron 15 3511' },
    { serial: 'SN-HP-002',   brand: 'HP',     model: 'Pavilion 14' },
    { serial: 'SN-LEN-003',  brand: 'Lenovo', model: 'IdeaPad Slim 3' },
    { serial: 'SN-APL-004',  brand: 'Apple',  model: 'MacBook Air M1' },
    { serial: 'SN-ASU-005',  brand: 'Asus',   model: 'VivoBook 15' },
    { serial: 'SN-ACR-006',  brand: 'Acer',   model: 'Aspire 5' },
    { serial: 'SN-MSI-007',  brand: 'MSI',    model: 'GF63 Thin' },
    { serial: 'SN-DELL-008', brand: 'Dell',   model: 'Vostro 3520' },
    { serial: 'SN-HP-009',   brand: 'HP',     model: 'Victus 15' },
    { serial: 'SN-LEN-010',  brand: 'Lenovo', model: 'ThinkPad E14' },
    { serial: 'SN-APL-011',  brand: 'Apple',  model: 'MacBook Pro 14' },
    { serial: 'SN-ASU-012',  brand: 'Asus',   model: 'ROG Strix G15' },
  ]

  const assetIds = []
  for (let i = 0; i < assetDefs.length; i++) {
    const a = assetDefs[i]
    try {
      const rows = await api('POST', '/rest/v1/assets?select=id', {
        org_id: orgId,
        customer_id: customerIds[i],
        field_values: { serial: a.serial, brand: a.brand, model: a.model },
      })
      assetIds.push(rows[0]?.id ?? rows?.id)
    } catch (e) {
      if (e.message.includes('unique') || e.message.includes('duplicate')) {
        const rows = await api('GET', `/rest/v1/assets?customer_id=eq.${customerIds[i]}&select=id&limit=1`)
        assetIds.push(rows[0]?.id)
      } else throw e
    }
  }
  console.log(`  ✓ ${assetIds.length} assets created`)

  // ── 5. Jobs ──────────────────────────────────────────────────────────────
  console.log('\n4. Creating jobs in various statuses...')

  // Status map with created_at offsets (days ago) and estimated_delivery offsets (from now)
  const jobDefs = [
    { idx: 0,  status: 'delivered',     category: 'Screen Damage',    accessories: ['Charger'],          parts_cost: 4500, labour: 500,  paid: 5000, created: 20, delivery: -2,  note: 'Screen replaced successfully. Customer satisfied.' },
    { idx: 1,  status: 'ready',         category: 'Battery Issue',    accessories: ['Charger', 'Mouse'], parts_cost: 2800, labour: 300,  paid: 2000, created: 8,  delivery: 0,   note: 'New battery fitted. Ready for pickup.' },
    { idx: 2,  status: 'in_service',    category: 'Motherboard',      accessories: ['Charger'],          parts_cost: 8500, labour: 1000, paid: 0,    created: 5,  delivery: 7,   note: 'Motherboard replaced. Testing in progress.' },
    { idx: 3,  status: 'parts',         category: 'Charging Port',    accessories: [],                   parts_cost: 1200, labour: 400,  paid: 0,    created: 4,  delivery: 5,   note: 'Waiting for USB-C port from supplier.' },
    { idx: 4,  status: 'approved',      category: 'RAM/Storage',      accessories: ['Charger', 'Bag'],   parts_cost: 3500, labour: 500,  paid: 0,    created: 3,  delivery: 4,   note: 'Customer approved estimate. Ordered 16GB RAM.' },
    { idx: 5,  status: 'estimate_sent', category: 'Hinge',            accessories: [],                   parts_cost: 2200, labour: 800,  paid: 0,    created: 2,  delivery: 5,   note: 'Estimate sent to customer via WhatsApp.' },
    { idx: 6,  status: 'inspection',    category: 'Keyboard',         accessories: ['Charger'],          parts_cost: 1800, labour: 200,  paid: 0,    created: 2,  delivery: 4,   note: 'Keyboard not responding. Spill damage suspected.' },
    { idx: 7,  status: 'received',      category: 'Overheating',      accessories: ['Charger', 'Mouse'], parts_cost: 0,    labour: 0,    paid: 0,    created: 1,  delivery: 3,   note: 'Laptop overheating and shutting down.' },
    { idx: 8,  status: 'in_service',    category: 'Software/OS',      accessories: [],                   parts_cost: 0,    labour: 800,  paid: 500,  created: 3,  delivery: 2,   note: 'Windows reinstall and driver updates in progress.' },
    { idx: 9,  status: 'delivered',     category: 'Screen Damage',    accessories: ['Charger'],          parts_cost: 6200, labour: 600,  paid: 6800, created: 15, delivery: -5,  note: 'MacBook screen replaced. Customer collected.' },
    { idx: 10, status: 'ready',         category: 'Battery Issue',    accessories: ['Charger'],          parts_cost: 3200, labour: 400,  paid: 1500, created: 6,  delivery: 1,   note: 'Battery swollen, replaced. Fully tested.' },
    { idx: 11, status: 'received',      category: 'Other',            accessories: ['Bag'],              parts_cost: 0,    labour: 0,    paid: 0,    created: 0,  delivery: 5,   note: 'GPU issue suspected. Detailed diagnosis pending.' },
  ]

  const jobIds = []
  for (const j of jobDefs) {
      const branchId = branchIds[j.idx % branchIds.length]
      const rows = await api('POST', '/rest/v1/jobs?select=id,job_number', {
        org_id: orgId,
        branch_id: branchId,
        customer_id: customerIds[j.idx],
        asset_id: assetIds[j.idx],
        status: j.status,
        issue_category: j.category,
        issue_description: j.note,
        accessories_received: j.accessories,
        assigned_tech_id: techId ?? null,
        estimated_delivery: daysFromNow(j.delivery),
        estimate_total: j.parts_cost + j.labour,
        created_by: adminId,
      })
      const jobId = rows[0]?.id ?? rows?.id
      const jobNum = rows[0]?.job_number ?? rows?.job_number
      jobIds.push(jobId)

      // Status log entries (simulate progression)
      const statusFlow = {
        received:      ['received'],
        inspection:    ['received', 'inspection'],
        estimate_sent: ['received', 'inspection', 'estimate_sent'],
        approved:      ['received', 'inspection', 'estimate_sent', 'approved'],
        parts:         ['received', 'inspection', 'estimate_sent', 'approved', 'parts'],
        in_service:    ['received', 'inspection', 'estimate_sent', 'approved', 'in_service'],
        ready:         ['received', 'inspection', 'estimate_sent', 'approved', 'in_service', 'ready'],
        delivered:     ['received', 'inspection', 'estimate_sent', 'approved', 'in_service', 'ready', 'delivered'],
      }
      const flow = statusFlow[j.status] ?? ['received']
      for (let s = 1; s < flow.length; s++) {
        await api('POST', '/rest/v1/job_status_log', {
          job_id: jobId, org_id: orgId,
          from_status: flow[s - 1], to_status: flow[s],
          changed_by: adminId,
          notes: s === flow.length - 1 ? j.note : null,
        })
      }

      // Parts
      if (j.parts_cost > 0) {
        await api('POST', '/rest/v1/job_parts', {
          job_id: jobId, org_id: orgId,
          item_name: `Replacement ${j.category.split('/')[0].trim()} Component`,
          quantity: 1, unit_cost: j.parts_cost, is_labour: false, created_by: adminId,
        })
      }
      if (j.labour > 0) {
        await api('POST', '/rest/v1/job_parts', {
          job_id: jobId, org_id: orgId,
          item_name: 'Labour Charges',
          quantity: 1, unit_cost: j.labour, is_labour: true, created_by: adminId,
        })
      }

      // Note
      await api('POST', '/rest/v1/job_notes', {
        job_id: jobId, org_id: orgId,
        note: j.note, created_by: adminId,
      })

      // Invoice (for ready/delivered)
      if (['ready', 'delivered'].includes(j.status) && (j.parts_cost + j.labour) > 0) {
        await api('POST', '/rest/v1/invoices', {
          job_id: jobId, org_id: orgId,
          parts_total: j.parts_cost, labour_total: j.labour,
          subtotal: j.parts_cost + j.labour, total: j.parts_cost + j.labour,
          generated_by: adminId,
        }).catch(() => {}) // ignore duplicate
      }

      // Payment
      if (j.paid > 0) {
        await api('POST', '/rest/v1/payments', {
          job_id: jobId, org_id: orgId,
          amount: j.paid, mode: pick(['cash', 'upi', 'card']),
          reference: j.paid >= (j.parts_cost + j.labour) ? null : 'Partial payment',
          notes: null, recorded_by: adminId,
        })
      }

      console.log(`  ✓ ${jobNum} — ${customerDefs[j.idx].full_name} — ${j.status}`)
  }

  // ── 6. Portal tokens ──────────────────────────────────────────────────────
  console.log('\n5. Ensuring portal tokens...')
  for (const jobId of jobIds.slice(0, 6)) {
    try {
      await api('POST', '/rest/v1/portal_tokens', {
        job_id: jobId, org_id: orgId,
      })
    } catch (e) { /* already exists */ }
  }
  console.log('  ✓ Portal tokens created')

  // ── Summary ───────────────────────────────────────────────────────────────
  console.log('\n─────────────────────────────────────────')
  console.log('✓ DEMO SEED COMPLETE\n')
  console.log(`Branches   : ${branchIds.length} (Kothrud, Shivajinagar, Viman Nagar, Hinjewadi)`)
  console.log(`Customers  : ${customerIds.length}`)
  console.log(`Jobs       : ${jobDefs.length} across all statuses`)
  console.log('\nStatus breakdown:')
  const counts = {}
  jobDefs.forEach(j => { counts[j.status] = (counts[j.status] || 0) + 1 })
  Object.entries(counts).forEach(([s, n]) => console.log(`  ${s.padEnd(16)}: ${n}`))
  console.log('\nApp: http://localhost:3000')
  console.log('─────────────────────────────────────────\n')
}

main().catch(e => { console.error('\n✗ Error:', e.message); process.exit(1) })
