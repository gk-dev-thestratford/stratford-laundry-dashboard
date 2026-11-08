import { useCallback, useEffect, useState } from 'react'
import { Receipt, X } from 'lucide-react'
import {
  fetchCreditRequests, fetchReconSettings, fetchSupplierContacts, openMailDraft, recordCreditNote, setCreditStatus,
  type CreditRequest,
} from '../../lib/reconPhase1'

// Credit notes panel: what Goldstar still owes, each request's status (Requested → Received →
// Closed), record a received credit note, send a reminder. Used on Reconciliation (one invoice)
// and Recon History (all invoices).

const money = (n: number) => `£${n.toFixed(2)}`
const daysSince = (iso: string) => Math.floor((Date.now() - new Date(iso).getTime()) / 86_400_000)

export default function CreditNotesPanel({ invoiceNumber, refreshKey = 0, creditLinesOnInvoice = [] }: {
  invoiceNumber?: string
  refreshKey?: number
  /** Negative (credit) lines found on the invoice being reconciled — suggested matches */
  creditLinesOnInvoice?: { date: string; description: string; net: number; gross: number }[]
}) {
  const [requests, setRequests] = useState<CreditRequest[]>([])
  const [owedAll, setOwedAll] = useState(0)
  const [chaseDays, setChaseDays] = useState(30)
  const [recording, setRecording] = useState<CreditRequest | null>(null)
  const [cnNo, setCnNo] = useState('')
  const [cnAmount, setCnAmount] = useState('')
  const [err, setErr] = useState('')

  const load = useCallback(async () => {
    const [mine, open, settings] = await Promise.all([
      fetchCreditRequests(invoiceNumber ? { invoiceNumber } : {}),
      fetchCreditRequests({ openOnly: true }),
      fetchReconSettings(),
    ])
    setRequests(mine)
    setOwedAll(open.reduce((s, r) => s + (r.total - (r.received_amount ?? 0)), 0))
    if (settings.credit_chase_days) setChaseDays(Number(settings.credit_chase_days) || 30)
  }, [invoiceNumber])
  useEffect(() => { load() }, [load, refreshKey])

  async function remind(r: CreditRequest) {
    const { contacts } = await fetchSupplierContacts()
    const to = r.to_emails || contacts.filter(c => c.role === 'to').map(c => c.email).join(', ')
    const cc = r.cc_emails || contacts.filter(c => c.role === 'cc').map(c => c.email).join(', ')
    openMailDraft(to, cc, `Reminder: credit note request ${r.reference} (${money(r.total)} incl. VAT)`,
      `Dear Goldstar team,\n\nA reminder about our credit note request ${r.reference} for invoice ${r.invoice_number}, sent on ${new Date(r.requested_at).toLocaleDateString('en-GB')}: ${money(r.total)} incl. VAT (${r.lines.length} line(s)).\n\nPlease let us know when the credit note will be issued.\n\nKind regards,\nThe Stratford — Laundry Team`)
  }

  async function saveRecord() {
    if (!recording) return
    const amount = Number(cnAmount.replace(/[£,\s]/g, ''))
    if (!cnNo.trim() || !amount) { setErr('Enter the credit note number and the amount.'); return }
    const e = await recordCreditNote(recording, cnNo.trim(), amount)
    if (e) { setErr(e); return }
    setRecording(null); setCnNo(''); setCnAmount(''); setErr('')
    load()
  }

  if (!requests.length && !owedAll && !creditLinesOnInvoice.length) return null
  return (
    <div className="bg-white rounded-xl border border-gray-200 overflow-hidden">
      <div className="px-5 py-3 border-b border-gray-200 flex items-center justify-between gap-3">
        <div className="flex items-center gap-2"><Receipt className="w-4 h-4 text-navy" /><h3 className="text-sm font-semibold text-gray-900">Credit notes</h3>
          {invoiceNumber && <span className="text-xs text-gray-400">for this invoice</span>}</div>
        <span className="text-sm font-semibold text-orange-600">Owed by Goldstar (all invoices): {money(owedAll)}</span>
      </div>
      {creditLinesOnInvoice.length > 0 && (
        <div className="px-5 py-2.5 bg-green-50 border-b border-green-100 text-xs text-green-800">
          This invoice contains {creditLinesOnInvoice.length} credit line{creditLinesOnInvoice.length > 1 ? 's' : ''}: {creditLinesOnInvoice.map(c => `${c.date} ${c.description} ${money(c.gross)}`).join(' · ')}. Record it against the matching request below.
        </div>
      )}
      {requests.length > 0 && (
        <table className="w-full text-sm">
          <thead><tr className="border-b border-gray-200 bg-gray-50 text-xs text-gray-600"><th className="px-3 py-2 text-left font-medium">Reference</th>{!invoiceNumber && <th className="px-3 text-left font-medium">Invoice</th>}<th className="px-3 text-right font-medium">Lines</th><th className="px-3 text-right font-medium">Requested</th><th className="px-3 text-left font-medium">Status</th><th className="px-3 text-right font-medium">Received</th><th className="px-3" /></tr></thead>
          <tbody className="divide-y divide-gray-100">
            {requests.map(r => {
              const age = daysSince(r.requested_at)
              const overdue = r.status === 'requested' && age >= chaseDays
              return (
                <tr key={r.id} className={r.status === 'closed' || r.status === 'cancelled' ? 'text-gray-500' : ''}>
                  <td className="px-3 py-2.5 font-mono text-xs" title={r.lines.map(l => `${l.date} ${l.ticket} ${l.guest}: £${l.credit_net.toFixed(2)}`).join('\n')}>{r.reference}</td>
                  {!invoiceNumber && <td className="px-3 text-xs">{r.invoice_number}</td>}
                  <td className="px-3 text-right">{r.lines.length}</td>
                  <td className="px-3 text-right">{money(r.total)}</td>
                  <td className="px-3">
                    <span className={`text-[11px] font-medium rounded px-1.5 py-0.5 ${r.status === 'closed' ? 'bg-green-100 text-green-700' : r.status === 'received' ? 'bg-teal-100 text-teal-700' : r.status === 'cancelled' ? 'bg-gray-100 text-gray-500' : overdue ? 'bg-red-100 text-red-700' : 'bg-amber-100 text-amber-700'}`}>
                      {r.status === 'requested' ? `Requested ${new Date(r.requested_at).toLocaleDateString('en-GB')} · ${age} day${age !== 1 ? 's' : ''}${overdue ? ', chase' : ''}`
                        : r.status === 'received' ? `Part received ${r.credit_note_no ?? ''}` : r.status === 'closed' ? `Received ${r.credit_note_no ?? ''} · closed` : 'Cancelled'}
                    </span>
                  </td>
                  <td className="px-3 text-right">{r.received_amount != null ? money(r.received_amount) : <span className="text-gray-300">—</span>}</td>
                  <td className="px-3 py-2 text-right whitespace-nowrap space-x-1">
                    {(r.status === 'requested' || r.status === 'received') && <>
                      <button onClick={() => { setRecording(r); setCnAmount(String(+(r.total - (r.received_amount ?? 0)).toFixed(2))); setErr('') }} className="text-[11px] border border-gray-300 rounded px-2 py-0.5 hover:bg-gray-50">Record credit note</button>
                      <button onClick={() => remind(r)} className={`text-[11px] rounded px-2 py-0.5 ${overdue ? 'text-white bg-red-600' : 'border border-gray-300 hover:bg-gray-50'}`}>Send reminder</button>
                      <button onClick={async () => { if (window.confirm(`Cancel ${r.reference}?`)) { await setCreditStatus(r, 'cancelled'); load() } }} className="text-[11px] text-gray-400 hover:text-red-600">Cancel</button>
                    </>}
                  </td>
                </tr>
              )
            })}
          </tbody>
        </table>
      )}
      {recording && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40" onClick={() => setRecording(null)}>
          <div className="bg-white rounded-xl shadow-xl w-full max-w-md mx-4 p-5 space-y-3" onClick={e => e.stopPropagation()}>
            <div className="flex justify-between"><h3 className="font-semibold text-sm">Record credit note: {recording.reference}</h3><button onClick={() => setRecording(null)}><X className="w-4 h-4 text-gray-400" /></button></div>
            <div className="grid grid-cols-2 gap-x-4">
              <div><label className="block text-xs font-medium text-gray-700 mb-1">Goldstar credit note no.</label><input value={cnNo} onChange={e => setCnNo(e.target.value)} className="w-full h-[38px] px-3 border border-gray-300 rounded-lg text-sm" /></div>
              <div><label className="block text-xs font-medium text-gray-700 mb-1">Amount received (inc VAT)</label><input value={cnAmount} onChange={e => setCnAmount(e.target.value)} inputMode="decimal" className="w-full h-[38px] px-3 border border-gray-300 rounded-lg text-sm" />
                <p className="text-[11px] text-gray-400 mt-1">requested {money(recording.total)}{recording.received_amount ? `, already received ${money(recording.received_amount)}` : ''}</p></div>
            </div>
            <p className="text-[11px] text-gray-500">Less than requested keeps the rest open as "Part received".</p>
            {err && <p className="text-xs text-red-600">{err}</p>}
            <div className="flex justify-end gap-2"><button onClick={() => setRecording(null)} className="px-3 py-1.5 text-sm bg-gray-100 rounded-lg">Cancel</button><button onClick={saveRecord} className="px-3 py-1.5 text-sm text-white bg-navy rounded-lg">Save</button></div>
          </div>
        </div>
      )}
    </div>
  )
}
