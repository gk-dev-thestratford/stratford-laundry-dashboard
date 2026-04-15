import { jsPDF } from 'jspdf'
import autoTable from 'jspdf-autotable'
import type { ParsedInvoice } from './invoiceParser'

// ── Types ──

export interface DepartmentDisplayRow {
  departmentName: string
  lineLabel: string
  isTopUp: boolean
  orderCount: number
  invoiceNet: number
  systemTotal: number
  difference: number
  totalGross: number
}

interface ReconciliationResultForPdf {
  rows: {
    invoiceLine: { ticket: string; date: string; description: string; net: number; vat: number; gross: number; guestInfo?: string }
    sectionType: string
    order: { department?: { name: string } | null; staff_name?: string | null; guest_name?: string | null } | null
    status: 'matched' | 'price_mismatch' | 'not_found'
    systemTotal: number
    difference: number
  }[]
  topUpCharges: { net: number }[]
  missingFromInvoice: {
    docket_number: string
    department?: { name: string } | null
    order_type: string
    order_items?: { quantity_sent: number; item_name: string }[]
    total_price: number | null
  }[]
  stats: { matched: number; priceMismatch: number; notFound: number; missing: number }
  invoiceTotal: number
  systemTotal: number
}

// ── Brand colours ──

const NAVY = '#1B2A4A'
const GOLD = '#C9A84C'
const LIGHT_GRAY = '#F3F4F6'

// ── Generator ──

export interface UniformMinWeek {
  dateRange: string
  items: { key: string; sent: number; topUp: number; min: number }[]
  topUpNet: number
}

export interface NapkinDeptAllocation {
  deptName: string
  totalSent: number
  pctShare: number
  totalActualCost: number
  totalTopUpAlloc: number
  totalCost: number
}

export interface NapkinWeekSummary {
  dateRange: string
  invoiceSentQty: number
  topUpQty: number
  topUpNet: number
  totalChargedQty: number
  totalNet: number
  deptBreakdown: { deptName: string; sentQty: number; topUpAlloc: number; totalCost: number }[]
}

export interface FinancialTotals {
  lineItemsNet: number
  topUpNet: number
  invoiceNet: number
  invoiceVat: number
  invoiceGross: number
  systemNet: number
}

export function generateReconciliationPdf(
  invoice: ParsedInvoice,
  result: ReconciliationResultForPdf,
  displayRows: DepartmentDisplayRow[],
  napkinDeptAllocation?: NapkinDeptAllocation[],
  uniformMinWeeks?: UniformMinWeek[],
  napkinWeeks?: NapkinWeekSummary[],
  financials?: FinancialTotals
): jsPDF {
  const doc = new jsPDF()
  const pageWidth = doc.internal.pageSize.getWidth()
  // Use pre-computed financials from the reconciliation page (same as on-screen)
  const totalTopUp = financials?.topUpNet ?? result.topUpCharges.reduce((s, l) => s + l.net, 0)
  const lineItemsNet = financials?.lineItemsNet ?? result.invoiceTotal
  const grandNet = financials?.invoiceNet ?? (result.invoiceTotal + totalTopUp)
  const grandVat = financials?.invoiceVat ?? +(grandNet * 0.2).toFixed(2)
  const grandGross = financials?.invoiceGross ?? +(grandNet * 1.2).toFixed(2)
  let y = 15

  // ── Header ──
  doc.setFillColor(NAVY)
  doc.rect(0, 0, pageWidth, 22, 'F')
  doc.setTextColor(GOLD)
  doc.setFontSize(14)
  doc.setFont('helvetica', 'bold')
  doc.text('The Stratford', 14, 10)
  doc.setFontSize(9)
  doc.setFont('helvetica', 'normal')
  doc.setTextColor('#FFFFFF')
  doc.text('Laundry Reconciliation Report', 14, 17)

  // Date generated on right
  doc.setFontSize(7)
  doc.setTextColor('#D1D5DB')
  const now = new Date()
  doc.text(
    `Generated: ${now.toLocaleDateString('en-GB')} ${now.toLocaleTimeString('en-GB', { hour: '2-digit', minute: '2-digit' })}`,
    pageWidth - 14, 17, { align: 'right' }
  )

  y = 28

  // ── Invoice metadata ──
  doc.setTextColor(NAVY)
  doc.setFontSize(10)
  doc.setFont('helvetica', 'bold')
  doc.text('Invoice Details', 14, y)
  y += 6

  doc.setFont('helvetica', 'normal')
  doc.setFontSize(9)
  doc.setTextColor('#374151')
  const meta = [
    ['Invoice Number', invoice.invoiceNumber || 'N/A'],
    ['Invoice Date', invoice.invoiceDate || 'N/A'],
    ['Invoice Period', invoice.invoicePeriod || 'N/A'],
    ['Sections', invoice.sections.map(s => s.name).join(', ')],
  ]
  for (const [label, value] of meta) {
    doc.setFont('helvetica', 'bold')
    doc.text(`${label}:`, 14, y)
    doc.setFont('helvetica', 'normal')
    doc.text(value, 55, y)
    y += 5
  }

  y += 4

  // ── Financial Summary ──
  doc.setTextColor(NAVY)
  doc.setFontSize(10)
  doc.setFont('helvetica', 'bold')
  doc.text('Financial Summary', 14, y)
  y += 2

  autoTable(doc, {
    startY: y,
    head: [['', 'NET (\u00a3)', 'VAT (\u00a3)', 'GROSS (\u00a3)']],
    body: [
      ['Invoice Line Items', lineItemsNet.toFixed(2), (lineItemsNet * 0.2).toFixed(2), (lineItemsNet * 1.2).toFixed(2)],
      ['TopUp Charges', totalTopUp.toFixed(2), (totalTopUp * 0.2).toFixed(2), (totalTopUp * 1.2).toFixed(2)],
      ['Grand Total (Invoice)', grandNet.toFixed(2), grandVat.toFixed(2), grandGross.toFixed(2)],
      ['System Total', (financials?.systemNet ?? result.systemTotal).toFixed(2), ((financials?.systemNet ?? result.systemTotal) * 0.2).toFixed(2), ((financials?.systemNet ?? result.systemTotal) * 1.2).toFixed(2)],
    ],
    theme: 'grid',
    styles: { fontSize: 8, cellPadding: 2 },
    headStyles: { fillColor: NAVY, textColor: '#FFFFFF', fontStyle: 'bold' },
    columnStyles: {
      0: { fontStyle: 'bold', cellWidth: 50 },
      1: { halign: 'right' },
      2: { halign: 'right' },
      3: { halign: 'right' },
    },
    margin: { left: 14, right: 14 },
  })

  y = (doc as any).lastAutoTable.finalY + 8

  // ── Department Breakdown (with TopUp split) ──
  // Check if we need a new page
  if (y > 220) {
    doc.addPage()
    y = 15
  }

  doc.setTextColor(NAVY)
  doc.setFontSize(10)
  doc.setFont('helvetica', 'bold')
  doc.text('Department Breakdown', 14, y)
  y += 2

  const deptBody: (string | { content: string; styles?: Record<string, any> })[][] = []
  for (const row of displayRows) {
    const isRealTopUp = row.isTopUp && row.lineLabel === 'Minimum TopUp'
    const label = row.isTopUp
      ? `    ${row.departmentName} \u2014 ${row.lineLabel}`
      : `${row.departmentName} \u2014 ${row.lineLabel}`

    const rowCostNet = row.invoiceNet
    deptBody.push([
      { content: label, styles: row.isTopUp ? { fontStyle: 'italic', textColor: '#6B7280' } : {} },
      isRealTopUp ? '\u2014' : String(row.orderCount),
      isRealTopUp ? '\u2014' : row.invoiceNet.toFixed(2),
      isRealTopUp ? row.invoiceNet.toFixed(2) : '\u2014',
      rowCostNet.toFixed(2),
      row.totalGross.toFixed(2),
    ])
  }

  // Totals row
  const totalOrders = displayRows.filter(r => !r.isTopUp).reduce((s, r) => s + r.orderCount, 0)
  const totalItemsNet = displayRows.filter(r => !r.isTopUp).reduce((s, r) => s + r.invoiceNet, 0)
  const totalTopUpAlloc = displayRows.filter(r => r.isTopUp).reduce((s, r) => s + r.invoiceNet, 0)
  const totalCostNet = displayRows.reduce((s, r) => s + r.invoiceNet, 0)
  const totalGross = displayRows.reduce((s, r) => s + r.totalGross, 0)
  deptBody.push([
    { content: 'TOTAL', styles: { fontStyle: 'bold' } },
    String(totalOrders),
    totalItemsNet.toFixed(2),
    totalTopUpAlloc.toFixed(2),
    totalCostNet.toFixed(2),
    totalGross.toFixed(2),
  ])

  autoTable(doc, {
    startY: y,
    head: [['Department / Line', 'Orders', 'Items NET (\u00a3)', 'TopUp Alloc (\u00a3)', 'Total Cost NET (\u00a3)', 'Total inc VAT (\u00a3)']],
    body: deptBody,
    theme: 'grid',
    styles: { fontSize: 7.5, cellPadding: 2 },
    headStyles: { fillColor: NAVY, textColor: '#FFFFFF', fontStyle: 'bold', fontSize: 7.5 },
    columnStyles: {
      0: { cellWidth: 55 },
      1: { halign: 'right', cellWidth: 16 },
      2: { halign: 'right', cellWidth: 26 },
      3: { halign: 'right', cellWidth: 26 },
      4: { halign: 'right', cellWidth: 28 },
      5: { halign: 'right', cellWidth: 30 },
    },
    margin: { left: 14, right: 14 },
    didParseCell: (data) => {
      // Style last row as total
      if (data.row.index === deptBody.length - 1) {
        data.cell.styles.fillColor = LIGHT_GRAY
        data.cell.styles.fontStyle = 'bold'
      }
    },
  })

  y = (doc as any).lastAutoTable.finalY + 8


  // ── Napkin Weekly Minimum TopUp Breakdown ──
  if (napkinWeeks && napkinWeeks.length > 0) {
    y = (doc as any).lastAutoTable?.finalY ?? y
    if (y > doc.internal.pageSize.getHeight() - 60) { doc.addPage(); y = 20 }
    y += 8
    doc.setTextColor(NAVY)
    doc.setFontSize(11)
    doc.setFont('helvetica', 'bold')
    doc.text('Napkin Minimum \u2014 Weekly TopUp Breakdown', 14, y)
    y += 4

    const weekBody = napkinWeeks.map(w => [
      w.dateRange,
      w.invoiceSentQty.toLocaleString(),
      w.topUpQty.toLocaleString(),
      w.totalChargedQty.toLocaleString(),
      `\u00a3${w.topUpNet.toFixed(2)}`,
      `\u00a3${w.totalNet.toFixed(2)}`,
    ])
    const totSentQty = napkinWeeks.reduce((s, w) => s + w.invoiceSentQty, 0)
    const totTopUpQty = napkinWeeks.reduce((s, w) => s + w.topUpQty, 0)
    const totChargedQty = napkinWeeks.reduce((s, w) => s + w.totalChargedQty, 0)
    const totTopUpNet = napkinWeeks.reduce((s, w) => s + w.topUpNet, 0)
    const totNet = napkinWeeks.reduce((s, w) => s + w.totalNet, 0)
    weekBody.push([
      `Total (${napkinWeeks.length} weeks)`,
      totSentQty.toLocaleString(), totTopUpQty.toLocaleString(), totChargedQty.toLocaleString(),
      `\u00a3${totTopUpNet.toFixed(2)}`, `\u00a3${totNet.toFixed(2)}`,
    ])

    autoTable(doc, {
      startY: y,
      head: [['Week', 'Sent', 'TopUp Qty', 'Total Charged', 'TopUp NET', 'Total NET']],
      body: weekBody,
      styles: { fontSize: 8, cellPadding: 2 },
      headStyles: { fillColor: NAVY, textColor: '#FFFFFF', fontStyle: 'bold' },
      alternateRowStyles: { fillColor: '#FAFAFA' },
      columnStyles: {
        1: { halign: 'right' },
        2: { halign: 'right' },
        3: { halign: 'right' },
        4: { halign: 'right' },
        5: { halign: 'right', fontStyle: 'bold' },
      },
      margin: { left: 14, right: 14 },
      didParseCell: (data) => {
        if (data.section === 'body' && data.row.index === weekBody.length - 1) {
          data.cell.styles.fontStyle = 'bold'
          data.cell.styles.fillColor = LIGHT_GRAY
        }
        if (data.section === 'body' && data.column.index === 4 && data.row.index < weekBody.length - 1) {
          data.cell.styles.textColor = '#D97706'
        }
      },
    })
  }

  // ── Napkin Department Cost Allocation ──
  if (napkinDeptAllocation && napkinDeptAllocation.length > 0) {
    y = (doc as any).lastAutoTable?.finalY ?? y
    if (y > doc.internal.pageSize.getHeight() - 60) { doc.addPage(); y = 20 }
    y += 8
    doc.setTextColor(NAVY)
    doc.setFontSize(11)
    doc.setFont('helvetica', 'bold')
    doc.text('Napkin Minimum — Department Cost Allocation', 14, y)
    y += 4

    const napkinRows = napkinDeptAllocation.map(d => [
      d.deptName,
      d.totalSent.toLocaleString(),
      `${d.pctShare.toFixed(1)}%`,
      `£${d.totalActualCost.toFixed(2)}`,
      `£${d.totalTopUpAlloc.toFixed(2)}`,
      `£${d.totalCost.toFixed(2)}`,
      `£${(d.totalCost * 1.2).toFixed(2)}`,
    ])
    // Totals row
    const totSent = napkinDeptAllocation.reduce((s, d) => s + d.totalSent, 0)
    const totActual = napkinDeptAllocation.reduce((s, d) => s + d.totalActualCost, 0)
    const totTopUp = napkinDeptAllocation.reduce((s, d) => s + d.totalTopUpAlloc, 0)
    const totCost = napkinDeptAllocation.reduce((s, d) => s + d.totalCost, 0)
    napkinRows.push([
      'Total', totSent.toLocaleString(), '100%',
      `£${totActual.toFixed(2)}`, `£${totTopUp.toFixed(2)}`,
      `£${totCost.toFixed(2)}`, `£${(totCost * 1.2).toFixed(2)}`,
    ])

    autoTable(doc, {
      startY: y,
      head: [['Department', 'Sent', '% Share', 'Actual Cost', 'TopUp Alloc', 'Total NET', 'Total inc VAT']],
      body: napkinRows,
      styles: { fontSize: 8, cellPadding: 2 },
      headStyles: { fillColor: NAVY, textColor: '#FFFFFF', fontStyle: 'bold' },
      alternateRowStyles: { fillColor: '#FAFAFA' },
      columnStyles: {
        1: { halign: 'right' },
        2: { halign: 'right' },
        3: { halign: 'right' },
        4: { halign: 'right' },
        5: { halign: 'right', fontStyle: 'bold' },
        6: { halign: 'right', fontStyle: 'bold' },
      },
      margin: { left: 14, right: 14 },
      didParseCell: (data) => {
        // Bold the totals row
        if (data.section === 'body' && data.row.index === napkinRows.length - 1) {
          data.cell.styles.fontStyle = 'bold'
          data.cell.styles.fillColor = LIGHT_GRAY
        }
        // Amber colour for TopUp column
        if (data.section === 'body' && data.column.index === 4 && data.row.index < napkinRows.length - 1) {
          data.cell.styles.textColor = '#D97706'
        }
      },
    })
  }

  // ── Chef Uniform Minimum Usage ──
  if (uniformMinWeeks && uniformMinWeeks.length > 0) {
    y = (doc as any).lastAutoTable?.finalY ?? y
    if (y > doc.internal.pageSize.getHeight() - 60) { doc.addPage(); y = 20 }
    y += 8
    doc.setTextColor(NAVY)
    doc.setFontSize(11)
    doc.setFont('helvetica', 'bold')
    doc.text('Chef Uniform Minimum Usage \u2014 Main Kitchen', 14, y)
    y += 4

    const itemKeys = uniformMinWeeks[0]?.items.map(i => i.key) ?? []
    const head = ['Week', ...itemKeys.flatMap(k => [`${k} Sent`, 'TopUp', 'Used%']), 'TopUp NET']

    const body = uniformMinWeeks.map(w => {
      const cells: string[] = [w.dateRange]
      for (const it of w.items) {
        const pct = Math.round(it.sent / it.min * 100)
        cells.push(String(it.sent), it.topUp > 0 ? String(it.topUp) : '\u2014', `${pct}%`)
      }
      cells.push(`\u00a3${w.topUpNet.toFixed(2)}`)
      return cells
    })

    autoTable(doc, {
      startY: y,
      head: [head],
      body,
      styles: { fontSize: 7, cellPadding: 1.5 },
      headStyles: { fillColor: NAVY, textColor: '#FFFFFF', fontStyle: 'bold', fontSize: 6 },
      alternateRowStyles: { fillColor: '#FAFAFA' },
      columnStyles: Object.fromEntries(
        Array.from({ length: head.length }, (_, i) => [i, { halign: i === 0 ? 'left' as const : 'right' as const }])
      ),
      margin: { left: 14, right: 14 },
    })
  }

  // ── Footer on every page ──
  const pageCount = doc.getNumberOfPages()
  for (let i = 1; i <= pageCount; i++) {
    doc.setPage(i)
    const pgHeight = doc.internal.pageSize.getHeight()
    doc.setFillColor(NAVY)
    doc.rect(0, pgHeight - 12, pageWidth, 12, 'F')
    doc.setTextColor('#9CA3AF')
    doc.setFontSize(7)
    doc.setFont('helvetica', 'normal')
    doc.text('Generated by The Stratford Laundry Dashboard', 14, pgHeight - 4.5)
    doc.text(`Page ${i} of ${pageCount}`, pageWidth - 14, pgHeight - 4.5, { align: 'right' })
  }

  return doc
}

/** Generate the report and trigger a browser download. */
export function downloadReconciliationPdf(
  invoice: ParsedInvoice,
  result: ReconciliationResultForPdf,
  displayRows: DepartmentDisplayRow[],
  napkinDeptAllocation?: NapkinDeptAllocation[],
  uniformMinWeeks?: UniformMinWeek[],
  napkinWeeks?: NapkinWeekSummary[],
  financials?: FinancialTotals
): void {
  const doc = generateReconciliationPdf(invoice, result, displayRows, napkinDeptAllocation, uniformMinWeeks, napkinWeeks, financials)
  doc.save(`reconciliation-report-${invoice.invoiceNumber || 'report'}.pdf`)
}

/** Generate the report and return as a Blob (for uploading to storage). */
export function generateReconciliationPdfBlob(
  invoice: ParsedInvoice,
  result: ReconciliationResultForPdf,
  displayRows: DepartmentDisplayRow[],
  napkinDeptAllocation?: NapkinDeptAllocation[],
  uniformMinWeeks?: UniformMinWeek[],
  napkinWeeks?: NapkinWeekSummary[],
  financials?: FinancialTotals
): Blob {
  const doc = generateReconciliationPdf(invoice, result, displayRows, napkinDeptAllocation, uniformMinWeeks, napkinWeeks, financials)
  return doc.output('blob')
}
