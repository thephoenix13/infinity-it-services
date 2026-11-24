from reportlab.lib.pagesizes import A4
from reportlab.lib.units import mm
from reportlab.lib import colors
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.enums import TA_LEFT, TA_CENTER, TA_RIGHT
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle,
    HRFlowable, KeepTogether
)
from reportlab.platypus.flowables import Flowable
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
import os

# ── Colours ──────────────────────────────────────────────────────────────────
NAVY     = colors.HexColor("#0f1f3d")
BLUE     = colors.HexColor("#1a56db")
BLUE_LT  = colors.HexColor("#eff6ff")
TEAL     = colors.HexColor("#0694a2")
AMBER    = colors.HexColor("#d97706")
AMBER_LT = colors.HexColor("#fffbeb")
GREEN    = colors.HexColor("#057a55")
GREEN_LT = colors.HexColor("#e8f5e9")
PURPLE   = colors.HexColor("#7c3aed")
PURPLE_LT= colors.HexColor("#f3e8ff")
INK      = colors.HexColor("#111827")
MUTED    = colors.HexColor("#6b7280")
SUBTLE   = colors.HexColor("#9ca3af")
BORDER   = colors.HexColor("#e5e7eb")
SAND     = colors.HexColor("#f9fafb")
WHITE    = colors.white
ORANGE_LT= colors.HexColor("#fff7ed")
INDIGO_LT= colors.HexColor("#eef2ff")

# ── Styles ────────────────────────────────────────────────────────────────────
def S(name, **kw):
    base = dict(fontName="Helvetica", fontSize=10, leading=14,
                textColor=INK, spaceAfter=0, spaceBefore=0)
    base.update(kw)
    return ParagraphStyle(name, **base)

sEyebrow   = S("eyebrow", fontName="Helvetica-Bold", fontSize=8,
               textColor=BLUE, spaceAfter=3, letterSpacing=1.2)
sH1        = S("h1", fontName="Helvetica-Bold", fontSize=26,
               textColor=WHITE, leading=32, spaceAfter=6)
sH1Sub     = S("h1sub", fontSize=11, textColor=colors.HexColor("#ffffff99"),
               leading=16, spaceAfter=12)
sH2        = S("h2", fontName="Helvetica-Bold", fontSize=16,
               textColor=NAVY, leading=20, spaceAfter=4)
sLead      = S("lead", fontSize=10, textColor=MUTED, leading=15, spaceAfter=16)
sBody      = S("body", fontSize=9.5, textColor=MUTED, leading=14, spaceAfter=4)
sBullet    = S("bullet", fontSize=9.5, textColor=MUTED, leading=13,
               leftIndent=10, firstLineIndent=0, spaceAfter=3)
sModTitle  = S("modtitle", fontName="Helvetica-Bold", fontSize=10,
               textColor=NAVY, spaceAfter=2)
sLabel     = S("label", fontName="Helvetica-Bold", fontSize=7.5,
               textColor=MUTED, letterSpacing=0.8, spaceAfter=2)
sCostAmt   = S("costamt", fontName="Helvetica-Bold", fontSize=10,
               textColor=BLUE)
sCostNote  = S("costnote", fontSize=8.5, textColor=MUTED, leading=12)
sRoleTitle = S("roletitle", fontName="Helvetica-Bold", fontSize=11,
               textColor=WHITE, spaceAfter=1)
sRoleSub   = S("rolesub", fontSize=8.5, textColor=colors.HexColor("#ffffffaa"),
               spaceAfter=0)
sNotifTrig = S("notiftrig", fontName="Helvetica-Bold", fontSize=7.5,
               textColor=MUTED, letterSpacing=0.5, spaceAfter=2)
sNotifMsg  = S("notifmsg", fontName="Helvetica-Oblique", fontSize=8.5,
               textColor=INK, leading=13, backColor=SAND)
sFooter    = S("footer", fontSize=8, textColor=SUBTLE, alignment=TA_CENTER)
sCallout   = S("callout", fontSize=9, textColor=colors.HexColor("#1e40af"),
               leading=13)
sTableHd   = S("tablehd", fontName="Helvetica-Bold", fontSize=7.5,
               textColor=WHITE, letterSpacing=0.5)
sTableSvc  = S("tablesvc", fontName="Helvetica-Bold", fontSize=9, textColor=INK)
sTableBill = S("tablebill", fontSize=8.5, textColor=MUTED)

PW, PH = A4
ML = MR = 18*mm
MT = 14*mm
MB = 16*mm
CW = PW - ML - MR

# ── Helper flowables ──────────────────────────────────────────────────────────
def div(h=6): return Spacer(1, h)
def hr(c=BORDER, t=0.5): return HRFlowable(width="100%", thickness=t, color=c, spaceAfter=0, spaceBefore=0)

def bullet_item(text):
    return Paragraph(f"<bullet bulletIndent='0' bulletOffsetY='1'>·</bullet> {text}", sBullet)

# ── Hero banner ───────────────────────────────────────────────────────────────
class HeroBanner(Flowable):
    def __init__(self, w, h=62*mm):
        super().__init__()
        self.w = w
        self.h = h

    def wrap(self, *_): return self.w, self.h

    def draw(self):
        c = self.canv
        c.setFillColor(NAVY)
        c.rect(0, 0, self.w, self.h, fill=1, stroke=0)

        # decorative circles
        c.setStrokeColor(colors.HexColor("#60a5fa22"))
        c.setLineWidth(0.6)
        for r in [140, 100, 60]:
            c.circle(self.w + 10, self.h + 10, r, fill=0, stroke=1)

        # badge pill
        bx, by = 0, self.h - 22*mm
        c.setFillColor(colors.HexColor("#1a56db33"))
        c.roundRect(0, by, 68, 14, 7, fill=1, stroke=0)
        c.setFillColor(colors.HexColor("#93c5fd"))
        c.setFont("Helvetica-Bold", 6.5)
        c.drawString(8, by + 4, "SOLUTION BRIEF")

        # h1
        c.setFillColor(WHITE)
        c.setFont("Helvetica-Bold", 22)
        c.drawString(0, self.h - 36*mm, "Laptop Service")
        c.setFillColor(colors.HexColor("#60a5fa"))
        c.drawString(0, self.h - 44*mm, "Management Platform")

        # sub
        c.setFillColor(colors.HexColor("#ffffff88"))
        c.setFont("Helvetica", 9)
        sub = ("A centralised web platform for a 7-branch laptop servicing agency — "
               "from customer intake to job closure,")
        sub2 = "with real-time tracking and automated customer notifications."
        c.drawString(0, self.h - 52*mm, sub)
        c.drawString(0, self.h - 57*mm, sub2)


# ── Section heading helper ────────────────────────────────────────────────────
def section_heading(eyebrow, title, lead=None):
    items = [
        Paragraph(eyebrow.upper(), sEyebrow),
        Paragraph(title, sH2),
    ]
    if lead:
        items.append(Paragraph(lead, sLead))
    else:
        items.append(div(8))
    return items


# ── Coloured badge row (workflow steps) ──────────────────────────────────────
STEP_COLORS = [BLUE_LT, PURPLE_LT, ORANGE_LT, INDIGO_LT,
               AMBER_LT, colors.HexColor("#e0f7fa"),
               GREEN_LT, colors.HexColor("#fce7f3")]
STEP_ICONS  = ["📋","🔖","🔍","💬","🔧","✅","💳","📦"]
STEP_LABELS = [
    "Customer\nIntake", "Job Sheet\nCreated", "Inspection",
    "Estimate &\nApproval", "Service\nin Progress", "Work\nComplete",
    "Payment\nCollected", "Device\nHanded Over"
]
STEP_SUBS = [
    "Device + issue\nlogged", "Auto number\n+ receipt", "Parts + photos\nof damage",
    "Customer\napproves cost", "Assigned to\ntechnician", "Post-service\nphotos added",
    "Invoice\ngenerated", "Job sheet\nclosed"
]

def workflow_table(w):
    cell_w = w / 8
    data = [[],[],[]]
    for i in range(8):
        icon_p = Paragraph(f"<font size='14'>{STEP_ICONS[i]}</font>",
                           S(f"ic{i}", alignment=TA_CENTER))
        lbl_p  = Paragraph(STEP_LABELS[i].replace("\n","<br/>"),
                           S(f"lb{i}", fontName="Helvetica-Bold", fontSize=7.5,
                             textColor=INK, alignment=TA_CENTER, leading=10))
        sub_p  = Paragraph(STEP_SUBS[i].replace("\n","<br/>"),
                           S(f"sb{i}", fontSize=6.5, textColor=MUTED,
                             alignment=TA_CENTER, leading=9))
        data[0].append(icon_p)
        data[1].append(lbl_p)
        data[2].append(sub_p)

    col_ws = [cell_w]*8
    t = Table(data, colWidths=col_ws, rowHeights=[22, 18, 16])
    style = [
        ("ALIGN", (0,0), (-1,-1), "CENTER"),
        ("VALIGN", (0,0), (-1,-1), "MIDDLE"),
        ("TOPPADDING",  (0,0), (-1,-1), 4),
        ("BOTTOMPADDING",(0,0),(-1,-1), 4),
        ("LEFTPADDING", (0,0), (-1,-1), 2),
        ("RIGHTPADDING",(0,0), (-1,-1), 2),
        ("LINEAFTER", (0,0), (6,0), 0.5, BORDER),
        ("BOX", (0,0), (-1,-1), 0.5, BORDER),
        ("ROWBACKGROUNDS", (0,0), (-1,-1), [SAND, WHITE, SAND]),
    ]
    for i, bg in enumerate(STEP_COLORS):
        style.append(("BACKGROUND", (i,0), (i,0), bg))
    t.setStyle(TableStyle(style))
    return t


# ── Module card ───────────────────────────────────────────────────────────────
def mod_card(icon, title, bullets, bg=BLUE_LT, w=None):
    if w is None:
        w = CW / 2 - 3*mm

    head = Table(
        [[Paragraph(icon, S("mi", fontSize=14, alignment=TA_CENTER)),
          Paragraph(title, sModTitle)]],
        colWidths=[22, w - 22],
        rowHeights=[24]
    )
    head.setStyle(TableStyle([
        ("BACKGROUND", (0,0), (-1,-1), bg),
        ("VALIGN", (0,0), (-1,-1), "MIDDLE"),
        ("LEFTPADDING", (0,0), (0,0), 6),
        ("LEFTPADDING", (1,0), (1,0), 6),
        ("RIGHTPADDING",(0,0),(-1,-1), 6),
        ("TOPPADDING",  (0,0),(-1,-1), 4),
        ("BOTTOMPADDING",(0,0),(-1,-1),4),
        ("LINEBELOW", (0,0),(-1,0), 0.5, BORDER),
    ]))

    body_items = [head]
    for b in bullets:
        body_items.append(Paragraph(f"· {b}", sBullet))
    body_items.append(div(6))

    inner = Table([[body_items]], colWidths=[w])
    inner.setStyle(TableStyle([
        ("BOX", (0,0),(-1,-1), 0.5, BORDER),
        ("BACKGROUND",(0,0),(-1,-1), WHITE),
        ("TOPPADDING",  (0,0),(-1,-1), 0),
        ("BOTTOMPADDING",(0,0),(-1,-1),0),
        ("LEFTPADDING", (0,0),(-1,-1), 0),
        ("RIGHTPADDING",(0,0),(-1,-1), 0),
        ("ROUNDEDCORNERS", [6]),
    ]))
    return inner


# ── Two-column mod grid ───────────────────────────────────────────────────────
def mod_grid(cards):
    col_w = CW / 2 - 3*mm
    rows = []
    for i in range(0, len(cards), 2):
        left  = cards[i]
        right = cards[i+1] if i+1 < len(cards) else Spacer(col_w, 1)
        rows.append([left, right])
    t = Table(rows, colWidths=[col_w, col_w], hAlign="LEFT")
    t.setStyle(TableStyle([
        ("VALIGN", (0,0),(-1,-1), "TOP"),
        ("LEFTPADDING", (0,0),(-1,-1), 0),
        ("RIGHTPADDING",(0,0),(-1,-1), 0),
        ("TOPPADDING",  (0,0),(-1,-1), 0),
        ("BOTTOMPADDING",(0,0),(-1,-1), 6*mm),
        ("COLPADDING", (1,0),(1,-1), 6),
    ]))
    return t


# ── Status flow ───────────────────────────────────────────────────────────────
STATUS = [
    ("📥","Received","#eff6ff","#bfdbfe"),
    ("🔍","Inspection","#f3e8ff","#e9d5ff"),
    ("💬","Estimate\nSent","#eef2ff","#c7d2fe"),
    ("👍","Approved","#f0fdf4","#86efac"),
    ("⏳","Awaiting\nParts","#fffbeb","#fde68a"),
    ("🔧","In Service","#e0f7fa","#a5f3fc"),
    ("✅","Ready for\nPickup","#e8f5e9","#bbf7d0"),
    ("📦","Delivered","#f0fdf4","#86efac"),
]

def status_table(w):
    cell_w = w / 8
    icons = [[Paragraph(f"<font size='13'>{s[0]}</font>",
                        S(f"sti{i}", alignment=TA_CENTER)) for i,s in enumerate(STATUS)]]
    labels= [[Paragraph(s[1].replace("\n","<br/>"),
                        S(f"stl{i}", fontSize=7, fontName="Helvetica-Bold",
                          alignment=TA_CENTER, leading=9, textColor=INK))
              for i,s in enumerate(STATUS)]]
    data  = icons + labels
    t = Table(data, colWidths=[cell_w]*8, rowHeights=[24, 18])
    style = [
        ("ALIGN", (0,0),(-1,-1),"CENTER"),
        ("VALIGN",(0,0),(-1,-1),"MIDDLE"),
        ("BOX",   (0,0),(-1,-1), 0.5, BORDER),
        ("GRID",  (0,0),(-1,-1), 0.3, BORDER),
        ("TOPPADDING",   (0,0),(-1,-1), 4),
        ("BOTTOMPADDING",(0,0),(-1,-1), 4),
    ]
    for i, s in enumerate(STATUS):
        style.append(("BACKGROUND", (i,0),(i,0), colors.HexColor(s[2])))
        style.append(("BACKGROUND", (i,1),(i,1), SAND))
    t.setStyle(TableStyle(style))
    return t


# ── Notification row ──────────────────────────────────────────────────────────
def notif_row(icon, trigger, msg, bg):
    trigger_p = Paragraph(trigger.upper(), sNotifTrig)
    msg_p     = Paragraph(msg, sNotifMsg)
    inner = Table([[trigger_p],[msg_p]], colWidths=[CW - 38])
    inner.setStyle(TableStyle([
        ("TOPPADDING",  (0,0),(-1,-1), 2),
        ("BOTTOMPADDING",(0,0),(-1,-1),2),
        ("LEFTPADDING", (0,0),(-1,-1), 0),
        ("RIGHTPADDING",(0,0),(-1,-1), 0),
    ]))
    icon_p = Paragraph(f"<font size='16'>{icon}</font>",
                       S("ni", alignment=TA_CENTER))
    row = Table([[icon_p, inner]], colWidths=[34, CW - 34])
    row.setStyle(TableStyle([
        ("BACKGROUND", (0,0),(-1,-1), WHITE),
        ("BOX",        (0,0),(-1,-1), 0.5, BORDER),
        ("VALIGN",     (0,0),(-1,-1), "TOP"),
        ("LEFTPADDING",(0,0),(0,0),   8),
        ("RIGHTPADDING",(0,0),(-1,-1),8),
        ("TOPPADDING", (0,0),(-1,-1), 8),
        ("BOTTOMPADDING",(0,0),(-1,-1),8),
        ("BACKGROUND", (0,0),(0,0), bg),
    ]))
    return row


# ── Role card ─────────────────────────────────────────────────────────────────
def role_card(icon, name, sub, bullets, head_color, w=None):
    if w is None:
        w = CW / 2 - 3*mm

    head = Table(
        [[Paragraph(f"<font size='18'>{icon}</font>",
                    S("rih", fontSize=18, alignment=TA_CENTER, textColor=WHITE)),
          [Paragraph(name, sRoleTitle), Paragraph(sub, sRoleSub)]]],
        colWidths=[30, w - 30], rowHeights=[36]
    )
    head.setStyle(TableStyle([
        ("BACKGROUND", (0,0),(-1,-1), head_color),
        ("VALIGN",     (0,0),(-1,-1), "MIDDLE"),
        ("LEFTPADDING",(0,0),(0,0),   8),
        ("LEFTPADDING",(1,0),(1,0),   8),
        ("RIGHTPADDING",(0,0),(-1,-1),8),
        ("TOPPADDING", (0,0),(-1,-1), 6),
        ("BOTTOMPADDING",(0,0),(-1,-1),6),
    ]))

    body = [head]
    for b in bullets:
        body.append(Paragraph(f"· {b}", sBullet))
    body.append(div(6))

    inner = Table([[body]], colWidths=[w])
    inner.setStyle(TableStyle([
        ("BOX",        (0,0),(-1,-1), 0.5, BORDER),
        ("BACKGROUND", (0,0),(-1,-1), WHITE),
        ("TOPPADDING", (0,0),(-1,-1), 0),
        ("BOTTOMPADDING",(0,0),(-1,-1),0),
        ("LEFTPADDING", (0,0),(-1,-1), 0),
        ("RIGHTPADDING",(0,0),(-1,-1), 0),
    ]))
    return inner


# ── Cost table ────────────────────────────────────────────────────────────────
def cost_table(rows, w):
    col_ws = [w*0.28, w*0.14, w*0.18, w*0.40]
    headers = ["Service", "Billed", "Annual Cost", "Notes"]
    data = [[Paragraph(h, sTableHd) for h in headers]]
    for svc, bill, amt, note in rows:
        data.append([
            Paragraph(svc,  sTableSvc),
            Paragraph(bill, sTableBill),
            Paragraph(amt,  sCostAmt),
            Paragraph(note, sCostNote),
        ])
    t = Table(data, colWidths=col_ws, repeatRows=1)
    style = [
        ("BACKGROUND",   (0,0),(-1,0),  NAVY),
        ("ROWBACKGROUNDS",(0,1),(-1,-1), [SAND, WHITE]),
        ("BOX",          (0,0),(-1,-1),  0.5, BORDER),
        ("LINEBELOW",    (0,0),(-1,-2),  0.3, BORDER),
        ("VALIGN",       (0,0),(-1,-1),  "TOP"),
        ("TOPPADDING",   (0,0),(-1,-1),  5),
        ("BOTTOMPADDING",(0,0),(-1,-1),  5),
        ("LEFTPADDING",  (0,0),(-1,-1),  7),
        ("RIGHTPADDING", (0,0),(-1,-1),  7),
    ]
    t.setStyle(TableStyle(style))
    return t


# ── Summary bar ───────────────────────────────────────────────────────────────
def cost_summary(w):
    left  = [Paragraph("Estimated annual infrastructure cost", sLabel),
             Paragraph("<font color='#1a56db'><b>~₹92,000 – 98,000</b></font> / year",
                       S("sv1", fontSize=13, fontName="Helvetica-Bold", textColor=INK))]
    right = [Paragraph("One-time Android store registration", sLabel),
             Paragraph("<font color='#1a56db'><b>~₹2,100</b></font> one-time",
                       S("sv2", fontSize=13, fontName="Helvetica-Bold", textColor=INK))]
    t = Table([[left, right]], colWidths=[w/2, w/2])
    t.setStyle(TableStyle([
        ("BACKGROUND", (0,0),(-1,-1), NAVY),
        ("VALIGN",     (0,0),(-1,-1), "MIDDLE"),
        ("TOPPADDING", (0,0),(-1,-1), 10),
        ("BOTTOMPADDING",(0,0),(-1,-1),10),
        ("LEFTPADDING", (0,0),(-1,-1), 14),
        ("RIGHTPADDING",(0,0),(-1,-1), 14),
        ("LINEAFTER",  (0,0),(0,-1),   0.5, colors.HexColor("#ffffff22")),
        ("BOX",        (0,0),(-1,-1),  0, WHITE),
    ]))
    return t


# ── Callout box ───────────────────────────────────────────────────────────────
def callout(text, bg=BLUE_LT, border=colors.HexColor("#bfdbfe"), icon="ℹ"):
    p = Paragraph(f"<b>{icon}</b>  {text}", sCallout)
    t = Table([[p]], colWidths=[CW])
    t.setStyle(TableStyle([
        ("BACKGROUND", (0,0),(-1,-1), bg),
        ("BOX",        (0,0),(-1,-1), 0.8, border),
        ("LEFTPADDING",(0,0),(-1,-1), 10),
        ("RIGHTPADDING",(0,0),(-1,-1),10),
        ("TOPPADDING", (0,0),(-1,-1), 8),
        ("BOTTOMPADDING",(0,0),(-1,-1),8),
    ]))
    return t


# ── Report stats row ──────────────────────────────────────────────────────────
def report_stats(w):
    stats = [
        ("Live", "Open jobs across all branches, updated the moment a status changes"),
        ("7",    "Branches visible on one dashboard, filterable by branch or all at once"),
        ("∞",    "Report history retained — look back at any date, branch, or technician"),
    ]
    cells = []
    for val, lbl in stats:
        cells.append([
            Paragraph(f"<font color='#0f1f3d'><b>{val}</b></font>",
                      S("rv", fontSize=22, fontName="Helvetica-Bold",
                        textColor=NAVY, leading=26)),
            Paragraph(lbl, S("rl", fontSize=8.5, textColor=MUTED, leading=12)),
        ])
    col_w = w / 3
    t = Table([cells], colWidths=[col_w]*3)
    t.setStyle(TableStyle([
        ("BACKGROUND", (0,0),(-1,-1), WHITE),
        ("BOX",        (0,0),(-1,-1), 0.5, BORDER),
        ("LINEAFTER",  (0,0),(1,-1),  0.5, BORDER),
        ("VALIGN",     (0,0),(-1,-1), "TOP"),
        ("TOPPADDING", (0,0),(-1,-1), 10),
        ("BOTTOMPADDING",(0,0),(-1,-1),10),
        ("LEFTPADDING", (0,0),(-1,-1), 12),
        ("RIGHTPADDING",(0,0),(-1,-1), 12),
    ]))
    return t


# ─────────────────────────────────────────────────────────────────────────────
# BUILD THE PDF
# ─────────────────────────────────────────────────────────────────────────────
OUT = r"D:\Projects\laptop-service-app\Laptop_Service_Platform_Solution_Brief.pdf"

doc = SimpleDocTemplate(
    OUT, pagesize=A4,
    leftMargin=ML, rightMargin=MR, topMargin=MT, bottomMargin=MB,
    title="Laptop Service Management Platform — Solution Brief",
    author="PrakritAI",
)

story = []

# ── HERO ─────────────────────────────────────────────────────────────────────
story.append(HeroBanner(CW))
story.append(div(14))

# ── WORKFLOW ──────────────────────────────────────────────────────────────────
story += section_heading("Core Workflow", "Eight steps from intake to closure",
    "Every job follows the same lifecycle. No step can be skipped — "
    "every transition is timestamped and logged.")
story.append(workflow_table(CW))
story.append(div(8))
story.append(callout(
    "<b>Job sheet cannot be closed without payment.</b> The system enforces this — "
    "the 'Mark as Delivered' action is locked until payment is recorded.",
    bg=BLUE_LT, border=colors.HexColor("#bfdbfe")
))
story.append(div(16))
story.append(hr())

# ── MODULES ───────────────────────────────────────────────────────────────────
story.append(div(14))
story += section_heading("Platform Modules", "Everything in one system",
    "Eight core modules covering every role — front desk staff, technicians, "
    "branch managers, and head office.")

col_w = CW / 2 - 3*mm
cards = [
    mod_card("📋","Customer Intake",[
        "Customer name, phone number, email (optional)",
        "Device: brand, model, serial number",
        "Reported issue (free text + category dropdown)",
        "Accessories checklist (charger, bag, mouse, etc.)",
        "Estimated delivery date",
        "Intake staff name + branch auto-stamped",
        "Auto-generated job sheet number (e.g. JS-2026-08-00142)",
        "WhatsApp/SMS confirmation sent on creation",
    ], bg=BLUE_LT, w=col_w),
    mod_card("🔍","Inspection & Estimation",[
        "Technician opens inspection against the job sheet after intake",
        "Add parts/components — item, description, unit cost, quantity",
        "Upload photos of damage or issue at time of inspection",
        "Labour charges added separately alongside parts cost",
        "Auto-calculated total estimate with line-item breakdown",
        "Estimate shared with customer via WhatsApp/SMS with one click",
        "Customer response (Approve / Decline) logged against the job",
        "Job cannot move to In Service until approval is recorded",
    ], bg=ORANGE_LT, w=col_w),
    mod_card("🔧","Job & Technician Management",[
        "Assign job to a technician at intake or after inspection",
        "Technician updates status from their own login",
        "Internal notes per job (visible to staff, not customer)",
        "Parts used log — item, quantity, cost (pre-filled from estimate)",
        "Post-service photo upload — parts fixed, modified, or replaced",
        "Diagnosis notes and resolution summary",
        "Estimated vs actual time tracking",
        "Flag job as 'Awaiting Parts' with expected arrival date",
    ], bg=PURPLE_LT, w=col_w),
    mod_card("📊","Job Status Tracking",[
        "Status pipeline: Received → Inspection → Estimate Sent → Approved → Awaiting Parts → In Service → Ready for Pickup → Delivered",
        "Every status change timestamped and attributed to staff member",
        "Customer auto-notified at configured status milestones",
        "Overdue flag when job exceeds estimated delivery date",
        "Branch manager can override or escalate any job",
        "Search and filter by status, branch, date, technician, or customer",
    ], bg=colors.HexColor("#e0f7fa"), w=col_w),
    mod_card("💳","Payment & Invoicing",[
        "Invoice auto-generated from parts + labour at job completion",
        "Payment modes: cash, UPI, card — recorded per job",
        "Advance payment option at intake (deposit)",
        "Job delivery locked until payment is fully recorded",
        "Invoice PDF printable / shareable on WhatsApp",
        "Partial payment + balance tracking",
    ], bg=GREEN_LT, w=col_w),
    mod_card("🏢","Branch Management",[
        "Each branch has its own view — staff see only their branch's jobs",
        "Branch Manager: sees all jobs at their branch, can reassign",
        "Head Office: full view across all 7 branches simultaneously",
        "Branch-level performance comparison in reports",
        "Configurable working hours and holiday schedule per branch",
        "Branch-specific job sheet numbering prefix",
    ], bg=AMBER_LT, w=col_w),
    mod_card("👤","Customer History",[
        "Customer profile auto-created on first intake by phone number",
        "Full history of all past jobs — any branch, any device",
        "Repeat customer identified at intake — no re-entering details",
        "Device history: all past services for a specific serial number",
        "Outstanding balance flag if previous invoice unpaid",
    ], bg=colors.HexColor("#fce7f3"), w=col_w),
]
story.append(mod_grid(cards))
story.append(hr())

# ── STATUS LIFECYCLE ──────────────────────────────────────────────────────────
story.append(div(14))
story += section_heading("Job Status Lifecycle", "Eight statuses, every transition logged",
    "Staff update status from their device. Every change is instant across all branches "
    "and triggers the appropriate customer notification.")
story.append(status_table(CW))
story.append(div(8))
story.append(callout(
    "<b>Awaiting Parts</b> is optional — jobs can move directly from Approved to In Service "
    "if parts are available. <b>Approved</b> is a hard gate — no technician can move a job "
    "to In Service without a recorded customer approval against the inspection estimate.",
    bg=BLUE_LT, border=colors.HexColor("#bfdbfe")
))
story.append(div(16))
story.append(hr())

# ── NOTIFICATIONS ─────────────────────────────────────────────────────────────
story.append(div(14))
story += section_heading("Customer Notifications",
    "Automated WhatsApp / SMS — zero manual effort",
    "Customers receive updates at key moments without staff having to remember to send them.")

notifs = [
    ("📋", "Trigger: Job created", BLUE_LT,
     "Hi Ramesh, your laptop (Dell Inspiron, SN: DL2024819) has been received at our Kothrud branch. "
     "Your Job ID is JS-2026-08-00142. We'll keep you updated. — TechFix Service"),
    ("💬", "Trigger: Estimate shared (status → Estimate Sent)", INDIGO_LT,
     "Hi Ramesh, inspection of your laptop (JS-2026-08-00142) is complete. "
     "Estimated repair cost: ₹2,200 (Screen replacement: ₹1,800 + Labour: ₹400). "
     "Reply YES to approve or call us at 9876543210. — TechFix Service"),
    ("🔧", "Trigger: Work begins (status → In Service)", colors.HexColor("#e0f7fa"),
     "Hi Ramesh, our technician has started working on your laptop (JS-2026-08-00142). "
     "Expected completion: Today by 6 PM. We'll notify you when it's ready. — TechFix Service"),
    ("✅", "Trigger: Status → Ready for Pickup", GREEN_LT,
     "Great news, Ramesh! Your laptop is ready for pickup at our Kothrud branch. "
     "Amount due: ₹2,200. Branch timings: 10 AM – 7 PM. Job ID: JS-2026-08-00142. — TechFix Service"),
    ("📦", "Trigger: Job closed (device handed over)", colors.HexColor("#f0fdf4"),
     "Your laptop has been delivered. Invoice: ₹2,200 paid. Thank you for choosing TechFix. "
     "For any issues within 30 days, quote Job ID JS-2026-08-00142. — TechFix Service"),
]
for icon, trigger, bg, msg in notifs:
    story.append(notif_row(icon, trigger, msg, bg))
    story.append(div(6))

story.append(div(4))
story.append(callout(
    "<b>WhatsApp Business API required</b> for automated sends. Setup takes 2–3 days "
    "and requires a dedicated business number.",
    bg=AMBER_LT, border=colors.HexColor("#fde68a"), icon="⚠"
))
story.append(div(16))
story.append(hr())

# ── REPORTS ───────────────────────────────────────────────────────────────────
story.append(div(14))
story += section_heading("Reporting & Head Office View",
    "One dashboard for all 7 branches",
    "Head Office gets a live view of every branch — no calls, no compiled Excel sheets.")
story.append(report_stats(CW))
story.append(div(10))

rf_items = [
    "Jobs by status — how many are received, in service, ready, overdue right now",
    "Revenue by branch — daily, weekly, monthly, custom date range",
    "Technician performance — jobs completed, average turnaround time per person",
    "Overdue jobs report — jobs past estimated delivery date, with aging",
    "Parts cost vs revenue — per job and rolled up by branch",
    "Customer return rate — repeat customers per branch",
    "Branch comparison — side-by-side volume and revenue across all 7 branches",
    "Export to Excel / PDF — any report, any date range, one click",
]
half = len(rf_items) // 2
left_col  = [bullet_item(i) for i in rf_items[:half]]
right_col = [bullet_item(i) for i in rf_items[half:]]
col_w2 = CW / 2 - 3*mm
rf_table = Table([[left_col, right_col]], colWidths=[col_w2, col_w2])
rf_table.setStyle(TableStyle([
    ("VALIGN",(0,0),(-1,-1),"TOP"),
    ("LEFTPADDING",(0,0),(-1,-1),0),
    ("RIGHTPADDING",(0,0),(-1,-1),0),
    ("TOPPADDING",(0,0),(-1,-1),0),
    ("BOTTOMPADDING",(0,0),(-1,-1),0),
    ("COLPADDING",(1,0),(1,-1),8),
]))
story.append(rf_table)
story.append(div(16))
story.append(hr())

# ── FEATURE & FUNCTIONALITY PLAN ─────────────────────────────────────────────
story.append(div(14))
story += section_heading("Feature & Functionality Plan",
    "What each user can do",
    "Every role gets exactly the access and tools they need — nothing more, nothing less.")

col_w3 = CW / 2 - 3*mm
role_cards_data = [
    ("🏢","Admin","Head Office", NAVY,[
        "Full cross-branch view — all jobs and all branches simultaneously",
        "User management — add/remove staff, assign roles and branches",
        "Branch configuration — numbering prefix, working hours, holiday schedule",
        "Head Office live dashboard — open jobs, overdue counts, branch status",
        "Revenue and performance reports across all 7 branches",
        "Branch comparison — side-by-side volume and revenue",
        "Override or escalate any job from any branch",
        "Export any report to Excel or PDF",
    ]),
    ("📊","Manager","Branch Manager", TEAL,[
        "Full view of all jobs at their branch",
        "Reassign or transfer jobs between technicians",
        "Override or escalate any job status at their branch",
        "Branch performance reports — daily and weekly summary",
        "Overdue job alerts and follow-up tracking",
        "Branch-level export and reporting",
        "View technician workload and open job count per person",
    ]),
    ("🔧","Engineer","Technician", AMBER,[
        "View assigned jobs and personal job queue",
        "Open and fill inspection form for each job",
        "Add parts and components with unit cost and quantity",
        "Upload damage photos during inspection",
        "Upload post-service photos on job completion",
        "Update job status from mobile app (iOS + Android)",
        "Push notifications for new assignments and escalations",
        "Mobile inspection form with direct camera capture",
    ]),
    ("🖥️","Front Desk","Intake Staff", PURPLE,[
        "Customer intake — name, phone, device details, reported issue",
        "Accessories checklist at intake (charger, bag, mouse, etc.)",
        "Auto job sheet number generated on creation",
        "Repeat customer auto-detected by phone number",
        "Assign job to a technician at intake or later",
        "Record payment — cash, UPI, card, partial or advance deposit",
        "Print or share job receipt and invoice via WhatsApp",
        "Job closure and device handover confirmation",
    ]),
    ("👤","Customer","End User", GREEN,[
        "WhatsApp/SMS confirmation on job creation with Job ID",
        "Inspection estimate received via WhatsApp with line-item breakdown",
        "Approve or decline estimate by replying on WhatsApp",
        "Notification when work begins and when device is ready",
        "Self-service tracking portal — live job status without calling",
        "View inspection photos and post-service photos via portal",
        "Approve estimate via portal (alternative to WhatsApp)",
        "Download invoice from portal",
        "Warranty period tracking and 30-day follow-up",
    ]),
]

rc_rows = []
for i in range(0, len(role_cards_data), 2):
    left_data = role_cards_data[i]
    rc_left = role_card(left_data[0], left_data[1], left_data[2],
                        left_data[4], left_data[3], w=col_w3)
    if i + 1 < len(role_cards_data):
        right_data = role_cards_data[i+1]
        rc_right = role_card(right_data[0], right_data[1], right_data[2],
                             right_data[4], right_data[3], w=col_w3)
    else:
        rc_right = Spacer(col_w3, 1)
    rc_rows.append([rc_left, rc_right])

rc_table = Table(rc_rows, colWidths=[col_w3, col_w3])
rc_table.setStyle(TableStyle([
    ("VALIGN",(0,0),(-1,-1),"TOP"),
    ("LEFTPADDING",(0,0),(-1,-1),0),
    ("RIGHTPADDING",(0,0),(-1,-1),0),
    ("TOPPADDING",(0,0),(-1,-1),0),
    ("BOTTOMPADDING",(0,0),(-1,-1),6*mm),
    ("COLPADDING",(1,0),(1,-1),6),
]))
story.append(rc_table)
story.append(hr())

# ── COSTS ─────────────────────────────────────────────────────────────────────
story.append(div(14))
story += section_heading("Deployment Costs", "What it costs to run",
    "All infrastructure is pay-as-you-go or low fixed annual fees — "
    "no large upfront commitments beyond the build itself.")

cost_rows = [
    ("Cloud Hosting",              "Annually",    "₹36,000 / yr",
     "Hosts the web application; includes CDN, SSL, and auto-scaling. Covers all branches on a single deployment."),
    ("Database, Auth & Realtime",  "Annually",    "₹30,000 / yr",
     "Postgres database, user authentication, realtime job-status sync, and storage for all inspection and service photos."),
    ("WhatsApp Business API — platform", "Annually", "₹18,000–24,000 / yr",
     "Platform licence fee for automated WhatsApp sends — estimates, job updates, and notifications."),
    ("WhatsApp — per conversation", "Usage-based", "₹0.30–0.85 / msg",
     "Utility messages ~₹0.30/window. Marketing messages ~₹0.85/window. Billed on actual usage."),
    ("Domain Name",                "Annually",    "At actuals",
     ".in domain ~₹800–1,200/yr; .com ~₹900–1,500/yr. Branch subdomains included at no extra cost."),
    ("iOS — App Store",            "Annually",    "₹8,200 / yr",
     "Apple Developer Program membership. Required to publish and maintain the app on the iOS App Store."),
    ("Android — Play Store",       "One-time",    "₹2,100 one-time",
     "Play Console registration fee. Paid once — no annual renewal. Covers all future app updates on Android."),
]
story.append(cost_table(cost_rows, CW))
story.append(div(10))
story.append(cost_summary(CW))
story.append(div(16))

# ── FOOTER ────────────────────────────────────────────────────────────────────
story.append(hr())
story.append(div(6))
story.append(Paragraph(
    "Laptop Service Management Platform · Solution Brief · August 2026",
    sFooter
))

# ── BUILD ─────────────────────────────────────────────────────────────────────
doc.build(story)
print(f"PDF created: {OUT}")
