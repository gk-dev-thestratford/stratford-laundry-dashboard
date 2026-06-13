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

// ── Fetch orders that moved into a status since [sinceISO] (default: today, UK) ──
// For an express follow-up send, sinceISO = the last send time, so the report
// covers only the new batch.
async function fetchTodaysOrders(targetStatus: string, sinceISO?: string) {
  const lowerBound = sinceISO || getUKMidnightISO();

  const { data: logs } = await supabase
    .from("order_status_log")
    .select("order_id")
    .eq("status", targetStatus)
    .gte("created_at", lowerBound);

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

// ── Fetch napkin returns since [sinceISO] (default: today, UK) ──
async function fetchTodaysNapkinReturns(sinceISO?: string) {
  const lowerBound = sinceISO || getUKMidnightISO();

  const { data } = await supabase
    .from("linen_ledger")
    .select("*, department:departments(name)")
    .eq("direction", "in")
    .gte("created_at", lowerBound)
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
  senderName?: string,
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
    // Exclude tickets sent TODAY (days === 0): they already appear under
    // "Sent to Laundry Today", so listing them as outstanding too would
    // double-count and wrongly flag same-day sends as overdue.
    .filter((o) => o.items.length > 0 && o.days >= 1);

  // ── KPI numbers (napkin pool excluded; outstanding already excludes today's sends) ──
  const receivedItems = [...fullReceived, ...partialReceived].reduce(
    (s, o) => s + nonPoolItems(o).reduce((ss: number, i: any) => ss + (i.quantity_received || 0), 0), 0);
  const receivedOrdersCount = fullReceived.length + partialReceived.length;
  const sentItems = sentNonPool.reduce(
    (s, o) => s + nonPoolItems(o).reduce((ss: number, i: any) => ss + (i.quantity_sent || 0), 0), 0);
  const totalOutstanding = outstandingFiltered.reduce((s, o) => s + o.items.reduce((ss, i) => ss + i.awaited, 0), 0);
  const hasOutstanding = totalOutstanding > 0;
  const napkinTotal = napkinReturns.reduce((s: number, n: any) => s + (n.quantity || 0), 0);

  const weekday = new Date().toLocaleDateString("en-GB", { weekday: "long", timeZone: "Europe/London" });
  const time = new Date().toLocaleTimeString("en-GB", { hour: "2-digit", minute: "2-digit", timeZone: "Europe/London" });

  // ── Shared styles & helpers ──
  const TH = (align: string, edge: boolean) =>
    `padding:9px ${edge ? "14px" : "8px"};font-size:10.5px;font-weight:700;color:#8A92A6;text-transform:uppercase;letter-spacing:0.4px;text-align:${align};`;
  const cardOpen = `<table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="background:#FFFFFF;border:1px solid #E6E9EF;border-radius:10px;overflow:hidden;">`;
  const cardClose = `</table>`;
  const emptyCard = (t: string) =>
    `${cardOpen}<tr><td style="padding:15px;text-align:center;font-size:12.5px;color:#A6AEBF;">${t}</td></tr>${cardClose}`;
  const stripe = (i: number) => (i % 2 === 1 ? "background:#FCFCFD;" : "");
  const C = { received: "#0E9384", partial: "#C77700", sent: "#2563EB", outstanding: "#D64545", napkin: "#7C5CBF" };

  const sectionHead = (dot: string, title: string, right: string) => `
    <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="margin:24px 0 9px;">
      <tr>
        <td style="vertical-align:middle;"><span style="display:inline-block;width:9px;height:9px;border-radius:2px;background:${dot};vertical-align:middle;"></span><span style="font-size:13px;font-weight:700;letter-spacing:0.6px;color:#1B2A4A;text-transform:uppercase;vertical-align:middle;margin-left:9px;">${title}</span></td>
        <td align="right" style="font-size:12px;color:#8A92A6;vertical-align:middle;">${right}</td>
      </tr>
    </table>`;

  const kpi = (num: string | number, label: string, sub: string, accent: string) => `
    <td width="25%" valign="top" style="padding:0 5px;">
      <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="background:#FFFFFF;border:1px solid #E6E9EF;border-radius:10px;">
        <tr><td style="height:3px;background:${accent};font-size:0;line-height:0;border-radius:10px 10px 0 0;">&nbsp;</td></tr>
        <tr><td align="center" style="padding:14px 6px 12px;">
          <div style="font-size:30px;font-weight:700;color:#1B2A4A;line-height:1;">${num}</div>
          <div style="font-size:11px;font-weight:700;letter-spacing:0.5px;color:${accent};text-transform:uppercase;margin-top:7px;">${label}</div>
          <div style="font-size:11px;color:#8A92A6;margin-top:2px;">${sub}</div>
        </td></tr>
      </table>
    </td>`;

  const dayPill = (days: number) => {
    const overdue = days >= AGING_RED_DAYS, warn = days >= AGING_AMBER_DAYS;
    const bg = overdue ? "#FBEAEA" : warn ? "#FBF1E3" : "#EEF0F4";
    const fg = overdue ? "#D64545" : warn ? "#C77700" : "#8A92A6";
    return `<span style="display:inline-block;padding:3px 9px;border-radius:11px;background:${bg};color:${fg};font-size:11.5px;font-weight:700;">${days}d${overdue ? " overdue" : ""}</span>`;
  };

  // ── Section 1: Received Today (complete tickets) ──
  let receivedSection = sectionHead(C.received, "Received Today",
    `${fullReceived.length} order${fullReceived.length !== 1 ? "s" : ""} &middot; ${fullReceived.reduce((s, o) => s + nonPoolItems(o).reduce((ss: number, i: any) => ss + (i.quantity_received || 0), 0), 0)} items`);
  if (fullReceived.length > 0) {
    const rows = fullReceived.map((order: any, idx: number) => {
      const items = nonPoolItems(order);
      const qty = items.reduce((s: number, i: any) => s + (i.quantity_received || 0), 0);
      const desc = items.map((i: any) => `${i.quantity_sent}&times; ${i.item_name}`).join(", ");
      return `<tr style="border-top:1px solid #EEF0F4;${stripe(idx)}">
        <td style="padding:11px 14px;font-size:13px;color:#1B2A4A;font-weight:700;">#${order.docket_number}</td>
        <td style="padding:11px 8px;font-size:13px;color:#2D3340;">${order.staff_name || order.guest_name || "—"}</td>
        <td style="padding:11px 8px;font-size:13px;color:#2D3340;">${order.departments?.name || "—"}</td>
        <td style="padding:11px 8px;font-size:13px;color:#5B6478;">${desc || "—"}</td>
        <td align="right" style="padding:11px 14px;font-size:13px;color:#2D3340;font-weight:700;">${qty}</td>
      </tr>`;
    }).join("");
    receivedSection += `${cardOpen}
      <tr style="background:#F7F8FA;"><th style="${TH("left", true)}">Docket</th><th style="${TH("left", false)}">Name</th><th style="${TH("left", false)}">Department</th><th style="${TH("left", false)}">Items</th><th style="${TH("right", true)}">Qty</th></tr>
      ${rows}${cardClose}`;
  } else {
    receivedSection += emptyCard("No complete tickets received today.");
  }

  // ── Section 2: Partially Received (only if any) ──
  let partialSection = "";
  if (partialReceived.length > 0) {
    const rows = partialReceived.map((order: any, idx: number) => {
      const items = nonPoolItems(order);
      const sent = items.reduce((s: number, i: any) => s + (i.quantity_sent || 0), 0);
      const rec = items.reduce((s: number, i: any) => s + (i.quantity_received || 0), 0);
      const awaiting = items.filter((i: any) => (i.quantity_received ?? 0) < (i.quantity_sent || 0))
        .map((i: any) => `${(i.quantity_sent || 0) - (i.quantity_received ?? 0)}&times; ${i.item_name}`).join(", ");
      return `<tr style="border-top:1px solid #EEF0F4;${stripe(idx)}">
        <td style="padding:11px 14px;font-size:13px;color:#1B2A4A;font-weight:700;">#${order.docket_number}</td>
        <td style="padding:11px 8px;font-size:13px;color:#2D3340;">${order.staff_name || order.guest_name || "—"} &middot; ${order.departments?.name || "—"}</td>
        <td style="padding:11px 8px;font-size:13px;color:#2D3340;">${rec} of ${sent}</td>
        <td style="padding:11px 14px;font-size:13px;color:#D64545;font-weight:600;">${awaiting}</td>
      </tr>`;
    }).join("");
    partialSection = sectionHead(C.partial, "Partially Received", `${partialReceived.length} ticket${partialReceived.length !== 1 ? "s" : ""} short`)
      + `${cardOpen}
        <tr style="background:#F7F8FA;"><th style="${TH("left", true)}">Docket</th><th style="${TH("left", false)}">Name</th><th style="${TH("left", false)}">Received</th><th style="${TH("left", true)}">Still Awaiting</th></tr>
        ${rows}${cardClose}`;
  }

  // ── Section 3: Sent to Laundry Today ──
  let sentSection = sectionHead(C.sent, "Sent to Laundry Today",
    `${sentNonPool.length} order${sentNonPool.length !== 1 ? "s" : ""} &middot; ${sentItems} items`);
  if (sentNonPool.length > 0) {
    const rows = sentNonPool.map((order: any, idx: number) => {
      const items = nonPoolItems(order);
      const qty = items.reduce((s: number, i: any) => s + (i.quantity_sent || 0), 0);
      const desc = items.map((i: any) => `${i.quantity_sent}&times; ${i.item_name}`).join(", ");
      return `<tr style="border-top:1px solid #EEF0F4;${stripe(idx)}">
        <td style="padding:11px 14px;font-size:13px;color:#1B2A4A;font-weight:700;">#${order.docket_number}</td>
        <td style="padding:11px 8px;font-size:13px;color:#2D3340;">${order.staff_name || order.guest_name || "—"}</td>
        <td style="padding:11px 8px;font-size:13px;color:#2D3340;">${order.departments?.name || "—"}</td>
        <td style="padding:11px 8px;font-size:13px;color:#5B6478;">${desc || "—"}</td>
        <td align="right" style="padding:11px 14px;font-size:13px;color:#2D3340;font-weight:700;">${qty}</td>
      </tr>`;
    }).join("");
    sentSection += `${cardOpen}
      <tr style="background:#F7F8FA;"><th style="${TH("left", true)}">Docket</th><th style="${TH("left", false)}">Name</th><th style="${TH("left", false)}">Department</th><th style="${TH("left", false)}">Items</th><th style="${TH("right", true)}">Qty</th></tr>
      ${rows}${cardClose}`;
  } else {
    sentSection += emptyCard(`Nothing sent to the laundry today${sentOrders.length > 0 ? " (napkin-only tickets are balanced in the napkin pool)" : ""}.`);
  }

  // ── Section 4: Still at Laundry (full backlog, days >= 1) ──
  let outstandingSection = sectionHead(C.outstanding, "Still at Laundry",
    `${outstandingFiltered.length} ticket${outstandingFiltered.length !== 1 ? "s" : ""} &middot; ${totalOutstanding} items`);
  if (outstandingFiltered.length > 0) {
    const rows = outstandingFiltered.map((o, idx) => {
      const desc = o.items.map((i) => `${i.awaited}&times; ${i.item}`).join(", ");
      return `<tr style="border-top:1px solid #EEF0F4;${stripe(idx)}">
        <td style="padding:11px 14px;font-size:13px;color:#1B2A4A;font-weight:700;">#${o.docket}${o.isChild ? ' <span style="font-weight:500;color:#C77700;font-size:11px;">partial</span>' : ""}</td>
        <td style="padding:11px 8px;font-size:13px;color:#2D3340;">${o.department}</td>
        <td style="padding:11px 8px;font-size:13px;color:#5B6478;">${desc}</td>
        <td align="right" style="padding:11px 14px;">${dayPill(o.days)}</td>
      </tr>`;
    }).join("");
    outstandingSection += `${cardOpen}
      <tr style="background:#F7F8FA;"><th style="${TH("left", true)}">Docket</th><th style="${TH("left", false)}">Department</th><th style="${TH("left", false)}">Awaiting</th><th style="${TH("right", true)}">Days Out</th></tr>
      ${rows}${cardClose}`;
  } else {
    outstandingSection += emptyCard("Nothing outstanding — everything is back &#10003;");
  }

  // ── Section 5: Napkin Returns (only if any) ──
  let napkinSection = "";
  if (napkinReturns.length > 0) {
    const rows = napkinReturns.map((n: any, idx: number) => `<tr style="border-top:1px solid #EEF0F4;${stripe(idx)}">
        <td style="padding:11px 14px;font-size:13px;color:#2D3340;">${n.department?.name || "—"}</td>
        <td style="padding:11px 8px;font-size:13px;color:#5B6478;">${n.note || "—"}</td>
        <td align="right" style="padding:11px 14px;font-size:13px;color:#2D3340;font-weight:700;">${n.quantity}</td>
      </tr>`).join("");
    napkinSection = sectionHead(C.napkin, "Napkin Returns", `${napkinTotal} napkin${napkinTotal !== 1 ? "s" : ""}`)
      + `${cardOpen}
        <tr style="background:#F7F8FA;"><th style="${TH("left", true)}">Department</th><th style="${TH("left", false)}">Note</th><th style="${TH("right", true)}">Qty</th></tr>
        ${rows}${cardClose}`;
  }

  const kpiRow = `
    <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="margin-bottom:6px;">
      <tr>
        ${kpi(receivedItems, "Received", `${receivedOrdersCount} order${receivedOrdersCount !== 1 ? "s" : ""}`, C.received)}
        ${kpi(sentItems, "Sent", `${sentNonPool.length} order${sentNonPool.length !== 1 ? "s" : ""}`, C.sent)}
        ${kpi(totalOutstanding, "Outstanding", `${outstandingFiltered.length} ticket${outstandingFiltered.length !== 1 ? "s" : ""}`, hasOutstanding ? C.outstanding : "#2E7D32")}
        ${kpi(napkinTotal, "Napkins", "returned", C.napkin)}
      </tr>
    </table>`;

  const sentLine = senderName
    ? `Sent by ${senderName} &middot; ${time}, ${today}`
    : `Generated automatically &middot; ${time}, ${today}`;

  // ── Assemble (modern, card-based, email-safe + FLUID so it never forces a
  //    fixed width wider than the screen — avoids a nested horizontal scroll) ──
  return `
    <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="background:#EEF1F5;font-family:-apple-system,Segoe UI,Roboto,Helvetica,Arial,sans-serif;">
      <tr><td align="center" style="padding:20px 12px;">
        <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="max-width:640px;background:#FFFFFF;border-radius:14px;box-shadow:0 1px 4px rgba(20,30,55,0.08);">
          <tr><td style="background:#1B2A4A;padding:26px 32px;">
            <table role="presentation" width="100%" cellspacing="0" cellpadding="0"><tr>
              <td align="left" style="vertical-align:middle;">
                <div style="color:#FFFFFF;font-size:18px;font-weight:700;letter-spacing:1.5px;">THE STRATFORD HOTEL</div>
                <div style="color:#C9A84C;font-size:12px;font-weight:600;letter-spacing:0.5px;margin-top:5px;">Daily Laundry Report</div>
              </td>
              <td align="right" style="vertical-align:middle;">
                <div style="color:#AEB6C9;font-size:12px;">${weekday}</div>
                <div style="color:#FFFFFF;font-size:14px;font-weight:600;margin-top:2px;">${today}</div>
              </td>
            </tr></table>
          </td></tr>
          <tr><td style="padding:24px 28px 28px;">
            ${kpiRow}
            ${receivedSection}
            ${partialSection}
            ${sentSection}
            ${outstandingSection}
            ${napkinSection}
          </td></tr>
          <tr><td style="background:#F7F8FA;border-top:1px solid #E6E9EF;padding:18px 28px;text-align:center;">
            <div style="font-size:12px;color:#5B6478;font-weight:600;">${sentLine}</div>
            <div style="font-size:11px;color:#A6AEBF;line-height:1.6;margin-top:7px;">The Stratford Hotel &middot; Laundry Management System<br>Managed by the Housekeeping Department</div>
          </td></tr>
        </table>
      </td></tr>
    </table>
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
  /** Express follow-up: ISO time of the previous send today. When set, the
   *  self-fetched Received/Sent/Napkins cover only items after this time. */
  since?: string;
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

    // Express follow-up: only items since the previous send today.
    const since = payload?.since;

    // Mode selection: payload data wins; otherwise fetch from DB (since the
    // last send if provided, else since today's UK midnight).
    const receivedOrders = payload?.receivedOrders ?? await fetchTodaysOrders("received", since);
    const sentOrders = payload?.sentOrders ?? payload?.collectedOrders ?? await fetchTodaysOrders("sent", since);
    const outstandingOrders = payload?.outstandingOrders ?? await fetchOpenSentOrders();
    const napkinReturns = payload?.napkinReturns ?? await fetchTodaysNapkinReturns(since);

    const recipients = (payload?.recipients && payload.recipients.length > 0)
      ? payload.recipients
      : await fetchRecipients();

    const reportHtml = buildDailyReport(receivedOrders, sentOrders, outstandingOrders, napkinReturns, payload?.senderName);

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
    // Express follow-up sends (since set) are labelled as an update, not the
    // first "Daily" report, so recipients can tell them apart.
    const reportLabel = since ? "Laundry Update" : "Daily Laundry Report";
    const subject = `${reportLabel} — ${today}${parts.length > 0 ? ` (${parts.join(", ")})` : ""}${senderTag}`;

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
