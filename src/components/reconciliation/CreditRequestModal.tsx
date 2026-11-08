import { useEffect, useMemo, useState } from 'react'
import { X, Mail, Download, RefreshCw } from 'lucide-react'
import { jsPDF } from 'jspdf'
import autoTable from 'jspdf-autotable'
import {
  CREDIT_REASON_LABELS, createCreditRequest, fetchReconSettings, fetchSupplierContacts, nextCreditReference, openMailDraft,
  type CreditLine, type CreditReason,
} from '../../lib/reconPhase1'

// "Request credit note" (replaces Challenge): one reason + credit amount per selected line,
// To/Cc from Configuration → Goldstar contacts, opens the user's own email program with the
// request filled in (mailto, as before) and offers the PDF to attach. Saved with a reference.

const VAT_RATE = 0.2
const money = (n: number) => `£${n.toFixed(2)}`

export default function CreditRequestModal({ invoiceNumber, invoiceLabel, initialLines, onClose, onCreated }: {
  invoiceNumber: string
  invoiceLabel: string
  initialLines: CreditLine[]
  onClose: () => void
  onCreated: () => void
}) {
  const [lines, setLines] = useState<CreditLine[]>(initialLines)
  const [to, setTo] = useState('')
  const [cc, setCc] = useState('')
  const [message, setMessage] = useState('Please issue a credit note for the lines below. The reason for each line is in the table.')
  const [signature, setSignature] = useState('The Stratford — Laundry Team')
  const [reference, setReference] = useState('')
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState('')

  useEffect(() => {
    fetchSupplierContacts().then(({ contacts }) => {
      setTo(contacts.filter(c => c.role === 'to').map(c => c.email).join(', '))
      setCc(contacts.filter(c => c.role === 'cc').map(c => c.email).join(', '))
    })
    fetchReconSettings().then(s => { if (s.credit_signature) setSignature(s.credit_signature) })
    nextCreditReference(invoiceNumber).then(setReference)
  }, [invoiceNumber])

  const net = useMemo(() => +lines.reduce((s, l) => s + (Number(l.credit_net) || 0), 0).toFixed(2), [lines])
  const vat = +(net * VAT_RATE).toFixed(2)
  const total = +(net + vat).toFixed(2)
  const update = (i: number, patch: Partial<CreditLine>) => setLines(prev => prev.map((l, j) => j === i ? { ...l, ...patch } : l))

  const reasonText = (l: CreditLine) => `${CREDIT_REASON_LABELS[l.reason]}${l.reason_text ? `: ${l.reason_text}` : ''}`
  const subject = `Credit note request: invoice ${invoiceNumber} (${invoiceLabel}): ${money(total)} incl. VAT`
  const body = [
    'Dear Goldstar team,', '', message.trim(), '',
    ...lines.map(l => `${l.date} · ${[l.ticket, l.guest].filter(Boolean).join(' ')} · ${l.description} · ${reasonText(l)} · credit ${money(l.credit_net)} (invoiced ${money(l.invoice_net)})`),
    '', `Total credit requested: ${money(net)} + VAT ${money(vat)} = ${money(total)}`,
    `Our reference: ${reference}`, '', 'Kind regards,', signature,
  ].join('\n')

  function buildPdf() {
    const doc = new jsPDF()
    doc.setFontSize(14); doc.text('Credit note request', 14, 18)
    doc.setFontSize(9); doc.setTextColor('#555555')
    doc.text(`Invoice ${invoiceNumber} (${invoiceLabel}) · Reference ${reference} · ${new Date().toLocaleDateString('en-GB')}`, 14, 25)
    doc.setTextColor('#111111')
    doc.text(doc.splitTextToSize(message.trim(), 180), 14, 33)
    autoTable(doc, {
      startY: 42,
      head: [['Date', 'Ticket / guest', 'Description', 'Reason', 'Invoiced', 'Credit']],
      body: lines.map(l => [l.date, [l.ticket, l.guest].filter(Boolean).join(' '), l.description, reasonText(l), money(l.invoice_net), money(l.credit_net)]),
      foot: [['', '', '', 'Credit NET', '', money(net)], ['', '', '', 'VAT 20%', '', money(vat)], ['', '', '', 'Total', '', money(total)]],
      styles: { fontSize: 8, cellPadding: 1.5 }, headStyles: { fillColor: '#1B2A4A' }, footStyles: { fillColor: '#F3F4F6', textColor: '#111111', fontStyle: 'bold' },
      columnStyles: { 4: { halign: 'right' }, 5: { halign: 'right' } },
    })
    return doc
  }

  async function send() {
    if (!message.trim()) { setError('The message to Goldstar is required.'); return }
    if (!to.trim()) { setError('Add Goldstar’s email (Configuration → Goldstar contacts, or type it here).'); return }
    if (lines.some(l => l.reason === 'other' && !l.reason_text.trim())) { setError('Explain the "Other" reason on each line.'); return }
    if (net <= 0) { setError('The credit amount must be more than £0.'); return }
    setSaving(true); setError('')
    const { error: err } = await createCreditRequest({ reference, invoice_number: invoiceNumber, lines, net, vat, total, to_emails: to, cc_emails: cc, message })
    setSaving(false)
    if (err) { setError(`Could not save the request: ${err}`); return }
    openMailDraft(to, cc, subject, body)
    onCreated()
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40" onClick={() => !saving && onClose()}>
      <div className="bg-white rounded-xl shadow-xl w-full max-w-4xl mx-4 max-h-[90vh] flex flex-col" onClick={e => e.stopPropagation()}>
        <div className="p-5 border-b border-gray-200 flex justify-between gap-3">
          <div>
            <h3 className="text-base font-semibold text-gray-900">Request credit note: {invoiceNumber} ({invoiceLabel})</h3>
            <p className="text-xs text-gray-500 mt-1">{lines.length} line{lines.length !== 1 ? 's' : ''} · the credit amount follows the reason and can be edited · reference {reference || '…'}</p>
          </div>
          <button onClick={onClose} className="p-1 rounded hover:bg-gray-100"><X className="w-5 h-5 text-gray-400" /></button>
        </div>
        <div className="flex-1 overflow-auto p-5 space-y-4 text-sm">
          <table className="w-full text-xs">
            <thead><tr className="text-gray-500 border-b border-gray-200"><th className="py-2 text-left font-medium">Date</th><th className="text-left font-medium">Ticket / guest</th><th className="text-left font-medium">Invoice line</th><th className="text-left font-medium">Reason</th><th className="text-right font-medium">Invoiced</th><th className="text-right font-medium">Credit £</th></tr></thead>
            <tbody className="divide-y divide-gray-100">
              {lines.map((l, i) => (
                <tr key={i} className="align-top">
                  <td className="py-2 pr-2 whitespace-nowrap">{l.date}</td>
                  <td className="pr-2 whitespace-nowrap">{[l.ticket, l.guest].filter(Boolean).join(' ')}</td>
                  <td className="pr-2 max-w-[220px] truncate" title={l.description}>{l.description}</td>
                  <td className="pr-2">
                    <select value={l.reason} onChange={e => update(i, { reason: e.target.value as CreditReason })} className="border border-gray-300 rounded px-1 py-1 bg-white">
                      {Object.entries(CREDIT_REASON_LABELS).map(([k, v]) => <option key={k} value={k}>{v}</option>)}
                    </select>
                    <input value={l.reason_text} onChange={e => update(i, { reason_text: e.target.value })} placeholder={l.reason === 'other' ? 'explain (required)' : 'detail (optional)'}
                      className={`mt-1 w-full border rounded px-1.5 py-1 ${l.reason === 'other' && !l.reason_text.trim() ? 'border-red-300' : 'border-gray-300'}`} />
                  </td>
                  <td className="text-right pr-2">{money(l.invoice_net)}</td>
                  <td className="text-right"><input inputMode="decimal" value={String(l.credit_net)} onChange={e => update(i, { credit_net: Number(e.target.value.replace(/[£,\s]/g, '')) || 0 })} className="w-20 border border-gray-300 rounded px-1.5 py-1 text-right" /></td>
                </tr>
              ))}
            </tbody>
            <tfoot>
              <tr className="border-t-2 border-gray-300 font-semibold"><td colSpan={5} className="py-1.5 text-right">Credit requested (NET)</td><td className="text-right">{money(net)}</td></tr>
              <tr className="text-gray-500"><td colSpan={5} className="text-right">+ VAT 20%</td><td className="text-right">{money(vat)}</td></tr>
              <tr className="font-semibold"><td colSpan={5} className="text-right">Total</td><td className="text-right">{money(total)}</td></tr>
            </tfoot>
          </table>
          <div className="grid grid-cols-2 gap-x-4">
            <div><label className="block text-xs font-medium text-gray-700 mb-1">To</label><input value={to} onChange={e => setTo(e.target.value)} className="w-full h-[38px] px-3 border border-gray-300 rounded-lg" /><p className="text-[11px] text-gray-400 mt-1">from Configuration → Goldstar contacts</p></div>
            <div><label className="block text-xs font-medium text-gray-700 mb-1">Cc</label><input value={cc} onChange={e => setCc(e.target.value)} className="w-full h-[38px] px-3 border border-gray-300 rounded-lg" /></div>
          </div>
          <div><label className="block text-xs font-medium text-gray-700 mb-1">Message to Goldstar <span className="text-red-600">* required</span></label>
            <textarea value={message} onChange={e => setMessage(e.target.value)} rows={2} className="w-full px-3 py-2 border border-gray-300 rounded-lg" /></div>
          <details className="rounded-lg border border-gray-200 bg-gray-50 p-3"><summary className="text-xs font-medium text-gray-600 cursor-pointer">Email preview</summary>
            <pre className="mt-2 text-[11px] whitespace-pre-wrap font-mono text-gray-700">Subject: {subject}{'\n\n'}{body}</pre></details>
          {error && <p className="text-xs text-red-600">{error}</p>}
        </div>
        <div className="p-4 border-t border-gray-200 flex items-center justify-between gap-2">
          <span className="text-xs text-gray-500">Saved as <b>Requested</b> when you press Open in email. Email links can{'’'}t attach files: use Download PDF and attach it.</span>
          <div className="flex gap-2">
            <button onClick={() => buildPdf().save(`credit-request-${reference || invoiceNumber}.pdf`)} className="flex items-center gap-1.5 px-3 py-2 text-sm bg-gray-100 rounded-lg hover:bg-gray-200"><Download className="w-4 h-4" />Download PDF</button>
            <button onClick={send} disabled={saving || !reference} className="flex items-center gap-1.5 px-4 py-2 text-sm text-white bg-navy rounded-lg hover:bg-navy-light disabled:opacity-50">
              {saving ? <RefreshCw className="w-4 h-4 animate-spin" /> : <Mail className="w-4 h-4" />}Open in email</button>
          </div>
        </div>
      </div>
    </div>
  )
}
