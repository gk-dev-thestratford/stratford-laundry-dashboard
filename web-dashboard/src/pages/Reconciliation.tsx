import { useState, useMemo, useCallback, useEffect } from 'react'
import { Upload, RefreshCw, Download, CheckCircle, AlertTriangle, XCircle, HelpCircle, FileText, X, Save, Clock, ChevronRight } from 'lucide-react'
import { supabase } from '../lib/supabase'
import {
  extractPdfLines, extractPdfLinesRaw, parseInvoice, parseInvoicePeriod, derivePeriodFromLines,
  sectionTypeToOrderType,
  type ParsedInvoice, type InvoiceLine, type InvoiceSectionType,
} from '../lib/invoiceParser'
import { generateReconciliationPdf, type DepartmentDisplayRow } from '../lib/pdfReport'
import type { Order, OrderType } from '../types'
import { ORDER_TYPE_LABELS } from '../types'
import { utils, writeFile } from 'xlsx'
import { format } from 'date-fns'

// ── Types ──

interface ReconciliationRow {
  invoiceLine: InvoiceLine
  sectionType: string
  order: Order | null
  status: 'matched' | 'price_mismatch' | 'not_found'
  systemTotal: number
  difference: number
}

interface DepartmentBreakdown {
  departmentName: string
  departmentId: string | null
  orderCount: number
  invoiceNet: number
  invoiceGross: number
  systemTotal: number
  difference: number
  allocatedTopUp: number
  totalCostNet: number
  totalCostGross: number
}

interface ReconciliationResult {
  rows: ReconciliationRow[]
  topUpCharges: InvoiceLine[]
  missingFromInvoice: Order[]
  stats: { matched: number; priceMismatch: number; notFound: number; missing: number }
  invoiceTotal: number
  systemTotal: number
  departmentBreakdown: DepartmentBreakdown[]
}

interface SavedReconciliation {
  id: string
  invoice_number: string
  invoice_date: string
  invoice_period: string
  created_at: string
  created_by: string
  invoice_net: number
  invoice_gross: number
  system_total: number
  topup_total: number
  matched_count: number
  mismatch_count: number
  not_found_count: number
  missing_count: number
  department_breakdown: DepartmentBreakdown[]
}

// ── Helpers ──

function computeOrderCost(o: Order): number {
  if (o.order_items && o.order_items.length > 0) {
    const t = o.order_items.reduce((s, i) => s + (i.price_at_time ?? 0) * (i.quantity_sent ?? 0), 0)
    if (t > 0) return t
  }
  return o.total_price ?? 0
}

/**
 * Allocate TopUp charges to the department with the highest order volume
 * for that section type. E.g. napkins TopUp -> Kitchen E20, staff TopUp -> Main Kitchen
 */
function buildDepartmentBreakdown(rows: ReconciliationRow[], topUpCharges: InvoiceLine[]): DepartmentBreakdown[] {
  const deptMap = new Map<string, DepartmentBreakdown>()

  for (const row of rows) {
    const deptName = row.order?.department?.name || 'Unallocated'
    const deptId = row.order?.department_id || null
    if (!deptMap.has(deptName)) {
      deptMap.set(deptName, {
        departmentName: deptName, departmentId: deptId,
        orderCount: 0, invoiceNet: 0, invoiceGross: 0,
        systemTotal: 0, difference: 0, allocatedTopUp: 0,
        totalCostNet: 0, totalCostGross: 0,
      })
    }
    const dept = deptMap.get(deptName)!
    dept.orderCount++
    dept.invoiceNet += row.invoiceLine.net
    dept.invoiceGross += row.invoiceLine.gross
    dept.systemTotal += row.systemTotal
    dept.difference += row.difference
  }

  // Allocate TopUp by section type -> department with most orders in that section
  if (topUpCharges.length > 0) {
    const sectionDeptCounts = new Map<string, Map<string, number>>()
    for (const row of rows) {
      if (!row.order?.department?.name) continue
      const secType = row.invoiceLine.sectionType || row.sectionType
      if (!sectionDeptCounts.has(secType)) sectionDeptCounts.set(secType, new Map())
      const counts = sectionDeptCounts.get(secType)!
      counts.set(row.order.department.name, (counts.get(row.order.department.name) || 0) + 1)
    }

    for (const topUp of topUpCharges) {
      const secType = topUp.sectionType || 'staff'
      const orderType = sectionTypeToOrderType(secType as InvoiceSectionType)
      const deptCounts = sectionDeptCounts.get(secType) || sectionDeptCounts.get(orderType)

      let targetDept = 'Unallocated'
      if (deptCounts && deptCounts.size > 0) {
        let max = 0
        for (const [name, count] of deptCounts) {
          if (count > max) { max = count; targetDept = name }
        }
      }

      if (!deptMap.has(targetDept)) {
        deptMap.set(targetDept, {
          departmentName: targetDept, departmentId: null,
          orderCount: 0, invoiceNet: 0, invoiceGross: 0,
          systemTotal: 0, difference: 0, allocatedTopUp: 0,
          totalCostNet: 0, totalCostGross: 0,
        })
      }
      deptMap.get(targetDept)!.allocatedTopUp += topUp.net
    }
  }

  for (const dept of deptMap.values()) {
    dept.allocatedTopUp = +dept.allocatedTopUp.toFixed(2)
    dept.totalCostNet = +(dept.invoiceNet + dept.allocatedTopUp).toFixed(2)
    dept.totalCostGross = +(dept.totalCostNet * 1.2).toFixed(2)
  }

  return Array.from(deptMap.values()).sort((a, b) => b.totalCostNet - a.totalCostNet)
}

/** Derive a human label for the regular items in a department based on the predominant order/section type */
function departmentItemsLabel(rows: ReconciliationRow[], deptName: string): string {
  const typeCounts = new Map<string, number>()
  for (const row of rows) {
    const dept = row.order?.department?.name || 'Unallocated'
    if (dept !== deptName) continue
    const t = row.sectionType || 'uniform'
    typeCounts.set(t, (typeCounts.get(t) || 0) + 1)
  }
  if (typeCounts.size === 0) return 'Items'
  // Pick the most common type
  let best = 'uniform'
  let max = 0
  for (const [t, c] of typeCounts) { if (c > max) { max = c; best = t } }
  const label = ORDER_TYPE_LABELS[best as OrderType]
  if (label) return label
  switch (best) {
    case 'uniform': return 'Uniforms'
    case 'fnb_linen': return 'F&B Linen'
    case 'hsk_linen': return 'HSK Linen'
    case 'guest_laundry': return 'Guest Laundry'
    default: return 'Items'
  }
}

/** Build display rows from department breakdown + topUp, splitting items and TopUp per dept */
function buildDepartmentDisplayRows(
  breakdown: DepartmentBreakdown[],
  allRows: ReconciliationRow[]
): DepartmentDisplayRow[] {
  const displayRows: DepartmentDisplayRow[] = []
  for (const dept of breakdown) {
    // Regular items row
    const label = departmentItemsLabel(allRows, dept.departmentName)
    displayRows.push({
      departmentName: dept.departmentName,
      lineLabel: label,
      isTopUp: false,
      orderCount: dept.orderCount,
      invoiceNet: dept.invoiceNet,
      systemTotal: dept.systemTotal,
      difference: dept.difference,
      totalGross: +(dept.invoiceNet * 1.2).toFixed(2),
    })
    // TopUp sub-row if allocated
    if (dept.allocatedTopUp > 0) {
      displayRows.push({
        departmentName: dept.departmentName,
        lineLabel: 'Minimum TopUp',
        isTopUp: true,
        orderCount: 0,
        invoiceNet: dept.allocatedTopUp,
        systemTotal: 0,
        difference: 0,
        totalGross: +(dept.allocatedTopUp * 1.2).toFixed(2),
      })
    }
  }
  return displayRows
}

function reconcile(invoice: ParsedInvoice, orders: Order[], period: { start: Date; end: Date } | null): ReconciliationResult {
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
      let order = byDocket.get(line.ticket) ?? null
      if (!order && section.type === 'guest' && line.ticket) {
        const candidates = byRoom.get(line.ticket) ?? []
        if (candidates.length === 1) order = candidates[0]
        else if (candidates.length > 1 && line.guestInfo) {
          const name = line.guestInfo.replace(/[()]/g, '').toLowerCase()
          order = candidates.find(o => o.guest_name?.toLowerCase().includes(name)) ?? candidates[0]
        }
      }
      if (order) matchedOrderIds.add(order.id)
      const systemTotal = order ? computeOrderCost(order) : 0
      const diff = order ? +(line.net - systemTotal).toFixed(2) : line.net
      const status: ReconciliationRow['status'] = !order
        ? 'not_found' : Math.abs(diff) < 0.02 ? 'matched' : 'price_mismatch'
      rows.push({ invoiceLine: line, sectionType: orderType, order, status, systemTotal, difference: diff })
    }
  }

  const invoiceOrderTypes = new Set(invoice.sections.map(s => sectionTypeToOrderType(s.type)))
  const missingFromInvoice = orders.filter(o => {
    if (matchedOrderIds.has(o.id)) return false
    if (!invoiceOrderTypes.has(o.order_type)) return false
    // Only flag orders within the invoice period
    if (period) {
      const orderDate = new Date(o.created_at)
      if (orderDate < period.start || orderDate > period.end) return false
    }
    return true
  })

  return {
    rows, topUpCharges, missingFromInvoice,
    stats: {
      matched: rows.filter(r => r.status === 'matched').length,
      priceMismatch: rows.filter(r => r.status === 'price_mismatch').length,
      notFound: rows.filter(r => r.status === 'not_found').length,
      missing: missingFromInvoice.length,
    },
    invoiceTotal: rows.reduce((s, r) => s + r.invoiceLine.net, 0),
    systemTotal: rows.reduce((s, r) => s + r.systemTotal, 0),
    departmentBreakdown: buildDepartmentBreakdown(rows, topUpCharges),
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
  const [saving, setSaving] = useState(false)
  const [saved, setSaved] = useState(false)
  const [showHistory, setShowHistory] = useState(false)
  const [history, setHistory] = useState<SavedReconciliation[]>([])
  const [loadingHistory, setLoadingHistory] = useState(false)
  const [updatingPrices, setUpdatingPrices] = useState<Set<string>>(new Set())
  const [missingResolutions, setMissingResolutions] = useState<Record<string, string>>({})

  const loadHistory = useCallback(async () => {
    setLoadingHistory(true)
    const { data } = await supabase
      .from('reconciliations').select('*')
      .order('created_at', { ascending: false }).limit(50)
    setHistory((data as SavedReconciliation[] | null) ?? [])
    setLoadingHistory(false)
  }, [])

  useEffect(() => { loadHistory() }, [loadHistory])

  async function handleFile(f: File) {
    if (!f.type.includes('pdf')) { setError('Please upload a PDF file'); return }
    setFile(f); setError(''); setParsing(true)
    setInvoice(null); setResult(null); setSaved(false); setShowHistory(false)
    try {
      const lines = await extractPdfLines(f)
      const parsed = parseInvoice(lines)
      if (parsed.sections.every(s => s.lines.length === 0)) {
        setError('Could not parse any invoice lines.'); setParsing(false); return
      }
      setInvoice(parsed)
      // Try parsing the period text, fall back to deriving from invoice line dates
      const period = parseInvoicePeriod(parsed.invoicePeriod) || derivePeriodFromLines(parsed)
      let fetchedOrders: Order[] = []
      if (period) {
        const { data } = await supabase.from('orders').select('*, department:departments(*), order_items(*)')
          .gte('created_at', period.start.toISOString()).lte('created_at', period.end.toISOString())
          .order('created_at', { ascending: true })
        fetchedOrders = data ?? []
      } else {
        const { data } = await supabase.from('orders').select('*, department:departments(*), order_items(*)')
          .order('created_at', { ascending: false }).limit(500)
        fetchedOrders = data ?? []
      }
      setOrders(fetchedOrders)
      setResult(reconcile(parsed, fetchedOrders, period))
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to parse PDF')
    } finally { setParsing(false) }
  }

  function reset() {
    setFile(null); setInvoice(null); setOrders([]); setResult(null)
    setError(''); setFilter('all'); setSaved(false)
    setUpdatingPrices(new Set()); setMissingResolutions({})
  }

  const saveReconciliation = useCallback(async () => {
    if (!result || !invoice) return
    setSaving(true)
    const totalTopUp = result.topUpCharges.reduce((s, l) => s + l.net, 0)
    const { data: { user } } = await supabase.auth.getUser()
    await supabase.from('reconciliations').insert({
      invoice_number: invoice.invoiceNumber, invoice_date: invoice.invoiceDate,
      invoice_period: invoice.invoicePeriod, created_by: user?.email || 'unknown',
      invoice_net: +result.invoiceTotal.toFixed(2), invoice_gross: +(result.invoiceTotal * 1.2).toFixed(2),
      system_total: +result.systemTotal.toFixed(2), topup_total: +totalTopUp.toFixed(2),
      matched_count: result.stats.matched, mismatch_count: result.stats.priceMismatch,
      not_found_count: result.stats.notFound, missing_count: result.stats.missing,
      department_breakdown: result.departmentBreakdown.map(d => ({
        departmentName: d.departmentName, orderCount: d.orderCount,
        invoiceNet: +d.invoiceNet.toFixed(2), systemTotal: +d.systemTotal.toFixed(2),
        allocatedTopUp: d.allocatedTopUp, totalCostNet: d.totalCostNet, totalCostGross: d.totalCostGross,
      })),
    })
    setSaving(false); setSaved(true); loadHistory()
  }, [result, invoice, loadHistory])

  const filteredRows = useMemo(() => {
    if (!result) return []
    if (filter === 'all') return result.rows
    if (filter === 'matched') return result.rows.filter(r => r.status === 'matched')
    if (filter === 'mismatch') return result.rows.filter(r => r.status === 'price_mismatch')
    if (filter === 'not_found') return result.rows.filter(r => r.status === 'not_found')
    return []
  }, [result, filter])

  const departmentDisplayRows = useMemo<DepartmentDisplayRow[]>(() => {
    if (!result) return []
    return buildDepartmentDisplayRows(result.departmentBreakdown, result.rows)
  }, [result])

  // ── Accounting Report Export ──
  const exportAccountingReport = useCallback(() => {
    if (!result || !invoice) return
    const wb = utils.book_new()
    const totalTopUp = result.topUpCharges.reduce((s, l) => s + l.net, 0)
    const grandNet = result.invoiceTotal + totalTopUp

    // Sheet 1: Summary
    const summarySheet = utils.aoa_to_sheet([
      ['The Stratford \u2014 Laundry Reconciliation Report'],
      [],
      ['Invoice Number', invoice.invoiceNumber],
      ['Invoice Date', invoice.invoiceDate],
      ['Invoice Period', invoice.invoicePeriod],
      ['Invoice Type', invoice.sections.map(s => s.name).join(', ')],
      ['Report Generated', format(new Date(), 'dd/MM/yyyy HH:mm')],
      [],
      ['FINANCIAL SUMMARY'],
      ['', 'NET (\u00a3)', 'VAT (\u00a3)', 'GROSS (\u00a3)'],
      ['Invoice Line Items', +result.invoiceTotal.toFixed(2), +(result.invoiceTotal * 0.2).toFixed(2), +(result.invoiceTotal * 1.2).toFixed(2)],
      ['Minimum TopUp Charges', +totalTopUp.toFixed(2), +(totalTopUp * 0.2).toFixed(2), +(totalTopUp * 1.2).toFixed(2)],
      ['Grand Total (Invoice)', +grandNet.toFixed(2), +(grandNet * 0.2).toFixed(2), +(grandNet * 1.2).toFixed(2)],
      ['System Total', +result.systemTotal.toFixed(2), +(result.systemTotal * 0.2).toFixed(2), +(result.systemTotal * 1.2).toFixed(2)],
      [],
      ['RECONCILIATION SUMMARY'],
      ['Matched Orders', result.stats.matched],
      ['Price Mismatches', result.stats.priceMismatch],
      ['Not Found in System', result.stats.notFound],
      ['Missing from Invoice', result.stats.missing],
    ])
    summarySheet['!cols'] = [{ wch: 25 }, { wch: 15 }, { wch: 12 }, { wch: 15 }]
    utils.book_append_sheet(wb, summarySheet, 'Summary')

    // Sheet 2: Department Breakdown (split items + TopUp rows)
    const deptDisplayRows = buildDepartmentDisplayRows(result.departmentBreakdown, result.rows)
    const deptExcelRows: Record<string, string | number>[] = deptDisplayRows.map(row => ({
      'Department': row.departmentName,
      'Line': row.lineLabel,
      'Orders': row.isTopUp ? '' as any : row.orderCount,
      'Invoice NET (\u00a3)': +row.invoiceNet.toFixed(2),
      'System NET (\u00a3)': row.isTopUp ? '' as any : +row.systemTotal.toFixed(2),
      'Difference (\u00a3)': row.isTopUp ? '' as any : +row.difference.toFixed(2),
      'Total inc VAT (\u00a3)': +row.totalGross.toFixed(2),
    }))
    const totalDisplayOrders = deptDisplayRows.filter(r => !r.isTopUp).reduce((s, r) => s + r.orderCount, 0)
    const totalDisplayInvNet = deptDisplayRows.reduce((s, r) => s + r.invoiceNet, 0)
    const totalDisplaySysNet = deptDisplayRows.filter(r => !r.isTopUp).reduce((s, r) => s + r.systemTotal, 0)
    const totalDisplayDiff = deptDisplayRows.filter(r => !r.isTopUp).reduce((s, r) => s + r.difference, 0)
    const totalDisplayGross = deptDisplayRows.reduce((s, r) => s + r.totalGross, 0)
    deptExcelRows.push({
      'Department': 'TOTAL', 'Line': '',
      'Orders': totalDisplayOrders,
      'Invoice NET (\u00a3)': +totalDisplayInvNet.toFixed(2),
      'System NET (\u00a3)': +totalDisplaySysNet.toFixed(2),
      'Difference (\u00a3)': +totalDisplayDiff.toFixed(2),
      'Total inc VAT (\u00a3)': +totalDisplayGross.toFixed(2),
    })
    utils.book_append_sheet(wb, utils.json_to_sheet(deptExcelRows), 'Department Breakdown')

    // Sheet 3: Detailed Items
    utils.book_append_sheet(wb, utils.json_to_sheet(result.rows.map(r => ({
      'Status': r.status === 'matched' ? 'Matched' : r.status === 'price_mismatch' ? 'Price Mismatch' : 'Not Found',
      'Department': r.order?.department?.name || 'Unallocated',
      'Date': r.invoiceLine.date, 'Docket': r.invoiceLine.ticket,
      'Type': ORDER_TYPE_LABELS[r.sectionType as OrderType] ?? r.sectionType,
      'Invoice Description': r.invoiceLine.description,
      'Invoice NET (\u00a3)': +r.invoiceLine.net.toFixed(2), 'Invoice VAT (\u00a3)': +r.invoiceLine.vat.toFixed(2),
      'Invoice GROSS (\u00a3)': +r.invoiceLine.gross.toFixed(2),
      'System Total (\u00a3)': r.order ? +r.systemTotal.toFixed(2) : '',
      'Difference (\u00a3)': r.order ? +r.difference.toFixed(2) : '',
      'Staff/Guest': r.order?.staff_name || r.order?.guest_name || '',
    }))), 'Detailed Items')

    // Sheet 4: TopUp Charges
    if (result.topUpCharges.length > 0) {
      const topUpRows = result.topUpCharges.map(l => ({
        'Date Range': l.date, 'Description': l.description, 'Section': l.sectionType?.replace('_', ' ') || '',
        'NET (\u00a3)': +l.net.toFixed(2), 'VAT (\u00a3)': +l.vat.toFixed(2), 'GROSS (\u00a3)': +l.gross.toFixed(2),
      }))
      topUpRows.push({ 'Date Range': 'TOTAL', 'Description': '', 'Section': '',
        'NET (\u00a3)': +totalTopUp.toFixed(2), 'VAT (\u00a3)': +(totalTopUp * 0.2).toFixed(2), 'GROSS (\u00a3)': +(totalTopUp * 1.2).toFixed(2) })
      utils.book_append_sheet(wb, utils.json_to_sheet(topUpRows), 'TopUp Charges')
    }

    // Sheet 5: Discrepancies & Actions
    const discRows: Record<string, string | number>[] = []
    result.rows.filter(r => r.status === 'price_mismatch').forEach(r => discRows.push({
      'Issue': 'Price Mismatch', 'Docket': r.invoiceLine.ticket, 'Department': r.order?.department?.name || '',
      'Invoice NET (\u00a3)': +r.invoiceLine.net.toFixed(2), 'System NET (\u00a3)': +r.systemTotal.toFixed(2),
      'Difference (\u00a3)': +r.difference.toFixed(2), 'Description': r.invoiceLine.description,
      'Recommended Action': 'Verify pricing with Goldstar / update system prices',
    }))
    result.rows.filter(r => r.status === 'not_found').forEach(r => discRows.push({
      'Issue': 'Invoice entry not in system', 'Docket': r.invoiceLine.ticket, 'Department': '',
      'Invoice NET (\u00a3)': +r.invoiceLine.net.toFixed(2), 'System NET (\u00a3)': 0,
      'Difference (\u00a3)': +r.invoiceLine.net.toFixed(2), 'Description': r.invoiceLine.description,
      'Recommended Action': 'Check if order was recorded / query with Goldstar',
    }))
    result.missingFromInvoice.forEach(o => discRows.push({
      'Issue': 'System order not on invoice', 'Docket': o.docket_number, 'Department': o.department?.name || '',
      'Invoice NET (\u00a3)': 0, 'System NET (\u00a3)': +computeOrderCost(o).toFixed(2),
      'Difference (\u00a3)': +(-computeOrderCost(o)).toFixed(2),
      'Description': (o.order_items || []).map(i => `${i.quantity_sent}x ${i.item_name}`).join(', '),
      'Recommended Action': 'Confirm with Goldstar if processed / check different invoice period',
    }))
    if (discRows.length > 0) utils.book_append_sheet(wb, utils.json_to_sheet(discRows), 'Discrepancies & Actions')

    writeFile(wb, `accounting-report-${invoice.invoiceNumber || 'reconciliation'}-${format(new Date(), 'yyyy-MM-dd')}.xlsx`)
  }, [result, invoice])

  const statusIcon = (s: ReconciliationRow['status']) => {
    if (s === 'matched') return <CheckCircle className="w-4 h-4 text-green-500" />
    if (s === 'price_mismatch') return <AlertTriangle className="w-4 h-4 text-amber-500" />
    return <XCircle className="w-4 h-4 text-red-500" />
  }

  // ── Action: update prices to match invoice ──
  const handleUpdatePrice = useCallback(async (row: ReconciliationRow) => {
    if (!row.order || !invoice) return
    const orderId = row.order.id
    setUpdatingPrices(prev => new Set(prev).add(orderId))
    try {
      const items = row.order.order_items || []
      const currentTotal = computeOrderCost(row.order)
      const invoiceNet = row.invoiceLine.net

      if (items.length > 0 && currentTotal > 0) {
        // Scale each item price proportionally so total matches invoice NET
        const ratio = invoiceNet / currentTotal
        for (const item of items) {
          const oldPrice = item.price_at_time ?? 0
          const newPrice = +(oldPrice * ratio).toFixed(4)
          await supabase.from('order_items').update({ price_at_time: newPrice }).eq('id', item.id)
        }
      }
      // Update order total_price to invoice NET
      await supabase.from('orders').update({ total_price: +invoiceNet.toFixed(2) }).eq('id', orderId)

      // Re-fetch orders and re-run reconciliation
      const period = parseInvoicePeriod(invoice.invoicePeriod) || derivePeriodFromLines(invoice)
      let fetchedOrders: Order[] = []
      if (period) {
        const { data } = await supabase.from('orders').select('*, department:departments(*), order_items(*)')
          .gte('created_at', period.start.toISOString()).lte('created_at', period.end.toISOString())
          .order('created_at', { ascending: true })
        fetchedOrders = data ?? []
      } else {
        const { data } = await supabase.from('orders').select('*, department:departments(*), order_items(*)')
          .order('created_at', { ascending: false }).limit(500)
        fetchedOrders = data ?? []
      }
      setOrders(fetchedOrders)
      setResult(reconcile(invoice, fetchedOrders, period))
    } catch (e) {
      console.error('Failed to update prices:', e)
    } finally {
      setUpdatingPrices(prev => { const next = new Set(prev); next.delete(orderId); return next })
    }
  }, [invoice])

  // ── Action: delete a missing order ──
  const handleDeleteOrder = useCallback(async (orderId: string) => {
    if (!window.confirm('Are you sure you want to delete this order? This cannot be undone.')) return
    if (!invoice) return
    try {
      await supabase.from('order_items').delete().eq('order_id', orderId)
      await supabase.from('orders').delete().eq('id', orderId)
      // Re-fetch and re-run
      const period = parseInvoicePeriod(invoice.invoicePeriod) || derivePeriodFromLines(invoice)
      let fetchedOrders: Order[] = []
      if (period) {
        const { data } = await supabase.from('orders').select('*, department:departments(*), order_items(*)')
          .gte('created_at', period.start.toISOString()).lte('created_at', period.end.toISOString())
          .order('created_at', { ascending: true })
        fetchedOrders = data ?? []
      } else {
        const { data } = await supabase.from('orders').select('*, department:departments(*), order_items(*)')
          .order('created_at', { ascending: false }).limit(500)
        fetchedOrders = data ?? []
      }
      setOrders(fetchedOrders)
      setResult(reconcile(invoice, fetchedOrders, period))
    } catch (e) {
      console.error('Failed to delete order:', e)
    }
  }, [invoice])

  // ── PDF Report ──
  const handlePdfReport = useCallback(() => {
    if (!result || !invoice) return
    generateReconciliationPdf(invoice, result, departmentDisplayRows)
  }, [result, invoice, departmentDisplayRows])

  // ── History view ──
  if (showHistory) return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-semibold text-gray-900">Reconciliation History</h1>
          <p className="text-sm text-gray-500 mt-1">Past reconciliations and audit trail</p>
        </div>
        <button onClick={() => setShowHistory(false)} className="flex items-center gap-2 px-3 py-2 text-sm text-gray-600 bg-gray-100 rounded-lg hover:bg-gray-200">
          <Upload className="w-4 h-4" /> New Reconciliation
        </button>
      </div>
      {loadingHistory ? (
        <div className="flex justify-center py-20"><RefreshCw className="w-6 h-6 text-gray-400 animate-spin" /></div>
      ) : history.length === 0 ? (
        <div className="bg-white rounded-xl border border-gray-200 p-12 text-center">
          <Clock className="w-12 h-12 text-gray-300 mx-auto mb-3" />
          <p className="text-gray-500">No reconciliations saved yet</p>
        </div>
      ) : (
        <div className="bg-white rounded-xl border border-gray-200 overflow-hidden">
          <table className="w-full text-sm">
            <thead><tr className="border-b border-gray-200 bg-gray-50">
              <th className="px-4 py-3 text-left font-medium text-gray-600">Invoice</th>
              <th className="px-4 py-3 text-left font-medium text-gray-600">Period</th>
              <th className="px-4 py-3 text-left font-medium text-gray-600">Reconciled</th>
              <th className="px-4 py-3 text-right font-medium text-gray-600">Invoice NET</th>
              <th className="px-4 py-3 text-right font-medium text-gray-600">TopUp</th>
              <th className="px-4 py-3 text-center font-medium text-gray-600">Matched</th>
              <th className="px-4 py-3 text-center font-medium text-gray-600">Issues</th>
              <th className="px-4 py-3 text-left font-medium text-gray-600">By</th>
            </tr></thead>
            <tbody>{history.map(h => {
              const issues = h.mismatch_count + h.not_found_count + h.missing_count
              return (
                <tr key={h.id} className="border-b border-gray-100 hover:bg-gray-50">
                  <td className="px-4 py-3 font-mono font-medium text-navy">{h.invoice_number}</td>
                  <td className="px-4 py-3 text-gray-600">{h.invoice_period}</td>
                  <td className="px-4 py-3 text-gray-500">{format(new Date(h.created_at), 'dd MMM yyyy HH:mm')}</td>
                  <td className="px-4 py-3 text-right font-medium">{'\u00a3'}{h.invoice_net.toFixed(2)}</td>
                  <td className="px-4 py-3 text-right text-amber-600">{h.topup_total > 0 ? `\u00a3${h.topup_total.toFixed(2)}` : '\u2014'}</td>
                  <td className="px-4 py-3 text-center"><span className="inline-flex px-2 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-700">{h.matched_count}</span></td>
                  <td className="px-4 py-3 text-center"><span className={`inline-flex px-2 py-0.5 rounded-full text-xs font-medium ${issues > 0 ? 'bg-amber-100 text-amber-700' : 'bg-green-100 text-green-700'}`}>{issues}</span></td>
                  <td className="px-4 py-3 text-gray-500 text-xs">{h.created_by}</td>
                </tr>
              )
            })}</tbody>
          </table>
        </div>
      )}
    </div>
  )

  // ── Upload ──
  if (!invoice && !parsing) return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-semibold text-gray-900">Invoice Reconciliation</h1>
          <p className="text-sm text-gray-500 mt-1">Upload a Goldstar invoice PDF to cross-check against your orders</p>
        </div>
        {history.length > 0 && (
          <button onClick={() => setShowHistory(true)} className="flex items-center gap-2 px-3 py-2 text-sm text-gray-600 bg-gray-100 rounded-lg hover:bg-gray-200">
            <Clock className="w-4 h-4" /> History ({history.length})
          </button>
        )}
      </div>
      {error && <div className="p-3 bg-red-50 border border-red-200 rounded-lg text-sm text-red-700">{error}</div>}
      <label
        onDragOver={e => { e.preventDefault(); setDragOver(true) }} onDragLeave={() => setDragOver(false)}
        onDrop={e => { e.preventDefault(); setDragOver(false); const f = e.dataTransfer.files[0]; if (f) handleFile(f) }}
        className={`flex flex-col items-center justify-center border-2 border-dashed rounded-xl p-16 cursor-pointer transition-colors ${dragOver ? 'border-gold bg-gold/5' : 'border-gray-300 hover:border-gold/50 hover:bg-gray-50'}`}
      >
        <Upload className={`w-12 h-12 mb-4 ${dragOver ? 'text-gold' : 'text-gray-400'}`} />
        <p className="text-lg font-medium text-gray-700">Drop invoice PDF here</p>
        <p className="text-sm text-gray-500 mt-1">or click to browse</p>
        <input type="file" accept=".pdf" className="hidden" onChange={e => { const f = e.target.files?.[0]; if (f) handleFile(f) }} />
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

  if (parsing) return (
    <div className="flex flex-col items-center justify-center py-32">
      <RefreshCw className="w-8 h-8 text-gold animate-spin mb-4" />
      <p className="text-lg font-medium text-gray-700">Parsing invoice...</p>
      <p className="text-sm text-gray-500 mt-1">{file?.name}</p>
    </div>
  )

  if (!invoice || !result) return null

  const totalTopUp = result.topUpCharges.reduce((s, l) => s + l.net, 0)
  const grandInvoiceNet = result.invoiceTotal + totalTopUp
  const statedNet = invoice.totals.net
  const parsedVsStatedGap = statedNet > 0 ? Math.abs(statedNet - grandInvoiceNet) : 0

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-2xl font-semibold text-gray-900">Invoice Reconciliation</h1>
          <p className="text-sm text-gray-500 mt-1">{file?.name}</p>
        </div>
        <div className="flex items-center gap-2 flex-wrap">
          <button onClick={exportAccountingReport} className="flex items-center gap-2 px-4 py-2 text-sm text-white bg-navy rounded-lg hover:bg-navy-light">
            <Download className="w-4 h-4" /> Accounting Report
          </button>
          <button onClick={handlePdfReport} className="flex items-center gap-2 px-4 py-2 text-sm text-white bg-navy rounded-lg hover:bg-navy-light">
            <FileText className="w-4 h-4" /> PDF Report
          </button>
          <button onClick={saveReconciliation} disabled={saving || saved}
            className={`flex items-center gap-2 px-3 py-2 text-sm rounded-lg transition-colors ${saved ? 'bg-green-100 text-green-700' : 'text-white bg-gold hover:bg-gold/90'} ${saving ? 'opacity-50' : ''}`}>
            {saved ? <CheckCircle className="w-4 h-4" /> : <Save className="w-4 h-4" />}
            {saved ? 'Saved' : saving ? 'Saving...' : 'Save'}
          </button>
          <button onClick={reset} className="flex items-center gap-2 px-3 py-2 text-sm text-gray-600 bg-gray-100 rounded-lg hover:bg-gray-200">
            <X className="w-4 h-4" /> New
          </button>
        </div>
      </div>

      {/* Invoice info */}
      <div className="bg-white rounded-xl border border-gray-200 p-4 flex flex-wrap gap-6 text-sm">
        <div><span className="text-gray-500">Invoice:</span> <span className="font-medium text-navy">{invoice.invoiceNumber}</span></div>
        <div><span className="text-gray-500">Date:</span> <span className="font-medium">{invoice.invoiceDate}</span></div>
        <div><span className="text-gray-500">Period:</span> <span className="font-medium">{invoice.invoicePeriod}</span></div>
        <div><span className="text-gray-500">Sections:</span> <span className="font-medium">{invoice.sections.map(s => s.name).join(', ')}</span></div>
        <div><span className="text-gray-500">Lines:</span> <span className="font-medium">{invoice.sections.reduce((s, sec) => s + sec.lines.length, 0)}</span></div>
        <div><span className="text-gray-500">System orders:</span> <span className="font-medium">{orders.length}</span></div>
      </div>

      {/* Parse integrity warning */}
      {parsedVsStatedGap > 1 && (
        <div className="bg-amber-50 border border-amber-300 rounded-lg p-4 flex items-start gap-3">
          <AlertTriangle className="w-5 h-5 text-amber-600 mt-0.5 flex-shrink-0" />
          <div className="text-sm flex-1">
            <p className="font-semibold text-amber-800">Parse discrepancy detected</p>
            <p className="text-amber-700 mt-1">
              Invoice states NET total of <span className="font-medium">{'\u00a3'}{statedNet.toFixed(2)}</span> but
              parsed lines total <span className="font-medium">{'\u00a3'}{grandInvoiceNet.toFixed(2)}</span> (items {'\u00a3'}{result.invoiceTotal.toFixed(2)} + TopUp {'\u00a3'}{totalTopUp.toFixed(2)}).
              Gap: <span className="font-bold">{'\u00a3'}{parsedVsStatedGap.toFixed(2)}</span> — some invoice lines may not have been captured from the PDF.
            </p>
            {file && (
              <button
                onClick={async () => {
                  const raw = await extractPdfLinesRaw(file)
                  const blob = new Blob([raw.join('\n')], { type: 'text/plain' })
                  const a = document.createElement('a')
                  a.href = URL.createObjectURL(blob)
                  a.download = `pdf-diagnostic-${file.name.replace('.pdf', '')}.txt`
                  a.click()
                }}
                className="mt-2 text-xs text-amber-800 underline hover:text-amber-900"
              >
                Download PDF diagnostic
              </button>
            )}
          </div>
        </div>
      )}

      {/* Stats */}
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

      {/* Department Breakdown — split items + TopUp rows */}
      <div className="bg-white rounded-xl border border-gray-200 overflow-hidden">
        <div className="px-5 py-3 border-b border-gray-200 flex items-center gap-2">
          <ChevronRight className="w-4 h-4 text-gray-500" />
          <h3 className="text-sm font-semibold text-gray-900">Department Breakdown</h3>
          {totalTopUp > 0 && <span className="text-xs text-gray-400 ml-2">(TopUp allocated by service type)</span>}
        </div>
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead><tr className="border-b border-gray-200 bg-gray-50">
              <th className="px-4 py-2.5 text-left font-medium text-gray-600">Department / Line</th>
              <th className="px-4 py-2.5 text-right font-medium text-gray-600">Orders</th>
              <th className="px-4 py-2.5 text-right font-medium text-gray-600">Invoice NET</th>
              <th className="px-4 py-2.5 text-right font-medium text-gray-600">System NET</th>
              <th className="px-4 py-2.5 text-right font-medium text-gray-600">Diff</th>
              <th className="px-4 py-2.5 text-right font-medium text-gray-600">Total inc VAT</th>
            </tr></thead>
            <tbody>{departmentDisplayRows.map((row, i) => (
              <tr key={i} className={`border-b border-gray-100 ${row.isTopUp ? 'bg-amber-50/20' : ''}`}>
                <td className={`px-4 py-2.5 ${row.isTopUp ? 'pl-8 italic text-gray-500 text-xs' : 'font-medium'}`}>
                  {row.departmentName} {'\u2014'} {row.lineLabel}
                </td>
                <td className="px-4 py-2.5 text-right">{row.isTopUp ? '\u2014' : row.orderCount}</td>
                <td className="px-4 py-2.5 text-right">{'\u00a3'}{row.invoiceNet.toFixed(2)}</td>
                <td className="px-4 py-2.5 text-right">{row.isTopUp ? '\u2014' : `\u00a3${row.systemTotal.toFixed(2)}`}</td>
                <td className={`px-4 py-2.5 text-right font-medium ${row.isTopUp ? 'text-gray-400' : Math.abs(row.difference) < 0.02 ? 'text-green-600' : 'text-amber-600'}`}>
                  {row.isTopUp ? '\u2014' : Math.abs(row.difference) < 0.02 ? '\u2713' : `\u00a3${row.difference.toFixed(2)}`}
                </td>
                <td className="px-4 py-2.5 text-right font-semibold">{'\u00a3'}{row.totalGross.toFixed(2)}</td>
              </tr>
            ))}</tbody>
            <tfoot><tr className="bg-gray-50 font-semibold border-t-2 border-gray-300">
              <td className="px-4 py-3">Total</td>
              <td className="px-4 py-3 text-right">{departmentDisplayRows.filter(r => !r.isTopUp).reduce((s, r) => s + r.orderCount, 0)}</td>
              <td className="px-4 py-3 text-right">{'\u00a3'}{departmentDisplayRows.reduce((s, r) => s + r.invoiceNet, 0).toFixed(2)}</td>
              <td className="px-4 py-3 text-right">{'\u00a3'}{departmentDisplayRows.filter(r => !r.isTopUp).reduce((s, r) => s + r.systemTotal, 0).toFixed(2)}</td>
              <td className={`px-4 py-3 text-right ${Math.abs(result.invoiceTotal - result.systemTotal) < 0.02 ? 'text-green-600' : 'text-amber-600'}`}>
                {'\u00a3'}{departmentDisplayRows.filter(r => !r.isTopUp).reduce((s, r) => s + r.difference, 0).toFixed(2)}
              </td>
              <td className="px-4 py-3 text-right">{'\u00a3'}{departmentDisplayRows.reduce((s, r) => s + r.totalGross, 0).toFixed(2)}</td>
            </tr></tfoot>
          </table>
        </div>
      </div>

      {/* Filter tabs */}
      <div className="flex gap-1.5 bg-gray-100 rounded-lg p-1 w-fit">
        {([['all', 'All', result.rows.length], ['matched', 'Matched', result.stats.matched],
          ['mismatch', 'Mismatches', result.stats.priceMismatch], ['not_found', 'Not Found', result.stats.notFound],
          ['missing', 'Missing', result.stats.missing]] as [FilterTab, string, number][]).map(([key, label, count]) => (
          <button key={key} onClick={() => setFilter(key)}
            className={`px-3 py-1.5 text-xs font-medium rounded-md transition-colors ${filter === key ? 'bg-white text-navy shadow-sm' : 'text-gray-600 hover:text-gray-900'}`}
          >{label} ({count})</button>
        ))}
      </div>

      {/* Detail table */}
      {filter !== 'missing' ? (
        <div className="bg-white rounded-xl border border-gray-200 overflow-hidden"><div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead><tr className="border-b border-gray-200 bg-gray-50">
              <th className="w-10 px-3 py-3" />
              <th className="px-3 py-3 text-left font-medium text-gray-600">Date</th>
              <th className="px-3 py-3 text-left font-medium text-gray-600">Docket</th>
              <th className="px-3 py-3 text-left font-medium text-gray-600">Department</th>
              <th className="px-3 py-3 text-left font-medium text-gray-600">Description</th>
              <th className="px-3 py-3 text-right font-medium text-gray-600">Invoice NET</th>
              <th className="px-3 py-3 text-right font-medium text-gray-600">System NET</th>
              <th className="px-3 py-3 text-right font-medium text-gray-600">Diff</th>
              <th className="px-3 py-3 text-center font-medium text-gray-600">Action</th>
            </tr></thead>
            <tbody>
              {filteredRows.length === 0
                ? <tr><td colSpan={9} className="px-4 py-12 text-center text-gray-500">No items in this category</td></tr>
                : filteredRows.map((row, i) => (
                <tr key={i} className={`border-b border-gray-100 ${row.status === 'price_mismatch' ? 'bg-amber-50/50' : row.status === 'not_found' ? 'bg-red-50/50' : ''}`}>
                  <td className="px-3 py-2.5 text-center">{statusIcon(row.status)}</td>
                  <td className="px-3 py-2.5 text-gray-500 whitespace-nowrap">{row.invoiceLine.date}</td>
                  <td className="px-3 py-2.5 font-mono font-medium text-navy">
                    {row.invoiceLine.ticket}{row.invoiceLine.guestInfo && <span className="text-gray-400 ml-1">{row.invoiceLine.guestInfo}</span>}
                  </td>
                  <td className="px-3 py-2.5 text-gray-600">{row.order?.department?.name || '\u2014'}</td>
                  <td className="px-3 py-2.5 text-gray-700 max-w-[250px] truncate" title={row.invoiceLine.description}>{row.invoiceLine.description}</td>
                  <td className="px-3 py-2.5 text-right font-medium">{'\u00a3'}{row.invoiceLine.net.toFixed(2)}</td>
                  <td className="px-3 py-2.5 text-right font-medium">{row.order ? `\u00a3${row.systemTotal.toFixed(2)}` : '\u2014'}</td>
                  <td className={`px-3 py-2.5 text-right font-medium ${row.status === 'matched' ? 'text-green-600' : row.status === 'price_mismatch' ? 'text-amber-600' : 'text-gray-400'}`}>
                    {row.order ? (row.difference >= 0 ? '+' : '') + `\u00a3${row.difference.toFixed(2)}` : '\u2014'}
                  </td>
                  <td className="px-3 py-2.5 text-center">
                    {row.status === 'matched' && <CheckCircle className="w-4 h-4 text-green-500 mx-auto" />}
                    {row.status === 'price_mismatch' && row.order && (
                      <button
                        onClick={() => handleUpdatePrice(row)}
                        disabled={updatingPrices.has(row.order!.id)}
                        className="px-2 py-1 text-xs font-medium text-white bg-amber-500 rounded hover:bg-amber-600 disabled:opacity-50 whitespace-nowrap"
                      >
                        {updatingPrices.has(row.order!.id) ? (
                          <RefreshCw className="w-3 h-3 animate-spin inline" />
                        ) : 'Update Price'}
                      </button>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
            {filteredRows.length > 0 && <tfoot><tr className="bg-gray-50 font-medium">
              <td colSpan={5} className="px-3 py-3 text-right text-gray-700">Totals</td>
              <td className="px-3 py-3 text-right">{'\u00a3'}{filteredRows.reduce((s, r) => s + r.invoiceLine.net, 0).toFixed(2)}</td>
              <td className="px-3 py-3 text-right">{'\u00a3'}{filteredRows.reduce((s, r) => s + r.systemTotal, 0).toFixed(2)}</td>
              <td className="px-3 py-3 text-right">{'\u00a3'}{filteredRows.reduce((s, r) => s + r.difference, 0).toFixed(2)}</td>
              <td />
            </tr></tfoot>}
          </table>
        </div></div>
      ) : (
        <div className="bg-white rounded-xl border border-gray-200 overflow-hidden"><div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead><tr className="border-b border-gray-200 bg-gray-50">
              <th className="px-3 py-3 text-left font-medium text-gray-600">Docket</th>
              <th className="px-3 py-3 text-left font-medium text-gray-600">Department</th>
              <th className="px-3 py-3 text-left font-medium text-gray-600">Type</th>
              <th className="px-3 py-3 text-left font-medium text-gray-600">Name</th>
              <th className="px-3 py-3 text-left font-medium text-gray-600">Items</th>
              <th className="px-3 py-3 text-right font-medium text-gray-600">System Total</th>
              <th className="px-3 py-3 text-left font-medium text-gray-600">Date</th>
              <th className="px-3 py-3 text-center font-medium text-gray-600">Action</th>
            </tr></thead>
            <tbody>
              {result.missingFromInvoice.length === 0
                ? <tr><td colSpan={8} className="px-4 py-12 text-center text-gray-500">All system orders found on invoice</td></tr>
                : result.missingFromInvoice.map(o => {
                const resolution = missingResolutions[o.id]
                return (
                <tr key={o.id} className={`border-b border-gray-100 ${resolution === 'Ignore' ? 'bg-gray-50/60 opacity-60' : resolution === 'Investigate' ? 'bg-yellow-50/40' : 'bg-blue-50/30'}`}>
                  <td className="px-3 py-2.5 font-mono font-medium text-navy">{o.docket_number}</td>
                  <td className="px-3 py-2.5 text-gray-600">{o.department?.name || '\u2014'}</td>
                  <td className="px-3 py-2.5 text-gray-600">{ORDER_TYPE_LABELS[o.order_type as OrderType] ?? o.order_type}</td>
                  <td className="px-3 py-2.5 text-gray-900">{o.staff_name || o.guest_name || '\u2014'}</td>
                  <td className="px-3 py-2.5 text-gray-600 max-w-[250px] truncate">{(o.order_items || []).map(i => `${i.quantity_sent}x ${i.item_name}`).join(', ') || '\u2014'}</td>
                  <td className="px-3 py-2.5 text-right font-medium">{'\u00a3'}{computeOrderCost(o).toFixed(2)}</td>
                  <td className="px-3 py-2.5 text-gray-500 whitespace-nowrap">{format(new Date(o.created_at), 'dd/MM/yyyy')}</td>
                  <td className="px-3 py-2.5 text-center">
                    <select
                      value={resolution || ''}
                      onChange={e => {
                        const val = e.target.value
                        if (val === 'Delete') {
                          handleDeleteOrder(o.id)
                        } else {
                          setMissingResolutions(prev => ({ ...prev, [o.id]: val }))
                        }
                      }}
                      className="text-xs border border-gray-300 rounded px-1.5 py-1 bg-white focus:outline-none focus:ring-1 focus:ring-navy"
                    >
                      <option value="">-- Resolve --</option>
                      <option value="Ignore">Ignore</option>
                      <option value="Investigate">Investigate</option>
                      <option value="Delete">Delete</option>
                    </select>
                    {resolution && resolution !== 'Delete' && (
                      <span className={`ml-1.5 inline-flex px-1.5 py-0.5 rounded text-[10px] font-medium ${resolution === 'Ignore' ? 'bg-gray-200 text-gray-600' : 'bg-yellow-100 text-yellow-700'}`}>
                        {resolution}
                      </span>
                    )}
                  </td>
                </tr>
              )})}
            </tbody>
          </table>
        </div></div>
      )}

      {/* TopUp charges */}
      {result.topUpCharges.length > 0 && (
        <div>
          <h3 className="text-sm font-medium text-gray-700 mb-2">Minimum TopUp Charges</h3>
          <div className="bg-white rounded-xl border border-gray-200 overflow-hidden">
            <table className="w-full text-sm">
              <thead><tr className="border-b border-gray-200 bg-gray-50">
                <th className="px-4 py-3 text-left font-medium text-gray-600">Date Range</th>
                <th className="px-4 py-3 text-left font-medium text-gray-600">Description</th>
                <th className="px-4 py-3 text-left font-medium text-gray-600">Section</th>
                <th className="px-4 py-3 text-right font-medium text-gray-600">NET</th>
                <th className="px-4 py-3 text-right font-medium text-gray-600">VAT</th>
                <th className="px-4 py-3 text-right font-medium text-gray-600">GROSS</th>
              </tr></thead>
              <tbody>{result.topUpCharges.map((l, i) => (
                <tr key={i} className="border-b border-gray-100 bg-amber-50/30">
                  <td className="px-4 py-2.5 text-gray-500">{l.date}</td>
                  <td className="px-4 py-2.5 text-gray-700">{l.description}</td>
                  <td className="px-4 py-2.5 text-gray-500 capitalize">{l.sectionType?.replace('_', ' ') || '\u2014'}</td>
                  <td className="px-4 py-2.5 text-right font-medium">{'\u00a3'}{l.net.toFixed(2)}</td>
                  <td className="px-4 py-2.5 text-right text-gray-500">{'\u00a3'}{l.vat.toFixed(2)}</td>
                  <td className="px-4 py-2.5 text-right font-medium">{'\u00a3'}{l.gross.toFixed(2)}</td>
                </tr>
              ))}</tbody>
              <tfoot><tr className="bg-gray-50 font-medium">
                <td colSpan={3} className="px-4 py-3 text-right text-gray-700">TopUp Total</td>
                <td className="px-4 py-3 text-right">{'\u00a3'}{totalTopUp.toFixed(2)}</td>
                <td className="px-4 py-3 text-right text-gray-500">{'\u00a3'}{(totalTopUp * 0.2).toFixed(2)}</td>
                <td className="px-4 py-3 text-right">{'\u00a3'}{(totalTopUp * 1.2).toFixed(2)}</td>
              </tr></tfoot>
            </table>
          </div>
        </div>
      )}

      {/* Grand totals */}
      <div className="bg-white rounded-xl border border-gray-200 p-6">
        <div className="grid grid-cols-2 sm:grid-cols-4 gap-6">
          <div><p className="text-xs text-gray-500 mb-1">Invoice Total (NET)</p>
            <p className="text-lg font-bold text-gray-900">{'\u00a3'}{invoice.totals.net > 0 ? invoice.totals.net.toFixed(2) : grandInvoiceNet.toFixed(2)}</p></div>
          <div><p className="text-xs text-gray-500 mb-1">Invoice Total (GROSS)</p>
            <p className="text-lg font-bold text-gray-900">{'\u00a3'}{invoice.totals.gross > 0 ? invoice.totals.gross.toFixed(2) : (grandInvoiceNet * 1.2).toFixed(2)}</p></div>
          <div><p className="text-xs text-gray-500 mb-1">System Total (NET)</p>
            <p className="text-lg font-bold text-gray-900">{'\u00a3'}{result.systemTotal.toFixed(2)}</p></div>
          <div><p className="text-xs text-gray-500 mb-1">Order Difference</p>
            <p className={`text-lg font-bold ${Math.abs(result.invoiceTotal - result.systemTotal) < 0.02 ? 'text-green-600' : 'text-amber-600'}`}>
              {'\u00a3'}{(result.invoiceTotal - result.systemTotal).toFixed(2)}</p>
            {totalTopUp > 0 && <p className="text-xs text-gray-500 mt-0.5">+ {'\u00a3'}{totalTopUp.toFixed(2)} TopUp charges</p>}
          </div>
        </div>
      </div>
    </div>
  )
}

function StatCard({ icon, label, value, color }: { icon: React.ReactNode; label: string; value: number; color: string }) {
  return (
    <div className="bg-white rounded-xl border border-gray-200 p-4">
      <div className="flex items-center gap-2 mb-1">{icon}<span className="text-xs text-gray-500">{label}</span></div>
      <p className={`text-2xl font-bold text-${color}-600`}>{value}</p>
    </div>
  )
}
