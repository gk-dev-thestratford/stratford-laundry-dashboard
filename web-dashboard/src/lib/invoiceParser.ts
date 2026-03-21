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

export async function extractPdfLines(file: File): Promise<string[]> {
  const arrayBuffer = await file.arrayBuffer()
  const pdf = await getDocument({ data: new Uint8Array(arrayBuffer) }).promise
  const allLines: string[] = []

  for (let p = 1; p <= pdf.numPages; p++) {
    const page = await pdf.getPage(p)
    const content = await page.getTextContent()

    // Group text items by Y position to reconstruct lines
    const lineMap = new Map<number, { x: number; str: string }[]>()
    for (const item of content.items) {
      if (!('str' in item) || !(item as any).str?.trim()) continue
      const y = Math.round((item as any).transform[5] / 2) * 2
      const x = (item as any).transform[4] as number
      if (!lineMap.has(y)) lineMap.set(y, [])
      lineMap.get(y)!.push({ x, str: (item as any).str })
    }

    // Sort top-to-bottom, left-to-right
    const sortedYs = [...lineMap.keys()].sort((a, b) => b - a)
    for (const y of sortedYs) {
      const items = lineMap.get(y)!.sort((a, b) => a.x - b.x)
      const text = items.map(i => i.str).join(' ').replace(/\s+/g, ' ').trim()
      if (text) allLines.push(text)
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

  // Skip non-data lines
  if (/^(DATE|TICKET|NUMBER|DESCRIPTION|NET\b|VAT\b|GROSS|Goldstar|Manhattan|Olympic|London|E\d|United|020|Account|Sort|Company|National|Invoice)/i.test(line)) return null

  // Must have 3 price values: £ net £vat £gross
  const priceRe = /£\s*([\d,]+\.\d{2})\s+£\s*([\d,]+\.\d{2})\s+£\s*([\d,]+\.\d{2})\s*$/
  const pm = line.match(priceRe)
  if (!pm) return null

  const net = parseFloat(pm[1].replace(',', ''))
  const vat = parseFloat(pm[2].replace(',', ''))
  const gross = parseFloat(pm[3].replace(',', ''))
  let before = line.substring(0, pm.index).trim()
  if (!before) return null

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
  // Only match short lines that are purely section headers
  if (lower.length > 25) return null
  return SECTION_NAMES[lower] ?? null
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

  for (const line of lines) {
    // Extract metadata
    const numM = line.match(/Invoice\s*Number:\s*(\S+)/i)
    if (numM) invoiceNumber = numM[1]

    const dateM = line.match(/Invoice\s*Date:\s*(\S+)/i)
    if (dateM) invoiceDate = dateM[1]

    const periodM = line.match(/Invoice\s*Period:\s*(.+?)$/i)
    if (periodM) invoicePeriod = periodM[1].trim()

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

    // Data line
    if (currentSection) {
      const parsed = parseLine(line, lastDate)
      if (parsed) {
        const { parsedDate, ...invoiceLine } = parsed
        currentSection.lines.push(invoiceLine)
        lastDate = parsedDate
      }
    }
  }

  // If no sections detected, create one from invoice number
  if (sections.length === 0) {
    let type: InvoiceSectionType = 'staff'
    if (/GM/i.test(invoiceNumber)) type = 'guest'
    else if (/HH/i.test(invoiceNumber)) type = 'bathrobes'
    else if (/NM/i.test(invoiceNumber)) type = 'napkins'
    else if (/HM/i.test(invoiceNumber)) type = 'hsk'

    const section: InvoiceSection = { name: type, type, lines: [] }
    for (const line of lines) {
      const parsed = parseLine(line, lastDate)
      if (parsed) {
        const { parsedDate, ...invoiceLine } = parsed
        section.lines.push(invoiceLine)
        lastDate = parsedDate
      }
    }
    if (section.lines.length > 0) sections.push(section)
  }

  return {
    invoiceNumber, invoiceDate, invoicePeriod,
    sections,
    totals: { net: totalNet, vat: totalVat, gross: totalGross },
  }
}

// ── Period parsing ──

export function parseInvoicePeriod(period: string): { start: Date; end: Date } | null {
  const m = period.match(/(\d{2})\.(\d{2})\.(\d{2,4})\s*-\s*(\d{2})\.(\d{2})\.(\d{2,4})/)
  if (!m) return null
  let sy = parseInt(m[3]); if (sy < 100) sy += 2000
  let ey = parseInt(m[6]); if (ey < 100) ey += 2000
  return {
    start: new Date(sy, parseInt(m[2]) - 1, parseInt(m[1])),
    end: new Date(ey, parseInt(m[5]) - 1, parseInt(m[4]), 23, 59, 59),
  }
}
