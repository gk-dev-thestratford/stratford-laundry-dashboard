import { useState, useMemo, useCallback, useEffect, useRef, Fragment } from 'react'
import { Upload, RefreshCw, Download, CheckCircle, AlertTriangle, XCircle, HelpCircle, FileText, X, Save, Clock, ChevronRight, Plus, Mail, Ban, ArrowRightLeft, Send, Search, Scale, StickyNote, Tag } from 'lucide-react'
import { supabase } from '../lib/supabase'
import {
  extractPdfLinesRaw, parseInvoiceFile, parseInvoicePeriod, derivePeriodFromLines,
  sectionTypeToOrderType, canonicalDocket, guestNameMatches, guestNameSimilar,
  type ParsedInvoice, type InvoiceLine, type InvoiceSectionType,
  extractAndParseD140, type D140Report, type D140Transaction,
} from '../lib/invoiceParser'
import { downloadReconciliationPdf, generateReconciliationPdfBlob, type DepartmentDisplayRow, type FinancialTotals, type PdfChargeGroup } from '../lib/pdfReport'
import { computeOrderCost } from '../lib/orderCost'
import { CHEF_WEEKLY_MINIMUMS, CHEF_TOPUP_RATES, NAPKIN_WEEKLY_MINIMUM, NAPKIN_RATE } from '../lib/minimums'
import {
  phase1Available, logAction, fetchActions, loadDraft, saveDraft,
  fetchOrderResolutions, setOrderResolution, clearOrderResolution, fetchOpenExpected, markExpectedFound,
  ORDER_RESOLUTION_LABELS, type ReconAction, type OrderResolution, type OrderResolutionRow,
} from '../lib/reconPhase1'
import {
  buildLineKeys, fetchLineNotes, upsertLineNote, deleteLineNote, fetchGroupFolios, upsertGroupFolio,
  fetchKnownGroupNames, chargeLabel, chargeBucket, CHARGE_TYPE_LABELS, isExplainedType,
  type LineNote, type GroupFolio, type ChargeType,
} from '../lib/lineNotes'
import type { Order, OrderType, Department } from '../types'
import { ORDER_TYPE_LABELS } from '../types'
import { utils, writeFile } from 'xlsx'
import CreditRequestModal from '../components/reconciliation/CreditRequestModal'
import CreditNotesPanel from '../components/reconciliation/CreditNotesPanel'
import type { CreditLine } from '../lib/reconPhase1'
import { format } from 'date-fns'

// ── Types ──

interface ReconciliationRow {
  invoiceLine: InvoiceLine
  sectionType: string
  order: Order | null
  status: 'matched' | 'price_mismatch' | 'not_found'
  systemTotal: number
  difference: number
  rowIndex: number
  // True when the order matched but the price differs only by a small, proportionate
  // amount (e.g. the £0.215 vs £0.22 napkin rate gap). Still a 'price_mismatch', but
  // surfaced as a calm "minor variance" rather than an alarming discrepancy.
  minorVariance: boolean
  /** Why a line is unmatched when that's useful, e.g. "ticket 1691 is a F&B Linen order…" */
  hint?: string
}

/** Price-difference tolerance: minor if within max(£0.15, 3% of the system total). */
function isMinorVariance(diff: number, systemTotal: number): boolean {
  return Math.abs(diff) <= Math.max(0.15, systemTotal * 0.03)
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
  /** Not on this invoice but written on the period's last day: probably next invoice */
  nextInvoice: Order[]
  matchedOrderIds: string[]
  stats: { matched: number; priceMismatch: number; minorVariance: number; notFound: number; missing: number }
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

// Snapshot of the per-line work, saved to reconciliations.line_resolutions (jsonb) and
// restored when the same invoice is uploaded again. Keys are notFoundKey() / order ids,
// which are deterministic for the same PDF.
interface LineResolutionsSnapshot {
  notFound?: Record<string, Resolution>
  missing?: Record<string, Resolution>
  challenged?: string[]
  lineNotes?: Record<string, string>
}

/** Unique key for a not_found invoice line */
function notFoundKey(row: ReconciliationRow): string {
  return `${row.invoiceLine.ticket}-${row.invoiceLine.date}-${row.invoiceLine.net}-${row.rowIndex}`
}

// ── Helpers ──

// computeOrderCost is the shared canonical calculation — see src/lib/orderCost.ts

// Unused weekly napkin minimum (the Napkin TopUp) is split by a fixed agreed ratio,
// not by usage — a department that sent nothing that week still carries its share.
const NAPKIN_TOPUP_SPLIT: [string, number][] = [
  ['Kitchen E20 Front', 0.60],
  ['Lounge', 0.15],
  ['Events', 0.25],
]

/** Napkin TopUp NET → per-department shares; rounding remainder goes to the largest share so they sum exactly. */
function splitNapkinTopUp(net: number): Map<string, number> {
  const shares = new Map<string, number>()
  for (const [name, pct] of NAPKIN_TOPUP_SPLIT) shares.set(name, +(net * pct).toFixed(2))
  const remainder = +(net - Array.from(shares.values()).reduce((s, v) => s + v, 0)).toFixed(2)
  if (remainder !== 0) shares.set(NAPKIN_TOPUP_SPLIT[0][0], +(shares.get(NAPKIN_TOPUP_SPLIT[0][0])! + remainder).toFixed(2))
  return shares
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
      } else if (secType === 'napkins') {
        // Napkin TopUp: fixed split (Kitchen E20 Front 60% / Lounge 15% / Events 25%)
        for (const [name, share] of splitNapkinTopUp(topUp.net)) {
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

// A row counts as HSK linen ONLY when the matched system order is an hsk_linen order.
// Never classify by item-name substrings: the hsk_linen catalogue contains generic names
// like "Hoodie" that also appear in staff uniforms, which falsely split Main Kitchen /
// Kitchen E20 Front into a phantom "Other (HSK Linen)" line.
function isHskLinenRow(row: ReconciliationRow): boolean {
  return row.order?.order_type === 'hsk_linen'
}

function buildDepartmentDisplayRows(
  breakdown: DepartmentBreakdown[],
  allRows: ReconciliationRow[],
  // Per-department small print for tagged / no-room lines ("Incl. Group: X £..."), so the
  // breakdown shows group charges without adding rows that would double-count totals.
  chargeDetail?: Map<string, string>
): DepartmentDisplayRow[] {
  const displayRows: DepartmentDisplayRow[] = []
  for (const dept of breakdown) {
    // Check if this department has a mix of staff uniform and HSK linen items
    let uniformCount = 0, uniformInvNet = 0, uniformSysNet = 0
    let linenCount = 0, linenInvNet = 0, linenSysNet = 0
    const linenItemQty = new Map<string, number>()

    for (const row of allRows) {
      const deptName = row.order?.department?.name || 'Unallocated'
      if (deptName !== dept.departmentName || row.status === 'not_found') continue
      if (isHskLinenRow(row)) {
        linenCount++
        linenInvNet += row.invoiceLine.net
        linenSysNet += row.systemTotal
        for (const it of row.order?.order_items ?? []) {
          if (!it.item_name) continue
          linenItemQty.set(it.item_name, (linenItemQty.get(it.item_name) || 0) + (it.quantity_sent ?? 0))
        }
      } else {
        uniformCount++
        uniformInvNet += row.invoiceLine.net
        uniformSysNet += row.systemTotal
      }
    }

    const label = departmentItemsLabel(allRows, dept.departmentName)

    // One row per department. When the department mixes uniforms with HSK linen
    // (e.g. Housekeeping), the linen content is shown as small print under the main
    // line instead of a separate "Other (HSK Linen)" row — totals stay combined.
    const linenDetail = linenCount > 0
      ? `Incl. HSK Linen £${linenInvNet.toFixed(2)} (${linenCount} order${linenCount !== 1 ? 's' : ''})${
          linenItemQty.size > 0
            ? ': ' + Array.from(linenItemQty.entries()).sort((a, b) => b[1] - a[1]).map(([name, qty]) => `${qty}x ${name}`).join(', ')
            : ''}`
      : undefined
    displayRows.push({
      departmentName: dept.departmentName,
      lineLabel: linenCount > 0 && uniformCount > 0 ? 'Staff Uniform' : label,
      subDetail: [linenDetail, chargeDetail?.get(dept.departmentName)].filter(Boolean).join(' · ') || undefined,
      isTopUp: false,
      orderCount: dept.orderCount,
      invoiceNet: dept.invoiceNet,
      systemTotal: dept.systemTotal,
      difference: dept.difference,
      totalGross: +(dept.invoiceNet * 1.2).toFixed(2),
    })
    if (dept.allocatedTopUp > 0) {
      displayRows.push({
        departmentName: dept.departmentName,
        lineLabel: 'Minimum TopUp',
        // Uniform TopUp lands 100% on Main Kitchen — it's the unutilised part of the
        // weekly uniform minimum, i.e. still Staff Uniform spend, not a separate service.
        subDetail: dept.departmentName === 'Main Kitchen' ? 'Unutilised weekly uniform minimum (counts as Staff Uniform)' : undefined,
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

const DAY_MS = 86_400_000

/** Invoice line date ("DD/MM/YY", "D/M/YYYY", ...) → UTC day number, or null. */
function invoiceLineDay(date: string): number | null {
  const m = date?.match(/^(\d{1,2})\/(\d{1,2})\/(\d{2,4})$/)
  if (!m) return null
  let yr = parseInt(m[3]); if (yr < 100) yr += 2000
  return Math.floor(Date.UTC(yr, parseInt(m[2]) - 1, parseInt(m[1])) / DAY_MS)
}

/** Opera D140 date ("DD-MM-YY") → UTC day number, or null. */
function d140Day(date: string): number | null {
  const m = date?.match(/^(\d{2})-(\d{2})-(\d{2,4})$/)
  if (!m) return null
  let yr = +m[3]; if (yr < 100) yr += 2000
  return Math.floor(Date.UTC(yr, +m[2] - 1, +m[1]) / DAY_MS)
}

function orderDay(o: Order): number {
  return Math.floor(new Date(o.created_at).getTime() / DAY_MS)
}

/**
 * Guest rooms repeat within a month (same guest, several bags; or a new guest in the same
 * room), so "first unclaimed order for room 417" can pair the wrong bags. Rank candidates
 * by: guest name matches → closest creation date to the invoice line → closest cost.
 */
/**
 * Rejected / expired on the tablet. NOT excluded: Goldstar still invoices many of them
 * (Sept 2026: napkins 1440, 1445, 1448… were rejected yet invoiced and reconciled), so they
 * stay matchable, rank below active orders, and are labelled on the row.
 */
function isInactiveOrder(o: Order): boolean {
  return o.status === 'rejected' || o.status === 'expired'
}

/**
 * Orders that "Add to System" created from a weekly Minimum top-up line (old parser, before
 * 5 Nov 2026). They are copies of a top-up CHARGE, not real laundry, and double-count it.
 */
function isTopUpCopy(o: Order): boolean {
  return /^REC-/i.test(o.docket_number ?? '') && /Added from invoice reconciliation/.test(o.notes ?? '') && /\[ref:\|/.test(o.notes ?? '')
}

const itemWords = (s: string) => s.toLowerCase().replace(/[^a-z\s]/g, ' ').split(/\s+/).filter(w => w.length > 2 && !['and', 'the'].includes(w))

/**
 * Several orders with the same ticket in the same service (typos, re-used numbers): pick
 * the one whose items, date and amount fit the invoice line best, instead of the first.
 * Sept 2026: staff 1563 (2x Chef Jacket) took the Front Office shirts order before this.
 */
function pickBestDocketOrder(candidates: Order[], line: InvoiceLine): Order | null {
  if (candidates.length <= 1) return candidates[0] ?? null
  const lineDay = invoiceLineDay(line.date)
  const invQty = line.items.reduce((s, it) => s + it.quantity, 0)
  const invWords = new Set(line.items.flatMap(it => itemWords(it.name)))
  const score = (o: Order) => {
    const items = o.order_items ?? []
    const sysQty = items.reduce((s, it) => s + (it.quantity_sent ?? 0), 0)
    const sysWords = new Set(items.flatMap(it => itemWords(it.item_name ?? '')))
    const overlap = invWords.size ? [...invWords].filter(w => sysWords.has(w)).length / invWords.size : 0
    const days = lineDay == null ? 0 : Math.abs(orderDay(o) - lineDay)
    return (invQty > 0 && sysQty === invQty ? 3 : 0) + overlap * 2 + (Math.abs(computeOrderCost(o) - line.net) < 0.02 ? 1 : 0) - Math.min(days, 10) * 0.3
      - (isInactiveOrder(o) ? 0.5 : 0)
  }
  return [...candidates].sort((a, b) => score(b) - score(a))[0]
}

function pickClosestGuestOrder(candidates: Order[], line: InvoiceLine): Order | null {
  const lineDay0 = invoiceLineDay(line.date)
  // Orders within a few days of the line come first; only fall back to further ones
  if (lineDay0 != null && candidates.length > 1) {
    const near = candidates.filter(o => Math.abs(orderDay(o) - lineDay0) <= GUEST_NEAR_DAYS)
    if (near.length) candidates = near
  }
  if (candidates.length <= 1) return candidates[0] ?? null
  const lineDay = lineDay0
  const rank = (o: Order): [number, number, number] => [
    line.guestInfo && guestNameMatches(line.guestInfo, o.guest_name) ? 0 : 1,
    lineDay == null ? 0 : Math.abs(orderDay(o) - lineDay),
    Math.abs(computeOrderCost(o) - line.net),
  ]
  return candidates
    .map(o => ({ o, r: rank(o) }))
    .sort((a, b) => a.r[0] - b.r[0] || a.r[1] - b.r[1] || a.r[2] - b.r[2])[0].o
}

// Days either side of the invoice line date for name-only and room-override matching.
const GUEST_MATCH_WINDOW_DAYS = 1
// Days before the invoice period start that orders are still considered (written the
// evening before Goldstar's first collection of the month).
const LEAD_WINDOW_DAYS = 3
// Guest room/docket candidates within this many days of the invoice line are preferred.
const GUEST_NEAR_DAYS = 3

/**
 * Manual-link keys per invoice line, stamped as "[ref:...]" into the linked order's notes.
 * Lines with a ticket use "[ref:<ticket>|<date>|<net>]". Lines with NO ticket (guest lines
 * without a room) need an occurrence number, otherwise two no-room lines with the same date
 * and amount share one key and linking the second silently unlinks the first. The first
 * such line also accepts the legacy "[ref:|<date>|<net>]" form so existing links survive.
 * First key = the one to write; the rest are also accepted when matching.
 */
function lineRefKeys(invoice: ParsedInvoice | null): Map<InvoiceLine, string[]> {
  const out = new Map<InvoiceLine, string[]>()
  if (!invoice) return out
  const seen = new Map<string, number>()
  for (const section of invoice.sections) {
    for (const line of section.lines) {
      if (line.isTopUp) continue
      if (line.ticket) { out.set(line, [`[ref:${line.ticket}|${line.date}|${line.net}]`]); continue }
      const base = `${line.date}|${line.net}`
      const n = (seen.get(base) ?? 0) + 1
      seen.set(base, n)
      out.set(line, n === 1 ? [`[ref:#1|${base}]`, `[ref:|${base}]`] : [`[ref:#${n}|${base}]`])
    }
  }
  return out
}

function reconcile(
  invoice: ParsedInvoice, orders: Order[], period: { start: Date; end: Date } | null,
  strictPeriod?: { start: Date; end: Date } | null,
  // Line notes for this invoice: explicit order picks and "room missing" overrides
  notesByLine?: Map<InvoiceLine, LineNote>,
): ReconciliationResult {
  // Issue 2: Use array map to handle duplicate docket numbers.
  // Key by canonicalDocket so a reset-booklet ticket "6" matches a stored "0006", etc.
  const byDocket = new Map<string, Order[]>()
  const byRoom = new Map<string, Order[]>()
  // Explicit human links (made via the Link modal) are stamped as "[ref:ticket|date|net]"
  // in order notes. They take PRIORITY over docket/room heuristics — a manual link must
  // never be overridden by a coincidental docket match. An order pinned to one of THIS
  // invoice's lines is kept OUT of the docket/room pools so another line can't steal it.
  // Orders explicitly picked in a line note ("who could it be") are pinned the same way.
  const refKeys = lineRefKeys(invoice)
  const wantedRefs = new Set([...refKeys.values()].flat())
  const pickedIds = new Set<string>()
  for (const n of notesByLine?.values() ?? []) if (n.order_id) pickedIds.add(n.order_id)
  const byRef = new Map<string, Order[]>()
  const guestPool: Order[] = [] // unpinned guest orders, for the name-only fallback
  for (const o of orders) {
    const refs = o.notes?.match(/\[ref:[^\]]+\]/g) ?? []
    let pinned = pickedIds.has(o.id)
    for (const r of refs) {
      if (!wantedRefs.has(r)) continue
      pinned = true
      if (!byRef.has(r)) byRef.set(r, [])
      byRef.get(r)!.push(o)
    }
    if (pinned) continue
    if (o.order_type === 'guest_laundry') guestPool.push(o)
    const dk = canonicalDocket(o.docket_number)
    if (!byDocket.has(dk)) byDocket.set(dk, [])
    byDocket.get(dk)!.push(o)
    if (o.room_number) {
      if (!byRoom.has(o.room_number)) byRoom.set(o.room_number, [])
      byRoom.get(o.room_number)!.push(o)
    }
  }

  const topUpCharges: InvoiceLine[] = []
  const matchedOrderIds = new Set<string>()
  const pending: { line: InvoiceLine; sectionType: InvoiceSectionType; orderType: string; order: Order | null; hint?: string }[] = []

  for (const section of invoice.sections) {
    const orderType = sectionTypeToOrderType(section.type)
    for (const line of section.lines) {
      if (line.isTopUp) { topUpCharges.push(line); continue }
      // 1) Explicit manual link (ref-key) wins over everything
      let order: Order | null = null
      for (const k of refKeys.get(line) ?? []) {
        order = (byRef.get(k) ?? []).find(o => !matchedOrderIds.has(o.id)) ?? null
        if (order) break
      }
      // 1b) Order explicitly picked for this line in its note
      const pickedId = notesByLine?.get(line)?.order_id
      if (!order && pickedId) order = orders.find(o => o.id === pickedId && !matchedOrderIds.has(o.id)) ?? null
      // 2) Docket match (canonicalised both sides), SAME SERVICE ONLY. Goldstar uses one
      // ticket booklet for every service, so a number only means something within its own
      // service: a bathrobe line must never take a napkin order with the same ticket
      // (Sept 2026: bathrobe 1691 ↔ napkin 1691). Guest dockets are room numbers.
      // When a ticket exists more than once, pick the best order (items, date, amount),
      // not the first one. An empty ticket must not match orders with no docket.
      const docketKey = canonicalDocket(line.ticket)
      let hint: string | undefined
      if (!order && docketKey) {
        const sameTicket = (byDocket.get(docketKey) ?? []).filter(o => !matchedOrderIds.has(o.id))
        const docketCandidates = sameTicket.filter(o => o.order_type === orderType)
        order = section.type === 'guest' ? pickClosestGuestOrder(docketCandidates, line) : pickBestDocketOrder(docketCandidates, line)
        if (!order) {
          const other = sameTicket.find(o => o.order_type !== orderType)
          if (other) hint = `ticket ${line.ticket} is a ${ORDER_TYPE_LABELS[other.order_type as OrderType] ?? other.order_type} order (${other.department?.name ?? 'no department'}): different service, not matched`
        }
      }
      // 3) Guest lines: fall back to room-number match
      if (!order && section.type === 'guest' && line.ticket) {
        const candidates = (byRoom.get(line.ticket) ?? []).filter(o => !matchedOrderIds.has(o.id))
        order = pickClosestGuestOrder(candidates, line)
      }
      if (order) matchedOrderIds.add(order.id)
      pending.push({ line, sectionType: section.type, orderType, order, hint })
    }
  }

  // 4) Guest lines the invoice prints with no room (e.g. "OVER GT EX MOHAMMED", "EX SHAFIQ"):
  // after every room/docket match has claimed its order, try the guest name against the
  // remaining guest orders created within ±1 day of the line date.
  const inWindow = (o: Order, line: InvoiceLine) => {
    const lineDay = invoiceLineDay(line.date)
    return lineDay == null || Math.abs(orderDay(o) - lineDay) <= GUEST_MATCH_WINDOW_DAYS
  }
  for (const p of pending) {
    if (p.order || p.sectionType !== 'guest' || p.line.ticket || !p.line.guestInfo) continue
    if (notesByLine?.get(p.line)?.charge_type === 'room_missing') continue // pass 5 uses the typed room
    const candidates = guestPool.filter(o =>
      !matchedOrderIds.has(o.id) && guestNameMatches(p.line.guestInfo, o.guest_name) && inWindow(o, p.line))
    p.order = pickClosestGuestOrder(candidates, p.line)
    if (p.order) matchedOrderIds.add(p.order.id)
  }

  // 5) "Room missing on invoice" lines with a room typed in: matched LAST, so the override
  // can never take an order that a genuine room line on the invoice should get.
  for (const p of pending) {
    const room = notesByLine?.get(p.line)?.charge_type === 'room_missing' ? notesByLine.get(p.line)?.room_override : null
    if (p.order || p.sectionType !== 'guest' || !room) continue
    const key = canonicalDocket(room)
    const candidates = guestPool.filter(o =>
      !matchedOrderIds.has(o.id) && inWindow(o, p.line) &&
      (o.room_number === room || canonicalDocket(o.docket_number) === key))
    p.order = pickClosestGuestOrder(candidates, p.line)
    if (p.order) matchedOrderIds.add(p.order.id)
  }

  const rows: ReconciliationRow[] = pending.map(({ line, orderType, order, hint }, rowIndex) => {
    const systemTotal = order ? computeOrderCost(order) : 0
    const diff = order ? +(line.net - systemTotal).toFixed(2) : line.net
    const status: ReconciliationRow['status'] = !order
      ? 'not_found' : Math.abs(diff) < 0.02 ? 'matched' : 'price_mismatch'
    const minorVariance = status === 'price_mismatch' && isMinorVariance(diff, systemTotal)
    return { invoiceLine: line, sectionType: orderType, order, status, systemTotal, difference: diff, rowIndex, minorVariance, hint }
  })

  // Issue 1: Use strictPeriod (original invoice period) for "In System Only" filtering
  // so broader-search orders from the previous month don't appear as missing.
  // Orders written on the period's LAST day are usually collected and invoiced the next
  // day, i.e. on next month's invoice: listed as "probably next invoice", not missing.
  const missingPeriod = strictPeriod ?? period
  const invoiceOrderTypes = new Set(invoice.sections.map(s => sectionTypeToOrderType(s.type)))
  const lastDay = missingPeriod ? Math.floor(missingPeriod.end.getTime() / DAY_MS) : null
  const unmatched = orders.filter(o => {
    if (matchedOrderIds.has(o.id)) return false
    if (!invoiceOrderTypes.has(o.order_type)) return false
    if (missingPeriod) {
      const orderDate = new Date(o.created_at)
      if (orderDate < missingPeriod.start || orderDate > missingPeriod.end) return false
    }
    return true
  })
  const nextInvoice = lastDay == null ? [] : unmatched.filter(o => orderDay(o) === lastDay)
  const missingFromInvoice = unmatched.filter(o => !nextInvoice.includes(o))

  return {
    rows, topUpCharges, missingFromInvoice, nextInvoice,
    matchedOrderIds: Array.from(matchedOrderIds),
    stats: {
      matched: rows.filter(r => r.status === 'matched').length,
      priceMismatch: rows.filter(r => r.status === 'price_mismatch').length,
      minorVariance: rows.filter(r => r.minorVariance).length,
      notFound: rows.filter(r => r.status === 'not_found').length,
      missing: missingFromInvoice.length,
    },
    invoiceTotal: rows.reduce((s, r) => s + r.invoiceLine.net, 0),
    systemTotal: rows.reduce((s, r) => s + r.systemTotal, 0),
    departmentBreakdown: buildDepartmentBreakdown(rows, topUpCharges),
  }
}

// Fetch the orders the matcher works against: everything inside the invoice period
// (optionally extended 1 month back), PLUS any order carrying a manual "[ref:...]" link
// key in its notes. Linked orders can live OUTSIDE the period (whole-DB link search) —
// without this merge a link to an order from another month silently disappears on
// refetch and on every re-upload.
function invoiceRefKeys(invoice: ParsedInvoice): Set<string> {
  return new Set([...lineRefKeys(invoice).values()].flat())
}

function pickedOrderIds(notes: Record<string, LineNote>): string[] {
  return Object.values(notes).map(n => n.order_id).filter((id): id is string => !!id)
}

/** Line notes keyed by the invoice line they belong to (via the stable line keys). */
function notesMapFor(invoice: ParsedInvoice | null, notes: Record<string, LineNote>): Map<InvoiceLine, LineNote> {
  const m = new Map<InvoiceLine, LineNote>()
  for (const [line, key] of buildLineKeys(invoice)) if (notes[key]) m.set(line, notes[key])
  return m
}

async function fetchOrdersForReconciliation(invoice: ParsedInvoice, period: { start: Date; end: Date } | null, broaderSearch: boolean, pickedOrderIds: string[] = []): Promise<Order[]> {
  let fetched: Order[] = []
  if (period) {
    // Tickets are often written the evening before Goldstar collects (e.g. 31/08 for an
    // invoice line dated 01/09), so always look a few days before the period starts.
    let fetchStart = new Date(period.start.getTime() - LEAD_WINDOW_DAYS * DAY_MS)
    if (broaderSearch) {
      fetchStart = new Date(period.start)
      fetchStart.setUTCMonth(fetchStart.getUTCMonth() - 1)
    }
    const { data } = await supabase.from('orders').select('*, department:departments(*), order_items(*)')
      .gte('created_at', fetchStart.toISOString()).lte('created_at', period.end.toISOString())
      .order('created_at', { ascending: true })
    fetched = (data as Order[] | null) ?? []
  } else {
    const { data } = await supabase.from('orders').select('*, department:departments(*), order_items(*)')
      .order('created_at', { ascending: false }).limit(500)
    fetched = (data as Order[] | null) ?? []
  }
  // Merge only orders whose ref-key belongs to one of THIS invoice's lines — merging all
  // ref-linked orders would let an order linked to a different invoice docket-match here.
  const wanted = invoiceRefKeys(invoice)
  const { data: refLinked } = await supabase.from('orders').select('*, department:departments(*), order_items(*)')
    .ilike('notes', '%[ref:%').limit(500)
  if (refLinked?.length) {
    const seen = new Set(fetched.map(o => o.id))
    for (const o of refLinked as Order[]) {
      if (seen.has(o.id)) continue
      const refs = o.notes?.match(/\[ref:[^\]]+\]/g)
      if (refs?.some(r => wanted.has(r))) fetched.push(o)
    }
  }
  // Orders explicitly picked in line notes may sit just outside the period (±1 day)
  const missingPicked = pickedOrderIds.filter(id => !fetched.some(o => o.id === id))
  if (missingPicked.length) {
    const { data: picked } = await supabase.from('orders').select('*, department:departments(*), order_items(*)').in('id', missingPicked)
    fetched.push(...((picked as Order[] | null) ?? []))
  }
  return fetched
}

type FilterTab = 'all' | 'matched' | 'mismatch' | 'not_found' | 'missing' | 'group' | 'explained'

// ── Component ──

export default function Reconciliation() {
  const [file, setFile] = useState<File | null>(null)
  const [parsing, setParsing] = useState(false)
  const [error, setError] = useState('')
  const [invoice, setInvoice] = useState<ParsedInvoice | null>(null)
  const [orders, setOrders] = useState<Order[]>([])
  const [result, setResult] = useState<ReconciliationResult | null>(null)
  const [filter, setFilter] = useState<FilterTab>('all')
  const [searchTerm, setSearchTerm] = useState('')
  const [dragOver, setDragOver] = useState(false)
  const [saving, setSaving] = useState(false)
  const [saved, setSaved] = useState(false)
  const [parsedPeriod, setParsedPeriod] = useState<{ start: Date; end: Date } | null>(null)
  const [showHistory, setShowHistory] = useState(false)
  const [history, setHistory] = useState<SavedReconciliation[]>([])
  const [loadingHistory, setLoadingHistory] = useState(false)
  const [updatingPrices, setUpdatingPrices] = useState<Set<string>>(new Set())
  const [broaderSearch, setBroaderSearch] = useState(false)
  const [deptBreakdownOpen, setDeptBreakdownOpen] = useState(true)
  const [uniformMinOpen, setUniformMinOpen] = useState(true)
  const [d140Report, setD140Report] = useState<D140Report | null>(null)
  const [d140Loading, setD140Loading] = useState(false)
  const [showD140Prompt, setShowD140Prompt] = useState(false)
  const [lastSavedRecId, setLastSavedRecId] = useState<string | null>(null)
  const [d140Saving, setD140Saving] = useState(false)
  const [d140Saved, setD140Saved] = useState(false)

  // Resolution tracking
  const [notFoundResolutions, setNotFoundResolutions] = useState<Record<string, Resolution>>({})
  const [missingResolutions, setMissingResolutions] = useState<Record<string, Resolution>>({})
  const [challengedItems, setChallengedItems] = useState<Set<string>>(new Set()) // "nf:{key}" or "miss:{orderId}" or "mm:{key}"
  // Per-line notes (keyed by notFoundKey) — shown as a flag on the row, persisted in
  // reconciliations.line_resolutions and restored when the same invoice is re-uploaded.
  const [lineNotes, setLineNotes] = useState<Record<string, string>>({})
  // created_at of the saved reconciliation whose per-line work was restored (banner)
  const [restoredFrom, setRestoredFrom] = useState<string | null>(null)

  // "Charge to" tags + notes per invoice line (reconciliation_line_notes, autosaved), keyed by
  // the stable line key. The ref mirrors state so reconcile() always sees the latest notes.
  const [noteRows, setNoteRows] = useState<Record<string, LineNote>>({})
  const noteRowsRef = useRef<Record<string, LineNote>>({})
  const [notesAvailable, setNotesAvailable] = useState(true) // false until the migration is run
  const [groupFolios, setGroupFolios] = useState<Record<string, GroupFolio>>({})
  const groupFoliosRef = useRef<Record<string, GroupFolio>>({})
  const folioSaveQueue = useRef<Promise<unknown>>(Promise.resolve())
  const applyGroupFolios = (rows: Record<string, GroupFolio>) => { groupFoliosRef.current = rows; setGroupFolios(rows) }
  const [knownGroups, setKnownGroups] = useState<string[]>([])
  const [noteModal, setNoteModal] = useState<ReconciliationRow | null>(null)
  const [noteForm, setNoteForm] = useState<{ type: ChargeType; room: string; group: string; note: string; orderId: string | null; recharge: '' | 'recharged' | 'not_yet' | 'not_chargeable'; folio: string; kg: string }>({ type: 'note', room: '', group: '', note: '', orderId: null, recharge: '', folio: '', kg: '' })
  // Phase 1 tables (migration 2026-11-08) present? Enables service wash / who-pays fields,
  // history, autosaved invoice note, In-System-Only resolutions, credit notes.
  const [phase1, setPhase1] = useState(false)
  useEffect(() => { phase1Available().then(setPhase1) }, [])
  const [actions, setActions] = useState<ReconAction[]>([])
  const [orderRes, setOrderRes] = useState<Record<string, OrderResolutionRow>>({})
  const [expectedFromBefore, setExpectedFromBefore] = useState<{ row: OrderResolutionRow; order: Order | null }[]>([])
  const [draftSavedAt, setDraftSavedAt] = useState<string | null>(null)
  const draftTimer = useRef<ReturnType<typeof setTimeout> | null>(null)
  // Ticked invoice lines (by line key) and ticked In-System-Only orders (by order id)
  const [selectedLines, setSelectedLines] = useState<Set<string>>(new Set())
  const [selectedOrders, setSelectedOrders] = useState<Set<string>>(new Set())
  const [bulkModal, setBulkModal] = useState<null | 'explain' | 'note'>(null)
  const [bulkForm, setBulkForm] = useState<{ type: ChargeType; group: string; recharge: '' | 'recharged' | 'not_yet' | 'not_chargeable'; folio: string; note: string }>({ type: 'group', group: '', recharge: '', folio: '', note: '' })
  const [bulkSaving, setBulkSaving] = useState(false)
  const [bulkError, setBulkError] = useState('')
  const [creditLines, setCreditLines] = useState<CreditLine[] | null>(null)
  const [creditRefresh, setCreditRefresh] = useState(0)
  const [noteSaving, setNoteSaving] = useState(false)
  const [noteError, setNoteError] = useState('')
  const [noteCandidates, setNoteCandidates] = useState<Order[]>([])
  const [noteCandidateSearch, setNoteCandidateSearch] = useState('')
  // D140 VAT basis is unconfirmed: margins are labelled until the accounts team confirms
  const [d140IncludesVat, setD140IncludesVat] = useState(false)
  const [showChallengePanel, setShowChallengePanel] = useState(false)
  const [challengeEmail, setChallengeEmail] = useState('')

  const [showSaveConfirm, setShowSaveConfirm] = useState(false)

  // Free-text notes about this reconciliation / invoice (e.g. "ticket 7208 should be 6208",
  // "napkin rate billed at £0.22 not £0.215 — query with Goldstar"). Saved to
  // reconciliations.notes and printed in the PDF + Excel breakdown.
  const [reconciliationNote, setReconciliationNote] = useState('')

  // Add to System modal
  const [addModal, setAddModal] = useState<{ row: ReconciliationRow; index: number } | null>(null)
  const [addModalDept, setAddModalDept] = useState('')
  const [addModalDocket, setAddModalDocket] = useState('')
  const [addModalDate, setAddModalDate] = useState('')
  const [addModalSaving, setAddModalSaving] = useState(false)
  // 'create' = make a new order; 'link' = attach this invoice line to an EXISTING order
  // (avoids duplicates, and handles wrong/changed ticket numbers). Linking stamps the
  // matcher's ref-key into the chosen order's notes so re-reconciliation picks it up.
  const [addModalMode, setAddModalMode] = useState<'create' | 'link'>('create')
  const [addModalLinkSearch, setAddModalLinkSearch] = useState('')
  const [addModalLinkOrderId, setAddModalLinkOrderId] = useState('')
  const [addModalNote, setAddModalNote] = useState('')
  // When linking: the docket/ticket to record on the order (lets the user correct a wrong
  // invoice ticket or keep ours), and whether to also sync the order's price to the invoice.
  const [addModalLinkDocket, setAddModalLinkDocket] = useState('')
  const [addModalLinkUpdatePrice, setAddModalLinkUpdatePrice] = useState(false)
  // Optional department correction when linking ('' = keep the order's current department)
  const [addModalLinkDept, setAddModalLinkDept] = useState('')
  // Link search hits the WHOLE database (not just this period's unmatched orders), so any
  // existing order — matched elsewhere, or from another month — can be found and linked.
  const [addModalLinkDbResults, setAddModalLinkDbResults] = useState<Order[]>([])
  // Guard: confirm before creating a new order when a likely existing order is shown
  const [addCreateAnyway, setAddCreateAnyway] = useState(false)
  const [addModalLinkSearching, setAddModalLinkSearching] = useState(false)
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

  // Link mode: search the WHOLE orders table (all dates) for the typed term, so the user
  // can link to any existing order — not just this period's unmatched ones. Debounced.
  const linkSectionType = addModal?.row.sectionType
  useEffect(() => {
    if (addModalMode !== 'link') { setAddModalLinkDbResults([]); return }
    const term = addModalLinkSearch.trim()
    if (term.length < 2 || !linkSectionType) { setAddModalLinkDbResults([]); setAddModalLinkSearching(false); return }
    let cancelled = false
    setAddModalLinkSearching(true)
    const handle = setTimeout(async () => {
      const like = `%${term.replace(/[%,]/g, '')}%`
      const { data } = await supabase.from('orders')
        .select('*, department:departments(*), order_items(*)')
        .eq('order_type', linkSectionType)
        .or(`docket_number.ilike.${like},staff_name.ilike.${like},guest_name.ilike.${like},room_number.ilike.${like}`)
        .order('created_at', { ascending: false })
        .limit(40)
      if (!cancelled) { setAddModalLinkDbResults((data as Order[]) ?? []); setAddModalLinkSearching(false) }
    }, 300)
    return () => { cancelled = true; clearTimeout(handle) }
  }, [addModalLinkSearch, addModalMode, linkSectionType])

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
    const notes = noteRowsRef.current
    const fetchedOrders = await fetchOrdersForReconciliation(invoice, period, broaderSearch, pickedOrderIds(notes))
    setOrders(fetchedOrders)
    // Pass original period as strictPeriod so broader-search orders don't appear in "In System Only"
    setResult(reconcile(invoice, fetchedOrders, broaderSearch && period ? { start: new Date(new Date(period.start).setUTCMonth(period.start.getUTCMonth() - 1)), end: period.end } : period, period, notesMapFor(invoice, notes)))
  }, [invoice, broaderSearch])

  const applyNoteRows = (rows: Record<string, LineNote>) => { noteRowsRef.current = rows; setNoteRows(rows) }

  async function handleFile(f: File) {
    if (!f.type.includes('pdf')) { setError('Please upload a PDF file'); return }
    setFile(f); setError(''); setParsing(true)
    setInvoice(null); setResult(null); setSaved(false); setShowHistory(false)
    setNotFoundResolutions({}); setMissingResolutions({}); setChallengedItems(new Set())
    setReconciliationNote(''); setLineNotes({}); setRestoredFrom(null)
    applyNoteRows({}); applyGroupFolios({}); setNotesAvailable(true)
    setActions([]); setOrderRes({}); setExpectedFromBefore([]); setDraftSavedAt(null); setSelectedLines(new Set()); setSelectedOrders(new Set())
    try {
      // Handles both Goldstar layouts (legacy text lines and the 2026-09 column table)
      const parsed = await parseInvoiceFile(f)
      console.log('[Reconciliation] Parsed metadata:', { layout: parsed.layout, invoiceNumber: parsed.invoiceNumber, invoiceDate: parsed.invoiceDate, invoicePeriod: parsed.invoicePeriod })
      if (parsed.sections.every(s => s.lines.length === 0)) {
        setError('Could not parse any invoice lines.'); setParsing(false); return
      }
      setInvoice(parsed)
      const period = parseInvoicePeriod(parsed.invoicePeriod) || derivePeriodFromLines(parsed)
      setParsedPeriod(period)
      // Line notes first: their order picks / room overrides feed the matcher
      let notes: Record<string, LineNote> = {}
      if (parsed.invoiceNumber) {
        const [{ notes: list, available }, folios] = await Promise.all([fetchLineNotes(parsed.invoiceNumber), fetchGroupFolios(parsed.invoiceNumber)])
        setNotesAvailable(available)
        notes = Object.fromEntries(list.map(n => [n.line_key, n]))
        applyGroupFolios(Object.fromEntries(folios.map(g => [g.group_name, g])))
      }
      applyNoteRows(notes)
      const fetchedOrders = await fetchOrdersForReconciliation(parsed, period, broaderSearch, pickedOrderIds(notes))
      setOrders(fetchedOrders)
      setResult(reconcile(parsed, fetchedOrders, broaderSearch && period ? { start: new Date(new Date(period.start).setUTCMonth(period.start.getUTCMonth() - 1)), end: period.end } : period, period, notesMapFor(parsed, notes)))

      // Restore previously saved per-line work (resolutions, challenges, notes) for this
      // invoice so re-uploading doesn't lose decisions already made.
      if (parsed.invoiceNumber) {
        const { data: prevRecs } = await supabase.from('reconciliations')
          .select('created_at, notes, line_resolutions')
          .eq('invoice_number', parsed.invoiceNumber)
          .order('created_at', { ascending: false }).limit(1)
        const prevRec = prevRecs?.[0] as { created_at: string; notes: string | null; line_resolutions?: LineResolutionsSnapshot | null } | undefined
        if (prevRec) {
          const lr = prevRec.line_resolutions
          if (lr) {
            if (lr.notFound) setNotFoundResolutions(lr.notFound)
            if (lr.missing) setMissingResolutions(lr.missing)
            if (Array.isArray(lr.challenged)) setChallengedItems(new Set(lr.challenged))
            if (lr.lineNotes) setLineNotes(lr.lineNotes)
          }
          if (prevRec.notes) setReconciliationNote(prevRec.notes)
          setRestoredFrom(prevRec.created_at)
        }
        // Phase 1: autosaved invoice note (newer than the last Save wins), history,
        // In-System-Only resolutions, and items expected from earlier invoices
        if (await phase1Available()) {
          const inv = parsed.invoiceNumber
          const [draft, acts, res, expected] = await Promise.all([loadDraft(inv), fetchActions(inv), fetchOrderResolutions(inv), fetchOpenExpected(inv)])
          if (draft && (!prevRec || draft.updated_at > prevRec.created_at)) { setReconciliationNote(draft.note ?? ''); setDraftSavedAt(draft.updated_at) }
          setActions(acts)
          setOrderRes(Object.fromEntries(res.map(r => [r.order_id, r])))
          const types = new Set(parsed.sections.map(sec => sectionTypeToOrderType(sec.type)))
          if (expected.length) {
            const { data: exOrders } = await supabase.from('orders').select('*, department:departments(*), order_items(*)').in('id', expected.map(e => e.order_id))
            const byId = new Map(((exOrders as Order[] | null) ?? []).map(o => [o.id, o]))
            setExpectedFromBefore(expected.map(row => ({ row, order: byId.get(row.order_id) ?? null })).filter(x => x.order && types.has(x.order.order_type)))
          }
        }
      }
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to parse PDF')
    } finally { setParsing(false) }
  }

  function reset() {
    setFile(null); setInvoice(null); setOrders([]); setResult(null)
    setError(''); setFilter('all'); setSaved(false); setBroaderSearch(false)
    setUpdatingPrices(new Set()); setNotFoundResolutions({}); setMissingResolutions({})
    setAddModalDocket(''); setAddModalDate(''); setSearchTerm('')
    setAddModalMode('create'); setAddModalLinkOrderId(''); setAddModalNote(''); setAddModalLinkSearch('')
    setAddModalLinkDocket(''); setAddModalLinkUpdatePrice(false); setAddModalLinkDbResults([]); setAddModalLinkDept('')
    setReconciliationNote(''); setLineNotes({}); setRestoredFrom(null)
    setChallengedItems(new Set()); setAddModal(null); setShowSaveConfirm(false)
    setD140Report(null); setShowD140Prompt(false); setLastSavedRecId(null); setD140Saved(false)
    applyNoteRows({}); applyGroupFolios({}); setNoteModal(null)
    setActions([]); setOrderRes({}); setExpectedFromBefore([]); setDraftSavedAt(null); setSelectedLines(new Set()); setSelectedOrders(new Set())
  }

  // ── Line notes ("Charge to") ──
  const lineKeys = useMemo(() => buildLineKeys(invoice), [invoice])
  const refKeyMap = useMemo(() => lineRefKeys(invoice), [invoice])
  const noteFor = useCallback((line: InvoiceLine): LineNote | undefined => {
    const key = lineKeys.get(line)
    return key ? noteRows[key] : undefined
  }, [lineKeys, noteRows])
  // Notes whose line no longer appears (corrected / re-issued invoice) — never silently lost
  const unattachedNotes = useMemo(() => {
    const live = new Set(lineKeys.values())
    return Object.values(noteRows).filter(n => !live.has(n.line_key))
  }, [lineKeys, noteRows])

  function openNoteModal(row: ReconciliationRow) {
    const n = noteFor(row.invoiceLine)
    const noRoomGuest = !row.invoiceLine.ticket && row.sectionType === 'guest_laundry'
    setNoteForm({
      type: n?.charge_type ?? (noRoomGuest ? 'room_missing' : 'note'),
      room: n?.room_override ?? '', group: n?.group_name ?? '', note: n?.note ?? '', orderId: n?.order_id ?? null,
      recharge: n?.recharge_status ?? '', folio: n?.folio_ref ?? '', kg: n?.weight_kg != null ? String(n.weight_kg) : '',
    })
    setNoteError(''); setNoteCandidateSearch(''); setNoteCandidates([])
    setNoteModal(row)
    fetchKnownGroupNames().then(setKnownGroups)
    // "Who could it be": guest orders from the invoice month ±1 day
    if (row.sectionType === 'guest_laundry' && parsedPeriod) {
      const from = new Date(parsedPeriod.start.getTime() - DAY_MS).toISOString()
      const to = new Date(parsedPeriod.end.getTime() + DAY_MS).toISOString()
      supabase.from('orders').select('*, department:departments(*), order_items(*)')
        .eq('order_type', 'guest_laundry').gte('created_at', from).lte('created_at', to)
        .order('created_at', { ascending: true }).limit(500)
        .then(({ data }) => setNoteCandidates((data as Order[] | null) ?? []))
    }
  }

  const saveLineNote = useCallback(async (remove = false) => {
    if (!noteModal || !invoice) return
    const line = noteModal.invoiceLine
    const key = lineKeys.get(line)
    if (!key) return
    if (!invoice.invoiceNumber) { setNoteError('This invoice has no invoice number, so notes cannot be saved against it.'); return }
    if (!notesAvailable) { setNoteError('The line-notes table does not exist yet. Run db/migrations/2026-11-05_reconciliation_line_notes.sql in Supabase first.'); return }
    const f = noteForm
    const room = f.room.trim().toUpperCase()
    const group = f.group.trim()
    if (!remove) {
      if (f.type === 'room_missing' && !room && !f.orderId) { setNoteError('Type the room number, or pick the guest order below.'); return }
      if ((f.type === 'group' || f.type === 'service_wash') && !group) { setNoteError('Enter who pays (group / account).'); return }
      if (f.type === 'other' && !f.note.trim()) { setNoteError('A note is required: why is this charge accepted?'); return }
    }
    setNoteSaving(true); setNoteError('')
    const isEmpty = f.type === 'note' && !f.note.trim()
    let err: string | null
    const next = { ...noteRowsRef.current }
    if (remove || isEmpty) {
      err = await deleteLineNote(invoice.invoiceNumber, key)
      if (!err) { delete next[key]; logAction({ invoice_number: invoice.invoiceNumber, line_key: key, action: 'Cleared tag / note' }) }
    } else {
      const { data: { user } } = await supabase.auth.getUser()
      const n: LineNote = {
        invoice_number: invoice.invoiceNumber, line_key: key,
        line_date: line.date, ticket: line.ticket || null, guest_label: line.guestInfo ?? null,
        description: line.description || null, net: line.net,
        charge_type: f.type,
        room_override: f.type === 'room_missing' ? (room || null) : null,
        group_name: isExplainedType(f.type) ? (group || null) : null,
        note: f.note.trim() || null,
        order_id: f.type === 'room_missing' ? f.orderId : null,
        updated_by: user?.email ?? null,
      }
      if (phase1 && isExplainedType(f.type)) {
        n.recharge_status = f.recharge || null
        n.folio_ref = f.folio.trim() || null
        n.weight_kg = f.kg.trim() && !isNaN(Number(f.kg)) ? Number(f.kg) : null
      }
      err = await upsertLineNote(n)
      if (!err) logAction({ invoice_number: invoice.invoiceNumber, line_key: key, action: chargeLabel(n), detail: [n.note, n.recharge_status ? `charged on: ${n.recharge_status.replace('_', ' ')}` : '', n.folio_ref ? `folio ${n.folio_ref}` : ''].filter(Boolean).join(' · ') || null })
      if (!err) next[key] = { ...n, updated_at: new Date().toISOString() }
    }
    setNoteSaving(false)
    if (err) { setNoteError(`Could not save: ${err}`); return }
    applyNoteRows(next)
    // Re-match with the new tag before closing, so the row's result is visible on close
    setNoteSaving(true)
    await refetchAndReconcile()
    if (invoice.invoiceNumber) fetchActions(invoice.invoiceNumber).then(setActions)
    setNoteSaving(false)
    setNoteModal(null)
  }, [noteModal, invoice, lineKeys, notesAvailable, noteForm, refetchAndReconcile, phase1])

  const removeUnattachedNote = useCallback(async (n: LineNote) => {
    const err = await deleteLineNote(n.invoice_number, n.line_key)
    if (err) { setPriceUpdateError(`Could not remove note: ${err}`); return }
    const next = { ...noteRowsRef.current }; delete next[n.line_key]
    applyNoteRows(next)
  }, [])

  // Each folio field saves on blur. Merge every patch into the LATEST values (ref, updated
  // optimistically) and run the upserts one after another, so quick successive edits can't
  // overwrite each other with a stale copy of the record.
  const saveGroupFolio = useCallback((groupName: string, patch: Partial<GroupFolio>) => {
    if (!invoice?.invoiceNumber || !notesAvailable) return
    const invoiceNumber = invoice.invoiceNumber
    const base: GroupFolio = groupFoliosRef.current[groupName] ?? { invoice_number: invoiceNumber, group_name: groupName, master_room: null, revenue_posted: null, folio_ref: null, note: null, updated_by: null }
    applyGroupFolios({ ...groupFoliosRef.current, [groupName]: { ...base, ...patch } })
    folioSaveQueue.current = folioSaveQueue.current.then(async () => {
      const { data: { user } } = await supabase.auth.getUser()
      const latest = groupFoliosRef.current[groupName]
      if (!latest) return
      const err = await upsertGroupFolio({ ...latest, updated_by: user?.email ?? null })
      if (err) setPriceUpdateError(`Could not save group details: ${err}`)
    })
  }, [invoice, notesAvailable])

  const isGuestInvoice = invoice?.sections.some(s => s.type === 'guest') ?? false

  const handleD140File = useCallback(async (f: File) => {
    if (!f.name.toLowerCase().endsWith('.pdf')) return
    setD140Loading(true)
    try {
      const report = await extractAndParseD140(f)
      setD140Report(report)
      console.log(`[D140] Parsed ${report.transactions.length} transactions, total £${report.grandTotal}`)
    } catch (e) {
      console.error('Failed to parse D140 report:', e)
    } finally {
      setD140Loading(false)
    }
  }, [])

  // Cross-reference guest invoice lines with D140 Opera transactions
  const guestMarginData = useMemo(() => {
    if (!result || !d140Report || !isGuestInvoice) return null
    const guestRows = result.rows.filter(r => r.sectionType === 'guest_laundry' || r.invoiceLine.sectionType === 'guest')
    // VAT basis of D140 amounts is unconfirmed — margin uses the net-equivalent revenue
    const vatDiv = d140IncludesVat ? 1.2 : 1
    // D140 postings on a group's master folio room are that group's revenue, not a line's
    const masterRoomGroup = new Map<string, string>()
    for (const f of Object.values(groupFolios)) if (f.master_room) masterRoomGroup.set(canonicalDocket(f.master_room), f.group_name)
    const groupRevenueD140 = new Map<string, number>()
    // Index D140 transactions by room number
    const d140ByRoom = new Map<string, D140Transaction[]>()
    for (const t of d140Report.transactions) {
      if (t.isCredit) continue // skip corrections/refunds
      const grp = masterRoomGroup.get(canonicalDocket(t.roomNumber))
      if (grp) { groupRevenueD140.set(grp, (groupRevenueD140.get(grp) ?? 0) + t.amount); continue }
      if (!d140ByRoom.has(t.roomNumber)) d140ByRoom.set(t.roomNumber, [])
      d140ByRoom.get(t.roomNumber)!.push(t)
    }

    const matched: { invoiceLine: typeof guestRows[0]; d140: D140Transaction; room: string; margin: number; marginPct: number }[] = []
    const invoiceOnly: typeof guestRows[0][] = []
    const d140Only: D140Transaction[] = []
    const usedD140 = new Set<D140Transaction>()
    const groupRows = new Map<string, typeof guestRows>()

    // Closest-date posting for the room, then closest amount
    const takeD140 = (room: string, row: typeof guestRows[0]) => {
      const lineDay = invoiceLineDay(row.invoiceLine.date)
      const cands = (d140ByRoom.get(room) ?? []).filter(t => !usedD140.has(t))
      cands.sort((a, b) => {
        const da = lineDay == null ? 0 : Math.abs((d140Day(a.date) ?? lineDay) - lineDay)
        const db = lineDay == null ? 0 : Math.abs((d140Day(b.date) ?? lineDay) - lineDay)
        return da - db || Math.abs(a.amount - row.invoiceLine.gross) - Math.abs(b.amount - row.invoiceLine.gross)
      })
      const d140 = cands[0]
      if (!d140) return false
      usedD140.add(d140)
      const revenueNet = d140.amount / vatDiv
      const margin = revenueNet - row.invoiceLine.net
      const marginPct = revenueNet > 0 ? (margin / revenueNet) * 100 : 0
      matched.push({ invoiceLine: row, d140, room, margin: +margin.toFixed(2), marginPct: +marginPct.toFixed(1) })
      return true
    }

    // Pass A: lines with the room printed on the invoice. Pass B: "room missing" lines with a
    // room typed in — matched after, so they can't take a genuine line's posting.
    const overrideRows: typeof guestRows = []
    for (const row of guestRows) {
      const n = noteFor(row.invoiceLine)
      if (n && (n.charge_type === 'group' || n.charge_type === 'house' || n.charge_type === 'other')) {
        const name = chargeBucket(n, row.invoiceLine) ?? 'Other'
        if (!groupRows.has(name)) groupRows.set(name, [])
        groupRows.get(name)!.push(row)
        continue
      }
      if (n?.charge_type === 'room_missing' && n.room_override) { overrideRows.push(row); continue }
      if (!row.invoiceLine.ticket || !takeD140(row.invoiceLine.ticket, row)) invoiceOnly.push(row)
    }
    for (const row of overrideRows) {
      if (!takeD140(noteFor(row.invoiceLine)!.room_override!, row)) invoiceOnly.push(row)
    }

    // Find D140 entries not matched to any invoice line
    for (const t of d140Report.transactions) {
      if (!t.isCredit && !usedD140.has(t) && !masterRoomGroup.has(canonicalDocket(t.roomNumber))) d140Only.push(t)
    }

    // Per group: D140 postings on the master room, else the manually entered revenue
    const groups = [...groupRows.entries()].map(([bucket, rows]) => {
      const groupName = bucket.startsWith('Group: ') ? bucket.slice(7) : null
      const folio = groupName ? groupFolios[groupName] : undefined
      const auto = groupName ? groupRevenueD140.get(groupName) : undefined
      const revenue = auto ?? folio?.revenue_posted ?? null
      const cost = rows.reduce((s, r) => s + r.invoiceLine.net, 0)
      const margin = revenue != null ? +(revenue / vatDiv - cost).toFixed(2) : null
      return { bucket, groupName, rows, cost: +cost.toFixed(2), revenue, revenueSource: auto != null ? 'D140 master room' : revenue != null ? 'Entered manually' : null, masterRoom: folio?.master_room ?? null, folioRef: folio?.folio_ref ?? null, margin }
    })

    const groupsWithRevenue = groups.filter(g => g.revenue != null)
    const totalCost = matched.reduce((s, m) => s + m.invoiceLine.invoiceLine.net, 0) + groupsWithRevenue.reduce((s, g) => s + g.cost, 0)
    const totalRevenue = matched.reduce((s, m) => s + m.d140.amount, 0) + groupsWithRevenue.reduce((s, g) => s + (g.revenue ?? 0), 0)
    const totalMargin = totalRevenue / vatDiv - totalCost
    const avgMarginPct = totalRevenue > 0 ? (totalMargin / (totalRevenue / vatDiv)) * 100 : 0

    return { matched, invoiceOnly, d140Only, groups, totalCost, totalRevenue, totalMargin, avgMarginPct }
  }, [result, d140Report, isGuestInvoice, noteFor, groupFolios, d140IncludesVat])

  const handleSaveD140 = useCallback(async () => {
    if (!guestMarginData || !lastSavedRecId || !d140Report) return
    setD140Saving(true)
    const d140Summary = {
      matched: guestMarginData.matched.map(m => ({
        room: m.invoiceLine.invoiceLine.ticket,
        guestName: m.d140.guestName,
        date: m.invoiceLine.invoiceLine.date,
        cost: m.invoiceLine.invoiceLine.net,
        revenue: m.d140.amount,
        margin: m.margin,
        marginPct: m.marginPct,
        description: m.invoiceLine.invoiceLine.description,
      })),
      invoiceOnly: guestMarginData.invoiceOnly.map(row => ({
        room: row.invoiceLine.ticket,
        description: row.invoiceLine.guestInfo || row.invoiceLine.description,
        cost: row.invoiceLine.net,
      })),
      d140Only: guestMarginData.d140Only.map(t => ({
        room: t.roomNumber, guestName: t.guestName, date: t.date, revenue: t.amount,
      })),
      totals: {
        totalCost: +guestMarginData.totalCost.toFixed(2),
        totalRevenue: +guestMarginData.totalRevenue.toFixed(2),
        totalMargin: +guestMarginData.totalMargin.toFixed(2),
        avgMarginPct: +guestMarginData.avgMarginPct.toFixed(1),
        matchedCount: guestMarginData.matched.length,
        invoiceOnlyCount: guestMarginData.invoiceOnly.length,
        d140OnlyCount: guestMarginData.d140Only.length,
      },
      groups: guestMarginData.groups.map(g => ({
        group: g.bucket, lines: g.rows.length, cost: g.cost, revenue: g.revenue,
        revenueSource: g.revenueSource, masterRoom: g.masterRoom, folioRef: g.folioRef, margin: g.margin,
      })),
      d140AmountsIncludeVat: d140IncludesVat,
      vatBasisConfirmed: false,
      d140Period: d140Report.period,
      d140TransactionCount: d140Report.transactions.length,
      d140GrandTotal: d140Report.grandTotal,
    }
    const { error } = await supabase.from('reconciliations').update({
      d140_summary: d140Summary,
      d140_total_revenue: +guestMarginData.totalRevenue.toFixed(2),
      d140_total_cost: +guestMarginData.totalCost.toFixed(2),
      d140_total_margin: +guestMarginData.totalMargin.toFixed(2),
      d140_margin_pct: +guestMarginData.avgMarginPct.toFixed(1),
    }).eq('id', lastSavedRecId)
    if (error) console.error('Failed to save D140 analysis:', error)
    else setD140Saved(true)
    setD140Saving(false)
  }, [guestMarginData, lastSavedRecId, d140Report, d140IncludesVat])

  // Guest room + day pairs that already matched: a second unmatched line for the same room
  // and day is most likely a 2nd bag the tablet recorded as one order.
  // In System Only: the same ticket in the same service was matched to another order, so
  // this one is probably a ticket typo (Sept 2026: Front Office 1563 vs Main Kitchen 1563).
  const matchedTickets = useMemo(() => {
    const m = new Map<string, Order>()
    for (const r of result?.rows ?? []) if (r.order && r.order.order_type !== 'guest_laundry') m.set(`${r.order.order_type}|${canonicalDocket(r.order.docket_number)}`, r.order)
    return m
  }, [result])
  const duplicateTicketHint = (o: Order): string | null => {
    if (o.order_type === 'guest_laundry') return null
    const other = matchedTickets.get(`${o.order_type}|${canonicalDocket(o.docket_number)}`)
    if (!other || other.id === o.id) return null
    return `ticket also used by ${other.department?.name ?? 'another order'} ${format(new Date(other.created_at), 'dd/MM')} (matched): typo?`
  }

  const matchedRoomDays = useMemo(() => new Set((result?.rows ?? [])
    .filter(r => r.order && r.sectionType === 'guest_laundry' && r.invoiceLine.ticket)
    .map(r => `${r.invoiceLine.date}|${r.invoiceLine.ticket}`)), [result])

  // ── Bulk: explain / add note on all ticked lines (one note, required) ──
  const applyBulk = async () => {
    if (!invoice?.invoiceNumber || !bulkModal) return
    if (!notesAvailable) { setBulkError('The line-notes table is not available.'); return }
    if (!bulkForm.note.trim()) { setBulkError('A note is required for actions on several lines.'); return }
    if (bulkModal === 'explain' && (bulkForm.type === 'group' || bulkForm.type === 'service_wash') && !bulkForm.group.trim()) { setBulkError('Enter who pays (group / account).'); return }
    setBulkSaving(true); setBulkError('')
    const { data: { user } } = await supabase.auth.getUser()
    const next = { ...noteRowsRef.current }
    for (const [line, key] of lineKeys) {
      if (!selectedLines.has(key)) continue
      const existing = next[key]
      const n: LineNote = bulkModal === 'note' && existing
        ? { ...existing, note: bulkForm.note.trim(), updated_by: user?.email ?? null }
        : {
          invoice_number: invoice.invoiceNumber, line_key: key, line_date: line.date, ticket: line.ticket || null,
          guest_label: line.guestInfo ?? null, description: line.description || null, net: line.net,
          charge_type: bulkModal === 'explain' ? bulkForm.type : 'note', room_override: null,
          group_name: bulkModal === 'explain' ? (bulkForm.group.trim() || null) : null,
          note: bulkForm.note.trim(), order_id: null, updated_by: user?.email ?? null,
        }
      if (bulkModal === 'explain' && phase1) { n.recharge_status = bulkForm.recharge || null; n.folio_ref = bulkForm.folio.trim() || null }
      const err = await upsertLineNote(n)
      if (err) { setBulkError(`Could not save: ${err}`); setBulkSaving(false); applyNoteRows(next); return }
      next[key] = { ...n, updated_at: new Date().toISOString() }
      logAction({ invoice_number: invoice.invoiceNumber, line_key: key, action: bulkModal === 'explain' ? `${chargeLabel(n)} (bulk)` : 'Note (bulk)', detail: n.note })
    }
    applyNoteRows(next)
    await refetchAndReconcile()
    fetchActions(invoice.invoiceNumber).then(setActions)
    setBulkSaving(false); setBulkModal(null); setSelectedLines(new Set())
  }

  // ── Credit note request: one line per ticked invoice line, reason + amount pre-filled ──
  const openCreditRequestFor = (onlyKey?: string) => () => openCreditRequest(onlyKey ? new Set([onlyKey]) : undefined)
  const openCreditRequest = (keys?: Set<string>) => {
    if (!result) return
    const wanted = keys ?? selectedLines
    const lines: CreditLine[] = []
    for (const r of result.rows) {
      const key = lineKeys.get(r.invoiceLine)
      if (!key || !wanted.has(key)) continue
      const invQty = r.invoiceLine.items.reduce((sum, it) => sum + it.quantity, 0)
      const sysQty = (r.order?.order_items ?? []).reduce((sum, it) => sum + (it.quantity_sent ?? 0), 0)
      let reason: CreditLine['reason'] = 'not_ours', credit = r.invoiceLine.net, text = ''
      if (r.status === 'price_mismatch') { reason = 'wrong_price'; credit = Math.max(0, +(r.invoiceLine.net - r.systemTotal).toFixed(2)); text = `invoiced £${r.invoiceLine.net.toFixed(2)}, our records £${r.systemTotal.toFixed(2)}` }
      else if (r.order && invQty > sysQty && sysQty > 0) { reason = 'wrong_quantity'; credit = +((invQty - sysQty) / invQty * r.invoiceLine.net).toFixed(2); text = `charged ${invQty}, sent ${sysQty}` }
      else if (r.order) { reason = 'other'; credit = 0 }
      lines.push({
        line_key: key, date: r.invoiceLine.date, ticket: r.invoiceLine.ticket,
        guest: [r.invoiceLine.guestInfo?.replace(/[()]/g, ''), r.invoiceLine.serviceNote].filter(Boolean).join(' '),
        description: r.invoiceLine.description, invoice_net: r.invoiceLine.net, reason, reason_text: text, credit_net: credit,
      })
    }
    if (lines.length) setCreditLines(lines)
  }
  const creditRequestButton = phase1 && invoice?.invoiceNumber
    ? <button onClick={() => openCreditRequest()} className="px-2.5 py-1 text-xs text-white bg-orange-600 rounded">Request credit note{'\u2026'}</button>
    : null

  const actionsByLine = useMemo(() => {
    const m = new Map<string, ReconAction[]>()
    for (const a of actions) if (a.line_key) { if (!m.has(a.line_key)) m.set(a.line_key, []); m.get(a.line_key)!.push(a) }
    return m
  }, [actions])

  const filteredRows = useMemo(() => {
    if (!result) return []
    let rows = result.rows
    if (filter === 'matched') rows = rows.filter(r => r.status === 'matched')
    else if (filter === 'mismatch') rows = rows.filter(r => r.status === 'price_mismatch')
    else if (filter === 'not_found') rows = rows.filter(r => r.status === 'not_found' && !isExplainedType(noteFor(r.invoiceLine)?.charge_type))
    else if (filter === 'explained') rows = rows.filter(r => r.status === 'not_found' && isExplainedType(noteFor(r.invoiceLine)?.charge_type))
    else if (filter === 'group') rows = rows.filter(r => chargeBucket(noteFor(r.invoiceLine), r.invoiceLine) != null)
    if (searchTerm) {
      const s = searchTerm.toLowerCase()
      rows = rows.filter(r =>
        r.invoiceLine.description?.toLowerCase().includes(s) ||
        r.invoiceLine.ticket?.toLowerCase().includes(s) ||
        r.invoiceLine.guestInfo?.toLowerCase().includes(s) ||
        noteFor(r.invoiceLine)?.group_name?.toLowerCase().includes(s) ||
        noteFor(r.invoiceLine)?.note?.toLowerCase().includes(s) ||
        r.order?.department?.name?.toLowerCase().includes(s) ||
        r.order?.staff_name?.toLowerCase().includes(s) ||
        r.order?.guest_name?.toLowerCase().includes(s) ||
        r.invoiceLine.net.toFixed(2).includes(s) ||
        r.systemTotal.toFixed(2).includes(s)
      )
    }
    return rows
  }, [result, filter, searchTerm, noteFor])

  const filteredMissing = useMemo(() => {
    if (!result || !searchTerm) return result?.missingFromInvoice ?? []
    const s = searchTerm.toLowerCase()
    return result.missingFromInvoice.filter(o =>
      o.docket_number?.toLowerCase().includes(s) ||
      o.department?.name?.toLowerCase().includes(s) ||
      o.staff_name?.toLowerCase().includes(s) ||
      o.guest_name?.toLowerCase().includes(s) ||
      (o.order_items || []).some(i => i.item_name?.toLowerCase().includes(s)) ||
      computeOrderCost(o).toFixed(2).includes(s)
    )
  }, [result, searchTerm])

  // ── Group & No-room charges: tagged lines + guest lines printed without a room ──
  const chargeGroups = useMemo(() => {
    if (!result) return []
    const map = new Map<string, { bucket: string; groupName: string | null; rows: ReconciliationRow[]; net: number; vat: number; gross: number }>()
    for (const r of result.rows) {
      const bucket = chargeBucket(noteFor(r.invoiceLine), r.invoiceLine)
      if (!bucket) continue
      if (!map.has(bucket)) map.set(bucket, { bucket, groupName: bucket.startsWith('Group: ') ? bucket.slice(7) : null, rows: [], net: 0, vat: 0, gross: 0 })
      const g = map.get(bucket)!
      g.rows.push(r); g.net += r.invoiceLine.net; g.vat += r.invoiceLine.vat; g.gross += r.invoiceLine.gross
    }
    // Groups first (A–Z), then house / other / room-added, "not yet assigned" last
    const rank = (b: string) => b.startsWith('Group: ') ? 0 : b.startsWith('No room') ? 3 : b.startsWith('Room missing') ? 2 : 1
    return [...map.values()].sort((a, b) => rank(a.bucket) - rank(b.bucket) || a.bucket.localeCompare(b.bucket))
  }, [result, noteFor])

  // Same groups, flattened for the PDF section and the Excel "Group Charges" sheet
  const pdfChargeGroups = useMemo<PdfChargeGroup[]>(() => chargeGroups.map(g => {
    const folio = g.groupName ? groupFolios[g.groupName] : undefined
    return {
      bucket: g.bucket, net: +g.net.toFixed(2), vat: +g.vat.toFixed(2), gross: +g.gross.toFixed(2),
      masterRoom: folio?.master_room ?? null, revenuePosted: folio?.revenue_posted ?? null, folioRef: folio?.folio_ref ?? null,
      lines: g.rows.map(r => {
        const n = noteFor(r.invoiceLine)
        return {
          date: r.invoiceLine.date,
          ticket: r.invoiceLine.ticket || (n?.room_override ? `${n.room_override}*` : ''),
          guest: [r.invoiceLine.guestInfo, r.invoiceLine.serviceNote].filter(Boolean).join(' '),
          description: r.invoiceLine.description,
          net: r.invoiceLine.net, vat: r.invoiceLine.vat, gross: r.invoiceLine.gross,
          note: n?.note ?? '',
        }
      }),
    }
  }), [chargeGroups, groupFolios, noteFor])

  // Small print per department ("Incl. Group: X £120.00 · No room — not yet assigned £41.70")
  const chargeDetailByDept = useMemo(() => {
    const perDept = new Map<string, Map<string, number>>()
    for (const g of chargeGroups) {
      for (const r of g.rows) {
        const dept = r.order?.department?.name || 'Unallocated'
        if (!perDept.has(dept)) perDept.set(dept, new Map())
        const m = perDept.get(dept)!
        m.set(g.bucket, (m.get(g.bucket) ?? 0) + r.invoiceLine.net)
      }
    }
    const out = new Map<string, string>()
    for (const [dept, m] of perDept) out.set(dept, 'Incl. ' + [...m.entries()].map(([b, v]) => `${b} £${v.toFixed(2)}`).join(' · '))
    return out
  }, [chargeGroups])

  const departmentDisplayRows = useMemo<DepartmentDisplayRow[]>(() => {
    if (!result) return []
    return buildDepartmentDisplayRows(result.departmentBreakdown, result.rows, chargeDetailByDept)
  }, [result, chargeDetailByDept])

  // ── Price-discrepancy pattern detector ──
  // Reconciliation should ideally have NO discrepancies. When it does, look for a
  // SYSTEMATIC cause: the same item priced consistently differently in our system vs the
  // invoice (e.g. napkins at £0.22 in our catalogue but £0.215 on every invoice line).
  // Grouping by item + per-unit gap surfaces a stale rate to correct, vs one-off errors.
  const pricePatterns = useMemo(() => {
    if (!result) return []
    interface Pat { item: string; count: number; sysUnitSum: number; invUnitSum: number; totalImpact: number }
    const map = new Map<string, Pat>()
    for (const r of result.rows) {
      if (r.status !== 'price_mismatch' || !r.order) continue
      const items = r.invoiceLine.items
      // Only single-item lines give a clean per-unit rate
      if (items.length !== 1) continue
      const qty = items[0].quantity
      if (qty <= 0) continue
      const invUnit = r.invoiceLine.net / qty
      const sysUnit = r.systemTotal / qty
      if (Math.abs(invUnit - sysUnit) < 0.001) continue
      const name = items[0].name.toLowerCase().replace(/s$/, '')
      const key = `${name}|${sysUnit.toFixed(3)}|${invUnit.toFixed(3)}`
      if (!map.has(key)) map.set(key, { item: items[0].name, count: 0, sysUnitSum: 0, invUnitSum: 0, totalImpact: 0 })
      const p = map.get(key)!
      p.count++; p.sysUnitSum += sysUnit; p.invUnitSum += invUnit; p.totalImpact += r.difference
    }
    return Array.from(map.values())
      .filter(p => p.count >= 3) // a "pattern" = at least 3 lines with the same gap
      .map(p => ({
        item: p.item, count: p.count,
        sysUnit: p.sysUnitSum / p.count,
        invUnit: p.invUnitSum / p.count,
        totalImpact: +p.totalImpact.toFixed(2),
      }))
      .sort((a, b) => Math.abs(b.totalImpact) - Math.abs(a.totalImpact))
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

    const WEEKLY_MIN = NAPKIN_WEEKLY_MINIMUM
    const UNIT_RATE = NAPKIN_RATE

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
      // TopUp uses the fixed NAPKIN_TOPUP_SPLIT — a split department with no orders
      // this week still gets a (zero-sent) row carrying its share.
      const topUpShares = splitNapkinTopUp(week.topUpNet)
      if (week.topUpNet > 0) {
        const presentNames = new Set(Array.from(deptMap.values()).map(d => d.name))
        for (const [name] of NAPKIN_TOPUP_SPLIT) {
          if (!presentNames.has(name)) deptMap.set(`_split:${name}`, { name, qty: 0 })
        }
      }
      week.deptBreakdown = Array.from(deptMap.entries()).map(([id, d]) => {
        const splitPct = NAPKIN_TOPUP_SPLIT.find(([name]) => name === d.name)?.[1] ?? 0
        const actualCost = +(d.qty * UNIT_RATE).toFixed(2)
        const topUpAlloc = topUpShares.get(d.name) ?? 0
        return {
          deptId: id === '_none' || id.startsWith('_split:') ? null : id,
          deptName: d.name,
          sentQty: d.qty,
          pctShare: splitPct * 100,
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
    // Keyed by name: a split department can appear with a null id in weeks it sent nothing
    const deptTotalMap = new Map<string, { id: string | null; name: string; sent: number; topUp: number; actual: number }>()
    for (const week of weeks) {
      for (const d of week.deptBreakdown) {
        const key = d.deptName
        if (!deptTotalMap.has(key)) deptTotalMap.set(key, { id: d.deptId, name: d.deptName, sent: 0, topUp: 0, actual: 0 })
        const t = deptTotalMap.get(key)!
        if (!t.id) t.id = d.deptId
        t.sent += d.sentQty
        t.topUp += d.topUpAlloc
        t.actual += d.actualCost
      }
    }
    const totalSentAll = Array.from(deptTotalMap.values()).reduce((s, d) => s + d.sent, 0)
    const deptTotals = Array.from(deptTotalMap.values()).map(d => ({
      deptId: d.id,
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
  // Napkins by week: what Goldstar would charge using OUR count (the weekly minimum still
  // applies on weeks that carry a top-up), and the £ difference. Below the minimum on both
  // counts the bill is identical, so piece differences only matter above it.
  const napkinOverUnder = (w: { invoiceSentQty: number; systemSentQty: number; topUpQty: number; totalChargedQty: number }) => {
    if (!napkinSummary || w.systemSentQty <= 0) return null
    const ourQty = w.topUpQty > 0 ? Math.max(w.systemSentQty, napkinSummary.weeklyMinimum) : w.systemSentQty
    return { ourQty, pounds: +((w.totalChargedQty - ourQty) * napkinSummary.unitRate).toFixed(2) }
  }
  const napkinMonth = (() => {
    let ourQty = 0, pounds = 0, weeks = 0
    for (const w of napkinSummary?.weeks ?? []) {
      const ow = napkinOverUnder(w)
      if (!ow) continue
      ourQty += ow.ourQty; pounds += ow.pounds; weeks++
    }
    return { ourQty, pounds: +pounds.toFixed(2), weeks }
  })()

  const uniformMinSummary = useMemo(() => {
    if (!result || !invoice) return null
    const staffSection = invoice.sections.find(s => s.type === 'staff')
    if (!staffSection || !staffSection.lines.some(l => l.isTopUp)) return null

    const ITEM_KEYS = ['chef jacket', 'apron', 'chef trouser'] as const
    type ItemKey = typeof ITEM_KEYS[number]
    const MINIMUMS: Record<ItemKey, number> = CHEF_WEEKLY_MINIMUMS
    const PRICES: Record<ItemKey, number> = CHEF_TOPUP_RATES
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

  // ── Save reconciliation ──
  const saveReconciliation = useCallback(async () => {
    if (!result || !invoice) return
    setSaving(true)
    const totalTopUp = result.topUpCharges.reduce((s, l) => s + l.net, 0)
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

    let invoicePath: string | null = null
    if (file) {
      const path = `invoices/${ts}-${file.name}`
      const { error: uploadErr } = await supabase.storage.from('reconciliations').upload(path, file, { contentType: 'application/pdf' })
      if (!uploadErr) invoicePath = path
    }

    let reportPath: string | null = null
    try {
      const deptRows = buildDepartmentDisplayRows(result.departmentBreakdown, result.rows, chargeDetailByDept)
      const uniformMinWeeksForPdf = uniformMinSummary?.weeks.map(w => ({
        dateRange: w.dateRange,
        items: uniformMinSummary.ITEM_KEYS.map(k => ({
          key: k.charAt(0).toUpperCase() + k.slice(1),
          sent: w.invoiceSent[k], topUp: w.topUp[k], min: uniformMinSummary.MINIMUMS[k],
        })),
        topUpNet: w.topUpNet,
      }))
      const napkinWeeksForPdf = napkinSummary?.weeks.map(w => ({
        dateRange: w.dateRange,
        invoiceSentQty: w.invoiceSentQty,
        topUpQty: w.topUpQty,
        topUpNet: w.topUpNet,
        totalChargedQty: w.totalChargedQty,
        totalNet: w.totalNet,
        deptBreakdown: w.deptBreakdown.map(d => ({
          deptName: d.deptName, sentQty: d.sentQty, topUpAlloc: d.topUpAlloc, totalCost: d.totalCost,
        })),
      }))
      const saveTotalTopUp = result.topUpCharges.reduce((s, l) => s + l.net, 0)
      const saveStatedNet = invoice.totals.net
      const saveGrandNet = saveStatedNet > 0 ? saveStatedNet : (result.invoiceTotal + saveTotalTopUp)
      const saveFinancials: FinancialTotals = {
        lineItemsNet: +result.invoiceTotal.toFixed(2),
        topUpNet: +saveTotalTopUp.toFixed(2),
        invoiceNet: +saveGrandNet.toFixed(2),
        invoiceVat: +(invoice.totals.vat > 0 ? invoice.totals.vat : saveGrandNet * 0.2).toFixed(2),
        invoiceGross: +(invoice.totals.gross > 0 ? invoice.totals.gross : saveGrandNet * 1.2).toFixed(2),
        systemNet: +result.systemTotal.toFixed(2),
      }
      const reportBlob = generateReconciliationPdfBlob(invoice, result, deptRows, napkinSummary?.deptTotals, uniformMinWeeksForPdf, napkinWeeksForPdf, saveFinancials, reconciliationNote.trim() || undefined, pdfChargeGroups)
      const rptName = `reports/${ts}-reconciliation-${invoice.invoiceNumber || 'report'}.pdf`
      const { error: rptErr } = await supabase.storage.from('reconciliations').upload(rptName, reportBlob, { contentType: 'application/pdf' })
      if (!rptErr) reportPath = rptName
    } catch (e) {
      console.error('Failed to upload PDF report:', e)
    }

    const insertPayload: Record<string, unknown> = {
      invoice_number: invoice.invoiceNumber, invoice_date: invoice.invoiceDate,
      invoice_period: invoice.invoicePeriod, created_by: user?.email || 'unknown',
      invoice_net: +result.invoiceTotal.toFixed(2), invoice_gross: +(result.invoiceTotal * 1.2).toFixed(2),
      system_total: +result.systemTotal.toFixed(2), topup_total: +totalTopUp.toFixed(2),
      matched_count: result.stats.matched, mismatch_count: result.stats.priceMismatch,
      not_found_count: result.stats.notFound, missing_count: result.stats.missing,
      invoice_file_path: invoicePath,
      report_file_path: reportPath,
      invoice_category: invoiceCategory,
      notes: reconciliationNote.trim() || null,
      // Per-line work snapshot — restored when this invoice is uploaded again
      line_resolutions: {
        notFound: notFoundResolutions,
        missing: missingResolutions,
        challenged: Array.from(challengedItems),
        // Line notes now live in reconciliation_line_notes; the jsonb copy is kept only
        // until that table exists (migration not run yet).
        lineNotes: notesAvailable ? {} : lineNotes,
      } satisfies LineResolutionsSnapshot,
      department_breakdown: result.departmentBreakdown.map(d => ({
        departmentName: d.departmentName, orderCount: d.orderCount,
        invoiceNet: +d.invoiceNet.toFixed(2), systemTotal: +d.systemTotal.toFixed(2),
        allocatedTopUp: d.allocatedTopUp, totalCostNet: d.totalCostNet, totalCostGross: d.totalCostGross,
      })),
    }
    let { data: savedRec, error: saveErr } = await supabase.from('reconciliations').insert(insertPayload).select('id').single()
    if (saveErr && /line_resolutions/i.test(saveErr.message || '')) {
      // DB migration not applied yet — save without the snapshot rather than losing the save
      delete insertPayload.line_resolutions
      ;({ data: savedRec, error: saveErr } = await supabase.from('reconciliations').insert(insertPayload).select('id').single())
    }
    if (saveErr) console.error('Failed to save reconciliation:', saveErr)
    if (savedRec) setLastSavedRecId(savedRec.id)

    if (savedRec && result.matchedOrderIds.length > 0) {
      const { error: stampErr } = await supabase.from('orders')
        .update({ reconciliation_id: savedRec.id })
        .in('id', result.matchedOrderIds)
      if (stampErr) console.error('Failed to stamp orders as reconciled:', stampErr)
    }

    if (savedRec && invoice.invoiceNumber && expectedFromBefore.length) {
      const found = expectedFromBefore.filter(x => x.order && result.matchedOrderIds.includes(x.order.id)).map(x => x.row)
      if (found.length) {
        await markExpectedFound(found, invoice.invoiceNumber)
        for (const f of found) logAction({ invoice_number: invoice.invoiceNumber, order_id: f.order_id, action: 'Expected order found', detail: `expected from ${f.invoice_number}` })
      }
    }
    if (savedRec && notesAvailable && invoice.invoiceNumber) {
      // Older per-line notes saved in the jsonb snapshot (keyed by notFoundKey) move into
      // the line-notes table once, so there is a single source of truth from now on.
      const migrated = { ...noteRowsRef.current }
      for (const row of result.rows) {
        const legacy = lineNotes[notFoundKey(row)]
        const key = lineKeys.get(row.invoiceLine)
        if (!legacy || !key || migrated[key]) continue
        const n: LineNote = {
          invoice_number: invoice.invoiceNumber, line_key: key, line_date: row.invoiceLine.date,
          ticket: row.invoiceLine.ticket || null, guest_label: row.invoiceLine.guestInfo ?? null,
          description: row.invoiceLine.description || null, net: row.invoiceLine.net,
          charge_type: 'note', room_override: null, group_name: null, note: legacy, order_id: null,
          updated_by: user?.email ?? null,
        }
        if (!(await upsertLineNote(n))) migrated[key] = n
      }

      // Copy each tag onto its matched order as ONE plain line (no internal keys or guest
      // names — order notes appear in staff status emails and on the tablet). Done on Save
      // only; the authoritative link stays in reconciliation_line_notes.
      const prefix = `Reconciliation ${invoice.invoiceNumber}:`
      for (const row of result.rows) {
        const key = lineKeys.get(row.invoiceLine)
        const n = key ? migrated[key] : undefined
        if (!n || !row.order) continue
        const text = `${prefix} ${chargeLabel(n)}${n.note ? ` — ${n.note}` : ''}`
        const kept = (row.order.notes ?? '').split('\n').filter(l => !l.startsWith(prefix))
        const newNotes = [...kept, text].filter(l => l.trim()).join('\n')
        if (newNotes === (row.order.notes ?? '')) continue
        const { error: noteErr } = await supabase.from('orders').update({ notes: newNotes }).eq('id', row.order.id)
        if (noteErr) { console.error('Failed to copy line note to order:', noteErr); continue }
        await supabase.from('reconciliation_line_notes').update({ mirrored_to_order_at: new Date().toISOString() })
          .eq('invoice_number', invoice.invoiceNumber).eq('line_key', n.line_key)
      }
      applyNoteRows(migrated)
    }

    if (savedRec) {
      // Remove any existing TopUp rows for this invoice (prevents duplicates on re-save)
      await supabase.from('reconciliation_topups').delete().eq('invoice_number', invoice.invoiceNumber)

      const topUpRows: any[] = []
      if (napkinSummary) {
        for (const w of napkinSummary.weeks) {
          if (w.topUpNet <= 0) continue
          topUpRows.push({
            reconciliation_id: savedRec.id,
            invoice_number: invoice.invoiceNumber,
            category: 'Linen Napkins',
            week_date_range: w.dateRange,
            week_start: w.weekStart?.toISOString().slice(0, 10) ?? null,
            week_end: w.weekEnd?.toISOString().slice(0, 10) ?? null,
            topup_net: +w.topUpNet.toFixed(2),
            topup_gross: +(w.topUpNet * 1.2).toFixed(2),
            sent_qty: w.invoiceSentQty,
            topup_qty: w.topUpQty,
          })
        }
      }
      if (uniformMinSummary) {
        for (const w of uniformMinSummary.weeks) {
          if (w.topUpNet <= 0) continue
          const totalSent = uniformMinSummary.ITEM_KEYS.reduce((s, k) => s + w.invoiceSent[k], 0)
          const totalTopUpQty = uniformMinSummary.ITEM_KEYS.reduce((s, k) => s + w.topUp[k], 0)
          topUpRows.push({
            reconciliation_id: savedRec.id,
            invoice_number: invoice.invoiceNumber,
            category: 'Kitchen Uniforms',
            week_date_range: w.dateRange,
            week_start: w.weekStart?.toISOString().slice(0, 10) ?? null,
            week_end: w.weekEnd?.toISOString().slice(0, 10) ?? null,
            topup_net: +w.topUpNet.toFixed(2),
            topup_gross: +(w.topUpNet * 1.2).toFixed(2),
            sent_qty: totalSent,
            topup_qty: totalTopUpQty,
            details: Object.fromEntries(uniformMinSummary.ITEM_KEYS.map(k => [
              k, { sent: w.invoiceSent[k], topUp: w.topUp[k] }
            ])),
          })
        }
      }
      if (topUpRows.length > 0) {
        const { error: topUpErr } = await supabase.from('reconciliation_topups').insert(topUpRows)
        if (topUpErr) console.error('Failed to save TopUp data:', topUpErr)
      }
    }

    setSaving(false); setSaved(true); loadHistory()
    // Prompt for D140 upload after saving a guest invoice
    if (invoice.sections.some(s => s.type === 'guest')) setShowD140Prompt(true)
  }, [result, invoice, file, loadHistory, napkinSummary, uniformMinSummary, reconciliationNote, notFoundResolutions, missingResolutions, challengedItems, lineNotes, notesAvailable, lineKeys, chargeDetailByDept, pdfChargeGroups, expectedFromBefore])

  // ── Adjusted totals considering resolutions ──
  const adjustedTotals = useMemo(() => {
    if (!result) return { unresolvedDiff: 0, resolvedCount: 0, acceptedTotal: 0, writtenOffTotal: 0, challengedCount: 0, explainedTotal: 0, explainedCount: 0 }

    let acceptedTotal = 0
    let writtenOffTotal = 0
    let resolvedCount = 0
    let explainedTotal = 0
    let explainedCount = 0

    // Not Found resolutions
    for (const row of result.rows) {
      if (row.status !== 'not_found') continue
      // Explained (group / service wash / house use / other): someone else pays or the
      // charge is accepted, so the line is not a discrepancy.
      if (isExplainedType(noteFor(row.invoiceLine)?.charge_type)) {
        explainedTotal += row.invoiceLine.net; explainedCount++
        continue
      }
      const key = notFoundKey(row)
      const res = notFoundResolutions[key]
      if (res) {
        resolvedCount++
        if (res.type === 'accepted' || res.type === 'added_to_system') {
          acceptedTotal += row.invoiceLine.net
        }
      }
    }

    // Missing resolutions (old in-page ones, or Phase 1 DB-backed ones)
    for (const o of result.missingFromInvoice) {
      const db = orderRes[o.id]
      const res = missingResolutions[o.id] ?? (db ? { type: db.resolution === 'expect_next' ? 'deferred' as const : 'written_off' as const } : undefined)
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
    const unresolvedDiff = (result.invoiceTotal - result.systemTotal) - acceptedTotal - explainedTotal + writtenOffTotal

    return {
      unresolvedDiff: +unresolvedDiff.toFixed(2),
      resolvedCount,
      acceptedTotal: +acceptedTotal.toFixed(2),
      writtenOffTotal: +writtenOffTotal.toFixed(2),
      challengedCount: challengedItems.size,
      explainedTotal: +explainedTotal.toFixed(2),
      explainedCount,
    }
  }, [result, notFoundResolutions, missingResolutions, challengedItems, noteFor, orderRes])

  // Count unresolved items for save validation
  const unresolvedCounts = useMemo(() => {
    if (!result) return { nfCount: 0, nfTotal: 0, missCount: 0, missTotal: 0 }
    let nfCount = 0, nfTotal = 0
    for (const row of result.rows) {
      if (row.status !== 'not_found') continue
      if (isExplainedType(noteFor(row.invoiceLine)?.charge_type)) continue
      if (!notFoundResolutions[notFoundKey(row)]) { nfCount++; nfTotal += row.invoiceLine.net }
    }
    let missCount = 0, missTotal = 0
    for (const o of result.missingFromInvoice) {
      if (!missingResolutions[o.id] && !orderRes[o.id]) { missCount++; missTotal += computeOrderCost(o) }
    }
    return { nfCount, nfTotal: +nfTotal.toFixed(2), missCount, missTotal: +missTotal.toFixed(2) }
  }, [result, notFoundResolutions, missingResolutions, noteFor, orderRes])

  const handleSaveClick = useCallback(() => {
    const hasIssues = unresolvedCounts.nfCount > 0 || unresolvedCounts.missCount > 0 || Math.abs(adjustedTotals.unresolvedDiff) >= 1
    if (hasIssues) {
      setShowSaveConfirm(true)
    } else {
      saveReconciliation()
    }
  }, [unresolvedCounts, adjustedTotals, saveReconciliation])

  // ── Accounting Report Export ──
  const exportAccountingReport = useCallback(() => {
    if (!result || !invoice) return
    const wb = utils.book_new()
    const totalTopUp = result.topUpCharges.reduce((s, l) => s + l.net, 0)
    const parsedGrandNet = result.invoiceTotal + totalTopUp
    // Use stated invoice totals when available
    const grandNet = invoice.totals.net > 0 ? invoice.totals.net : parsedGrandNet
    const grandVat = invoice.totals.vat > 0 ? invoice.totals.vat : +(grandNet * 0.2).toFixed(2)
    const grandGross = invoice.totals.gross > 0 ? invoice.totals.gross : +(grandNet * 1.2).toFixed(2)

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
      ['Grand Total (Invoice)', +grandNet.toFixed(2), +grandVat.toFixed(2), +grandGross.toFixed(2)],
      ['System Total', +result.systemTotal.toFixed(2), +(result.systemTotal * 0.2).toFixed(2), +(result.systemTotal * 1.2).toFixed(2)],
      [],
      ['RECONCILIATION SUMMARY'],
      ['Matched Orders', result.stats.matched],
      ['Price Discrepancies', result.stats.priceMismatch],
      ['  of which minor (≤3%)', result.stats.minorVariance],
      ['On Invoice Only', result.stats.notFound],
      ['In System Only', result.stats.missing],
      ...(reconciliationNote.trim() ? [[], ['NOTES / INVOICE ISSUES'], ...reconciliationNote.trim().split('\n').map(l => [l])] : []),
    ])
    summarySheet['!cols'] = [{ wch: 25 }, { wch: 15 }, { wch: 12 }, { wch: 15 }]
    utils.book_append_sheet(wb, summarySheet, 'Summary')

    const deptDisplayRows = buildDepartmentDisplayRows(result.departmentBreakdown, result.rows, chargeDetailByDept)
    const deptExcelRows: Record<string, string | number>[] = deptDisplayRows.flatMap(row => {
      const line: Record<string, string | number> = {
        'Department': row.departmentName,
        'Line': row.subDetail ? `${row.lineLabel} — ${row.subDetail}` : row.lineLabel,
        'Orders': (row.isTopUp && row.lineLabel === 'Minimum TopUp') ? '' as any : row.orderCount,
        'Invoice NET (£)': +row.invoiceNet.toFixed(2),
        'System NET (£)': (row.isTopUp && row.lineLabel === 'Minimum TopUp') ? '' as any : +row.systemTotal.toFixed(2),
        'Difference (£)': (row.isTopUp && row.lineLabel === 'Minimum TopUp') ? '' as any : +row.difference.toFixed(2),
        'Total inc VAT (£)': +row.totalGross.toFixed(2),
      }
      if (!(row.isTopUp && row.lineLabel === 'Minimum TopUp')) return [line]
      // Usage + top-up subtotal for the department (informational; the TOTAL row below
      // is computed from the display rows only, so this is not double-counted)
      const dRows = deptDisplayRows.filter(r => r.departmentName === row.departmentName)
      const usage = dRows.filter(r => !r.isTopUp).reduce((s, r) => s + r.invoiceNet, 0)
      return [line, {
        'Department': row.departmentName, 'Line': 'Total cost (usage + minimum top-up)', 'Orders': '',
        'Invoice NET (£)': +(usage + row.invoiceNet).toFixed(2), 'System NET (£)': '', 'Difference (£)': '',
        'Total inc VAT (£)': +dRows.reduce((s, r) => s + r.totalGross, 0).toFixed(2),
      }]
    })
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
      'Status': r.status === 'matched' ? 'Matched' : r.status === 'price_mismatch' ? 'Price Discrepancy' : isExplainedType(noteFor(r.invoiceLine)?.charge_type) ? 'Explained' : 'On Invoice Only',
      'Department': r.order?.department?.name || 'Unallocated',
      'Date': r.invoiceLine.date, 'Docket': r.invoiceLine.ticket,
      'Type': ORDER_TYPE_LABELS[r.sectionType as OrderType] ?? r.sectionType,
      'Invoice Description': r.invoiceLine.description,
      'Our Items (System)': (r.order?.order_items || []).map(it => `${it.quantity_sent}x ${it.item_name}`).join(', '),
      'Invoice NET (\u00a3)': +r.invoiceLine.net.toFixed(2), 'Invoice VAT (\u00a3)': +r.invoiceLine.vat.toFixed(2),
      'Invoice GROSS (\u00a3)': +r.invoiceLine.gross.toFixed(2),
      'System Total (\u00a3)': r.order ? +r.systemTotal.toFixed(2) : '',
      'Difference (\u00a3)': r.order ? +r.difference.toFixed(2) : '',
      'Resolution': r.status === 'not_found' ? (notFoundResolutions[notFoundKey(r)]?.type || '') : '',
      'Staff/Guest': r.order?.staff_name || r.order?.guest_name || '',
      'Invoice Guest': [r.invoiceLine.guestInfo?.replace(/[()]/g, ''), r.invoiceLine.serviceNote].filter(Boolean).join(' '),
      'Charge to': (() => { const n = noteFor(r.invoiceLine); return n && n.charge_type !== 'note' ? chargeLabel(n) : (!r.invoiceLine.ticket && r.sectionType === 'guest_laundry' ? 'No room — not yet assigned' : '') })(),
      'Line note': noteFor(r.invoiceLine)?.note || lineNotes[notFoundKey(r)] || '',
    }))), 'Detailed Items')

    // Group & No-room charges — per-group subtotals with the revenue posted to Opera, so
    // accounts can check the group master folio against what Goldstar charged.
    if (pdfChargeGroups.length > 0) {
      const gRows: Record<string, string | number>[] = []
      for (const g of pdfChargeGroups) {
        for (const l of g.lines) gRows.push({
          'Charge to': g.bucket, 'Date': l.date, 'Room': l.ticket, 'Invoice Guest': l.guest,
          'Description': l.description, 'NET (£)': +l.net.toFixed(2), 'VAT (£)': +l.vat.toFixed(2), 'GROSS (£)': +l.gross.toFixed(2),
          'Line note': l.note, 'Master room': '', 'Revenue posted (£)': '', 'Folio ref': '',
        })
        gRows.push({
          'Charge to': `SUBTOTAL — ${g.bucket}`, 'Date': '', 'Room': '', 'Invoice Guest': `${g.lines.length} line(s)`,
          'Description': '', 'NET (£)': g.net, 'VAT (£)': g.vat, 'GROSS (£)': g.gross, 'Line note': '',
          'Master room': g.masterRoom ?? '', 'Revenue posted (£)': g.revenuePosted ?? '', 'Folio ref': g.folioRef ?? '',
        })
      }
      utils.book_append_sheet(wb, utils.json_to_sheet(gRows), 'Group Charges')
    }

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
      'Line note': noteFor(r.invoiceLine)?.note || lineNotes[notFoundKey(r)] || '',
      'Recommended Action': 'Verify pricing with Goldstar / update system prices',
    }))
    result.rows.filter(r => r.status === 'not_found' && !isExplainedType(noteFor(r.invoiceLine)?.charge_type)).forEach(r => discRows.push({
      'Issue': 'On invoice but not in system', 'Docket': r.invoiceLine.ticket, 'Department': '',
      'Invoice NET (\u00a3)': +r.invoiceLine.net.toFixed(2), 'System NET (\u00a3)': 0,
      'Difference (\u00a3)': +r.invoiceLine.net.toFixed(2), 'Description': r.invoiceLine.description,
      'Resolution': notFoundResolutions[notFoundKey(r)]?.type || 'Unresolved',
      'Charge to': (() => { const n = noteFor(r.invoiceLine); return n && n.charge_type !== 'note' ? chargeLabel(n) : '' })(),
      'Line note': noteFor(r.invoiceLine)?.note || lineNotes[notFoundKey(r)] || '',
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
  }, [result, invoice, notFoundResolutions, missingResolutions, reconciliationNote, noteFor, lineNotes, pdfChargeGroups, chargeDetailByDept])

  const statusIcon = (s: ReconciliationRow['status'], minor = false) => {
    if (s === 'matched') return <CheckCircle className="w-4 h-4 text-green-500" />
    if (s === 'price_mismatch') return minor
      ? <AlertTriangle className="w-4 h-4 text-gray-400" />
      : <AlertTriangle className="w-4 h-4 text-amber-500" />
    return <XCircle className="w-4 h-4 text-red-500" />
  }

  // Price update error banner
  const [priceUpdateError, setPriceUpdateError] = useState<string | null>(null)

  // ── Action: update prices to match invoice ──
  // Sets per-item unit price (full precision) and total_price (authoritative, 2dp).
  const handleUpdatePrice = useCallback(async (row: ReconciliationRow) => {
    if (!row.order || !invoice) return
    // Overwrite stays the rule, but show the piece difference first: a price overwrite on
    // an order whose pieces don't agree hides the real problem (Sept 2026 napkins).
    const invQty = row.invoiceLine.items.reduce((s, it) => s + it.quantity, 0)
    const sysQty = (row.order.order_items ?? []).reduce((s, it) => s + (it.quantity_sent ?? 0), 0)
    if (invQty > 0 && sysQty > 0 && invQty !== sysQty) {
      const ok = window.confirm(
        `Pieces don't agree on ticket ${row.invoiceLine.ticket || row.order.docket_number}:\n` +
        `  Invoice: ${invQty} pcs    Our order: ${sysQty} pcs\n\n` +
        `Update Price will overwrite our order price £${row.systemTotal.toFixed(2)} → £${row.invoiceLine.net.toFixed(2)}.\n` +
        `The piece difference will no longer show as a price difference.\n\nOverwrite anyway?`)
      if (!ok) return
    }
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
        const { error: orderErr, data: updRows } = await supabase.from('orders').update({ total_price: +invoiceNet.toFixed(2) }).eq('id', orderId).select('id')
        if (orderErr) {
          setPriceUpdateError(`Docket ${docket}: Failed to update order total — ${orderErr.message}`)
          return
        }
        if (!updRows || updRows.length === 0) {
          setPriceUpdateError(`Docket ${docket}: Order total update had no effect (possible RLS policy)`)
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

      const { error: orderErr, data: ordRows } = await supabase.from('orders').update({ total_price: +invoiceNet.toFixed(2) }).eq('id', orderId).select('id')
      if (orderErr) errors.push(`Order total: ${orderErr.message}`)
      else if (!ordRows || ordRows.length === 0) errors.push('Order total: update had no effect (possible RLS policy)')

      if (errors.length > 0) {
        setPriceUpdateError(`Docket ${docket}: ${errors.join('; ')}`)
      }
      logAction({ invoice_number: invoice.invoiceNumber || null, line_key: lineKeys.get(row.invoiceLine) ?? null, order_id: orderId, action: 'Price updated to invoice', detail: `£${row.systemTotal.toFixed(2)} → £${invoiceNet.toFixed(2)}` })
      await refetchAndReconcile()
    } catch (e) {
      const msg = e instanceof Error ? e.message : 'Unknown error'
      setPriceUpdateError(`Docket ${docket}: ${msg}`)
    } finally {
      setUpdatingPrices(prev => { const next = new Set(prev); next.delete(orderId); return next })
    }
  }, [invoice, lineKeys, refetchAndReconcile])

  // ── Action: delete a missing order ──
  const handleDeleteOrder = useCallback(async (orderId: string) => {
    if (!invoice) return
    const o = orders.find(x => x.id === orderId)
    const reason = window.prompt(`Delete order ${o?.docket_number ?? ''} permanently?\nThis cannot be undone. Use it only for an order entered by mistake (never sent).\n\nReason (required):`)
    if (reason == null) return
    if (!reason.trim()) { window.alert('A reason is required to delete an order.'); return }
    try {
      await logAction({ invoice_number: invoice.invoiceNumber || null, order_id: orderId, action: 'Deleted order', detail: `${o?.docket_number ?? ''} ${o?.department?.name ?? ''} £${o ? computeOrderCost(o).toFixed(2) : ''}: ${reason.trim()}` })
      await supabase.from('order_items').delete().eq('order_id', orderId)
      await supabase.from('orders').delete().eq('id', orderId)
      setMissingResolutions(prev => { const next = { ...prev }; delete next[orderId]; return next })
      await refetchAndReconcile()
    } catch (e) {
      console.error('Failed to delete order:', e)
    }
  }, [invoice, refetchAndReconcile, orders])

  // ── In System Only: DB-backed resolutions (Phase 1) ──
  const resolveOrders = useCallback(async (ids: string[], resolution: OrderResolution) => {
    if (!invoice?.invoiceNumber) return
    let note: string | null = null
    if (resolution === 'write_off') {
      const r = window.prompt(`Write off ${ids.length} order${ids.length > 1 ? 's' : ''}: why? (required)`)
      if (r == null) return
      if (!r.trim()) { window.alert('A note is required to write off.'); return }
      note = r.trim()
    } else if (resolution === 'not_charged') {
      const r = window.prompt(`Mark ${ids.length} order${ids.length > 1 ? 's' : ''} as not charged by Goldstar (counts as £0 in reports). Note (optional):`, '')
      if (r == null) return
      note = r.trim() || null
    }
    const next = { ...orderRes }
    for (const id of ids) {
      const err = await setOrderResolution(invoice.invoiceNumber, id, resolution, note)
      if (err) { setPriceUpdateError(`Could not save: ${err}`); break }
      next[id] = { invoice_number: invoice.invoiceNumber, order_id: id, resolution, note, found_on_invoice: null, created_by: null, created_at: new Date().toISOString() }
    }
    setOrderRes(next); setSelectedOrders(new Set())
    if (resolution === 'not_charged') await refetchAndReconcile()
    fetchActions(invoice.invoiceNumber).then(setActions)
  }, [invoice, orderRes, refetchAndReconcile])

  const unresolveOrder = useCallback(async (id: string) => {
    if (!invoice?.invoiceNumber) return
    const was = orderRes[id]
    const err = await clearOrderResolution(invoice.invoiceNumber, id, was?.resolution === 'not_charged')
    if (err) { setPriceUpdateError(`Could not undo: ${err}`); return }
    const next = { ...orderRes }; delete next[id]; setOrderRes(next)
    if (was?.resolution === 'not_charged') await refetchAndReconcile()
    fetchActions(invoice.invoiceNumber).then(setActions)
  }, [invoice, orderRes, refetchAndReconcile])

  // ── Action: Add invoice-only item to system ──
  // Orders that probably ARE this line (same service, same ticket / room / guest, ±3 days):
  // shown in the Add pop-up so a duplicate isn't created by mistake.
  const likelyExisting = useMemo(() => {
    if (!addModal || addModal.row.order) return []
    const line = addModal.row.invoiceLine
    const lineDay = invoiceLineDay(line.date)
    const key = canonicalDocket(line.ticket)
    const isGuest = addModal.row.sectionType === 'guest_laundry'
    const out: { o: Order; why: string }[] = []
    for (const o of orders) {
      if (o.order_type !== addModal.row.sectionType) continue
      const days = lineDay == null ? 0 : Math.abs(orderDay(o) - lineDay)
      if (key && canonicalDocket(o.docket_number) === key) { out.push({ o, why: `same ticket · ${days}d` }); continue }
      if (days > 3) continue
      if (isGuest && line.guestInfo && guestNameSimilar(line.guestInfo, o.guest_name)) out.push({ o, why: `similar guest name · ${days}d` })
    }
    return out.slice(0, 4)
  }, [addModal, orders])

  const handleAddToSystem = useCallback(async () => {
    if (!addModal || !invoice) return
    const { row } = addModal
    if (!addModalDept) return
    setAddModalSaving(true)
    try {
      const docket = addModalDocket.trim() || row.invoiceLine.ticket || `REC-${String(Date.now()).slice(-6)}`
      const orderType = row.sectionType as OrderType
      // A line that was linked before and is now added: move the link, never keep both
      // (Aug 2026 tickets 1341 / 1389 ended up with a linked AND an added order).
      const addRefKey = refKeyMap.get(row.invoiceLine)?.[0]
      if (addRefKey) {
        const { data: stale } = await supabase.from('orders').select('id, notes').ilike('notes', `%${addRefKey}%`)
        for (const st of stale ?? []) {
          const cleaned = (st.notes || '').split(addRefKey).join(' ').replace(/\s{2,}/g, ' ').trim()
          await supabase.from('orders').update({ notes: cleaned || null }).eq('id', st.id)
        }
      }

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

      // Clamp date to invoice period — if the line date falls outside, use the closest period boundary
      // This prevents orders from being created outside the reconciliation fetch window
      if (period) {
        const d = new Date(createdAt)
        if (d < period.start) createdAt = period.start.toISOString()
        else if (d > period.end) createdAt = period.end.toISOString()
      }

      // Create order
      const { data: newOrder, error: orderErr } = await supabase.from('orders').insert({
        docket_number: docket,
        order_type: orderType,
        department_id: addModalDept,
        staff_name: row.invoiceLine.guestInfo?.replace(/[()]/g, '') || null,
        guest_name: orderType === 'guest_laundry' ? (row.invoiceLine.guestInfo?.replace(/[()]/g, '') || null) : null,
        room_number: orderType === 'guest_laundry' ? row.invoiceLine.ticket : null,
        status: 'received',
        total_price: +row.invoiceLine.net.toFixed(2),
        notes: `Added from invoice reconciliation — ${invoice.invoiceNumber} ${refKeyMap.get(row.invoiceLine)?.[0] ?? `[ref:${row.invoiceLine.ticket}|${row.invoiceLine.date}|${row.invoiceLine.net}]`}`,
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
          status: 'received',
          changed_by_name: userName,
          reason: `Added from invoice reconciliation — ${invoice.invoiceNumber}`,
        })
      }

      // Mark as resolved
      const key = notFoundKey(row)
      setNotFoundResolutions(prev => ({ ...prev, [key]: { type: 'added_to_system' } }))
      logAction({ invoice_number: invoice.invoiceNumber || null, line_key: lineKeys.get(row.invoiceLine) ?? null, order_id: newOrder?.id ?? null, action: 'Added new order', detail: `docket ${docket} · £${row.invoiceLine.net.toFixed(2)}` })

      // Re-reconcile to pick up the new order
      await refetchAndReconcile()
      setAddModal(null)
      setAddModalDept('')
    } catch (e) {
      console.error('Failed to add to system:', e)
    } finally {
      setAddModalSaving(false)
    }
  }, [addModal, addModalDept, addModalDocket, addModalDate, invoice, refetchAndReconcile, refKeyMap, lineKeys])

  // ── Action: Link this invoice line to an EXISTING order ──
  // Used when the order is already in the system but wasn't matched (wrong/changed ticket
  // number, or a near-miss). Instead of creating a duplicate, we stamp the matcher's
  // ref-key — and an optional human note — into the chosen order's notes, so the next
  // reconciliation pass links them directly.
  const handleLinkExisting = useCallback(async () => {
    if (!addModal || !invoice || !addModalLinkOrderId) return
    const { row } = addModal
    setAddModalSaving(true)
    try {
      const target = orders.find(o => o.id === addModalLinkOrderId) ?? addModalLinkDbResults.find(o => o.id === addModalLinkOrderId)
      if (!target) throw new Error('Selected order not found')
      const refKey = refKeyMap.get(row.invoiceLine)?.[0] ?? `[ref:${row.invoiceLine.ticket}|${row.invoiceLine.date}|${row.invoiceLine.net}]`

      // Re-linking: remove this line's ref-key from any OTHER order that carries it,
      // so the old link can't shadow the new one on the next matching pass.
      const { data: stale } = await supabase.from('orders')
        .select('id, notes').ilike('notes', `%${refKey}%`).neq('id', target.id)
      for (const s of stale ?? []) {
        const cleaned = (s.notes || '').split(refKey).join(' ').replace(/\s{2,}/g, ' ').trim()
        await supabase.from('orders').update({ notes: cleaned || null }).eq('id', s.id)
      }

      // The docket to record on the order — user may correct a wrong invoice ticket here.
      const newDocket = addModalLinkDocket.trim() || target.docket_number
      const docketChanged = newDocket !== target.docket_number
      const correction = docketChanged
        ? ` (docket ${target.docket_number} → ${newDocket})`
        : (canonicalDocket(target.docket_number) !== canonicalDocket(row.invoiceLine.ticket)
            ? ` (invoice ticket ${row.invoiceLine.ticket} → our docket ${target.docket_number})` : '')
      // Re-linking the same line to the same order must not append a second copy
      const existingNotes = (target.notes || '').split(refKey).join(' ').replace(/\s{2,}/g, ' ').trim()
      const noteParts = [
        existingNotes,
        `Linked to invoice ${invoice.invoiceNumber}${correction} ${refKey}`,
      ]
      if (addModalNote.trim()) noteParts.push(`Note: ${addModalNote.trim()}`)
      const newNotes = noteParts.filter(Boolean).join(' ')

      const orderUpdate: Record<string, unknown> = { notes: newNotes, reconciliation_id: null }
      if (docketChanged) orderUpdate.docket_number = newDocket
      if (addModalLinkUpdatePrice) orderUpdate.total_price = +row.invoiceLine.net.toFixed(2)
      if (addModalLinkDept && addModalLinkDept !== target.department_id) orderUpdate.department_id = addModalLinkDept
      const { error: updErr, data: updRows } = await supabase.from('orders').update(orderUpdate).eq('id', target.id).select('id')
      if (updErr) throw updErr
      if (!updRows || updRows.length === 0) throw new Error('Order update had no effect (possible RLS policy)')

      // Optionally sync per-item prices to the invoice (distribute net by quantity)
      if (addModalLinkUpdatePrice) {
        const { data: items } = await supabase.from('order_items').select('id, quantity_sent').eq('order_id', target.id)
        const valid = (items || []).filter((i: any) => (i.quantity_sent ?? 0) > 0 && i.id)
        const totalQty = valid.reduce((s: number, i: any) => s + (i.quantity_sent ?? 0), 0)
        if (totalQty > 0) {
          const unit = row.invoiceLine.net / totalQty
          for (const it of valid) await supabase.from('order_items').update({ price_at_time: unit }).eq('id', it.id)
        }
      }

      let userName = 'Dashboard'
      const { data: { user: authUser } } = await supabase.auth.getUser()
      if (authUser) {
        const { data: du } = await supabase.from('dashboard_users').select('name, email').eq('id', authUser.id).single()
        userName = `Dashboard / ${du?.name || du?.email || 'Unknown'}`
      }
      await supabase.from('order_status_log').insert({
        order_id: target.id, status: target.status, changed_by_name: userName,
        reason: `Linked to invoice ${invoice.invoiceNumber} line "${row.invoiceLine.ticket}"${correction}${addModalNote.trim() ? ` — ${addModalNote.trim()}` : ''}`,
      })

      const key = notFoundKey(row)
      if (row.status === 'not_found') {
        setNotFoundResolutions(prev => ({ ...prev, [key]: { type: 'added_to_system', note: addModalNote.trim() || undefined } }))
      }
      if (addModalNote.trim()) setLineNotes(prev => ({ ...prev, [key]: addModalNote.trim() }))
      logAction({ invoice_number: invoice.invoiceNumber || null, line_key: lineKeys.get(row.invoiceLine) ?? null, order_id: target.id, action: 'Linked to order', detail: `${target.docket_number}${correction}${addModalNote.trim() ? ` · ${addModalNote.trim()}` : ''}` })
      if (invoice.invoiceNumber) fetchActions(invoice.invoiceNumber).then(setActions)
      await refetchAndReconcile()
      setAddModal(null); setAddModalLinkOrderId(''); setAddModalNote(''); setAddModalLinkSearch(''); setAddModalMode('create')
      setAddModalLinkDocket(''); setAddModalLinkUpdatePrice(false); setAddModalLinkDbResults([]); setAddModalLinkDept('')
    } catch (e) {
      console.error('Failed to link existing order:', e)
      setPriceUpdateError(`Link failed (docket ${addModal.row.invoiceLine.ticket}): ${e instanceof Error ? e.message : 'unknown error'}`)
    } finally {
      setAddModalSaving(false)
    }
  }, [addModal, invoice, addModalLinkOrderId, addModalNote, addModalLinkDocket, addModalLinkUpdatePrice, addModalLinkDept, orders, addModalLinkDbResults, refetchAndReconcile, refKeyMap, lineKeys])

  // ── Open the Add/Link modal for ANY row (not-found, mismatch, or matched) ──
  // Lets the user link/relink a line to the right order (by docket, room, name…) and add
  // a per-line note, on every line — including guest rooms and already-matched lines.
  const openAddModal = useCallback((row: ReconciliationRow, index: number, mode: 'create' | 'link') => {
    setAddCreateAnyway(false)
    setAddModal({ row, index }); setAddModalDept('')
    setAddModalMode(mode); setAddModalLinkOrderId(''); setAddModalNote(''); setAddModalLinkDocket('')
    setAddModalLinkUpdatePrice(false); setAddModalLinkDbResults([]); setAddModalLinkDept('')
    // For a line that already has an order, pre-seed the search with the room (guest) or
    // docket so the current order surfaces immediately — they can re-select to add a note,
    // or search for a different one.
    const seed = mode === 'link'
      ? (row.invoiceLine.sectionType === 'guest' ? (row.invoiceLine.ticket || row.order?.room_number || '') : (row.order?.docket_number || ''))
      : ''
    setAddModalLinkSearch(seed)
    setAddModalDocket(row.invoiceLine.ticket || `REC-${String(Date.now()).slice(-6)}`)
    const ld = row.invoiceLine.date
    if (ld) setAddModalDate(ld)
    else if (parsedPeriod) setAddModalDate(format(parsedPeriod.start, 'yyyy-MM-dd'))
    else setAddModalDate('')
  }, [parsedPeriod])

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
    const challengedNF = result.rows.filter(r => r.status === 'not_found' && challengedItems.has(`nf:${notFoundKey(r)}`))
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
    const challengedMM = result.rows.filter(r => r.status === 'price_mismatch' && challengedItems.has(`mm:${notFoundKey(r)}`))
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
    const napkinWeeksForPdf = napkinSummary?.weeks.map(w => ({
      dateRange: w.dateRange,
      invoiceSentQty: w.invoiceSentQty,
      topUpQty: w.topUpQty,
      topUpNet: w.topUpNet,
      totalChargedQty: w.totalChargedQty,
      totalNet: w.totalNet,
      deptBreakdown: w.deptBreakdown.map(d => ({
        deptName: d.deptName, sentQty: d.sentQty, topUpAlloc: d.topUpAlloc, totalCost: d.totalCost,
      })),
    }))
    const pdfTopUp = result.topUpCharges.reduce((s, l) => s + l.net, 0)
    const pdfStatedNet = invoice.totals.net
    const pdfGrandNet = pdfStatedNet > 0 ? pdfStatedNet : (result.invoiceTotal + pdfTopUp)
    const pdfFinancials: FinancialTotals = {
      lineItemsNet: +result.invoiceTotal.toFixed(2),
      topUpNet: +pdfTopUp.toFixed(2),
      invoiceNet: +pdfGrandNet.toFixed(2),
      invoiceVat: +(invoice.totals.vat > 0 ? invoice.totals.vat : pdfGrandNet * 0.2).toFixed(2),
      invoiceGross: +(invoice.totals.gross > 0 ? invoice.totals.gross : pdfGrandNet * 1.2).toFixed(2),
      systemNet: +result.systemTotal.toFixed(2),
    }
    downloadReconciliationPdf(invoice, result, departmentDisplayRows, napkinSummary?.deptTotals, uniformMinWeeksForPdf, napkinWeeksForPdf, pdfFinancials, reconciliationNote.trim() || undefined, pdfChargeGroups)
  }, [result, invoice, departmentDisplayRows, napkinSummary, uniformMinSummary, reconciliationNote, pdfChargeGroups])

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
          <button onClick={handleSaveClick} disabled={saving || saved}
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
      {(restoredFrom || history.some(h => h.invoice_number === invoice.invoiceNumber)) && (
        <div className="bg-blue-50 border border-blue-200 rounded-lg p-3 flex items-center gap-3">
          <AlertTriangle className="w-5 h-5 text-blue-500 flex-shrink-0" />
          <p className="text-sm text-blue-800">
            This invoice (<span className="font-medium">{invoice.invoiceNumber}</span>) was previously reconciled
            {restoredFrom
              ? <> on <span className="font-medium">{format(new Date(restoredFrom), 'dd MMM yyyy HH:mm')}</span>. Your earlier work — resolutions, challenge flags, per-line notes and the invoice note — has been <span className="font-medium">restored</span>; links made to system orders are picked up automatically.</>
              : <>. No saved per-line work was found to restore.</>}
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
      <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-6 gap-4">
        <StatCard icon={<CheckCircle className="w-5 h-5 text-green-500" />} label="Matched" value={result.stats.matched} color="green" />
        <button onClick={() => setFilter('explained')} className="text-left bg-white rounded-xl border-2 border-indigo-200 p-4 hover:border-indigo-300" title="Lines tagged Group / Service wash / House use / Other: someone else pays or the charge is accepted, so they are not discrepancies">
          <div className="flex items-center gap-2 mb-1"><Tag className="w-5 h-5 text-indigo-500" /><span className="text-xs text-indigo-700 font-medium">Explained</span></div>
          <p className="text-2xl font-bold text-indigo-700">{adjustedTotals.explainedCount}</p>
          {adjustedTotals.explainedCount > 0 && <p className="text-[10px] text-gray-500 mt-0.5">{'\u00a3'}{adjustedTotals.explainedTotal.toFixed(2)} · not discrepancies</p>}
        </button>
        <StatCard icon={<AlertTriangle className="w-5 h-5 text-amber-500" />} label="Price Discrepancy" value={result.stats.priceMismatch} color="amber"
          subtitle={result.stats.minorVariance > 0 ? `${result.stats.minorVariance} minor (≤3%)` : undefined} />
        {/* "minor" = matched order, price within tolerance (e.g. £0.215 vs £0.22 napkin rate). Real overcharges stay flagged. */}
        <StatCard icon={<XCircle className="w-5 h-5 text-red-500" />} label="On Invoice Only" value={result.stats.notFound - adjustedTotals.explainedCount} color="red"
          subtitle={Object.keys(notFoundResolutions).length > 0 ? `${Object.keys(notFoundResolutions).length} resolved` : undefined} />
        <StatCard icon={<HelpCircle className="w-5 h-5 text-blue-500" />} label="In System Only" value={result.stats.missing} color="blue"
          subtitle={[Object.keys(missingResolutions).length > 0 ? `${Object.keys(missingResolutions).length} resolved` : '', result.nextInvoice.length > 0 ? `+${result.nextInvoice.length} probably next invoice` : ''].filter(Boolean).join(' · ') || undefined} />
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

      {/* Detected systematic price patterns — a stale rate to correct, not one-off errors. */}
      {pricePatterns.length > 0 && (
        <div className="bg-amber-50 rounded-xl border border-amber-200 p-4">
          <div className="flex items-center gap-2 mb-2">
            <Scale className="w-4 h-4 text-amber-600" />
            <h3 className="text-sm font-semibold text-gray-900">Systematic price patterns detected</h3>
            <span className="text-xs text-gray-500">— consistent gaps that look like a stale rate, not one-off errors</span>
          </div>
          <div className="space-y-1.5">
            {pricePatterns.map((p, i) => (
              <div key={i} className="flex items-center justify-between text-sm bg-white rounded-lg px-3 py-2 border border-amber-100">
                <span className="text-gray-700">
                  <strong>{p.item}</strong> {'·'} {p.count} lines {'·'} our rate {'£'}{p.sysUnit.toFixed(3)}/unit {'→'} invoice {'£'}{p.invUnit.toFixed(3)}/unit
                </span>
                <span className={`font-medium ${Math.abs(p.totalImpact) >= 0.01 ? 'text-amber-700' : 'text-gray-500'}`}>
                  {p.totalImpact >= 0 ? '+' : ''}{'£'}{p.totalImpact.toFixed(2)} total
                </span>
              </div>
            ))}
          </div>
          <p className="text-[11px] text-gray-500 mt-2">
            A consistent per-unit gap usually means our catalogue/order rate is out of date. Correct the rate in the Catalogue (fixes future orders) and use “Update price” on the affected lines, or note it here to query with the cleaning company.
          </p>
        </div>
      )}

      {/* Reconciliation notes — invoice errors / corrections to request / anything to record.
          Saved with the reconciliation and printed on the PDF + Excel breakdown. */}
      <div className="bg-white rounded-xl border border-gray-200 p-4">
        <div className="flex items-center gap-2 mb-2">
          <FileText className="w-4 h-4 text-navy" />
          <h3 className="text-sm font-semibold text-gray-900">Notes / Invoice Issues</h3>
          <span className="text-xs text-gray-400">— recorded on the saved report (PDF & Excel)</span>
        </div>
        {phase1 && invoice.invoiceNumber && (
          <p className="text-[11px] mb-1.5 text-gray-500">{draftSavedAt ? <span className="text-green-700">{'\u2713'} Draft saved {format(new Date(draftSavedAt), 'HH:mm')}: kept even if you re-upload without Save</span> : 'Saves automatically as you type'}</p>
        )}
        <textarea
          value={reconciliationNote}
          onChange={e => {
            const v = e.target.value
            setReconciliationNote(v)
            if (phase1 && invoice.invoiceNumber) {
              if (draftTimer.current) clearTimeout(draftTimer.current)
              const inv = invoice.invoiceNumber
              draftTimer.current = setTimeout(async () => { if (!(await saveDraft(inv, v))) setDraftSavedAt(new Date().toISOString()) }, 900)
            }
          }}
          rows={3}
          placeholder={'e.g. Ticket 7208 doesn’t exist — should be 6208 (linked). Napkins billed at £0.22 but agreed rate is £0.215 — query with Goldstar. Charged £4.37 for jacket+apron (should be £2.40).'}
          className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-navy/30 resize-y"
        />
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
            <tbody>{departmentDisplayRows.map((row, i) => {
              // After a department's Minimum TopUp line: usage + top-up = what that department
              // really cost (display only — not part of the data the footer/Excel/PDF sum)
              const deptRows = row.isTopUp && row.lineLabel === 'Minimum TopUp'
                ? departmentDisplayRows.filter(r => r.departmentName === row.departmentName) : null
              const usage = deptRows ? deptRows.filter(r => !r.isTopUp).reduce((s, r) => s + r.invoiceNet, 0) : 0
              return (<Fragment key={i}>
              <tr className={`border-b border-gray-100 ${row.isTopUp ? 'bg-amber-50/20' : ''}`}>
                <td className={`px-4 py-2.5 ${row.isTopUp ? 'pl-8 italic text-gray-500 text-xs' : 'font-medium'}`}>
                  {row.departmentName} {'\u2014'} {row.lineLabel}
                  {row.subDetail && <div className="text-[10px] text-gray-400 font-normal mt-0.5">{row.subDetail}</div>}
                </td>
                <td className="px-4 py-2.5 text-right">{row.isTopUp && row.lineLabel === 'Minimum TopUp' ? '\u2014' : row.orderCount}</td>
                <td className="px-4 py-2.5 text-right">{'\u00a3'}{row.invoiceNet.toFixed(2)}</td>
                <td className="px-4 py-2.5 text-right">{row.isTopUp && row.lineLabel === 'Minimum TopUp' ? '\u2014' : `\u00a3${row.systemTotal.toFixed(2)}`}</td>
                <td className={`px-4 py-2.5 text-right font-medium ${row.isTopUp && row.lineLabel === 'Minimum TopUp' ? 'text-gray-400' : Math.abs(row.difference) < 0.02 ? 'text-green-600' : 'text-amber-600'}`}>
                  {row.isTopUp && row.lineLabel === 'Minimum TopUp' ? '\u2014' : Math.abs(row.difference) < 0.02 ? '\u2713' : `\u00a3${row.difference.toFixed(2)}`}
                </td>
                <td className="px-4 py-2.5 text-right font-semibold">{'\u00a3'}{row.totalGross.toFixed(2)}</td>
              </tr>
              {deptRows && (
                <tr className="border-b border-gray-200 bg-gray-50/70">
                  <td className="px-4 py-2 pl-8 text-xs font-semibold text-gray-800">
                    {row.departmentName} {'\u2014'} Total cost (usage {'\u00a3'}{usage.toFixed(2)} + minimum top-up {'\u00a3'}{row.invoiceNet.toFixed(2)})
                    {usage + row.invoiceNet > 0 && <span className="ml-1 font-normal text-gray-500">{'\u00b7'} top-up is {((row.invoiceNet / (usage + row.invoiceNet)) * 100).toFixed(0)}% of the total</span>}
                  </td>
                  <td className="px-4 py-2" />
                  <td className="px-4 py-2 text-right text-xs font-semibold">{'\u00a3'}{(usage + row.invoiceNet).toFixed(2)}</td>
                  <td className="px-4 py-2" colSpan={2} />
                  <td className="px-4 py-2 text-right text-xs font-semibold">{'\u00a3'}{deptRows.reduce((s, r) => s + r.totalGross, 0).toFixed(2)}</td>
                </tr>
              )}
              </Fragment>)
            })}</tbody>
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
                <th className="px-3 py-2.5 text-right font-medium text-gray-600" title="What Goldstar would charge if they used OUR sent count (the weekly minimum still applies)">Charge by our count</th>
                <th className="px-3 py-2.5 text-right font-medium text-gray-600" title="Charged minus 'charge by our count', at the napkin rate. £0 when both counts are under the weekly minimum.">Over / under {'\u00a3'}</th>
                <th className="px-3 py-2.5 text-left font-medium text-gray-600" title="Invoice top-up vs minimum minus sent, and £ charged vs quantity x rate">Check</th>
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
                      {(() => {
                        const ow = napkinOverUnder(w)
                        return (<>
                          <td className="px-3 py-2 text-right">{ow ? ow.ourQty.toLocaleString() : <span className="text-gray-300">{'\u2014'}</span>}</td>
                          <td className={`px-3 py-2 text-right font-medium ${!ow ? 'text-gray-300' : ow.pounds > 0.005 ? 'text-red-600' : ow.pounds < -0.005 ? 'text-amber-600' : 'text-green-600'}`}
                            title={ow ? (ow.pounds === 0 ? (hasTopUp ? 'Both counts are under the weekly minimum: the bill is the same either way' : 'Counts agree') : `${ow.pounds > 0 ? 'Charged more' : 'Charged less'} than our count: ${Math.abs(w.totalChargedQty - ow.ourQty)} napkins`) : 'No tablet orders for this week'}>
                            {!ow ? '\u2014' : ow.pounds > 0.005 ? `+\u00a3${ow.pounds.toFixed(2)} over` : ow.pounds < -0.005 ? `\u2212\u00a3${Math.abs(ow.pounds).toFixed(2)} under` : '\u00a30.00'}
                          </td>
                        </>)
                      })()}
                      {(() => {
                        const expectedQty = hasTopUp ? Math.max(0, napkinSummary.weeklyMinimum - w.invoiceSentQty) : 0
                        const qtyOff = hasTopUp && w.topUpQty !== expectedQty
                        const expectedNet = w.topUpQty * napkinSummary.unitRate
                        const chargeOff = hasTopUp && Math.abs(expectedNet - w.topUpNet) > 0.05
                        const detail = [
                          ...(qtyOff ? [`invoice top-up ${w.topUpQty} vs ${napkinSummary.weeklyMinimum} min - ${w.invoiceSentQty} sent = ${expectedQty}`] : []),
                          ...(chargeOff ? [`charged £${w.topUpNet.toFixed(2)} vs £${expectedNet.toFixed(2)} at £${napkinSummary.unitRate.toFixed(3)}`] : []),
                        ]
                        const splitWeek = i === 0 && qtyOff && !chargeOff && w.topUpQty < expectedQty
                        return (
                          <td className={`px-3 py-2 whitespace-nowrap text-xs ${!hasTopUp ? 'text-gray-300' : detail.length ? 'text-amber-700' : 'text-green-600'}`} title={detail.join('\n')}>
                            {!hasTopUp ? '\u2014' : detail.length === 0 ? '\u2713' : splitWeek ? '\u26a0 week starts on previous invoice?' : `\u26a0 ${detail.length} difference${detail.length > 1 ? 's' : ''}`}
                          </td>
                        )
                      })()}
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
                  <td className="px-3 py-3 text-right">{napkinMonth.ourQty > 0 ? napkinMonth.ourQty.toLocaleString() : '\u2014'}</td>
                  <td className={`px-3 py-3 text-right ${napkinMonth.pounds > 0.005 ? 'text-red-600' : napkinMonth.pounds < -0.005 ? 'text-amber-600' : 'text-green-600'}`}>
                    {napkinMonth.pounds > 0.005 ? `+\u00a3${napkinMonth.pounds.toFixed(2)}` : napkinMonth.pounds < -0.005 ? `\u2212\u00a3${Math.abs(napkinMonth.pounds).toFixed(2)}` : '\u00a30.00'}
                  </td>
                  <td className="px-3 py-3" />
                </tr>
              </tfoot>
            </table>
          </div>
          {/* Summary footer */}
          <div className="px-5 py-3 bg-gray-50 border-t border-gray-200 text-xs text-gray-600 space-y-1">
            <div>Weekly minimum: {napkinSummary.weeklyMinimum.toLocaleString()} napkins @ {'\u00a3'}{napkinSummary.unitRate.toFixed(3)}/each = {'\u00a3'}{napkinSummary.weeklyMinCost.toFixed(2)}/week</div>
            {napkinMonth.weeks > 0 && (
              <div className={`font-medium ${Math.abs(napkinMonth.pounds) < 1 ? 'text-green-700' : napkinMonth.pounds > 0 ? 'text-red-700' : 'text-amber-700'}`}>
                Verdict by our count: {Math.abs(napkinMonth.pounds) < 1
                  ? `billed correctly (difference ${'\u00a3'}${Math.abs(napkinMonth.pounds).toFixed(2)}). Weeks under the minimum cost the same whatever the count.`
                  : napkinMonth.pounds > 0 ? `over-charged by ${'\u00a3'}${napkinMonth.pounds.toFixed(2)}: check the weeks marked "over" and consider a credit request.`
                  : `under-charged by ${'\u00a3'}${Math.abs(napkinMonth.pounds).toFixed(2)} compared with our count.`}
              </div>
            )}
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
              <div className="px-5 py-2 text-xs text-gray-500 border-t border-gray-100">
                % Share = share of napkins sent. TopUp (unused minimum) split fixed: {NAPKIN_TOPUP_SPLIT.map(([name, pct]) => `${name} ${Math.round(pct * 100)}%`).join(' · ')}
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
                <th className="px-3 py-2 text-left font-medium text-gray-600 border-l border-gray-200" rowSpan={2} title="Invoice top-up quantity vs minimum minus sent, and £ charged vs quantity x rate">Check</th>
              </tr><tr className="border-b border-gray-200 bg-gray-50">
                {uniformMinSummary.ITEM_KEYS.map(k => (
                  <Fragment key={`${k}-s-f`}><th key={`${k}-s`} className="px-2 py-1 text-right font-medium text-gray-500 border-l border-gray-200">Sent</th>
                  <th key={`${k}-t`} className="px-2 py-1 text-right font-medium text-gray-500">TopUp</th>
                  <th key={`${k}-p`} className="px-2 py-1 text-right font-medium text-gray-500">Used%</th></Fragment>
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
                        <Fragment key={`${k}-s-${i}-f`}><td key={`${k}-s-${i}`} className="px-2 py-2 text-right border-l border-gray-200">{sent}</td>
                        <td key={`${k}-t-${i}`} className={`px-2 py-2 text-right ${w.topUp[k] > 0 ? 'text-amber-600 font-medium' : 'text-gray-300'}`}>
                          {w.topUp[k] > 0 ? w.topUp[k] : '-'}
                        </td>
                        <td key={`${k}-p-${i}`} className={`px-2 py-2 text-right font-medium ${pct < 60 ? 'text-red-600' : pct < 80 ? 'text-amber-600' : pct >= 100 ? 'text-green-600' : 'text-amber-500'}`}>
                          {pct}%
                        </td></Fragment>
                      )
                    })}
                    <td className="px-3 py-2 text-right border-l border-gray-200 font-medium">{'\u00a3'}{w.topUpNet.toFixed(2)}</td>
                    {(() => {
                      // Does the invoice top-up equal minimum minus sent, and £ = qty x rate?
                      const short = (k: typeof uniformMinSummary.ITEM_KEYS[number]) => Math.max(0, uniformMinSummary.MINIMUMS[k] - w.invoiceSent[k])
                      const qtyIssues = uniformMinSummary.ITEM_KEYS.filter(k => w.topUp[k] !== short(k))
                      const expectedNet = uniformMinSummary.ITEM_KEYS.reduce((s, k) => s + w.topUp[k] * uniformMinSummary.PRICES[k], 0)
                      const chargeOff = w.topUpNet > 0 && Math.abs(expectedNet - w.topUpNet) > 0.05
                      const detail = [
                        ...qtyIssues.map(k => `${k}: invoice top-up ${w.topUp[k]} vs ${uniformMinSummary.MINIMUMS[k]} min - ${w.invoiceSent[k]} sent = ${short(k)}`),
                        ...(chargeOff ? [`charged £${w.topUpNet.toFixed(2)} vs £${expectedNet.toFixed(2)} at the agreed rates`] : []),
                      ]
                      // First week of the month: the days before the 1st are on the previous invoice
                      const splitWeek = i === 0 && qtyIssues.length > 0 && !chargeOff && qtyIssues.every(k => w.topUp[k] < short(k))
                      return (
                        <td className={`px-3 py-2 border-l border-gray-200 whitespace-nowrap ${detail.length ? 'text-amber-700' : 'text-green-600'}`} title={detail.join('\n') || 'Top-up matches minimum minus sent, and the charge matches the agreed rates'}>
                          {detail.length === 0 ? '\u2713' : splitWeek ? '\u26a0 week starts on previous invoice?' : `\u26a0 ${detail.length} difference${detail.length > 1 ? 's' : ''}`}
                        </td>
                      )
                    })()}
                  </tr>
                ))}
              </tbody>
              <tfoot><tr className="bg-gray-50 font-semibold border-t-2 border-gray-300">
                <td className="px-3 py-2.5">Total ({uniformMinSummary.weekCount} weeks)</td>
                {uniformMinSummary.ITEM_KEYS.map(k => (
                  <Fragment key={`${k}-ts-f`}><td key={`${k}-ts`} className="px-2 py-2.5 text-right border-l border-gray-200">{uniformMinSummary.totalInvoiceSent[k]}</td>
                  <td key={`${k}-tt`} className="px-2 py-2.5 text-right text-amber-600">{uniformMinSummary.totalTopUp[k]}</td>
                  <td key={`${k}-tp`} className="px-2 py-2.5 text-right">
                    {Math.round(uniformMinSummary.totalInvoiceSent[k] / (uniformMinSummary.MINIMUMS[k] * uniformMinSummary.weekCount) * 100)}%
                  </td></Fragment>
                ))}
                <td className="px-3 py-2.5 text-right border-l border-gray-200">{'\u00a3'}{uniformMinSummary.totalTopUpNet.toFixed(2)}</td>
                <td className="px-3 py-2.5 border-l border-gray-200" />
              </tr></tfoot>
            </table>
          </div>
          <div className="px-5 py-3 bg-gray-50 border-t border-gray-200 text-xs text-gray-600 space-y-1">
            <div className="flex flex-wrap gap-4">
              <span className="text-gray-500">Pieces short of the weekly minimum (paid for, not used):</span>
              {uniformMinSummary.ITEM_KEYS.map(k => (
                <span key={k} className={uniformMinSummary.unusedCapacity[k] > 0 ? 'text-amber-700 font-medium' : 'text-green-600'}>
                  {k.charAt(0).toUpperCase() + k.slice(1)}: {uniformMinSummary.unusedCapacity[k]} pcs ({'\u00a3'}{(uniformMinSummary.unusedCapacity[k] * uniformMinSummary.PRICES[k]).toFixed(2)} @ {'\u00a3'}{uniformMinSummary.PRICES[k].toFixed(2)})
                </span>
              ))}
            </div>
            <div className="text-amber-700 font-medium">
              Total overspend on unused minimum: {'\u00a3'}{uniformMinSummary.unusedCost.toFixed(2)}
              {(() => {
                const cost = (k: typeof uniformMinSummary.ITEM_KEYS[number]) => uniformMinSummary.unusedCapacity[k] * uniformMinSummary.PRICES[k]
                const worst = [...uniformMinSummary.ITEM_KEYS].sort((a, b) => cost(b) - cost(a))[0]
                const used = Math.round(uniformMinSummary.totalInvoiceSent[worst] / (uniformMinSummary.MINIMUMS[worst] * Math.max(1, uniformMinSummary.weekCount)) * 100)
                return uniformMinSummary.unusedCapacity[worst] > 0
                  ? <span className="font-normal text-gray-600"> {'\u00b7'} biggest overspend: <strong>{worst}</strong> (only {used}% of the minimum used)</span>
                  : null
              })()}
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

      {/* Group & No-room charges — lines without a room, and lines tagged as group / house / other */}
      {(chargeGroups.length > 0 || unattachedNotes.length > 0) && (
        <div className="bg-white rounded-xl border border-gray-200 overflow-hidden">
          <div className="px-5 py-3 border-b border-gray-200 flex items-center gap-2">
            <Tag className="w-4 h-4 text-indigo-600" />
            <h3 className="text-sm font-semibold text-gray-900">Group & No-room Charges</h3>
            <span className="text-xs text-gray-500">{'—'} for accounts to cross-check against the group master folio / room charges in Opera</span>
          </div>
          {!notesAvailable && (
            <div className="px-5 py-2.5 bg-amber-50 text-xs text-amber-800 border-b border-amber-100">
              Tags can{'’'}t be saved yet: run <span className="font-mono">db/migrations/2026-11-05_reconciliation_line_notes.sql</span> in the Supabase SQL Editor.
            </div>
          )}
          {chargeGroups.length > 0 && (
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead><tr className="border-b border-gray-200 bg-gray-50 text-xs">
                  <th className="px-4 py-2 text-left font-medium text-gray-600">Charge to</th>
                  <th className="px-3 py-2 text-right font-medium text-gray-600">Lines</th>
                  <th className="px-3 py-2 text-right font-medium text-gray-600">NET</th>
                  <th className="px-3 py-2 text-right font-medium text-gray-600">VAT</th>
                  <th className="px-3 py-2 text-right font-medium text-gray-600">GROSS</th>
                  <th className="px-3 py-2 text-left font-medium text-gray-600" title="Opera group master folio room number — D140 postings on it are matched to this group">Master room</th>
                  <th className="px-3 py-2 text-left font-medium text-gray-600" title="Revenue posted to Opera for this group (used when there is no D140 master-room match)">Revenue posted {'£'}</th>
                  <th className="px-3 py-2 text-left font-medium text-gray-600">Folio ref</th>
                </tr></thead>
                <tbody>
                  {chargeGroups.map(g => {
                    const folio = g.groupName ? groupFolios[g.groupName] : undefined
                    const cell = 'w-full px-2 py-1 text-xs border border-gray-200 rounded focus:outline-none focus:ring-1 focus:ring-navy/30 disabled:bg-gray-50'
                    return (
                      <tr key={g.bucket} className={`border-b border-gray-100 ${g.bucket.startsWith('No room') ? 'bg-amber-50/50' : ''}`}>
                        <td className="px-4 py-2">
                          <button onClick={() => setFilter('group')} className="font-medium text-gray-800 hover:text-navy text-left">{g.bucket}</button>
                        </td>
                        <td className="px-3 py-2 text-right">{g.rows.length}</td>
                        <td className="px-3 py-2 text-right font-medium">{'£'}{g.net.toFixed(2)}</td>
                        <td className="px-3 py-2 text-right">{'£'}{g.vat.toFixed(2)}</td>
                        <td className="px-3 py-2 text-right">{'£'}{g.gross.toFixed(2)}</td>
                        {g.groupName ? (<>
                          <td className="px-3 py-1.5 w-28"><input key={`mr-${g.groupName}-${folio?.master_room ?? ''}`} defaultValue={folio?.master_room ?? ''} disabled={!notesAvailable} placeholder="e.g. 9001"
                            onBlur={e => { const v = e.target.value.trim().toUpperCase() || null; if (v !== (folio?.master_room ?? null)) saveGroupFolio(g.groupName!, { master_room: v }) }} className={cell} /></td>
                          <td className="px-3 py-1.5 w-32"><input key={`rv-${g.groupName}-${folio?.revenue_posted ?? ''}`} defaultValue={folio?.revenue_posted ?? ''} disabled={!notesAvailable} inputMode="decimal" placeholder="0.00"
                            onBlur={e => { const raw = e.target.value.replace(/[£,\s]/g, ''); const v = raw ? Number(raw) : null; if (v != null && isNaN(v)) return; if (v !== (folio?.revenue_posted ?? null)) saveGroupFolio(g.groupName!, { revenue_posted: v }) }} className={cell} /></td>
                          <td className="px-3 py-1.5 w-36"><input key={`fr-${g.groupName}-${folio?.folio_ref ?? ''}`} defaultValue={folio?.folio_ref ?? ''} disabled={!notesAvailable} placeholder="Opera folio"
                            onBlur={e => { const v = e.target.value.trim() || null; if (v !== (folio?.folio_ref ?? null)) saveGroupFolio(g.groupName!, { folio_ref: v }) }} className={cell} /></td>
                        </>) : (
                          <td colSpan={3} className="px-3 py-2 text-xs text-gray-400">
                            {g.bucket.startsWith('No room') ? 'Use “Assign room / group” on each line' : '—'}
                          </td>
                        )}
                      </tr>
                    )
                  })}
                </tbody>
              </table>
            </div>
          )}
          {unattachedNotes.length > 0 && (
            <div className="px-5 py-3 border-t border-gray-200 bg-gray-50/60">
              <p className="text-xs font-medium text-gray-700 mb-1.5">Notes whose invoice line no longer appears ({unattachedNotes.length}) {'—'} e.g. a corrected invoice changed the date or amount</p>
              <div className="space-y-1">
                {unattachedNotes.map(n => (
                  <div key={n.line_key} className="flex items-center justify-between gap-3 text-xs text-gray-600">
                    <span>{n.line_date} {n.ticket || ''} {n.guest_label || ''} {'£'}{(n.net ?? 0).toFixed(2)} {'—'} <span className="font-medium">{chargeLabel(n)}</span>{n.note ? `: ${n.note}` : ''}</span>
                    <button onClick={() => removeUnattachedNote(n)} className="text-red-500 hover:text-red-700">Remove</button>
                  </div>
                ))}
              </div>
            </div>
          )}
        </div>
      )}

      {phase1 && invoice.invoiceNumber && (
        <CreditNotesPanel invoiceNumber={invoice.invoiceNumber} refreshKey={creditRefresh}
          creditLinesOnInvoice={invoice.sections.flatMap(sec => sec.lines).filter(l => l.net < 0).map(l => ({ date: l.date, description: l.description, net: l.net, gross: l.gross }))} />
      )}

      {/* Search + Filter tabs */}
      <div className="flex items-center gap-3 flex-wrap">
        <div className="relative">
          <Search className="absolute left-2.5 top-1/2 -translate-y-1/2 w-3.5 h-3.5 text-gray-400" />
          <input
            type="text"
            value={searchTerm}
            onChange={e => setSearchTerm(e.target.value)}
            placeholder="Search by docket, description, price..."
            className="pl-8 pr-3 py-1.5 text-xs border border-gray-300 rounded-lg w-64 focus:outline-none focus:ring-2 focus:ring-navy/30"
          />
          {searchTerm && (
            <button onClick={() => setSearchTerm('')} className="absolute right-2 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600">
              <X className="w-3.5 h-3.5" />
            </button>
          )}
        </div>
      <div className="flex gap-1.5 bg-gray-100 rounded-lg p-1 w-fit">
        {([['all', 'All', result.rows.length], ['matched', 'Matched', result.stats.matched],
          ['mismatch', 'Price Discrepancy', result.stats.priceMismatch], ['not_found', 'On Invoice Only', result.stats.notFound - adjustedTotals.explainedCount],
          ['explained', 'Explained', adjustedTotals.explainedCount],
          ['missing', 'In System Only', result.stats.missing],
          ...(chargeGroups.length > 0 ? [['group', 'Group / No-room', chargeGroups.reduce((s, g) => s + g.rows.length, 0)]] : [])] as [FilterTab, string, number][]).map(([key, label, count]) => (
          <button key={key} onClick={() => setFilter(key)}
            className={`px-3 py-1.5 text-xs font-medium rounded-md transition-colors ${filter === key ? 'bg-white text-navy shadow-sm' : 'text-gray-600 hover:text-gray-900'}`}
          >{label} ({count})</button>
        ))}
      </div>
      </div>

      {/* Bulk actions for ticked lines / orders */}
      {filter !== 'missing' && selectedLines.size > 0 && (
        <div className="sticky top-2 z-20 bg-sky-50 border border-sky-200 rounded-xl px-4 py-2.5 flex flex-wrap items-center gap-2 text-sm shadow-sm">
          <b>{selectedLines.size} line{selectedLines.size > 1 ? 's' : ''} selected</b>
          <span className="text-gray-500">{'\u00b7'} {'\u00a3'}{(result?.rows ?? []).filter(r => { const k = lineKeys.get(r.invoiceLine); return k && selectedLines.has(k) }).reduce((s2, r) => s2 + r.invoiceLine.net, 0).toFixed(2)}</span>
          <span className="ml-auto flex flex-wrap gap-1.5">
            <button onClick={() => { setBulkForm({ type: 'group', group: '', recharge: '', folio: '', note: '' }); setBulkError(''); setBulkModal('explain') }} className="px-2.5 py-1 text-xs text-white bg-navy rounded">Explain as{'\u2026'}</button>
            {creditRequestButton}
            <button onClick={() => { setBulkForm(f => ({ ...f, note: '' })); setBulkError(''); setBulkModal('note') }} className="px-2.5 py-1 text-xs border border-gray-300 rounded bg-white">Add note</button>
            <button onClick={() => setSelectedLines(new Set())} className="px-2.5 py-1 text-xs border border-gray-300 rounded bg-white">Clear selection</button>
          </span>
        </div>
      )}
      {filter === 'missing' && phase1 && selectedOrders.size > 0 && (
        <div className="sticky top-2 z-20 bg-sky-50 border border-sky-200 rounded-xl px-4 py-2.5 flex flex-wrap items-center gap-2 text-sm shadow-sm">
          <b>{selectedOrders.size} order{selectedOrders.size > 1 ? 's' : ''} selected</b>
          <span className="ml-auto flex flex-wrap gap-1.5">
            <button onClick={() => resolveOrders([...selectedOrders], 'expect_next')} className="px-2.5 py-1 text-xs border border-gray-300 rounded bg-white">Expect next invoice</button>
            <button onClick={() => resolveOrders([...selectedOrders], 'not_charged')} className="px-2.5 py-1 text-xs text-white bg-teal-600 rounded">Not charged (£0)</button>
            <button onClick={() => resolveOrders([...selectedOrders], 'write_off')} className="px-2.5 py-1 text-xs border border-gray-300 rounded bg-white">Write off</button>
            <button onClick={() => setSelectedOrders(new Set())} className="px-2.5 py-1 text-xs border border-gray-300 rounded bg-white">Clear selection</button>
          </span>
        </div>
      )}

      {/* Expected from earlier invoices ("Expect on next invoice") */}
      {expectedFromBefore.length > 0 && result && (() => {
        const found = expectedFromBefore.filter(x => x.order && result.matchedOrderIds.includes(x.order.id))
        const missing = expectedFromBefore.filter(x => !(x.order && result.matchedOrderIds.includes(x.order.id)))
        return (
          <div className="bg-white rounded-xl border-2 border-indigo-200 p-4 text-sm">
            <p className="font-semibold">Expected from earlier invoices: {expectedFromBefore.length} order{expectedFromBefore.length > 1 ? 's' : ''}</p>
            <p className="text-xs text-gray-600 mt-1">
              {found.length > 0 && <span className="text-green-700">{'\u2713'} found on this invoice: {found.map(x => x.order?.docket_number).join(', ')} (ticked off when you Save). </span>}
              {missing.length > 0 && <span className="text-red-700">{'\u2717'} still missing: {missing.map(x => `${x.order?.docket_number} (${x.row.invoice_number})`).join(', ')}</span>}
            </p>
          </div>
        )
      })()}

      {/* Detail table — all tabs except missing */}
      {filter !== 'missing' ? (
        <div className="bg-white rounded-xl border border-gray-200 overflow-hidden"><div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead><tr className="border-b border-gray-200 bg-gray-50">
              <th className="w-8 px-3 py-3"><input type="checkbox" aria-label="Select all lines"
                checked={filteredRows.length > 0 && filteredRows.every(r => { const k = lineKeys.get(r.invoiceLine); return !!k && selectedLines.has(k) })}
                onChange={e => setSelectedLines(e.target.checked ? new Set(filteredRows.map(r => lineKeys.get(r.invoiceLine)).filter((k): k is string => !!k)) : new Set())} /></th>
              <th className="w-10 px-3 py-3" />
              <th className="px-3 py-3 text-left font-medium text-gray-600">Date</th>
              <th className="px-3 py-3 text-left font-medium text-gray-600">Docket</th>
              <th className="px-3 py-3 text-left font-medium text-gray-600">Department</th>
              <th className="px-3 py-3 text-left font-medium text-gray-600">Invoice Description</th>
              <th className="px-3 py-3 text-left font-medium text-gray-600">Our Items (System)</th>
              <th className="px-3 py-3 text-right font-medium text-gray-600">Invoice NET</th>
              <th className="px-3 py-3 text-right font-medium text-gray-600">System NET</th>
              <th className="px-3 py-3 text-right font-medium text-gray-600">Diff</th>
              <th className="px-3 py-3 text-center font-medium text-gray-600">Action</th>
            </tr></thead>
            <tbody>
              {filteredRows.length === 0
                ? <tr><td colSpan={11} className="px-4 py-12 text-center text-gray-500">No items in this category</td></tr>
                : filteredRows.map((row, i) => {
                const nfKey = notFoundKey(row)
                const nfRes = row.status === 'not_found' ? notFoundResolutions[nfKey] : undefined
                const isChallenged = row.status === 'not_found'
                  ? challengedItems.has(`nf:${nfKey}`)
                  : row.status === 'price_mismatch'
                    ? challengedItems.has(`mm:${nfKey}`)
                    : false
                // Note attached to this line (this session, a restored save, or stamped on
                // the linked order's notes) — flagged so it resurfaces on re-reconciliation.
                const tag = noteFor(row.invoiceLine)
                const noRoomGuest = !row.invoiceLine.ticket && row.sectionType === 'guest_laundry'
                const rowNote = tag?.note
                  || lineNotes[nfKey]
                  || nfRes?.note
                  || row.order?.notes?.match(/Note:\s*([^[]+)/)?.[1]?.trim()
                const explained = row.status === 'not_found' && isExplainedType(tag?.charge_type)
                const lineKey = lineKeys.get(row.invoiceLine)
                const history = lineKey ? actionsByLine.get(lineKey) ?? [] : []
                const secondBag = row.status === 'not_found' && row.sectionType === 'guest_laundry' && !!row.invoiceLine.ticket
                  && matchedRoomDays.has(`${row.invoiceLine.date}|${row.invoiceLine.ticket}`)
                return (
                <tr key={i} className={`border-b border-gray-100 ${
                  explained ? 'bg-indigo-50/40' :
                  nfRes?.type === 'accepted' ? 'bg-green-50/40' :
                  nfRes?.type === 'added_to_system' ? 'bg-blue-50/40' :
                  isChallenged ? 'bg-orange-50/40' :
                  row.status === 'price_mismatch' ? 'bg-amber-50/50' :
                  row.status === 'not_found' ? 'bg-red-50/50' : ''
                }`}>
                  <td className="px-3 py-2.5">{lineKey && <input type="checkbox" checked={selectedLines.has(lineKey)}
                    onChange={e => setSelectedLines(prev => { const n = new Set(prev); if (e.target.checked) n.add(lineKey); else n.delete(lineKey); return n })} />}</td>
                  <td className="px-3 py-2.5 text-center">{explained ? <Tag className="w-4 h-4 text-indigo-500 inline" /> : statusIcon(row.status, row.minorVariance)}</td>
                  <td className="px-3 py-2.5 text-gray-500 whitespace-nowrap">{row.invoiceLine.date}</td>
                  <td className="px-3 py-2.5 font-mono font-medium text-navy">
                    {row.invoiceLine.ticket}{row.invoiceLine.guestInfo && <span className="text-gray-400 ml-1">{row.invoiceLine.guestInfo}</span>}
                    {row.invoiceLine.serviceNote && (
                      <span className="ml-1.5 px-1.5 py-0.5 rounded bg-amber-50 text-amber-700 text-[10px] font-sans align-middle" title="Service tag printed on the invoice">{row.invoiceLine.serviceNote}</span>
                    )}
                    <div className="mt-1 flex items-center gap-1 flex-wrap font-sans">
                      {tag && tag.charge_type !== 'note' && (
                        <button onClick={() => openNoteModal(row)} title="Edit"
                          className={`px-1.5 py-0.5 rounded text-[10px] font-medium ${isExplainedType(tag.charge_type) ? 'bg-indigo-100 text-indigo-700' : tag.charge_type === 'room_missing' ? 'bg-sky-50 text-sky-700' : 'bg-gray-100 text-gray-700'}`}>
                          {explained ? 'Explained · ' : ''}{chargeLabel(tag)}
                        </button>
                      )}
                      {noRoomGuest && row.status === 'not_found' && (!tag || tag.charge_type === 'note') && (
                        <button onClick={() => openNoteModal(row)}
                          className="px-1.5 py-0.5 rounded text-[10px] font-medium bg-amber-100 text-amber-800 hover:bg-amber-200"
                          title="No room on the invoice: add the room, pick the guest, or tag it as a group / house charge">
                          Assign room / group
                        </button>
                      )}
                      <button onClick={() => openNoteModal(row)} className="inline-flex items-center gap-0.5 px-1.5 py-0.5 rounded border border-gray-200 text-[10px] text-gray-500 hover:text-navy hover:border-gray-300"
                        title={rowNote ? 'Edit the note' : 'Add a note to this line'}>
                        <StickyNote className="w-3 h-3" />{rowNote ? 'Edit note' : 'Note'}
                      </button>
                    </div>
                    {rowNote && (
                      <p className="mt-1 font-sans font-normal text-[11px] italic text-gray-600 border-l-2 border-amber-300 pl-2 max-w-[260px] whitespace-normal">
                        {rowNote}{tag?.note && tag.updated_by ? <span className="not-italic text-gray-400"> {'\u00b7'} {tag.updated_by.split('@')[0]}{tag.updated_at ? ` ${tag.updated_at.slice(8, 10)}/${tag.updated_at.slice(5, 7)}` : ''}</span> : null}
                      </p>
                    )}
                    {history.length > 0 && (
                      <p className="mt-1 font-sans font-normal text-[10px] text-gray-400 cursor-help w-fit"
                        title={history.map(h => `${format(new Date(h.created_at), 'dd/MM HH:mm')} · ${(h.actor ?? '').split('@')[0]} · ${h.action}${h.detail ? `: ${h.detail}` : ''}`).join('\n')}>
                        History ({history.length})
                      </p>
                    )}
                    {row.order && isInactiveOrder(row.order) && (
                      <p className="mt-1 font-sans font-normal text-[11px] text-gray-700 bg-gray-100 rounded px-1.5 py-0.5 w-fit">tablet status: {row.order.status}</p>
                    )}
                    {row.hint && (
                      <p className="mt-1 font-sans font-normal text-[11px] text-gray-700 bg-gray-100 rounded px-1.5 py-0.5 max-w-[260px] whitespace-normal">{row.hint}</p>
                    )}
                    {secondBag && (
                      <p className="mt-1 font-sans font-normal text-[11px] text-amber-800 bg-amber-50 rounded px-1.5 py-0.5 max-w-[260px] whitespace-normal">Same room and day as a matched line: <b>probably a 2nd bag</b> on one tablet order</p>
                    )}
                  </td>
                  <td className="px-3 py-2.5 text-gray-600">{row.order?.department?.name || '\u2014'}</td>
                  <td className="px-3 py-2.5 text-gray-700 max-w-[220px] truncate" title={row.invoiceLine.description}>{row.invoiceLine.description}</td>
                  {(() => {
                    const sysItems = (row.order?.order_items || []).map(it => `${it.quantity_sent}x ${it.item_name}`).join(', ')
                    // Flag when the system items look different from the invoice (different
                    // total quantity) so a mis-recorded order jumps out immediately.
                    const invQty = row.invoiceLine.items.reduce((s, it) => s + it.quantity, 0)
                    const sysQty = (row.order?.order_items || []).reduce((s, it) => s + (it.quantity_sent ?? 0), 0)
                    const qtyDiffers = !!row.order && invQty > 0 && sysQty > 0 && invQty !== sysQty
                    return (
                      <td className={`px-3 py-2.5 max-w-[220px] ${qtyDiffers ? 'text-amber-700' : 'text-gray-600'}`}
                        title={sysItems ? `${sysItems}${qtyDiffers ? `  (invoice ${invQty} pcs vs system ${sysQty} pcs)` : ''}` : 'Not in system'}>
                        <div className="truncate">{row.order ? (sysItems || <span className="text-gray-400">no items recorded on the tablet</span>) : <span className="text-gray-300">{'\u2014'}</span>}</div>
                        {qtyDiffers && <span className="inline-block mt-0.5 text-[10px] font-medium text-amber-800 bg-amber-100 rounded px-1.5 py-0.5">pieces: invoice {invQty} {'\u00b7'} ours {sysQty}</span>}
                      </td>
                    )
                  })()}
                  <td className="px-3 py-2.5 text-right font-medium">{'\u00a3'}{row.invoiceLine.net.toFixed(2)}</td>
                  <td className="px-3 py-2.5 text-right font-medium">{row.order ? `\u00a3${row.systemTotal.toFixed(2)}` : '\u2014'}</td>
                  <td className={`px-3 py-2.5 text-right font-medium ${row.status === 'matched' ? 'text-green-600' : row.status === 'price_mismatch' ? 'text-amber-600' : 'text-gray-400'}`}>
                    {row.order ? (row.difference >= 0 ? '+' : '') + `\u00a3${row.difference.toFixed(2)}` : '\u2014'}
                  </td>
                  <td className="px-3 py-2.5 text-center">
                    {/* Matched — relink/note available (e.g. wrong room linked, or to add a note) */}
                    {row.status === 'matched' && (
                      <div className="flex items-center gap-1 justify-center">
                        <CheckCircle className="w-4 h-4 text-green-500" />
                        <button
                          onClick={() => openAddModal(row, i, 'link')}
                          className="p-1 rounded hover:bg-gray-100 text-gray-400 hover:text-navy"
                          title="Re-link to a different order, or add a note to this line"
                        >
                          <ArrowRightLeft className="w-3.5 h-3.5" />
                        </button>
                      </div>
                    )}

                    {/* Price Mismatch — Update Price + Relink/Note + Challenge */}
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
                          onClick={() => openAddModal(row, i, 'link')}
                          className="p-1 rounded hover:bg-gray-100 text-gray-400 hover:text-navy"
                          title="Re-link to the correct order, or add a note to this line"
                        >
                          <ArrowRightLeft className="w-3.5 h-3.5" />
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

                    {/* Not Found — Link to existing (primary) / Add new / Challenge supplier */}
                    {row.status === 'not_found' && !nfRes && (
                      <div className="flex items-center gap-1 justify-center">
                        <button
                          onClick={() => openNoteModal(row)}
                          className="px-2 py-1 text-xs font-medium text-white bg-navy rounded hover:bg-navy/90 whitespace-nowrap"
                          title="Link to an order, add the missing room, explain it (group / service wash / house use / other) or add a note"
                        >
                          Resolve{'\u2026'}
                        </button>
                        <button
                          onClick={() => openAddModal(row, i, 'link')}
                          className="p-1 rounded hover:bg-gray-100 text-gray-400 hover:text-navy"
                          title="Link this invoice line to an order already in the system (wrong/changed ticket or room number)"
                        >
                          <ArrowRightLeft className="w-3.5 h-3.5" />
                        </button>
                        <button
                          onClick={() => openAddModal(row, i, 'create')}
                          className="px-2 py-1 text-xs font-medium text-blue-700 bg-blue-100 rounded hover:bg-blue-200 whitespace-nowrap"
                          title="Create a new order for this item (only if it genuinely isn't in the system)"
                        >
                          <Plus className="w-3 h-3 inline mr-0.5" />Add
                        </button>
                        {phase1 && invoice.invoiceNumber && lineKey ? (
                          <button
                            onClick={() => { setSelectedLines(new Set([lineKey])); setTimeout(openCreditRequestFor(lineKey), 0) }}
                            className="p-1 rounded hover:bg-orange-100 text-gray-400 hover:text-orange-600"
                            title="Request a credit note from Goldstar for this line"
                          >
                            <Mail className="w-3.5 h-3.5" />
                          </button>
                        ) : (
                          <button
                            onClick={() => handleChallenge(nfKey, 'nf')}
                            className={`p-1 rounded hover:bg-orange-100 ${isChallenged ? 'text-orange-600 bg-orange-100' : 'text-gray-400'}`}
                            title="Flag to the cleaning company — billed but not in our records"
                          >
                            <Mail className="w-3.5 h-3.5" />
                          </button>
                        )}
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
              <td colSpan={7} className="px-3 py-3 text-right text-gray-700">Totals</td>
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
              {phase1 && <th className="w-8 px-3 py-3"><input type="checkbox" aria-label="Select all"
                checked={filteredMissing.length > 0 && filteredMissing.every(o => selectedOrders.has(o.id))}
                onChange={e => setSelectedOrders(e.target.checked ? new Set(filteredMissing.map(o => o.id)) : new Set())} /></th>}
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
              {filteredMissing.length === 0
                ? <tr><td colSpan={phase1 ? 9 : 8} className="px-4 py-12 text-center text-gray-500">{searchTerm ? 'No matching orders' : 'All system orders found on invoice'}</td></tr>
                : filteredMissing.map(o => {
                const resolution = missingResolutions[o.id]
                const isChallenged = challengedItems.has(`miss:${o.id}`)
                return (
                <tr key={o.id} className={`border-b border-gray-100 ${
                  orderRes[o.id] ? 'bg-gray-50/70' :
                  resolution?.type === 'written_off' ? 'bg-gray-50/60 opacity-60' :
                  resolution?.type === 'deferred' ? 'bg-purple-50/40' :
                  isChallenged ? 'bg-orange-50/40' :
                  'bg-blue-50/30'
                }`}>
                  {phase1 && <td className="px-3 py-2.5"><input type="checkbox" checked={selectedOrders.has(o.id)}
                    onChange={e => setSelectedOrders(prev => { const n = new Set(prev); if (e.target.checked) n.add(o.id); else n.delete(o.id); return n })} /></td>}
                  <td className="px-3 py-2.5 font-mono font-medium text-navy">{o.docket_number}
                    {isInactiveOrder(o) && <div className="mt-1 font-sans text-[10px] text-gray-700 bg-gray-100 rounded px-1.5 py-0.5 w-fit">tablet status: {o.status}</div>}
                    {isTopUpCopy(o) && <div className="mt-1 font-sans text-[10px] font-medium text-red-700 bg-red-100 rounded px-1.5 py-0.5 w-fit" title="Created by 'Add to System' from a weekly Minimum top-up line: it copies a top-up CHARGE, it is not real laundry, and it double-counts the top-up">Copy of a top-up charge, not a real order</div>}
                    {(() => { const dup = duplicateTicketHint(o); return dup ? <div className="mt-1 font-sans text-[10px] text-amber-800 bg-amber-50 rounded px-1.5 py-0.5 w-fit">{dup}</div> : null })()}
                  </td>
                  <td className="px-3 py-2.5 text-gray-600">{o.department?.name || '\u2014'}</td>
                  <td className="px-3 py-2.5 text-gray-600">{ORDER_TYPE_LABELS[o.order_type as OrderType] ?? o.order_type}</td>
                  <td className="px-3 py-2.5 text-gray-900">{o.staff_name || o.guest_name || '\u2014'}</td>
                  <td className="px-3 py-2.5 text-gray-600 max-w-[250px] truncate">{(o.order_items || []).map(i => `${i.quantity_sent}x ${i.item_name}`).join(', ') || '\u2014'}</td>
                  <td className="px-3 py-2.5 text-right font-medium">{'\u00a3'}{computeOrderCost(o).toFixed(2)}</td>
                  <td className="px-3 py-2.5 text-gray-500 whitespace-nowrap">{format(new Date(o.created_at), 'dd/MM/yyyy')}</td>
                  <td className="px-3 py-2.5 text-center">
                    {phase1 && orderRes[o.id] ? (
                      <div className="flex items-center gap-1 justify-center">
                        <span className={`px-2 py-0.5 rounded text-[11px] font-medium ${orderRes[o.id].resolution === 'not_charged' ? 'bg-teal-100 text-teal-700' : orderRes[o.id].resolution === 'expect_next' ? 'bg-slate-200 text-slate-700' : 'bg-gray-200 text-gray-700'}`}
                          title={[orderRes[o.id].note, orderRes[o.id].created_by].filter(Boolean).join(' · ')}>
                          {ORDER_RESOLUTION_LABELS[orderRes[o.id].resolution]}
                        </span>
                        <button onClick={() => unresolveOrder(o.id)} className="p-0.5 rounded hover:bg-gray-200 text-gray-400" title="Undo"><X className="w-3 h-3" /></button>
                      </div>
                    ) : phase1 && !resolution ? (
                      <div className="flex items-center gap-1 justify-center flex-wrap">
                        <button onClick={() => resolveOrders([o.id], 'expect_next')} className="px-2 py-1 text-xs font-medium text-slate-700 bg-slate-100 rounded hover:bg-slate-200 whitespace-nowrap"
                          title="Sent late in the month: show it on next month's reconciliation to tick off">Expect next invoice</button>
                        <button onClick={() => resolveOrders([o.id], 'not_charged')} className="px-2 py-1 text-xs font-medium text-teal-700 bg-teal-50 rounded hover:bg-teal-100 whitespace-nowrap"
                          title="Goldstar didn't bill it: keep the order, count it as £0 in reports">Not charged (£0)</button>
                        <button onClick={() => resolveOrders([o.id], 'write_off')} className="px-2 py-1 text-xs font-medium text-gray-600 bg-gray-100 rounded hover:bg-gray-200 whitespace-nowrap"
                          title="Accept the order is wrong / lost: leaves this reconciliation (note required)"><Ban className="w-3 h-3 inline mr-0.5" />Write off</button>
                        <button onClick={() => handleDeleteOrder(o.id)} className="px-2 py-1 text-xs font-medium text-red-600 bg-red-50 rounded hover:bg-red-100 whitespace-nowrap"
                          title="Entered by mistake (never sent): delete permanently, reason required"><X className="w-3 h-3 inline mr-0.5" />Delete</button>
                      </div>
                    ) : !resolution ? (
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
                          title="Expect this order on next month's invoice"
                        >
                          <ArrowRightLeft className="w-3 h-3 inline mr-0.5" />Expect next invoice
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
        </div>
        {result.nextInvoice.length > 0 && (
          <div className="border-t border-gray-200 bg-gray-50/70 px-4 py-3">
            <p className="text-xs font-semibold text-gray-600 mb-1.5">Probably next invoice ({result.nextInvoice.length}): written on the last day of the period, usually collected and invoiced the next day. Not counted as missing.</p>
            <div className="flex flex-wrap gap-1.5">
              {result.nextInvoice.map(o => (
                <span key={o.id} className="text-[11px] text-gray-600 bg-white border border-gray-200 rounded px-2 py-0.5" title={(o.order_items || []).map(i => `${i.quantity_sent}x ${i.item_name}`).join(', ')}>
                  <span className="font-mono font-medium text-navy">{o.docket_number}</span> {'\u00b7'} {o.department?.name || ORDER_TYPE_LABELS[o.order_type as OrderType]} {'\u00b7'} {'\u00a3'}{computeOrderCost(o).toFixed(2)}
                </span>
              ))}
            </div>
          </div>
        )}
        </div>
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
        <div className="grid grid-cols-2 sm:grid-cols-6 gap-6">
          <div><p className="text-xs text-gray-500 mb-1">Invoice Total (NET)</p>
            <p className="text-lg font-bold text-gray-900">{'\u00a3'}{invoice.totals.net > 0 ? invoice.totals.net.toFixed(2) : grandInvoiceNet.toFixed(2)}</p></div>
          <div><p className="text-xs text-gray-500 mb-1">Invoice VAT</p>
            <p className="text-lg font-bold text-gray-900">{'\u00a3'}{invoice.totals.vat > 0 ? invoice.totals.vat.toFixed(2) : ((invoice.totals.net > 0 ? invoice.totals.net : grandInvoiceNet) * 0.2).toFixed(2)}</p>
            {!(invoice.totals.vat > 0) && <p className="text-xs text-gray-400 mt-0.5">estimated at 20%</p>}</div>
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
                const nfItems = result.rows.filter(r => r.status === 'not_found' && challengedItems.has(`nf:${notFoundKey(r)}`))
                const missItems = result.missingFromInvoice.filter(o => challengedItems.has(`miss:${o.id}`))
                const mmItems = result.rows.filter(r => r.status === 'price_mismatch' && challengedItems.has(`mm:${notFoundKey(r)}`))
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

      {/* ── Bulk explain / note modal ── */}
      {bulkModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40" onClick={() => !bulkSaving && setBulkModal(null)}>
          <div className="bg-white rounded-xl shadow-xl w-full max-w-xl mx-4" onClick={e => e.stopPropagation()}>
            <div className="p-5 border-b border-gray-200 flex justify-between">
              <h3 className="text-base font-semibold text-gray-900">{bulkModal === 'explain' ? `Explain ${selectedLines.size} selected line${selectedLines.size > 1 ? 's' : ''}` : `Add a note to ${selectedLines.size} line${selectedLines.size > 1 ? 's' : ''}`}</h3>
              <button onClick={() => setBulkModal(null)} className="p-1 rounded hover:bg-gray-100"><X className="w-5 h-5 text-gray-400" /></button>
            </div>
            <div className="p-5 space-y-3 text-sm">
              {bulkModal === 'explain' && (
                <div className="grid grid-cols-2 gap-x-4 gap-y-1">
                  <div><label className="block text-xs font-medium text-gray-700 mb-1 h-[18px]">Explain as</label>
                    <select value={bulkForm.type} onChange={e => setBulkForm(f => ({ ...f, type: e.target.value as ChargeType }))} className="w-full h-[38px] px-3 border border-gray-300 rounded-lg bg-white">
                      <option value="group">Group charge</option>{phase1 && <option value="service_wash">Service wash (kg)</option>}<option value="house">House use</option><option value="other">Other / accept charge</option>
                    </select><p className="min-h-[15px]" /></div>
                  <div><label className="block text-xs font-medium text-gray-700 mb-1 h-[18px]">Who pays / account</label>
                    <input value={bulkForm.group} onChange={e => setBulkForm(f => ({ ...f, group: e.target.value }))} list="known-groups-bulk" className="w-full h-[38px] px-3 border border-gray-300 rounded-lg" />
                    <datalist id="known-groups-bulk">{knownGroups.map(g => <option key={g} value={g} />)}</datalist><p className="text-[11px] text-gray-400 mt-1 min-h-[15px]">remembered list</p></div>
                  {phase1 && <>
                    <div><label className="block text-xs font-medium text-gray-700 mb-1 h-[18px]">Charged on to them?</label>
                      <select value={bulkForm.recharge} onChange={e => setBulkForm(f => ({ ...f, recharge: e.target.value as typeof f.recharge }))} className="w-full h-[38px] px-3 border border-gray-300 rounded-lg bg-white">
                        <option value="">{'\u2014'} choose {'\u2014'}</option><option value="recharged">Yes, recharged</option><option value="not_yet">Not yet</option><option value="not_chargeable">Not chargeable</option>
                      </select></div>
                    <div><label className="block text-xs font-medium text-gray-700 mb-1 h-[18px]">Folio / reference</label>
                      <input value={bulkForm.folio} onChange={e => setBulkForm(f => ({ ...f, folio: e.target.value }))} className="w-full h-[38px] px-3 border border-gray-300 rounded-lg" /></div>
                  </>}
                </div>
              )}
              <div><label className="block text-xs font-medium text-gray-700 mb-1">Note <span className="text-red-600">* required</span></label>
                <textarea value={bulkForm.note} onChange={e => setBulkForm(f => ({ ...f, note: e.target.value }))} rows={3} className="w-full px-3 py-2 border border-gray-300 rounded-lg"
                  placeholder="The same note is added to every selected line. You can still edit lines one by one afterwards." /></div>
              {bulkError && <p className="text-xs text-red-600">{bulkError}</p>}
            </div>
            <div className="p-4 border-t border-gray-200 flex justify-end gap-2">
              <button onClick={() => setBulkModal(null)} className="px-4 py-2 text-sm bg-gray-100 rounded-lg">Cancel</button>
              <button onClick={applyBulk} disabled={bulkSaving} className="px-4 py-2 text-sm text-white bg-navy rounded-lg disabled:opacity-50">{bulkSaving ? 'Saving' + '\u2026' : `Apply to ${selectedLines.size} line${selectedLines.size > 1 ? 's' : ''}`}</button>
            </div>
          </div>
        </div>
      )}

      {/* ── Credit note request ── */}
      {creditLines && invoice?.invoiceNumber && (
        <CreditRequestModal invoiceNumber={invoice.invoiceNumber} invoiceLabel={invoice.invoicePeriod || invoice.invoiceDate}
          initialLines={creditLines} onClose={() => setCreditLines(null)}
          onCreated={() => { setCreditLines(null); setSelectedLines(new Set()); setCreditRefresh(n => n + 1); fetchActions(invoice.invoiceNumber).then(setActions) }} />
      )}

      {/* ── Line note / "Charge to" modal ── */}
      {noteModal && (() => {
        const line = noteModal.invoiceLine
        const f = noteForm
        const existing = noteFor(line)
        const lineDay = invoiceLineDay(line.date)
        // Which invoice line each order is currently matched to (to warn before re-using it)
        const matchedTo = new Map<string, ReconciliationRow>()
        for (const r of result?.rows ?? []) if (r.order && r.invoiceLine !== line) matchedTo.set(r.order.id, r)
        const term = noteCandidateSearch.trim().toLowerCase()
        const candidates = noteCandidates
          .filter(o => !term || [o.guest_name, o.room_number, o.docket_number].some(v => v?.toLowerCase().includes(term)))
          .map(o => ({ o, nameHit: guestNameSimilar(line.guestInfo, o.guest_name), free: !matchedTo.has(o.id), days: lineDay == null ? 0 : Math.abs(orderDay(o) - lineDay), cost: computeOrderCost(o) }))
          // Similar name → not already matched to another line → closest date → closest amount
          .sort((a, b) => Number(b.nameHit) - Number(a.nameHit) || Number(b.free) - Number(a.free) || a.days - b.days || Math.abs(a.cost - line.net) - Math.abs(b.cost - line.net))
          .slice(0, 12)
        // Opera D140 postings from the invoice month ±1 day (only when a D140 has been loaded)
        const pStart = parsedPeriod ? Math.floor(parsedPeriod.start.getTime() / DAY_MS) - 1 : null
        const pEnd = parsedPeriod ? Math.floor(parsedPeriod.end.getTime() / DAY_MS) + 1 : null
        const d140Cands = (d140Report?.transactions ?? [])
          .filter(t => { if (t.isCredit) return false; const d = d140Day(t.date); return d == null || pStart == null || pEnd == null || (d >= pStart && d <= pEnd) })
          .filter(t => !term || t.guestName.toLowerCase().includes(term) || t.roomNumber.includes(term))
          .map(t => ({ t, nameHit: guestNameSimilar(line.guestInfo, t.guestName), days: lineDay == null ? 0 : Math.abs((d140Day(t.date) ?? lineDay) - lineDay) }))
          .sort((a, b) => Number(b.nameHit) - Number(a.nameHit) || a.days - b.days || Math.abs(a.t.amount - line.gross) - Math.abs(b.t.amount - line.gross))
          .slice(0, 6)
        const types: ChargeType[] = noteModal.sectionType === 'guest_laundry'
          ? ['room_missing', 'group', ...(phase1 ? ['service_wash' as ChargeType] : []), 'house', 'other', 'note']
          : ['note', 'other']
        return (
          <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40" onClick={() => !noteSaving && setNoteModal(null)}>
            <div className="bg-white rounded-xl shadow-xl max-w-2xl w-full mx-4 max-h-[88vh] flex flex-col" onClick={e => e.stopPropagation()}>
              <div className="p-5 border-b border-gray-200 flex items-start justify-between gap-3">
                <div>
                  <h3 className="text-base font-semibold text-gray-900">Resolve this line</h3>
                  <p className="text-xs text-gray-500 mt-1">
                    {line.date} {'·'} <span className="font-mono">{line.ticket || 'no room'}</span> {line.guestInfo} {line.serviceNote && <span className="px-1 rounded bg-amber-50 text-amber-700">{line.serviceNote}</span>} {'·'} {'£'}{line.net.toFixed(2)} net
                  </p>
                  <p className="text-xs text-gray-400 mt-0.5 truncate max-w-[34rem]" title={line.description}>{line.description}</p>
                </div>
                <button onClick={() => setNoteModal(null)} className="p-1 rounded hover:bg-gray-100"><X className="w-5 h-5 text-gray-400" /></button>
              </div>
              <div className="flex-1 overflow-auto p-5 space-y-4">
                <div>
                  <p className="text-xs font-medium text-gray-700 mb-1.5">What is this line?</p>
                  <div className="grid grid-cols-3 gap-1.5">
                    {noteModal.status === 'not_found' && (
                      <button onClick={() => { const row = noteModal; setNoteModal(null); openAddModal(row, row.rowIndex, 'link') }}
                        className="px-2 py-2 text-xs font-medium rounded-lg border bg-white text-gray-700 border-gray-300 hover:bg-gray-50">
                        Link to an order{'\u2026'}
                      </button>
                    )}
                    {types.map(t => (
                      <button key={t} onClick={() => setNoteForm(prev => ({ ...prev, type: t }))}
                        className={`px-2 py-2 text-xs font-medium rounded-lg border ${f.type === t ? 'bg-navy text-white border-navy' : 'bg-white text-gray-700 border-gray-300 hover:bg-gray-50'}`}>
                        {CHARGE_TYPE_LABELS[t]}
                      </button>
                    ))}
                  </div>
                  <p className="text-[11px] text-gray-400 mt-1.5">Group, Service wash, House use and Other count as <b>Explained</b>, not as discrepancies.</p>
                </div>

                {f.type === 'room_missing' && (
                  <div className="space-y-3">
                    <div>
                      <label className="block text-xs font-medium text-gray-700 mb-1">Room number (Goldstar left it off the invoice)</label>
                      <input value={f.room} onChange={e => setNoteForm(prev => ({ ...prev, room: e.target.value, orderId: null }))} placeholder="e.g. 515"
                        className="w-40 px-3 py-1.5 text-sm border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-navy/30" />
                      {f.orderId && <span className="ml-2 text-xs text-green-700">Linked to the selected guest order</span>}
                    </div>
                    <div>
                      <div className="flex items-center justify-between mb-1.5">
                        <label className="text-xs font-medium text-gray-700">Who could it be? Guest orders from the invoice month {'±'}1 day</label>
                        <input value={noteCandidateSearch} onChange={e => setNoteCandidateSearch(e.target.value)} placeholder="Filter name / room"
                          className="px-2 py-1 text-xs border border-gray-300 rounded w-40 focus:outline-none focus:ring-1 focus:ring-navy/30" />
                      </div>
                      <div className="border border-gray-200 rounded-lg divide-y divide-gray-100 max-h-56 overflow-auto">
                        {candidates.length === 0 && <p className="px-3 py-3 text-xs text-gray-400">No guest orders found{term ? ' for this filter' : ''}.</p>}
                        {candidates.map(({ o, nameHit, days, cost }) => {
                          const other = matchedTo.get(o.id)
                          const selected = f.orderId === o.id
                          return (
                            <button key={o.id} onClick={() => setNoteForm(prev => ({ ...prev, orderId: o.id, room: o.room_number || o.docket_number || '' }))}
                              className={`w-full text-left px-3 py-2 text-xs flex items-center gap-3 hover:bg-gray-50 ${selected ? 'bg-sky-50' : ''}`}>
                              <span className="w-16 text-gray-500">{format(new Date(o.created_at), 'dd/MM/yy')}</span>
                              <span className="w-12 font-mono font-medium text-navy">{o.room_number || o.docket_number}</span>
                              <span className={`flex-1 truncate ${nameHit ? 'font-semibold text-gray-900' : 'text-gray-700'}`}>{o.guest_name || '—'}</span>
                              <span className="w-16 text-right">{'£'}{cost.toFixed(2)}</span>
                              <span className={`w-28 text-right ${other ? 'text-amber-700' : 'text-gray-400'}`}>
                                {other ? `matched to ${other.invoiceLine.date}` : days === 0 ? 'same day' : `${days}d away`}
                              </span>
                            </button>
                          )
                        })}
                      </div>
                    </div>
                    {d140Cands.length > 0 && (
                      <div>
                        <label className="block text-xs font-medium text-gray-700 mb-1.5">Opera D140 charges (invoice month {'±'}1 day) {'—'} click to use the room</label>
                        <div className="border border-gray-200 rounded-lg divide-y divide-gray-100">
                          {d140Cands.map(({ t, nameHit }, i) => (
                            <button key={i} onClick={() => setNoteForm(prev => ({ ...prev, room: t.roomNumber, orderId: null }))}
                              className="w-full text-left px-3 py-2 text-xs flex items-center gap-3 hover:bg-gray-50">
                              <span className="w-16 text-gray-500">{t.date}</span>
                              <span className="w-12 font-mono font-medium text-navy">{t.roomNumber}</span>
                              <span className={`flex-1 truncate ${nameHit ? 'font-semibold text-gray-900' : 'text-gray-700'}`}>{t.guestName}</span>
                              <span className="w-16 text-right">{'£'}{t.amount.toFixed(2)}</span>
                            </button>
                          ))}
                        </div>
                      </div>
                    )}
                  </div>
                )}

                {isExplainedType(f.type) && (
                  <div className="grid grid-cols-2 gap-x-4 gap-y-1">
                    <div>
                      <label className="block text-xs font-medium text-gray-700 mb-1 h-[18px]">
                        {f.type === 'group' || f.type === 'service_wash' ? 'Who pays / account responsible' : 'Account / label (optional)'}
                      </label>
                      <input value={f.group} onChange={e => setNoteForm(prev => ({ ...prev, group: e.target.value }))} list="known-groups"
                        placeholder={f.type === 'house' ? 'e.g. Spa, Front office' : 'e.g. Ecuador team – LTA'}
                        className="w-full h-[38px] px-3 text-sm border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-navy/30" />
                      <datalist id="known-groups">{knownGroups.map(g => <option key={g} value={g} />)}</datalist>
                      <p className="text-[11px] text-gray-400 mt-1 min-h-[15px]">remembered list: same spelling each time</p>
                    </div>
                    {phase1 ? (<>
                      <div>
                        <label className="block text-xs font-medium text-gray-700 mb-1 h-[18px]">Charged on to them?</label>
                        <select value={f.recharge} onChange={e => setNoteForm(prev => ({ ...prev, recharge: e.target.value as typeof prev.recharge }))}
                          className="w-full h-[38px] px-3 text-sm border border-gray-300 rounded-lg bg-white focus:outline-none focus:ring-2 focus:ring-navy/30">
                          <option value="">{'\u2014'} choose {'\u2014'}</option><option value="recharged">Yes, recharged</option><option value="not_yet">Not yet</option><option value="not_chargeable">Not chargeable</option>
                        </select>
                        <p className="text-[11px] text-gray-400 mt-1 min-h-[15px]"></p>
                      </div>
                      <div>
                        <label className="block text-xs font-medium text-gray-700 mb-1 h-[18px]">Folio / reference</label>
                        <input value={f.folio} onChange={e => setNoteForm(prev => ({ ...prev, folio: e.target.value }))} placeholder="e.g. 4471"
                          className="w-full h-[38px] px-3 text-sm border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-navy/30" />
                        <p className="text-[11px] text-gray-400 mt-1 min-h-[15px]"></p>
                      </div>
                      <div>
                        <label className="block text-xs font-medium text-gray-700 mb-1 h-[18px]">Weight (kg) <span className="text-gray-400 font-normal">optional</span></label>
                        <input value={f.kg} onChange={e => setNoteForm(prev => ({ ...prev, kg: e.target.value }))} inputMode="decimal" placeholder={/(\d+(?:\.\d+)?)\s*kg/i.exec(line.description)?.[1] ?? ''}
                          className="w-full h-[38px] px-3 text-sm border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-navy/30" />
                        <p className="text-[11px] text-gray-400 mt-1 min-h-[15px]">{/kg|kilo/i.test(line.description) ? 'from the invoice line' : ''}</p>
                      </div>
                    </>) : <div />}
                  </div>
                )}

                <div>
                  <label className="block text-xs font-medium text-gray-700 mb-1">Note {f.type === 'other' ? <span className="text-red-600 font-normal">* required: why is it accepted?</span> : f.type !== 'note' && <span className="text-gray-400 font-normal">(optional)</span>}</label>
                  <textarea value={f.note} onChange={e => setNoteForm(prev => ({ ...prev, note: e.target.value }))} rows={2}
                    placeholder="Shown on this line, in the Excel / PDF, and copied to the matched order when you Save"
                    className="w-full px-3 py-2 text-sm border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-navy/30" />
                </div>
                {noteError && <p className="text-xs text-red-600">{noteError}</p>}
              </div>
              <div className="p-4 border-t border-gray-200 flex items-center justify-between gap-2">
                <div>
                  {existing && (
                    <button onClick={() => saveLineNote(true)} disabled={noteSaving} className="px-3 py-2 text-sm text-red-600 hover:bg-red-50 rounded-lg disabled:opacity-50">Remove tag</button>
                  )}
                </div>
                <div className="flex gap-2">
                  <button onClick={() => setNoteModal(null)} disabled={noteSaving} className="px-4 py-2 text-sm font-medium text-gray-700 bg-gray-100 rounded-lg hover:bg-gray-200">Cancel</button>
                  <button onClick={() => saveLineNote(false)} disabled={noteSaving}
                    className="px-4 py-2 text-sm font-medium text-white bg-navy rounded-lg hover:bg-navy-light disabled:opacity-50">
                    {noteSaving ? 'Saving…' : 'Save'}
                  </button>
                </div>
              </div>
            </div>
          </div>
        )
      })()}

      {/* ── D140 Opera Report Modal (post-save for guest invoices) ── */}
      {showD140Prompt && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40" onClick={() => setShowD140Prompt(false)}>
          <div className="bg-white rounded-xl shadow-xl max-w-3xl w-full mx-4 max-h-[85vh] flex flex-col" onClick={e => e.stopPropagation()}>
            <div className="p-5 border-b border-gray-200 flex items-center justify-between">
              <div>
                <h3 className="text-base font-semibold text-gray-900">Guest Revenue Verification</h3>
                <p className="text-xs text-gray-500 mt-0.5">Upload D140 Opera PMS report to verify guest charges and profit margins</p>
              </div>
              <div className="flex items-center gap-2">
                {d140Report && (
                  <span className="text-xs text-navy font-medium">{d140Report.transactions.length} transactions | {'\u00a3'}{d140Report.grandTotal.toFixed(2)} revenue</span>
                )}
                <button onClick={() => setShowD140Prompt(false)} className="p-1 rounded hover:bg-gray-100">
                  <X className="w-5 h-5 text-gray-400" />
                </button>
              </div>
            </div>
            <div className="flex-1 overflow-auto">
              {!d140Report ? (
                <div className="p-8">
                  <label className="flex flex-col items-center justify-center gap-3 px-6 py-10 border-2 border-dashed border-gray-300 rounded-lg cursor-pointer hover:border-navy/40 hover:bg-gray-50 transition-colors">
                    <Upload className="w-8 h-8 text-gray-400" />
                    <span className="text-sm text-gray-600 font-medium">{d140Loading ? 'Parsing D140 report...' : 'Click to upload D140 report PDF'}</span>
                    <span className="text-xs text-gray-400">D140 Journal Cashier&TC report from Opera PMS</span>
                    <input type="file" accept=".pdf" className="hidden" onChange={e => { if (e.target.files?.[0]) handleD140File(e.target.files[0]) }} />
                  </label>
                </div>
              ) : guestMarginData && (
                <div className="overflow-x-auto">
                  <div className="px-4 py-2 bg-amber-50 border-b border-amber-100 flex items-center justify-between gap-3 text-xs text-amber-800">
                    <span>Margin VAT basis <strong>unconfirmed</strong> {'—'} check with accounts whether D140 amounts include VAT.</span>
                    <label className="flex items-center gap-1.5 whitespace-nowrap cursor-pointer">
                      <input type="checkbox" checked={d140IncludesVat} onChange={e => setD140IncludesVat(e.target.checked)} />
                      D140 amounts include VAT
                    </label>
                  </div>
                  <table className="w-full text-sm">
                    <thead><tr className="border-b border-gray-200 bg-gray-50">
                      <th className="px-3 py-2.5 text-left font-medium text-gray-600">Room</th>
                      <th className="px-3 py-2.5 text-left font-medium text-gray-600">Guest</th>
                      <th className="px-3 py-2.5 text-left font-medium text-gray-600">Date</th>
                      <th className="px-3 py-2.5 text-right font-medium text-gray-600">Cost (Invoice)</th>
                      <th className="px-3 py-2.5 text-right font-medium text-gray-600">Revenue (D140)</th>
                      <th className="px-3 py-2.5 text-right font-medium text-gray-600">Margin</th>
                      <th className="px-3 py-2.5 text-right font-medium text-gray-600">Margin %</th>
                    </tr></thead>
                    <tbody>
                      {guestMarginData.matched.map((m, i) => (
                        <tr key={i} className="border-b border-gray-100">
                          <td className="px-3 py-2 font-mono font-medium text-navy">{m.room}{!m.invoiceLine.invoiceLine.ticket && <span className="text-sky-600" title="Room added in the reconciliation (missing on the invoice)">*</span>}</td>
                          <td className="px-3 py-2 text-gray-700">{m.d140.guestName}</td>
                          <td className="px-3 py-2 text-gray-500">{m.invoiceLine.invoiceLine.date}</td>
                          <td className="px-3 py-2 text-right">{'\u00a3'}{m.invoiceLine.invoiceLine.net.toFixed(2)}</td>
                          <td className="px-3 py-2 text-right font-medium">{'\u00a3'}{m.d140.amount.toFixed(2)}</td>
                          <td className="px-3 py-2 text-right text-green-600 font-medium">{'\u00a3'}{m.margin.toFixed(2)}</td>
                          <td className={`px-3 py-2 text-right font-medium ${m.marginPct < 35 ? 'text-red-600' : m.marginPct < 40 ? 'text-amber-600' : 'text-green-600'}`}>
                            {m.marginPct.toFixed(1)}%
                          </td>
                        </tr>
                      ))}
                      {guestMarginData.groups.map(g => (
                        <tr key={`grp-${g.bucket}`} className="border-b border-gray-100 bg-indigo-50/40">
                          <td className="px-3 py-2 font-mono text-indigo-700">{g.masterRoom || '—'}</td>
                          <td className="px-3 py-2 text-gray-800 font-medium" colSpan={2}>
                            {g.bucket} <span className="text-xs font-normal text-gray-500">{'·'} {g.rows.length} line{g.rows.length !== 1 ? 's' : ''}{g.folioRef ? ` · folio ${g.folioRef}` : ''}{g.revenueSource ? ` · ${g.revenueSource}` : ''}</span>
                          </td>
                          <td className="px-3 py-2 text-right">{'£'}{g.cost.toFixed(2)}</td>
                          {g.revenue != null ? (<>
                            <td className="px-3 py-2 text-right font-medium">{'£'}{g.revenue.toFixed(2)}</td>
                            <td className="px-3 py-2 text-right text-green-600 font-medium">{'£'}{(g.margin ?? 0).toFixed(2)}</td>
                            <td className="px-3 py-2 text-right text-gray-500">{g.revenue > 0 ? `${(((g.margin ?? 0) / (g.revenue / (d140IncludesVat ? 1.2 : 1))) * 100).toFixed(1)}%` : '—'}</td>
                          </>) : (
                            <td className="px-3 py-2 text-right text-indigo-700 text-xs" colSpan={3}>Set the master room or revenue posted in the Group & No-room panel</td>
                          )}
                        </tr>
                      ))}
                      {guestMarginData.invoiceOnly.map((row, i) => (
                        <tr key={`inv-${i}`} className="border-b border-gray-100 bg-amber-50/50">
                          <td className="px-3 py-2 font-mono text-navy">{row.invoiceLine.ticket}</td>
                          <td className="px-3 py-2 text-gray-500" colSpan={2}>{row.invoiceLine.guestInfo || row.invoiceLine.description}</td>
                          <td className="px-3 py-2 text-right">{'\u00a3'}{row.invoiceLine.net.toFixed(2)}</td>
                          <td className="px-3 py-2 text-right text-amber-600" colSpan={3}>No D140 charge found</td>
                        </tr>
                      ))}
                      {guestMarginData.d140Only.map((t, i) => (
                        <tr key={`d140-${i}`} className="border-b border-gray-100 bg-blue-50/50">
                          <td className="px-3 py-2 font-mono text-navy">{t.roomNumber}</td>
                          <td className="px-3 py-2 text-gray-700">{t.guestName}</td>
                          <td className="px-3 py-2 text-gray-500">{t.date}</td>
                          <td className="px-3 py-2 text-right text-blue-600" colSpan={4}>D140 charge but not on invoice — {'\u00a3'}{t.amount.toFixed(2)}</td>
                        </tr>
                      ))}
                    </tbody>
                    <tfoot><tr className="bg-gray-50 font-medium">
                      <td colSpan={3} className="px-3 py-2.5 text-right text-gray-700">Totals</td>
                      <td className="px-3 py-2.5 text-right">{'\u00a3'}{guestMarginData.totalCost.toFixed(2)}</td>
                      <td className="px-3 py-2.5 text-right">{'\u00a3'}{guestMarginData.totalRevenue.toFixed(2)}</td>
                      <td className="px-3 py-2.5 text-right text-green-600">{'\u00a3'}{guestMarginData.totalMargin.toFixed(2)}</td>
                      <td className={`px-3 py-2.5 text-right ${guestMarginData.avgMarginPct < 35 ? 'text-red-600' : 'text-green-600'}`}>
                        {guestMarginData.avgMarginPct.toFixed(1)}%
                      </td>
                    </tr></tfoot>
                  </table>
                </div>
              )}
            </div>
            <div className="p-4 border-t border-gray-200 flex justify-end gap-2">
              {d140Report && guestMarginData && lastSavedRecId && !d140Saved && (
                <button onClick={handleSaveD140} disabled={d140Saving}
                  className="px-4 py-2 text-sm font-medium text-white bg-navy rounded-lg hover:bg-navy-light disabled:opacity-50">
                  {d140Saving ? 'Saving...' : 'Save D140 Analysis'}
                </button>
              )}
              {d140Saved && (
                <span className="px-4 py-2 text-sm font-medium text-green-700 bg-green-100 rounded-lg flex items-center gap-1">
                  <CheckCircle className="w-4 h-4" /> Saved
                </span>
              )}
              <button onClick={() => setShowD140Prompt(false)}
                className="px-4 py-2 text-sm font-medium text-gray-700 bg-gray-100 rounded-lg hover:bg-gray-200">
                {d140Report ? 'Close' : 'Skip'}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* ── Save Confirmation Dialog ── */}
      {showSaveConfirm && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40" onClick={() => setShowSaveConfirm(false)}>
          <div className="bg-white rounded-xl shadow-xl max-w-md w-full mx-4" onClick={e => e.stopPropagation()}>
            <div className="p-5 border-b border-gray-200 flex items-center gap-3">
              <div className="w-10 h-10 rounded-full bg-amber-100 flex items-center justify-center flex-shrink-0">
                <AlertTriangle className="w-5 h-5 text-amber-600" />
              </div>
              <div>
                <h3 className="text-base font-semibold text-gray-900">Before saving</h3>
                <p className="text-xs text-gray-500 mt-0.5">Review what's still open</p>
              </div>
            </div>
            <div className="p-5 space-y-3 text-sm">
              {unresolvedCounts.nfCount > 0 && (
                <div className="flex items-start gap-2 bg-red-50 border border-red-200 rounded-lg p-3">
                  <XCircle className="w-4 h-4 text-red-500 mt-0.5 flex-shrink-0" />
                  <div>
                    <p className="font-medium text-red-800">{unresolvedCounts.nfCount} "On Invoice Only" item{unresolvedCounts.nfCount > 1 ? 's' : ''} unresolved</p>
                    <p className="text-red-600 text-xs mt-0.5">{'\u00a3'}{unresolvedCounts.nfTotal.toFixed(2)} NET billed but not matched to system orders</p>
                  </div>
                </div>
              )}
              {unresolvedCounts.missCount > 0 && (
                <div className="flex items-start gap-2 bg-blue-50 border border-blue-200 rounded-lg p-3">
                  <HelpCircle className="w-4 h-4 text-blue-500 mt-0.5 flex-shrink-0" />
                  <div>
                    <p className="font-medium text-blue-800">{unresolvedCounts.missCount} "In System Only" item{unresolvedCounts.missCount > 1 ? 's' : ''} unresolved</p>
                    <p className="text-blue-600 text-xs mt-0.5">{'\u00a3'}{unresolvedCounts.missTotal.toFixed(2)} NET in system but not on invoice</p>
                  </div>
                </div>
              )}
              {Math.abs(adjustedTotals.unresolvedDiff) >= 1 && (
                <div className="flex items-start gap-2 bg-amber-50 border border-amber-200 rounded-lg p-3">
                  <AlertTriangle className="w-4 h-4 text-amber-500 mt-0.5 flex-shrink-0" />
                  <div>
                    <p className="font-medium text-amber-800">Unresolved difference: {'\u00a3'}{Math.abs(adjustedTotals.unresolvedDiff).toFixed(2)}</p>
                    <p className="text-amber-600 text-xs mt-0.5">Invoice and system totals do not match after resolutions</p>
                  </div>
                </div>
              )}
              {adjustedTotals.explainedCount > 0 && (
                <div className="flex items-start gap-2 bg-indigo-50 border-2 border-indigo-200 rounded-lg p-3">
                  <Tag className="w-4 h-4 text-indigo-500 mt-0.5 flex-shrink-0" />
                  <div>
                    <p className="font-medium text-indigo-800">{adjustedTotals.explainedCount} explained line{adjustedTotals.explainedCount > 1 ? 's' : ''}: {'\u00a3'}{adjustedTotals.explainedTotal.toFixed(2)} NET</p>
                    <p className="text-indigo-600 text-xs mt-0.5">Group / service wash / house use / other: not counted as discrepancies</p>
                  </div>
                </div>
              )}
              {result.nextInvoice.length > 0 && (
                <p className="text-xs text-gray-500">{result.nextInvoice.length} order{result.nextInvoice.length > 1 ? 's' : ''} written on the last day ({'\u00a3'}{result.nextInvoice.reduce((s, o) => s + computeOrderCost(o), 0).toFixed(2)}) are probably on next month's invoice, so they are not counted.</p>
              )}
              <p className="text-gray-500 text-xs pt-1">You can still save; open items stay listed in the reconciliation record.</p>
            </div>
            <div className="p-4 border-t border-gray-200 flex gap-2 justify-end">
              <button onClick={() => setShowSaveConfirm(false)}
                className="px-4 py-2 text-sm font-medium text-gray-700 bg-gray-100 rounded-lg hover:bg-gray-200">
                Go Back
              </button>
              <button onClick={() => { setShowSaveConfirm(false); saveReconciliation() }}
                className="px-4 py-2 text-sm font-medium text-white bg-amber-500 rounded-lg hover:bg-amber-600">
                Save
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
              <h3 className="text-lg font-semibold text-gray-900">{addModal.row.order ? 'Re-link / note' : addModalMode === 'link' ? 'Link to an existing order' : 'Add to system'}</h3>
              <button onClick={() => setAddModal(null)} className="p-1 rounded hover:bg-gray-100"><X className="w-5 h-5 text-gray-400" /></button>
            </div>
            <div className="px-6 py-4 space-y-4">
              <p className="text-sm text-gray-600">
                {addModal.row.order
                  ? <>This line is currently linked to <strong className="font-mono">#{addModal.row.order.docket_number}</strong>. Re-link it to a different order, or select it again to attach a note.</>
                  : <>This invoice item was not found in our system. Either <strong>create</strong> a new order, or <strong>link it to an existing order</strong> (if it's already in the system under a different/wrong ticket number) {'\u2014'} linking avoids creating a duplicate.</>}
              </p>

              {/* Invoice item details */}
              <div className="bg-gray-50 rounded-lg p-3 text-sm space-y-2">
                <div className="flex justify-between"><span className="text-gray-500">Ticket:</span><span className="font-mono">{addModal.row.invoiceLine.ticket || '\u2014'}</span></div>
                <div className="flex justify-between"><span className="text-gray-500">Description:</span><span className="text-right max-w-[250px] truncate">{addModal.row.invoiceLine.description}</span></div>
                <div className="flex justify-between"><span className="text-gray-500">Amount (NET):</span><span className="font-bold">{'\u00a3'}{addModal.row.invoiceLine.net.toFixed(2)}</span></div>
                <div className="flex justify-between"><span className="text-gray-500">Service Type:</span><span>{ORDER_TYPE_LABELS[addModal.row.sectionType as OrderType] ?? addModal.row.sectionType}</span></div>
              </div>

              {/* Likely existing order: link instead of creating a duplicate */}
              {!addModal.row.order && addModalMode === 'create' && likelyExisting.length > 0 && (
                <div className="rounded-lg border border-amber-300 bg-amber-50 p-3 space-y-2">
                  <p className="text-sm font-semibold text-amber-800">An order like this already exists</p>
                  {likelyExisting.map(({ o, why }) => (
                    <div key={o.id} className="flex items-center justify-between gap-2 bg-white border border-amber-200 rounded px-2 py-1.5 text-xs">
                      <span><b className="font-mono">{o.docket_number}</b> {'\u00b7'} {o.department?.name || '\u2014'} {'\u00b7'} {format(new Date(o.created_at), 'dd/MM')} {'\u00b7'} {'\u00a3'}{computeOrderCost(o).toFixed(2)} <span className="text-gray-500">({why})</span></span>
                      <button onClick={() => { setAddModalMode('link'); setAddModalLinkOrderId(o.id); setAddModalLinkDocket(o.docket_number) }}
                        className="px-2 py-0.5 rounded bg-navy text-white whitespace-nowrap">Link this</button>
                    </div>
                  ))}
                  <label className="flex items-center gap-2 text-xs text-amber-900"><input type="checkbox" checked={addCreateAnyway} onChange={e => setAddCreateAnyway(e.target.checked)} /> Create a new order anyway</label>
                </div>
              )}

              {/* Mode toggle: create new vs link existing */}
              <div className="flex rounded-lg border border-gray-200 p-1 bg-gray-50">
                <button onClick={() => setAddModalMode('create')}
                  className={`flex-1 px-3 py-1.5 text-sm font-medium rounded-md ${addModalMode === 'create' ? 'bg-white shadow text-navy' : 'text-gray-500'}`}>
                  Create new order
                </button>
                <button onClick={() => setAddModalMode('link')}
                  className={`flex-1 px-3 py-1.5 text-sm font-medium rounded-md ${addModalMode === 'link' ? 'bg-white shadow text-navy' : 'text-gray-500'}`}>
                  Link existing order
                </button>
              </div>

              {/* \u2500\u2500 LINK MODE: pick an existing in-system order \u2500\u2500 */}
              {addModalMode === 'link' && (
                <div className="space-y-2">
                  <label className="block text-sm font-medium text-gray-700">Find the existing order to link</label>
                  <div className="relative">
                    <Search className="absolute left-2.5 top-2.5 w-4 h-4 text-gray-400" />
                    <input
                      type="text" value={addModalLinkSearch} onChange={e => setAddModalLinkSearch(e.target.value)}
                      placeholder="Search by docket, department, items..."
                      className="w-full pl-8 pr-3 py-2 border border-gray-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-navy/30"
                    />
                  </div>
                  <div className="border border-gray-200 rounded-lg max-h-52 overflow-y-auto divide-y divide-gray-100">
                    {(() => {
                      const s = addModalLinkSearch.toLowerCase()
                      // In-period unmatched orders (instant, local)
                      const local = (result?.missingFromInvoice ?? []).filter(o => {
                        if (o.order_type !== addModal.row.sectionType) return false
                        if (!s) return true
                        return o.docket_number?.toLowerCase().includes(s)
                          || o.department?.name?.toLowerCase().includes(s)
                          || o.staff_name?.toLowerCase().includes(s)
                          || o.guest_name?.toLowerCase().includes(s)
                          || o.room_number?.toLowerCase().includes(s)
                          || (o.order_items || []).some(it => it.item_name?.toLowerCase().includes(s))
                      })
                      const localIds = new Set(local.map(o => o.id))
                      // Whole-DB matches (any date / already matched elsewhere), deduped
                      const dbExtra = addModalLinkDbResults.filter(o => !localIds.has(o.id))
                      const candidates = [...local, ...dbExtra]
                      if (candidates.length === 0) {
                        const msg = addModalLinkSearching ? 'Searching all orders\u2026'
                          : s.length < 2 ? 'Type a docket, name, room or item to search all orders (any date).'
                          : 'No matching orders found. Check the spelling, or create a new order.'
                        return <p className="px-3 py-4 text-xs text-gray-400 text-center">{msg}</p>
                      }
                      return candidates.slice(0, 60).map(o => {
                        const cost = computeOrderCost(o)
                        const items = (o.order_items || []).map(it => `${it.quantity_sent}x ${it.item_name}`).join(', ')
                        const sel = addModalLinkOrderId === o.id
                        const priceGap = Math.abs(cost - addModal.row.invoiceLine.net) >= 0.02
                        const fromOtherPeriod = !localIds.has(o.id)
                        const who = o.room_number ? `Room ${o.room_number}${o.guest_name ? ` (${o.guest_name})` : ''}` : (o.department?.name || o.staff_name || 'Unallocated')
                        return (
                          <button key={o.id} onClick={() => { setAddModalLinkOrderId(o.id); setAddModalLinkDocket(o.docket_number); setAddModalLinkUpdatePrice(priceGap) }}
                            className={`w-full text-left px-3 py-2 text-xs hover:bg-blue-50 ${sel ? 'bg-blue-100' : ''}`}>
                            <div className="flex justify-between font-medium">
                              <span className="font-mono">#{o.docket_number}{fromOtherPeriod && <span className="ml-1 text-[9px] font-normal text-amber-600 bg-amber-50 rounded px-1">elsewhere</span>}</span>
                              <span>{'\u00a3'}{cost.toFixed(2)} {!priceGap ? '\u2713' : `(inv ${'\u00a3'}${addModal.row.invoiceLine.net.toFixed(2)})`}</span>
                            </div>
                            <div className="text-gray-500">{format(new Date(o.created_at), 'dd/MM/yy')}{' \u00b7 '}{who}{' \u00b7 '}{items || '\u2014'}</div>
                          </button>
                        )
                      })
                    })()}
                  </div>

                  {/* Once an order is picked: correct the ticket + optionally sync price */}
                  {addModalLinkOrderId && (
                    <div className="space-y-3 bg-blue-50/50 border border-blue-100 rounded-lg p-3">
                      <div>
                        <label className="block text-sm font-medium text-gray-700 mb-1">Ticket / docket to record on this order</label>
                        <input type="text" value={addModalLinkDocket} onChange={e => setAddModalLinkDocket(e.target.value)}
                          className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm font-mono focus:outline-none focus:ring-2 focus:ring-navy/30" />
                        <p className="text-[10px] text-gray-500 mt-0.5">Correct it if the invoice ticket is wrong, or keep our docket {'\u2014'} the two are linked either way.</p>
                      </div>
                      <div>
                        <label className="block text-sm font-medium text-gray-700 mb-1">Department (correct it if wrong)</label>
                        <select value={addModalLinkDept} onChange={e => setAddModalLinkDept(e.target.value)}
                          className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-navy/30">
                          <option value="">
                            Keep current ({(orders.find(o => o.id === addModalLinkOrderId) ?? addModalLinkDbResults.find(o => o.id === addModalLinkOrderId))?.department?.name || 'Unallocated'})
                          </option>
                          {departments.map(d => <option key={d.id} value={d.id}>{d.name}</option>)}
                        </select>
                      </div>
                      {(() => {
                        const t = orders.find(o => o.id === addModalLinkOrderId) ?? addModalLinkDbResults.find(o => o.id === addModalLinkOrderId)
                        const sysCost = t ? computeOrderCost(t) : 0
                        const gap = Math.abs(sysCost - addModal.row.invoiceLine.net) >= 0.02
                        if (!gap) return null
                        return (
                          <label className="flex items-center gap-2 text-sm text-gray-700 cursor-pointer">
                            <input type="checkbox" checked={addModalLinkUpdatePrice} onChange={e => setAddModalLinkUpdatePrice(e.target.checked)} className="rounded" />
                            Update this order&apos;s price {'\u00a3'}{sysCost.toFixed(2)} {'\u2192'} {'\u00a3'}{addModal.row.invoiceLine.net.toFixed(2)} (match the invoice)
                          </label>
                        )
                      })()}
                      <div>
                        <label className="block text-sm font-medium text-gray-700 mb-1">Note (optional \u2014 why the ticket/room was wrong, for the audit trail)</label>
                        <input type="text" value={addModalNote} onChange={e => setAddModalNote(e.target.value)}
                          placeholder="e.g. Invoice shows ticket 7208 but our docket is 6208"
                          className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-navy/30" />
                      </div>
                    </div>
                  )}
                </div>
              )}

              {/* \u2500\u2500 CREATE MODE \u2500\u2500 */}
              {addModalMode === 'create' && (<>
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
              </>)}

              <div className="flex gap-3 pt-2">
                <button onClick={() => setAddModal(null)} className="flex-1 px-4 py-2 text-sm text-gray-700 bg-gray-100 rounded-lg hover:bg-gray-200">
                  Cancel
                </button>
                {addModalMode === 'create' ? (
                  <button
                    onClick={handleAddToSystem}
                    disabled={!addModalDept || addModalSaving || (likelyExisting.length > 0 && !addCreateAnyway)}
                    className="flex-1 flex items-center justify-center gap-2 px-4 py-2 text-sm font-medium text-white bg-blue-600 rounded-lg hover:bg-blue-700 disabled:opacity-50"
                  >
                    {addModalSaving ? <RefreshCw className="w-4 h-4 animate-spin" /> : <Plus className="w-4 h-4" />}
                    {addModalSaving ? 'Adding...' : 'Add Order'}
                  </button>
                ) : (
                  <button
                    onClick={handleLinkExisting}
                    disabled={!addModalLinkOrderId || addModalSaving}
                    className="flex-1 flex items-center justify-center gap-2 px-4 py-2 text-sm font-medium text-white bg-blue-600 rounded-lg hover:bg-blue-700 disabled:opacity-50"
                  >
                    {addModalSaving ? <RefreshCw className="w-4 h-4 animate-spin" /> : <ArrowRightLeft className="w-4 h-4" />}
                    {addModalSaving ? 'Linking...' : 'Link Order'}
                  </button>
                )}
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
