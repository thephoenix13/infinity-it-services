// ServiceDesk — Customization Requirement Sheet Generator
// Run: node generate-req-sheet.js
// Output: ServiceDesk-Customization-Requirements.docx

const {
  Document, Packer, Paragraph, Table, TableRow, TableCell,
  HeadingLevel, TextRun, WidthType, AlignmentType, ShadingType,
  PageBreak, BorderStyle,
} = require('docx');
const fs = require('fs');

// ─── Screen Data ────────────────────────────────────────────────────────────

const SCREENS = [
  {
    name: 'Login',
    route: '/login',
    does: 'Entry point for all users. Shows role-based login for demo mode (Admin, Technician, Front Desk) and a standard Email + Password login for production. Links to platform overview and demo guide documents.',
    inputs: 'Email (text), Password (text). Demo mode: one-click role cards (Admin / Technician / Front Desk). URL query param for error messages.',
    outputs: 'Authenticates user and redirects to /dashboard. Error message shown inline on failed login. Demo mode logs in with a pre-seeded account for the selected role.',
  },
  {
    name: 'Signup / Create Workspace',
    route: '/signup',
    does: '3-step onboarding flow for new organisations registering on the platform. Creates the org and first admin account.',
    inputs: 'Step 1 — Organisation name (text), URL slug (auto-generated, editable). Step 2 — Business vertical selection (grid of options). Step 3 — Admin full name, email, password (min 8 characters).',
    outputs: 'Creates organisation + admin user in database. Redirects to /setup (post-signup wizard) on success. Inline error on failure.',
  },
  {
    name: 'Workspace Setup Wizard',
    route: '/setup',
    does: '4-step post-signup wizard run once after org creation. Configures the first branch and app branding before the team starts using the platform.',
    inputs: 'Step 1 — Welcome (read-only, shows selected vertical). Step 2 — Branch name (required), address (optional), phone (optional), job number prefix (2–4 uppercase letters, required). Step 3 — App display name (text), brand color (color picker + hex input). Step 4 — Done / confirmation screen.',
    outputs: 'Creates first branch in DB. Saves branding (display name + brand color) to org settings. Redirects to /dashboard on completion. Brand color and app name appear across all screens immediately.',
  },
  {
    name: 'Dashboard',
    route: '/dashboard',
    does: 'Main home screen after login. Shows a real-time snapshot of branch activity and quick links to key actions. Scoped to the active branch selected in the sidebar.',
    inputs: 'No form inputs. Branch context set via sidebar branch selector. Auto-refreshes on branch change.',
    outputs: '4 KPI stat cards (Open Jobs, Ready for Pickup, Overdue, Today\'s Revenue in ₹). Jobs-by-status bar chart (all 8 statuses). Quick-action links: New Job, All Jobs, Ready for Pickup, Overdue Jobs, Reports. Recent Jobs table (Job #, Customer, Status, Branch, Created Date — last 10 jobs).',
  },
  {
    name: 'Jobs List',
    route: '/jobs',
    does: 'Searchable, filterable master list of all repair jobs for the active branch/org. Starting point for finding any existing job.',
    inputs: 'Live text search (filters by job number). Status dropdown filter (All / Received / Inspection / Estimate Sent / Approved / Waiting Parts / In Service / Ready / Delivered). Branch scoped via sidebar selector. "New Job" button navigates to job creation.',
    outputs: 'Filtered job table showing: Job #, Customer name + phone, Asset identifier, Status badge, Issue category, Branch, Assigned technician, Created date. Clicking a job number navigates to Job Detail.',
  },
  {
    name: 'New Job (Create Job)',
    route: '/jobs/new',
    does: '4-step wizard to intake a new repair job. Handles customer lookup/creation, asset capture, job configuration, and a final review before submission.',
    inputs: 'Step 1 (Customer): Phone number (10-digit, required — triggers existing-customer lookup); if new customer: Full name (required), Email (optional). Step 2 (Asset): Primary identifier e.g. serial number (required), plus any custom device fields configured in Settings. Step 3 (Job Details): Branch (select — admin/manager only for multi-branch), Issue category (dropdown from org settings or free text), Issue description (textarea), Accessories received (multi-select chips from org settings), Expected delivery date (date picker), Assigned technician (select), Advance payment ₹ (number). Step 4 (Review): Summary of all data before final submit.',
    outputs: 'Creates customer record (if new), asset record, and job record in DB. Advance payment logged. Triggers WhatsApp/SMS notification to customer (if "Received" trigger is enabled in settings). Redirects to the new Job Detail screen.',
  },
  {
    name: 'Job Detail',
    route: '/jobs/[id]',
    does: 'Full management screen for a single repair job — covers the entire job lifecycle from intake to delivery. The primary workspace for technicians and managers.',
    inputs: 'Status transition buttons (each opens a confirmation modal with an optional note field). Add Part/Labour: item name, quantity, unit cost ₹, type toggle (part or labour). Add Note: free-text internal note. Payments: handled in a payment panel sub-section (amount, method). All actions are role-gated.',
    outputs: 'Displays: Job # + status badge, branch, dates, customer info card, asset info card, issue details (category + description + accessories + assigned technician). Parts & Labour table with cost totals. Internal notes feed (with author + timestamp). Status timeline / audit log (all transitions, notes, who changed it, when). Payment panel (amounts received, balance). Customer tracking portal link (token-secured URL to share via WhatsApp). WhatsApp/SMS fired on each status transition if configured.',
  },
  {
    name: 'Customers List',
    route: '/customers',
    does: 'Searchable directory of all customers in the org. Customers are created automatically during job intake — no manual add form here.',
    inputs: 'Live text search (filters by name or phone, client-side). No other inputs.',
    outputs: 'Customer table showing: Name (link to Customer Detail), Phone, Email, Joined date (date of first job). Total customer count shown above the table.',
  },
  {
    name: 'Customer Detail',
    route: '/customers/[id]',
    does: 'Profile view for a single customer showing their contact info and full job history with this org.',
    inputs: 'None — fully read-only screen.',
    outputs: 'Customer profile card (name, phone, email, join date). Complete job history table (Job #, Status, Issue Category, Created date, Expected delivery date) with links to individual job pages. Jobs sorted newest first.',
  },
  {
    name: 'Reports',
    route: '/reports',
    does: 'Analytics dashboard for branch or org-wide performance. Scoped to the active branch or all branches via the sidebar selector.',
    inputs: 'Date range selector (Last 7 days / Last 30 days / Last 90 days). Branch context from sidebar.',
    outputs: '4 summary stat cards: Total Jobs, Completed Jobs, Total Revenue (₹), Average Job Value (₹). Revenue Trend chart (daily bar chart for selected period). Jobs by Category chart (horizontal bar per issue category). By Technician table (assigned / completed / in-progress counts per technician). CSV export and advanced filters noted as planned features.',
  },
  {
    name: 'Settings — Home',
    route: '/settings',
    does: 'Navigation hub for all configuration sub-sections. Admin-only — non-admin users are redirected to the dashboard.',
    inputs: 'None (navigation only). Restricted to role = Admin.',
    outputs: '6 navigation tiles linking to: Branding, Issue Categories, Team & Users, Branches, Notifications, Organisation.',
  },
  {
    name: 'Settings — Organisation',
    route: '/settings/org',
    does: 'Lets the admin update the organisation\'s display name. Slug and active status are shown read-only.',
    inputs: 'Organisation name (text, required, editable). Slug (read-only). Status (read-only — managed by Platform Admin).',
    outputs: 'Saves updated org name to the organisations table. "Saved!" confirmation shown for 3 seconds.',
  },
  {
    name: 'Settings — Branding',
    route: '/settings/branding',
    does: 'Customises the app display name and brand color shown across all screens and the customer portal. Logo upload UI is present but marked coming soon.',
    inputs: 'App display name (text). Brand color (color picker + hex text input). Logo upload (UI present, not yet functional).',
    outputs: 'Saves app name and brand color to org settings. Live preview updates in real time (showing the button and name as they\'ll appear). Confirmation shown on save.',
  },
  {
    name: 'Settings — Issue Categories & Accessories',
    route: '/settings/categories',
    does: 'Manages two configurable lists used during job intake: (1) Issue Categories — single-select dropdown on the New Job form. (2) Accessories Received — multi-select checklist on the New Job form.',
    inputs: 'New category: text input + Enter / Add button to add. Remove (×) button per item. New accessory: same pattern.',
    outputs: 'Updates issue_categories and accessories arrays in org settings. Changes take effect immediately in the New Job wizard.',
  },
  {
    name: 'Settings — Team & Users',
    route: '/settings/team',
    does: 'Manages all staff accounts for the org. Allows admin to invite new members, assign roles and branch access, and activate or deactivate existing users.',
    inputs: '"Invite Member" button opens a modal. Modal inputs: Full name (required), Email (required), Password (min 6 chars, required), Role (Technician / Front Desk / Manager / Admin), Branch access (multi-checkbox, shown for non-admin roles). Activate / Deactivate toggle per existing user row.',
    outputs: 'Creates Supabase auth user + user record in DB with org_id, role, and branch assignments. Activate/Deactivate updates user active status. Team table refreshes on success.',
  },
  {
    name: 'Settings — Branches',
    route: '/settings/branches',
    does: 'Lists and manages all branches for the org. Admin can add new branches and enable or disable existing ones.',
    inputs: 'Add branch form: Branch name (required), Prefix (2–4 uppercase letters, required), Phone (optional), Address (optional). Enable / Disable toggle per existing branch row.',
    outputs: 'Inserts new branch into DB. Updates branch active status. Branch prefix shown formatted (e.g. KTH). New branch becomes immediately available in the sidebar branch selector.',
  },
  {
    name: 'Settings — Notifications',
    route: '/settings/notifications',
    does: 'Configures outbound WhatsApp and SMS notifications sent to customers. Three sections: Triggers (which status changes send a notification), Templates (message text per status), and Provider Setup (credentials for WhatsApp/SMS gateway).',
    inputs: 'Triggers: toggle per status (8 statuses), WhatsApp and/or SMS checkbox when toggle is on. Templates: editable textarea per status using placeholders ({{customer_name}}, {{job_number}}, {{status}}, {{branch_name}}, {{branch_phone}}). Provider Setup: provider dropdown (None / Twilio / 2Factor.in) for WhatsApp and SMS separately; API key field shown when a provider is selected.',
    outputs: 'Saves trigger config, message templates, and integration credentials to org settings. When a job status changes and the corresponding trigger is on, the Supabase Edge Function sends the configured message to the customer\'s phone.',
  },
  {
    name: 'Platform Admin — All Organisations',
    route: '/admin',
    does: 'Super-admin / operator view of the entire platform. Gated by a platform admin email env variable — no other user can access this. Shows platform-wide health and all tenant orgs.',
    inputs: 'None — read-only. Access restricted to the configured platform admin email.',
    outputs: '3 stat cards (total orgs, users, jobs platform-wide). Health banner listing inactive orgs (or "all active" if clean). Org table: name (link to detail), slug, business vertical, branch count, user count, job count, status badge, created date.',
  },
  {
    name: 'Platform Admin — Organisation Detail',
    route: '/admin/orgs/[id]',
    does: 'Detailed operator view of a single tenant organisation. Allows platform admin to inspect an org\'s branches, users, and recent jobs.',
    inputs: 'None — read-only.',
    outputs: 'Org header (name, slug, vertical, status, created date). Branches list (name, prefix, active status). Users list (name, role, active status). Recent Jobs table (last 10: Job #, status badge, created date). Debug access notice explaining that full impersonation is not yet implemented.',
  },
  {
    name: 'Customer Portal — Job Tracker',
    route: '/track/[token]',
    does: 'Public-facing, no-login page for customers to track their repair job. Accessed via a unique token link sent via WhatsApp or SMS when the job is created. Applies the org\'s branding (color + display name).',
    inputs: 'Token from the URL path. Fully read-only — no user input required.',
    outputs: 'Greeting with customer name and job number. Current status badge + next-step message. Device info section. Status timeline (newest first, with notes and timestamps). Parts & Labour estimate table (if items have been added by the technician). Branch contact info and expected delivery date in the footer. Invalid or expired token shows a "Job not found" message.',
  },
];

// ─── Helpers ─────────────────────────────────────────────────────────────────

const BLUE_DARK  = '1E4080';
const BLUE_LIGHT = 'D6E4F7';
const GREY_LABEL = 'EEF2F7';
const CUST_LABEL = 'FFF8E7';
const CUST_HEAD  = '7B4F00';
const WHITE      = 'FFFFFF';

function px(n) { return n * 20; } // points to half-points (twips approximation for font size)

function shading(fill) {
  return { fill, type: ShadingType.CLEAR, color: 'auto' };
}

function noBorders() {
  const s = { style: BorderStyle.NONE, size: 0, color: 'FFFFFF' };
  return { top: s, bottom: s, left: s, right: s, insideHorizontal: s, insideVertical: s };
}

function thinBorders() {
  const s = { style: BorderStyle.SINGLE, size: 1, color: 'CCCCCC' };
  return { top: s, bottom: s, left: s, right: s, insideHorizontal: s, insideVertical: s };
}

function cell(text, opts = {}) {
  const { fill, bold = false, color = '000000', width, colspan, fontSize = 20, italic = false } = opts;
  return new TableCell({
    shading: fill ? shading(fill) : undefined,
    width: width ? { size: width, type: WidthType.PERCENTAGE } : undefined,
    columnSpan: colspan,
    margins: { top: 80, bottom: 80, left: 120, right: 120 },
    children: [
      new Paragraph({
        children: [new TextRun({ text, bold, color, size: fontSize, italics: italic })],
      }),
    ],
  });
}

function blankCell(opts = {}) {
  const { fill, width } = opts;
  return new TableCell({
    shading: fill ? shading(fill) : undefined,
    width: width ? { size: width, type: WidthType.PERCENTAGE } : undefined,
    margins: { top: 80, bottom: 160, left: 120, right: 120 },
    children: [new Paragraph({ text: '' })],
  });
}

function sectionHeading(text) {
  return new Paragraph({
    heading: HeadingLevel.HEADING_2,
    spacing: { before: 320, after: 100 },
    children: [new TextRun({ text, color: BLUE_DARK, size: 28, bold: true })],
  });
}

function routeLabel(route) {
  return new Paragraph({
    spacing: { before: 0, after: 140 },
    children: [new TextRun({ text: `Route: ${route}`, size: 18, color: '666666', italics: true })],
  });
}

function subHeading(text, fill) {
  return new Table({
    width: { size: 100, type: WidthType.PERCENTAGE },
    borders: noBorders(),
    rows: [
      new TableRow({
        children: [
          new TableCell({
            shading: shading(fill),
            margins: { top: 60, bottom: 60, left: 120, right: 120 },
            children: [new Paragraph({
              children: [new TextRun({ text, bold: true, size: 20, color: WHITE })],
            })],
          }),
        ],
      }),
    ],
  });
}

function infoTable(screen) {
  return new Table({
    width: { size: 100, type: WidthType.PERCENTAGE },
    borders: thinBorders(),
    rows: [
      new TableRow({ children: [cell('What it does', { fill: GREY_LABEL, bold: true, width: 22 }), cell(screen.does, { width: 78 })] }),
      new TableRow({ children: [cell('Inputs', { fill: GREY_LABEL, bold: true, width: 22 }), cell(screen.inputs, { width: 78 })] }),
      new TableRow({ children: [cell('Outputs', { fill: GREY_LABEL, bold: true, width: 22 }), cell(screen.outputs, { width: 78 })] }),
    ],
  });
}

function custTable() {
  const areas = [
    'Fields / data points to add',
    'Fields / labels to modify or rename',
    'Fields to remove',
    'Workflow or process changes',
    'Access / role-level changes',
    'Other requirements or notes',
  ];
  return new Table({
    width: { size: 100, type: WidthType.PERCENTAGE },
    borders: thinBorders(),
    rows: [
      new TableRow({
        children: [
          cell('Customization Area', { fill: CUST_HEAD, bold: true, color: WHITE, width: 38, fontSize: 20 }),
          cell('Prospect\'s Requirements (please fill in)', { fill: CUST_HEAD, bold: true, color: WHITE, width: 62, fontSize: 20 }),
        ],
      }),
      ...areas.map(area =>
        new TableRow({
          children: [
            cell(area, { fill: CUST_LABEL, width: 38 }),
            blankCell({ width: 62 }),
          ],
        })
      ),
    ],
  });
}

function spacer(n = 1) {
  return Array.from({ length: n }, () => new Paragraph({ text: '', spacing: { after: 60 } }));
}

function screenSection(screen, isLast) {
  const blocks = [
    sectionHeading(`${screen.name}`),
    routeLabel(screen.route),
    infoTable(screen),
    ...spacer(1),
    subHeading('  Customization Requirements — Prospect to Fill', CUST_HEAD),
    custTable(),
  ];
  if (!isLast) {
    blocks.push(new Paragraph({ children: [new PageBreak()] }));
  }
  return blocks;
}

// ─── Document Build ──────────────────────────────────────────────────────────

const coverTable = new Table({
  width: { size: 100, type: WidthType.PERCENTAGE },
  borders: thinBorders(),
  rows: [
    new TableRow({ children: [cell('Prospect Company', { fill: GREY_LABEL, bold: true, width: 35 }), blankCell({ width: 65 })] }),
    new TableRow({ children: [cell('Prepared by', { fill: GREY_LABEL, bold: true, width: 35 }), cell('ServiceDesk Team', { width: 65 })] }),
    new TableRow({ children: [cell('Date', { fill: GREY_LABEL, bold: true, width: 35 }), cell(new Date().toLocaleDateString('en-IN', { day: '2-digit', month: 'long', year: 'numeric' }), { width: 65 })] }),
    new TableRow({ children: [cell('Version', { fill: GREY_LABEL, bold: true, width: 35 }), cell('1.0', { width: 65 })] }),
  ],
});

const instructions = [
  new Paragraph({
    spacing: { before: 300, after: 120 },
    children: [new TextRun({ text: 'How to Use This Document', bold: true, size: 24, color: BLUE_DARK })],
  }),
  new Paragraph({
    spacing: { after: 200 },
    children: [new TextRun({
      text: 'This document lists every screen in the ServiceDesk platform as it is built today. For each screen, we have documented its purpose, the data it takes as input, and what it produces as output. The shaded "Customization Requirements" table beneath each screen is for your team to fill in — please describe any fields you need added, renamed, removed, workflow changes, access changes, or other requirements specific to your business.',
      size: 20,
    })],
  }),
];

const doc = new Document({
  styles: {
    default: {
      document: {
        run: { font: 'Calibri', size: 20 },
      },
    },
  },
  sections: [
    {
      children: [
        new Paragraph({
          spacing: { before: 200, after: 80 },
          children: [new TextRun({ text: 'ServiceDesk', bold: true, size: 52, color: BLUE_DARK })],
        }),
        new Paragraph({
          spacing: { before: 0, after: 40 },
          children: [new TextRun({ text: 'Screen Customization Requirement Sheet', size: 32, color: '444444' })],
        }),
        new Paragraph({
          spacing: { before: 0, after: 300 },
          children: [new TextRun({ text: 'Platform: servicedesk-app.vercel.app', size: 20, color: '888888', italics: true })],
        }),
        coverTable,
        ...instructions,
        new Paragraph({ children: [new PageBreak()] }),
        ...SCREENS.flatMap((screen, i) => screenSection(screen, i === SCREENS.length - 1)),
      ],
    },
  ],
});

Packer.toBuffer(doc).then(buffer => {
  const out = 'ServiceDesk-Customization-Requirements.docx';
  fs.writeFileSync(out, buffer);
  console.log(`✓ Generated: ${out}`);
}).catch(err => {
  console.error('Error generating document:', err.message);
});
