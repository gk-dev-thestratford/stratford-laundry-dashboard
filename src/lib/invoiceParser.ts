import { getDocument, GlobalWorkerOptions } from 'pdfjs-dist'

// Use local worker bundled with pdfjs-dist
import workerUrl from 'pdfjs-dist/build/pdf.worker.min.mjs?url'
GlobalWorkerOptions.workerSrc = workerUrl

// ── Types ──

export interface InvoiceItem {
  quantity: number
  name: string
}

export interface InvoiceLine {
  date: string
  ticket: string
  guestInfo?: string
  description: string
  items: InvoiceItem[]
  net: number
  vat: number
  gross: number
  isTopUp: boolean
  sectionType?: InvoiceSectionType
}

export type InvoiceSectionType = 'staff' | 'guest' | 'napkins' | 'table_cloths' | 'bathrobes' | 'hsk'

export interface InvoiceSection {
  name: string
  type: InvoiceSectionType
  lines: InvoiceLine[]
}

export interface ParsedInvoice {
  invoiceNumber: string
  invoiceDate: string
  invoicePeriod: string
  sections: InvoiceSection[]
  totals: { net: number; vat: number; gross: number }
}

export function sectionTypeToOrderType(type: InvoiceSectionType): string {
  switch (type) {
    case 'staff': return 'uniform'
    case 'guest': return 'guest_laundry'
    case 'napkins': case 'table_cloths': return 'fnb_linen'
    case 'bathrobes': case 'hsk': return 'hsk_linen'
  }
}

// ── PDF text extraction ──

/**
 * Merge consecutive lines where a description got split from its prices.
 * e.g. Line 1: "25/01/26 8004 1x duvet" (no prices)
 *      Line 2: "£11.99 £2.40 £14.39"   (prices only)
 * → merged: "25/01/26 8004 1x duvet £11.99 £2.40 £14.39"
 */
function mergeSplitLines(lines: string[]): string[] {
  const priceEnd = /£\s*[\d,]+\.\d{2}\s+£\s*[\d,]+\.\d{2}\s+£\s*[\d,]+\.\d{2}\s*$/
  const result: string[] = []

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i]
    if (priceEnd.test(line) && result.length > 0) {
      const prev = result[result.length - 1]
      // If the previous line has no £ signs, it's likely a split description
      if (!/£/.test(prev) && prev.length < 120
        && !/^(DATE|TICKET|NET|VAT|GROSS|Invoice|Account|Company|Goldstar|Sort|National)/i.test(prev)) {
        result[result.length - 1] = (prev + ' ' + line).replace(/\s+/g, ' ').trim()
        continue
      }
    }
    result.push(line)
  }
  return result
}

export async function extractPdfLines(file: File): Promise<string[]> {
  const arrayBuffer = await file.arrayBuffer()
  const pdf = await getDocument({ data: new Uint8Array(arrayBuffer) }).promise
  const allLines: string[] = []

  for (let p = 1; p <= pdf.numPages; p++) {
    const page = await pdf.getPage(p)
    const content = await page.getTextContent()

    // Collect all text items with positions
    const textItems: { x: number; y: number; str: string }[] = []
    for (const item of content.items) {
      if (!('str' in item) || !(item as any).str?.trim()) continue
      textItems.push({
        x: (item as any).transform[4] as number,
        y: (item as any).transform[5] as number,
        str: (item as any).str,
      })
    }

    // Sort by Y descending (top to bottom of page)
    textItems.sort((a, b) => b.y - a.y)

    // Cluster items into lines using Y-proximity (tolerance of 3 units)
    // This handles cases where text items on the same visual line have
    // slightly different Y positions (e.g. currency symbol vs number)
    const LINE_TOLERANCE = 3
    const lineGroups: { x: number; str: string }[][] = []
    let currentY = -Infinity

    for (const item of textItems) {
      if (Math.abs(item.y - currentY) > LINE_TOLERANCE || lineGroups.length === 0) {
        lineGroups.push([])
        currentY = item.y
      }
      lineGroups[lineGroups.length - 1].push({ x: item.x, str: item.str })
    }

    // Sort items within each line left-to-right and join
    for (const group of lineGroups) {
      group.sort((a, b) => a.x - b.x)
      const text = group.map(i => i.str).join(' ').replace(/\s+/g, ' ').trim()
      if (text) allLines.push(text)
    }
  }

  // Post-process: merge lines where description and prices got split
  return mergeSplitLines(allLines)
}

/** Extract raw PDF lines for diagnostics (unmerged) */
export async function extractPdfLinesRaw(file: File): Promise<string[]> {
  const arrayBuffer = await file.arrayBuffer()
  const pdf = await getDocument({ data: new Uint8Array(arrayBuffer) }).promise
  const allLines: string[] = []
  for (let p = 1; p <= pdf.numPages; p++) {
    allLines.push(`--- PAGE ${p} ---`)
    const page = await pdf.getPage(p)
    const content = await page.getTextContent()
    const textItems: { x: number; y: number; str: string }[] = []
    for (const item of content.items) {
      if (!('str' in item) || !(item as any).str?.trim()) continue
      textItems.push({
        x: (item as any).transform[4] as number,
        y: (item as any).transform[5] as number,
        str: (item as any).str,
      })
    }
    textItems.sort((a, b) => b.y - a.y || a.x - b.x)
    for (const item of textItems) {
      allLines.push(`[Y=${item.y.toFixed(1)} X=${item.x.toFixed(1)}] ${item.str}`)
    }
  }
  return allLines
}

// ── Parsing helpers ──

function parseDescriptionItems(desc: string): InvoiceItem[] {
  const items: InvoiceItem[] = []
  const regex = /(\d+)x\s+([^,]+)/g
  let m
  while ((m = regex.exec(desc)) !== null) {
    items.push({
      quantity: parseInt(m[1]),
      name: m[2].trim()
        .replace(/\s+express\s+charge\s+added/i, '')
        .replace(/\s+overnight\s+express\s+added/i, '')
        .trim(),
    })
  }
  return items
}

function parseLine(raw: string, lastDate: string): (InvoiceLine & { parsedDate: string }) | null {
  const line = raw.trim()
  if (!line) return null

  // Skip non-data lines (headers, company info, etc.)
  if (/^(DATE|TICKET|NUMBER|DESCRIPTION|NET\b|VAT\b|GROSS|Goldstar|Manhattan|Olympic|London|United|020|Account|Sort|Company|National|Invoice)/i.test(line)) return null

  // Must have 3 price values: £ net £vat £gross
  const priceRe = /£\s*([\d,]+\.\d{2})\s+£\s*([\d,]+\.\d{2})\s+£\s*([\d,]+\.\d{2})\s*$/
  const pm = line.match(priceRe)
  if (!pm) return null

  const net = parseFloat(pm[1].replace(',', ''))
  const vat = parseFloat(pm[2].replace(',', ''))
  const gross = parseFloat(pm[3].replace(',', ''))
  let before = line.substring(0, pm.index).trim()
  if (!before) return null

  // Strip leading section name if merged with data line during extraction
  // e.g. "Guest 02/01/26 604 (Liu) 1x jumper" → "02/01/26 604 (Liu) 1x jumper"
  const sectionPrefixM = before.match(/^(Staff|Guest|Napkins?|Table\s*Cloths?|Bathrobes?|HSK)\s+/i)
  if (sectionPrefixM) {
    before = before.substring(sectionPrefixM[0].length).trim()
  }

  // Extract date (range or single)
  let date = lastDate
  const drm = before.match(/^(\d{2}\/\d{2}(?:\/\d{2,4})?\s*-\s*\d{2}\/\d{2}(?:\/\d{2,4})?)\s+(.*)/)
  const dm = before.match(/^(\d{2}\/\d{2}\/\d{2,4})\s+(.*)/)
  if (drm) { date = drm[1].trim(); before = drm[2].trim() }
  else if (dm) { date = dm[1].trim(); before = dm[2].trim() }

  // Skip total/summary rows
  if (/^Total\s+\d{2}\/\d{2}/i.test(before)) return null
  if (/^Net\b|^VAT\b|^Total\b/i.test(before)) return null

  // Extract ticket
  let ticket = ''
  let description = before
  let guestInfo: string | undefined

  const guestM = before.match(/^(\d{3,4})\s*(\([^)]+\))\s+(.*)/)
  const topUpM = before.match(/^(Minimum TopUp)\s+(.*)/)
  const napkinM = before.match(/^(NAPKINS)\s+(.*)/)
  const ntnM = before.match(/^(NTN)\s+(.*)/)
  const stdM = before.match(/^(\d{4})\s+(.*)/)

  if (guestM) { ticket = guestM[1]; guestInfo = guestM[2]; description = guestM[3].trim() }
  else if (topUpM) { ticket = 'Minimum TopUp'; description = topUpM[2].trim() }
  else if (napkinM) { ticket = 'NAPKINS'; description = napkinM[2].trim() }
  else if (ntnM) { ticket = 'NTN'; description = ntnM[2].trim() }
  else if (stdM) { ticket = stdM[1]; description = stdM[2].trim() }

  return {
    date, ticket, guestInfo, description,
    items: parseDescriptionItems(description),
    net, vat, gross,
    isTopUp: ticket === 'Minimum TopUp',
    parsedDate: date,
  }
}

const SECTION_NAMES: Record<string, InvoiceSectionType> = {
  'staff': 'staff',
  'guest': 'guest',
  'napkins': 'napkins',
  'table cloths': 'table_cloths',
  'tablecloths': 'table_cloths',
  'bathrobes': 'bathrobes',
  'bathrobe': 'bathrobes',
  'hsk': 'hsk',
}

function detectSection(line: string): InvoiceSectionType | null {
  const lower = line.toLowerCase().trim()
  // Section headers are short lines without prices
  if (lower.length > 40) return null
  if (lower.includes('£')) return null

  // Exact match first
  if (SECTION_NAMES[lower]) return SECTION_NAMES[lower]

  // Substring/keyword match for variations like "STAFF UNIFORMS", "GUEST LAUNDRY"
  if (/\bstaff\b/.test(lower)) return 'staff'
  if (/\bguest\b/.test(lower)) return 'guest'
  if (/\bnapkin/.test(lower)) return 'napkins'
  if (/\btable\s*cloth/.test(lower)) return 'table_cloths'
  if (/\bbathrobe/.test(lower)) return 'bathrobes'
  if (/\bhsk\b/.test(lower)) return 'hsk'

  return null
}

// ── Main parser ──

export function parseInvoice(lines: string[]): ParsedInvoice {
  let invoiceNumber = ''
  let invoiceDate = ''
  let invoicePeriod = ''
  let totalNet = 0, totalVat = 0, totalGross = 0

  const sections: InvoiceSection[] = []
  let currentSection: InvoiceSection | null = null
  let lastDate = ''

  // First pass: join all lines to extract metadata that might be split
  const fullText = lines.join('\n')

  // Extract metadata from full text (handles multi-line and merged lines)
  const numFull = fullText.match(/Invoice\s*Number[:\s]+([A-Z0-9]+)/i)
  if (numFull) invoiceNumber = numFull[1]

  const dateFull = fullText.match(/Invoice\s*Date[:\s]+(\d{2}[\./]\d{2}[\./]\d{2,4})/i)
  if (dateFull) invoiceDate = dateFull[1]

  const periodFull = fullText.match(/Invoice\s*Period[:\s]+(\d{2}[\./]\d{2}[\./]\d{2,4}\s*[-–]\s*\d{2}[\./]\d{2}[\./]\d{2,4})/i)
  if (periodFull) invoicePeriod = periodFull[1]
  else {
    // Try multi-line: period start on one line, end on next
    const periodStart = fullText.match(/Invoice\s*Period[:\s]+(\d{2}[\./]\d{2}[\./]\d{2,4}\s*[-–])\s*\n\s*(\d{2}[\./]\d{2}[\./]\d{2,4})/i)
    if (periodStart) invoicePeriod = periodStart[1] + ' ' + periodStart[2]
  }

  for (let li = 0; li < lines.length; li++) {
    const line = lines[li]

    // Grand totals
    const netM = line.match(/^Net\s+£\s*([\d,]+\.\d{2})/i)
    if (netM) totalNet = parseFloat(netM[1].replace(',', ''))

    const vatM = line.match(/^VAT\s+£\s*([\d,]+\.\d{2})/i)
    if (vatM) totalVat = parseFloat(vatM[1].replace(',', ''))

    const grossM = line.match(/^Total\s+£\s*([\d,]+\.\d{2})/i)
    if (grossM) totalGross = parseFloat(grossM[1].replace(',', ''))

    // Section header
    const sectionType = detectSection(line)
    if (sectionType) {
      currentSection = { name: line.trim(), type: sectionType, lines: [] }
      sections.push(currentSection)
      continue
    }

    // Data line — if no section detected yet, create a default one
    const parsed = parseLine(line, lastDate)
    if (parsed) {
      if (!currentSection) {
        let type: InvoiceSectionType = 'staff'
        if (/GM/i.test(invoiceNumber)) type = 'guest'
        else if (/HH/i.test(invoiceNumber)) type = 'bathrobes'
        else if (/NM/i.test(invoiceNumber)) type = 'napkins'
        else if (/HM/i.test(invoiceNumber)) type = 'hsk'
        currentSection = { name: type, type, lines: [] }
        sections.push(currentSection)
      }
      const { parsedDate, ...invoiceLine } = parsed
      invoiceLine.sectionType = currentSection.type
      currentSection.lines.push(invoiceLine)
      lastDate = parsedDate
    }
  }

  return {
    invoiceNumber, invoiceDate, invoicePeriod,
    sections,
    totals: { net: totalNet, vat: totalVat, gross: totalGross },
  }
}

// ── Period parsing ──

export function parseInvoicePeriod(period: string): { start: Date; end: Date } | null {
  // Normalize: replace en-dash/em-dash with hyphen, collapse whitespace
  const normalized = period.replace(/[–—]/g, '-').replace(/\s+/g, ' ').trim()

  // Try DD.MM.YY(YY) - DD.MM.YY(YY)
  const dotM = normalized.match(/(\d{2})\.(\d{2})\.(\d{2,4})\s*-\s*(\d{2})\.(\d{2})\.(\d{2,4})/)
  if (dotM) return buildPeriod(dotM[1], dotM[2], dotM[3], dotM[4], dotM[5], dotM[6])

  // Try DD/MM/YY(YY) - DD/MM/YY(YY)
  const slashM = normalized.match(/(\d{2})\/(\d{2})\/(\d{2,4})\s*-\s*(\d{2})\/(\d{2})\/(\d{2,4})/)
  if (slashM) return buildPeriod(slashM[1], slashM[2], slashM[3], slashM[4], slashM[5], slashM[6])

  return null
}

function buildPeriod(sd: string, sm: string, sy: string, ed: string, em: string, ey: string) {
  let startY = parseInt(sy); if (startY < 100) startY += 2000
  let endY = parseInt(ey); if (endY < 100) endY += 2000
  return {
    start: new Date(Date.UTC(startY, parseInt(sm) - 1, parseInt(sd), 0, 0, 0)),
    end: new Date(Date.UTC(endY, parseInt(em) - 1, parseInt(ed), 23, 59, 59)),
  }
}

/**
 * Derive a date range from parsed invoice line dates as a fallback
 * when the invoice period text can't be parsed.
 */
export function derivePeriodFromLines(invoice: ParsedInvoice): { start: Date; end: Date } | null {
  const dates: Date[] = []
  for (const section of invoice.sections) {
    for (const line of section.lines) {
      if (!line.date) continue
      // Handle single dates DD/MM/YY or DD/MM/YYYY
      const dm = line.date.match(/(\d{2})\/(\d{2})\/(\d{2,4})/)
      if (dm) {
        let y = parseInt(dm[3]); if (y < 100) y += 2000
        dates.push(new Date(y, parseInt(dm[2]) - 1, parseInt(dm[1])))
        continue
      }
      // Handle date ranges DD/MM - DD/MM or DD/MM/YY - DD/MM/YY
      const drm = line.date.match(/(\d{2})\/(\d{2})(?:\/(\d{2,4}))?\s*-\s*(\d{2})\/(\d{2})(?:\/(\d{2,4}))?/)
      if (drm) {
        let y1 = drm[3] ? parseInt(drm[3]) : new Date().getFullYear()
        let y2 = drm[6] ? parseInt(drm[6]) : y1
        if (y1 < 100) y1 += 2000
        if (y2 < 100) y2 += 2000
        dates.push(new Date(y1, parseInt(drm[2]) - 1, parseInt(drm[1])))
        dates.push(new Date(y2, parseInt(drm[5]) - 1, parseInt(drm[4])))
      }
    }
  }
  if (dates.length === 0) return null
  const sorted = dates.sort((a, b) => a.getTime() - b.getTime())
  return {
    start: sorted[0],
    end: new Date(sorted[sorted.length - 1].getFullYear(), sorted[sorted.length - 1].getMonth(), sorted[sorted.length - 1].getDate(), 23, 59, 59),
  }
}
