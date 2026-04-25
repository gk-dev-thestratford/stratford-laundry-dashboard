import { useState, useEffect, useMemo } from 'react'
import { X, Send, AlertCircle, CheckCircle, FileText, Truck, Package, UtensilsCrossed, Loader2 } from 'lucide-react'
import { format } from 'date-fns'
import { supabase } from '../lib/supabase'
import { logActivity } from '../hooks/useSessionActivity'
import { showStatusToast } from './StatusToast'

const REPORT_RECIPIENTS = [
  'kunov.georgi@gmail.com',
  'georgi@thestratford.com',
  'set1000@hotmail.com',
]

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
  collected: ReportOrder[]
  received: ReportOrder[]
  napkins: NapkinReturn[]
}

interface OutstandingItem {
  docket: string
  department: string
  item: string
  sent: number
  received: number
  outstanding: number
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

function extractOutstanding(received: ReportOrder[]): OutstandingItem[] {
  const items: OutstandingItem[] = []
  for (const o of received) {
    for (const i of o.order_items || []) {
      const sent = i.quantity_sent || 0
      const recvd = i.quantity_received ?? 0
      const out = sent - recvd
      if (out > 0) {
        items.push({
          docket: o.docket_number,
          department: o.departments?.name || '—',
          item: i.item_name,
          sent,
          received: recvd,
          outstanding: out,
        })
      }
    }
  }
  return items
}

export default function DailyReportModal({ onClose }: DailyReportModalProps) {
  const [data, setData] = useState<ReportData | null>(null)
  const [loading, setLoading] = useState(true)
  const [sending, setSending] = useState(false)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    let cancelled = false
    ;(async () => {
      try {
        const [collected, received, napkins] = await Promise.all([
          fetchOrdersByStatus('collected'),
          fetchOrdersByStatus('received'),
          fetchTodaysNapkinReturns(),
        ])
        if (!cancelled) {
          setData({ collected, received, napkins })
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

  const outstanding = useMemo(
    () => (data ? extractOutstanding(data.received) : []),
    [data],
  )

  const counts = useMemo(() => {
    if (!data) return { collected: 0, collectedItems: 0, received: 0, receivedItems: 0, napkins: 0, napkinsQty: 0 }
    const collectedItems = data.collected.reduce(
      (s, o) => s + (o.order_items || []).reduce((ss, i) => ss + (i.quantity_sent || 0), 0), 0)
    const receivedItems = data.received.reduce(
      (s, o) => s + (o.order_items || []).reduce((ss, i) => ss + (i.quantity_received ?? 0), 0), 0)
    const napkinsQty = data.napkins.reduce((s, n) => s + (n.quantity || 0), 0)
    return {
      collected: data.collected.length,
      collectedItems,
      received: data.received.length,
      receivedItems,
      napkins: data.napkins.length,
      napkinsQty,
    }
  }, [data])

  const outstandingTotal = outstanding.reduce((s, i) => s + i.outstanding, 0)
  const isEmpty = !loading && data && counts.collected === 0 && counts.received === 0 && counts.napkins === 0

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

      // Send via Edge Function with the exact payload we previewed
      const { data: result, error: invokeError } = await supabase.functions.invoke('daily-report', {
        body: {
          collectedOrders: data.collected,
          receivedOrders: data.received,
          napkinReturns: data.napkins,
          recipients: REPORT_RECIPIENTS,
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
      const { error: logError } = await supabase.from('daily_report_log').insert({
        sent_by_user_id: user?.id ?? null,
        sent_by_name: senderName,
        collected_count: counts.collected,
        received_count: counts.received,
        outstanding_qty: outstandingTotal,
        napkin_returns_count: counts.napkins,
        napkin_returns_qty: counts.napkinsQty,
        collected_order_ids: data.collected.map((o) => o.id),
        received_order_ids: data.received.map((o) => o.id),
        napkin_ledger_ids: data.napkins.map((n) => n.id),
        email_recipients: REPORT_RECIPIENTS,
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
          collected: counts.collected,
          received: counts.received,
          outstanding: outstandingTotal,
          napkins: counts.napkinsQty,
        },
      })
      showStatusToast({
        customLabel: 'Daily report sent',
        subtitle: `Emailed to ${REPORT_RECIPIENTS.length} recipient${REPORT_RECIPIENTS.length !== 1 ? 's' : ''}`,
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
                  value={counts.received}
                  detail={`${counts.receivedItems} items`}
                  color={counts.received > 0 ? 'teal' : 'gray'}
                />
                <SummaryCard
                  icon={<Truck className="w-4 h-4" />}
                  label="Collected"
                  value={counts.collected}
                  detail={`${counts.collectedItems} items`}
                  color={counts.collected > 0 ? 'orange' : 'gray'}
                />
                <SummaryCard
                  icon={<AlertCircle className="w-4 h-4" />}
                  label="Outstanding"
                  value={outstandingTotal}
                  detail={`${outstanding.length} item${outstanding.length !== 1 ? 's' : ''}`}
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

              {/* Outstanding section */}
              {outstanding.length > 0 && (
                <PreviewSection title="Outstanding Items" tone="red" countLabel={`${outstandingTotal} item${outstandingTotal !== 1 ? 's' : ''} not returned`}>
                  <table className="w-full text-xs">
                    <thead>
                      <tr className="text-left text-gray-500 border-b border-gray-200 dark:border-gray-700">
                        <th className="py-1.5 pr-2">Docket</th>
                        <th className="py-1.5 pr-2">Dept</th>
                        <th className="py-1.5 pr-2">Item</th>
                        <th className="py-1.5 pr-2 text-right">Sent</th>
                        <th className="py-1.5 pr-2 text-right">Recv</th>
                        <th className="py-1.5 text-right text-red-600">Out</th>
                      </tr>
                    </thead>
                    <tbody>
                      {outstanding.map((o, i) => (
                        <tr key={i} className="border-b border-gray-100 dark:border-gray-700/50 last:border-0">
                          <td className="py-1.5 pr-2 font-mono">#{o.docket}</td>
                          <td className="py-1.5 pr-2">{o.department}</td>
                          <td className="py-1.5 pr-2">{o.item}</td>
                          <td className="py-1.5 pr-2 text-right">{o.sent}</td>
                          <td className="py-1.5 pr-2 text-right">{o.received}</td>
                          <td className="py-1.5 text-right font-bold text-red-600">{o.outstanding}</td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </PreviewSection>
              )}

              {/* Received section */}
              {data.received.length > 0 && (
                <PreviewSection title="Received Today" tone="teal" countLabel={`${counts.received} order${counts.received !== 1 ? 's' : ''}, ${counts.receivedItems} items`}>
                  <OrderListTable orders={data.received} mode="received" />
                </PreviewSection>
              )}

              {/* Collected section */}
              {data.collected.length > 0 && (
                <PreviewSection title="Collected Today" tone="orange" countLabel={`${counts.collected} order${counts.collected !== 1 ? 's' : ''}, ${counts.collectedItems} items`}>
                  <OrderListTable orders={data.collected} mode="collected" />
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

              {/* Recipients note */}
              <div className="mt-4 px-3 py-2 bg-gray-50 dark:bg-gray-700/30 rounded-lg text-xs text-gray-500 dark:text-gray-400">
                Will be emailed to: {REPORT_RECIPIENTS.join(', ')}
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
            disabled={loading || sending || !data}
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

function OrderListTable({ orders, mode }: { orders: ReportOrder[]; mode: 'received' | 'collected' }) {
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
          const totalSent = (o.order_items || []).reduce((s, i) => s + (i.quantity_sent || 0), 0)
          const totalRecv = (o.order_items || []).reduce((s, i) => s + (i.quantity_received ?? 0), 0)
          const out = totalSent - totalRecv
          const itemsDesc = (o.order_items || []).map((i) => `${i.quantity_sent}× ${i.item_name}`).join(', ')
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
