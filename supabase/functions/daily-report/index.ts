// Supabase Edge Function: Daily collection & receiving report
// Triggered on-demand when the Collect button is pressed on the tablet.
// Also still callable via pg_cron as a fallback.
//
// Deploy: supabase functions deploy daily-report

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const RESEND_API_KEY = Deno.env.get("RESEND_API_KEY") ?? "";

const REPORT_EMAILS = ["kunov.georgi@gmail.com", "georgi@thestratford.com", "set1000@hotmail.com"];

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);

// ── Helper: send an email via Resend ──
async function sendEmail(to: string, subject: string, html: string) {
  if (!RESEND_API_KEY) return;
  await fetch("https://api.resend.com/emails", {
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
}

// ── Fetch orders that were moved to a given status today ──
async function fetchTodaysOrdersByStatus(targetStatus: string) {
  const today = new Date();
  today.setUTCHours(0, 0, 0, 0);

  // Find status logs created today for the target status
  const { data: logs } = await supabase
    .from("order_status_log")
    .select("order_id")
    .eq("status", targetStatus)
    .gte("created_at", today.toISOString());

  if (!logs || logs.length === 0) return [];

  const orderIds = [...new Set(logs.map((l: any) => l.order_id))];

  const { data: orders } = await supabase
    .from("orders")
    .select("*, order_items(*), departments(*)")
    .in("id", orderIds)
    .order("created_at", { ascending: false });

  return orders || [];
}

// ── Build daily collection report ──
function buildCollectionReport(orders: any[]) {
  const today = new Date().toLocaleDateString("en-GB", { day: "numeric", month: "long", year: "numeric" });

  const rows = orders.map((order: any) => {
    const items = order.order_items || [];
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

  const grandTotal = orders.reduce((sum: number, o: any) =>
    sum + (o.order_items || []).reduce((s: number, i: any) => s + (i.quantity_sent || 0), 0), 0);

  return `
    <div style="font-family:sans-serif;max-width:750px;margin:0 auto;border:1px solid #e0e0e0;border-radius:8px;overflow:hidden">
      <div style="background:#1B2A4A;padding:24px;text-align:center">
        <h1 style="color:white;margin:0;font-size:22px;letter-spacing:2px">THE STRATFORD HOTEL</h1>
        <p style="color:#C9A84C;margin:6px 0 0;font-size:12px;letter-spacing:1px">Daily Collection Report</p>
      </div>

      <div style="background:#E65100;padding:14px 24px;text-align:center">
        <h2 style="color:white;margin:0;font-size:18px">Items Collected — ${today}</h2>
      </div>

      <div style="padding:24px;background:white">
        <p style="margin:0 0 16px;color:#555">${orders.length} order${orders.length > 1 ? "s" : ""} collected today — ${grandTotal} items total.</p>

        <table style="width:100%;border-collapse:collapse;margin:16px 0;font-size:13px">
          <tr style="background:#1B2A4A;color:white">
            <th style="padding:10px 8px;text-align:left">Docket</th>
            <th style="padding:10px 8px;text-align:left">Name</th>
            <th style="padding:10px 8px;text-align:left">Department</th>
            <th style="padding:10px 8px;text-align:left">Items</th>
            <th style="padding:10px 8px;text-align:center">Qty</th>
          </tr>
          ${rows}
          <tr style="background:#f5f5f5;font-weight:bold">
            <td colspan="4" style="padding:10px 8px;text-align:right">Total Items</td>
            <td style="padding:10px 8px;text-align:center">${grandTotal}</td>
          </tr>
        </table>
      </div>

      <div style="background:#f5f5f5;padding:20px;text-align:center;font-size:11px;color:#999;border-top:1px solid #e0e0e0">
        The Stratford Hotel — Laundry Management System<br>
        Managed by the Housekeeping Department
      </div>
    </div>
  `;
}

// ── Fetch today's linen napkin returns from ledger ──
async function fetchTodaysNapkinReturns() {
  const today = new Date();
  today.setUTCHours(0, 0, 0, 0);
  const { data } = await supabase
    .from("linen_ledger")
    .select("*")
    .eq("direction", "in")
    .eq("item_name", "Linen Napkins")
    .gte("created_at", today.toISOString())
    .order("created_at", { ascending: false });
  return data || [];
}

// ── Build daily receiving report ──
function buildReceivedReport(orders: any[], napkinReturns: any[] = []) {
  const today = new Date().toLocaleDateString("en-GB", { day: "numeric", month: "long", year: "numeric" });

  let grandSent = 0;
  let grandReceived = 0;

  const rows = orders.map((order: any) => {
    const items = order.order_items || [];
    const itemsDesc = items.map((i: any) => `${i.quantity_sent}x ${i.item_name}`).join(", ");
    const totalSent = items.reduce((sum: number, i: any) => sum + (i.quantity_sent || 0), 0);
    const totalReceived = items.reduce((sum: number, i: any) => sum + (i.quantity_received || 0), 0);
    const outstanding = totalSent - totalReceived;

    grandSent += totalSent;
    grandReceived += totalReceived;

    return `<tr style="border-bottom:1px solid #eee">
      <td style="padding:10px 8px;font-weight:bold">#${order.docket_number}</td>
      <td style="padding:10px 8px">${order.staff_name || order.guest_name || "—"}</td>
      <td style="padding:10px 8px">${order.departments?.name || "—"}</td>
      <td style="padding:10px 8px">${itemsDesc || "—"}</td>
      <td style="padding:10px 8px;text-align:center">${totalSent}</td>
      <td style="padding:10px 8px;text-align:center">${totalReceived}</td>
      <td style="padding:10px 8px;text-align:center;color:${outstanding > 0 ? "#C62828" : "#2E7D32"};font-weight:bold">${outstanding > 0 ? outstanding : "✓"}</td>
    </tr>`;
  }).join("");

  const grandOutstanding = grandSent - grandReceived;
  const hasDiscrepancies = grandOutstanding > 0;

  return `
    <div style="font-family:sans-serif;max-width:750px;margin:0 auto;border:1px solid #e0e0e0;border-radius:8px;overflow:hidden">
      <div style="background:#1B2A4A;padding:24px;text-align:center">
        <h1 style="color:white;margin:0;font-size:22px;letter-spacing:2px">THE STRATFORD HOTEL</h1>
        <p style="color:#C9A84C;margin:6px 0 0;font-size:12px;letter-spacing:1px">Daily Receiving Report</p>
      </div>

      <div style="background:${hasDiscrepancies ? "#C62828" : "#2E7D32"};padding:14px 24px;text-align:center">
        <h2 style="color:white;margin:0;font-size:18px">${hasDiscrepancies ? "Items Partly Received — Outstanding Items" : "All Items Received"} — ${today}</h2>
      </div>

      <div style="padding:24px;background:white">
        <p style="margin:0 0 16px;color:#555">${orders.length} order${orders.length > 1 ? "s" : ""} received today — ${grandSent} sent, ${grandReceived} received${hasDiscrepancies ? `, <strong style="color:#C62828">${grandOutstanding} outstanding</strong>` : ""}.</p>

        <table style="width:100%;border-collapse:collapse;margin:16px 0;font-size:13px">
          <tr style="background:#1B2A4A;color:white">
            <th style="padding:10px 8px;text-align:left">Docket</th>
            <th style="padding:10px 8px;text-align:left">Name</th>
            <th style="padding:10px 8px;text-align:left">Department</th>
            <th style="padding:10px 8px;text-align:left">Items</th>
            <th style="padding:10px 8px;text-align:center">Sent</th>
            <th style="padding:10px 8px;text-align:center">Received</th>
            <th style="padding:10px 8px;text-align:center">Outstanding</th>
          </tr>
          ${rows}
          <tr style="background:#f5f5f5;font-weight:bold">
            <td colspan="4" style="padding:10px 8px;text-align:right">Totals</td>
            <td style="padding:10px 8px;text-align:center">${grandSent}</td>
            <td style="padding:10px 8px;text-align:center">${grandReceived}</td>
            <td style="padding:10px 8px;text-align:center;color:${hasDiscrepancies ? "#C62828" : "#2E7D32"}">${hasDiscrepancies ? grandOutstanding : "✓"}</td>
          </tr>
        </table>

        ${napkinReturns.length > 0 ? `
        <div style="margin-top:24px;padding-top:16px;border-top:2px solid #C9A84C">
          <h3 style="color:#1B2A4A;margin:0 0 12px;font-size:15px">Linen Napkins — Returns Today</h3>
          <table style="width:100%;border-collapse:collapse;font-size:13px">
            <tr style="background:#C9A84C;color:white">
              <th style="padding:8px;text-align:left">Time</th>
              <th style="padding:8px;text-align:center">Quantity</th>
              <th style="padding:8px;text-align:left">Note</th>
              <th style="padding:8px;text-align:left">Recorded By</th>
            </tr>
            ${napkinReturns.map((r: any) => `<tr style="border-bottom:1px solid #eee">
              <td style="padding:8px">${new Date(r.created_at).toLocaleTimeString("en-GB", { hour: "2-digit", minute: "2-digit" })}</td>
              <td style="padding:8px;text-align:center;font-weight:bold">${r.quantity}</td>
              <td style="padding:8px">${r.note || "—"}</td>
              <td style="padding:8px">${r.recorded_by || "—"}</td>
            </tr>`).join("")}
            <tr style="background:#f5f5f5;font-weight:bold">
              <td style="padding:8px">Total Returned</td>
              <td style="padding:8px;text-align:center">${napkinReturns.reduce((s: number, r: any) => s + (r.quantity || 0), 0)}</td>
              <td colspan="2"></td>
            </tr>
          </table>
        </div>
        ` : ""}
      </div>

      <div style="background:#f5f5f5;padding:20px;text-align:center;font-size:11px;color:#999;border-top:1px solid #e0e0e0">
        The Stratford Hotel — Laundry Management System<br>
        Managed by the Housekeeping Department
      </div>
    </div>
  `;
}

serve(async (_req: Request) => {
  try {
    const emailsSent: string[] = [];

    // Fetch orders collected today
    const collectedOrders = await fetchTodaysOrdersByStatus("collected");
    if (collectedOrders.length > 0) {
      const reportHtml = buildCollectionReport(collectedOrders);
      const today = new Date().toLocaleDateString("en-GB");
      const subject = `Daily Collection Report — ${today} (${collectedOrders.length} order${collectedOrders.length > 1 ? "s" : ""})`;
      for (const email of REPORT_EMAILS) {
        await sendEmail(email, subject, reportHtml);
        emailsSent.push(`collected:${email}`);
      }
    }

    // Fetch orders received today + today's napkin returns
    const receivedOrders = await fetchTodaysOrdersByStatus("received");
    const napkinReturns = await fetchTodaysNapkinReturns();
    if (receivedOrders.length > 0 || napkinReturns.length > 0) {
      const reportHtml = buildReceivedReport(receivedOrders, napkinReturns);
      const today = new Date().toLocaleDateString("en-GB");
      const napkinTotal = napkinReturns.reduce((s: number, r: any) => s + (r.quantity || 0), 0);
      const napkinNote = napkinReturns.length > 0 ? ` + ${napkinTotal} napkins returned` : "";
      const subject = `Daily Receiving Report — ${today} (${receivedOrders.length} order${receivedOrders.length !== 1 ? "s" : ""}${napkinNote})`;
      for (const email of REPORT_EMAILS) {
        await sendEmail(email, subject, reportHtml);
        emailsSent.push(`received:${email}`);
      }
    }

    if (emailsSent.length === 0) {
      return new Response(JSON.stringify({ message: "No orders today, no reports sent" }), { status: 200 });
    }

    return new Response(JSON.stringify({ success: true, emails: emailsSent }), { status: 200 });
  } catch (err) {
    return new Response(JSON.stringify({ error: String(err) }), { status: 500 });
  }
});
