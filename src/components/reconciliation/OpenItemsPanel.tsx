import { useEffect, useState } from 'react'
import { ListChecks } from 'lucide-react'
import { supabase } from '../../lib/supabase'
import { computeOrderCost } from '../../lib/orderCost'
import { fetchCreditRequests, fetchOpenExpected, phase1Available } from '../../lib/reconPhase1'
import type { Order } from '../../types'

// Open items across all invoices: credits Goldstar still owes, orders expected on a later
// invoice, explained lines whose recharge is still pending, and saved reconciliations that
// still have unresolved lines. Shown on Recon History.

interface Row { label: string; count: number; amount: number; oldest: string; tone: string }
const money = (n: number) => `£${n.toFixed(2)}`

export default function OpenItemsPanel() {
  const [rows, setRows] = useState<Row[] | null>(null)

  useEffect(() => {
    (async () => {
      if (!(await phase1Available())) { setRows([]); return }
      // All four lookups at once: one round trip of waiting instead of four
      const [credits, expected, { data: pending }, { data: recs }] = await Promise.all([
        fetchCreditRequests({ openOnly: true }),
        fetchOpenExpected(''),
        supabase.from('reconciliation_line_notes').select('invoice_number, net, group_name').eq('recharge_status', 'not_yet').limit(500),
        supabase.from('reconciliations').select('invoice_number, created_at, not_found_count, missing_count').order('created_at', { ascending: false }).limit(200),
      ])
      const out: Row[] = []
      if (credits.length) {
        const oldest = credits.reduce((a, b) => (a.requested_at < b.requested_at ? a : b))
        out.push({ label: 'Credit notes awaiting Goldstar', count: credits.length, amount: credits.reduce((s, c) => s + c.total - (c.received_amount ?? 0), 0),
          oldest: `${oldest.invoice_number} · ${Math.floor((Date.now() - new Date(oldest.requested_at).getTime()) / 86_400_000)} days`, tone: 'text-orange-600' })
      }
      if (expected.length) {
        const { data } = await supabase.from('orders').select('id, total_price, not_charged_at, order_items(price_at_time, quantity_sent)').in('id', expected.map(e => e.order_id))
        const amount = ((data as Order[] | null) ?? []).reduce((s, o) => s + computeOrderCost(o), 0)
        out.push({ label: 'Expected on a later invoice (not found yet)', count: expected.length, amount, oldest: [...new Set(expected.map(e => e.invoice_number))].join(', '), tone: 'text-gray-700' })
      }
      if (pending?.length) {
        out.push({ label: 'Explained, recharge to group/guest pending', count: pending.length, amount: pending.reduce((s, p) => s + Number(p.net ?? 0), 0),
          oldest: [...new Set(pending.map(p => p.group_name).filter(Boolean))].slice(0, 3).join(', '), tone: 'text-indigo-700' })
      }
      // Invoices whose latest saved reconciliation still has unresolved lines (counted per invoice)
      const latest = new Map<string, { not_found_count: number; missing_count: number }>()
      for (const r of recs ?? []) if (r.invoice_number && !latest.has(r.invoice_number)) latest.set(r.invoice_number, r)
      const open = [...latest.entries()].filter(([, r]) => (r.not_found_count ?? 0) + (r.missing_count ?? 0) > 0)
      if (open.length) {
        const lines = open.reduce((s, [, r]) => s + (r.not_found_count ?? 0) + (r.missing_count ?? 0), 0)
        const shown = open.slice(0, 4).map(([inv]) => inv).join(', ')
        out.push({ label: 'Invoices with unresolved lines (latest save)', count: open.length, amount: NaN,
          oldest: `${shown}${open.length > 4 ? ` +${open.length - 4} more` : ''} · ${lines} lines`, tone: 'text-red-700' })
      }
      setRows(out)
    })()
  }, [])

  if (!rows || rows.length === 0) return null
  return (
    <div className="bg-white rounded-xl border border-gray-200 overflow-hidden">
      <div className="px-5 py-3 border-b border-gray-200 flex items-center gap-2"><ListChecks className="w-4 h-4 text-navy" /><h3 className="text-sm font-semibold text-gray-900">Open items: all invoices</h3></div>
      <table className="w-full text-sm">
        <thead><tr className="border-b border-gray-200 bg-gray-50 text-xs text-gray-600"><th className="px-4 py-2 text-left font-medium">Type</th><th className="px-4 text-right font-medium">Items</th><th className="px-4 text-right font-medium">£ NET / total</th><th className="px-4 text-left font-medium">Oldest / where</th></tr></thead>
        <tbody className="divide-y divide-gray-100">
          {rows.map(r => (
            <tr key={r.label}><td className="px-4 py-2.5">{r.label}</td><td className="px-4 text-right">{r.count}</td><td className={`px-4 text-right font-medium ${r.tone}`}>{isNaN(r.amount) ? '—' : money(r.amount)}</td><td className="px-4 text-xs text-gray-600">{r.oldest}</td></tr>
          ))}
        </tbody>
      </table>
    </div>
  )
}
