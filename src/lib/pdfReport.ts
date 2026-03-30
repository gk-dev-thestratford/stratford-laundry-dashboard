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

export function generateReconciliationPdf(
  invoice: ParsedInvoice,
  result: ReconciliationResultForPdf,
  displayRows: DepartmentDisplayRow[]
): jsPDF {
  const doc = new jsPDF()
  const pageWidth = doc.internal.pageSize.getWidth()
  const totalTopUp = result.topUpCharges.reduce((s, l) => s + l.net, 0)
  const grandNet = result.invoiceTotal + totalTopUp
  let y = 15

  // ── Header ──
  doc.setFillColor(NAVY)
  doc.rect(0, 0, pageWidth, 32, 'F')
  doc.setTextColor(GOLD)
  doc.setFontSize(18)
  doc.setFont('helvetica', 'bold')
  doc.text('The Stratford', 14, 16)
  doc.setFontSize(11)
  doc.setFont('helvetica', 'normal')
  doc.setTextColor('#FFFFFF')
  doc.text('Laundry Reconciliation Report', 14, 25)

  // Date generated on right
  doc.setFontSize(8)
  doc.setTextColor('#D1D5DB')
  const now = new Date()
  doc.text(
    `Generated: ${now.toLocaleDateString('en-GB')} ${now.toLocaleTimeString('en-GB', { hour: '2-digit', minute: '2-digit' })}`,
    pageWidth - 14, 25, { align: 'right' }
  )

  y = 40

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
      ['Invoice Line Items', result.invoiceTotal.toFixed(2), (result.invoiceTotal * 0.2).toFixed(2), (result.invoiceTotal * 1.2).toFixed(2)],
      ['TopUp Charges', totalTopUp.toFixed(2), (totalTopUp * 0.2).toFixed(2), (totalTopUp * 1.2).toFixed(2)],
      ['Grand Total (Invoice)', grandNet.toFixed(2), (grandNet * 0.2).toFixed(2), (grandNet * 1.2).toFixed(2)],
      ['System Total', result.systemTotal.toFixed(2), (result.systemTotal * 0.2).toFixed(2), (result.systemTotal * 1.2).toFixed(2)],
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

  // ── Reconciliation Stats ──
  doc.setTextColor(NAVY)
  doc.setFontSize(10)
  doc.setFont('helvetica', 'bold')
  doc.text('Reconciliation Summary', 14, y)
  y += 2

  autoTable(doc, {
    startY: y,
    head: [['Metric', 'Count']],
    body: [
      ['Matched Orders', String(result.stats.matched)],
      ['Price Mismatches', String(result.stats.priceMismatch)],
      ['Not Found in System', String(result.stats.notFound)],
      ['Missing from Invoice', String(result.stats.missing)],
    ],
    theme: 'grid',
    styles: { fontSize: 8, cellPadding: 2 },
    headStyles: { fillColor: NAVY, textColor: '#FFFFFF', fontStyle: 'bold' },
    columnStyles: {
      0: { fontStyle: 'bold', cellWidth: 50 },
      1: { halign: 'right', cellWidth: 25 },
    },
    tableWidth: 75,
    margin: { left: 14 },
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
    const isSubRow = row.isTopUp && row.lineLabel !== 'Minimum TopUp'
    const label = row.isTopUp
      ? `    ${row.departmentName} \u2014 ${row.lineLabel}`
      : `${row.departmentName} \u2014 ${row.lineLabel}`

    deptBody.push([
      { content: label, styles: row.isTopUp ? { fontStyle: 'italic', textColor: '#6B7280' } : {} },
      isRealTopUp ? '\u2014' : String(row.orderCount),
      row.invoiceNet.toFixed(2),
      isRealTopUp ? '\u2014' : row.systemTotal.toFixed(2),
      isRealTopUp ? '\u2014' : (Math.abs(row.difference) < 0.02 ? '\u2713' : row.difference.toFixed(2)),
      row.totalGross.toFixed(2),
    ])
  }

  // Totals row
  const totalOrders = displayRows.filter(r => !r.isTopUp).reduce((s, r) => s + r.orderCount, 0)
  const totalInvNet = displayRows.reduce((s, r) => s + r.invoiceNet, 0)
  const totalSysNet = displayRows.filter(r => !r.isTopUp).reduce((s, r) => s + r.systemTotal, 0)
  const totalDiff = displayRows.filter(r => !r.isTopUp).reduce((s, r) => s + r.difference, 0)
  const totalGross = displayRows.reduce((s, r) => s + r.totalGross, 0)
  deptBody.push([
    { content: 'TOTAL', styles: { fontStyle: 'bold' } },
    String(totalOrders),
    totalInvNet.toFixed(2),
    totalSysNet.toFixed(2),
    totalDiff.toFixed(2),
    totalGross.toFixed(2),
  ])

  autoTable(doc, {
    startY: y,
    head: [['Department / Line', 'Orders', 'Invoice NET (\u00a3)', 'System NET (\u00a3)', 'Diff (\u00a3)', 'Total inc VAT (\u00a3)']],
    body: deptBody,
    theme: 'grid',
    styles: { fontSize: 7.5, cellPadding: 2 },
    headStyles: { fillColor: NAVY, textColor: '#FFFFFF', fontStyle: 'bold', fontSize: 7.5 },
    columnStyles: {
      0: { cellWidth: 60 },
      1: { halign: 'right', cellWidth: 18 },
      2: { halign: 'right', cellWidth: 28 },
      3: { halign: 'right', cellWidth: 28 },
      4: { halign: 'right', cellWidth: 22 },
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

  // ── Discrepancies ──
  const mismatches = result.rows.filter(r => r.status === 'price_mismatch')
  const notFound = result.rows.filter(r => r.status === 'not_found')

  if (mismatches.length > 0 || notFound.length > 0 || result.missingFromInvoice.length > 0) {
    if (y > 230) {
      doc.addPage()
      y = 15
    }

    doc.setTextColor(NAVY)
    doc.setFontSize(10)
    doc.setFont('helvetica', 'bold')
    doc.text('Discrepancies', 14, y)
    y += 2

    const discBody: string[][] = []

    for (const r of mismatches) {
      discBody.push([
        'Price Mismatch',
        r.invoiceLine.ticket,
        r.order?.department?.name || '\u2014',
        r.invoiceLine.net.toFixed(2),
        r.systemTotal.toFixed(2),
        r.difference.toFixed(2),
      ])
    }

    for (const r of notFound) {
      discBody.push([
        'Not Found',
        r.invoiceLine.ticket,
        '\u2014',
        r.invoiceLine.net.toFixed(2),
        '\u2014',
        r.invoiceLine.net.toFixed(2),
      ])
    }

    for (const o of result.missingFromInvoice) {
      const cost = o.total_price ?? 0
      discBody.push([
        'Missing from Invoice',
        o.docket_number,
        o.department?.name || '\u2014',
        '\u2014',
        cost.toFixed(2),
        (-cost).toFixed(2),
      ])
    }

    autoTable(doc, {
      startY: y,
      head: [['Issue', 'Docket', 'Department', 'Invoice NET (\u00a3)', 'System NET (\u00a3)', 'Diff (\u00a3)']],
      body: discBody,
      theme: 'grid',
      styles: { fontSize: 7.5, cellPadding: 2 },
      headStyles: { fillColor: NAVY, textColor: '#FFFFFF', fontStyle: 'bold', fontSize: 7.5 },
      columnStyles: {
        0: { cellWidth: 35 },
        1: { cellWidth: 22 },
        2: { cellWidth: 35 },
        3: { halign: 'right', cellWidth: 28 },
        4: { halign: 'right', cellWidth: 28 },
        5: { halign: 'right', cellWidth: 22 },
      },
      margin: { left: 14, right: 14 },
      didParseCell: (data) => {
        if (data.section === 'body' && data.column.index === 0) {
          const issue = data.cell.raw as string
          if (issue === 'Price Mismatch') data.cell.styles.textColor = '#D97706'
          else if (issue === 'Not Found') data.cell.styles.textColor = '#DC2626'
          else if (issue === 'Missing from Invoice') data.cell.styles.textColor = '#2563EB'
        }
      },
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

  doc.save(`reconciliation-report-${invoice.invoiceNumber || 'report'}.pdf`)

  return doc
}

/** Generate the same report but return the PDF as a Blob (for uploading to storage). */
export function generateReconciliationPdfBlob(
  invoice: ParsedInvoice,
  result: ReconciliationResultForPdf,
  displayRows: DepartmentDisplayRow[]
): Blob {
  const doc = generateReconciliationPdf(invoice, result, displayRows)
  return doc.output('blob')
}
