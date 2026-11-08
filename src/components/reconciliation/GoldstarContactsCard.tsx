import { useEffect, useState } from 'react'
import { Mail, Plus, Trash2, RefreshCw } from 'lucide-react'
import {
  addSupplierContact, fetchReconSettings, fetchSupplierContacts, removeSupplierContact, saveReconSetting,
  type SupplierContact,
} from '../../lib/reconPhase1'

// Configuration → Goldstar contacts: To / Cc for credit note emails, how long before a
// credit request is flagged for chasing, and the email signature.

export default function GoldstarContactsCard() {
  const [contacts, setContacts] = useState<SupplierContact[]>([])
  const [available, setAvailable] = useState(true)
  const [loading, setLoading] = useState(true)
  const [email, setEmail] = useState('')
  const [role, setRole] = useState<'to' | 'cc'>('to')
  const [chase, setChase] = useState('30')
  const [signature, setSignature] = useState('')
  const [msg, setMsg] = useState('')

  const load = async () => {
    setLoading(true)
    const [{ contacts: c, available: a }, settings] = await Promise.all([fetchSupplierContacts(), fetchReconSettings()])
    setContacts(c); setAvailable(a)
    setChase(settings.credit_chase_days ?? '30'); setSignature(settings.credit_signature ?? 'The Stratford — Laundry Team')
    setLoading(false)
  }
  useEffect(() => { load() }, [])

  const add = async () => {
    const e = email.trim().toLowerCase()
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(e)) { setMsg('Enter a valid email address.'); return }
    const err = await addSupplierContact(e, role)
    if (err) { setMsg(/duplicate|unique/i.test(err) ? 'That address is already in the list.' : err); return }
    setEmail(''); setMsg(''); load()
  }
  const remove = async (c: SupplierContact) => {
    if (!window.confirm(`Remove ${c.email}?`)) return
    const err = await removeSupplierContact(c.id)
    if (err) setMsg(err); else load()
  }
  const saveSetting = async (key: string, value: string) => {
    const err = await saveReconSetting(key, value)
    setMsg(err ? err : 'Saved')
    if (!err) setTimeout(() => setMsg(''), 1500)
  }

  return (
    <section className="bg-white rounded-xl border border-gray-200 overflow-hidden">
      <div className="px-5 py-4 border-b border-gray-100 flex items-center gap-2">
        <Mail className="w-4 h-4 text-navy" /><h2 className="font-semibold text-gray-900">Goldstar Contacts: credit note requests</h2>
      </div>
      <div className="px-5 py-4 space-y-4 text-sm">
        {!available ? (
          <p className="text-xs text-amber-800 bg-amber-50 rounded-lg p-3">Not available yet: run <span className="font-mono">db/migrations/2026-11-08_reconciliation_phase1.sql</span> in Supabase.</p>
        ) : loading ? <RefreshCw className="w-5 h-5 text-gray-400 animate-spin" /> : (<>
          <p className="text-xs text-gray-500">Used to fill in To / Cc of credit note emails from the Reconciliation page. Emails open in your own email program.</p>
          <div className="border border-gray-200 rounded-lg divide-y divide-gray-100">
            {contacts.length === 0 && <p className="px-4 py-3 text-xs text-gray-400">No contacts yet.</p>}
            {contacts.map(c => (
              <div key={c.id} className="px-4 py-3 flex items-center justify-between">
                <span>{c.email} <span className={`ml-1 text-[11px] rounded px-1.5 ${c.role === 'to' ? 'text-indigo-700 bg-indigo-50' : 'text-gray-600 bg-gray-100'}`}>{c.role === 'to' ? 'To' : 'Cc'}</span>
                  {c.added_by && <span className="block text-[11px] text-gray-400">added by {c.added_by}</span>}</span>
                <button onClick={() => remove(c)} className="p-1.5 rounded hover:bg-red-50 text-gray-400 hover:text-red-600" title="Remove"><Trash2 className="w-4 h-4" /></button>
              </div>
            ))}
          </div>
          <div className="grid grid-cols-[1fr_110px_90px] gap-2">
            <input value={email} onChange={e => setEmail(e.target.value)} onKeyDown={e => { if (e.key === 'Enter') add() }} placeholder="add.contact@example.com" className="h-[38px] px-3 border border-gray-300 rounded-lg" />
            <select value={role} onChange={e => setRole(e.target.value as 'to' | 'cc')} className="h-[38px] px-3 border border-gray-300 rounded-lg bg-white"><option value="to">To</option><option value="cc">Cc</option></select>
            <button onClick={add} className="h-[38px] flex items-center justify-center gap-1 rounded-lg bg-navy text-white"><Plus className="w-4 h-4" />Add</button>
          </div>
          <div className="grid grid-cols-2 gap-x-4">
            <div><label className="block text-xs font-medium text-gray-700 mb-1">Chase credit notes after (days)</label>
              <input value={chase} onChange={e => setChase(e.target.value)} onBlur={() => saveSetting('credit_chase_days', String(Number(chase) || 30))} inputMode="numeric" className="w-full h-[38px] px-3 border border-gray-300 rounded-lg" /></div>
            <div><label className="block text-xs font-medium text-gray-700 mb-1">Email signature</label>
              <input value={signature} onChange={e => setSignature(e.target.value)} onBlur={() => saveSetting('credit_signature', signature.trim())} className="w-full h-[38px] px-3 border border-gray-300 rounded-lg" /></div>
          </div>
          {msg && <p className={`text-xs ${msg === 'Saved' ? 'text-green-600' : 'text-red-600'}`}>{msg}</p>}
        </>)}
      </div>
    </section>
  )
}
