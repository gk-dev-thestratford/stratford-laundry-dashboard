import { useState, useEffect, useMemo } from 'react'
import { X, Send, AlertCircle, CheckCircle, FileText, Truck, Package, UtensilsCrossed, Loader2, Mail } from 'lucide-react'
import { format } from 'date-fns'
import { supabase } from '../lib/supabase'
import { logActivity } from '../hooks/useSessionActivity'
import { showStatusToast } from './StatusToast'

/** Editable recipient list lives in the report_recipients table (shared with the
 *  tablet — the edge function reads the same table for payload-less sends). */
interface Recipient {
  id: string
  email: string
}

async function fetchRecipients(): Promise<Recipient[]> {
  const { data } = await supabase
    .from('report_recipients')
    .select('id, email')
    .eq('is_active', true)
    .order('created_at')
  return (data ?? []) as Recipient[]
}

/** Pool-tracked napkins balance through the linen pool, so napkin lines and
 *  napkin-only tickets are excluded from the order sections (the edge function
 *  applies the same rule to the email). */
const isPoolItem = (name: string) => (name || '').toLowerCase().includes('napkin')
const nonPoolItems = (o: ReportOrder) => (o.order_items || []).filter((i) => !isPoolItem(i.item_name))
const isPartialOrder = (o: ReportOrder) =>
  nonPoolItems(o).some((i) => (i.quantity_received ?? 0) < (i.quantity_sent || 0))

interface ReportOrder {
  id: string
  docket_number: string
  staff_name: string | null
  guest_name: string | null
  departments: { name: string } | null
  order_items: {
    item_name: string
    quantity_sent: number
    quantity_received: number | null
  }[]
}

interface NapkinReturn {
  id: string
  quantity: number
  note: string | null
  department: { name: string } | null
}

interface ReportData {
  received: ReportOrder[]
  sent: ReportOrder[]
  napkins: NapkinReturn[]
  openSent: OutstandingOrder[]
}

/** An order still at the laundry (status = sent) — the not-yet-received backlog */
interface OutstandingOrder {
  id: string
  docket: string
  department: string
  name: string
  days: number
  isChild: boolean
  items: { item: string; awaited: number }[]
}

interface DailyReportModalProps {
  onClose: () => void
}

// ── UK midnight (BST/GMT-correct) as a UTC ISO string ──
function getUKMidnightISO(): string {
  const now = new Date()
  const parts = new Intl.DateTimeFormat('en-GB', {
    timeZone: 'Europe/London',
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
  }).formatToParts(now)
  const y = parts.find((p) => p.type === 'year')!.value
  const m = parts.find((p) => p.type === 'month')!.value
  const d = parts.find((p) => p.type === 'day')!.value
  const candidate = new Date(`${y}-${m}-${d}T00:00:00Z`)
  const ukHour = parseInt(
    new Intl.DateTimeFormat('en-GB', { timeZone: 'Europe/London', hour: 'numeric', hour12: false }).format(candidate),
    10,
  )
  return new Date(candidate.getTime() - ukHour * 3_600_000).toISOString()
}

async function fetchOrdersByStatus(status: string): Promise<ReportOrder[]> {
  const since = getUKMidnightISO()
  const { data: logs } = await supabase
    .from('order_status_log')
    .select('order_id')
    .eq('status', status)
    .gte('created_at', since)
  if (!logs || logs.length === 0) return []

  const ids = [...new Set(logs.map((l: { order_id: string }) => l.order_id))]
  const { data: orders } = await supabase
    .from('orders')
    .select('id, docket_number, staff_name, guest_name, departments(name), order_items(item_name, quantity_sent, quantity_received)')
    .in('id', ids)
  return (orders ?? []) as unknown as ReportOrder[]
}

async function fetchTodaysNapkinReturns(): Promise<NapkinReturn[]> {
  const since = getUKMidnightISO()
  const { data } = await supabase
    .from('linen_ledger')
    .select('id, quantity, note, department:departments(name)')
    .eq('direction', 'in')
    .gte('created_at', since)
    .order('created_at', { ascending: false })
  return (data ?? []) as unknown as NapkinReturn[]
}

/** All orders currently at the laundry (status = sent), regardless of day, with aging. */
async function fetchOpenSentOrders(): Promise<OutstandingOrder[]> {
  const { data } = await supabase
    .from('orders')
    .select('id, docket_number, staff_name, guest_name, parent_order_id, created_at, departments(name), order_items(item_name, quantity_sent, quantity_received), status_log:order_status_log(status, created_at)')
    .eq('status', 'sent')
    .order('created_at', { ascending: true })
  return (data ?? [])
    .map((o: any) => {
      const sentLogs = (o.status_log || []).filter((l: any) => l.status === 'sent')
      const since = sentLogs.length > 0
        ? sentLogs.reduce((b: any, l: any) => (new Date(l.created_at) > new Date(b.created_at) ? l : b)).created_at
        : o.created_at
      const days = Math.max(0, Math.floor((Date.now() - new Date(since).getTime()) / 86_400_000))
      const items = (o.order_items || [])
        .map((i: any) => ({ item: i.item_name, awaited: (i.quantity_sent || 0) - (i.quantity_received ?? 0) }))
        .filter((i: { awaited: number }) => i.awaited > 0)
      return {
        id: o.id,
        docket: o.docket_number,
        department: o.departments?.name || '—',
        name: o.staff_name || o.guest_name || '—',
        days,
        isChild: !!o.parent_order_id,
        items,
      }
    })
    .filter((o: OutstandingOrder) => o.items.length > 0)
}

export default function DailyReportModal({ onClose }: DailyReportModalProps) {
  const [data, setData] = useState<ReportData | null>(null)
  const [loading, setLoading] = useState(true)
  const [sending, setSending] = useState(false)
  const [error, setError] = useState<string | null>(null)

  // Live recipient list — managed on the Configuration page
  const [recipients, setRecipients] = useState<Recipient[]>([])

  useEffect(() => {
    let cancelled = false
    ;(async () => {
      try {
        const [received, sent, napkins, openSent, recips] = await Promise.all([
          fetchOrdersByStatus('received'),
          fetchOrdersByStatus('sent'),
          fetchTodaysNapkinReturns(),
          fetchOpenSentOrders(),
          fetchRecipients(),
        ])
        if (!cancelled) {
          setData({ received, sent, napkins, openSent })
          setRecipients(recips)
          setLoading(false)
        }
      } catch (err) {
        if (!cancelled) {
          console.error('Daily report fetch failed', err)
          setError(err instanceof Error ? err.message : 'Failed to load today\'s data')
          setLoading(false)
        }
      }
    })()
    return () => { cancelled = true }
  }, [])


  // Napkin-pool exclusion + full/partial split (mirrors the email builder)
  const fullReceived = useMemo(
    () => (data?.received ?? []).filter((o) => nonPoolItems(o).length > 0 && !isPartialOrder(o)), [data])
  const partialReceived = useMemo(
    () => (data?.received ?? []).filter((o) => nonPoolItems(o).length > 0 && isPartialOrder(o)), [data])
  const sentNonPool = useMemo(
    () => (data?.sent ?? []).filter((o) => nonPoolItems(o).length > 0), [data])
  const outstanding = useMemo(
    () => (data?.openSent ?? [])
      .map((o) => ({ ...o, items: o.items.filter((i) => !isPoolItem(i.item)) }))
      // Exclude tickets sent today (days === 0) — they show under "Sent Today",
      // not as outstanding (they're not overdue, they just left).
      .filter((o) => o.items.length > 0 && o.days >= 1),
    [data])

  const counts = useMemo(() => {
    const sentItems = sentNonPool.reduce(
      (s, o) => s + nonPoolItems(o).reduce((ss, i) => ss + (i.quantity_sent || 0), 0), 0)
    const receivedItems = [...fullReceived, ...partialReceived].reduce(
      (s, o) => s + nonPoolItems(o).reduce((ss, i) => ss + (i.quantity_received ?? 0), 0), 0)
    const napkinsQty = (data?.napkins ?? []).reduce((s, n) => s + (n.quantity || 0), 0)
    return {
      sent: sentNonPool.length,
      sentItems,
      received: fullReceived.length,
      partial: partialReceived.length,
      receivedItems,
      napkins: data?.napkins.length ?? 0,
      napkinsQty,
    }
  }, [data, fullReceived, partialReceived, sentNonPool])

  const outstandingTotal = outstanding.reduce((s, o) => s + o.items.reduce((ss, i) => ss + i.awaited, 0), 0)
  const isEmpty = !loading && data && counts.sent === 0 && counts.received === 0 && counts.partial === 0 && counts.napkins === 0

  async function handleSend() {
    if (!data || sending) return
    setSending(true)
    setError(null)

    try {
      // Get current dashboard user info for sender tag + audit
      const { data: { user } } = await supabase.auth.getUser()
      let senderName = 'Dashboard'
      if (user) {
        const { data: du } = await supabase.from('dashboard_users').select('name, email').eq('id', user.id).single()
        senderName = du?.name || du?.email || senderName
      }

      const emails = recipients.map((r) => r.email)
      if (emails.length === 0) throw new Error('No report recipients configured — add at least one on the Configuration page')

      // Send via Edge Function with the exact payload we previewed
      const { data: result, error: invokeError } = await supabase.functions.invoke('daily-report', {
        body: {
          receivedOrders: data.received,
          sentOrders: data.sent,
          outstandingOrders: data.openSent,
          napkinReturns: data.napkins,
          recipients: emails,
          senderName,
        },
      })

      if (invokeError) {
        const msg = invokeError instanceof Error ? invokeError.message : String(invokeError)
        throw new Error(msg)
      }
      if (result?.success === false) {
        const failed = (result?.emails ?? []).filter((e: { ok: boolean }) => !e.ok)
        throw new Error(`Some emails failed to send: ${failed.map((e: { to: string; error?: string }) => `${e.to} (${e.error || 'unknown'})`).join(', ')}`)
      }

      // Audit row in daily_report_log
      // NOTE: collected_* audit columns now hold the "sent to laundry" figures
      // (status renamed collected -> sent on 2026-06-12; columns kept for history).
      const { error: logError } = await supabase.from('daily_report_log').insert({
        sent_by_user_id: user?.id ?? null,
        sent_by_name: senderName,
        collected_count: counts.sent,
        received_count: counts.received,
        outstanding_qty: outstandingTotal,
        napkin_returns_count: counts.napkins,
        napkin_returns_qty: counts.napkinsQty,
        collected_order_ids: data.sent.map((o) => o.id),
        received_order_ids: data.received.map((o) => o.id),
        napkin_ledger_ids: data.napkins.map((n) => n.id),
        email_recipients: emails,
        send_result: result,
      })
      if (logError) {
        // Don't block the user — log to console but treat send as successful
        console.warn('daily_report_log insert failed (email was sent):', logError.message)
      }

      // Activity panel + toast
      logActivity({
        type: 'daily_report_sent',
        reportSummary: {
          collected: counts.sent,
          received: counts.received,
          outstanding: outstandingTotal,
          napkins: counts.napkinsQty,
        },
      })
      showStatusToast({
        customLabel: 'Daily report sent',
        subtitle: `Emailed to ${emails.length} recipient${emails.length !== 1 ? 's' : ''}`,
      })

      onClose()
    } catch (err) {
      console.error('Send daily report failed', err)
      setError(err instanceof Error ? err.message : 'Failed to send report')
      setSending(false)
    }
  }

  const today = format(new Date(), 'd MMM yyyy')

  return (
    <div className="fixed inset-0 z-[60] flex items-center justify-center p-4 bg-black/40">
      <div className="bg-white dark:bg-gray-800 rounded-2xl shadow-2xl w-full max-w-3xl max-h-[90vh] flex flex-col overflow-hidden">
        {/* Header */}
        <div className="px-6 py-4 border-b border-gray-200 dark:border-gray-700 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-lg bg-navy/10 flex items-center justify-center">
              <FileText className="w-5 h-5 text-navy" />
            </div>
            <div>
              <h2 className="font-semibold text-gray-900 dark:text-white">Send Daily Report</h2>
              <p className="text-xs text-gray-500 dark:text-gray-400">{today} — preview before sending</p>
            </div>
          </div>
          <button
            onClick={onClose}
            disabled={sending}
            className="p-1.5 hover:bg-gray-100 dark:hover:bg-gray-700 rounded-lg disabled:opacity-50"
          >
            <X className="w-4 h-4 text-gray-500" />
          </button>
        </div>

        {/* Body */}
        <div className="flex-1 overflow-y-auto px-6 py-4">
          {loading && (
            <div className="flex flex-col items-center justify-center py-16 text-gray-400">
              <Loader2 className="w-8 h-8 animate-spin mb-3" />
              <p className="text-sm">Loading today's activity…</p>
            </div>
          )}

          {error && !loading && (
            <div className="flex items-start gap-3 p-4 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg mb-4">
              <AlertCircle className="w-5 h-5 text-red-500 flex-shrink-0 mt-0.5" />
              <div>
                <p className="text-sm font-medium text-red-800 dark:text-red-300">Couldn't complete</p>
                <p className="text-xs text-red-700 dark:text-red-400 mt-1">{error}</p>
              </div>
            </div>
          )}

          {!loading && data && (
            <>
              {/* Summary cards */}
              <div className="grid grid-cols-2 md:grid-cols-4 gap-3 mb-5">
                <SummaryCard
                  icon={<Package className="w-4 h-4" />}
                  label="Received"
                  value={counts.received + counts.partial}
                  detail={`${counts.receivedItems} items${counts.partial > 0 ? ` • ${counts.partial} partial` : ''}`}
                  color={counts.partial > 0 ? 'orange' : counts.received > 0 ? 'teal' : 'gray'}
                />
                <SummaryCard
                  icon={<Truck className="w-4 h-4" />}
                  label="Sent"
                  value={counts.sent}
                  detail={`${counts.sentItems} items`}
                  color={counts.sent > 0 ? 'orange' : 'gray'}
                />
                <SummaryCard
                  icon={<AlertCircle className="w-4 h-4" />}
                  label="Outstanding"
                  value={outstandingTotal}
                  detail={`${outstanding.length} ticket${outstanding.length !== 1 ? 's' : ''} at laundry`}
                  color={outstandingTotal > 0 ? 'red' : 'green'}
                />
                <SummaryCard
                  icon={<UtensilsCrossed className="w-4 h-4" />}
                  label="Napkin Returns"
                  value={counts.napkinsQty}
                  detail={`${counts.napkins} entr${counts.napkins !== 1 ? 'ies' : 'y'}`}
                  color={counts.napkinsQty > 0 ? 'purple' : 'gray'}
                />
              </div>

              {isEmpty && (
                <div className="text-center py-8 text-gray-400 italic text-sm">
                  No activity recorded today. Sending an empty report won't include any items.
                </div>
              )}

              {/* 1. Received today — complete tickets */}
              {fullReceived.length > 0 && (
                <PreviewSection title="Received Today" tone="teal" countLabel={`${counts.received} order${counts.received !== 1 ? 's' : ''} complete`}>
                  <OrderListTable orders={fullReceived} mode="received" />
                </PreviewSection>
              )}

              {/* 2. Partially received — came back short */}
              {partialReceived.length > 0 && (
                <PreviewSection title="Partially Received Today" tone="orange" countLabel={`${counts.partial} ticket${counts.partial !== 1 ? 's' : ''} came back short`}>
                  <table className="w-full text-xs">
                    <thead>
                      <tr className="text-left text-gray-500 border-b border-gray-200 dark:border-gray-700">
                        <th className="py-1.5 pr-2">Docket</th>
                        <th className="py-1.5 pr-2">Name</th>
                        <th className="py-1.5 pr-2">Dept</th>
                        <th className="py-1.5 pr-2 text-right">Received</th>
                        <th className="py-1.5 text-left text-red-600">Still Awaiting</th>
                      </tr>
                    </thead>
                    <tbody>
                      {partialReceived.map((o) => {
                        const items = nonPoolItems(o)
                        const totalSent = items.reduce((s, i) => s + (i.quantity_sent || 0), 0)
                        const totalRecv = items.reduce((s, i) => s + (i.quantity_received ?? 0), 0)
                        const awaiting = items
                          .filter((i) => (i.quantity_received ?? 0) < (i.quantity_sent || 0))
                          .map((i) => `${(i.quantity_sent || 0) - (i.quantity_received ?? 0)}× ${i.item_name}`)
                          .join(', ')
                        return (
                          <tr key={o.id} className="border-b border-gray-100 dark:border-gray-700/50 last:border-0">
                            <td className="py-1.5 pr-2 font-mono">#{o.docket_number}</td>
                            <td className="py-1.5 pr-2">{o.staff_name || o.guest_name || '—'}</td>
                            <td className="py-1.5 pr-2">{o.departments?.name || '—'}</td>
                            <td className="py-1.5 pr-2 text-right">{totalRecv} of {totalSent}</td>
                            <td className="py-1.5 font-medium text-red-600">{awaiting}</td>
                          </tr>
                        )
                      })}
                    </tbody>
                  </table>
                </PreviewSection>
              )}

              {/* 3. Sent today — what the laundry company collected (napkin pool excluded) */}
              {sentNonPool.length > 0 && (
                <PreviewSection title="Sent to Laundry Today" tone="orange" countLabel={`${counts.sent} order${counts.sent !== 1 ? 's' : ''}, ${counts.sentItems} items`}>
                  <OrderListTable orders={sentNonPool} mode="sent" />
                </PreviewSection>
              )}

              {/* 3. Outstanding — everything still at the laundry, with aging */}
              {outstanding.length > 0 && (
                <PreviewSection title="Still at Laundry (Not Received)" tone="red" countLabel={`${outstandingTotal} item${outstandingTotal !== 1 ? 's' : ''} across ${outstanding.length} ticket${outstanding.length !== 1 ? 's' : ''}`}>
                  <table className="w-full text-xs">
                    <thead>
                      <tr className="text-left text-gray-500 border-b border-gray-200 dark:border-gray-700">
                        <th className="py-1.5 pr-2">Docket</th>
                        <th className="py-1.5 pr-2">Dept</th>
                        <th className="py-1.5 pr-2">Name</th>
                        <th className="py-1.5 pr-2">Awaiting</th>
                        <th className="py-1.5 text-right">Days</th>
                      </tr>
                    </thead>
                    <tbody>
                      {outstanding.map((o) => (
                        <tr key={o.id} className="border-b border-gray-100 dark:border-gray-700/50 last:border-0">
                          <td className="py-1.5 pr-2 font-mono">
                            #{o.docket}
                            {o.isChild && <span className="ml-1 text-[10px] text-amber-600 font-sans">(partial)</span>}
                          </td>
                          <td className="py-1.5 pr-2">{o.department}</td>
                          <td className="py-1.5 pr-2">{o.name}</td>
                          <td className="py-1.5 pr-2 text-gray-600">
                            {o.items.map((i) => `${i.awaited}× ${i.item}`).join(', ')}
                          </td>
                          <td className={`py-1.5 text-right font-bold ${
                            o.days >= 7 ? 'text-red-600' : o.days >= 3 ? 'text-amber-600' : 'text-gray-500'
                          }`}>
                            {o.days}d{o.days >= 7 ? ' ⚠' : ''}
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </PreviewSection>
              )}

              {/* Napkins section */}
              {data.napkins.length > 0 && (
                <PreviewSection title="Napkin Returns" tone="purple" countLabel={`${counts.napkinsQty} napkin${counts.napkinsQty !== 1 ? 's' : ''} across ${counts.napkins} entr${counts.napkins !== 1 ? 'ies' : 'y'}`}>
                  <table className="w-full text-xs">
                    <thead>
                      <tr className="text-left text-gray-500 border-b border-gray-200 dark:border-gray-700">
                        <th className="py-1.5 pr-2">Department</th>
                        <th className="py-1.5 pr-2 text-right">Qty</th>
                        <th className="py-1.5">Note</th>
                      </tr>
                    </thead>
                    <tbody>
                      {data.napkins.map((n) => (
                        <tr key={n.id} className="border-b border-gray-100 dark:border-gray-700/50 last:border-0">
                          <td className="py-1.5 pr-2">{n.department?.name || '—'}</td>
                          <td className="py-1.5 pr-2 text-right font-medium">{n.quantity}</td>
                          <td className="py-1.5 text-gray-500">{n.note || '—'}</td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </PreviewSection>
              )}

              {/* Recipients note — list is managed on the Configuration page */}
              <div className="mt-4 px-3 py-2 bg-gray-50 dark:bg-gray-700/30 rounded-lg text-xs text-gray-500 dark:text-gray-400 flex items-start gap-2">
                <Mail className="w-3.5 h-3.5 mt-0.5 shrink-0" />
                <span>
                  {recipients.length > 0
                    ? <>Will be emailed to: {recipients.map((r) => r.email).join(', ')}</>
                    : <span className="text-red-600 font-medium">No recipients configured — add some on the Configuration page before sending.</span>}
                  {' '}<a href="#/configuration" className="underline hover:text-navy">Manage recipients</a>
                </span>
              </div>
            </>
          )}
        </div>

        {/* Footer */}
        <div className="px-6 py-3 border-t border-gray-200 dark:border-gray-700 flex items-center justify-end gap-2">
          <button
            onClick={onClose}
            disabled={sending}
            className="px-4 py-2 text-sm text-gray-600 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-700 rounded-lg disabled:opacity-50"
          >
            Cancel
          </button>
          <button
            onClick={handleSend}
            disabled={loading || sending || !data || recipients.length === 0}
            className="flex items-center gap-2 px-5 py-2 text-sm font-medium text-white bg-navy hover:bg-navy-light rounded-lg disabled:bg-gray-300 disabled:cursor-not-allowed"
          >
            {sending ? (
              <>
                <Loader2 className="w-4 h-4 animate-spin" />
                Sending…
              </>
            ) : (
              <>
                <Send className="w-4 h-4" />
                Send Now
              </>
            )}
          </button>
        </div>
      </div>
    </div>
  )
}

function SummaryCard({ icon, label, value, detail, color }: {
  icon: React.ReactNode
  label: string
  value: number
  detail: string
  color: 'teal' | 'orange' | 'red' | 'green' | 'purple' | 'gray'
}) {
  const colorMap: Record<typeof color, { bg: string; text: string }> = {
    teal: { bg: 'bg-teal-50 dark:bg-teal-900/20', text: 'text-teal-700 dark:text-teal-300' },
    orange: { bg: 'bg-orange-50 dark:bg-orange-900/20', text: 'text-orange-700 dark:text-orange-300' },
    red: { bg: 'bg-red-50 dark:bg-red-900/20', text: 'text-red-700 dark:text-red-300' },
    green: { bg: 'bg-green-50 dark:bg-green-900/20', text: 'text-green-700 dark:text-green-300' },
    purple: { bg: 'bg-purple-50 dark:bg-purple-900/20', text: 'text-purple-700 dark:text-purple-300' },
    gray: { bg: 'bg-gray-50 dark:bg-gray-700/30', text: 'text-gray-500 dark:text-gray-400' },
  }
  const cls = colorMap[color]
  return (
    <div className={`rounded-lg p-3 ${cls.bg}`}>
      <div className={`flex items-center gap-1.5 text-[11px] font-medium ${cls.text}`}>
        {icon}
        {label}
      </div>
      <p className={`mt-1 text-2xl font-bold ${cls.text}`}>{value}</p>
      <p className="text-[10px] text-gray-500 dark:text-gray-400 mt-0.5">{detail}</p>
    </div>
  )
}

function PreviewSection({ title, tone, countLabel, children }: {
  title: string
  tone: 'red' | 'teal' | 'orange' | 'purple'
  countLabel: string
  children: React.ReactNode
}) {
  const toneMap: Record<typeof tone, string> = {
    red: 'border-red-200 dark:border-red-800 bg-red-50/50 dark:bg-red-900/10',
    teal: 'border-teal-200 dark:border-teal-800 bg-teal-50/50 dark:bg-teal-900/10',
    orange: 'border-orange-200 dark:border-orange-800 bg-orange-50/50 dark:bg-orange-900/10',
    purple: 'border-purple-200 dark:border-purple-800 bg-purple-50/50 dark:bg-purple-900/10',
  }
  const headerToneMap: Record<typeof tone, string> = {
    red: 'text-red-700 dark:text-red-300',
    teal: 'text-teal-700 dark:text-teal-300',
    orange: 'text-orange-700 dark:text-orange-300',
    purple: 'text-purple-700 dark:text-purple-300',
  }
  return (
    <div className={`mb-4 border rounded-lg overflow-hidden ${toneMap[tone]}`}>
      <div className="px-3 py-2 border-b border-gray-200 dark:border-gray-700/50 flex items-center justify-between">
        <h3 className={`text-sm font-semibold ${headerToneMap[tone]}`}>{title}</h3>
        <span className="text-[11px] text-gray-500 dark:text-gray-400">{countLabel}</span>
      </div>
      <div className="px-3 py-2 bg-white dark:bg-gray-800 overflow-x-auto">
        {children}
      </div>
    </div>
  )
}

function OrderListTable({ orders, mode }: { orders: ReportOrder[]; mode: 'received' | 'sent' }) {
  const showReceived = mode === 'received'
  return (
    <table className="w-full text-xs">
      <thead>
        <tr className="text-left text-gray-500 border-b border-gray-200 dark:border-gray-700">
          <th className="py-1.5 pr-2">Docket</th>
          <th className="py-1.5 pr-2">Name</th>
          <th className="py-1.5 pr-2">Dept</th>
          <th className="py-1.5 pr-2">Items</th>
          <th className="py-1.5 pr-2 text-right">Sent</th>
          {showReceived && <th className="py-1.5 pr-2 text-right">Recv</th>}
          {showReceived && <th className="py-1.5 text-right">Out</th>}
        </tr>
      </thead>
      <tbody>
        {orders.map((o) => {
          const items = nonPoolItems(o)
          const totalSent = items.reduce((s, i) => s + (i.quantity_sent || 0), 0)
          const totalRecv = items.reduce((s, i) => s + (i.quantity_received ?? 0), 0)
          const out = totalSent - totalRecv
          const itemsDesc = items.map((i) => `${i.quantity_sent}× ${i.item_name}`).join(', ')
          return (
            <tr key={o.id} className="border-b border-gray-100 dark:border-gray-700/50 last:border-0">
              <td className="py-1.5 pr-2 font-mono">#{o.docket_number}</td>
              <td className="py-1.5 pr-2">{o.staff_name || o.guest_name || '—'}</td>
              <td className="py-1.5 pr-2">{o.departments?.name || '—'}</td>
              <td className="py-1.5 pr-2 text-gray-500 max-w-xs truncate" title={itemsDesc}>{itemsDesc || '—'}</td>
              <td className="py-1.5 pr-2 text-right">{totalSent}</td>
              {showReceived && <td className="py-1.5 pr-2 text-right">{totalRecv}</td>}
              {showReceived && (
                <td className={`py-1.5 text-right font-medium ${out > 0 ? 'text-red-600' : 'text-green-600'}`}>
                  {out > 0 ? out : <CheckCircle className="w-3.5 h-3.5 inline" />}
                </td>
              )}
            </tr>
          )
        })}
      </tbody>
    </table>
  )
}
