import { supabase } from './supabase'

// Data access for Reconciliation Phase 1 (migration db/migrations/2026-11-08_reconciliation_phase1.sql):
// action history, invoice-note drafts, In-System-Only order resolutions, credit note requests,
// Goldstar contacts and settings. Every call degrades gracefully when the migration hasn't
// been run yet (missing table → treated as "feature unavailable", never as a crash).

function isMissing(err: { message?: string; code?: string } | null): boolean {
  return !!err && (err.code === '42P01' || err.code === 'PGRST205' || err.code === '42703' || /does not exist|could not find the table|column .* does not exist/i.test(err.message ?? ''))
}

async function currentEmail(): Promise<string | null> {
  const { data: { user } } = await supabase.auth.getUser()
  return user?.email ?? null
}

/** Probe once per page load whether the Phase 1 tables exist. */
let phase1Probe: Promise<boolean> | null = null
export function phase1Available(): Promise<boolean> {
  phase1Probe ??= (async () => {
    const { error } = await supabase.from('reconciliation_actions').select('id').limit(1)
    if (error) return false // missing table or any other failure → keep Phase 1 UI hidden
    const { error: colErr } = await supabase.from('orders').select('not_charged_at').limit(1)
    return !colErr
  })()
  return phase1Probe
}

// ── Action history ──────────────────────────────────────────────────────────────
export interface ReconAction { invoice_number: string | null; line_key: string | null; order_id: string | null; action: string; detail: string | null; actor: string | null; created_at: string }

export async function logAction(a: { invoice_number?: string | null; line_key?: string | null; order_id?: string | null; action: string; detail?: string | null }): Promise<void> {
  const actor = await currentEmail()
  const { error } = await supabase.from('reconciliation_actions').insert({ ...a, actor })
  if (error && !isMissing(error)) console.error('Failed to log reconciliation action:', error)
}

export async function fetchActions(invoiceNumber: string): Promise<ReconAction[]> {
  if (!invoiceNumber) return []
  const { data, error } = await supabase.from('reconciliation_actions')
    .select('invoice_number, line_key, order_id, action, detail, actor, created_at')
    .eq('invoice_number', invoiceNumber).order('created_at', { ascending: true }).limit(2000)
  if (error) { if (!isMissing(error)) console.error('Failed to load history:', error); return [] }
  return (data ?? []) as ReconAction[]
}

// ── Invoice-note drafts (autosave) ─────────────────────────────────────────────
export async function loadDraft(invoiceNumber: string): Promise<{ note: string; updated_by: string | null; updated_at: string } | null> {
  if (!invoiceNumber) return null
  const { data, error } = await supabase.from('reconciliation_drafts').select('note, updated_by, updated_at').eq('invoice_number', invoiceNumber).maybeSingle()
  if (error) { if (!isMissing(error)) console.error('Failed to load draft:', error); return null }
  return data as { note: string; updated_by: string | null; updated_at: string } | null
}

export async function saveDraft(invoiceNumber: string, note: string): Promise<string | null> {
  if (!invoiceNumber) return 'no invoice number'
  const updated_by = await currentEmail()
  const { error } = await supabase.from('reconciliation_drafts').upsert({ invoice_number: invoiceNumber, note, updated_by, updated_at: new Date().toISOString() }, { onConflict: 'invoice_number' })
  if (error) return isMissing(error) ? 'unavailable' : error.message
  return null
}

// ── In System Only: order resolutions ──────────────────────────────────────────
export type OrderResolution = 'expect_next' | 'not_charged' | 'write_off' | 'credit_query'
export const ORDER_RESOLUTION_LABELS: Record<OrderResolution, string> = {
  expect_next: 'Expect on next invoice',
  not_charged: 'Not charged by Goldstar (£0)',
  write_off: 'Written off',
  credit_query: 'Query / credit',
}
export interface OrderResolutionRow { invoice_number: string; order_id: string; resolution: OrderResolution; note: string | null; found_on_invoice: string | null; created_by: string | null; created_at: string }

export async function fetchOrderResolutions(invoiceNumber: string): Promise<OrderResolutionRow[]> {
  if (!invoiceNumber) return []
  const { data, error } = await supabase.from('reconciliation_order_resolutions')
    .select('invoice_number, order_id, resolution, note, found_on_invoice, created_by, created_at').eq('invoice_number', invoiceNumber).limit(2000)
  if (error) { if (!isMissing(error)) console.error('Failed to load order resolutions:', error); return [] }
  return (data ?? []) as OrderResolutionRow[]
}

/** "Expect on next invoice" items from OTHER invoices that haven't turned up yet. */
export async function fetchOpenExpected(excludeInvoice: string): Promise<OrderResolutionRow[]> {
  const { data, error } = await supabase.from('reconciliation_order_resolutions')
    .select('invoice_number, order_id, resolution, note, found_on_invoice, created_by, created_at')
    .eq('resolution', 'expect_next').is('found_on_invoice', null).neq('invoice_number', excludeInvoice || '-').limit(500)
  if (error) { if (!isMissing(error)) console.error('Failed to load expected items:', error); return [] }
  return (data ?? []) as OrderResolutionRow[]
}

export async function setOrderResolution(invoiceNumber: string, orderId: string, resolution: OrderResolution, note: string | null): Promise<string | null> {
  const created_by = await currentEmail()
  const { error } = await supabase.from('reconciliation_order_resolutions').upsert(
    { invoice_number: invoiceNumber, order_id: orderId, resolution, note, created_by, updated_at: new Date().toISOString() },
    { onConflict: 'invoice_number,order_id' })
  if (error) return error.message
  if (resolution === 'not_charged') {
    const { error: oErr } = await supabase.from('orders').update({ not_charged_at: new Date().toISOString(), not_charged_by: created_by, not_charged_reason: note }).eq('id', orderId)
    if (oErr) return oErr.message
  }
  await logAction({ invoice_number: invoiceNumber, order_id: orderId, action: ORDER_RESOLUTION_LABELS[resolution], detail: note })
  return null
}

export async function clearOrderResolution(invoiceNumber: string, orderId: string, wasNotCharged: boolean): Promise<string | null> {
  const { error } = await supabase.from('reconciliation_order_resolutions').delete().eq('invoice_number', invoiceNumber).eq('order_id', orderId)
  if (error) return error.message
  if (wasNotCharged) {
    const { error: oErr } = await supabase.from('orders').update({ not_charged_at: null, not_charged_by: null, not_charged_reason: null }).eq('id', orderId)
    if (oErr) return oErr.message
  }
  await logAction({ invoice_number: invoiceNumber, order_id: orderId, action: 'Cleared resolution' })
  return null
}

export async function markExpectedFound(rows: { invoice_number: string; order_id: string }[], foundOnInvoice: string): Promise<void> {
  for (const r of rows) {
    await supabase.from('reconciliation_order_resolutions').update({ found_on_invoice: foundOnInvoice, updated_at: new Date().toISOString() })
      .eq('invoice_number', r.invoice_number).eq('order_id', r.order_id)
  }
}

// ── Credit note requests ───────────────────────────────────────────────────────
export type CreditReason = 'not_ours' | 'wrong_price' | 'wrong_quantity' | 'charged_twice' | 'wrong_service' | 'other'
export const CREDIT_REASON_LABELS: Record<CreditReason, string> = {
  not_ours: 'Not ours / no order',
  wrong_price: 'Wrong price',
  wrong_quantity: 'Wrong quantity',
  charged_twice: 'Charged twice',
  wrong_service: 'Wrong service or room',
  other: 'Other',
}
export interface CreditLine {
  line_key: string | null; order_id?: string | null
  date: string; ticket: string; guest: string; description: string
  invoice_net: number; reason: CreditReason; reason_text: string; credit_net: number
}
export type CreditStatus = 'requested' | 'received' | 'closed' | 'cancelled'
export interface CreditRequest {
  id: string; reference: string; invoice_number: string; status: CreditStatus
  lines: CreditLine[]; net: number; vat: number; total: number
  to_emails: string | null; cc_emails: string | null; message: string | null
  requested_by: string | null; requested_at: string
  credit_note_no: string | null; received_amount: number | null; received_by: string | null; received_at: string | null; closed_at: string | null
}

const CR_COLS = 'id, reference, invoice_number, status, lines, net, vat, total, to_emails, cc_emails, message, requested_by, requested_at, credit_note_no, received_amount, received_by, received_at, closed_at'

export async function fetchCreditRequests(opts: { invoiceNumber?: string; openOnly?: boolean } = {}): Promise<CreditRequest[]> {
  let q = supabase.from('reconciliation_credit_requests').select(CR_COLS).order('requested_at', { ascending: false }).limit(500)
  if (opts.invoiceNumber) q = q.eq('invoice_number', opts.invoiceNumber)
  if (opts.openOnly) q = q.in('status', ['requested', 'received'])
  const { data, error } = await q
  if (error) { if (!isMissing(error)) console.error('Failed to load credit requests:', error); return [] }
  return (data ?? []) as CreditRequest[]
}

export async function nextCreditReference(invoiceNumber: string): Promise<string> {
  const { count } = await supabase.from('reconciliation_credit_requests').select('id', { count: 'exact', head: true }).eq('invoice_number', invoiceNumber)
  return `CR-${invoiceNumber}-${(count ?? 0) + 1}`
}

export async function createCreditRequest(r: Omit<CreditRequest, 'id' | 'status' | 'requested_by' | 'requested_at' | 'credit_note_no' | 'received_amount' | 'received_by' | 'received_at' | 'closed_at'>): Promise<{ id: string | null; error: string | null }> {
  const requested_by = await currentEmail()
  const { data, error } = await supabase.from('reconciliation_credit_requests').insert({ ...r, requested_by, status: 'requested' }).select('id').single()
  if (error) return { id: null, error: error.message }
  await logAction({ invoice_number: r.invoice_number, action: 'Credit note requested', detail: `${r.reference}: £${r.total.toFixed(2)} incl. VAT, ${r.lines.length} line(s)` })
  for (const l of r.lines) if (l.line_key) await logAction({ invoice_number: r.invoice_number, line_key: l.line_key, action: 'Credit note requested', detail: `${r.reference}: ${CREDIT_REASON_LABELS[l.reason]}${l.reason_text ? ` (${l.reason_text})` : ''}, £${l.credit_net.toFixed(2)}` })
  return { id: (data as { id: string }).id, error: null }
}

export async function recordCreditNote(cr: CreditRequest, creditNoteNo: string, amount: number): Promise<string | null> {
  const by = await currentEmail()
  // Partial credits add up; the request closes once the total has been received
  const received = +((cr.received_amount ?? 0) + amount).toFixed(2)
  const fully = received + 0.005 >= cr.total
  const creditNos = [cr.credit_note_no, creditNoteNo].filter(Boolean).join(', ')
  const { error } = await supabase.from('reconciliation_credit_requests').update({
    credit_note_no: creditNos, received_amount: received, received_by: by, received_at: new Date().toISOString(),
    status: fully ? 'closed' : 'received', closed_at: fully ? new Date().toISOString() : null, updated_at: new Date().toISOString(),
  }).eq('id', cr.id)
  if (error) return error.message
  await logAction({ invoice_number: cr.invoice_number, action: 'Credit note received', detail: `${cr.reference}: ${creditNoteNo}, £${amount.toFixed(2)} (total received £${received.toFixed(2)} of £${cr.total.toFixed(2)})${fully ? ', closed' : ', still open'}` })
  return null
}

export async function setCreditStatus(cr: CreditRequest, status: CreditStatus): Promise<string | null> {
  const { error } = await supabase.from('reconciliation_credit_requests').update({ status, closed_at: status === 'closed' || status === 'cancelled' ? new Date().toISOString() : null, updated_at: new Date().toISOString() }).eq('id', cr.id)
  if (error) return error.message
  await logAction({ invoice_number: cr.invoice_number, action: `Credit request ${status}`, detail: cr.reference })
  return null
}

// ── Goldstar contacts + settings ───────────────────────────────────────────────
export interface SupplierContact { id: string; email: string; role: 'to' | 'cc'; added_by: string | null; created_at: string }

export async function fetchSupplierContacts(): Promise<{ contacts: SupplierContact[]; available: boolean }> {
  const { data, error } = await supabase.from('supplier_contacts').select('id, email, role, added_by, created_at').order('created_at')
  if (error) return { contacts: [], available: !isMissing(error) }
  return { contacts: (data ?? []) as SupplierContact[], available: true }
}
export async function addSupplierContact(email: string, role: 'to' | 'cc'): Promise<string | null> {
  const added_by = await currentEmail()
  const { error } = await supabase.from('supplier_contacts').insert({ email, role, added_by })
  return error ? error.message : null
}
export async function removeSupplierContact(id: string): Promise<string | null> {
  const { error } = await supabase.from('supplier_contacts').delete().eq('id', id)
  return error ? error.message : null
}

export async function fetchReconSettings(): Promise<Record<string, string>> {
  const { data, error } = await supabase.from('reconciliation_settings').select('key, value')
  if (error) return {}
  return Object.fromEntries((data ?? []).map(r => [(r as { key: string }).key, (r as { value: string }).value]))
}
export async function saveReconSetting(key: string, value: string): Promise<string | null> {
  const updated_by = await currentEmail()
  const { error } = await supabase.from('reconciliation_settings').upsert({ key, value, updated_by, updated_at: new Date().toISOString() }, { onConflict: 'key' })
  return error ? error.message : null
}

// ── Sign-off ─────────────────────────────────────────────────────────────────────
export async function approveReconciliation(recId: string, approverName: string): Promise<string | null> {
  const { error } = await supabase.from('reconciliations').update({ approved_by: approverName, approved_at: new Date().toISOString() }).eq('id', recId)
  if (error) return error.message
  return null
}

/** Opens the user's own email program with the message filled in (mailto). */
export function openMailDraft(to: string, cc: string, subject: string, body: string) {
  const params = [cc ? `cc=${encodeURIComponent(cc)}` : '', `subject=${encodeURIComponent(subject)}`, `body=${encodeURIComponent(body)}`].filter(Boolean).join('&')
  window.location.href = `mailto:${encodeURIComponent(to).replace(/%2C/gi, ',').replace(/%40/g, '@')}?${params}`
}
