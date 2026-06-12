import { useState, useEffect } from 'react'
import { Mail, Plus, Trash2, Loader2, Settings } from 'lucide-react'
import { format } from 'date-fns'
import { supabase } from '../lib/supabase'

/**
 * Configuration — the dashboard acts as the back office for the tablet app.
 * First section: daily-report email recipients (report_recipients table; the
 * daily-report edge function reads the same table for tablet-triggered sends).
 * New operational settings should be added here as further sections.
 */

interface Recipient {
  id: string
  email: string
  added_by: string | null
  created_at: string
}

export default function Configuration() {
  const [recipients, setRecipients] = useState<Recipient[]>([])
  const [loading, setLoading] = useState(true)
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [newEmail, setNewEmail] = useState('')

  async function load() {
    const { data, error: fetchErr } = await supabase
      .from('report_recipients')
      .select('id, email, added_by, created_at')
      .eq('is_active', true)
      .order('created_at')
    if (fetchErr) setError(fetchErr.message)
    else setRecipients((data ?? []) as Recipient[])
    setLoading(false)
  }

  useEffect(() => { load() }, [])

  async function addRecipient() {
    const email = newEmail.trim().toLowerCase()
    if (!email) return
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
      setError("That doesn't look like a valid email address")
      return
    }
    setBusy(true)
    setError(null)
    const { data: { user } } = await supabase.auth.getUser()
    let addedBy = 'dashboard'
    if (user) {
      const { data: du } = await supabase.from('dashboard_users').select('name, email').eq('id', user.id).single()
      addedBy = du?.name || du?.email || addedBy
    }
    const { error: insErr } = await supabase.from('report_recipients').insert({ email, added_by: addedBy })
    if (insErr) {
      setError(insErr.code === '23505' ? 'That email is already on the list' : insErr.message)
    } else {
      setNewEmail('')
      await load()
    }
    setBusy(false)
  }

  async function removeRecipient(r: Recipient) {
    if (!window.confirm(`Remove ${r.email} from the daily report recipients?`)) return
    setBusy(true)
    setError(null)
    const { error: delErr } = await supabase.from('report_recipients').delete().eq('id', r.id)
    if (delErr) setError(delErr.message)
    else setRecipients((prev) => prev.filter((x) => x.id !== r.id))
    setBusy(false)
  }

  return (
    <div className="space-y-6 max-w-3xl">
      <div>
        <h1 className="text-2xl font-semibold text-gray-900 flex items-center gap-2">
          <Settings className="w-6 h-6 text-navy" />
          Configuration
        </h1>
        <p className="text-sm text-gray-500 mt-1">
          Operational settings for the laundry system — changes here apply to both the dashboard and the tablet app.
        </p>
      </div>

      {/* ── Daily report recipients ── */}
      <section className="bg-white rounded-xl border border-gray-200 overflow-hidden">
        <div className="px-5 py-4 border-b border-gray-100 flex items-center gap-2">
          <Mail className="w-4 h-4 text-navy" />
          <h2 className="font-semibold text-gray-900">Daily Report Recipients</h2>
        </div>
        <div className="px-5 py-4 space-y-4">
          <p className="text-xs text-gray-500">
            These addresses receive the daily laundry report (received, sent, outstanding items and napkin returns) —
            whether it is sent from the dashboard or from the tablet.
          </p>

          {error && (
            <div className="px-3 py-2 bg-red-50 border border-red-200 rounded-lg text-sm text-red-700">{error}</div>
          )}

          {loading ? (
            <div className="flex items-center gap-2 text-gray-400 text-sm py-4">
              <Loader2 className="w-4 h-4 animate-spin" /> Loading…
            </div>
          ) : (
            <ul className="divide-y divide-gray-100 border border-gray-200 rounded-lg overflow-hidden">
              {recipients.length === 0 && (
                <li className="px-4 py-6 text-center text-sm text-red-600 font-medium">
                  No recipients configured — the daily report cannot be sent until at least one is added.
                </li>
              )}
              {recipients.map((r) => (
                <li key={r.id} className="px-4 py-2.5 flex items-center gap-3 bg-white">
                  <Mail className="w-4 h-4 text-gray-300 shrink-0" />
                  <div className="flex-1 min-w-0">
                    <p className="text-sm text-gray-900 truncate">{r.email}</p>
                    <p className="text-[11px] text-gray-400">
                      added {format(new Date(r.created_at), 'dd MMM yyyy')}{r.added_by ? ` by ${r.added_by}` : ''}
                    </p>
                  </div>
                  <button
                    onClick={() => removeRecipient(r)}
                    disabled={busy}
                    className="p-1.5 text-gray-400 hover:text-red-600 hover:bg-red-50 rounded-lg transition-colors disabled:opacity-50"
                    title={`Remove ${r.email}`}
                  >
                    <Trash2 className="w-4 h-4" />
                  </button>
                </li>
              ))}
            </ul>
          )}

          <div className="flex gap-2">
            <input
              type="email"
              value={newEmail}
              onChange={(e) => { setNewEmail(e.target.value); setError(null) }}
              onKeyDown={(e) => { if (e.key === 'Enter') addRecipient() }}
              placeholder="add.recipient@example.com"
              className="flex-1 px-3 py-2 text-sm border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-gold"
            />
            <button
              onClick={addRecipient}
              disabled={busy || !newEmail.trim()}
              className="flex items-center gap-1.5 px-4 py-2 text-sm font-medium text-white bg-navy rounded-lg hover:bg-navy-light disabled:opacity-50"
            >
              {busy ? <Loader2 className="w-4 h-4 animate-spin" /> : <Plus className="w-4 h-4" />}
              Add
            </button>
          </div>
        </div>
      </section>
    </div>
  )
}
