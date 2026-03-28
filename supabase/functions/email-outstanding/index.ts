// Supabase Edge Function: Send outstanding items email via Resend
// Deploy: supabase functions deploy email-outstanding

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const RESEND_API_KEY = Deno.env.get("RESEND_API_KEY") ?? "";

interface OutstandingItem {
  docket: string;
  department: string;
  item: string;
  sent: number;
  received: number;
  outstanding: number;
}

interface RequestBody {
  to: string;
  items: OutstandingItem[];
}

serve(async (req: Request) => {
  // CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", {
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "POST, OPTIONS",
        "Access-Control-Allow-Headers": "Content-Type, Authorization, apikey",
      },
    });
  }

  try {
    const { to, items } = (await req.json()) as RequestBody;

    if (!to || !items || items.length === 0) {
      return new Response(JSON.stringify({ error: "Missing 'to' or 'items'" }), {
        status: 400,
        headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
      });
    }

    if (!RESEND_API_KEY) {
      return new Response(JSON.stringify({ error: "RESEND_API_KEY not configured" }), {
        status: 500,
        headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
      });
    }

    const totalOutstanding = items.reduce((s, i) => s + i.outstanding, 0);
    const uniqueDockets = [...new Set(items.map((i) => i.docket))];
    const now = new Date().toLocaleDateString("en-GB", {
      day: "2-digit",
      month: "long",
      year: "numeric",
    });

    const html = `
      <div style="font-family:sans-serif;max-width:700px;margin:0 auto;border:1px solid #e0e0e0;border-radius:8px;overflow:hidden">
        <div style="background:#1B2A4A;padding:24px;text-align:center">
          <h1 style="color:white;margin:0;font-size:22px;letter-spacing:2px">THE STRATFORD HOTEL</h1>
          <p style="color:#C9A84C;margin:6px 0 0;font-size:12px;letter-spacing:1px">Autograph Collection</p>
        </div>

        <div style="background:#E65100;padding:12px 24px">
          <p style="color:white;margin:0;font-size:14px;font-weight:bold;text-align:center">
            Outstanding Items Report
          </p>
        </div>

        <div style="padding:24px">
          <p style="margin:0 0 8px;font-size:14px;color:#333">Dear Team,</p>
          <p style="margin:0 0 16px;font-size:14px;color:#555;line-height:1.5">
            Please find below a report of <strong>${totalOutstanding} outstanding item${totalOutstanding !== 1 ? "s" : ""}</strong>
            across <strong>${uniqueDockets.length} order${uniqueDockets.length !== 1 ? "s" : ""}</strong>
            that require investigation. These items were sent but have not yet been returned.
          </p>

          <table style="width:100%;border-collapse:collapse;margin:16px 0;font-size:13px">
            <tr style="background:#1B2A4A;color:white">
              <th style="padding:10px 8px;text-align:left">Docket</th>
              <th style="padding:10px 8px;text-align:left">Department</th>
              <th style="padding:10px 8px;text-align:left">Item</th>
              <th style="padding:10px 8px;text-align:center">Sent</th>
              <th style="padding:10px 8px;text-align:center">Received</th>
              <th style="padding:10px 8px;text-align:center">Outstanding</th>
            </tr>
            ${items
              .map(
                (item, i) => `
              <tr style="border-bottom:1px solid #eee;background:${i % 2 === 0 ? "#fff" : "#fafafa"}">
                <td style="padding:8px;font-family:monospace;font-size:12px">${item.docket}</td>
                <td style="padding:8px">${item.department}</td>
                <td style="padding:8px">${item.item}</td>
                <td style="padding:8px;text-align:center">${item.sent}</td>
                <td style="padding:8px;text-align:center">${item.received}</td>
                <td style="padding:8px;text-align:center;color:#C62828;font-weight:bold">${item.outstanding}</td>
              </tr>`
              )
              .join("")}
            <tr style="background:#f5f5f5;font-weight:bold;border-top:2px solid #ddd">
              <td style="padding:10px 8px" colspan="3">Total</td>
              <td style="padding:10px 8px;text-align:center">${items.reduce((s, i) => s + i.sent, 0)}</td>
              <td style="padding:10px 8px;text-align:center">${items.reduce((s, i) => s + i.received, 0)}</td>
              <td style="padding:10px 8px;text-align:center;color:#C62828">${totalOutstanding}</td>
            </tr>
          </table>

          <p style="margin:16px 0 0;font-size:14px;color:#555;line-height:1.5">
            Please investigate and advise on the status of these items at your earliest convenience.
          </p>

          <p style="margin:16px 0 0;font-size:14px;color:#333">
            Kind regards,<br />
            <strong>The Stratford Laundry Team</strong>
          </p>
        </div>

        <div style="background:#f5f5f5;padding:16px 24px;border-top:1px solid #e0e0e0;text-align:center">
          <p style="margin:0;font-size:11px;color:#999">
            Report generated on ${now} &bull; ${uniqueDockets.length} order${uniqueDockets.length !== 1 ? "s" : ""} &bull; ${totalOutstanding} outstanding item${totalOutstanding !== 1 ? "s" : ""}
          </p>
          <p style="margin:4px 0 0;font-size:11px;color:#bbb">
            Powered by Laundrevo Limited
          </p>
        </div>
      </div>
    `;

    const subject = `Outstanding Laundry Items \u2014 ${totalOutstanding} item${totalOutstanding !== 1 ? "s" : ""} requiring investigation`;

    const resendRes = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${RESEND_API_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        from: "The Stratford Laundry <noreply@hskthestratford.uk>",
        to: [to],
        subject,
        html,
      }),
    });

    if (!resendRes.ok) {
      const err = await resendRes.text();
      return new Response(JSON.stringify({ error: `Resend error: ${err}` }), {
        status: 500,
        headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
      });
    }

    const result = await resendRes.json();
    return new Response(JSON.stringify({ success: true, id: result.id }), {
      headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
    });
  } catch (e) {
    return new Response(JSON.stringify({ error: (e as Error).message }), {
      status: 500,
      headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
    });
  }
});
