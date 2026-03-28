// Supabase Edge Function: Email notifications on order status change
// Deploy: supabase functions deploy notify-order-status
//
// This function is triggered by a database webhook on the order_status_log table.
// It sends email notifications to staff who provided an email address.
// For "collected" and "received" statuses, it also sends a report to Laundrevo.

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const RESEND_API_KEY = Deno.env.get("RESEND_API_KEY") ?? "";

// Report emails — daily report at 2pm + express alerts after 2pm
const REPORT_EMAILS = ["georgi@thestratford.com", "set1000@hotmail.com"];
const DAILY_REPORT_HOUR_UTC = 14; // 2pm GMT / 3pm BST

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);

interface StatusLogPayload {
  record: {
    id: string;
    order_id: string;
    status: string;
    changed_by_name: string | null;
    reason: string | null;
    created_at: string;
  };
}

const STATUS_LABELS: Record<string, string> = {
  submitted: "Order Submitted",
  approved: "Order Approved",
  rejected: "Order Rejected",
  collected: "Items Collected by Laundrevo",
  in_processing: "Items Being Processed",
  received: "Clean Items Received",
  completed: "Order Completed",
};

const STATUS_MESSAGES: Record<string, string> = {
  submitted:
    "Your laundry order has been submitted successfully and is now awaiting approval from the laundry team. You will receive another email once your order has been reviewed.",
  approved:
    "Great news! Your laundry order has been approved and is now scheduled for collection by Laundrevo. You will be notified once your items have been picked up.",
  rejected:
    "Unfortunately, your laundry order could not be approved. Please see the reason below and resubmit if needed. If you have questions, contact the laundry team.",
  collected:
    "Your laundry items have been collected by Laundrevo and are now on their way to the cleaning facility. We will notify you once processing begins.",
  in_processing:
    "Your items are currently being cleaned and processed at the Laundrevo facility. We will notify you as soon as your clean items are ready for delivery.",
  received:
    "Your clean items have been received back at The Stratford Hotel. Please see the item summary below for any discrepancies. Items are ready for collection from the laundry room.",
  completed:
    "Your laundry order is now complete. All items have been returned and the order is closed. Thank you for using The Stratford laundry service.",
};

const STATUS_COLOURS: Record<string, string> = {
  submitted: "#1565C0",
  approved: "#2E7D32",
  rejected: "#C62828",
  collected: "#E65100",
  in_processing: "#6A1B9A",
  received: "#00838F",
  completed: "#2E7D32",
};

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

// ── Helper: build items table HTML ──
function buildItemsTable(items: any[], showReceived: boolean) {
  if (!items || items.length === 0) return "";

  const totalSent = items.reduce((sum: number, i: any) => sum + (i.quantity_sent || 0), 0);
  const totalReceived = showReceived
    ? items.reduce((sum: number, i: any) => sum + (i.quantity_received || 0), 0)
    : 0;
  const totalOutstanding = showReceived ? totalSent - totalReceived : 0;

  return `
    <table style="width:100%;border-collapse:collapse;margin:16px 0">
      <tr style="background:#1B2A4A;color:white">
        <th style="padding:8px;text-align:left">Item</th>
        <th style="padding:8px;text-align:center">Qty Sent</th>
        ${showReceived ? '<th style="padding:8px;text-align:center">Qty Received</th><th style="padding:8px;text-align:center">Outstanding</th>' : ""}
      </tr>
      ${items.map((item: any) => {
        const outstanding = (item.quantity_sent || 0) - (item.quantity_received || 0);
        return `<tr style="border-bottom:1px solid #eee">
          <td style="padding:8px">${item.item_name}</td>
          <td style="padding:8px;text-align:center">${item.quantity_sent}</td>
          ${showReceived ? `<td style="padding:8px;text-align:center">${item.quantity_received ?? "—"}</td><td style="padding:8px;text-align:center;color:${outstanding > 0 ? "#C62828" : "#2E7D32"};font-weight:bold">${outstanding > 0 ? outstanding : "✓"}</td>` : ""}
        </tr>`;
      }).join("")}
      <tr style="background:#f5f5f5;font-weight:bold">
        <td style="padding:8px">Total</td>
        <td style="padding:8px;text-align:center">${totalSent}</td>
        ${showReceived ? `<td style="padding:8px;text-align:center">${totalReceived}</td><td style="padding:8px;text-align:center;color:${totalOutstanding > 0 ? "#C62828" : "#2E7D32"}">${totalOutstanding > 0 ? totalOutstanding : "✓"}</td>` : ""}
      </tr>
    </table>
  `;
}

// ── Helper: build the standard branded email ──
function buildStaffEmail(order: any, status: string, statusLabel: string, reason: string | null) {
  const statusMessage = STATUS_MESSAGES[status] || "";
  const statusColour = STATUS_COLOURS[status] || "#1B2A4A";
  const isGuestOrder = order.order_type === "guest_laundry";
  const recipientName = order.guest_name || order.staff_name || "Team Member";
  const orderTypeLabel: Record<string, string> = {
    uniform: "Uniform",
    hsk_linen: "Housekeeping Linen",
    fnb_linen: "F&B Linen",
    guest_laundry: "Guest Laundry",
  };

  const showReceived = status === "received";
  const itemsHtml = buildItemsTable(order.order_items, showReceived);

  const rejectionBlock = status === "rejected" && reason
    ? `<div style="margin:16px 0;padding:16px;background:#FFEBEE;border-left:4px solid #C62828;border-radius:4px">
        <p style="margin:0;color:#C62828;font-weight:bold;font-size:14px">Reason for Rejection</p>
        <p style="margin:8px 0 0;color:#B71C1C;font-size:14px">${reason}</p>
      </div>`
    : "";

  return `
    <div style="font-family:sans-serif;max-width:600px;margin:0 auto;border:1px solid #e0e0e0;border-radius:8px;overflow:hidden">
      <div style="background:#1B2A4A;padding:24px;text-align:center">
        <h1 style="color:white;margin:0;font-size:22px;letter-spacing:2px">THE STRATFORD HOTEL</h1>
        <p style="color:#C9A84C;margin:6px 0 0;font-size:12px;letter-spacing:1px">Autograph Collection</p>
      </div>

      <div style="background:${statusColour};padding:14px 24px;text-align:center">
        <h2 style="color:white;margin:0;font-size:18px">${statusLabel}</h2>
      </div>

      <div style="padding:24px;background:white">
        <p style="margin:0 0 16px;color:#333">Dear ${recipientName},</p>
        <p style="margin:0 0 20px;color:#555;line-height:1.6">${statusMessage}</p>

        ${rejectionBlock}

        <table style="width:100%;border-collapse:collapse;margin:0 0 20px;background:#f9f9f9;border-radius:6px">
          <tr>
            <td style="padding:10px 16px;color:#777;font-size:13px;border-bottom:1px solid #eee">Docket Number</td>
            <td style="padding:10px 16px;font-weight:bold;color:#1B2A4A;border-bottom:1px solid #eee">#${order.docket_number}</td>
          </tr>
          <tr>
            <td style="padding:10px 16px;color:#777;font-size:13px;border-bottom:1px solid #eee">Order Type</td>
            <td style="padding:10px 16px;color:#333;border-bottom:1px solid #eee">${orderTypeLabel[order.order_type] || order.order_type}</td>
          </tr>
          <tr>
            <td style="padding:10px 16px;color:#777;font-size:13px;border-bottom:1px solid #eee">Date</td>
            <td style="padding:10px 16px;color:#333;border-bottom:1px solid #eee">${new Date(order.created_at).toLocaleDateString("en-GB", { day: "numeric", month: "long", year: "numeric" })}</td>
          </tr>
          <tr>
            <td style="padding:10px 16px;color:#777;font-size:13px;border-bottom:1px solid #eee">Department</td>
            <td style="padding:10px 16px;color:#333;border-bottom:1px solid #eee">${order.departments?.name || "—"}</td>
          </tr>
          ${isGuestOrder ? `
          <tr>
            <td style="padding:10px 16px;color:#777;font-size:13px;border-bottom:1px solid #eee">Room</td>
            <td style="padding:10px 16px;color:#333;border-bottom:1px solid #eee">${order.room_number || "—"}</td>
          </tr>
          <tr>
            <td style="padding:10px 16px;color:#777;font-size:13px;border-bottom:1px solid #eee">Bags</td>
            <td style="padding:10px 16px;color:#333;border-bottom:1px solid #eee">${order.bag_count || 1}</td>
          </tr>` : ""}
        </table>

        ${itemsHtml}
        ${order.notes ? `<p style="margin:16px 0;padding:12px 16px;background:#FFF8E1;border-left:4px solid #C9A84C;color:#555;font-size:13px"><strong>Notes:</strong> ${order.notes}</p>` : ""}
      </div>

      <div style="background:#f5f5f5;padding:20px;text-align:center;font-size:11px;color:#999;border-top:1px solid #e0e0e0">
        The Stratford Hotel — Laundry Management System<br>
        <span style="color:#bbb">This is an automated notification — please do not reply to this email.</span>
      </div>
    </div>
  `;
}

// ── Helper: fetch all orders with a given status logged today ──
async function fetchTodaysOrders(targetStatus: string) {
  const today = new Date();
  today.setHours(0, 0, 0, 0);

  // Find all status logs for today with the target status
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
    .in("id", orderIds);

  return orders || [];
}

// ── Helper: build combined daily collection report for Laundrevo ──
function buildCollectionReport(orders: any[]) {
  const today = new Date().toLocaleDateString("en-GB", { day: "numeric", month: "long", year: "numeric" });

  // One row per docket — items combined into description
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

// ── Helper: build combined daily receiving report for Laundrevo ──
function buildReceivedReport(orders: any[]) {
  const today = new Date().toLocaleDateString("en-GB", { day: "numeric", month: "long", year: "numeric" });

  // One row per docket — items combined into description, totals per order
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
      </div>

      <div style="background:#f5f5f5;padding:20px;text-align:center;font-size:11px;color:#999;border-top:1px solid #e0e0e0">
        The Stratford Hotel — Laundry Management System<br>
        Managed by the Housekeeping Department
      </div>
    </div>
  `;
}

// ── Helper: build express alert for after-2pm collections/returns ──
function buildExpressAlert(order: any, status: string) {
  const isCollected = status === "collected";
  const label = isCollected ? "Express Collection" : "Express Return";
  const colour = isCollected ? "#E65100" : "#00838F";
  const today = new Date().toLocaleDateString("en-GB", { day: "numeric", month: "long", year: "numeric" });
  const time = new Date().toLocaleTimeString("en-GB", { hour: "2-digit", minute: "2-digit" });

  const items = order.order_items || [];
  const itemsDesc = items.map((i: any) => `${i.quantity_sent}x ${i.item_name}`).join(", ");
  const totalQty = items.reduce((sum: number, i: any) => sum + (i.quantity_sent || 0), 0);

  const orderTypeLabel: Record<string, string> = {
    uniform: "Uniform",
    hsk_linen: "Housekeeping Linen",
    fnb_linen: "F&B Linen",
    guest_laundry: "Guest Laundry",
  };

  return `
    <div style="font-family:sans-serif;max-width:600px;margin:0 auto;border:1px solid #e0e0e0;border-radius:8px;overflow:hidden">
      <div style="background:#1B2A4A;padding:24px;text-align:center">
        <h1 style="color:white;margin:0;font-size:22px;letter-spacing:2px">THE STRATFORD HOTEL</h1>
        <p style="color:#C9A84C;margin:6px 0 0;font-size:12px;letter-spacing:1px">Autograph Collection</p>
      </div>

      <div style="background:${colour};padding:14px 24px;text-align:center">
        <h2 style="color:white;margin:0;font-size:18px">${label} — After Daily Report</h2>
      </div>

      <div style="padding:24px;background:white">
        <div style="margin:0 0 16px;padding:12px 16px;background:#FFF8E1;border-left:4px solid #C9A84C;border-radius:4px">
          <p style="margin:0;color:#795548;font-size:13px"><strong>New item added after the 2pm daily report.</strong></p>
        </div>

        <table style="width:100%;border-collapse:collapse;margin:0 0 20px;background:#f9f9f9;border-radius:6px">
          <tr>
            <td style="padding:10px 16px;color:#777;font-size:13px;border-bottom:1px solid #eee">Docket Number</td>
            <td style="padding:10px 16px;font-weight:bold;color:#1B2A4A;border-bottom:1px solid #eee">#${order.docket_number}</td>
          </tr>
          <tr>
            <td style="padding:10px 16px;color:#777;font-size:13px;border-bottom:1px solid #eee">Order Type</td>
            <td style="padding:10px 16px;color:#333;border-bottom:1px solid #eee">${orderTypeLabel[order.order_type] || order.order_type}</td>
          </tr>
          <tr>
            <td style="padding:10px 16px;color:#777;font-size:13px;border-bottom:1px solid #eee">Name</td>
            <td style="padding:10px 16px;color:#333;border-bottom:1px solid #eee">${order.staff_name || order.guest_name || "—"}</td>
          </tr>
          <tr>
            <td style="padding:10px 16px;color:#777;font-size:13px;border-bottom:1px solid #eee">Department</td>
            <td style="padding:10px 16px;color:#333;border-bottom:1px solid #eee">${order.departments?.name || "—"}</td>
          </tr>
          <tr>
            <td style="padding:10px 16px;color:#777;font-size:13px;border-bottom:1px solid #eee">Items</td>
            <td style="padding:10px 16px;color:#333;border-bottom:1px solid #eee">${itemsDesc || "—"}</td>
          </tr>
          <tr>
            <td style="padding:10px 16px;color:#777;font-size:13px;border-bottom:1px solid #eee">Total Qty</td>
            <td style="padding:10px 16px;font-weight:bold;color:#1B2A4A;border-bottom:1px solid #eee">${totalQty}</td>
          </tr>
          <tr>
            <td style="padding:10px 16px;color:#777;font-size:13px">Time</td>
            <td style="padding:10px 16px;color:#333">${time} — ${today}</td>
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

serve(async (req: Request) => {
  try {
    const payload: StatusLogPayload = await req.json();
    const { order_id, status, reason } = payload.record;

    // Fetch order with items
    const { data: order, error } = await supabase
      .from("orders")
      .select("*, order_items(*), departments(*)")
      .eq("id", order_id)
      .single();

    if (error || !order) {
      return new Response(JSON.stringify({ error: "Order not found" }), { status: 404 });
    }

    const statusLabel = STATUS_LABELS[status] || status;
    const subject = `The Stratford Hotel — ${statusLabel} (Docket #${order.docket_number})`;
    const emailsSent: string[] = [];

    // 1. Send to the staff/guest who submitted the order
    if (order.email) {
      const html = buildStaffEmail(order, status, statusLabel, reason);
      await sendEmail(order.email, subject, html);
      emailsSent.push(order.email);
    }

    // 2. After the daily report (2pm), send express alerts to the laundry company
    //    for any new collections or returns that happen later in the day.
    if ((status === "collected" || status === "received") && REPORT_EMAILS.length > 0) {
      const nowUTC = new Date();
      if (nowUTC.getUTCHours() >= DAILY_REPORT_HOUR_UTC) {
        const expressHtml = buildExpressAlert(order, status);
        const expressLabel = status === "collected" ? "Express Collection" : "Express Return";
        const expressSubject = `${expressLabel} — Docket #${order.docket_number} (After Daily Report)`;
        for (const email of REPORT_EMAILS) {
          await sendEmail(email, expressSubject, expressHtml);
          emailsSent.push(`express:${email}`);
        }
      }
    }

    if (emailsSent.length === 0) {
      return new Response(JSON.stringify({ message: "No recipients configured, skipping" }), { status: 200 });
    }

    return new Response(JSON.stringify({ success: true, emails: emailsSent }), { status: 200 });
  } catch (err) {
    return new Response(JSON.stringify({ error: String(err) }), { status: 500 });
  }
});
