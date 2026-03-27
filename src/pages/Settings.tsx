import { useState, useEffect, useCallback } from 'react'
import { Trash2, UserPlus, Users, ShieldCheck } from 'lucide-react'
import { supabase } from '../lib/supabase'
import type { DashboardUser } from '../types'

interface AdminUser {
  id: string
  name: string
  pin_hash: string
  is_active: boolean
  can_delete_orders: boolean
}

interface SettingsProps {
  currentUser: DashboardUser | null
}

// SHA-256 hash matching the Flutter app's crypto package
async function hashPin(pin: string): Promise<string> {
  const data = new TextEncoder().encode(pin)
  const hashBuffer = await crypto.subtle.digest('SHA-256', data)
  const hashArray = Array.from(new Uint8Array(hashBuffer))
  return hashArray.map((b) => b.toString(16).padStart(2, '0')).join('')
}

export default function Settings({ currentUser: _currentUser }: SettingsProps) {
  const [admins, setAdmins] = useState<AdminUser[]>([])
  const [loading, setLoading] = useState(true)
  const [showCreate, setShowCreate] = useState(false)

  // Create form
  const [newName, setNewName] = useState('')
  const [newPin, setNewPin] = useState('')
  const [creating, setCreating] = useState(false)
  const [error, setError] = useState('')
  const [success, setSuccess] = useState('')

  const fetchAdmins = useCallback(async () => {
    setLoading(true)
    const { data } = await supabase
      .from('admin_users')
      .select('*')
      .order('name')
    if (data) setAdmins(data)
    setLoading(false)
  }, [])

  useEffect(() => {
    fetchAdmins()
  }, [fetchAdmins])

  async function handleCreate(e: React.FormEvent) {
    e.preventDefault()
    setError('')
    setSuccess('')

    if (newPin.length < 4) {
      setError('PIN must be at least 4 digits')
      return
    }

    setCreating(true)
    const pinHash = await hashPin(newPin)

    const { error: insertError } = await supabase
      .from('admin_users')
      .insert({ name: newName, pin_hash: pinHash, is_active: true })

    if (insertError) {
      setError(insertError.message)
    } else {
      setSuccess(`User "${newName}" created successfully`)
      setNewName('')
      setNewPin('')
      setShowCreate(false)
      fetchAdmins()
    }
    setCreating(false)
  }

  async function handleToggleActive(admin: AdminUser) {
    const newStatus = !admin.is_active
    const { error } = await supabase
      .from('admin_users')
      .update({ is_active: newStatus })
      .eq('id', admin.id)

    if (error) {
      setError(error.message)
    } else {
      setSuccess(`"${admin.name}" ${newStatus ? 'activated' : 'deactivated'}`)
      fetchAdmins()
    }
  }

  async function handleDelete(admin: AdminUser) {
    if (!window.confirm(`Delete user "${admin.name}"? This cannot be undone.`)) return

    const { error } = await supabase
      .from('admin_users')
      .delete()
      .eq('id', admin.id)

    if (error) {
      setError(error.message)
    } else {
      setSuccess(`"${admin.name}" deleted`)
      fetchAdmins()
    }
  }

  async function handleToggleCanDelete(admin: AdminUser) {
    const newVal = !admin.can_delete_orders
    const { error } = await supabase
      .from('admin_users')
      .update({ can_delete_orders: newVal })
      .eq('id', admin.id)

    if (error) {
      setError(error.message)
    } else {
      setSuccess(`"${admin.name}" ${newVal ? 'can now delete orders' : 'can no longer delete orders'}`)
      fetchAdmins()
    }
  }

  async function handleResetPin(admin: AdminUser) {
    const newPin = window.prompt(`Enter new PIN for "${admin.name}" (min 4 digits):`)
    if (!newPin || newPin.length < 4) {
      if (newPin) setError('PIN must be at least 4 digits')
      return
    }

    const pinHash = await hashPin(newPin)
    const { error } = await supabase
      .from('admin_users')
      .update({ pin_hash: pinHash })
      .eq('id', admin.id)

    if (error) {
      setError(error.message)
    } else {
      setSuccess(`PIN updated for "${admin.name}"`)
    }
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-semibold text-gray-900">User Management</h1>
          <p className="text-sm text-gray-500 mt-1">Manage tablet users and their PIN access</p>
        </div>
        <button
          onClick={() => { setShowCreate(!showCreate); setError(''); setSuccess('') }}
          className="flex items-center gap-2 px-4 py-2 text-sm text-white bg-navy rounded-lg hover:bg-navy-light"
        >
          <UserPlus className="w-4 h-4" />
          Add User
        </button>
      </div>

      {error && (
        <div className="p-3 bg-red-50 border border-red-200 rounded-lg text-sm text-red-700">{error}</div>
      )}
      {success && (
        <div className="p-3 bg-green-50 border border-green-200 rounded-lg text-sm text-green-700">{success}</div>
      )}

      {/* Create admin form */}
      {showCreate && (
        <div className="bg-white rounded-xl border border-gray-200 p-6">
          <h2 className="text-sm font-semibold text-gray-900 mb-4 flex items-center gap-2">
            <UserPlus className="w-4 h-4" />
            Create New Tablet User
          </h2>
          <form onSubmit={handleCreate} className="flex flex-wrap items-end gap-4">
            <div className="flex-1 min-w-[200px]">
              <label className="block text-sm font-medium text-gray-700 mb-1">Full Name *</label>
              <input
                type="text"
                value={newName}
                onChange={(e) => setNewName(e.target.value)}
                required
                className="w-full px-3 py-2 text-sm border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-gold"
                placeholder="e.g. John Smith"
              />
            </div>
            <div className="w-40">
              <label className="block text-sm font-medium text-gray-700 mb-1">PIN * (min 4 digits)</label>
              <input
                type="text"
                value={newPin}
                onChange={(e) => setNewPin(e.target.value.replace(/\D/g, ''))}
                required
                maxLength={6}
                className="w-full px-3 py-2 text-sm border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-gold font-mono tracking-widest text-center"
                placeholder="0000"
              />
            </div>
            <div className="flex gap-2">
              <button
                type="submit"
                disabled={creating}
                className="px-4 py-2 text-sm text-white bg-navy rounded-lg hover:bg-navy-light disabled:opacity-50"
              >
                {creating ? 'Creating...' : 'Create'}
              </button>
              <button
                type="button"
                onClick={() => setShowCreate(false)}
                className="px-4 py-2 text-sm text-gray-700 bg-white border border-gray-200 rounded-lg hover:bg-gray-50"
              >
                Cancel
              </button>
            </div>
          </form>
        </div>
      )}

      {/* Admins list */}
      <div className="bg-white rounded-xl border border-gray-200 overflow-hidden">
        <div className="px-6 py-4 border-b border-gray-200 flex items-center gap-2">
          <Users className="w-5 h-5 text-gray-500" />
          <h2 className="text-sm font-semibold text-gray-900">Tablet Users</h2>
          <span className="text-xs text-gray-400 ml-1">({admins.length})</span>
        </div>

        {loading ? (
          <div className="flex items-center justify-center py-12">
            <div className="w-6 h-6 border-2 border-navy/30 border-t-navy rounded-full animate-spin" />
          </div>
        ) : (
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-gray-200 bg-gray-50">
                <th className="px-6 py-3 text-left font-medium text-gray-600">Name</th>
                <th className="px-6 py-3 text-left font-medium text-gray-600">Status</th>
                <th className="px-6 py-3 text-center font-medium text-gray-600">Can Delete Orders</th>
                <th className="px-6 py-3 text-right font-medium text-gray-600">Actions</th>
              </tr>
            </thead>
            <tbody>
              {admins.map((admin) => (
                <tr key={admin.id} className="border-b border-gray-100 last:border-0">
                  <td className="px-6 py-3">
                    <div className="flex items-center gap-3">
                      <div className={`w-9 h-9 rounded-full flex items-center justify-center text-xs font-semibold ${
                        admin.is_active ? 'bg-navy/10 text-navy' : 'bg-gray-100 text-gray-400'
                      }`}>
                        {admin.name.split(' ').map((n) => n[0]).join('').slice(0, 2)}
                      </div>
                      <div>
                        <span className={`font-medium ${admin.is_active ? 'text-gray-900' : 'text-gray-400'}`}>
                          {admin.name}
                        </span>
                        <p className="text-xs text-gray-400 flex items-center gap-1 mt-0.5">
                          <ShieldCheck className="w-3 h-3" />
                          PIN access
                        </p>
                      </div>
                    </div>
                  </td>
                  <td className="px-6 py-3">
                    <button
                      onClick={() => handleToggleActive(admin)}
                      className={`inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium cursor-pointer transition-colors ${
                        admin.is_active
                          ? 'bg-green-100 text-green-800 hover:bg-green-200'
                          : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
                      }`}
                    >
                      {admin.is_active ? 'Active' : 'Inactive'}
                    </button>
                  </td>
                  <td className="px-6 py-3 text-center">
                    <button
                      onClick={() => handleToggleCanDelete(admin)}
                      className={`relative inline-flex h-6 w-11 items-center rounded-full transition-colors ${
                        admin.can_delete_orders ? 'bg-navy' : 'bg-gray-300'
                      }`}
                      title={admin.can_delete_orders ? 'Click to revoke delete permission' : 'Click to grant delete permission'}
                    >
                      <span
                        className={`inline-block h-4 w-4 rounded-full bg-white shadow transform transition-transform ${
                          admin.can_delete_orders ? 'translate-x-6' : 'translate-x-1'
                        }`}
                      />
                    </button>
                  </td>
                  <td className="px-6 py-3 text-right">
                    <div className="flex items-center justify-end gap-2">
                      <button
                        onClick={() => handleResetPin(admin)}
                        className="px-2.5 py-1.5 text-xs text-navy bg-navy/5 hover:bg-navy/10 border border-navy/10 rounded-lg transition-colors"
                      >
                        Reset PIN
                      </button>
                      <button
                        onClick={() => handleDelete(admin)}
                        className="inline-flex items-center gap-1 px-2.5 py-1.5 text-xs text-red-700 bg-red-50 hover:bg-red-100 border border-red-200 rounded-lg transition-colors"
                      >
                        <Trash2 className="w-3 h-3" />
                        Delete
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
              {admins.length === 0 && (
                <tr>
                  <td colSpan={4} className="px-6 py-12 text-center text-gray-500">No admin users found</td>
                </tr>
              )}
            </tbody>
          </table>
        )}
      </div>

      <p className="text-xs text-gray-400">
        These are the users who can log into the tablet app with a PIN to manage orders.
      </p>
    </div>
  )
}
