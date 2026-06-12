// Supabase Edge Function: Combined daily laundry report
// Sends ONE email, in operational order:
//   1. Received Today (what came back from the laundry)
//   2. Sent to Laundry Today (what the laundry company collected)
//   3. Still at Laundry (ALL not-yet-received tickets, with days-outstanding aging)
//   4. Napkin Returns
//
// Status model (renamed 2026-06-12): submitted -> approved -> sent -> received -> collected.
//
// Two modes:
//  1. Cron / no body  — fetches today's data from the DB and emails it.
//  2. Manual / POST with JSON body — uses the provided payload as-is so the email
//     matches exactly what the dashboard/tablet previewed. Body shape:
//       { receivedOrders, sentOrders, outstandingOrders, napkinReturns,
//         recipients?: string[], senderName?: string }
//     (legacy field `collectedOrders` is accepted as an alias for sentOrders)
//
// Deploy: supabase functions deploy daily-report

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const RESEND_API_KEY = Deno.env.get("RESEND_API_KEY") ?? "";

// Last-resort fallback only — the live list is the report_recipients table,
// managed from the web dashboard.
const REPORT_EMAILS = ["kunov.georgi@gmail.com", "georgi@thestratford.com", "set1000@hotmail.com"];

async function fetchRecipients(): Promise<string[]> {
  try {
    const { data } = await supabase
      .from("report_recipients")
      .select("email")
      .eq("is_active", true);
    const emails = (data ?? []).map((r: any) => r.email).filter(Boolean);
    if (emails.length > 0) return emails;
  } catch (e) {
    console.error("fetchRecipients failed, using fallback:", e);
  }
  return REPORT_EMAILS;
}

// Aging escalation for not-received tickets (normal turnaround is 1-2 days)
const AGING_AMBER_DAYS = 3;
const AGING_RED_DAYS = 7;

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);

// ── Helper: send an email via Resend ──
async function sendEmail(to: string, subject: string, html: string): Promise<{ ok: boolean; error?: string }> {
  if (!RESEND_API_KEY) {
    console.error("RESEND_API_KEY not configured — skipping email to", to);
    return { ok: false, error: "RESEND_API_KEY not configured" };
  }
  const res = await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${RESEND_API_KEY}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      from: "The Stratford Laundry <noreply@hskthestratford.uk>",
      to: [to],
      subject,
      html,
    }),
  });
  if (!res.ok) {
    const err = await res.text();
    console.error(`Resend error for ${to}: ${err}`);
    return { ok: false, error: err };
  }
  return { ok: true };
}

// ── UK-timezone-aware midnight as a UTC ISO string (BST/GMT correct) ──
function getUKMidnightISO(): string {
  const now = new Date();
  const parts = new Intl.DateTimeFormat("en-GB", {
    timeZone: "Europe/London",
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).formatToParts(now);
  const y = parts.find((p) => p.type === "year")!.value;
  const m = parts.find((p) => p.type === "month")!.value;
  const d = parts.find((p) => p.type === "day")!.value;

  // Candidate: that calendar date at UTC midnight. During BST this is 01:00 UK,
  // not 00:00 UK. Read what UK calls that instant — its hour reveals the offset.
  const candidate = new Date(`${y}-${m}-${d}T00:00:00Z`);
  const ukHourAtCandidate = parseInt(
    new Intl.DateTimeFormat("en-GB", {
      timeZone: "Europe/London",
      hour: "numeric",
      hour12: false,
    }).format(candidate),
    10,
  );
  // UK midnight in UTC = candidate − offset hours.
  return new Date(candidate.getTime() - ukHourAtCandidate * 3_600_000).toISOString();
}

// ── Fetch orders that moved into a status TODAY (UK time) ──
async function fetchTodaysOrders(targetStatus: string) {
  const todayISO = getUKMidnightISO();

  const { data: logs } = await supabase
    .from("order_status_log")
    .select("order_id")
    .eq("status", targetStatus)
    .gte("created_at", todayISO);

  if (!logs || logs.length === 0) return [];

  const orderIds = [...new Set(logs.map((l: any) => l.order_id))];

  const allOrders: any[] = [];
  for (let i = 0; i < orderIds.length; i += 50) {
    const batch = orderIds.slice(i, i + 50);
    const { data } = await supabase
      .from("orders")
      .select("*, order_items(*), departments(*)")
      .in("id", batch);
    if (data) allOrders.push(...data);
  }
  return allOrders;
}

// ── Fetch today's napkin returns from linen_ledger ──
async function fetchTodaysNapkinReturns() {
  const todayISO = getUKMidnightISO();

  const { data } = await supabase
    .from("linen_ledger")
    .select("*, department:departments(name)")
    .eq("direction", "in")
    .gte("created_at", todayISO)
    .order("created_at", { ascending: false });

  return data || [];
}

// ── The not-received backlog: every order still at the laundry, with aging ──
interface OutstandingOrder {
  id: string;
  docket: string;
  department: string;
  name: string;
  days: number;
  isChild: boolean; // partial-receipt follow-up ticket
  items: { item: string; awaited: number }[];
}

async function fetchOpenSentOrders(): Promise<OutstandingOrder[]> {
  const { data } = await supabase
    .from("orders")
    .select("id, docket_number, staff_name, guest_name, parent_order_id, created_at, departments(name), order_items(item_name, quantity_sent, quantity_received), status_log:order_status_log(status, created_at)")
    .eq("status", "sent")
    .order("created_at", { ascending: true });

  return (data ?? [])
    .map((o: any) => {
      const sentLogs = (o.status_log || []).filter((l: any) => l.status === "sent");
      const since = sentLogs.length > 0
        ? sentLogs.reduce((b: any, l: any) => (new Date(l.created_at) > new Date(b.created_at) ? l : b)).created_at
        : o.created_at;
      const days = Math.max(0, Math.floor((Date.now() - new Date(since).getTime()) / 86_400_000));
      const items = (o.order_items || [])
        .map((i: any) => ({ item: i.item_name, awaited: (i.quantity_sent || 0) - (i.quantity_received ?? 0) }))
        .filter((i: { awaited: number }) => i.awaited > 0);
      return {
        id: o.id,
        docket: o.docket_number,
        department: o.departments?.name || "—",
        name: o.staff_name || o.guest_name || "—",
        days,
        isChild: !!o.parent_order_id,
        items,
      };
    })
    .filter((o: OutstandingOrder) => o.items.length > 0);
}

// ── Napkin pool exclusion ─────────────────────────────────────────────────
// Pool-tracked napkins are balanced via the linen_ledger pool (napkin section),
// so napkin lines and napkin-only tickets are excluded from the Received /
// Partially Received / Sent / Still-at-Laundry sections.
const isPoolItem = (name: string) => (name || "").toLowerCase().includes("napkin");
const nonPoolItems = (order: any) => (order.order_items || []).filter((i: any) => !isPoolItem(i.item_name));

// ── Build combined daily report HTML ──
function buildDailyReport(
  receivedOrders: any[],
  sentOrders: any[],
  outstandingOrders: OutstandingOrder[],
  napkinReturns: any[],
) {
  const today = new Date().toLocaleDateString("en-GB", { day: "numeric", month: "long", year: "numeric", timeZone: "Europe/London" });

  // Split received into full vs partial (non-pool items only); drop napkin-only tickets
  const fullReceived: any[] = [];
  const partialReceived: any[] = [];
  for (const o of receivedOrders) {
    const items = nonPoolItems(o);
    if (items.length === 0) continue;
    const isPartial = items.some((i: any) => (i.quantity_received ?? 0) < (i.quantity_sent || 0));
    (isPartial ? partialReceived : fullReceived).push(o);
  }
  const sentNonPool = sentOrders.filter((o: any) => nonPoolItems(o).length > 0);
  const outstandingFiltered = outstandingOrders
    .map((o) => ({ ...o, items: (o.items || []).filter((i) => !isPoolItem(i.item)) }))
    .filter((o) => o.items.length > 0);

  const totalOutstanding = outstandingFiltered.reduce((s, o) => s + o.items.reduce((ss, i) => ss + i.awaited, 0), 0);
  const hasOutstanding = totalOutstanding > 0;
  const hasOverdue = outstandingFiltered.some((o) => o.days >= AGING_AMBER_DAYS);

  // ── Section 1: Received Today — fully received tickets (teal) ──
  let receivedSection = "";
  if (fullReceived.length > 0) {
    let grandReceived = 0;

    const receivedRows = fullReceived.map((order: any) => {
      const items = nonPoolItems(order);
      const itemsDesc = items.map((i: any) => `${i.quantity_sent}x ${i.item_name}`).join(", ");
      const totalReceived = items.reduce((sum: number, i: any) => sum + (i.quantity_received || 0), 0);
      grandReceived += totalReceived;

      return `<tr style="border-bottom:1px solid #eee">
        <td style="padding:10px 8px;font-weight:bold">#${order.docket_number}</td>
        <td style="padding:10px 8px">${order.staff_name || order.guest_name || "—"}</td>
        <td style="padding:10px 8px">${order.departments?.name || "—"}</td>
        <td style="padding:10px 8px">${itemsDesc || "—"}</td>
        <td style="padding:10px 8px;text-align:center;font-weight:bold">${totalReceived}</td>
      </tr>`;
    }).join("");

    receivedSection = `
      <div style="background:#00838F;padding:12px 24px">
        <p style="color:white;margin:0;font-size:14px;font-weight:bold;text-align:center">
          1. Received Today — ${fullReceived.length} order${fullReceived.length !== 1 ? "s" : ""}, ${grandReceived} items, all complete ✓
        </p>
      </div>
      <div style="padding:16px 24px;background:white">
        <table style="width:100%;border-collapse:collapse;font-size:13px">
          <tr style="background:#1B2A4A;color:white">
            <th style="padding:10px 8px;text-align:left">Docket</th>
            <th style="padding:10px 8px;text-align:left">Name</th>
            <th style="padding:10px 8px;text-align:left">Department</th>
            <th style="padding:10px 8px;text-align:left">Items</th>
            <th style="padding:10px 8px;text-align:center">Received</th>
          </tr>
          ${receivedRows}
          <tr style="background:#f5f5f5;font-weight:bold">
            <td colspan="4" style="padding:10px 8px;text-align:right">Total Items</td>
            <td style="padding:10px 8px;text-align:center">${grandReceived}</td>
          </tr>
        </table>
      </div>`;
  } else {
    receivedSection = `
      <div style="background:#00838F;padding:12px 24px">
        <p style="color:white;margin:0;font-size:14px;font-weight:bold;text-align:center">1. Received Today</p>
      </div>
      <div style="padding:16px 24px;background:white">
        <p style="margin:0;color:#999;font-style:italic">No complete tickets received today.</p>
      </div>`;
  }

  // ── Section 2: Partially Received Today — tickets that came back short (amber) ──
  let partialSection = "";
  if (partialReceived.length > 0) {
    const partialRows = partialReceived.map((order: any) => {
      const items = nonPoolItems(order);
      const totalSent = items.reduce((s: number, i: any) => s + (i.quantity_sent || 0), 0);
      const totalReceived = items.reduce((s: number, i: any) => s + (i.quantity_received || 0), 0);
      const awaitingDesc = items
        .filter((i: any) => (i.quantity_received ?? 0) < (i.quantity_sent || 0))
        .map((i: any) => `${(i.quantity_sent || 0) - (i.quantity_received ?? 0)}x ${i.item_name}`)
        .join(", ");
      return `<tr style="border-bottom:1px solid #eee">
        <td style="padding:10px 8px;font-weight:bold">#${order.docket_number}</td>
        <td style="padding:10px 8px">${order.staff_name || order.guest_name || "—"}</td>
        <td style="padding:10px 8px">${order.departments?.name || "—"}</td>
        <td style="padding:10px 8px;text-align:center">${totalReceived} of ${totalSent}</td>
        <td style="padding:10px 8px;color:#C62828;font-weight:bold">${awaitingDesc}</td>
      </tr>`;
    }).join("");

    partialSection = `
      <div style="background:#E65100;padding:12px 24px">
        <p style="color:white;margin:0;font-size:14px;font-weight:bold;text-align:center">
          2. Partially Received Today — ${partialReceived.length} ticket${partialReceived.length !== 1 ? "s" : ""} came back short
        </p>
      </div>
      <div style="padding:16px 24px;background:#FFF8F0">
        <table style="width:100%;border-collapse:collapse;font-size:13px">
          <tr style="background:#E65100;color:white">
            <th style="padding:10px 8px;text-align:left">Docket</th>
            <th style="padding:10px 8px;text-align:left">Name</th>
            <th style="padding:10px 8px;text-align:left">Department</th>
            <th style="padding:10px 8px;text-align:center">Received</th>
            <th style="padding:10px 8px;text-align:left">Still Awaiting</th>
          </tr>
          ${partialRows}
        </table>
        <p style="margin:12px 0 0;font-size:11px;color:#999">Awaiting items stay on a follow-up ticket in the Still at Laundry list until they come back.</p>
      </div>`;
  }

  // ── Section 3: Sent to Laundry Today (orange) — napkin pool items excluded ──
  let sentSection = "";
  if (sentNonPool.length > 0) {
    const sentGrandTotal = sentNonPool.reduce((sum: number, o: any) =>
      sum + nonPoolItems(o).reduce((s: number, i: any) => s + (i.quantity_sent || 0), 0), 0);

    const sentRows = sentNonPool.map((order: any) => {
      const items = nonPoolItems(order);
      const itemsDesc = items.map((i: any) => `${i.quantity_sent}x ${i.item_name}`).join(", ");
      const totalQty = items.reduce((sum: number, i: any) => sum + (i.quantity_sent || 0), 0);
      return `<tr style="border-bottom:1px solid #eee">
        <td style="padding:10px 8px;font-weight:bold">#${order.docket_number}</td>
        <td style="padding:10px 8px">${order.staff_name || order.guest_name || "—"}</td>
        <td style="padding:10px 8px">${order.departments?.name || "—"}</td>
        <td style="padding:10px 8px">${itemsDesc || "—"}</td>
        <td style="padding:10px 8px;text-align:center;font-weight:bold">${totalQty}</td>
      </tr>`;
    }).join("");

    sentSection = `
      <div style="background:#E65100;padding:12px 24px">
        <p style="color:white;margin:0;font-size:14px;font-weight:bold;text-align:center">
          3. Sent to Laundry Today — ${sentNonPool.length} order${sentNonPool.length !== 1 ? "s" : ""}, ${sentGrandTotal} items
        </p>
      </div>
      <div style="padding:16px 24px;background:white">
        <table style="width:100%;border-collapse:collapse;font-size:13px">
          <tr style="background:#1B2A4A;color:white">
            <th style="padding:10px 8px;text-align:left">Docket</th>
            <th style="padding:10px 8px;text-align:left">Name</th>
            <th style="padding:10px 8px;text-align:left">Department</th>
            <th style="padding:10px 8px;text-align:left">Items</th>
            <th style="padding:10px 8px;text-align:center">Qty</th>
          </tr>
          ${sentRows}
          <tr style="background:#f5f5f5;font-weight:bold">
            <td colspan="4" style="padding:10px 8px;text-align:right">Total Items</td>
            <td style="padding:10px 8px;text-align:center">${sentGrandTotal}</td>
          </tr>
        </table>
      </div>`;
  } else {
    sentSection = `
      <div style="background:#E65100;padding:12px 24px">
        <p style="color:white;margin:0;font-size:14px;font-weight:bold;text-align:center">3. Sent to Laundry Today</p>
      </div>
      <div style="padding:16px 24px;background:white">
        <p style="margin:0;color:#999;font-style:italic">Nothing sent to the laundry today${sentOrders.length > 0 ? " (napkin-only tickets are pool-balanced in the napkin section)" : ""}.</p>
      </div>`;
  }

  // ── Section 4: Still at Laundry — the full not-received backlog with aging ──
  let outstandingSection = "";
  if (outstandingFiltered.length > 0) {
    const outstandingRows = outstandingFiltered.map((o, idx) => {
      const ageColour = o.days >= AGING_RED_DAYS ? "#C62828" : o.days >= AGING_AMBER_DAYS ? "#E65100" : "#666";
      const ageFlag = o.days >= AGING_RED_DAYS ? " ⚠ OVERDUE" : o.days >= AGING_AMBER_DAYS ? " ⚠" : "";
      const awaitedDesc = o.items.map((i) => `${i.awaited}x ${i.item}`).join(", ");
      return `
      <tr style="border-bottom:1px solid #eee;background:${idx % 2 === 0 ? "#fff" : "#FFF8F8"}">
        <td style="padding:8px;font-family:monospace;font-size:12px">#${o.docket}${o.isChild ? ' <span style="color:#E65100;font-size:10px">(partial)</span>' : ""}</td>
        <td style="padding:8px">${o.department}</td>
        <td style="padding:8px">${o.name}</td>
        <td style="padding:8px">${awaitedDesc}</td>
        <td style="padding:8px;text-align:center;color:${ageColour};font-weight:bold">${o.days}d${ageFlag}</td>
      </tr>`;
    }).join("");

    outstandingSection = `
      <div style="background:#C62828;padding:12px 24px">
        <p style="color:white;margin:0;font-size:14px;font-weight:bold;text-align:center">
          4. Still at Laundry — ${totalOutstanding} item${totalOutstanding !== 1 ? "s" : ""} across ${outstandingFiltered.length} ticket${outstandingFiltered.length !== 1 ? "s" : ""} not yet received
        </p>
      </div>
      <div style="padding:16px 24px;background:#FFF8F8">
        <table style="width:100%;border-collapse:collapse;font-size:13px">
          <tr style="background:#C62828;color:white">
            <th style="padding:8px;text-align:left">Docket</th>
            <th style="padding:8px;text-align:left">Department</th>
            <th style="padding:8px;text-align:left">Name</th>
            <th style="padding:8px;text-align:left">Awaiting</th>
            <th style="padding:8px;text-align:center">Days Out</th>
          </tr>
          ${outstandingRows}
        </table>
        <p style="margin:12px 0 0;font-size:11px;color:#999">Days Out = days since the ticket was sent to the laundry. ⚠ from ${AGING_AMBER_DAYS} days, ⚠ OVERDUE from ${AGING_RED_DAYS} days.</p>
      </div>`;
  } else {
    outstandingSection = `
      <div style="background:#2E7D32;padding:12px 24px">
        <p style="color:white;margin:0;font-size:14px;font-weight:bold;text-align:center">4. Still at Laundry — nothing outstanding ✓</p>
      </div>`;
  }

  // ── Section 4: Napkin Returns (purple, conditional) ──
  let napkinSection = "";
  if (napkinReturns.length > 0) {
    const napkinTotal = napkinReturns.reduce((s: number, n: any) => s + (n.quantity || 0), 0);

    const napkinRows = napkinReturns.map((n: any) => `
      <tr style="border-bottom:1px solid #eee">
        <td style="padding:8px">${n.department?.name || "—"}</td>
        <td style="padding:8px;text-align:center;font-weight:bold">${n.quantity}</td>
        <td style="padding:8px;color:#666">${n.note || "—"}</td>
      </tr>`).join("");

    napkinSection = `
      <div style="background:#6A1B9A;padding:12px 24px">
        <p style="color:white;margin:0;font-size:14px;font-weight:bold;text-align:center">
          5. Napkin Returns Today — ${napkinTotal} napkin${napkinTotal !== 1 ? "s" : ""} returned
        </p>
      </div>
      <div style="padding:16px 24px;background:white">
        <table style="width:100%;border-collapse:collapse;font-size:13px">
          <tr style="background:#6A1B9A;color:white">
            <th style="padding:8px;text-align:left">Department</th>
            <th style="padding:8px;text-align:center">Qty Returned</th>
            <th style="padding:8px;text-align:left">Note</th>
          </tr>
          ${napkinRows}
          <tr style="background:#f5f5f5;font-weight:bold">
            <td style="padding:8px">Total</td>
            <td style="padding:8px;text-align:center">${napkinTotal}</td>
            <td style="padding:8px"></td>
          </tr>
        </table>
      </div>`;
  }

  // ── Assemble full report ──
  const bannerColour = hasOverdue ? "#C62828" : hasOutstanding ? "#E65100" : "#2E7D32";
  const bannerText = hasOverdue
    ? "Action Required — Overdue Items at Laundry"
    : hasOutstanding
      ? "Items Still at Laundry"
      : "All Clear — Nothing Outstanding";

  return `
    <div style="font-family:sans-serif;max-width:750px;margin:0 auto;border:1px solid #e0e0e0;border-radius:8px;overflow:hidden">
      <div style="background:#1B2A4A;padding:24px;text-align:center">
        <h1 style="color:white;margin:0;font-size:22px;letter-spacing:2px">THE STRATFORD HOTEL</h1>
        <p style="color:#C9A84C;margin:6px 0 0;font-size:12px;letter-spacing:1px">Daily Laundry Report</p>
      </div>

      <div style="background:${bannerColour};padding:14px 24px;text-align:center">
        <h2 style="color:white;margin:0;font-size:18px">${bannerText} — ${today}</h2>
      </div>

      ${receivedSection}
      ${partialSection}
      ${sentSection}
      ${outstandingSection}
      ${napkinSection}

      <div style="background:#f5f5f5;padding:20px;text-align:center;font-size:11px;color:#999;border-top:1px solid #e0e0e0">
        The Stratford Hotel — Laundry Management System<br>
        Managed by the Housekeeping Department
      </div>
    </div>
  `;
}

interface ManualPayload {
  receivedOrders?: any[];
  sentOrders?: any[];
  /** Legacy alias for sentOrders (pre-2026-06-12 dashboards) */
  collectedOrders?: any[];
  outstandingOrders?: OutstandingOrder[];
  napkinReturns?: any[];
  recipients?: string[];
  senderName?: string;
}

async function readPayload(req: Request): Promise<ManualPayload | null> {
  if (req.method !== "POST") return null;
  try {
    const ct = req.headers.get("content-type") ?? "";
    if (!ct.includes("application/json")) return null;
    const body = await req.json();
    if (body && typeof body === "object") return body as ManualPayload;
  } catch {
    // ignore — fall through to cron mode
  }
  return null;
}

serve(async (req: Request) => {
  try {
    const payload = await readPayload(req);

    // Mode selection: payload data wins; otherwise fetch today's from DB.
    const receivedOrders = payload?.receivedOrders ?? await fetchTodaysOrders("received");
    const sentOrders = payload?.sentOrders ?? payload?.collectedOrders ?? await fetchTodaysOrders("sent");
    const outstandingOrders = payload?.outstandingOrders ?? await fetchOpenSentOrders();
    const napkinReturns = payload?.napkinReturns ?? await fetchTodaysNapkinReturns();

    const recipients = (payload?.recipients && payload.recipients.length > 0)
      ? payload.recipients
      : await fetchRecipients();

    const reportHtml = buildDailyReport(receivedOrders, sentOrders, outstandingOrders, napkinReturns);

    const today = new Date().toLocaleDateString("en-GB", { timeZone: "Europe/London" });
    // Subject counts mirror the report body: napkin pool items/tickets excluded
    const receivedReal = receivedOrders.filter((o: any) => nonPoolItems(o).length > 0);
    const partialCount = receivedReal.filter((o: any) =>
      nonPoolItems(o).some((i: any) => (i.quantity_received ?? 0) < (i.quantity_sent || 0))).length;
    const sentReal = sentOrders.filter((o: any) => nonPoolItems(o).length > 0);
    const totalOutstanding = outstandingOrders.reduce(
      (s, o) => s + (o.items || []).filter((i) => !isPoolItem(i.item)).reduce((ss, i) => ss + i.awaited, 0), 0);
    const parts: string[] = [];
    if (receivedReal.length > 0) parts.push(`${receivedReal.length} received${partialCount > 0 ? ` (${partialCount} partial)` : ""}`);
    if (sentReal.length > 0) parts.push(`${sentReal.length} sent`);
    if (totalOutstanding > 0) parts.push(`${totalOutstanding} outstanding`);
    if (napkinReturns.length > 0) parts.push(`${napkinReturns.reduce((s: number, n: any) => s + (n.quantity || 0), 0)} napkins`);

    const senderTag = payload?.senderName ? ` — sent by ${payload.senderName}` : "";
    const subject = `Daily Laundry Report — ${today}${parts.length > 0 ? ` (${parts.join(", ")})` : ""}${senderTag}`;

    const emailsSent: { to: string; ok: boolean; error?: string }[] = [];
    for (const email of recipients) {
      const result = await sendEmail(email, subject, reportHtml);
      emailsSent.push({ to: email, ok: result.ok, error: result.error });
    }

    const allOk = emailsSent.every((r) => r.ok);
    return new Response(
      JSON.stringify({ success: allOk, emails: emailsSent, mode: payload ? "manual" : "cron" }),
      { status: 200, headers: { "Content-Type": "application/json" } },
    );
  } catch (err) {
    console.error("Daily report error:", err);
    return new Response(JSON.stringify({ error: String(err) }), { status: 500 });
  }
});
