import { supabase } from './supabase'
import type { InvoiceLine, ParsedInvoice } from './invoiceParser'

// ── Reconciliation line notes ("Charge to") ──
//
// Guest invoices print some lines with no room: a group charge (posted to a group master
// folio in Opera), house use, or Goldstar simply left the room off. Each invoice line can
// carry one tag + note, autosaved to reconciliation_line_notes so it survives re-uploads,
// shows in the breakdown / Excel / PDF, and lets accounts cross-check revenue per group.
// See db/migrations/2026-11-05_reconciliation_line_notes.sql.

export type ChargeType = 'note' | 'room_missing' | 'group' | 'house' | 'other'

export const CHARGE_TYPE_LABELS: Record<ChargeType, string> = {
  note: 'Note only',
  room_missing: 'Room missing on invoice',
  group: 'Group charge',
  house: 'House use',
  other: 'Other',
}

export interface LineNote {
  invoice_number: string
  line_key: string
  line_date: string | null
  ticket: string | null
  guest_label: string | null
  description: string | null
  net: number | null
  charge_type: ChargeType
  room_override: string | null
  group_name: string | null
  note: string | null
  order_id: string | null
  mirrored_to_order_at?: string | null
  updated_by: string | null
  updated_at?: string
}

export interface GroupFolio {
  invoice_number: string
  group_name: string
  master_room: string | null
  revenue_posted: number | null
  folio_ref: string | null
  note: string | null
  updated_by: string | null
  updated_at?: string
}

const NOTE_COLS = 'invoice_number, line_key, line_date, ticket, guest_label, description, net, charge_type, room_override, group_name, note, order_id, mirrored_to_order_at, updated_by, updated_at'
const FOLIO_COLS = 'invoice_number, group_name, master_room, revenue_posted, folio_ref, note, updated_by, updated_at'

/**
 * Stable identity for every non-TopUp invoice line: "<date>|<ticket>|<net>|<n>", where n
 * counts identical date+ticket+net lines in invoice order. Guest name and description are
 * left out on purpose: the two parsers build them differently, so including them would
 * orphan notes whenever the parser changes.
 */
export function buildLineKeys(invoice: ParsedInvoice | null): Map<InvoiceLine, string> {
  const keys = new Map<InvoiceLine, string>()
  if (!invoice) return keys
  const seen = new Map<string, number>()
  for (const section of invoice.sections) {
    for (const line of section.lines) {
      if (line.isTopUp) continue
      const base = `${line.date}|${line.ticket}|${line.net.toFixed(2)}`
      const n = (seen.get(base) ?? 0) + 1
      seen.set(base, n)
      keys.set(line, `${base}|${n}`)
    }
  }
  return keys
}

/** True when the error means the migration hasn't been run yet (table missing). */
function isMissingTable(err: { message?: string; code?: string } | null): boolean {
  return !!err && (err.code === '42P01' || err.code === 'PGRST205' || /does not exist|could not find the table/i.test(err.message ?? ''))
}

export async function fetchLineNotes(invoiceNumber: string): Promise<{ notes: LineNote[]; available: boolean }> {
  if (!invoiceNumber) return { notes: [], available: true }
  const { data, error } = await supabase.from('reconciliation_line_notes').select(NOTE_COLS).eq('invoice_number', invoiceNumber).limit(1000)
  if (error) {
    if (!isMissingTable(error)) console.error('Failed to load line notes:', error)
    return { notes: [], available: !isMissingTable(error) }
  }
  return { notes: (data ?? []) as LineNote[], available: true }
}

export async function upsertLineNote(n: LineNote): Promise<string | null> {
  const { error } = await supabase.from('reconciliation_line_notes')
    .upsert({ ...n, updated_at: new Date().toISOString() }, { onConflict: 'invoice_number,line_key' })
  if (error) { console.error('Failed to save line note:', error); return error.message }
  return null
}

export async function deleteLineNote(invoiceNumber: string, lineKey: string): Promise<string | null> {
  const { error } = await supabase.from('reconciliation_line_notes').delete().eq('invoice_number', invoiceNumber).eq('line_key', lineKey)
  if (error) { console.error('Failed to delete line note:', error); return error.message }
  return null
}

export async function fetchGroupFolios(invoiceNumber: string): Promise<GroupFolio[]> {
  if (!invoiceNumber) return []
  const { data, error } = await supabase.from('reconciliation_group_folios').select(FOLIO_COLS).eq('invoice_number', invoiceNumber).limit(200)
  if (error) { if (!isMissingTable(error)) console.error('Failed to load group folios:', error); return [] }
  return (data ?? []) as GroupFolio[]
}

export async function upsertGroupFolio(f: GroupFolio): Promise<string | null> {
  const { error } = await supabase.from('reconciliation_group_folios')
    .upsert({ ...f, updated_at: new Date().toISOString() }, { onConflict: 'invoice_number,group_name' })
  if (error) { console.error('Failed to save group folio:', error); return error.message }
  return null
}

/** Group / account names used before (any invoice), so the same name is reused consistently. */
export async function fetchKnownGroupNames(): Promise<string[]> {
  const { data, error } = await supabase.from('reconciliation_line_notes').select('group_name')
    .not('group_name', 'is', null).order('updated_at', { ascending: false }).limit(500)
  if (error) return []
  return [...new Set((data ?? []).map(r => (r as { group_name: string }).group_name).filter(Boolean))].sort((a, b) => a.localeCompare(b))
}

/** Short human label for a tag, used on the row chip, Excel, PDF and the order-notes copy. */
export function chargeLabel(n: Pick<LineNote, 'charge_type' | 'group_name' | 'room_override'>): string {
  switch (n.charge_type) {
    case 'room_missing': return n.room_override ? `Room ${n.room_override} (missing on invoice)` : 'Room missing on invoice'
    case 'group': return `Group: ${n.group_name || '?'}`
    case 'house': return n.group_name ? `House use: ${n.group_name}` : 'House use'
    case 'other': return n.group_name ? `Other: ${n.group_name}` : 'Other'
    default: return 'Note'
  }
}

/** Grouping bucket for the "Group & No-room charges" breakdown. */
export function chargeBucket(n: LineNote | undefined, line: InvoiceLine): string | null {
  if (n && n.charge_type === 'group') return `Group: ${n.group_name || '?'}`
  if (n && n.charge_type === 'house') return 'House use'
  if (n && n.charge_type === 'other') return `Other${n.group_name ? `: ${n.group_name}` : ''}`
  if (n && n.charge_type === 'room_missing') return 'Room missing on invoice (room added)'
  if (!line.ticket && line.sectionType === 'guest') return 'No room — not yet assigned'
  return null
}
