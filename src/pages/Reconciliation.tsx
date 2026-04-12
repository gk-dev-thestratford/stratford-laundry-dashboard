import { useState, useMemo, useCallback, useEffect } from 'react'
import { Upload, RefreshCw, Download, CheckCircle, AlertTriangle, XCircle, HelpCircle, FileText, X, Save, Clock, ChevronRight, Plus, Mail, Ban, ArrowRightLeft, Send, Search, Scale } from 'lucide-react'
import { supabase } from '../lib/supabase'
import {
  extractPdfLines, extractPdfLinesRaw, parseInvoice, parseInvoicePeriod, derivePeriodFromLines,
  sectionTypeToOrderType,
  type ParsedInvoice, type InvoiceLine, type InvoiceSectionType,
} from '../lib/invoiceParser'
import { downloadReconciliationPdf, generateReconciliationPdfBlob, type DepartmentDisplayRow } from '../lib/pdfReport'
import type { Order, OrderType, Department } from '../types'
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
  matchedOrderIds: string[]
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

type ResolutionType = 'accepted' | 'challenged' | 'written_off' | 'deferred' | 'added_to_system'

interface Resolution {
  type: ResolutionType
  note?: string
}

/** Unique key for a not_found invoice line */
function notFoundKey(line: InvoiceLine): string {
  return `${line.ticket}-${line.date}-${line.net}`
}

// ── Helpers ──

function computeOrderCost(o: Order): number {
  if (o.order_items && o.order_items.length > 0) {
    const t = o.order_items.reduce((s, i) => s + (i.price_at_time ?? 0) * (i.quantity_sent ?? 0), 0)
    if (t > 0) {
      const itemTotal = Math.round(t * 100) / 100
      // If total_price was explicitly set (e.g. from invoice update) and differs from
      // item recalculation, trust total_price — item prices may not have saved (RLS)
      if (o.total_price != null && o.total_price > 0 && Math.abs(itemTotal - o.total_price) > 0.01) {
        return o.total_price
      }
      return itemTotal
    }
  }
  return o.total_price ?? 0
}

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

  if (topUpCharges.length > 0) {
    const sectionDeptCounts = new Map<string, Map<string, number>>()
    for (const row of rows) {
      if (!row.order?.department?.name) continue
      const secType = row.invoiceLine.sectionType || row.sectionType
      if (!sectionDeptCounts.has(secType)) sectionDeptCounts.set(secType, new Map())
      const counts = sectionDeptCounts.get(secType)!
      counts.set(row.order.department.name, (counts.get(row.order.department.name) || 0) + 1)
    }

    const NAPKIN_TOPUP_DEPTS = ['Kitchen E20 Front', 'Lounge', 'Events']
    const MAIN_KITCHEN_NAME = 'Main Kitchen'

    for (const topUp of topUpCharges) {
      const secType = topUp.sectionType || 'staff'
      const orderType = sectionTypeToOrderType(secType as InvoiceSectionType)
      const deptCounts = sectionDeptCounts.get(secType) || sectionDeptCounts.get(orderType)

      if (secType === 'staff') {
        // Uniform TopUp goes 100% to Main Kitchen
        const targetName = MAIN_KITCHEN_NAME
        if (!deptMap.has(targetName)) {
          deptMap.set(targetName, {
            departmentName: targetName, departmentId: null,
            orderCount: 0, invoiceNet: 0, invoiceGross: 0,
            systemTotal: 0, difference: 0, allocatedTopUp: 0,
            totalCostNet: 0, totalCostGross: 0,
          })
        }
        deptMap.get(targetName)!.allocatedTopUp += topUp.net
      } else if (secType === 'napkins' && deptCounts && deptCounts.size > 0) {
        // Napkin TopUp distributed proportionally only across eligible departments
        const eligibleCounts = new Map<string, number>()
        for (const [name, count] of deptCounts) {
          if (NAPKIN_TOPUP_DEPTS.includes(name)) eligibleCounts.set(name, count)
        }
        const totalCount = Array.from(eligibleCounts.values()).reduce((s, c) => s + c, 0)
        if (totalCount > 0) {
          for (const [name, count] of eligibleCounts) {
            const share = +(topUp.net * count / totalCount).toFixed(2)
            if (!deptMap.has(name)) {
              deptMap.set(name, {
                departmentName: name, departmentId: null,
                orderCount: 0, invoiceNet: 0, invoiceGross: 0,
                systemTotal: 0, difference: 0, allocatedTopUp: 0,
                totalCostNet: 0, totalCostGross: 0,
              })
            }
            deptMap.get(name)!.allocatedTopUp += share
          }
        }
      } else if (deptCounts && deptCounts.size > 0) {
        // Other sections: distribute TopUp proportionally across all departments
        const totalCount = Array.from(deptCounts.values()).reduce((s, c) => s + c, 0)
        for (const [name, count] of deptCounts) {
          const share = +(topUp.net * count / totalCount).toFixed(2)
          if (!deptMap.has(name)) {
            deptMap.set(name, {
              departmentName: name, departmentId: null,
              orderCount: 0, invoiceNet: 0, invoiceGross: 0,
              systemTotal: 0, difference: 0, allocatedTopUp: 0,
              totalCostNet: 0, totalCostGross: 0,
            })
          }
          deptMap.get(name)!.allocatedTopUp += share
        }
      } else {
        if (!deptMap.has('Unallocated')) {
          deptMap.set('Unallocated', {
            departmentName: 'Unallocated', departmentId: null,
            orderCount: 0, invoiceNet: 0, invoiceGross: 0,
            systemTotal: 0, difference: 0, allocatedTopUp: 0,
            totalCostNet: 0, totalCostGross: 0,
          })
        }
        deptMap.get('Unallocated')!.allocatedTopUp += topUp.net
      }
    }
  }

  for (const dept of deptMap.values()) {
    dept.allocatedTopUp = +dept.allocatedTopUp.toFixed(2)
    dept.totalCostNet = +(dept.invoiceNet + dept.allocatedTopUp).toFixed(2)
    dept.totalCostGross = +(dept.totalCostNet * 1.2).toFixed(2)
  }

  return Array.from(deptMap.values()).sort((a, b) => b.totalCostNet - a.totalCostNet)
}

function departmentItemsLabel(rows: ReconciliationRow[], deptName: string): string {
  const typeCounts = new Map<string, number>()
  for (const row of rows) {
    const dept = row.order?.department?.name || 'Unallocated'
    if (dept !== deptName) continue
    const t = row.sectionType || 'uniform'
    typeCounts.set(t, (typeCounts.get(t) || 0) + 1)
  }
  if (typeCounts.size === 0) return 'Items'
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

function isHskLinenRow(row: ReconciliationRow, hskLinenNames: Set<string>): boolean {
  // Check invoice line description and parsed items against catalogue HSK Linen names
  const desc = (row.invoiceLine.description || '').toLowerCase()
  for (const name of hskLinenNames) {
    if (desc.includes(name)) return true
  }
  if (row.invoiceLine.items?.length) {
    return row.invoiceLine.items.some(i => {
      const itemLower = i.name.toLowerCase()
      for (const name of hskLinenNames) {
        if (itemLower.includes(name)) return true
      }
      return false
    })
  }
  return false
}

function buildDepartmentDisplayRows(
  breakdown: DepartmentBreakdown[],
  allRows: ReconciliationRow[],
  hskLinenNames: Set<string> = new Set()
): DepartmentDisplayRow[] {
  const displayRows: DepartmentDisplayRow[] = []
  for (const dept of breakdown) {
    // Check if this department has a mix of staff uniform and HSK linen items
    let uniformCount = 0, uniformInvNet = 0, uniformSysNet = 0
    let linenCount = 0, linenInvNet = 0, linenSysNet = 0

    for (const row of allRows) {
      const deptName = row.order?.department?.name || 'Unallocated'
      if (deptName !== dept.departmentName || row.status === 'not_found') continue
      if (isHskLinenRow(row, hskLinenNames)) {
        linenCount++
        linenInvNet += row.invoiceLine.net
        linenSysNet += row.systemTotal
      } else {
        uniformCount++
        uniformInvNet += row.invoiceLine.net
        uniformSysNet += row.systemTotal
      }
    }

    const hasSubBreakdown = linenCount > 0 && uniformCount > 0
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

    if (hasSubBreakdown) {
      displayRows.push({
        departmentName: dept.departmentName,
        lineLabel: 'Staff Uniform',
        isTopUp: true,
        orderCount: uniformCount,
        invoiceNet: +uniformInvNet.toFixed(2),
        systemTotal: +uniformSysNet.toFixed(2),
        difference: +(uniformInvNet - uniformSysNet).toFixed(2),
        totalGross: +(uniformInvNet * 1.2).toFixed(2),
      })
      displayRows.push({
        departmentName: dept.departmentName,
        lineLabel: 'Other (HSK Linen)',
        isTopUp: true,
        orderCount: linenCount,
        invoiceNet: +linenInvNet.toFixed(2),
        systemTotal: +linenSysNet.toFixed(2),
        difference: +(linenInvNet - linenSysNet).toFixed(2),
        totalGross: +(linenInvNet * 1.2).toFixed(2),
      })
    }
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

function reconcile(invoice: ParsedInvoice, orders: Order[], period: { start: Date; end: Date } | null, strictPeriod?: { start: Date; end: Date } | null): ReconciliationResult {
  // Issue 2: Use array map to handle duplicate docket numbers
  const byDocket = new Map<string, Order[]>()
  const byRoom = new Map<string, Order[]>()
  for (const o of orders) {
    const dk = o.docket_number.trim()
    if (!byDocket.has(dk)) byDocket.set(dk, [])
    byDocket.get(dk)!.push(o)
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
      // Issue 2: Pick first unclaimed order with this docket
      const docketCandidates = byDocket.get(line.ticket.trim()) ?? []
      let order = docketCandidates.find(o => !matchedOrderIds.has(o.id)) ?? null
      if (!order && section.type === 'guest' && line.ticket) {
        const candidates = (byRoom.get(line.ticket) ?? []).filter(o => !matchedOrderIds.has(o.id))
        if (candidates.length === 1) order = candidates[0]
        else if (candidates.length > 1 && line.guestInfo) {
          const name = line.guestInfo.replace(/[()]/g, '').toLowerCase()
          order = candidates.find(o => o.guest_name?.toLowerCase().includes(name)) ?? candidates[0]
        }
      }
      // Fallback: match orders added from reconciliation by embedded ref key
      if (!order) {
        const refKey = `[ref:${line.ticket}|${line.date}|${line.net}]`
        order = orders.find(o => {
          if (matchedOrderIds.has(o.id)) return false
          return o.notes?.includes(refKey) === true
        }) ?? null
      }
      if (order) matchedOrderIds.add(order.id)
      const systemTotal = order ? computeOrderCost(order) : 0
      const diff = order ? +(line.net - systemTotal).toFixed(2) : line.net
      const status: ReconciliationRow['status'] = !order
        ? 'not_found' : Math.abs(diff) < 0.02 ? 'matched' : 'price_mismatch'
      rows.push({ invoiceLine: line, sectionType: orderType, order, status, systemTotal, difference: diff })
    }
  }

  // Issue 1: Use strictPeriod (original invoice period) for "In System Only" filtering
  // so broader-search orders from the previous month don't appear as missing
  const missingPeriod = strictPeriod ?? period
  const invoiceOrderTypes = new Set(invoice.sections.map(s => sectionTypeToOrderType(s.type)))
  const missingFromInvoice = orders.filter(o => {
    if (matchedOrderIds.has(o.id)) return false
    if (!invoiceOrderTypes.has(o.order_type)) return false
    if (missingPeriod) {
      const orderDate = new Date(o.created_at)
      if (orderDate < missingPeriod.start || orderDate > missingPeriod.end) return false
    }
    return true
  })

  return {
    rows, topUpCharges, missingFromInvoice,
    matchedOrderIds: Array.from(matchedOrderIds),
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
  const [parsedPeriod, setParsedPeriod] = useState<{ start: Date; end: Date } | null>(null)
  const [showHistory, setShowHistory] = useState(false)
  const [history, setHistory] = useState<SavedReconciliation[]>([])
  const [loadingHistory, setLoadingHistory] = useState(false)
  const [updatingPrices, setUpdatingPrices] = useState<Set<string>>(new Set())
  const [hskLinenNames, setHskLinenNames] = useState<Set<string>>(new Set())
  const [broaderSearch, setBroaderSearch] = useState(false)
  const [deptBreakdownOpen, setDeptBreakdownOpen] = useState(true)
  const [uniformMinOpen, setUniformMinOpen] = useState(true)

  // Fetch HSK Linen item names from catalogue (excluding bathrobes — they have their own invoice)
  useEffect(() => {
    supabase.from('item_catalogue').select('name').eq('category', 'hsk_linen').eq('is_active', true)
      .then(({ data }) => {
        if (data) {
          const names = new Set(data.map((i: { name: string }) => i.name.toLowerCase()).filter(n => !n.includes('bathrobe')))
          setHskLinenNames(names)
        }
      })
  }, [])

  // Resolution tracking
  const [notFoundResolutions, setNotFoundResolutions] = useState<Record<string, Resolution>>({})
  const [missingResolutions, setMissingResolutions] = useState<Record<string, Resolution>>({})
  const [challengedItems, setChallengedItems] = useState<Set<string>>(new Set()) // "nf:{key}" or "miss:{orderId}" or "mm:{key}"
  const [showChallengePanel, setShowChallengePanel] = useState(false)
  const [challengeEmail, setChallengeEmail] = useState('')

  // Add to System modal
  const [addModal, setAddModal] = useState<{ row: ReconciliationRow; index: number } | null>(null)
  const [addModalDept, setAddModalDept] = useState('')
  const [addModalDocket, setAddModalDocket] = useState('')
  const [addModalDate, setAddModalDate] = useState('')
  const [addModalSaving, setAddModalSaving] = useState(false)
  const [departments, setDepartments] = useState<Department[]>([])
  const [catalogueItems, setCatalogueItems] = useState<{ name: string; price: number | null; category: string }[]>([])

  // Fetch departments for "Add to System" form
  useEffect(() => {
    supabase.from('departments').select('*').eq('is_active', true).order('name').then(({ data }) => {
      if (data) setDepartments(data)
    })
  }, [])

  // Fetch catalogue items for price comparison in Add to System modal
  useEffect(() => {
    supabase.from('item_catalogue').select('name, price, category').eq('is_active', true).then(({ data }) => {
      if (data) setCatalogueItems(data)
    })
  }, [])

  const loadHistory = useCallback(async () => {
    setLoadingHistory(true)
    const { data } = await supabase
      .from('reconciliations').select('*')
      .order('created_at', { ascending: false }).limit(50)
    setHistory((data as SavedReconciliation[] | null) ?? [])
    setLoadingHistory(false)
  }, [])

  useEffect(() => { loadHistory() }, [loadHistory])

  // Issue 1: Re-trigger reconciliation when broader search toggle changes
  useEffect(() => {
    if (invoice) refetchAndReconcile()
  }, [broaderSearch]) // eslint-disable-line react-hooks/exhaustive-deps

  // ── Shared re-fetch + re-reconcile helper ──
  const refetchAndReconcile = useCallback(async () => {
    if (!invoice) return
    const period = parseInvoicePeriod(invoice.invoicePeriod) || derivePeriodFromLines(invoice)
    setParsedPeriod(period)
    let fetchedOrders: Order[] = []
    if (period) {
      // Issue 1: If broader search is ON, extend start date back 1 month
      let fetchStart = period.start
      if (broaderSearch) {
        fetchStart = new Date(period.start)
        fetchStart.setUTCMonth(fetchStart.getUTCMonth() - 1)
      }
      const { data } = await supabase.from('orders').select('*, department:departments(*), order_items(*)')
        .gte('created_at', fetchStart.toISOString()).lte('created_at', period.end.toISOString())
        .order('created_at', { ascending: true })
      fetchedOrders = data ?? []
    } else {
      const { data } = await supabase.from('orders').select('*, department:departments(*), order_items(*)')
        .order('created_at', { ascending: false }).limit(500)
      fetchedOrders = data ?? []
    }
    setOrders(fetchedOrders)
    // Pass original period as strictPeriod so broader-search orders don't appear in "In System Only"
    setResult(reconcile(invoice, fetchedOrders, broaderSearch && period ? { start: new Date(new Date(period.start).setUTCMonth(period.start.getUTCMonth() - 1)), end: period.end } : period, period))
  }, [invoice, broaderSearch])

  async function handleFile(f: File) {
    if (!f.type.includes('pdf')) { setError('Please upload a PDF file'); return }
    setFile(f); setError(''); setParsing(true)
    setInvoice(null); setResult(null); setSaved(false); setShowHistory(false)
    setNotFoundResolutions({}); setMissingResolutions({}); setChallengedItems(new Set())
    try {
      const lines = await extractPdfLines(f)
      console.log('[Reconciliation] Extracted PDF lines:', lines.slice(0, 30))
      const parsed = parseInvoice(lines)
      console.log('[Reconciliation] Parsed metadata:', { invoiceNumber: parsed.invoiceNumber, invoiceDate: parsed.invoiceDate, invoicePeriod: parsed.invoicePeriod })
      if (parsed.sections.every(s => s.lines.length === 0)) {
        setError('Could not parse any invoice lines.'); setParsing(false); return
      }
      setInvoice(parsed)
      const period = parseInvoicePeriod(parsed.invoicePeriod) || derivePeriodFromLines(parsed)
      setParsedPeriod(period)
      let fetchedOrders: Order[] = []
      if (period) {
        let fetchStart = period.start
        if (broaderSearch) {
          fetchStart = new Date(period.start)
          fetchStart.setUTCMonth(fetchStart.getUTCMonth() - 1)
        }
        const { data } = await supabase.from('orders').select('*, department:departments(*), order_items(*)')
          .gte('created_at', fetchStart.toISOString()).lte('created_at', period.end.toISOString())
          .order('created_at', { ascending: true })
        fetchedOrders = data ?? []
      } else {
        const { data } = await supabase.from('orders').select('*, department:departments(*), order_items(*)')
          .order('created_at', { ascending: false }).limit(500)
        fetchedOrders = data ?? []
      }
      setOrders(fetchedOrders)
      setResult(reconcile(parsed, fetchedOrders, broaderSearch && period ? { start: new Date(new Date(period.start).setUTCMonth(period.start.getUTCMonth() - 1)), end: period.end } : period, period))
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to parse PDF')
    } finally { setParsing(false) }
  }

  function reset() {
    setFile(null); setInvoice(null); setOrders([]); setResult(null)
    setError(''); setFilter('all'); setSaved(false); setBroaderSearch(false)
    setUpdatingPrices(new Set()); setNotFoundResolutions({}); setMissingResolutions({})
    setAddModalDocket(''); setAddModalDate('')
    setChallengedItems(new Set()); setAddModal(null)
  }

  const saveReconciliation = useCallback(async () => {
    if (!result || !invoice) return
    setSaving(true)
    const totalTopUp = result.topUpCharges.reduce((s, l) => s + l.net, 0)
    // Detect invoice category from filename or invoice title
    const fileName = (file?.name || '').toLowerCase()
    const invoiceCategory = fileName.includes('bathrobe') ? 'Bathrobes'
      : fileName.includes('napkin') ? 'Napkins'
      : fileName.includes('table cloth') || fileName.includes('tablecloth') ? 'Table Cloths'
      : fileName.includes('hsk') || fileName.includes('linen') ? 'HSK Linen'
      : fileName.includes('guest') ? 'Guest Laundry'
      : fileName.includes('staff') || fileName.includes('uniform') ? 'Staff Uniforms'
      : 'Other'
    const { data: { user } } = await supabase.auth.getUser()
    const ts = Date.now()

    // Upload invoice PDF to storage if we have the file
    let invoicePath: string | null = null
    if (file) {
      const path = `invoices/${ts}-${file.name}`
      const { error: uploadErr } = await supabase.storage.from('reconciliations').upload(path, file, { contentType: 'application/pdf' })
      if (!uploadErr) invoicePath = path
    }

    // Generate and upload reconciliation PDF report
    let reportPath: string | null = null
    try {
      const deptRows = buildDepartmentDisplayRows(result.departmentBreakdown, result.rows, hskLinenNames)
      const uniformMinWeeksForPdf = uniformMinSummary?.weeks.map(w => ({
        dateRange: w.dateRange,
        items: uniformMinSummary.ITEM_KEYS.map(k => ({
          key: k.charAt(0).toUpperCase() + k.slice(1),
          sent: w.invoiceSent[k], topUp: w.topUp[k], min: uniformMinSummary.MINIMUMS[k],
        })),
        topUpNet: w.topUpNet,
      }))
      const reportBlob = generateReconciliationPdfBlob(invoice, result, deptRows, napkinSummary?.deptTotals, uniformMinWeeksForPdf)
      const rptName = `reports/${ts}-reconciliation-${invoice.invoiceNumber || 'report'}.pdf`
      const { error: rptErr } = await supabase.storage.from('reconciliations').upload(rptName, reportBlob, { contentType: 'application/pdf' })
      if (!rptErr) reportPath = rptName
    } catch (e) {
      console.error('Failed to upload PDF report:', e)
    }

    const { data: savedRec, error: saveErr } = await supabase.from('reconciliations').insert({
      invoice_number: invoice.invoiceNumber, invoice_date: invoice.invoiceDate,
      invoice_period: invoice.invoicePeriod, created_by: user?.email || 'unknown',
      invoice_net: +result.invoiceTotal.toFixed(2), invoice_gross: +(result.invoiceTotal * 1.2).toFixed(2),
      system_total: +result.systemTotal.toFixed(2), topup_total: +totalTopUp.toFixed(2),
      matched_count: result.stats.matched, mismatch_count: result.stats.priceMismatch,
      not_found_count: result.stats.notFound, missing_count: result.stats.missing,
      invoice_file_path: invoicePath,
      report_file_path: reportPath,
      invoice_category: invoiceCategory,
      department_breakdown: result.departmentBreakdown.map(d => ({
        departmentName: d.departmentName, orderCount: d.orderCount,
        invoiceNet: +d.invoiceNet.toFixed(2), systemTotal: +d.systemTotal.toFixed(2),
        allocatedTopUp: d.allocatedTopUp, totalCostNet: d.totalCostNet, totalCostGross: d.totalCostGross,
      })),
    }).select('id').single()
    if (saveErr) console.error('Failed to save reconciliation:', saveErr)

    // Issue 4: Mark matched orders as reconciled so they don't appear in future reconciliations
    if (savedRec && result.matchedOrderIds.length > 0) {
      const { error: stampErr } = await supabase.from('orders')
        .update({ reconciliation_id: savedRec.id })
        .in('id', result.matchedOrderIds)
      if (stampErr) console.error('Failed to stamp orders as reconciled:', stampErr)
    }

    setSaving(false); setSaved(true); loadHistory()
  }, [result, invoice, file, loadHistory])

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
    return buildDepartmentDisplayRows(result.departmentBreakdown, result.rows, hskLinenNames)
  }, [result])

  // ── Napkin Usage Summary ──
  const [linenLedger, setLinenLedger] = useState<{ direction: string; quantity: number; created_at: string }[]>([])

  // Fetch linen ledger data when invoice has napkins section
  useEffect(() => {
    if (!invoice || !parsedPeriod) return
    const hasNapkins = invoice.sections.some(s => s.type === 'napkins')
    if (!hasNapkins) { setLinenLedger([]); return }
    supabase.from('linen_ledger')
      .select('direction, quantity, created_at')
      .ilike('item_name', '%napkin%')
      .gte('created_at', parsedPeriod.start.toISOString())
      .lte('created_at', parsedPeriod.end.toISOString())
      .then(({ data }) => setLinenLedger(data ?? []))
  }, [invoice, parsedPeriod])

  const napkinSummary = useMemo(() => {
    if (!result || !invoice) return null
    const napkinSection = invoice.sections.find(s => s.type === 'napkins')
    if (!napkinSection || napkinSection.lines.length === 0) return null

    const WEEKLY_MIN = 2500
    const UNIT_RATE = 0.215

    // Helper: parse date string to Date (derive year from invoice period)
    function parseDate(dateStr: string): Date | null {
      if (!dateStr) return null
      const yrM = invoice!.invoicePeriod.match(/(\d{2,4})\s*$/)
      let defaultYr = yrM ? parseInt(yrM[1]) : new Date().getFullYear()
      if (defaultYr < 100) defaultYr += 2000
      const singleM = dateStr.match(/^(\d{2})\/(\d{2})(?:\/(\d{2,4}))?$/)
      if (singleM) {
        let yr = singleM[3] ? parseInt(singleM[3]) : defaultYr
        if (yr < 100) yr += 2000
        return new Date(Date.UTC(yr, parseInt(singleM[2]) - 1, parseInt(singleM[1])))
      }
      return null
    }

    // Group invoice lines by week using TopUp lines as week boundaries
    // Each TopUp line marks the end of a week and shows the minimum shortfall
    interface NapkinDeptBreakdown {
      deptId: string | null
      deptName: string
      sentQty: number
      pctShare: number
      actualCost: number
      topUpAlloc: number
      totalCost: number
    }

    interface NapkinWeek {
      dateRange: string
      invoiceItems: number  // count of individual docket lines
      invoiceSentQty: number  // sum of actual napkins sent (from docket lines)
      topUpQty: number  // minimum top-up quantity
      topUpNet: number  // cost of the top-up
      totalChargedQty: number  // sent + topup = what they charge
      totalNet: number  // total cost for the week
      systemSentQty: number  // from our system orders
      poolReceivedQty: number  // from linen ledger 'in' entries
      weekStart: Date | null
      weekEnd: Date | null
      deptBreakdown: NapkinDeptBreakdown[]
    }

    const weeks: NapkinWeek[] = []
    let currentWeek: Omit<NapkinWeek, 'systemSentQty' | 'poolReceivedQty' | 'deptBreakdown'> = {
      dateRange: '', invoiceItems: 0, invoiceSentQty: 0,
      topUpQty: 0, topUpNet: 0, totalChargedQty: 0, totalNet: 0,
      weekStart: null, weekEnd: null,
    }
    let lastDate = ''

    for (const line of napkinSection.lines) {
      if (line.isTopUp) {
        // TopUp line closes the current week
        const topUpQty = line.items[0]?.quantity ?? 0
        currentWeek.topUpQty = topUpQty
        currentWeek.topUpNet = line.net
        currentWeek.totalChargedQty = currentWeek.invoiceSentQty + topUpQty
        currentWeek.totalNet += line.net
        currentWeek.dateRange = line.date || (currentWeek.weekStart ? `${format(currentWeek.weekStart, 'dd/MM')}-${currentWeek.weekEnd ? format(currentWeek.weekEnd, 'dd/MM') : ''}` : lastDate)
        weeks.push({ ...currentWeek, systemSentQty: 0, poolReceivedQty: 0, deptBreakdown: [] })
        currentWeek = { dateRange: '', invoiceItems: 0, invoiceSentQty: 0, topUpQty: 0, topUpNet: 0, totalChargedQty: 0, totalNet: 0, weekStart: null, weekEnd: null }
      } else {
        // Regular docket line
        const qty = line.items[0]?.quantity ?? 0
        currentWeek.invoiceItems++
        currentWeek.invoiceSentQty += qty
        currentWeek.totalNet += line.net
        const d = parseDate(line.date)
        if (d) {
          if (!currentWeek.weekStart || d < currentWeek.weekStart) currentWeek.weekStart = d
          if (!currentWeek.weekEnd || d > currentWeek.weekEnd) currentWeek.weekEnd = d
        }
        lastDate = line.date
      }
    }
    // Remaining lines after last TopUp (e.g. partial week at end of month)
    if (currentWeek.invoiceItems > 0) {
      currentWeek.totalChargedQty = currentWeek.invoiceSentQty
      currentWeek.dateRange = currentWeek.weekStart ? `${format(currentWeek.weekStart, 'dd/MM')}-${currentWeek.weekEnd ? format(currentWeek.weekEnd, 'dd/MM') : ''}` : lastDate
      weeks.push({ ...currentWeek, systemSentQty: 0, poolReceivedQty: 0, deptBreakdown: [] })
    }

    // Match system orders and linen ledger to each week, group by department
    const napkinOrders = orders.filter(o => o.order_type === 'fnb_linen' && o.order_items?.some(
      (it: any) => it.item_name?.toLowerCase().includes('napkin')
    ))

    for (const week of weeks) {
      if (!week.weekStart || !week.weekEnd) continue
      const ws = week.weekStart.getTime()
      const we = week.weekEnd.getTime() + 86400000 // end of day

      // Group system sent by department
      const deptMap = new Map<string, { name: string; qty: number }>()
      for (const o of napkinOrders) {
        const orderTime = new Date(o.created_at).getTime()
        if (orderTime >= ws && orderTime < we) {
          const deptId = o.department_id || '_none'
          const deptName = o.department?.name || 'Unallocated'
          if (!deptMap.has(deptId)) deptMap.set(deptId, { name: deptName, qty: 0 })
          for (const it of (o.order_items || [])) {
            if (it.item_name?.toLowerCase().includes('napkin')) {
              deptMap.get(deptId)!.qty += it.quantity_sent ?? 0
              week.systemSentQty += it.quantity_sent ?? 0
            }
          }
        }
      }

      // Calculate department breakdown with cost allocation
      // TopUp only allocated to eligible napkin departments
      const NAPKIN_TOPUP_DEPTS = ['Kitchen E20 Front', 'Lounge', 'Events']
      const eligibleSent = Array.from(deptMap.values())
        .filter(d => NAPKIN_TOPUP_DEPTS.includes(d.name))
        .reduce((s, d) => s + d.qty, 0)
      week.deptBreakdown = Array.from(deptMap.entries()).map(([id, d]) => {
        const isEligible = NAPKIN_TOPUP_DEPTS.includes(d.name)
        const pctShare = isEligible && eligibleSent > 0 ? d.qty / eligibleSent * 100 : 0
        const actualCost = +(d.qty * UNIT_RATE).toFixed(2)
        const topUpAlloc = isEligible ? +(pctShare / 100 * week.topUpNet).toFixed(2) : 0
        return {
          deptId: id === '_none' ? null : id,
          deptName: d.name,
          sentQty: d.qty,
          pctShare: Math.round(pctShare * 10) / 10,
          actualCost,
          topUpAlloc,
          totalCost: +(actualCost + topUpAlloc).toFixed(2),
        }
      }).sort((a, b) => b.sentQty - a.sentQty)

      // Pool received (from linen ledger 'in' entries)
      for (const entry of linenLedger) {
        if (entry.direction !== 'in') continue
        const entryTime = new Date(entry.created_at).getTime()
        if (entryTime >= ws && entryTime < we) {
          week.poolReceivedQty += entry.quantity
        }
      }
    }

    // Monthly department totals (aggregate across all weeks)
    const deptTotalMap = new Map<string, { name: string; sent: number; topUp: number; actual: number }>()
    for (const week of weeks) {
      for (const d of week.deptBreakdown) {
        const key = d.deptId || '_none'
        if (!deptTotalMap.has(key)) deptTotalMap.set(key, { name: d.deptName, sent: 0, topUp: 0, actual: 0 })
        const t = deptTotalMap.get(key)!
        t.sent += d.sentQty
        t.topUp += d.topUpAlloc
        t.actual += d.actualCost
      }
    }
    const totalSentAll = Array.from(deptTotalMap.values()).reduce((s, d) => s + d.sent, 0)
    const deptTotals = Array.from(deptTotalMap.entries()).map(([id, d]) => ({
      deptId: id === '_none' ? null : id,
      deptName: d.name,
      totalSent: d.sent,
      pctShare: totalSentAll > 0 ? Math.round(d.sent / totalSentAll * 1000) / 10 : 0,
      totalActualCost: +d.actual.toFixed(2),
      totalTopUpAlloc: +d.topUp.toFixed(2),
      totalCost: +(d.actual + d.topUp).toFixed(2),
    })).sort((a, b) => b.totalSent - a.totalSent)

    // Totals
    const totalInvoiceSent = weeks.reduce((s, w) => s + w.invoiceSentQty, 0)
    const totalTopUp = weeks.reduce((s, w) => s + w.topUpQty, 0)
    const totalCharged = weeks.reduce((s, w) => s + w.totalChargedQty, 0)
    const totalSystemSent = weeks.reduce((s, w) => s + w.systemSentQty, 0)
    const totalReceived = weeks.reduce((s, w) => s + w.poolReceivedQty, 0)
    const totalTopUpCost = weeks.reduce((s, w) => s + w.topUpNet, 0)
    const totalNet = weeks.reduce((s, w) => s + w.totalNet, 0)
    const hasLedgerData = linenLedger.length > 0

    return {
      weeks, deptTotals, totalInvoiceSent, totalTopUp, totalCharged,
      totalSystemSent, totalReceived, totalTopUpCost, totalNet,
      weeklyMinimum: WEEKLY_MIN, unitRate: UNIT_RATE,
      weeklyMinCost: +(WEEKLY_MIN * UNIT_RATE).toFixed(2),
      hasLedgerData,
    }
  }, [result, invoice, orders, linenLedger])

  // ── Chef Uniform Minimum Usage (Main Kitchen) ──
  const uniformMinSummary = useMemo(() => {
    if (!result || !invoice) return null
    const staffSection = invoice.sections.find(s => s.type === 'staff')
    if (!staffSection || !staffSection.lines.some(l => l.isTopUp)) return null

    const ITEM_KEYS = ['chef jacket', 'apron', 'chef trouser'] as const
    type ItemKey = typeof ITEM_KEYS[number]
    const MINIMUMS: Record<ItemKey, number> = { 'chef jacket': 85, 'apron': 80, 'chef trouser': 80 }
    const PRICES: Record<ItemKey, number> = { 'chef jacket': 1.41, 'apron': 0.99, 'chef trouser': 1.48 }
    const MAIN_KITCHEN_ID = '048478b5-976a-4522-8316-02a9456d8c91'

    function normaliseChefItem(name: string): ItemKey | null {
      const lower = name.toLowerCase()
      if (lower.includes('chef') && lower.includes('jacket')) return 'chef jacket'
      if (lower.includes('apron')) return 'apron'
      if (lower.includes('chef') && (lower.includes('trouser') || lower.includes('trousers'))) return 'chef trouser'
      return null
    }

    function emptyItemCounts(): Record<ItemKey, number> {
      return { 'chef jacket': 0, 'apron': 0, 'chef trouser': 0 }
    }

    interface UniformWeek {
      dateRange: string
      weekStart: Date | null
      weekEnd: Date | null
      invoiceSent: Record<ItemKey, number>
      topUp: Record<ItemKey, number>
      topUpNet: number
      systemSent: Record<ItemKey, number>
    }

    const weeks: UniformWeek[] = []
    let currentWeek = {
      dateRange: '', weekStart: null as Date | null, weekEnd: null as Date | null,
      invoiceSent: emptyItemCounts(), topUpNet: 0,
    }
    let lastDate = ''

    // Helper to parse date
    function parseDate(dateStr: string): Date | null {
      if (!dateStr) return null
      const yrM = invoice!.invoicePeriod.match(/(\d{2,4})\s*$/)
      let defaultYr = yrM ? parseInt(yrM[1]) : new Date().getFullYear()
      if (defaultYr < 100) defaultYr += 2000
      const singleM = dateStr.match(/^(\d{1,2})\/(\d{2})(?:\/(\d{2,4}))?$/)
      if (singleM) {
        let yr = singleM[3] ? parseInt(singleM[3]) : defaultYr
        if (yr < 100) yr += 2000
        return new Date(Date.UTC(yr, parseInt(singleM[2]) - 1, parseInt(singleM[1])))
      }
      return null
    }

    // Group staff section lines by week using TopUp as boundary
    for (const line of staffSection.lines) {
      if (line.isTopUp) {
        // Extract per-item TopUp quantities
        const topUp = emptyItemCounts()
        for (const it of line.items) {
          const key = normaliseChefItem(it.name)
          if (key) topUp[key] += it.quantity
        }
        const dr = line.date || (currentWeek.weekStart ? `${format(currentWeek.weekStart, 'dd/MM')}-${currentWeek.weekEnd ? format(currentWeek.weekEnd, 'dd/MM') : ''}` : lastDate)
        weeks.push({ ...currentWeek, dateRange: dr, topUp, topUpNet: line.net, systemSent: emptyItemCounts() })
        currentWeek = { dateRange: '', weekStart: null, weekEnd: null, invoiceSent: emptyItemCounts(), topUpNet: 0 }
      } else {
        // Count chef items from matched Main Kitchen orders
        if (line.sectionType === 'staff' || !line.sectionType) {
          for (const it of line.items) {
            const key = normaliseChefItem(it.name)
            if (key) currentWeek.invoiceSent[key] += it.quantity
          }
        }
        const d = parseDate(line.date)
        if (d) {
          if (!currentWeek.weekStart || d < currentWeek.weekStart) currentWeek.weekStart = d
          if (!currentWeek.weekEnd || d > currentWeek.weekEnd) currentWeek.weekEnd = d
        }
        lastDate = line.date
      }
    }

    // Skip if no weeks found (no TopUp lines in staff section)
    if (weeks.length === 0) return null

    // Match system orders for Main Kitchen uniforms per week
    const kitchenUniformOrders = orders.filter(o =>
      o.order_type === 'uniform' && o.department_id === MAIN_KITCHEN_ID
    )

    for (const week of weeks) {
      if (!week.weekStart || !week.weekEnd) continue
      const ws = week.weekStart.getTime()
      const we = week.weekEnd.getTime() + 86400000

      for (const o of kitchenUniformOrders) {
        const orderTime = new Date(o.created_at).getTime()
        if (orderTime >= ws && orderTime < we) {
          for (const it of (o.order_items || [])) {
            const key = normaliseChefItem(it.item_name || '')
            if (key) week.systemSent[key] += it.quantity_sent ?? 0
          }
        }
      }
    }

    // Totals
    const totalInvoiceSent = emptyItemCounts()
    const totalTopUp = emptyItemCounts()
    const totalSystemSent = emptyItemCounts()
    let totalTopUpNet = 0

    for (const w of weeks) {
      for (const k of ITEM_KEYS) {
        totalInvoiceSent[k] += w.invoiceSent[k]
        totalTopUp[k] += w.topUp[k]
        totalSystemSent[k] += w.systemSent[k]
      }
      totalTopUpNet += w.topUpNet
    }

    // Unused capacity per item across all weeks
    const unusedCapacity = emptyItemCounts()
    for (const w of weeks) {
      for (const k of ITEM_KEYS) {
        const sent = w.invoiceSent[k]
        if (sent < MINIMUMS[k]) unusedCapacity[k] += MINIMUMS[k] - sent
      }
    }

    return {
      weeks, ITEM_KEYS, MINIMUMS, PRICES, weekCount: weeks.length,
      totalInvoiceSent, totalTopUp, totalSystemSent, totalTopUpNet,
      unusedCapacity,
      unusedCost: ITEM_KEYS.reduce((s, k) => s + unusedCapacity[k] * PRICES[k], 0),
    }
  }, [result, invoice, orders])

  // ── Adjusted totals considering resolutions ──
  const adjustedTotals = useMemo(() => {
    if (!result) return { unresolvedDiff: 0, resolvedCount: 0, acceptedTotal: 0, writtenOffTotal: 0, challengedCount: 0 }

    let acceptedTotal = 0
    let writtenOffTotal = 0
    let resolvedCount = 0

    // Not Found resolutions
    for (const row of result.rows) {
      if (row.status !== 'not_found') continue
      const key = notFoundKey(row.invoiceLine)
      const res = notFoundResolutions[key]
      if (res) {
        resolvedCount++
        if (res.type === 'accepted' || res.type === 'added_to_system') {
          acceptedTotal += row.invoiceLine.net
        }
      }
    }

    // Missing resolutions
    for (const o of result.missingFromInvoice) {
      const res = missingResolutions[o.id]
      if (res) {
        resolvedCount++
        if (res.type === 'written_off' || res.type === 'deferred') {
          writtenOffTotal += computeOrderCost(o)
        }
      }
    }

    // Original difference = invoiceTotal - systemTotal
    // Accepted not-found items mean we acknowledge the charge → system effectively increases
    // Written-off missing items mean we don't expect billing → system effectively decreases
    const unresolvedDiff = (result.invoiceTotal - result.systemTotal) - acceptedTotal + writtenOffTotal

    return {
      unresolvedDiff: +unresolvedDiff.toFixed(2),
      resolvedCount,
      acceptedTotal: +acceptedTotal.toFixed(2),
      writtenOffTotal: +writtenOffTotal.toFixed(2),
      challengedCount: challengedItems.size,
    }
  }, [result, notFoundResolutions, missingResolutions, challengedItems])

  // ── Accounting Report Export ──
  const exportAccountingReport = useCallback(() => {
    if (!result || !invoice) return
    const wb = utils.book_new()
    const totalTopUp = result.topUpCharges.reduce((s, l) => s + l.net, 0)
    const grandNet = result.invoiceTotal + totalTopUp

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
      ['Price Discrepancies', result.stats.priceMismatch],
      ['On Invoice Only', result.stats.notFound],
      ['In System Only', result.stats.missing],
    ])
    summarySheet['!cols'] = [{ wch: 25 }, { wch: 15 }, { wch: 12 }, { wch: 15 }]
    utils.book_append_sheet(wb, summarySheet, 'Summary')

    const deptDisplayRows = buildDepartmentDisplayRows(result.departmentBreakdown, result.rows, hskLinenNames)
    const deptExcelRows: Record<string, string | number>[] = deptDisplayRows.map(row => ({
      'Department': row.departmentName,
      'Line': row.lineLabel,
      'Orders': (row.isTopUp && row.lineLabel === 'Minimum TopUp') ? '' as any : row.orderCount,
      'Invoice NET (\u00a3)': +row.invoiceNet.toFixed(2),
      'System NET (\u00a3)': (row.isTopUp && row.lineLabel === 'Minimum TopUp') ? '' as any : +row.systemTotal.toFixed(2),
      'Difference (\u00a3)': (row.isTopUp && row.lineLabel === 'Minimum TopUp') ? '' as any : +row.difference.toFixed(2),
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

    utils.book_append_sheet(wb, utils.json_to_sheet(result.rows.map(r => ({
      'Status': r.status === 'matched' ? 'Matched' : r.status === 'price_mismatch' ? 'Price Discrepancy' : 'On Invoice Only',
      'Department': r.order?.department?.name || 'Unallocated',
      'Date': r.invoiceLine.date, 'Docket': r.invoiceLine.ticket,
      'Type': ORDER_TYPE_LABELS[r.sectionType as OrderType] ?? r.sectionType,
      'Invoice Description': r.invoiceLine.description,
      'Invoice NET (\u00a3)': +r.invoiceLine.net.toFixed(2), 'Invoice VAT (\u00a3)': +r.invoiceLine.vat.toFixed(2),
      'Invoice GROSS (\u00a3)': +r.invoiceLine.gross.toFixed(2),
      'System Total (\u00a3)': r.order ? +r.systemTotal.toFixed(2) : '',
      'Difference (\u00a3)': r.order ? +r.difference.toFixed(2) : '',
      'Resolution': r.status === 'not_found' ? (notFoundResolutions[notFoundKey(r.invoiceLine)]?.type || '') : '',
      'Staff/Guest': r.order?.staff_name || r.order?.guest_name || '',
    }))), 'Detailed Items')

    if (result.topUpCharges.length > 0) {
      const topUpRows = result.topUpCharges.map(l => ({
        'Date Range': l.date, 'Description': l.description, 'Section': l.sectionType?.replace('_', ' ') || '',
        'NET (\u00a3)': +l.net.toFixed(2), 'VAT (\u00a3)': +l.vat.toFixed(2), 'GROSS (\u00a3)': +l.gross.toFixed(2),
      }))
      topUpRows.push({ 'Date Range': 'TOTAL', 'Description': '', 'Section': '',
        'NET (\u00a3)': +totalTopUp.toFixed(2), 'VAT (\u00a3)': +(totalTopUp * 0.2).toFixed(2), 'GROSS (\u00a3)': +(totalTopUp * 1.2).toFixed(2) })
      utils.book_append_sheet(wb, utils.json_to_sheet(topUpRows), 'TopUp Charges')
    }

    const discRows: Record<string, string | number>[] = []
    result.rows.filter(r => r.status === 'price_mismatch').forEach(r => discRows.push({
      'Issue': 'Price Discrepancy', 'Docket': r.invoiceLine.ticket, 'Department': r.order?.department?.name || '',
      'Invoice NET (\u00a3)': +r.invoiceLine.net.toFixed(2), 'System NET (\u00a3)': +r.systemTotal.toFixed(2),
      'Difference (\u00a3)': +r.difference.toFixed(2), 'Description': r.invoiceLine.description,
      'Recommended Action': 'Verify pricing with Goldstar / update system prices',
    }))
    result.rows.filter(r => r.status === 'not_found').forEach(r => discRows.push({
      'Issue': 'On invoice but not in system', 'Docket': r.invoiceLine.ticket, 'Department': '',
      'Invoice NET (\u00a3)': +r.invoiceLine.net.toFixed(2), 'System NET (\u00a3)': 0,
      'Difference (\u00a3)': +r.invoiceLine.net.toFixed(2), 'Description': r.invoiceLine.description,
      'Resolution': notFoundResolutions[notFoundKey(r.invoiceLine)]?.type || 'Unresolved',
      'Recommended Action': 'Add to system / accept charge / challenge with supplier',
    }))
    result.missingFromInvoice.forEach(o => discRows.push({
      'Issue': 'In system but not on invoice', 'Docket': o.docket_number, 'Department': o.department?.name || '',
      'Invoice NET (\u00a3)': 0, 'System NET (\u00a3)': +computeOrderCost(o).toFixed(2),
      'Difference (\u00a3)': +(-computeOrderCost(o)).toFixed(2),
      'Description': (o.order_items || []).map(i => `${i.quantity_sent}x ${i.item_name}`).join(', '),
      'Resolution': missingResolutions[o.id]?.type || 'Unresolved',
      'Recommended Action': 'Challenge with supplier / defer to next invoice / write off',
    }))
    if (discRows.length > 0) utils.book_append_sheet(wb, utils.json_to_sheet(discRows), 'Discrepancies & Actions')

    writeFile(wb, `accounting-report-${invoice.invoiceNumber || 'reconciliation'}-${format(new Date(), 'yyyy-MM-dd')}.xlsx`)
  }, [result, invoice, notFoundResolutions, missingResolutions])

  const statusIcon = (s: ReconciliationRow['status']) => {
    if (s === 'matched') return <CheckCircle className="w-4 h-4 text-green-500" />
    if (s === 'price_mismatch') return <AlertTriangle className="w-4 h-4 text-amber-500" />
    return <XCircle className="w-4 h-4 text-red-500" />
  }

  // Price update error banner
  const [priceUpdateError, setPriceUpdateError] = useState<string | null>(null)

  // ── Action: update prices to match invoice ──
  // Sets per-item unit price (full precision) and total_price (authoritative, 2dp).
  const handleUpdatePrice = useCallback(async (row: ReconciliationRow) => {
    if (!row.order || !invoice) return
    const orderId = row.order.id
    const docket = row.order.docket_number
    setUpdatingPrices(prev => new Set(prev).add(orderId))
    setPriceUpdateError(null)
    try {
      // Clear reconciliation_id so the order stays visible after refetch
      await supabase.from('orders').update({ reconciliation_id: null }).eq('id', orderId)

      const { data: freshItems, error: fetchErr } = await supabase
        .from('order_items').select('*').eq('order_id', orderId)
      if (fetchErr) {
        setPriceUpdateError(`Docket ${docket}: Failed to fetch order items — ${fetchErr.message}`)
        return
      }
      const items = freshItems || row.order.order_items || []
      const invoiceNet = row.invoiceLine.net

      if (items.length === 0) {
        const { error: orderErr } = await supabase.from('orders').update({ total_price: +invoiceNet.toFixed(2) }).eq('id', orderId)
        if (orderErr) {
          setPriceUpdateError(`Docket ${docket}: Failed to update order total — ${orderErr.message}`)
          return
        }
        await refetchAndReconcile()
        return
      }

      const validItems = items.filter((i: any) => (i.quantity_sent ?? 0) > 0 && i.id)
      const totalQty = validItems.reduce((s: number, i: any) => s + (i.quantity_sent ?? 0), 0)

      if (totalQty === 0) {
        setPriceUpdateError(`Docket ${docket}: All items have zero quantity — updated total price only`)
        await supabase.from('orders').update({ total_price: +invoiceNet.toFixed(2) }).eq('id', orderId)
        await refetchAndReconcile()
        return
      }

      const unitPrice = invoiceNet / totalQty
      const errors: string[] = []
      for (let idx = 0; idx < validItems.length; idx++) {
        const item = validItems[idx]
        const { error: itemErr, data: updatedRows } = await supabase.from('order_items')
          .update({ price_at_time: unitPrice }).eq('id', item.id).select('id')
        if (itemErr) errors.push(`Item "${item.item_name}": ${itemErr.message}`)
        else if (!updatedRows || updatedRows.length === 0) errors.push(`Item "${item.item_name}": update had no effect (possible RLS policy)`)
      }

      const { error: orderErr } = await supabase.from('orders').update({ total_price: +invoiceNet.toFixed(2) }).eq('id', orderId)
      if (orderErr) errors.push(`Order total: ${orderErr.message}`)

      if (errors.length > 0) {
        setPriceUpdateError(`Docket ${docket}: ${errors.join('; ')}`)
      }
      await refetchAndReconcile()
    } catch (e) {
      const msg = e instanceof Error ? e.message : 'Unknown error'
      setPriceUpdateError(`Docket ${docket}: ${msg}`)
    } finally {
      setUpdatingPrices(prev => { const next = new Set(prev); next.delete(orderId); return next })
    }
  }, [invoice, refetchAndReconcile])

  // ── Action: delete a missing order ──
  const handleDeleteOrder = useCallback(async (orderId: string) => {
    if (!window.confirm('Are you sure you want to delete this order? This cannot be undone.')) return
    if (!invoice) return
    try {
      await supabase.from('order_items').delete().eq('order_id', orderId)
      await supabase.from('orders').delete().eq('id', orderId)
      setMissingResolutions(prev => { const next = { ...prev }; delete next[orderId]; return next })
      await refetchAndReconcile()
    } catch (e) {
      console.error('Failed to delete order:', e)
    }
  }, [invoice, refetchAndReconcile])

  // ── Action: Add invoice-only item to system ──
  const handleAddToSystem = useCallback(async () => {
    if (!addModal || !invoice) return
    const { row } = addModal
    if (!addModalDept) return
    setAddModalSaving(true)
    try {
      const docket = addModalDocket.trim() || row.invoiceLine.ticket || `REC-${String(Date.now()).slice(-6)}`
      const orderType = row.sectionType as OrderType

      // Set created_at within the invoice period so re-reconciliation finds this order
      const period = parseInvoicePeriod(invoice.invoicePeriod) || derivePeriodFromLines(invoice)

      // Parse date from editable field (dd/MM/yy, dd/MM/yyyy, or yyyy-MM-dd format)
      let createdAt: string
      const lineDate = addModalDate.trim() || row.invoiceLine.date
      if (lineDate) {
        // Support yyyy-MM-dd (from date input) and dd/MM/yy (from invoice)
        const isoMatch = lineDate.match(/^(\d{4})-(\d{2})-(\d{2})$/)
        if (isoMatch) {
          createdAt = `${isoMatch[1]}-${isoMatch[2]}-${isoMatch[3]}T12:00:00.000Z`
        } else {
          const parts = lineDate.split('/')
          if (parts.length === 3) {
            const day = parts[0]
            const month = parts[1]
            let yr = parts[2]
            if (yr.length === 2) yr = `20${yr}`
            createdAt = `${yr}-${month.padStart(2, '0')}-${day.padStart(2, '0')}T12:00:00.000Z`
          } else {
            createdAt = period ? period.start.toISOString() : new Date().toISOString()
          }
        }
      } else {
        createdAt = period ? period.start.toISOString() : new Date().toISOString()
      }

      // Create order
      const { data: newOrder, error: orderErr } = await supabase.from('orders').insert({
        docket_number: docket,
        order_type: orderType,
        department_id: addModalDept,
        staff_name: row.invoiceLine.guestInfo?.replace(/[()]/g, '') || null,
        guest_name: orderType === 'guest_laundry' ? (row.invoiceLine.guestInfo?.replace(/[()]/g, '') || null) : null,
        room_number: orderType === 'guest_laundry' ? row.invoiceLine.ticket : null,
        status: 'completed',
        total_price: +row.invoiceLine.net.toFixed(2),
        notes: `Added from invoice reconciliation — ${invoice.invoiceNumber} [ref:${row.invoiceLine.ticket}|${row.invoiceLine.date}|${row.invoiceLine.net}]`,
        created_at: createdAt,
      }).select().single()

      if (orderErr) throw orderErr

      // Create order items from parsed invoice line items
      if (newOrder && row.invoiceLine.items.length > 0) {
        const totalItemQty = row.invoiceLine.items.reduce((s, it) => s + it.quantity, 0)
        const unitPrice = totalItemQty > 0 ? row.invoiceLine.net / totalItemQty : row.invoiceLine.net
        const itemInserts = row.invoiceLine.items.map((it) => ({
            order_id: newOrder.id,
            item_name: it.name,
            quantity_sent: it.quantity,
            quantity_received: it.quantity,
            price_at_time: unitPrice,
        }))
        await supabase.from('order_items').insert(itemInserts)
      } else if (newOrder) {
        // No parsed items — create a single generic item
        await supabase.from('order_items').insert({
          order_id: newOrder.id,
          item_name: row.invoiceLine.description || 'Invoice item',
          quantity_sent: 1,
          quantity_received: 1,
          price_at_time: +row.invoiceLine.net.toFixed(2),
        })
      }

      // Log status history
      if (newOrder) {
        let userName = 'Dashboard'
        const { data: { user: authUser } } = await supabase.auth.getUser()
        if (authUser) {
          const { data: du } = await supabase.from('dashboard_users').select('name, email').eq('id', authUser.id).single()
          userName = `Dashboard / ${du?.name || du?.email || 'Unknown'}`
        }
        await supabase.from('order_status_log').insert({
          order_id: newOrder.id,
          status: 'completed',
          changed_by_name: userName,
          reason: `Added from invoice reconciliation — ${invoice.invoiceNumber}`,
        })
      }

      // Mark as resolved
      const key = notFoundKey(row.invoiceLine)
      setNotFoundResolutions(prev => ({ ...prev, [key]: { type: 'added_to_system' } }))

      // Re-reconcile to pick up the new order
      await refetchAndReconcile()
      setAddModal(null)
      setAddModalDept('')
    } catch (e) {
      console.error('Failed to add to system:', e)
    } finally {
      setAddModalSaving(false)
    }
  }, [addModal, addModalDept, addModalDocket, addModalDate, invoice, refetchAndReconcile])

  // ── Action: Accept charge (acknowledge invoice-only item as valid) ──
  const handleAcceptCharge = useCallback((row: ReconciliationRow) => {
    const key = notFoundKey(row.invoiceLine)
    setNotFoundResolutions(prev => ({ ...prev, [key]: { type: 'accepted' } }))
  }, [])

  // ── Action: Challenge an item (toggle) ──
  const handleChallenge = useCallback((itemKey: string, category: 'nf' | 'miss' | 'mm') => {
    const fullKey = `${category}:${itemKey}`
    setChallengedItems(prev => {
      const next = new Set(prev)
      const isRemoving = next.has(fullKey)
      if (isRemoving) next.delete(fullKey)
      else next.add(fullKey)

      // Set or clear resolution accordingly
      if (category === 'nf') {
        if (isRemoving) {
          setNotFoundResolutions(p => { const n = { ...p }; delete n[itemKey]; return n })
        } else {
          setNotFoundResolutions(p => ({ ...p, [itemKey]: { type: 'challenged' } }))
        }
      } else if (category === 'miss') {
        if (isRemoving) {
          setMissingResolutions(p => { const n = { ...p }; delete n[itemKey]; return n })
        } else {
          setMissingResolutions(p => ({ ...p, [itemKey]: { type: 'challenged' } }))
        }
      }

      return next
    })
  }, [])

  // ── Action: Write off a missing order ──
  const handleWriteOff = useCallback((orderId: string) => {
    setMissingResolutions(prev => ({ ...prev, [orderId]: { type: 'written_off' } }))
  }, [])

  // ── Action: Defer missing order to next invoice ──
  const handleDefer = useCallback((orderId: string) => {
    setMissingResolutions(prev => ({ ...prev, [orderId]: { type: 'deferred' } }))
  }, [])

  // ── Clear a resolution ──
  const clearNotFoundResolution = useCallback((key: string) => {
    setNotFoundResolutions(prev => { const next = { ...prev }; delete next[key]; return next })
    setChallengedItems(prev => { const next = new Set(prev); next.delete(`nf:${key}`); return next })
  }, [])

  const clearMissingResolution = useCallback((orderId: string) => {
    setMissingResolutions(prev => { const next = { ...prev }; delete next[orderId]; return next })
    setChallengedItems(prev => { const next = new Set(prev); next.delete(`miss:${orderId}`); return next })
  }, [])

  // ── Generate challenge email ──
  const generateChallengeEmail = useCallback(() => {
    if (!result || !invoice) return
    const lines: string[] = []
    lines.push(`Subject: Invoice Discrepancy Query — ${invoice.invoiceNumber}`)
    lines.push('')
    lines.push(`Dear Supplier,`)
    lines.push('')
    lines.push(`We have identified the following discrepancies during reconciliation of invoice ${invoice.invoiceNumber} (Period: ${invoice.invoicePeriod}):`)
    lines.push('')

    // Challenged not-found items (on invoice but not in our system)
    const challengedNF = result.rows.filter(r => r.status === 'not_found' && challengedItems.has(`nf:${notFoundKey(r.invoiceLine)}`))
    if (challengedNF.length > 0) {
      lines.push('ITEMS BILLED BUT NOT IN OUR RECORDS:')
      for (const r of challengedNF) {
        lines.push(`  - Docket: ${r.invoiceLine.ticket} | Date: ${r.invoiceLine.date} | Amount: £${r.invoiceLine.net.toFixed(2)} | ${r.invoiceLine.description}`)
      }
      lines.push('')
    }

    // Challenged missing items (in our system but not on invoice)
    const challengedMiss = result.missingFromInvoice.filter(o => challengedItems.has(`miss:${o.id}`))
    if (challengedMiss.length > 0) {
      lines.push('ITEMS IN OUR RECORDS BUT NOT ON INVOICE:')
      for (const o of challengedMiss) {
        const items = (o.order_items || []).map(i => `${i.quantity_sent}x ${i.item_name}`).join(', ')
        lines.push(`  - Docket: ${o.docket_number} | Dept: ${o.department?.name || 'N/A'} | Amount: £${computeOrderCost(o).toFixed(2)} | ${items}`)
      }
      lines.push('')
    }

    // Challenged price mismatches
    const challengedMM = result.rows.filter(r => r.status === 'price_mismatch' && challengedItems.has(`mm:${notFoundKey(r.invoiceLine)}`))
    if (challengedMM.length > 0) {
      lines.push('PRICE DISCREPANCIES:')
      for (const r of challengedMM) {
        lines.push(`  - Docket: ${r.invoiceLine.ticket} | Invoice: £${r.invoiceLine.net.toFixed(2)} | Our records: £${r.systemTotal.toFixed(2)} | Diff: £${r.difference.toFixed(2)}`)
      }
      lines.push('')
    }

    lines.push('Could you please investigate and advise?')
    lines.push('')
    lines.push('Kind regards,')
    lines.push('The Stratford — Laundry Team')

    const body = encodeURIComponent(lines.slice(1).join('\n'))
    const subject = encodeURIComponent(`Invoice Discrepancy Query — ${invoice.invoiceNumber}`)
    const mailto = `mailto:${challengeEmail}?subject=${subject}&body=${body}`
    window.open(mailto, '_blank')
  }, [result, invoice, challengedItems, challengeEmail])

  // ── PDF Report ──
  const handlePdfReport = useCallback(() => {
    if (!result || !invoice) return
    const uniformMinWeeksForPdf = uniformMinSummary?.weeks.map(w => ({
      dateRange: w.dateRange,
      items: uniformMinSummary.ITEM_KEYS.map(k => ({
        key: k.charAt(0).toUpperCase() + k.slice(1),
        sent: w.invoiceSent[k], topUp: w.topUp[k], min: uniformMinSummary.MINIMUMS[k],
      })),
      topUpNet: w.topUpNet,
    }))
    downloadReconciliationPdf(invoice, result, departmentDisplayRows, napkinSummary?.deptTotals, uniformMinWeeksForPdf)
  }, [result, invoice, departmentDisplayRows, napkinSummary, uniformMinSummary])

  // ── Resolution badge helper ──
  function resolutionBadge(type: ResolutionType) {
    switch (type) {
      case 'accepted': return <span className="inline-flex px-1.5 py-0.5 rounded text-[10px] font-medium bg-green-100 text-green-700">Accepted</span>
      case 'challenged': return <span className="inline-flex px-1.5 py-0.5 rounded text-[10px] font-medium bg-orange-100 text-orange-700">Challenged</span>
      case 'added_to_system': return <span className="inline-flex px-1.5 py-0.5 rounded text-[10px] font-medium bg-blue-100 text-blue-700">Added</span>
      case 'written_off': return <span className="inline-flex px-1.5 py-0.5 rounded text-[10px] font-medium bg-gray-200 text-gray-600">Written Off</span>
      case 'deferred': return <span className="inline-flex px-1.5 py-0.5 rounded text-[10px] font-medium bg-purple-100 text-purple-700">Deferred</span>
    }
  }

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
  const originalDiff = +(result.invoiceTotal - result.systemTotal).toFixed(2)

  return (
    <div className="space-y-6 pb-20">
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
        {parsedPeriod ? (
          <div><span className="text-gray-500">Date range:</span> <span className="font-medium text-navy">{format(parsedPeriod.start, 'dd MMM yyyy')} — {format(parsedPeriod.end, 'dd MMM yyyy')}</span></div>
        ) : (
          <div><span className="text-gray-500">Date range:</span> <span className="font-medium text-red-600">Could not parse period "{invoice.invoicePeriod}"</span></div>
        )}
        <div><span className="text-gray-500">Sections:</span> <span className="font-medium">{invoice.sections.map(s => s.name).join(', ')}</span></div>
        <div><span className="text-gray-500">Lines:</span> <span className="font-medium">{invoice.sections.reduce((s, sec) => s + sec.lines.length, 0)}</span></div>
        <div><span className="text-gray-500">System orders:</span> <span className="font-medium">{orders.length}</span></div>
        {/* Issue 1: Broader search toggle */}
        <div className="flex items-center gap-2 ml-auto">
          <Search className="w-3.5 h-3.5 text-gray-400" />
          <span className="text-xs text-gray-500">Broader search (-1 month)</span>
          <button
            onClick={() => setBroaderSearch(prev => !prev)}
            className={`relative w-9 h-5 rounded-full transition-colors ${broaderSearch ? 'bg-navy' : 'bg-gray-300'}`}
          >
            <span className={`absolute top-0.5 left-0.5 w-4 h-4 bg-white rounded-full transition-transform ${broaderSearch ? 'translate-x-4' : ''}`} />
          </button>
        </div>
      </div>

      {/* Issue 4: Warning if this invoice was already reconciled */}
      {history.some(h => h.invoice_number === invoice.invoiceNumber) && (
        <div className="bg-blue-50 border border-blue-200 rounded-lg p-3 flex items-center gap-3">
          <AlertTriangle className="w-5 h-5 text-blue-500 flex-shrink-0" />
          <p className="text-sm text-blue-800">
            This invoice (<span className="font-medium">{invoice.invoiceNumber}</span>) was previously reconciled on{' '}
            <span className="font-medium">{format(new Date(history.find(h => h.invoice_number === invoice.invoiceNumber)!.created_at), 'dd MMM yyyy')}</span>.
            Previously matched orders are excluded from this reconciliation.
          </p>
        </div>
      )}

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
        <StatCard icon={<AlertTriangle className="w-5 h-5 text-amber-500" />} label="Price Discrepancy" value={result.stats.priceMismatch} color="amber" />
        <StatCard icon={<XCircle className="w-5 h-5 text-red-500" />} label="On Invoice Only" value={result.stats.notFound} color="red"
          subtitle={Object.keys(notFoundResolutions).length > 0 ? `${Object.keys(notFoundResolutions).length} resolved` : undefined} />
        <StatCard icon={<HelpCircle className="w-5 h-5 text-blue-500" />} label="In System Only" value={result.stats.missing} color="blue"
          subtitle={Object.keys(missingResolutions).length > 0 ? `${Object.keys(missingResolutions).length} resolved` : undefined} />
        <div className="bg-white rounded-xl border border-gray-200 p-4">
          <p className="text-xs text-gray-500 mb-1">Unresolved</p>
          <p className={`text-xl font-bold ${Math.abs(adjustedTotals.unresolvedDiff) < 0.02 ? 'text-green-600' : 'text-amber-600'}`}>
            {'\u00a3'}{Math.abs(adjustedTotals.unresolvedDiff).toFixed(2)}
          </p>
          {adjustedTotals.resolvedCount > 0 && (
            <p className="text-[10px] text-gray-400 mt-0.5">
              was {'\u00a3'}{Math.abs(originalDiff).toFixed(2)} — {adjustedTotals.resolvedCount} resolved
            </p>
          )}
        </div>
      </div>

      {/* Department Breakdown */}
      <div className="bg-white rounded-xl border border-gray-200 overflow-hidden">
        <div className="px-5 py-3 border-b border-gray-200 flex items-center gap-2 cursor-pointer select-none" onClick={() => setDeptBreakdownOpen(v => !v)}>
          <ChevronRight className={`w-4 h-4 text-gray-500 transition-transform ${deptBreakdownOpen ? 'rotate-90' : ''}`} />
          <h3 className="text-sm font-semibold text-gray-900">Department Breakdown</h3>
          {totalTopUp > 0 && <span className="text-xs text-gray-400 ml-2">(TopUp allocated by service type)</span>}
        </div>
        {deptBreakdownOpen && <div className="overflow-x-auto">
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
                <td className="px-4 py-2.5 text-right">{row.isTopUp && row.lineLabel === 'Minimum TopUp' ? '\u2014' : row.orderCount}</td>
                <td className="px-4 py-2.5 text-right">{'\u00a3'}{row.invoiceNet.toFixed(2)}</td>
                <td className="px-4 py-2.5 text-right">{row.isTopUp && row.lineLabel === 'Minimum TopUp' ? '\u2014' : `\u00a3${row.systemTotal.toFixed(2)}`}</td>
                <td className={`px-4 py-2.5 text-right font-medium ${row.isTopUp && row.lineLabel === 'Minimum TopUp' ? 'text-gray-400' : Math.abs(row.difference) < 0.02 ? 'text-green-600' : 'text-amber-600'}`}>
                  {row.isTopUp && row.lineLabel === 'Minimum TopUp' ? '\u2014' : Math.abs(row.difference) < 0.02 ? '\u2713' : `\u00a3${row.difference.toFixed(2)}`}
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
        </div>}
      </div>

      {/* Napkin Usage Summary */}
      {napkinSummary && (
        <div className="bg-white rounded-xl border border-gray-200 overflow-hidden">
          <div className="px-5 py-3 border-b border-gray-200 flex items-center justify-between">
            <div className="flex items-center gap-2">
              <ChevronRight className="w-4 h-4 text-gray-500" />
              <h3 className="text-sm font-semibold text-gray-900">Napkin Usage Summary</h3>
            </div>
            <span className="text-xs text-gray-500">Weekly minimum: {napkinSummary.weeklyMinimum.toLocaleString()} @ {'\u00a3'}{napkinSummary.unitRate.toFixed(3)}/ea = {'\u00a3'}{napkinSummary.weeklyMinCost.toFixed(2)}/week</span>
          </div>
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead><tr className="border-b border-gray-200 bg-gray-50">
                <th className="px-3 py-2.5 text-left font-medium text-gray-600">Week</th>
                <th className="px-3 py-2.5 text-right font-medium text-gray-600">Dockets</th>
                <th className="px-3 py-2.5 text-right font-medium text-gray-600">Invoice Sent</th>
                <th className="px-3 py-2.5 text-right font-medium text-gray-600">System Sent</th>
                <th className="px-3 py-2.5 text-right font-medium text-gray-600">Sent Diff</th>
                <th className="px-3 py-2.5 text-right font-medium text-gray-600">TopUp</th>
                <th className="px-3 py-2.5 text-right font-medium text-gray-600">Total Charged</th>
                <th className="px-3 py-2.5 text-right font-medium text-gray-600">Total NET</th>
                {napkinSummary.hasLedgerData && <th className="px-3 py-2.5 text-right font-medium text-gray-600">Received</th>}
                {napkinSummary.hasLedgerData && <th className="px-3 py-2.5 text-right font-medium text-gray-600">Shrinkage</th>}
                <th className="px-3 py-2.5 text-right font-medium text-gray-600">Min Used</th>
              </tr></thead>
              <tbody>
                {napkinSummary.weeks.map((w, i) => {
                  const sentDiff = w.systemSentQty - w.invoiceSentQty
                  const hasTopUp = w.topUpQty > 0
                  const minUsedPct = hasTopUp ? Math.round(w.invoiceSentQty / napkinSummary.weeklyMinimum * 100) : null
                  const shrinkage = napkinSummary.hasLedgerData && w.poolReceivedQty > 0 ? w.invoiceSentQty - w.poolReceivedQty : null
                  return (
                    <tr key={i} className={`border-b border-gray-100 ${hasTopUp && minUsedPct != null && minUsedPct < 80 ? 'bg-red-50/30' : hasTopUp ? 'bg-amber-50/30' : ''}`}>
                      <td className="px-3 py-2 font-medium text-gray-700 whitespace-nowrap">{w.dateRange}</td>
                      <td className="px-3 py-2 text-right text-gray-500">{w.invoiceItems}</td>
                      <td className="px-3 py-2 text-right">{w.invoiceSentQty.toLocaleString()}</td>
                      <td className="px-3 py-2 text-right font-medium">{w.systemSentQty > 0 ? w.systemSentQty.toLocaleString() : <span className="text-gray-300">-</span>}</td>
                      <td className={`px-3 py-2 text-right font-medium ${w.systemSentQty === 0 ? 'text-gray-300' : sentDiff > 0 ? 'text-red-600' : sentDiff < 0 ? 'text-amber-600' : 'text-green-600'}`}>
                        {w.systemSentQty === 0 ? '-' : `${sentDiff > 0 ? '+' : ''}${sentDiff.toLocaleString()}`}
                      </td>
                      <td className={`px-3 py-2 text-right ${hasTopUp ? 'text-amber-600 font-medium' : 'text-gray-300'}`}>
                        {hasTopUp ? w.topUpQty.toLocaleString() : '-'}
                      </td>
                      <td className="px-3 py-2 text-right font-medium">{w.totalChargedQty.toLocaleString()}</td>
                      <td className="px-3 py-2 text-right">{'\u00a3'}{w.totalNet.toFixed(2)}</td>
                      {napkinSummary.hasLedgerData && (
                        <td className="px-3 py-2 text-right">{w.poolReceivedQty > 0 ? w.poolReceivedQty.toLocaleString() : <span className="text-gray-300">-</span>}</td>
                      )}
                      {napkinSummary.hasLedgerData && (
                        <td className={`px-3 py-2 text-right font-medium ${shrinkage != null && shrinkage > 0 ? 'text-red-600' : 'text-gray-300'}`}>
                          {shrinkage != null && shrinkage > 0 ? shrinkage.toLocaleString() : '-'}
                        </td>
                      )}
                      <td className="px-3 py-2 text-right">
                        {minUsedPct != null ? (
                          <span className={minUsedPct < 60 ? 'text-red-600 font-bold' : minUsedPct < 80 ? 'text-red-600 font-medium' : minUsedPct < 100 ? 'text-amber-600' : 'text-green-600'}>
                            {minUsedPct}%
                          </span>
                        ) : <span className="text-gray-400">{'\u2014'}</span>}
                      </td>
                    </tr>
                  )
                })}
              </tbody>
              <tfoot>
                <tr className="bg-gray-50 font-semibold border-t-2 border-gray-300">
                  <td className="px-3 py-3">Total</td>
                  <td className="px-3 py-3 text-right text-gray-500">{napkinSummary.weeks.reduce((s, w) => s + w.invoiceItems, 0)}</td>
                  <td className="px-3 py-3 text-right">{napkinSummary.totalInvoiceSent.toLocaleString()}</td>
                  <td className="px-3 py-3 text-right">{napkinSummary.totalSystemSent > 0 ? napkinSummary.totalSystemSent.toLocaleString() : '-'}</td>
                  <td className={`px-3 py-3 text-right ${napkinSummary.totalSystemSent === 0 ? '' : napkinSummary.totalSystemSent - napkinSummary.totalInvoiceSent > 0 ? 'text-red-600' : 'text-amber-600'}`}>
                    {napkinSummary.totalSystemSent > 0 ? (napkinSummary.totalSystemSent - napkinSummary.totalInvoiceSent).toLocaleString() : '-'}
                  </td>
                  <td className="px-3 py-3 text-right text-amber-600">{napkinSummary.totalTopUp.toLocaleString()}</td>
                  <td className="px-3 py-3 text-right">{napkinSummary.totalCharged.toLocaleString()}</td>
                  <td className="px-3 py-3 text-right">{'\u00a3'}{napkinSummary.totalNet.toFixed(2)}</td>
                  {napkinSummary.hasLedgerData && <td className="px-3 py-3 text-right">{napkinSummary.totalReceived > 0 ? napkinSummary.totalReceived.toLocaleString() : '-'}</td>}
                  {napkinSummary.hasLedgerData && <td className="px-3 py-3 text-right text-red-600">{napkinSummary.totalReceived > 0 ? (napkinSummary.totalInvoiceSent - napkinSummary.totalReceived).toLocaleString() : '-'}</td>}
                  <td className="px-3 py-3" />
                </tr>
              </tfoot>
            </table>
          </div>
          {/* Summary footer */}
          <div className="px-5 py-3 bg-gray-50 border-t border-gray-200 text-xs text-gray-600 space-y-1">
            <div>Weekly minimum: {napkinSummary.weeklyMinimum.toLocaleString()} napkins @ {'\u00a3'}{napkinSummary.unitRate.toFixed(3)}/each = {'\u00a3'}{napkinSummary.weeklyMinCost.toFixed(2)}/week</div>
            {napkinSummary.totalTopUp > 0 && (
              <div className="text-amber-700 font-medium">
                TopUp waste: {napkinSummary.totalTopUp.toLocaleString()} napkins paid but not sent ({'\u00a3'}{napkinSummary.totalTopUpCost.toFixed(2)})
              </div>
            )}
            {napkinSummary.totalSystemSent === 0 && (
              <div className="text-gray-400 italic">No system order data for this period — docket tracking may not have been active yet</div>
            )}
            {!napkinSummary.hasLedgerData && (
              <div className="text-gray-400 italic">No linen pool data for this period — pool tracking may not have been active yet</div>
            )}
          </div>
          {/* Department Cost Allocation */}
          {napkinSummary.deptTotals.length > 0 && (
            <div className="border-t border-gray-200">
              <div className="px-5 py-3 border-b border-gray-100 flex items-center gap-2">
                <Scale className="w-4 h-4 text-gray-400" />
                <h4 className="text-sm font-semibold text-gray-800">Napkin Minimum — Department Cost Allocation</h4>
              </div>
              <div className="overflow-x-auto">
                <table className="w-full text-sm">
                  <thead><tr className="border-b border-gray-200 bg-gray-50">
                    <th className="px-4 py-2 text-left font-medium text-gray-600">Department</th>
                    <th className="px-4 py-2 text-right font-medium text-gray-600">Napkins Sent</th>
                    <th className="px-4 py-2 text-right font-medium text-gray-600">% Share</th>
                    <th className="px-4 py-2 text-right font-medium text-gray-600">Actual Cost</th>
                    <th className="px-4 py-2 text-right font-medium text-gray-600">TopUp Allocated</th>
                    <th className="px-4 py-2 text-right font-medium text-gray-600">Total Cost</th>
                    <th className="px-4 py-2 text-right font-medium text-gray-600">Total inc VAT</th>
                  </tr></thead>
                  <tbody>
                    {napkinSummary.deptTotals.map((d, i) => (
                      <tr key={i} className="border-b border-gray-100">
                        <td className="px-4 py-2 font-medium text-gray-700">{d.deptName}</td>
                        <td className="px-4 py-2 text-right">{d.totalSent.toLocaleString()}</td>
                        <td className="px-4 py-2 text-right">{d.pctShare.toFixed(1)}%</td>
                        <td className="px-4 py-2 text-right">{'\u00a3'}{d.totalActualCost.toFixed(2)}</td>
                        <td className="px-4 py-2 text-right text-amber-600">{'\u00a3'}{d.totalTopUpAlloc.toFixed(2)}</td>
                        <td className="px-4 py-2 text-right font-semibold">{'\u00a3'}{d.totalCost.toFixed(2)}</td>
                        <td className="px-4 py-2 text-right font-semibold">{'\u00a3'}{(d.totalCost * 1.2).toFixed(2)}</td>
                      </tr>
                    ))}
                  </tbody>
                  <tfoot><tr className="bg-gray-50 font-semibold border-t-2 border-gray-300">
                    <td className="px-4 py-2.5">Total</td>
                    <td className="px-4 py-2.5 text-right">{napkinSummary.deptTotals.reduce((s, d) => s + d.totalSent, 0).toLocaleString()}</td>
                    <td className="px-4 py-2.5 text-right">100%</td>
                    <td className="px-4 py-2.5 text-right">{'\u00a3'}{napkinSummary.deptTotals.reduce((s, d) => s + d.totalActualCost, 0).toFixed(2)}</td>
                    <td className="px-4 py-2.5 text-right text-amber-600">{'\u00a3'}{napkinSummary.deptTotals.reduce((s, d) => s + d.totalTopUpAlloc, 0).toFixed(2)}</td>
                    <td className="px-4 py-2.5 text-right">{'\u00a3'}{napkinSummary.deptTotals.reduce((s, d) => s + d.totalCost, 0).toFixed(2)}</td>
                    <td className="px-4 py-2.5 text-right">{'\u00a3'}{(napkinSummary.deptTotals.reduce((s, d) => s + d.totalCost, 0) * 1.2).toFixed(2)}</td>
                  </tr></tfoot>
                </table>
              </div>
            </div>
          )}
        </div>
      )}

      {/* Chef Uniform Minimum Usage */}
      {uniformMinSummary && (
        <div className="bg-white rounded-xl border border-gray-200 overflow-hidden">
          <div className="px-5 py-3 border-b border-gray-200 flex items-center justify-between cursor-pointer select-none" onClick={() => setUniformMinOpen(v => !v)}>
            <div className="flex items-center gap-2">
              <ChevronRight className={`w-4 h-4 text-gray-500 transition-transform ${uniformMinOpen ? 'rotate-90' : ''}`} />
              <h3 className="text-sm font-semibold text-gray-900">Chef Uniform Minimum Usage — Main Kitchen</h3>
            </div>
            <span className="text-xs text-gray-500">
              Weekly min: Jacket {uniformMinSummary.MINIMUMS['chef jacket']} | Apron {uniformMinSummary.MINIMUMS['apron']} | Trouser {uniformMinSummary.MINIMUMS['chef trouser']}
            </span>
          </div>
          {uniformMinOpen && <><div className="overflow-x-auto">
            <table className="w-full text-xs">
              <thead><tr className="border-b border-gray-200 bg-gray-50">
                <th className="px-3 py-2 text-left font-medium text-gray-600" rowSpan={2}>Week</th>
                <th className="px-3 py-2 text-center font-medium text-gray-600 border-l border-gray-200" colSpan={3}>Chef Jacket (min {uniformMinSummary.MINIMUMS['chef jacket']})</th>
                <th className="px-3 py-2 text-center font-medium text-gray-600 border-l border-gray-200" colSpan={3}>Apron (min {uniformMinSummary.MINIMUMS['apron']})</th>
                <th className="px-3 py-2 text-center font-medium text-gray-600 border-l border-gray-200" colSpan={3}>Chef Trouser (min {uniformMinSummary.MINIMUMS['chef trouser']})</th>
                <th className="px-3 py-2 text-right font-medium text-gray-600 border-l border-gray-200" rowSpan={2}>TopUp NET</th>
              </tr><tr className="border-b border-gray-200 bg-gray-50">
                {uniformMinSummary.ITEM_KEYS.map(k => (
                  <><th key={`${k}-s`} className="px-2 py-1 text-right font-medium text-gray-500 border-l border-gray-200">Sent</th>
                  <th key={`${k}-t`} className="px-2 py-1 text-right font-medium text-gray-500">TopUp</th>
                  <th key={`${k}-p`} className="px-2 py-1 text-right font-medium text-gray-500">Used%</th></>
                ))}
              </tr></thead>
              <tbody>
                {uniformMinSummary.weeks.map((w, i) => (
                  <tr key={i} className="border-b border-gray-100">
                    <td className="px-3 py-2 font-medium text-gray-700 whitespace-nowrap">{w.dateRange}</td>
                    {uniformMinSummary.ITEM_KEYS.map(k => {
                      const sent = w.invoiceSent[k]
                      const min = uniformMinSummary.MINIMUMS[k]
                      const pct = Math.round(sent / min * 100)
                      return (
                        <><td key={`${k}-s-${i}`} className="px-2 py-2 text-right border-l border-gray-200">{sent}</td>
                        <td key={`${k}-t-${i}`} className={`px-2 py-2 text-right ${w.topUp[k] > 0 ? 'text-amber-600 font-medium' : 'text-gray-300'}`}>
                          {w.topUp[k] > 0 ? w.topUp[k] : '-'}
                        </td>
                        <td key={`${k}-p-${i}`} className={`px-2 py-2 text-right font-medium ${pct < 60 ? 'text-red-600' : pct < 80 ? 'text-amber-600' : pct >= 100 ? 'text-green-600' : 'text-amber-500'}`}>
                          {pct}%
                        </td></>
                      )
                    })}
                    <td className="px-3 py-2 text-right border-l border-gray-200 font-medium">{'\u00a3'}{w.topUpNet.toFixed(2)}</td>
                  </tr>
                ))}
              </tbody>
              <tfoot><tr className="bg-gray-50 font-semibold border-t-2 border-gray-300">
                <td className="px-3 py-2.5">Total ({uniformMinSummary.weekCount} weeks)</td>
                {uniformMinSummary.ITEM_KEYS.map(k => (
                  <><td key={`${k}-ts`} className="px-2 py-2.5 text-right border-l border-gray-200">{uniformMinSummary.totalInvoiceSent[k]}</td>
                  <td key={`${k}-tt`} className="px-2 py-2.5 text-right text-amber-600">{uniformMinSummary.totalTopUp[k]}</td>
                  <td key={`${k}-tp`} className="px-2 py-2.5 text-right">
                    {Math.round(uniformMinSummary.totalInvoiceSent[k] / (uniformMinSummary.MINIMUMS[k] * uniformMinSummary.weekCount) * 100)}%
                  </td></>
                ))}
                <td className="px-3 py-2.5 text-right border-l border-gray-200">{'\u00a3'}{uniformMinSummary.totalTopUpNet.toFixed(2)}</td>
              </tr></tfoot>
            </table>
          </div>
          <div className="px-5 py-3 bg-gray-50 border-t border-gray-200 text-xs text-gray-600 space-y-1">
            <div className="flex flex-wrap gap-4">
              {uniformMinSummary.ITEM_KEYS.map(k => (
                <span key={k} className={uniformMinSummary.unusedCapacity[k] > 0 ? 'text-amber-700 font-medium' : 'text-green-600'}>
                  {k.charAt(0).toUpperCase() + k.slice(1)}: {uniformMinSummary.unusedCapacity[k]} unused ({'\u00a3'}{(uniformMinSummary.unusedCapacity[k] * uniformMinSummary.PRICES[k]).toFixed(2)} waste)
                </span>
              ))}
            </div>
            <div className="text-amber-700 font-medium">
              Total unused capacity cost: {'\u00a3'}{uniformMinSummary.unusedCost.toFixed(2)}
            </div>
          </div>
          </>}
        </div>
      )}

      {/* Price update error */}
      {priceUpdateError && (
        <div className="bg-red-50 border border-red-200 rounded-lg p-3 flex items-start gap-3">
          <XCircle className="w-5 h-5 text-red-500 flex-shrink-0 mt-0.5" />
          <div className="flex-1 text-sm text-red-800">{priceUpdateError}</div>
          <button onClick={() => setPriceUpdateError(null)} className="p-1 rounded hover:bg-red-100">
            <X className="w-4 h-4 text-red-400" />
          </button>
        </div>
      )}

      {/* Filter tabs */}
      <div className="flex gap-1.5 bg-gray-100 rounded-lg p-1 w-fit">
        {([['all', 'All', result.rows.length], ['matched', 'Matched', result.stats.matched],
          ['mismatch', 'Price Discrepancy', result.stats.priceMismatch], ['not_found', 'On Invoice Only', result.stats.notFound],
          ['missing', 'In System Only', result.stats.missing]] as [FilterTab, string, number][]).map(([key, label, count]) => (
          <button key={key} onClick={() => setFilter(key)}
            className={`px-3 py-1.5 text-xs font-medium rounded-md transition-colors ${filter === key ? 'bg-white text-navy shadow-sm' : 'text-gray-600 hover:text-gray-900'}`}
          >{label} ({count})</button>
        ))}
      </div>

      {/* Detail table — all tabs except missing */}
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
                : filteredRows.map((row, i) => {
                const nfKey = notFoundKey(row.invoiceLine)
                const nfRes = row.status === 'not_found' ? notFoundResolutions[nfKey] : undefined
                const isChallenged = row.status === 'not_found'
                  ? challengedItems.has(`nf:${nfKey}`)
                  : row.status === 'price_mismatch'
                    ? challengedItems.has(`mm:${nfKey}`)
                    : false
                return (
                <tr key={i} className={`border-b border-gray-100 ${
                  nfRes?.type === 'accepted' ? 'bg-green-50/40' :
                  nfRes?.type === 'added_to_system' ? 'bg-blue-50/40' :
                  isChallenged ? 'bg-orange-50/40' :
                  row.status === 'price_mismatch' ? 'bg-amber-50/50' :
                  row.status === 'not_found' ? 'bg-red-50/50' : ''
                }`}>
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
                    {/* Matched — no action needed */}
                    {row.status === 'matched' && <CheckCircle className="w-4 h-4 text-green-500 mx-auto" />}

                    {/* Price Mismatch — Update Price + Challenge */}
                    {row.status === 'price_mismatch' && row.order && (
                      <div className="flex items-center gap-1 justify-center">
                        <button
                          onClick={() => handleUpdatePrice(row)}
                          disabled={updatingPrices.has(row.order!.id)}
                          className="px-2 py-1 text-xs font-medium text-white bg-amber-500 rounded hover:bg-amber-600 disabled:opacity-50 whitespace-nowrap"
                        >
                          {updatingPrices.has(row.order!.id) ? (
                            <RefreshCw className="w-3 h-3 animate-spin inline" />
                          ) : 'Update Price'}
                        </button>
                        <button
                          onClick={() => handleChallenge(nfKey, 'mm')}
                          className={`p-1 rounded hover:bg-orange-100 ${isChallenged ? 'text-orange-600 bg-orange-100' : 'text-gray-400'}`}
                          title="Challenge this discrepancy"
                        >
                          <Mail className="w-3.5 h-3.5" />
                        </button>
                      </div>
                    )}

                    {/* Not Found — Add to System / Accept / Challenge */}
                    {row.status === 'not_found' && !nfRes && (
                      <div className="flex items-center gap-1 justify-center">
                        <button
                          onClick={() => {
                            setAddModal({ row, index: i }); setAddModalDept('')
                            setAddModalDocket(row.invoiceLine.ticket || `REC-${String(Date.now()).slice(-6)}`)
                            // Auto-populate date from invoice line, or fall back to invoice period start
                            const ld = row.invoiceLine.date
                            if (ld) {
                              setAddModalDate(ld)
                            } else if (parsedPeriod) {
                              setAddModalDate(format(parsedPeriod.start, 'yyyy-MM-dd'))
                            } else {
                              setAddModalDate('')
                            }
                          }}
                          className="px-2 py-1 text-xs font-medium text-white bg-blue-500 rounded hover:bg-blue-600 whitespace-nowrap"
                          title="Add this item to our system"
                        >
                          <Plus className="w-3 h-3 inline mr-0.5" />Add
                        </button>
                        <button
                          onClick={() => handleAcceptCharge(row)}
                          className="px-2 py-1 text-xs font-medium text-green-700 bg-green-100 rounded hover:bg-green-200 whitespace-nowrap"
                          title="Accept this charge as valid"
                        >
                          Accept
                        </button>
                        <button
                          onClick={() => handleChallenge(nfKey, 'nf')}
                          className={`p-1 rounded hover:bg-orange-100 ${isChallenged ? 'text-orange-600 bg-orange-100' : 'text-gray-400'}`}
                          title="Challenge this item with supplier"
                        >
                          <Mail className="w-3.5 h-3.5" />
                        </button>
                      </div>
                    )}
                    {/* Not Found — already resolved */}
                    {row.status === 'not_found' && nfRes && (
                      <div className="flex items-center gap-1 justify-center">
                        {resolutionBadge(nfRes.type)}
                        <button onClick={() => clearNotFoundResolution(nfKey)} className="p-0.5 rounded hover:bg-gray-200 text-gray-400" title="Undo">
                          <X className="w-3 h-3" />
                        </button>
                      </div>
                    )}
                  </td>
                </tr>
              )})}
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
        /* ── In System Only (Missing from Invoice) ── */
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
                const isChallenged = challengedItems.has(`miss:${o.id}`)
                return (
                <tr key={o.id} className={`border-b border-gray-100 ${
                  resolution?.type === 'written_off' ? 'bg-gray-50/60 opacity-60' :
                  resolution?.type === 'deferred' ? 'bg-purple-50/40' :
                  isChallenged ? 'bg-orange-50/40' :
                  'bg-blue-50/30'
                }`}>
                  <td className="px-3 py-2.5 font-mono font-medium text-navy">{o.docket_number}</td>
                  <td className="px-3 py-2.5 text-gray-600">{o.department?.name || '\u2014'}</td>
                  <td className="px-3 py-2.5 text-gray-600">{ORDER_TYPE_LABELS[o.order_type as OrderType] ?? o.order_type}</td>
                  <td className="px-3 py-2.5 text-gray-900">{o.staff_name || o.guest_name || '\u2014'}</td>
                  <td className="px-3 py-2.5 text-gray-600 max-w-[250px] truncate">{(o.order_items || []).map(i => `${i.quantity_sent}x ${i.item_name}`).join(', ') || '\u2014'}</td>
                  <td className="px-3 py-2.5 text-right font-medium">{'\u00a3'}{computeOrderCost(o).toFixed(2)}</td>
                  <td className="px-3 py-2.5 text-gray-500 whitespace-nowrap">{format(new Date(o.created_at), 'dd/MM/yyyy')}</td>
                  <td className="px-3 py-2.5 text-center">
                    {!resolution ? (
                      <div className="flex items-center gap-1 justify-center flex-wrap">
                        <button
                          onClick={() => handleChallenge(o.id, 'miss')}
                          className={`px-2 py-1 text-xs font-medium rounded whitespace-nowrap ${isChallenged ? 'text-orange-700 bg-orange-100' : 'text-orange-600 bg-orange-50 hover:bg-orange-100'}`}
                          title="Challenge with supplier — why isn't this on the invoice?"
                        >
                          <Mail className="w-3 h-3 inline mr-0.5" />Challenge
                        </button>
                        <button
                          onClick={() => handleDefer(o.id)}
                          className="px-2 py-1 text-xs font-medium text-purple-700 bg-purple-50 rounded hover:bg-purple-100 whitespace-nowrap"
                          title="Expected on next invoice"
                        >
                          <ArrowRightLeft className="w-3 h-3 inline mr-0.5" />Defer
                        </button>
                        <button
                          onClick={() => handleWriteOff(o.id)}
                          className="px-2 py-1 text-xs font-medium text-gray-600 bg-gray-100 rounded hover:bg-gray-200 whitespace-nowrap"
                          title="Write off — won't be billed"
                        >
                          <Ban className="w-3 h-3 inline mr-0.5" />Write Off
                        </button>
                        <button
                          onClick={() => handleDeleteOrder(o.id)}
                          className="px-2 py-1 text-xs font-medium text-red-600 bg-red-50 rounded hover:bg-red-100 whitespace-nowrap"
                          title="Delete order from system permanently"
                        >
                          <X className="w-3 h-3 inline mr-0.5" />Delete
                        </button>
                      </div>
                    ) : (
                      <div className="flex items-center gap-1 justify-center">
                        {resolutionBadge(resolution.type)}
                        <button onClick={() => clearMissingResolution(o.id)} className="p-0.5 rounded hover:bg-gray-200 text-gray-400" title="Undo">
                          <X className="w-3 h-3" />
                        </button>
                      </div>
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
        <div className="grid grid-cols-2 sm:grid-cols-5 gap-6">
          <div><p className="text-xs text-gray-500 mb-1">Invoice Total (NET)</p>
            <p className="text-lg font-bold text-gray-900">{'\u00a3'}{invoice.totals.net > 0 ? invoice.totals.net.toFixed(2) : grandInvoiceNet.toFixed(2)}</p></div>
          <div><p className="text-xs text-gray-500 mb-1">Invoice Total (GROSS)</p>
            <p className="text-lg font-bold text-gray-900">{'\u00a3'}{invoice.totals.gross > 0 ? invoice.totals.gross.toFixed(2) : (grandInvoiceNet * 1.2).toFixed(2)}</p></div>
          <div><p className="text-xs text-gray-500 mb-1">System Total (NET)</p>
            <p className="text-lg font-bold text-gray-900">{'\u00a3'}{result.systemTotal.toFixed(2)}</p></div>
          <div><p className="text-xs text-gray-500 mb-1">Original Difference</p>
            <p className={`text-lg font-bold ${Math.abs(originalDiff) < 0.02 ? 'text-green-600' : 'text-gray-400 line-through'}`}>
              {'\u00a3'}{originalDiff.toFixed(2)}</p>
            {totalTopUp > 0 && <p className="text-xs text-gray-500 mt-0.5">+ {'\u00a3'}{totalTopUp.toFixed(2)} TopUp</p>}
          </div>
          <div className="bg-navy/5 rounded-lg p-3 -m-1">
            <p className="text-xs text-navy font-medium mb-1">Unresolved Difference</p>
            <p className={`text-xl font-bold ${Math.abs(adjustedTotals.unresolvedDiff) < 0.02 ? 'text-green-600' : 'text-amber-600'}`}>
              {'\u00a3'}{adjustedTotals.unresolvedDiff.toFixed(2)}</p>
            {adjustedTotals.resolvedCount > 0 && (
              <p className="text-[10px] text-gray-500 mt-0.5">
                {adjustedTotals.acceptedTotal > 0 && `Accepted: \u00a3${adjustedTotals.acceptedTotal.toFixed(2)}`}
                {adjustedTotals.acceptedTotal > 0 && adjustedTotals.writtenOffTotal > 0 && ' | '}
                {adjustedTotals.writtenOffTotal > 0 && `Written off: \u00a3${adjustedTotals.writtenOffTotal.toFixed(2)}`}
              </p>
            )}
          </div>
        </div>
      </div>

      {/* ── Challenge floating bar ── */}
      {challengedItems.size > 0 && (
        <div className="fixed bottom-0 left-0 right-0 z-50 bg-orange-600 text-white shadow-lg border-t border-orange-700">
          <div className="max-w-7xl mx-auto px-6 py-3 flex items-center justify-between">
            <div className="flex items-center gap-3">
              <Mail className="w-5 h-5" />
              <span className="font-medium">{challengedItems.size} item{challengedItems.size !== 1 ? 's' : ''} flagged for challenge</span>
            </div>
            <div className="flex items-center gap-3">
              <button
                onClick={() => { setChallengedItems(new Set()); setNotFoundResolutions(prev => {
                  const next = { ...prev }; for (const k of Object.keys(next)) { if (next[k].type === 'challenged') delete next[k] }; return next
                }); setMissingResolutions(prev => {
                  const next = { ...prev }; for (const k of Object.keys(next)) { if (next[k].type === 'challenged') delete next[k] }; return next
                }) }}
                className="px-3 py-1.5 text-sm text-orange-200 hover:text-white"
              >
                Clear All
              </button>
              <button
                onClick={() => setShowChallengePanel(true)}
                className="flex items-center gap-2 px-4 py-1.5 text-sm font-medium bg-white text-orange-600 rounded-lg hover:bg-orange-50"
              >
                <Send className="w-4 h-4" /> Review & Send Email
              </button>
            </div>
          </div>
        </div>
      )}

      {/* ── Challenge email panel (modal) ── */}
      {showChallengePanel && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40" onClick={() => setShowChallengePanel(false)}>
          <div className="bg-white rounded-xl shadow-xl max-w-2xl w-full mx-4 max-h-[80vh] overflow-y-auto" onClick={e => e.stopPropagation()}>
            <div className="px-6 py-4 border-b border-gray-200 flex items-center justify-between">
              <h3 className="text-lg font-semibold text-gray-900">Challenge Discrepancies</h3>
              <button onClick={() => setShowChallengePanel(false)} className="p-1 rounded hover:bg-gray-100"><X className="w-5 h-5 text-gray-400" /></button>
            </div>
            <div className="px-6 py-4 space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Recipient Email</label>
                <input
                  type="email"
                  value={challengeEmail}
                  onChange={e => setChallengeEmail(e.target.value)}
                  placeholder="supplier@goldstar.com"
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-navy/30"
                />
              </div>

              {/* Preview challenged items */}
              {(() => {
                const nfItems = result.rows.filter(r => r.status === 'not_found' && challengedItems.has(`nf:${notFoundKey(r.invoiceLine)}`))
                const missItems = result.missingFromInvoice.filter(o => challengedItems.has(`miss:${o.id}`))
                const mmItems = result.rows.filter(r => r.status === 'price_mismatch' && challengedItems.has(`mm:${notFoundKey(r.invoiceLine)}`))
                return (
                  <div className="space-y-3">
                    {nfItems.length > 0 && (
                      <div>
                        <p className="text-xs font-semibold text-red-600 uppercase mb-1">On Invoice Only ({nfItems.length})</p>
                        <div className="bg-red-50 rounded-lg p-3 text-xs space-y-1">
                          {nfItems.map((r, i) => (
                            <div key={i} className="flex justify-between">
                              <span>Docket {r.invoiceLine.ticket} — {r.invoiceLine.description}</span>
                              <span className="font-medium">{'\u00a3'}{r.invoiceLine.net.toFixed(2)}</span>
                            </div>
                          ))}
                        </div>
                      </div>
                    )}
                    {missItems.length > 0 && (
                      <div>
                        <p className="text-xs font-semibold text-blue-600 uppercase mb-1">In System Only ({missItems.length})</p>
                        <div className="bg-blue-50 rounded-lg p-3 text-xs space-y-1">
                          {missItems.map(o => (
                            <div key={o.id} className="flex justify-between">
                              <span>Docket {o.docket_number} — {o.department?.name} — {(o.order_items || []).map(i => `${i.quantity_sent}x ${i.item_name}`).join(', ')}</span>
                              <span className="font-medium">{'\u00a3'}{computeOrderCost(o).toFixed(2)}</span>
                            </div>
                          ))}
                        </div>
                      </div>
                    )}
                    {mmItems.length > 0 && (
                      <div>
                        <p className="text-xs font-semibold text-amber-600 uppercase mb-1">Price Discrepancies ({mmItems.length})</p>
                        <div className="bg-amber-50 rounded-lg p-3 text-xs space-y-1">
                          {mmItems.map((r, i) => (
                            <div key={i} className="flex justify-between">
                              <span>Docket {r.invoiceLine.ticket} — Invoice {'\u00a3'}{r.invoiceLine.net.toFixed(2)} vs System {'\u00a3'}{r.systemTotal.toFixed(2)}</span>
                              <span className="font-medium text-amber-700">Diff {'\u00a3'}{r.difference.toFixed(2)}</span>
                            </div>
                          ))}
                        </div>
                      </div>
                    )}
                  </div>
                )
              })()}

              <button
                onClick={() => { generateChallengeEmail(); setShowChallengePanel(false) }}
                disabled={!challengeEmail}
                className="w-full flex items-center justify-center gap-2 px-4 py-2.5 text-sm font-medium text-white bg-orange-600 rounded-lg hover:bg-orange-700 disabled:opacity-50 disabled:cursor-not-allowed"
              >
                <Send className="w-4 h-4" /> Send Challenge Email
              </button>
            </div>
          </div>
        </div>
      )}

      {/* ── Add to System modal ── */}
      {addModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40" onClick={() => setAddModal(null)}>
          <div className="bg-white rounded-xl shadow-xl max-w-lg w-full mx-4" onClick={e => e.stopPropagation()}>
            <div className="px-6 py-4 border-b border-gray-200 flex items-center justify-between">
              <h3 className="text-lg font-semibold text-gray-900">Add to System</h3>
              <button onClick={() => setAddModal(null)} className="p-1 rounded hover:bg-gray-100"><X className="w-5 h-5 text-gray-400" /></button>
            </div>
            <div className="px-6 py-4 space-y-4">
              <p className="text-sm text-gray-600">
                This invoice item was not found in our system. Create an order to match it.
              </p>

              {/* Invoice item details */}
              <div className="bg-gray-50 rounded-lg p-3 text-sm space-y-2">
                <div className="flex justify-between"><span className="text-gray-500">Description:</span><span className="text-right max-w-[250px] truncate">{addModal.row.invoiceLine.description}</span></div>
                <div className="flex justify-between"><span className="text-gray-500">Amount (NET):</span><span className="font-bold">{'\u00a3'}{addModal.row.invoiceLine.net.toFixed(2)}</span></div>
                <div className="flex justify-between"><span className="text-gray-500">Service Type:</span><span>{ORDER_TYPE_LABELS[addModal.row.sectionType as OrderType] ?? addModal.row.sectionType}</span></div>
              </div>

              {/* Editable docket number and date */}
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Docket Number</label>
                  <input
                    type="text"
                    value={addModalDocket}
                    onChange={e => setAddModalDocket(e.target.value)}
                    placeholder="Auto-generated if empty"
                    className={`w-full px-3 py-2 border border-gray-300 rounded-lg text-sm font-mono focus:outline-none focus:ring-2 focus:ring-navy/30 ${addModalDocket.startsWith('REC-') ? 'text-gray-400 italic' : ''}`}
                  />
                  {addModalDocket.startsWith('REC-') && (
                    <p className="text-[10px] text-gray-400 mt-0.5">Auto-generated — edit if you have the actual docket number</p>
                  )}
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Date</label>
                  <input
                    type="date"
                    value={(() => {
                      // Convert dd/MM/yy to yyyy-MM-dd for the date input
                      if (!addModalDate) return ''
                      const parts = addModalDate.split('/')
                      if (parts.length === 3) {
                        let yr = parts[2]; if (yr.length === 2) yr = `20${yr}`
                        return `${yr}-${parts[1].padStart(2, '0')}-${parts[0].padStart(2, '0')}`
                      }
                      return addModalDate
                    })()}
                    onChange={e => setAddModalDate(e.target.value)}
                    className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-navy/30"
                  />
                </div>
              </div>

              {/* Catalogue price comparison */}
              {addModal.row.invoiceLine.items.length > 0 && (
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Price Comparison vs Catalogue</label>
                  <div className="border border-gray-200 rounded-lg overflow-hidden">
                    <table className="w-full text-xs">
                      <thead><tr className="bg-gray-50 border-b border-gray-200">
                        <th className="px-2 py-1.5 text-left font-medium text-gray-600">Item</th>
                        <th className="px-2 py-1.5 text-right font-medium text-gray-600">Qty</th>
                        <th className="px-2 py-1.5 text-right font-medium text-gray-600">Invoice</th>
                        <th className="px-2 py-1.5 text-right font-medium text-gray-600">Catalogue</th>
                        <th className="px-2 py-1.5 text-right font-medium text-gray-600">Diff</th>
                      </tr></thead>
                      <tbody>
                        {addModal.row.invoiceLine.items.map((it, idx) => {
                          const invoiceUnitPrice = addModal.row.invoiceLine.items.length === 1
                            ? addModal.row.invoiceLine.net / it.quantity
                            : null
                          const catMatch = catalogueItems.find(c =>
                            c.name.toLowerCase() === it.name.toLowerCase() ||
                            it.name.toLowerCase().includes(c.name.toLowerCase()) ||
                            c.name.toLowerCase().includes(it.name.toLowerCase())
                          )
                          const catPrice = catMatch?.price ?? null
                          const diff = invoiceUnitPrice != null && catPrice != null
                            ? Math.round((invoiceUnitPrice - catPrice) * 100) / 100
                            : null
                          return (
                            <tr key={idx} className={`border-b border-gray-100 ${diff != null && Math.abs(diff) >= 0.01 ? 'bg-amber-50' : ''}`}>
                              <td className="px-2 py-1.5 text-gray-700">{it.name}</td>
                              <td className="px-2 py-1.5 text-right">{it.quantity}</td>
                              <td className="px-2 py-1.5 text-right font-medium">
                                {invoiceUnitPrice != null ? `\u00a3${invoiceUnitPrice.toFixed(2)}` : '\u2014'}
                              </td>
                              <td className="px-2 py-1.5 text-right font-medium">
                                {catPrice != null ? `\u00a3${catPrice.toFixed(2)}` : <span className="text-gray-400">N/A</span>}
                              </td>
                              <td className={`px-2 py-1.5 text-right font-medium ${diff != null && Math.abs(diff) >= 0.01 ? 'text-amber-600' : 'text-green-600'}`}>
                                {diff != null ? (diff >= 0 ? '+' : '') + `\u00a3${diff.toFixed(2)}` : '\u2014'}
                              </td>
                            </tr>
                          )
                        })}
                      </tbody>
                    </table>
                  </div>
                </div>
              )}

              {/* Department selection */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Allocate to Department *</label>
                <select
                  value={addModalDept}
                  onChange={e => setAddModalDept(e.target.value)}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-navy/30"
                >
                  <option value="">Select department...</option>
                  {departments.map(d => (
                    <option key={d.id} value={d.id}>{d.name}</option>
                  ))}
                </select>
              </div>

              <div className="flex gap-3 pt-2">
                <button onClick={() => setAddModal(null)} className="flex-1 px-4 py-2 text-sm text-gray-700 bg-gray-100 rounded-lg hover:bg-gray-200">
                  Cancel
                </button>
                <button
                  onClick={handleAddToSystem}
                  disabled={!addModalDept || addModalSaving}
                  className="flex-1 flex items-center justify-center gap-2 px-4 py-2 text-sm font-medium text-white bg-blue-600 rounded-lg hover:bg-blue-700 disabled:opacity-50"
                >
                  {addModalSaving ? <RefreshCw className="w-4 h-4 animate-spin" /> : <Plus className="w-4 h-4" />}
                  {addModalSaving ? 'Adding...' : 'Add Order'}
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}

function StatCard({ icon, label, value, color, subtitle }: { icon: React.ReactNode; label: string; value: number; color: string; subtitle?: string }) {
  return (
    <div className="bg-white rounded-xl border border-gray-200 p-4">
      <div className="flex items-center gap-2 mb-1">{icon}<span className="text-xs text-gray-500">{label}</span></div>
      <p className={`text-2xl font-bold text-${color}-600`}>{value}</p>
      {subtitle && <p className="text-[10px] text-green-600 mt-0.5">{subtitle}</p>}
    </div>
  )
}
