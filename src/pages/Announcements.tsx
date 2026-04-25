import { useState, useEffect, useCallback, useMemo } from 'react'
import {
  Plus, Pencil, Trash2, X, Save, AlertCircle, AlertTriangle, Info,
  RefreshCw, Calendar, Clock,
} from 'lucide-react'
import { format } from 'date-fns'
import { supabase } from '../lib/supabase'
import type { Announcement, AnnouncementSeverity } from '../types'
import { ANNOUNCEMENT_SEVERITY_LABELS } from '../types'

type Tab = 'active' | 'upcoming' | 'expired'

const EMPTY_FORM: FormState = {
  title: '',
  body: '',
  starts_at: localNowPlus(0),
  ends_at: localNowPlus(60),
  severity: 'info',
  is_active: true,
}

interface FormState {
  title: string
  body: string
  starts_at: string  // datetime-local format: "yyyy-MM-ddTHH:mm"
  ends_at: string
  severity: AnnouncementSeverity
  is_active: boolean
}

/** Returns now + N minutes formatted for <input type="datetime-local"> in LOCAL time. */
function localNowPlus(minutes: number): string {
  const d = new Date(Date.now() + minutes * 60_000)
  const pad = (n: number) => String(n).padStart(2, '0')
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}T${pad(d.getHours())}:${pad(d.getMinutes())}`
}

/** datetime-local string -> ISO with the user's local timezone offset baked in. */
function localToISO(local: string): string {
  if (!local) return ''
  return new Date(local).toISOString()
}

/** ISO -> datetime-local string for the form. */
function isoToLocal(iso: string): string {
  const d = new Date(iso)
  const pad = (n: number) => String(n).padStart(2, '0')
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}T${pad(d.getHours())}:${pad(d.getMinutes())}`
}

export default function Announcements() {
  const [items, setItems] = useState<Announcement[]>([])
  const [loading, setLoading] = useState(true)
  const [tab, setTab] = useState<Tab>('active')
  const [formOpen, setFormOpen] = useState(false)
  const [editing, setEditing] = useState<Announcement | null>(null)
  const [form, setForm] = useState<FormState>(EMPTY_FORM)
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const fetchAll = useCallback(async () => {
    setLoading(true)
    const { data, error } = await supabase
      .from('announcements')
      .select('*')
      .order('starts_at', { ascending: false })
    if (error) {
      setError(error.message)
    } else {
      setItems((data ?? []) as Announcement[])
      setError(null)
    }
    setLoading(false)
  }, [])

  useEffect(() => { fetchAll() }, [fetchAll])

  const buckets = useMemo(() => {
    const now = Date.now()
    const active: Announcement[] = []
    const upcoming: Announcement[] = []
    const expired: Announcement[] = []
    for (const a of items) {
      const start = new Date(a.starts_at).getTime()
      const end = new Date(a.ends_at).getTime()
      if (end < now) {
        expired.push(a)
      } else if (start > now) {
        upcoming.push(a)
      } else {
        active.push(a)
      }
    }
    return { active, upcoming, expired }
  }, [items])

  const visible = buckets[tab]

  function openCreate() {
    setEditing(null)
    setForm({ ...EMPTY_FORM, starts_at: localNowPlus(0), ends_at: localNowPlus(60) })
    setFormOpen(true)
  }

  function openEdit(a: Announcement) {
    setEditing(a)
    setForm({
      title: a.title,
      body: a.body ?? '',
      starts_at: isoToLocal(a.starts_at),
      ends_at: isoToLocal(a.ends_at),
      severity: a.severity,
      is_active: a.is_active,
    })
    setFormOpen(true)
  }

  function closeForm() {
    setFormOpen(false)
    setEditing(null)
    setForm(EMPTY_FORM)
    setError(null)
  }

  async function handleSave() {
    if (!form.title.trim()) {
      setError('Title is required')
      return
    }
    const starts = localToISO(form.starts_at)
    const ends = localToISO(form.ends_at)
    if (!starts || !ends) {
      setError('Start and end times are required')
      return
    }
    if (new Date(starts) >= new Date(ends)) {
      setError('End must be after start')
      return
    }

    setSaving(true)
    setError(null)

    const payload = {
      title: form.title.trim(),
      body: form.body.trim() || null,
      starts_at: starts,
      ends_at: ends,
      severity: form.severity,
      is_active: form.is_active,
    }

    let creatorName = 'Dashboard'
    const { data: { user } } = await supabase.auth.getUser()
    if (user) {
      const { data: du } = await supabase.from('dashboard_users').select('name, email').eq('id', user.id).single()
      creatorName = du?.name || du?.email || creatorName
    }

    if (editing) {
      const { error } = await supabase.from('announcements').update(payload).eq('id', editing.id)
      if (error) {
        setError(error.message); setSaving(false); return
      }
    } else {
      const { error } = await supabase.from('announcements').insert({ ...payload, created_by: creatorName })
      if (error) {
        setError(error.message); setSaving(false); return
      }
    }

    setSaving(false)
    closeForm()
    fetchAll()
  }

  async function handleDelete(a: Announcement) {
    if (!window.confirm(`Delete announcement "${a.title}"? This cannot be undone.`)) return
    const { error } = await supabase.from('announcements').delete().eq('id', a.id)
    if (error) {
      window.alert(`Delete failed: ${error.message}`)
      return
    }
    fetchAll()
  }

  async function handleToggleActive(a: Announcement) {
    const { error } = await supabase
      .from('announcements')
      .update({ is_active: !a.is_active })
      .eq('id', a.id)
    if (error) {
      window.alert(`Update failed: ${error.message}`)
      return
    }
    fetchAll()
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-semibold text-gray-900">Announcements</h1>
          <p className="text-sm text-gray-500 mt-1">
            Schedule a message banner to appear on the tablet dashboard and order screens
          </p>
        </div>
        <div className="flex items-center gap-2">
          <button
            onClick={fetchAll}
            className="p-2 text-gray-600 hover:bg-gray-100 rounded-lg"
            title="Refresh"
          >
            <RefreshCw className={`w-4 h-4 ${loading ? 'animate-spin' : ''}`} />
          </button>
          <button
            onClick={openCreate}
            className="flex items-center gap-2 px-4 py-2 text-sm font-medium text-white bg-navy hover:bg-navy-light rounded-lg"
          >
            <Plus className="w-4 h-4" />
            New Announcement
          </button>
        </div>
      </div>

      <div className="flex items-center gap-1 border-b border-gray-200">
        {(['active', 'upcoming', 'expired'] as const).map((t) => {
          const count = buckets[t].length
          const isOn = tab === t
          return (
            <button
              key={t}
              onClick={() => setTab(t)}
              className={`px-4 py-2 text-sm font-medium border-b-2 transition-colors ${
                isOn ? 'border-navy text-navy' : 'border-transparent text-gray-500 hover:text-gray-700'
              }`}
            >
              {t.charAt(0).toUpperCase() + t.slice(1)}
              <span className={`ml-2 px-1.5 py-0.5 rounded-full text-[10px] ${
                isOn ? 'bg-navy/10 text-navy' : 'bg-gray-100 text-gray-500'
              }`}>{count}</span>
            </button>
          )
        })}
      </div>

      {loading ? (
        <div className="flex items-center justify-center py-20">
          <RefreshCw className="w-6 h-6 text-gray-400 animate-spin" />
        </div>
      ) : visible.length === 0 ? (
        <EmptyState tab={tab} />
      ) : (
        <div className="space-y-3">
          {visible.map((a) => (
            <AnnouncementRow
              key={a.id}
              announcement={a}
              tab={tab}
              onEdit={() => openEdit(a)}
              onDelete={() => handleDelete(a)}
              onToggleActive={() => handleToggleActive(a)}
            />
          ))}
        </div>
      )}

      {formOpen && (
        <FormModal
          form={form}
          editing={!!editing}
          saving={saving}
          error={error}
          onChange={setForm}
          onClose={closeForm}
          onSave={handleSave}
        />
      )}
    </div>
  )
}

function AnnouncementRow({ announcement, tab, onEdit, onDelete, onToggleActive }: {
  announcement: Announcement
  tab: Tab
  onEdit: () => void
  onDelete: () => void
  onToggleActive: () => void
}) {
  const tone = severityClasses(announcement.severity)
  return (
    <div className={`border rounded-xl ${tone.border} ${tone.bg} overflow-hidden`}>
      <div className="px-4 py-3">
        <div className="flex items-start gap-3">
          <div className={`mt-0.5 ${tone.icon}`}>
            <SeverityIcon severity={announcement.severity} />
          </div>
          <div className="flex-1 min-w-0">
            <div className="flex items-center gap-2 flex-wrap">
              <h3 className={`font-semibold ${tone.title}`}>{announcement.title}</h3>
              <span className={`px-2 py-0.5 rounded-full text-[10px] font-medium ${tone.badge}`}>
                {ANNOUNCEMENT_SEVERITY_LABELS[announcement.severity]}
              </span>
              {!announcement.is_active && (
                <span className="px-2 py-0.5 rounded-full text-[10px] font-medium bg-gray-200 text-gray-600">
                  Disabled
                </span>
              )}
              {tab === 'active' && (
                <span className="px-2 py-0.5 rounded-full text-[10px] font-medium bg-green-100 text-green-700">
                  Live
                </span>
              )}
            </div>
            {announcement.body && (
              <p className={`text-sm mt-1 ${tone.body}`}>{announcement.body}</p>
            )}
            <div className="flex items-center gap-4 mt-2 text-xs text-gray-500">
              <span className="flex items-center gap-1">
                <Calendar className="w-3 h-3" />
                {format(new Date(announcement.starts_at), 'd MMM yyyy')}
              </span>
              <span className="flex items-center gap-1">
                <Clock className="w-3 h-3" />
                {format(new Date(announcement.starts_at), 'HH:mm')} → {format(new Date(announcement.ends_at), 'd MMM yyyy HH:mm')}
              </span>
              {announcement.created_by && <span>by {announcement.created_by}</span>}
            </div>
          </div>
          <div className="flex items-center gap-1">
            <button
              onClick={onToggleActive}
              className="px-2 py-1.5 text-xs text-gray-600 hover:bg-white rounded-lg"
              title={announcement.is_active ? 'Disable (hide on tablet)' : 'Enable'}
            >
              {announcement.is_active ? 'Disable' : 'Enable'}
            </button>
            <button
              onClick={onEdit}
              className="p-2 text-gray-600 hover:bg-white rounded-lg"
              title="Edit"
            >
              <Pencil className="w-4 h-4" />
            </button>
            <button
              onClick={onDelete}
              className="p-2 text-red-600 hover:bg-red-50 rounded-lg"
              title="Delete"
            >
              <Trash2 className="w-4 h-4" />
            </button>
          </div>
        </div>
      </div>
    </div>
  )
}

function FormModal({
  form, editing, saving, error, onChange, onClose, onSave,
}: {
  form: FormState
  editing: boolean
  saving: boolean
  error: string | null
  onChange: (f: FormState) => void
  onClose: () => void
  onSave: () => void
}) {
  return (
    <div className="fixed inset-0 z-50 bg-black/40 flex items-center justify-center p-4">
      <div className="bg-white rounded-2xl shadow-2xl w-full max-w-2xl overflow-hidden flex flex-col max-h-[90vh]">
        <div className="px-6 py-4 border-b border-gray-100 flex items-center justify-between">
          <h2 className="font-semibold text-gray-900">
            {editing ? 'Edit Announcement' : 'New Announcement'}
          </h2>
          <button onClick={onClose} className="p-1.5 hover:bg-gray-100 rounded-lg">
            <X className="w-4 h-4 text-gray-500" />
          </button>
        </div>

        <div className="flex-1 overflow-y-auto px-6 py-4 space-y-4">
          {error && (
            <div className="flex items-start gap-2 p-3 bg-red-50 border border-red-200 rounded-lg">
              <AlertCircle className="w-4 h-4 text-red-500 flex-shrink-0 mt-0.5" />
              <p className="text-xs text-red-700">{error}</p>
            </div>
          )}

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Title</label>
            <input
              type="text"
              value={form.title}
              onChange={(e) => onChange({ ...form, title: e.target.value })}
              placeholder="e.g. No laundry collection tomorrow"
              maxLength={120}
              className="w-full px-3 py-2 text-sm border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-navy/30 focus:border-navy"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Body (optional)</label>
            <textarea
              value={form.body}
              onChange={(e) => onChange({ ...form, body: e.target.value })}
              placeholder="Add context — staff will see this under the title"
              rows={3}
              className="w-full px-3 py-2 text-sm border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-navy/30 focus:border-navy resize-none"
            />
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Starts</label>
              <input
                type="datetime-local"
                value={form.starts_at}
                onChange={(e) => onChange({ ...form, starts_at: e.target.value })}
                className="w-full px-3 py-2 text-sm border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-navy/30 focus:border-navy"
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Ends</label>
              <input
                type="datetime-local"
                value={form.ends_at}
                onChange={(e) => onChange({ ...form, ends_at: e.target.value })}
                className="w-full px-3 py-2 text-sm border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-navy/30 focus:border-navy"
              />
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">Severity</label>
            <div className="grid grid-cols-3 gap-2">
              {(['info', 'warning', 'critical'] as const).map((s) => {
                const tone = severityClasses(s)
                const isOn = form.severity === s
                return (
                  <button
                    key={s}
                    type="button"
                    onClick={() => onChange({ ...form, severity: s })}
                    className={`flex items-center justify-center gap-2 px-3 py-2 text-sm font-medium rounded-lg border transition-all ${
                      isOn
                        ? `${tone.bg} ${tone.border} ${tone.title}`
                        : 'bg-white border-gray-200 text-gray-500 hover:border-gray-300'
                    }`}
                  >
                    <SeverityIcon severity={s} />
                    {ANNOUNCEMENT_SEVERITY_LABELS[s]}
                  </button>
                )
              })}
            </div>
          </div>

          <label className="flex items-center gap-2 px-3 py-2 bg-gray-50 rounded-lg cursor-pointer">
            <input
              type="checkbox"
              checked={form.is_active}
              onChange={(e) => onChange({ ...form, is_active: e.target.checked })}
              className="w-4 h-4 rounded border-gray-300 text-navy focus:ring-navy"
            />
            <span className="text-sm text-gray-700">
              <strong>Enabled</strong> — uncheck to keep the schedule but hide it from the tablet
            </span>
          </label>

          <p className="text-xs text-gray-400 italic">
            Times use your local timezone. The tablet displays the banner only between Start and End.
          </p>
        </div>

        <div className="px-6 py-3 border-t border-gray-100 flex items-center justify-end gap-2">
          <button
            onClick={onClose}
            disabled={saving}
            className="px-4 py-2 text-sm text-gray-600 hover:bg-gray-100 rounded-lg disabled:opacity-50"
          >
            Cancel
          </button>
          <button
            onClick={onSave}
            disabled={saving}
            className="flex items-center gap-2 px-5 py-2 text-sm font-medium text-white bg-navy hover:bg-navy-light rounded-lg disabled:bg-gray-300"
          >
            <Save className="w-4 h-4" />
            {saving ? 'Saving…' : editing ? 'Save Changes' : 'Create'}
          </button>
        </div>
      </div>
    </div>
  )
}

function EmptyState({ tab }: { tab: Tab }) {
  const messages: Record<Tab, { title: string; sub: string }> = {
    active: { title: 'No active announcements', sub: 'Anything currently live on the tablet will show here.' },
    upcoming: { title: 'Nothing scheduled ahead', sub: 'Create an announcement with a future start time and it\'ll appear here.' },
    expired: { title: 'No expired announcements yet', sub: 'Past announcements stay here for audit.' },
  }
  const m = messages[tab]
  return (
    <div className="flex flex-col items-center justify-center py-16 text-center text-gray-400">
      <div className="w-12 h-12 rounded-full bg-gray-100 flex items-center justify-center mb-3">
        <Info className="w-6 h-6 text-gray-300" />
      </div>
      <p className="text-sm font-medium text-gray-600">{m.title}</p>
      <p className="text-xs mt-1 max-w-md">{m.sub}</p>
    </div>
  )
}

function severityClasses(severity: AnnouncementSeverity) {
  switch (severity) {
    case 'critical':
      return {
        border: 'border-red-200',
        bg: 'bg-red-50',
        title: 'text-red-900',
        body: 'text-red-700',
        icon: 'text-red-500',
        badge: 'bg-red-100 text-red-700',
      }
    case 'warning':
      return {
        border: 'border-amber-200',
        bg: 'bg-amber-50',
        title: 'text-amber-900',
        body: 'text-amber-800',
        icon: 'text-amber-500',
        badge: 'bg-amber-100 text-amber-800',
      }
    case 'info':
    default:
      return {
        border: 'border-blue-200',
        bg: 'bg-blue-50',
        title: 'text-blue-900',
        body: 'text-blue-700',
        icon: 'text-blue-500',
        badge: 'bg-blue-100 text-blue-700',
      }
  }
}

function SeverityIcon({ severity }: { severity: AnnouncementSeverity }) {
  if (severity === 'critical') return <AlertCircle className="w-4 h-4" />
  if (severity === 'warning') return <AlertTriangle className="w-4 h-4" />
  return <Info className="w-4 h-4" />
}
