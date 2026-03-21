import { useState, useMemo, useCallback } from 'react'
import { Upload, RefreshCw, Download, CheckCircle, AlertTriangle, XCircle, HelpCircle, FileText, X } from 'lucide-react'
import { supabase } from '../lib/supabase'
import {
  extractPdfLines, parseInvoice, parseInvoicePeriod,
  sectionTypeToOrderType,
  type ParsedInvoice, type InvoiceLine,
} from '../lib/invoiceParser'
import type { Order } from '../types'
import { ORDER_TYPE_LABELS } from '../types'
import { utils, writeFile } from 'xlsx'
import { format } from 'date-fns'

// ── Reconciliation types ──

interface ReconciliationRow {
  invoiceLine: InvoiceLine
  sectionType: string
  order: Order | null
  status: 'matched' | 'price_mismatch' | 'not_found'
  systemTotal: number
  difference: number
}

interface ReconciliationResult {
  rows: ReconciliationRow[]
  topUpCharges: InvoiceLine[]
  missingFromInvoice: Order[]
  stats: { matched: number; priceMismatch: number; notFound: number; missing: number }
  invoiceTotal: number
  systemTotal: number
}

// ── Helpers ──

function computeOrderCost(o: Order): number {
  if (o.order_items && o.order_items.length > 0) {
    const t = o.order_items.reduce((s, i) => s + (i.price_at_time ?? 0) * (i.quantity_sent ?? 0), 0)
    if (t > 0) return t
  }
  return o.total_price ?? 0
}

function reconcile(invoice: ParsedInvoice, orders: Order[]): ReconciliationResult {
  // Build lookup maps
  const byDocket = new Map<string, Order>()
  const byRoom = new Map<string, Order[]>()
  for (const o of orders) {
    byDocket.set(o.docket_number, o)
    if (o.room_number) {
      if (!byRoom.has(o.room_number)) byRoom.set(o.room_number, [])
      byRoom.get(o.room_number)!.push(o)
    }
  }

  const rows: ReconciliationRow[] = []
  const topUpCharges: InvoiceLine[] = []
  const matchedOrderIds = new Set<string>()

  for (const section of invoice.sections) {
    const orderType = sectionTypeToOrderType(section.type)

    for (const line of section.lines) {
      if (line.isTopUp) { topUpCharges.push(line); continue }

      // Try match by docket number
      let order = byDocket.get(line.ticket) ?? null

      // For guest invoices, try room number match
      if (!order && section.type === 'guest' && line.ticket) {
        const candidates = byRoom.get(line.ticket) ?? []
        if (candidates.length === 1) order = candidates[0]
        else if (candidates.length > 1 && line.guestInfo) {
          const name = line.guestInfo.replace(/[()]/g, '').toLowerCase()
          order = candidates.find(o =>
            o.guest_name?.toLowerCase().includes(name)
          ) ?? candidates[0]
        }
      }

      if (order) matchedOrderIds.add(order.id)

      const systemTotal = order ? computeOrderCost(order) : 0
      const diff = order ? +(line.net - systemTotal).toFixed(2) : line.net
      const status: ReconciliationRow['status'] = !order
        ? 'not_found'
        : Math.abs(diff) < 0.02 ? 'matched' : 'price_mismatch'

      rows.push({ invoiceLine: line, sectionType: orderType, order, status, systemTotal, difference: diff })
    }
  }

  // Orders in system not on invoice (same period/type)
  const invoiceOrderTypes = new Set(invoice.sections.map(s => sectionTypeToOrderType(s.type)))
  const missingFromInvoice = orders.filter(o =>
    !matchedOrderIds.has(o.id) && invoiceOrderTypes.has(o.order_type)
  )

  const stats = {
    matched: rows.filter(r => r.status === 'matched').length,
    priceMismatch: rows.filter(r => r.status === 'price_mismatch').length,
    notFound: rows.filter(r => r.status === 'not_found').length,
    missing: missingFromInvoice.length,
  }

  return {
    rows, topUpCharges, missingFromInvoice, stats,
    invoiceTotal: rows.reduce((s, r) => s + r.invoiceLine.net, 0),
    systemTotal: rows.reduce((s, r) => s + r.systemTotal, 0),
  }
}

type FilterTab = 'all' | 'matched' | 'mismatch' | 'not_found' | 'missing'

// ── Component ──

export default function Reconciliation() {
  const [file, setFile] = useState<File | null>(null)
  const [parsing, setParsing] = useState(false)
  const [error, setError] = useState('')
  const [invoice, setInvoice] = useState<ParsedInvoice | null>(null)
  const [orders, setOrders] = useState<Order[]>([])
  const [result, setResult] = useState<ReconciliationResult | null>(null)
  const [filter, setFilter] = useState<FilterTab>('all')
  const [dragOver, setDragOver] = useState(false)

  // ── Upload & parse ──

  async function handleFile(f: File) {
    if (!f.type.includes('pdf')) { setError('Please upload a PDF file'); return }
    setFile(f)
    setError('')
    setParsing(true)
    setInvoice(null)
    setResult(null)

    try {
      const lines = await extractPdfLines(f)
      const parsed = parseInvoice(lines)

      if (parsed.sections.every(s => s.lines.length === 0)) {
        setError('Could not parse any invoice lines. The PDF format may not be supported.')
        setParsing(false)
        return
      }

      setInvoice(parsed)

      // Fetch orders for the invoice period
      const period = parseInvoicePeriod(parsed.invoicePeriod)
      let fetchedOrders: Order[] = []

      if (period) {
        const { data } = await supabase
          .from('orders')
          .select('*, department:departments(*), order_items(*)')
          .gte('created_at', period.start.toISOString())
          .lte('created_at', period.end.toISOString())
          .order('created_at', { ascending: true })
        fetchedOrders = data ?? []
      } else {
        // Fallback: fetch recent orders
        const { data } = await supabase
          .from('orders')
          .select('*, department:departments(*), order_items(*)')
          .order('created_at', { ascending: false })
          .limit(500)
        fetchedOrders = data ?? []
      }

      setOrders(fetchedOrders)
      setResult(reconcile(parsed, fetchedOrders))
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to parse PDF')
    } finally {
      setParsing(false)
    }
  }

  function reset() {
    setFile(null)
    setInvoice(null)
    setOrders([])
    setResult(null)
    setError('')
    setFilter('all')
  }

  // ── Filtered rows ──

  const filteredRows = useMemo(() => {
    if (!result) return []
    if (filter === 'all') return result.rows
    if (filter === 'matched') return result.rows.filter(r => r.status === 'matched')
    if (filter === 'mismatch') return result.rows.filter(r => r.status === 'price_mismatch')
    if (filter === 'not_found') return result.rows.filter(r => r.status === 'not_found')
    return []
  }, [result, filter])

  // ── Export ──

  const exportReconciliation = useCallback(() => {
    if (!result || !invoice) return
    const wb = utils.book_new()

    // Sheet 1: Reconciliation
    const reconRows = result.rows.map(r => ({
      'Status': r.status === 'matched' ? 'Matched' : r.status === 'price_mismatch' ? 'Price Mismatch' : 'Not Found',
      'Date': r.invoiceLine.date,
      'Docket': r.invoiceLine.ticket,
      'Invoice Description': r.invoiceLine.description,
      'Invoice NET (\u00a3)': r.invoiceLine.net,
      'Invoice VAT (\u00a3)': r.invoiceLine.vat,
      'Invoice GROSS (\u00a3)': r.invoiceLine.gross,
      'System Total (\u00a3)': r.order ? r.systemTotal : '',
      'Difference (\u00a3)': r.order ? r.difference : '',
      'System Docket': r.order?.docket_number ?? '',
    }))

    // Add totals row
    reconRows.push({
      'Status': 'TOTAL',
      'Date': '', 'Docket': '', 'Invoice Description': '',
      'Invoice NET (\u00a3)': result.invoiceTotal,
      'Invoice VAT (\u00a3)': +(result.invoiceTotal * 0.2).toFixed(2),
      'Invoice GROSS (\u00a3)': +(result.invoiceTotal * 1.2).toFixed(2),
      'System Total (\u00a3)': result.systemTotal,
      'Difference (\u00a3)': +(result.invoiceTotal - result.systemTotal).toFixed(2),
      'System Docket': '',
    })

    utils.book_append_sheet(wb, utils.json_to_sheet(reconRows), 'Reconciliation')

    // Sheet 2: Additional Charges
    if (result.topUpCharges.length > 0) {
      const topUpRows = result.topUpCharges.map(l => ({
        'Date Range': l.date,
        'Description': l.description,
        'NET (\u00a3)': l.net,
        'VAT (\u00a3)': l.vat,
        'GROSS (\u00a3)': l.gross,
      }))
      const topUpTotal = result.topUpCharges.reduce((s, l) => s + l.net, 0)
      topUpRows.push({
        'Date Range': 'TOTAL', 'Description': '',
        'NET (\u00a3)': +topUpTotal.toFixed(2),
        'VAT (\u00a3)': +(topUpTotal * 0.2).toFixed(2),
        'GROSS (\u00a3)': +(topUpTotal * 1.2).toFixed(2),
      })
      utils.book_append_sheet(wb, utils.json_to_sheet(topUpRows), 'Additional Charges')
    }

    // Sheet 3: Missing from Invoice
    if (result.missingFromInvoice.length > 0) {
      const missRows = result.missingFromInvoice.map(o => ({
        'Docket': o.docket_number,
        'Type': ORDER_TYPE_LABELS[o.order_type] ?? o.order_type,
        'Name': o.staff_name || o.guest_name || '',
        'Items': (o.order_items || []).map(i => `${i.quantity_sent}x ${i.item_name}`).join(', '),
        'System Total (\u00a3)': computeOrderCost(o),
        'Date': format(new Date(o.created_at), 'dd/MM/yyyy'),
      }))
      utils.book_append_sheet(wb, utils.json_to_sheet(missRows), 'Missing from Invoice')
    }

    const invNum = invoice.invoiceNumber || 'reconciliation'
    writeFile(wb, `reconciliation-${invNum}-${format(new Date(), 'yyyy-MM-dd')}.xlsx`)
  }, [result, invoice])

  // ── Render ──

  const statusIcon = (s: ReconciliationRow['status']) => {
    if (s === 'matched') return <CheckCircle className="w-4 h-4 text-green-500" />
    if (s === 'price_mismatch') return <AlertTriangle className="w-4 h-4 text-amber-500" />
    return <XCircle className="w-4 h-4 text-red-500" />
  }

  // Upload state
  if (!invoice && !parsing) {
    return (
      <div className="space-y-6">
        <div>
          <h1 className="text-2xl font-semibold text-gray-900">Invoice Reconciliation</h1>
          <p className="text-sm text-gray-500 mt-1">Upload a Goldstar invoice PDF to cross-check against your orders</p>
        </div>

        {error && (
          <div className="p-3 bg-red-50 border border-red-200 rounded-lg text-sm text-red-700">{error}</div>
        )}

        <label
          onDragOver={(e) => { e.preventDefault(); setDragOver(true) }}
          onDragLeave={() => setDragOver(false)}
          onDrop={(e) => { e.preventDefault(); setDragOver(false); const f = e.dataTransfer.files[0]; if (f) handleFile(f) }}
          className={`flex flex-col items-center justify-center border-2 border-dashed rounded-xl p-16 cursor-pointer transition-colors ${
            dragOver ? 'border-gold bg-gold/5' : 'border-gray-300 hover:border-gold/50 hover:bg-gray-50'
          }`}
        >
          <Upload className={`w-12 h-12 mb-4 ${dragOver ? 'text-gold' : 'text-gray-400'}`} />
          <p className="text-lg font-medium text-gray-700">Drop invoice PDF here</p>
          <p className="text-sm text-gray-500 mt-1">or click to browse</p>
          <input
            type="file"
            accept=".pdf"
            className="hidden"
            onChange={(e) => { const f = e.target.files?.[0]; if (f) handleFile(f) }}
          />
        </label>

        <div className="bg-white rounded-xl border border-gray-200 p-6">
          <h3 className="font-medium text-gray-900 mb-3">Supported invoice types</h3>
          <div className="grid grid-cols-2 sm:grid-cols-4 gap-4 text-sm">
            <div className="flex items-center gap-2 text-gray-600"><FileText className="w-4 h-4 text-navy" /> Staff Uniforms</div>
            <div className="flex items-center gap-2 text-gray-600"><FileText className="w-4 h-4 text-navy" /> Guest Laundry</div>
            <div className="flex items-center gap-2 text-gray-600"><FileText className="w-4 h-4 text-navy" /> Napkins & Table Cloths</div>
            <div className="flex items-center gap-2 text-gray-600"><FileText className="w-4 h-4 text-navy" /> Bathrobes</div>
          </div>
        </div>
      </div>
    )
  }

  // Parsing state
  if (parsing) {
    return (
      <div className="flex flex-col items-center justify-center py-32">
        <RefreshCw className="w-8 h-8 text-gold animate-spin mb-4" />
        <p className="text-lg font-medium text-gray-700">Parsing invoice...</p>
        <p className="text-sm text-gray-500 mt-1">{file?.name}</p>
      </div>
    )
  }

  // Results state
  if (!invoice || !result) return null

  const totalTopUp = result.topUpCharges.reduce((s, l) => s + l.net, 0)
  const grandInvoiceNet = result.invoiceTotal + totalTopUp

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-2xl font-semibold text-gray-900">Invoice Reconciliation</h1>
          <p className="text-sm text-gray-500 mt-1">{file?.name}</p>
        </div>
        <div className="flex items-center gap-2">
          <button onClick={exportReconciliation} className="flex items-center gap-2 px-3 py-2 text-sm text-white bg-gold rounded-lg hover:bg-gold/90">
            <Download className="w-4 h-4" /> Export
          </button>
          <button onClick={reset} className="flex items-center gap-2 px-3 py-2 text-sm text-gray-600 bg-gray-100 rounded-lg hover:bg-gray-200">
            <X className="w-4 h-4" /> New Upload
          </button>
        </div>
      </div>

      {/* Invoice info */}
      <div className="bg-white rounded-xl border border-gray-200 p-4 flex flex-wrap gap-6 text-sm">
        <div><span className="text-gray-500">Invoice:</span> <span className="font-medium text-navy">{invoice.invoiceNumber}</span></div>
        <div><span className="text-gray-500">Date:</span> <span className="font-medium">{invoice.invoiceDate}</span></div>
        <div><span className="text-gray-500">Period:</span> <span className="font-medium">{invoice.invoicePeriod}</span></div>
        <div><span className="text-gray-500">Sections:</span> <span className="font-medium">{invoice.sections.map(s => s.name).join(', ')}</span></div>
        <div><span className="text-gray-500">Lines parsed:</span> <span className="font-medium">{invoice.sections.reduce((s, sec) => s + sec.lines.length, 0)}</span></div>
        <div><span className="text-gray-500">System orders:</span> <span className="font-medium">{orders.length}</span></div>
      </div>

      {/* Stats cards */}
      <div className="grid grid-cols-2 sm:grid-cols-5 gap-4">
        <StatCard icon={<CheckCircle className="w-5 h-5 text-green-500" />} label="Matched" value={result.stats.matched} color="green" />
        <StatCard icon={<AlertTriangle className="w-5 h-5 text-amber-500" />} label="Price Mismatch" value={result.stats.priceMismatch} color="amber" />
        <StatCard icon={<XCircle className="w-5 h-5 text-red-500" />} label="Not in System" value={result.stats.notFound} color="red" />
        <StatCard icon={<HelpCircle className="w-5 h-5 text-blue-500" />} label="Missing from Invoice" value={result.stats.missing} color="blue" />
        <div className="bg-white rounded-xl border border-gray-200 p-4">
          <p className="text-xs text-gray-500 mb-1">Difference</p>
          <p className={`text-xl font-bold ${Math.abs(result.invoiceTotal - result.systemTotal) < 0.02 ? 'text-green-600' : 'text-amber-600'}`}>
            {'\u00a3'}{Math.abs(result.invoiceTotal - result.systemTotal).toFixed(2)}
          </p>
        </div>
      </div>

      {/* Filter tabs */}
      <div className="flex gap-1.5 bg-gray-100 rounded-lg p-1 w-fit">
        {([
          ['all', 'All', result.rows.length],
          ['matched', 'Matched', result.stats.matched],
          ['mismatch', 'Mismatches', result.stats.priceMismatch],
          ['not_found', 'Not Found', result.stats.notFound],
          ['missing', 'Missing', result.stats.missing],
        ] as [FilterTab, string, number][]).map(([key, label, count]) => (
          <button
            key={key}
            onClick={() => setFilter(key)}
            className={`px-3 py-1.5 text-xs font-medium rounded-md transition-colors ${
              filter === key ? 'bg-white text-navy shadow-sm' : 'text-gray-600 hover:text-gray-900'
            }`}
          >
            {label} ({count})
          </button>
        ))}
      </div>

      {/* Reconciliation table */}
      {filter !== 'missing' ? (
        <div className="bg-white rounded-xl border border-gray-200 overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-gray-200 bg-gray-50">
                  <th className="w-10 px-3 py-3" />
                  <th className="px-3 py-3 text-left font-medium text-gray-600">Date</th>
                  <th className="px-3 py-3 text-left font-medium text-gray-600">Docket</th>
                  <th className="px-3 py-3 text-left font-medium text-gray-600">Invoice Description</th>
                  <th className="px-3 py-3 text-right font-medium text-gray-600">Invoice NET</th>
                  <th className="px-3 py-3 text-right font-medium text-gray-600">Invoice GROSS</th>
                  <th className="px-3 py-3 text-right font-medium text-gray-600">System Total</th>
                  <th className="px-3 py-3 text-right font-medium text-gray-600">Diff</th>
                </tr>
              </thead>
              <tbody>
                {filteredRows.length === 0 ? (
                  <tr><td colSpan={8} className="px-4 py-12 text-center text-gray-500">No items in this category</td></tr>
                ) : (
                  filteredRows.map((row, i) => (
                    <tr key={i} className={`border-b border-gray-100 ${
                      row.status === 'price_mismatch' ? 'bg-amber-50/50' :
                      row.status === 'not_found' ? 'bg-red-50/50' : ''
                    }`}>
                      <td className="px-3 py-2.5 text-center">{statusIcon(row.status)}</td>
                      <td className="px-3 py-2.5 text-gray-500 whitespace-nowrap">{row.invoiceLine.date}</td>
                      <td className="px-3 py-2.5 font-mono font-medium text-navy">
                        {row.invoiceLine.ticket}
                        {row.invoiceLine.guestInfo && <span className="text-gray-400 ml-1">{row.invoiceLine.guestInfo}</span>}
                      </td>
                      <td className="px-3 py-2.5 text-gray-700 max-w-[300px] truncate" title={row.invoiceLine.description}>
                        {row.invoiceLine.description}
                      </td>
                      <td className="px-3 py-2.5 text-right font-medium">{'\u00a3'}{row.invoiceLine.net.toFixed(2)}</td>
                      <td className="px-3 py-2.5 text-right text-gray-500">{'\u00a3'}{row.invoiceLine.gross.toFixed(2)}</td>
                      <td className="px-3 py-2.5 text-right font-medium">
                        {row.order ? `\u00a3${row.systemTotal.toFixed(2)}` : '\u2014'}
                      </td>
                      <td className={`px-3 py-2.5 text-right font-medium ${
                        row.status === 'matched' ? 'text-green-600' :
                        row.status === 'price_mismatch' ? 'text-amber-600' : 'text-gray-400'
                      }`}>
                        {row.order ? (row.difference >= 0 ? '+' : '') + `\u00a3${row.difference.toFixed(2)}` : '\u2014'}
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
              {filteredRows.length > 0 && (
                <tfoot>
                  <tr className="bg-gray-50 font-medium">
                    <td colSpan={4} className="px-3 py-3 text-right text-gray-700">Totals</td>
                    <td className="px-3 py-3 text-right">{'\u00a3'}{filteredRows.reduce((s, r) => s + r.invoiceLine.net, 0).toFixed(2)}</td>
                    <td className="px-3 py-3 text-right text-gray-500">{'\u00a3'}{filteredRows.reduce((s, r) => s + r.invoiceLine.gross, 0).toFixed(2)}</td>
                    <td className="px-3 py-3 text-right">{'\u00a3'}{filteredRows.reduce((s, r) => s + r.systemTotal, 0).toFixed(2)}</td>
                    <td className="px-3 py-3 text-right">
                      {'\u00a3'}{filteredRows.reduce((s, r) => s + r.difference, 0).toFixed(2)}
                    </td>
                  </tr>
                </tfoot>
              )}
            </table>
          </div>
        </div>
      ) : (
        /* Missing from Invoice table */
        <div className="bg-white rounded-xl border border-gray-200 overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-gray-200 bg-gray-50">
                  <th className="px-3 py-3 text-left font-medium text-gray-600">Docket</th>
                  <th className="px-3 py-3 text-left font-medium text-gray-600">Type</th>
                  <th className="px-3 py-3 text-left font-medium text-gray-600">Name</th>
                  <th className="px-3 py-3 text-left font-medium text-gray-600">Items</th>
                  <th className="px-3 py-3 text-right font-medium text-gray-600">System Total</th>
                  <th className="px-3 py-3 text-left font-medium text-gray-600">Date</th>
                </tr>
              </thead>
              <tbody>
                {result.missingFromInvoice.length === 0 ? (
                  <tr><td colSpan={6} className="px-4 py-12 text-center text-gray-500">All system orders found on invoice</td></tr>
                ) : (
                  result.missingFromInvoice.map((o) => (
                    <tr key={o.id} className="border-b border-gray-100 bg-blue-50/30">
                      <td className="px-3 py-2.5 font-mono font-medium text-navy">{o.docket_number}</td>
                      <td className="px-3 py-2.5 text-gray-600">{ORDER_TYPE_LABELS[o.order_type] ?? o.order_type}</td>
                      <td className="px-3 py-2.5 text-gray-900">{o.staff_name || o.guest_name || '\u2014'}</td>
                      <td className="px-3 py-2.5 text-gray-600 max-w-[300px] truncate">
                        {(o.order_items || []).map(i => `${i.quantity_sent}x ${i.item_name}`).join(', ') || '\u2014'}
                      </td>
                      <td className="px-3 py-2.5 text-right font-medium">{'\u00a3'}{computeOrderCost(o).toFixed(2)}</td>
                      <td className="px-3 py-2.5 text-gray-500 whitespace-nowrap">{format(new Date(o.created_at), 'dd/MM/yyyy')}</td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* Additional charges (TopUp) */}
      {result.topUpCharges.length > 0 && (
        <div>
          <h3 className="text-sm font-medium text-gray-700 mb-2">Additional Charges (Minimum TopUp)</h3>
          <div className="bg-white rounded-xl border border-gray-200 overflow-hidden">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-gray-200 bg-gray-50">
                  <th className="px-4 py-3 text-left font-medium text-gray-600">Date Range</th>
                  <th className="px-4 py-3 text-left font-medium text-gray-600">Description</th>
                  <th className="px-4 py-3 text-right font-medium text-gray-600">NET</th>
                  <th className="px-4 py-3 text-right font-medium text-gray-600">VAT</th>
                  <th className="px-4 py-3 text-right font-medium text-gray-600">GROSS</th>
                </tr>
              </thead>
              <tbody>
                {result.topUpCharges.map((l, i) => (
                  <tr key={i} className="border-b border-gray-100 bg-amber-50/30">
                    <td className="px-4 py-2.5 text-gray-500">{l.date}</td>
                    <td className="px-4 py-2.5 text-gray-700">{l.description}</td>
                    <td className="px-4 py-2.5 text-right font-medium">{'\u00a3'}{l.net.toFixed(2)}</td>
                    <td className="px-4 py-2.5 text-right text-gray-500">{'\u00a3'}{l.vat.toFixed(2)}</td>
                    <td className="px-4 py-2.5 text-right font-medium">{'\u00a3'}{l.gross.toFixed(2)}</td>
                  </tr>
                ))}
              </tbody>
              <tfoot>
                <tr className="bg-gray-50 font-medium">
                  <td colSpan={2} className="px-4 py-3 text-right text-gray-700">TopUp Total</td>
                  <td className="px-4 py-3 text-right">{'\u00a3'}{totalTopUp.toFixed(2)}</td>
                  <td className="px-4 py-3 text-right text-gray-500">{'\u00a3'}{(totalTopUp * 0.2).toFixed(2)}</td>
                  <td className="px-4 py-3 text-right">{'\u00a3'}{(totalTopUp * 1.2).toFixed(2)}</td>
                </tr>
              </tfoot>
            </table>
          </div>
        </div>
      )}

      {/* Grand totals */}
      <div className="bg-white rounded-xl border border-gray-200 p-6">
        <div className="grid grid-cols-2 sm:grid-cols-4 gap-6">
          <div>
            <p className="text-xs text-gray-500 mb-1">Invoice Total (NET)</p>
            <p className="text-lg font-bold text-gray-900">{'\u00a3'}{invoice.totals.net > 0 ? invoice.totals.net.toFixed(2) : grandInvoiceNet.toFixed(2)}</p>
          </div>
          <div>
            <p className="text-xs text-gray-500 mb-1">Invoice Total (GROSS)</p>
            <p className="text-lg font-bold text-gray-900">{'\u00a3'}{invoice.totals.gross > 0 ? invoice.totals.gross.toFixed(2) : (grandInvoiceNet * 1.2).toFixed(2)}</p>
          </div>
          <div>
            <p className="text-xs text-gray-500 mb-1">System Total (NET)</p>
            <p className="text-lg font-bold text-gray-900">{'\u00a3'}{result.systemTotal.toFixed(2)}</p>
          </div>
          <div>
            <p className="text-xs text-gray-500 mb-1">Order Difference</p>
            <p className={`text-lg font-bold ${Math.abs(result.invoiceTotal - result.systemTotal) < 0.02 ? 'text-green-600' : 'text-amber-600'}`}>
              {'\u00a3'}{(result.invoiceTotal - result.systemTotal).toFixed(2)}
            </p>
            {totalTopUp > 0 && (
              <p className="text-xs text-gray-500 mt-0.5">+ {'\u00a3'}{totalTopUp.toFixed(2)} TopUp charges</p>
            )}
          </div>
        </div>
      </div>
    </div>
  )
}

function StatCard({ icon, label, value, color }: { icon: React.ReactNode; label: string; value: number; color: string }) {
  return (
    <div className="bg-white rounded-xl border border-gray-200 p-4">
      <div className="flex items-center gap-2 mb-1">
        {icon}
        <span className="text-xs text-gray-500">{label}</span>
      </div>
      <p className={`text-2xl font-bold text-${color}-600`}>{value}</p>
    </div>
  )
}
