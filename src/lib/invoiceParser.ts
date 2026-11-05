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
  /** Service tag printed in the guest-name cell (e.g. "OVER GT EX"), kept verbatim. */
  serviceNote?: string
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
  /** Which parser produced this result: 'legacy' text-line parser or column-aware 'tabular'. */
  layout?: 'legacy' | 'tabular'
}

/**
 * Canonical key for matching an invoice ticket against a stored docket_number.
 * Goldstar prints reset-booklet tickets as bare numbers (6, 16, 3) while the system
 * stores them zero-padded to 4 digits ("0006"). Normalise both sides: trim, drop a
 * leading run of zeros (but keep at least one digit), and uppercase any letters.
 *   "0006" → "6",  "6" → "6",  " 7208 " → "7208",  "ntn" → "NTN"
 */
export function canonicalDocket(value: string | null | undefined): string {
  const s = String(value ?? '').trim()
  if (!s) return ''
  return s.replace(/^0+(?=\d)/, '').toUpperCase()
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
        && !/^(DATE|TICKET|NET|VAT|GROSS|Invoice|Account|Company|Goldstar|Sort|National)/i.test(prev)
        && !/^(Staff|Guest|Napkins?|Table\s*Cloths?|Bathrobes?|HSK\b)/i.test(prev)) {
        result[result.length - 1] = (prev + ' ' + line).replace(/\s+/g, ' ').trim()
        continue
      }
    }
    result.push(line)
  }
  return result
}

export interface PdfTextItem { x: number; y: number; w: number; h: number; str: string }

/** Every non-blank text item of every page, with its position (PDF units, y grows upward). */
export async function extractPositionedPages(file: File): Promise<PdfTextItem[][]> {
  const arrayBuffer = await file.arrayBuffer()
  const pdf = await getDocument({ data: new Uint8Array(arrayBuffer) }).promise
  const pages: PdfTextItem[][] = []
  for (let p = 1; p <= pdf.numPages; p++) {
    const page = await pdf.getPage(p)
    const content = await page.getTextContent()
    const textItems: PdfTextItem[] = []
    for (const item of content.items) {
      if (!('str' in item) || !(item as any).str?.trim()) continue
      textItems.push({
        x: (item as any).transform[4] as number,
        y: (item as any).transform[5] as number,
        w: ((item as any).width as number) || 0,
        h: ((item as any).height as number) || 0,
        str: (item as any).str,
      })
    }
    pages.push(textItems)
  }
  return pages
}

/**
 * Cluster a page's items into visual rows, top to bottom, each row sorted left to right.
 * Y-proximity tolerance of 3 units handles items on the same visual line having slightly
 * different Y positions (e.g. currency symbol vs number).
 */
function clusterRows(pageItems: PdfTextItem[]): PdfTextItem[][] {
  const textItems = [...pageItems].sort((a, b) => b.y - a.y)
  const LINE_TOLERANCE = 3
  const rows: PdfTextItem[][] = []
  let currentY = -Infinity
  for (const item of textItems) {
    if (Math.abs(item.y - currentY) > LINE_TOLERANCE || rows.length === 0) {
      rows.push([])
      currentY = item.y
    }
    rows[rows.length - 1].push(item)
  }
  for (const row of rows) row.sort((a, b) => a.x - b.x)
  return rows
}

function pagesToLines(pages: PdfTextItem[][]): string[] {
  const allLines: string[] = []
  for (const page of pages) {
    for (const row of clusterRows(page)) {
      const text = row.map(i => i.str).join(' ').replace(/\s+/g, ' ').trim()
      if (text) allLines.push(text)
    }
  }
  // Post-process: merge lines where description and prices got split
  return mergeSplitLines(allLines)
}

export async function extractPdfLines(file: File): Promise<string[]> {
  return pagesToLines(await extractPositionedPages(file))
}

/**
 * Parse an invoice PDF, whichever Goldstar layout it uses. Runs the legacy text-line parser
 * and, when the page has a recognisable column header (DATE | GUEST | ROOM | DESCRIPTION |
 * NET | VAT | GROSS and permutations), the column-aware parser too — then keeps the result
 * that identified more lines (ticket/room/guest), preferring the column-aware one on a tie.
 */
export async function parseInvoiceFile(file: File): Promise<ParsedInvoice> {
  const pages = await extractPositionedPages(file)
  const legacy: ParsedInvoice = { ...parseInvoice(pagesToLines(pages)), layout: 'legacy' }
  const tabular = parseTabularInvoice(pages, legacy)
  return pickBetterParse(legacy, tabular)
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
  // "4x T-Shirt" (all layouts so far); also tolerate "4 x T-Shirt" / "4× T-Shirt"
  const regex = /(\d+)\s?[x×]\s+([^,]+)/g
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

  // Extract date (range or single). Goldstar invoices drift between two formats within
  // the same document: US M/D/YYYY (e.g. "5/1/2026") early in the month and UK DD/MM/YY
  // (e.g. "14/05/26") later. Allow 1-OR-2 digit day AND month so both parse and the date
  // gets stripped — otherwise the ticket on the first line of each day is lost.
  let date = lastDate
  const drm = before.match(/^(\d{1,2}\/\d{1,2}(?:\/\d{2,4})?\s*-\s*\d{1,2}\/\d{1,2}(?:\/\d{2,4})?)\s+(.*)/)
  const dm = before.match(/^(\d{1,2}\/\d{1,2}\/\d{2,4})\s+(.*)/)
  if (drm) { date = drm[1].trim(); before = drm[2].trim() }
  else if (dm) { date = dm[1].trim(); before = dm[2].trim() }

  // Skip total/summary rows
  if (/^Total\s+\d{1,2}\/\d{2}/i.test(before)) return null
  if (/^Net\b|^VAT\b|^Total\b/i.test(before)) return null

  // Extract ticket
  let ticket = ''
  let description = before
  let guestInfo: string | undefined

  const guestM = before.match(/^(\d{3,4})\s*(\([^)]+\))\s+(.*)/)
  const topUpM = before.match(/^(Minimum\s+Top\s*[Uu]p)\s+(.*)/)
  const napkinM = before.match(/^(NAPKINS)\s+(.*)/)
  const ntnM = before.match(/^(NTN)\s+(.*)/)
  const stdM = before.match(/^(\d{4})\s+(.*)/)
  // Short numeric ticket (1-3 digits) from a reset booklet, e.g. "6 8x bathrobes",
  // "3 1x shirts". Require a quantity token ("Nx ...") after it so we never mistake a
  // leading item quantity for a ticket.
  const shortNumM = before.match(/^(\d{1,3})\s+(\d+x\b.*)/)
  // Alphanumeric ticket (e.g. "Sam 77x napkins") — short word followed by qty description
  const alphaM = before.match(/^([A-Za-z][A-Za-z0-9]{1,10})\s+(\d+x\s+.*)/)

  if (guestM) { ticket = guestM[1]; guestInfo = guestM[2]; description = guestM[3].trim() }
  else if (topUpM) { ticket = 'Minimum TopUp'; description = topUpM[2].trim() }
  else if (napkinM) { ticket = 'NAPKINS'; description = napkinM[2].trim() }
  else if (ntnM) { ticket = 'NTN'; description = ntnM[2].trim() }
  else if (stdM) { ticket = stdM[1]; description = stdM[2].trim() }
  else if (shortNumM) { ticket = shortNumM[1]; description = shortNumM[2].trim() }
  else if (alphaM) { ticket = alphaM[1]; description = alphaM[2].trim() }

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

  // Extract metadata — the PDF layout puts labels at end of one line and values
  // at start of next line mixed with other text, e.g.:
  //   'Manhattan Loft Gardens Hotel Limited, Invoice Number:'
  //   'T/A The Stratford GSSHSM017'
  //   'Olympic Park, Invoice Date:'
  //   '20 International Wy, 31.01.2026'
  //   'London Invoice Period:'
  //   'E20 1FD 01.01.26- 31.01.26'
  // Strategy: scan each line for labels, then look for the value on the same or next line.
  // Labels may or may not carry a colon: the 2026-09 template prints "INVOICE NUMBER
  // GSSHGM011026" / "INVOICE DATE 30.09.2026" / "INVOICE PERIOD 01.09.26 – 30.09.26".
  const DATE_TOKEN = String.raw`\d{1,2}[./-]\d{1,2}[./-]\d{2,4}`
  const PERIOD_RE = new RegExp(String.raw`(${DATE_TOKEN}\s*(?:[-–—]|to)\s*${DATE_TOKEN})`, 'i')

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i]
    const nextLine = i + 1 < lines.length ? lines[i + 1] : ''

    // Invoice Number
    if (!invoiceNumber && /Invoice\s*(?:Number|No\b\.?|#)/i.test(line)) {
      // Try same line first: value after the label (code must contain letters AND digits)
      const sameM = line.match(/Invoice\s*(?:Number|No\b\.?|#)\s*:?\s*([A-Z]{2,}[A-Z0-9-]*\d[A-Z0-9-]*)/i)
      if (sameM) { invoiceNumber = sameM[1]; continue }
      // Value is on next line — find alphanumeric code pattern (e.g. GSSHSM017)
      const nextM = nextLine.match(/([A-Z]{2,}[A-Z0-9]*\d+)/i)
      if (nextM) invoiceNumber = nextM[1]
    }

    // Invoice Date
    if (!invoiceDate && /Invoice\s*Date/i.test(line)) {
      const sameM = line.match(new RegExp(String.raw`Invoice\s*Date\s*:?\s*(${DATE_TOKEN})`, 'i'))
      if (sameM) { invoiceDate = sameM[1]; continue }
      const nextM = nextLine.match(new RegExp(`(${DATE_TOKEN})`))
      if (nextM) invoiceDate = nextM[1]
    }

    // Invoice Period
    if (!invoicePeriod && /Invoice\s*Perio/i.test(line)) {
      // Try same line: full period
      const sameM = line.match(PERIOD_RE)
      if (sameM) { invoicePeriod = sameM[1]; continue }
      // Try next line for the full period
      const nextFull = nextLine.match(PERIOD_RE)
      if (nextFull) { invoicePeriod = nextFull[1]; continue }
      // Try start on same line, end on next
      const startM = line.match(new RegExp(String.raw`(${DATE_TOKEN}\s*(?:[-–—]|to))`, 'i'))
      if (startM) {
        const endM = nextLine.match(new RegExp(`(${DATE_TOKEN})`))
        if (endM) invoicePeriod = startM[1] + ' ' + endM[1]
      }
    }
  }

  for (let li = 0; li < lines.length; li++) {
    const line = lines[li]

    // Grand totals — match anywhere in line (footer layout varies across PDFs).
    // Accepts "Net £x" / "Net Total £x", "VAT £x" / "VAT (20%) £x", "Total £x" / "Total Due £x".
    const netM = line.match(/\bNet(?:\s+Total)?\s*:?\s+£\s*([\d,]+\.\d{2})/i)
    if (netM && !line.match(/Invoice\s*NET|System\s*NET|Items?\s*NET/i)) totalNet = parseFloat(netM[1].replace(',', ''))

    const vatM = line.match(/\bVAT\s*(?:\(\s*\d+(?:\.\d+)?\s*%\s*\)|@\s*\d+(?:\.\d+)?\s*%)?\s*:?\s+£\s*([\d,]+\.\d{2})/i)
    if (vatM && !line.match(/\d{2}\/\d{2}/)) totalVat = parseFloat(vatM[1].replace(',', ''))

    const grossM = line.match(/\bTotal(?:\s+(?:Due|Payable|Amount|Gross))?\s*:?\s+£\s*([\d,]+\.\d{2})$/i)
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

  // Fallback: the amount can sit a point lower than its label and land on the NEXT text
  // line ("... VAT (20%)" then "£492.17"). Only used when the label line has no amount.
  for (let li = 0; li + 1 < lines.length; li++) {
    const amtM = lines[li + 1].match(/^£\s*([\d,]+\.\d{2})$/)
    if (!amtM) continue
    const amt = parseFloat(amtM[1].replace(',', ''))
    const label = lines[li]
    if (!totalNet && /\bNet(?:\s+Total)?\s*:?$/i.test(label)) totalNet = amt
    else if (!totalVat && /\bVAT\s*(?:\(\s*\d+(?:\.\d+)?\s*%\s*\)|@\s*\d+(?:\.\d+)?\s*%)?\s*:?$/i.test(label)) totalVat = amt
    else if (!totalGross && /\bTotal(?:\s+(?:Due|Payable|Amount|Gross))?\s*:?$/i.test(label)) totalGross = amt
  }

  // Fallback: the 2026-09 template also prints the gross in the header box ("AMOUNT DUE £x")
  if (!totalGross) {
    for (const line of lines) {
      const dueM = line.match(/\bAmount\s+Due\s*:?\s*£\s*([\d,]+\.\d{2})/i)
      if (dueM) { totalGross = parseFloat(dueM[1].replace(',', '')); break }
    }
  }

  // NOTE: We deliberately do NOT rescale per-line NETs to hit a section subtotal.
  // The previous implementation scaled every docket line proportionally so they summed
  // to "Total MM/YY", but that subtotal can legitimately differ from the sum of lines —
  // e.g. a separate "STOCK REPLACEMENT" charge is billed in the grand total but sits
  // outside the napkin usage subtotal. Scaling corrupted every real per-line price and
  // produced dozens of false price-mismatches against the system orders. Keeping the
  // true invoice line prices is essential for accurate ticket-level reconciliation;
  // any section-vs-lines delta is surfaced at the summary level instead.

  return {
    invoiceNumber, invoiceDate, invoicePeriod,
    sections,
    totals: { net: totalNet, vat: totalVat, gross: totalGross },
  }
}

// ── Column-aware (tabular) parser ──
//
// The 2026-09 Goldstar template is a real table: DATE | GUEST | ROOM | DESCRIPTION | NET |
// VAT | GROSS, with long descriptions and guest names wrapping onto a second visual row
// that carries no date and no prices. Text-line parsing glues those wrapped rows onto the
// NEXT record, so this parser works from item X positions instead: the header row fixes
// the column positions, a row with a date (or prices) starts a record, and wrapped rows are
// appended to the record above, column by column. Column order and the label wording are
// flexible (GUEST/NAME, ROOM/ROOM NO, TICKET/DOCKET, AMOUNT/TOTAL...), and a page without
// its own header reuses the previous page's columns.

type ColKey = 'date' | 'guest' | 'room' | 'ticket' | 'department' | 'description' | 'qty' | 'net' | 'vat' | 'gross'
type MoneyKey = 'net' | 'vat' | 'gross'
interface Column { key: ColKey; x: number; center: number }

const HEADER_LABELS: [RegExp, ColKey][] = [
  [/^DATES?$/, 'date'],
  // "GUEST / ROOM" is one combined column ("SEAN/417") — split per cell in recordToLine
  [/^(GUEST|GUEST NAME|NAME|CUSTOMER|CLIENT|GUEST ROOM|GUEST NAME ROOM|NAME ROOM)$/, 'guest'],
  [/^(ROOM|ROOM NO|ROOM NUMBER|RM|RM NO)$/, 'room'],
  [/^(TICKET|TICKET NO|TICKET NUMBER|DOCKET|DOCKET NO|DOCKET NUMBER|REF|REFERENCE)$/, 'ticket'],
  [/^(DEPARTMENT|DEPT)$/, 'department'],
  [/^(DESCRIPTION|ITEMS?|DETAILS|ITEM DESCRIPTION)$/, 'description'],
  [/^(QTY|QUANTITY)$/, 'qty'],
  [/^(NET|NET AMOUNT|AMOUNT|SUBTOTAL)$/, 'net'],
  [/^(VAT|TAX|VAT AMOUNT)$/, 'vat'],
  [/^(GROSS|TOTAL|GROSS AMOUNT)$/, 'gross'],
]
const MONEY_KEYS: MoneyKey[] = ['net', 'vat', 'gross']
const MONEY_RE = /^\(?-?£?\s*-?[\d,]+\.\d{2}\)?$/
const CELL_DATE_RE = /(\d{1,2})[/.-](\d{1,2})[/.-](\d{2,4})|(\d{1,2})[\s-]+([A-Za-z]{3,9})[\s-]+(\d{2,4})/
const MONTHS = ['jan', 'feb', 'mar', 'apr', 'may', 'jun', 'jul', 'aug', 'sep', 'oct', 'nov', 'dec']
const SUMMARY_ROW_RE = /^(sub\s*-?\s*total|total|net\b|vat\b|amount\s+due|balance|carried|brought)/i
const END_OF_TABLE_RE = /payment\s+details|bank\s+plc|account\s*(no|name)|sort\s*code|thank\s+you|registration\s+no|please\s+quote/i

function normLabel(s: string): string {
  return s.toUpperCase().replace(/[^A-Z ]+/g, ' ').replace(/\s+/g, ' ').trim()
}

function labelKey(s: string): ColKey | null {
  const n = normLabel(s)
  for (const [re, key] of HEADER_LABELS) if (re.test(n)) return key
  return null
}

/**
 * Cut one text item into pieces at the given character offsets. pdf.js only gives the
 * item's start X and total width, so piece positions are estimated proportionally.
 */
function splitItemAt(it: PdfTextItem, cuts: number[]): PdfTextItem[] {
  const cw = it.str.length ? it.w / it.str.length : 0
  const bounds = [0, ...cuts.filter(c => c > 0 && c < it.str.length).sort((a, b) => a - b), it.str.length]
  const out: PdfTextItem[] = []
  for (let i = 0; i < bounds.length - 1; i++) {
    const raw = it.str.slice(bounds[i], bounds[i + 1])
    const lead = raw.length - raw.trimStart().length
    const str = raw.trim()
    if (str) out.push({ ...it, x: it.x + (bounds[i] + lead) * cw, w: str.length * cw, str })
  }
  return out
}

/**
 * A header item holding several labels merged by pdf.js ("Room No. Guest Name") →
 * one entry per label, or null unless every word belongs to a label.
 */
function splitHeaderItem(it: PdfTextItem): { key: ColKey; x: number; right: number }[] | null {
  const words = [...it.str.matchAll(/[A-Za-z]+/g)].map(m => ({ w: m[0], i: m.index ?? 0 }))
  const cw = it.str.length ? it.w / it.str.length : 0
  const out: { key: ColKey; x: number; right: number }[] = []
  for (let i = 0; i < words.length;) {
    let used = 0
    for (let j = words.length; j > i; j--) {
      const key = labelKey(words.slice(i, j).map(x => x.w).join(' '))
      if (key) {
        out.push({ key, x: it.x + words[i].i * cw, right: it.x + (words[j - 1].i + words[j - 1].w.length) * cw })
        used = j - i
        break
      }
    }
    if (!used) return null
    i += used
  }
  return out.length >= 2 ? out : null
}

/** Recognise a table header row → column positions, or null if this row isn't one. */
function detectHeaderColumns(row: PdfTextItem[]): Column[] | null {
  const cols: Column[] = []
  let unknown = 0
  const addCol = (key: ColKey, x: number, right: number) => {
    if (cols.some(c => c.key === key)) return false
    cols.push({ key, x, center: (x + right) / 2 })
    return true
  }
  for (let i = 0; i < row.length; i++) {
    let key = labelKey(row[i].str)
    let right = row[i].x + row[i].w
    // A multi-word label may arrive as separate items ("ROOM" "NO")
    if (!key && i + 1 < row.length && row[i + 1].x - right < 6) {
      key = labelKey(row[i].str + ' ' + row[i + 1].str)
      if (key) { right = row[i + 1].x + row[i + 1].w; i++ }
    }
    if (!key) {
      // Old template's combined "TICKET/ ROOM" header belongs to the legacy parser
      if (/TICKET/.test(normLabel(row[i].str)) && /ROOM/.test(normLabel(row[i].str))) return null
      const parts = splitHeaderItem(row[i])
      if (parts) {
        for (const p of parts) if (!addCol(p.key, p.x, p.right)) return null
        continue
      }
      unknown++; continue
    }
    if (!addCol(key, row[i].x, right)) return null
  }
  const has = (k: ColKey) => cols.some(c => c.key === k)
  if (unknown > 1 || !has('date') || !has('description') || !(has('net') || has('gross'))) return null
  if (!(has('guest') || has('room') || has('ticket') || has('department'))) return null
  return cols.sort((a, b) => a.x - b.x)
}

function parseMoney(s: string): number {
  const neg = /^\(.*\)$/.test(s.trim()) || s.includes('-')
  const v = parseFloat(s.replace(/[^\d.]/g, ''))
  return neg ? -v : v
}

/** Normalise a date cell to DD/MM/YY (slash form used throughout the reconciliation). */
function normaliseCellDate(text: string): string {
  const m = text.match(CELL_DATE_RE)
  if (!m) return ''
  if (m[1]) return `${m[1].padStart(2, '0')}/${m[2].padStart(2, '0')}/${m[3].slice(-2)}`
  const mon = MONTHS.indexOf(m[5].slice(0, 3).toLowerCase())
  if (mon < 0) return ''
  return `${m[4].padStart(2, '0')}/${String(mon + 1).padStart(2, '0')}/${m[6].slice(-2)}`
}

interface TabRecord {
  cells: Partial<Record<ColKey, string>>
  money: Partial<Record<MoneyKey, number>>
  section: InvoiceSection
}

function appendCell(rec: TabRecord, key: ColKey, text: string) {
  const prev = rec.cells[key]
  if (!prev) { rec.cells[key] = text; return }
  // A word hyphenated across the wrap ("T-" + "Shirt") joins without a space
  rec.cells[key] = /-$/.test(prev) && /^[A-Za-z]/.test(text) ? prev + text : prev + ' ' + text
}

/**
 * Split a guest-name cell into the name and any service tag printed with it, e.g.
 *   "OVER GT EX -MUHAMED" → { name: "MUHAMED", note: "OVER GT EX" }
 *   "CHAITH (OVER NGT EX)" → { name: "CHAITH", note: "OVER NGT EX" }
 *   "EX- SHAING" → { name: "SHAING", note: "EX" }
 * The tag is kept verbatim (shown next to the name); only the name is used for matching.
 */
function splitGuestLabel(raw: string): { name: string; note?: string } {
  const SERVICE = String.raw`(?:OVER\s*N?I?GH?T\s*EX(?:PRESS)?|O\/N\s*EX(?:PRESS)?|EXPRESS|EX)`
  let name = raw.replace(/\s+/g, ' ').trim()
  const notes: string[] = []
  const paren = name.match(new RegExp(String.raw`\(\s*(${SERVICE})\s*\)`, 'i'))
  if (paren) { notes.push(paren[1].trim()); name = name.replace(paren[0], ' ') }
  const lead = name.match(new RegExp(String.raw`^(${SERVICE})(?=[\s\-–:/]|$)[\s\-–:/]*`, 'i'))
  if (lead) { notes.push(lead[1].trim()); name = name.slice(lead[0].length) }
  // Tag after the name: "CHAITH/OVER NGT EX", "CHAITH - EXPRESS"
  const trail = name.match(new RegExp(String.raw`[\s\-–:/]+(${SERVICE})$`, 'i'))
  if (trail && trail.index! > 0) { notes.push(trail[1].trim()); name = name.slice(0, trail.index) }
  name = name.replace(/^[\s\-–:]+|[\s\-–:]+$/g, '').replace(/\s+/g, ' ')
  return { name, note: notes.length ? notes.join(' ') : undefined }
}

function recordToLine(rec: TabRecord, lastDate: string): InvoiceLine | null {
  const c = rec.cells
  const net = rec.money.net ?? (rec.money.gross != null && rec.money.vat != null ? +(rec.money.gross - rec.money.vat).toFixed(2) : rec.money.gross)
  if (net == null || isNaN(net)) return null
  const vat = rec.money.vat ?? (rec.money.gross != null ? +(rec.money.gross - net).toFixed(2) : 0)
  const gross = rec.money.gross ?? +(net + vat).toFixed(2)

  let room = (c.room ?? '').trim()
  let guest = (c.guest ?? '').trim()
  let ticket = (c.ticket ?? '').trim()
  let guestInfo: string | undefined
  // Name and room in one cell: "SEAN/417" (GUEST / ROOM column), "OVER GT EX - 615",
  // "SEAN 417", or room first "417/SEAN"
  if (!room && guest) {
    const m = guest.match(/^(.*?\S)\s*[/\-–]?\s+(\d{3,4}[A-Z]?)$/) || guest.match(/^(.*?\S)\s*[/\-–]\s*(\d{3,4}[A-Z]?)$/)
    const r = guest.match(/^(\d{3,4}[A-Z]?)\s*\/\s*(.+)$/)
    if (m) { guest = m[1]; room = m[2] }
    else if (r) { room = r[1]; guest = r[2] }
  }
  if (room && !/^\S+$/.test(room)) {
    const m = room.match(/^(\d{3,4}[A-Z]?)\s+(.+)$/)
    if (m) { room = m[1]; guest = (guest + ' ' + m[2]).trim() }
  }
  // Legacy-style "623 (Curtis)" inside a ticket column
  const tg = ticket.match(/^(\S+)\s*\(([^)]+)\)$/)
  if (tg) { ticket = tg[1]; guest = guest || tg[2] }

  const { name, note } = splitGuestLabel(guest)
  if (name) guestInfo = `(${name})`
  const description = (c.description ?? '').replace(/\s+/g, ' ').trim()
  const isTopUp = /minimum\s+top\s*-?\s*up/i.test(`${ticket} ${guest} ${description}`)

  return {
    date: normaliseCellDate(c.date ?? '') || lastDate,
    ticket: isTopUp ? 'Minimum TopUp' : (room || ticket),
    guestInfo,
    serviceNote: note,
    description,
    items: parseDescriptionItems(description),
    net, vat, gross,
    isTopUp,
    sectionType: rec.section.type,
  }
}

function sectionFromContext(invoiceNumber: string, contextText: string, cols: Column[]): InvoiceSectionType {
  // Same invoice-number codes as the legacy parser (GSSH-GM = guest, -SM staff, ...)
  if (/GM/i.test(invoiceNumber)) return 'guest'
  if (/HH/i.test(invoiceNumber)) return 'bathrobes'
  if (/NM/i.test(invoiceNumber)) return 'napkins'
  if (/HM/i.test(invoiceNumber)) return 'hsk'
  if (/SM/i.test(invoiceNumber)) return 'staff'
  const t = contextText.toLowerCase()
  if (/\bguest\b/.test(t)) return 'guest'
  if (/\bnapkin/.test(t)) return 'napkins'
  if (/\btable\s*cloth/.test(t)) return 'table_cloths'
  if (/\bbathrobe/.test(t)) return 'bathrobes'
  if (/\bhsk\b/.test(t)) return 'hsk'
  if (/\bstaff\b|\buniform/.test(t)) return 'staff'
  if (cols.some(col => col.key === 'guest' || col.key === 'room')) return 'guest'
  return 'staff'
}

/**
 * Column-aware parse. Returns null when no page has a recognisable column header — the
 * caller then keeps the legacy result. Metadata and totals are taken from the legacy parse
 * (those regexes already cope with both templates).
 */
export function parseTabularInvoice(pages: PdfTextItem[][], meta: ParsedInvoice): ParsedInvoice | null {
  let cols: Column[] | null = null
  let contextText = ''
  const sections: InvoiceSection[] = []
  let currentSection: InvoiceSection | null = null
  let current: TabRecord | null = null
  let lastDate = ''
  const lines: InvoiceLine[] = []

  const flush = () => {
    if (!current) return
    const line = recordToLine(current, lastDate)
    if (line) { current.section.lines.push(line); lines.push(line); lastDate = line.date }
    current = null
  }

  for (const page of pages) {
    const rows = clusterRows(page)
    // Find this page's header; a page without one reuses the previous page's columns
    let start = 0
    for (let r = 0; r < rows.length; r++) {
      const found = detectHeaderColumns(rows[r])
      if (found) { cols = found; start = r + 1; break }
      if (!cols) contextText += ' ' + rows[r].map(i => i.str).join(' ')
    }
    if (!cols) continue
    const columns: Column[] = cols
    const moneyCols = columns.filter(c => MONEY_KEYS.includes(c.key as MoneyKey))
    const firstMoneyX = Math.min(...moneyCols.map(c => c.x))
    const textCols = columns.filter(c => !MONEY_KEYS.includes(c.key as MoneyKey))
    const tableLeft = columns[0].x - 4

    // pdf.js sometimes merges neighbouring cells into one item ("50.00£", "SEAN 4x Shirt").
    // Split amounts out of mixed items, and cut text that straddles a column start at the
    // word boundary nearest to it.
    const explode = (row: PdfTextItem[]): PdfTextItem[] => row.flatMap(it => {
      const s = it.str
      const moneyCuts: number[] = []
      if (!MONEY_RE.test(s.trim())) {
        for (const m of s.matchAll(/£\s*-?[\d,]+\.\d{2}|(?<![\d.])-?\d[\d,]*\.\d{2}(?![\d.])|£/g)) moneyCuts.push(m.index ?? 0, (m.index ?? 0) + m[0].length)
      }
      return splitItemAt(it, moneyCuts).flatMap(piece => {
        if (MONEY_RE.test(piece.str) || piece.str === '£') return [piece]
        const cw = piece.str.length ? piece.w / piece.str.length : 0
        const cuts: number[] = []
        for (const tc of textCols) {
          if (!(piece.x < tc.x - 2 && piece.x + piece.w > tc.x + 2) || !cw) continue
          const target = Math.round((tc.x - piece.x) / cw)
          let best = -1
          for (let d = 0; d <= 6 && best < 0; d++) {
            if (piece.str[target - d] === ' ') best = target - d
            else if (piece.str[target + d] === ' ') best = target + d
          }
          if (best > 0) cuts.push(best)
        }
        return cuts.length ? splitItemAt(piece, cuts) : [piece]
      })
    })

    // Classify each row after the header
    interface RowInfo { y: number; cells: Partial<Record<ColKey, string>>; money: Partial<Record<MoneyKey, number>>; date: string; outside: boolean; firstX: number; text: string }
    const infos: RowInfo[] = []
    for (let r = start; r < rows.length; r++) {
      const row = explode(rows[r])
      const cells: Partial<Record<ColKey, string>> = {}
      const money: Partial<Record<MoneyKey, number>> = {}
      let outside = false
      for (let i = 0; i < row.length; i++) {
        const it = row[i]
        let str = it.str.trim()
        let right = it.x + it.w
        // "£" printed as its own item before the number (old template style)
        if (/^-?£$/.test(str) && i + 1 < row.length && /^[\d,]+\.\d{2}$/.test(row[i + 1].str.trim())) {
          str = str + row[i + 1].str.trim(); right = row[i + 1].x + row[i + 1].w; i++
        }
        if (MONEY_RE.test(str) && right > firstMoneyX - 15) {
          const center = (it.x + right) / 2
          const col = moneyCols.reduce((a, b) => Math.abs(b.center - center) < Math.abs(a.center - center) ? b : a)
          money[col.key as MoneyKey] = parseMoney(str)
          continue
        }
        if (it.x < tableLeft) { outside = true; continue }
        let col = textCols[0]
        for (const tc of textCols) if (tc.x <= it.x + 3) col = tc
        cells[col.key] = cells[col.key] ? `${cells[col.key]} ${str}` : str
      }
      const text = row.map(i => i.str).join(' ').replace(/\s+/g, ' ').trim()
      infos.push({ y: row[0].y, cells, money, date: normaliseCellDate(cells.date ?? ''), outside, firstX: row[0].x, text })
    }

    // Wrapped rows sit closer to their record than records sit to each other
    const isStart = (ri: RowInfo) => !!ri.date || Object.keys(ri.money).length >= Math.min(2, moneyCols.length)
    const starts = infos.filter(isStart).map(ri => ri.y)
    const gaps = starts.slice(1).map((y, i) => starts[i] - y).filter(g => g > 0).sort((a, b) => a - b)
    const typicalRowH = page.find(i => i.h > 0)?.h ?? 8
    const contLimit = gaps.length ? gaps[Math.floor(gaps.length / 2)] * 0.9 : typicalRowH * 1.8

    let prevY = Infinity
    for (const ri of infos) {
      const firstText = Object.values(ri.cells).find(Boolean) ?? ''
      if (END_OF_TABLE_RE.test(ri.text)) { flush(); break }
      if (SUMMARY_ROW_RE.test(firstText) && !ri.date) { flush(); prevY = ri.y; continue }

      if (isStart(ri)) {
        const hasMoney = Object.keys(ri.money).length > 0
        // Prices printed one row below a dated record whose own row had none
        if (!ri.date && current && Object.keys(current.money).length === 0 && hasMoney && prevY - ri.y <= contLimit) {
          current.money = ri.money
          for (const [k, v] of Object.entries(ri.cells)) if (v) appendCell(current, k as ColKey, v)
          prevY = ri.y; continue
        }
        flush()
        if (!currentSection) {
          const type = sectionFromContext(meta.invoiceNumber, contextText, columns)
          currentSection = { name: type, type, lines: [] }
          sections.push(currentSection)
        }
        current = { cells: { ...ri.cells }, money: { ...ri.money }, section: currentSection }
        prevY = ri.y; continue
      }

      // In-table section heading ("Napkins", "Table Cloths"...) starts in the first column
      const secType = !ri.outside && ri.firstX < (columns[1]?.x ?? Infinity) - 3 ? detectSection(ri.text) : null
      if (secType) {
        flush()
        currentSection = { name: ri.text, type: secType, lines: [] }
        sections.push(currentSection)
        prevY = ri.y; continue
      }

      // Wrapped continuation of the record above
      if (current && !ri.outside && prevY - ri.y <= contLimit) {
        for (const [k, v] of Object.entries(ri.cells)) if (v) appendCell(current, k as ColKey, v)
        prevY = ri.y; continue
      }
      // Anything else (page footer, notes) ends the current record
      flush()
    }
    flush()
  }

  if (!lines.length) return null
  return { ...meta, sections: sections.filter(s => s.lines.length > 0), layout: 'tabular' }
}

/** Keep whichever parse identified more lines (ticket / room / guest name); ties → tabular. */
function pickBetterParse(legacy: ParsedInvoice, tabular: ParsedInvoice | null): ParsedInvoice {
  if (!tabular) return legacy
  const score = (inv: ParsedInvoice) => {
    const ls = inv.sections.flatMap(s => s.lines)
    const identified = ls.filter(l => l.ticket || l.guestInfo).length
    const sum = ls.reduce((s, l) => s + l.net, 0)
    const totalsAgree = inv.totals.net > 0 && Math.abs(sum - inv.totals.net) < 0.05
    return identified + (totalsAgree ? ls.length : 0)
  }
  return score(legacy) > score(tabular) ? legacy : tabular
}

const NAME_NOISE = new Set(['over', 'ngt', 'night', 'express', 'mr', 'mrs', 'ms', 'miss', 'dr'])

/** Lower-case name tokens (≥3 letters) from an invoice guestInfo like "(SEAN)" or "(Mr Lee)". */
export function guestNameTokens(guestInfo: string | null | undefined): string[] {
  return String(guestInfo ?? '').toLowerCase().replace(/[^a-z\s]/g, ' ').split(/\s+/)
    .filter(t => t.length >= 3 && !NAME_NOISE.has(t))
}

/**
 * Does an invoice guest name match a stored guest_name? Word-prefix match either way, so
 * Goldstar's truncated names still match ("ANG" ↔ "Angelys", "GRE" ↔ "Greg Smith").
 */
export function guestNameMatches(guestInfo: string | null | undefined, storedName: string | null | undefined): boolean {
  const keys = guestNameTokens(guestInfo)
  const words = String(storedName ?? '').toLowerCase().replace(/[^a-z\s]/g, ' ').split(/\s+/).filter(w => w.length >= 3)
  return keys.some(k => words.some(w => w.startsWith(k) || k.startsWith(w)))
}

// ── Period parsing ──

export function parseInvoicePeriod(period: string): { start: Date; end: Date } | null {
  // Normalize: replace en-dash/em-dash with hyphen, collapse whitespace
  const normalized = period.replace(/[–—]/g, '-').replace(/\s+/g, ' ').trim()

  // D.M.YY(YY) - D.M.YY(YY), with "." "/" or "-" separators, 1-2 digit day/month and
  // "-" or "to" between the two dates (e.g. "01.09.26 - 30.09.26", "1/9/2026 to 30/9/2026")
  const m = normalized.match(/(\d{1,2})[./-](\d{1,2})[./-](\d{2,4})\s*(?:-|to)\s*(\d{1,2})[./-](\d{1,2})[./-](\d{2,4})/i)
  if (m) return buildPeriod(m[1], m[2], m[3], m[4], m[5], m[6])

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

// ── D140 Opera PMS Report Parser ──

export interface D140Transaction {
  date: string
  time: string
  roomNumber: string
  guestName: string
  amount: number
  isCredit: boolean
  description: string
}

export interface D140Report {
  transactions: D140Transaction[]
  grandTotal: number
  period: { from: string; to: string }
}

export async function extractAndParseD140(file: File): Promise<D140Report> {
  const lines = await extractPdfLines(file)
  return parseD140Report(lines)
}

export function parseD140Report(lines: string[]): D140Report {
  const transactions: D140Transaction[] = []
  let grandTotal = 0
  let periodFrom = '', periodTo = ''

  console.log(`[D140] Parsing ${lines.length} lines`)
  console.log('[D140] First 10 lines:', lines.slice(0, 10))

  // Extract period from filter line
  for (const line of lines) {
    const periodM = line.match(/From\s+Date\s+(\d{2}-\d{2}-\d{2,4})\s+To\s+Date\s+(\d{2}-\d{2}-\d{2,4})/i)
    if (periodM) { periodFrom = periodM[1]; periodTo = periodM[2] }
  }

  // The D140 PDF has a complex table layout. The text extraction may produce lines
  // in various formats. We use multiple strategies to find transaction data.

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i]

    // Grand total — flexible matching
    const totalM = line.match(/Grand\s*Total\s*(?:£?\s*)?([\d,]+\.\d{2})/i)
    if (totalM) { grandTotal = parseFloat(totalM[1].replace(',', '')); continue }
    // Also try: just a number after "Grand Total" somewhere
    if (/grand\s*total/i.test(line)) {
      const numM = line.match(/([\d,]+\.\d{2})/)
      if (numM) grandTotal = parseFloat(numM[1].replace(',', ''))
    }

    // Strategy 1: Full line with date-time-room-name pattern
    // DD-MM-YY HH:MM ROOM NAME,FIRST,TITLE MKT 70100 ... GBP AMOUNT
    const fullM = line.match(/(\d{2}-\d{2}-\d{2})\s+(\d{2}:\d{2})\s+(\d{3,5})\s+(.+?)\s+(?:[A-Z]{2,4}\s+)?701\d{2}/)
    if (fullM) {
      const amtM = line.match(/([-\s]?[\d,]+\.\d{2})\s+[\d.]+\s*$/) || line.match(/GBP\s+([-\s]?[\d,]+\.\d{2})/) || line.match(/([-\s]?[\d,]+\.\d{2})/)
      if (amtM) {
        const amt = parseFloat(amtM[1].replace(/[\s,]/g, ''))
        if (!isNaN(amt)) {
          transactions.push({
            date: fullM[1], time: fullM[2], roomNumber: fullM[3],
            guestName: fullM[4].replace(/,/g, ' ').trim(),
            amount: Math.abs(amt), isCredit: amt < 0,
            description: 'Laundry - Dry Cleaning',
          })
          continue
        }
      }
    }

    // Strategy 2: Line starts with date (DD-MM-YY) — extract fields more flexibly
    const dateM = line.match(/^(\d{2}-\d{2}-\d{2})\s+(\d{2}:\d{2})\s+(\d{3,5})\s+/)
    if (dateM) {
      const rest = line.slice(dateM[0].length)
      // Find an amount (number with decimals) — take the first significant one
      const amounts = [...rest.matchAll(/([-\s]?[\d,]+\.\d{2})/g)].map(m => parseFloat(m[1].replace(/[\s,]/g, '')))
      const debit = amounts.find(a => !isNaN(a) && Math.abs(a) > 0)
      // Extract name: everything before "REG|ECM|ADP|GSP|HAC|GCO|BEN|PKG|SPE" market code
      const nameM = rest.match(/^(.+?)\s+(?:REG|ECM|ADP|GSP|HAC|GCO|BEN|PKG|SPE)\b/i)
      const guestName = nameM ? nameM[1].replace(/,/g, ' ').trim() : rest.split(/\s{2,}/)[0].replace(/,/g, ' ').trim()
      if (debit != null) {
        transactions.push({
          date: dateM[1], time: dateM[2], roomNumber: dateM[3],
          guestName, amount: Math.abs(debit), isCredit: debit < 0,
          description: 'Laundry - Dry Cleaning',
        })
        continue
      }
    }

    // Strategy 3: Look for room numbers + amounts on lines that have "Laundry" or "70100"
    if (/(?:laundry|70100)/i.test(line)) {
      const roomAmtM = line.match(/(\d{3,5}).*?(\d+\.\d{2})/)
      const dateInLine = line.match(/(\d{2}-\d{2}-\d{2})/)
      if (roomAmtM && dateInLine) {
        const amt = parseFloat(roomAmtM[2])
        if (!isNaN(amt) && amt > 0) {
          transactions.push({
            date: dateInLine[1], time: '', roomNumber: roomAmtM[1],
            guestName: '', amount: amt, isCredit: false,
            description: 'Laundry - Dry Cleaning',
          })
        }
      }
    }
  }

  // Deduplicate — same room + same date + same amount
  const seen = new Set<string>()
  const unique = transactions.filter(t => {
    const key = `${t.date}-${t.roomNumber}-${t.amount}`
    if (seen.has(key)) return false
    seen.add(key)
    return true
  })

  console.log(`[D140] Parsed ${unique.length} transactions (${transactions.length} before dedup), grand total £${grandTotal}`)
  if (unique.length > 0) console.log('[D140] First transaction:', unique[0])

  return {
    transactions: unique,
    grandTotal,
    period: { from: periodFrom, to: periodTo },
  }
}
