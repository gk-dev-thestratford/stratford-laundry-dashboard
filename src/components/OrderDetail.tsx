import { useState } from 'react'
import { X, Clock, Pencil, Save, XCircle, CheckCircle } from 'lucide-react'
import { format } from 'date-fns'
import StatusBadge from './StatusBadge'
import { ORDER_TYPE_LABELS, ORDER_STATUS_LABELS, ORDER_STATUS_COLORS } from '../types'
import type { Order, OrderStatus, OrderItem, Department } from '../types'

interface OrderDetailProps {
  order: Order
  departments: Department[]
  onClose: () => void
  onStatusChange: (orderId: string, status: OrderStatus, reason?: string) => void
  onSave: (orderId: string, updates: Partial<Order>) => Promise<{ error: unknown }>
  onSaveItem: (itemId: string, updates: { quantity_sent?: number; quantity_received?: number }) => Promise<{ error: unknown }>
}

const STATUS_TRANSITIONS: Record<OrderStatus, OrderStatus[]> = {
  submitted: ['approved', 'rejected'],
  approved: ['collected'],
  rejected: [],
  collected: ['in_processing'],
  in_processing: ['received'],
  received: ['completed'],
  completed: [],
}

const STATUS_ACTION_LABELS: Record<OrderStatus, string> = {
  submitted: 'Submit',
  approved: 'Approve',
  rejected: 'Reject',
  collected: 'Mark Collected',
  in_processing: 'Mark In Processing',
  received: 'Mark Received',
  completed: 'Mark Completed',
}

export default function OrderDetail({ order, departments, onClose, onStatusChange, onSave, onSaveItem }: OrderDetailProps) {
  const nextStatuses = STATUS_TRANSITIONS[order.status] || []
  const [editing, setEditing] = useState(false)
  const [saving, setSaving] = useState(false)

  // Editable fields
  const [staffName, setStaffName] = useState(order.staff_name || '')
  const [email, setEmail] = useState(order.email || '')
  const [guestName, setGuestName] = useState(order.guest_name || '')
  const [roomNumber, setRoomNumber] = useState(order.room_number || '')
  const [bagCount, setBagCount] = useState(order.bag_count ?? 0)
  const [notes, setNotes] = useState(order.notes || '')
  const [departmentId, setDepartmentId] = useState(order.department_id || '')
  const [docketNumber, setDocketNumber] = useState(order.docket_number)

  // Editable items
  const [editItems, setEditItems] = useState<Record<string, { sent: number; received: number | null }>>(
    Object.fromEntries(
      (order.order_items || []).map((item) => [item.id, { sent: item.quantity_sent, received: item.quantity_received }])
    )
  )

  function handleStatusChange(newStatus: OrderStatus) {
    let reason: string | undefined
    if (newStatus === 'rejected') {
      reason = window.prompt('Reason for rejection:') || undefined
    }
    onStatusChange(order.id, newStatus, reason)
  }

  function cancelEdit() {
    setStaffName(order.staff_name || '')
    setEmail(order.email || '')
    setGuestName(order.guest_name || '')
    setRoomNumber(order.room_number || '')
    setBagCount(order.bag_count ?? 0)
    setNotes(order.notes || '')
    setDepartmentId(order.department_id || '')
    setDocketNumber(order.docket_number)
    setEditItems(
      Object.fromEntries(
        (order.order_items || []).map((item) => [item.id, { sent: item.quantity_sent, received: item.quantity_received }])
      )
    )
    setEditing(false)
  }

  async function handleSave() {
    setSaving(true)
    const isGuest = order.order_type === 'guest_laundry'

    await onSave(order.id, {
      docket_number: docketNumber,
      department_id: departmentId || null,
      staff_name: isGuest ? null : staffName || null,
      email: isGuest ? null : email || null,
      guest_name: isGuest ? guestName || null : null,
      room_number: isGuest ? roomNumber || null : null,
      bag_count: isGuest ? bagCount : null,
      notes: notes || null,
    })

    // Save item changes
    for (const item of order.order_items || []) {
      const edited = editItems[item.id]
      if (edited && (edited.sent !== item.quantity_sent || edited.received !== item.quantity_received)) {
        await onSaveItem(item.id, { quantity_sent: edited.sent, quantity_received: edited.received ?? undefined })
      }
    }

    setSaving(false)
    setEditing(false)
  }

  const isGuest = order.order_type === 'guest_laundry'

  return (
    <div className="fixed inset-0 z-50 flex justify-end">
      <div className="absolute inset-0 bg-black/40" onClick={onClose} />
      <div className="relative w-full max-w-lg bg-white shadow-2xl overflow-y-auto">
        {/* Header */}
        <div className="sticky top-0 bg-white border-b border-gray-200 px-6 py-4 flex items-center justify-between z-10">
          <div>
            <h2 className="text-lg font-semibold text-gray-900">Order #{order.docket_number}</h2>
            <p className="text-sm text-gray-500">{ORDER_TYPE_LABELS[order.order_type]}</p>
          </div>
          <div className="flex items-center gap-2">
            {!editing ? (
              <button
                onClick={() => setEditing(true)}
                className="flex items-center gap-1.5 px-3 py-1.5 text-sm text-navy bg-navy/5 hover:bg-navy/10 rounded-lg transition-colors"
              >
                <Pencil className="w-3.5 h-3.5" />
                Edit
              </button>
            ) : (
              <>
                <button
                  onClick={cancelEdit}
                  className="flex items-center gap-1.5 px-3 py-1.5 text-sm text-gray-600 bg-gray-100 hover:bg-gray-200 rounded-lg transition-colors"
                >
                  <XCircle className="w-3.5 h-3.5" />
                  Cancel
                </button>
                <button
                  onClick={handleSave}
                  disabled={saving}
                  className="flex items-center gap-1.5 px-3 py-1.5 text-sm text-white bg-navy hover:bg-navy-light rounded-lg transition-colors disabled:opacity-50"
                >
                  <Save className="w-3.5 h-3.5" />
                  {saving ? 'Saving...' : 'Save'}
                </button>
              </>
            )}
            <button onClick={onClose} className="p-2 hover:bg-gray-100 rounded-lg transition-colors">
              <X className="w-5 h-5 text-gray-500" />
            </button>
          </div>
        </div>

        <div className="p-6 space-y-6">
          {/* Status & Actions */}
          <div>
            <div className="flex items-center gap-3 mb-3">
              <span className="text-sm font-medium text-gray-600">Status:</span>
              <StatusBadge status={order.status} />
            </div>
            {nextStatuses.length > 0 && (
              <div className="flex flex-wrap gap-2">
                {nextStatuses.map((s) => (
                  <button
                    key={s}
                    onClick={() => handleStatusChange(s)}
                    className={`px-4 py-2 text-sm font-medium rounded-lg transition-colors ${
                      s === 'rejected'
                        ? 'bg-red-50 text-red-700 hover:bg-red-100 border border-red-200'
                        : 'bg-navy text-white hover:bg-navy-light'
                    }`}
                  >
                    {STATUS_ACTION_LABELS[s]}
                  </button>
                ))}
              </div>
            )}
          </div>

          {/* Details — editable or read-only */}
          <div className="grid grid-cols-2 gap-4">
            <EditableField
              label="Docket Number"
              value={docketNumber}
              editing={editing}
              onChange={setDocketNumber}
            />
            <div>
              <p className="text-xs font-medium text-gray-500 mb-1">Department</p>
              {editing ? (
                <select
                  value={departmentId}
                  onChange={(e) => setDepartmentId(e.target.value)}
                  className="w-full px-2 py-1.5 text-sm border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-gold"
                >
                  <option value="">—</option>
                  {departments.map((d) => (
                    <option key={d.id} value={d.id}>{d.name}</option>
                  ))}
                </select>
              ) : (
                <p className="text-sm text-gray-900">{order.department?.name || '—'}</p>
              )}
            </div>

            {!isGuest && (
              <>
                <EditableField label="Staff Name" value={staffName} editing={editing} onChange={setStaffName} />
                <EditableField label="Email" value={email} editing={editing} onChange={setEmail} type="email" />
              </>
            )}

            {isGuest && (
              <>
                <EditableField label="Guest Name" value={guestName} editing={editing} onChange={setGuestName} />
                <EditableField label="Room Number" value={roomNumber} editing={editing} onChange={setRoomNumber} />
                <EditableField label="Bag Count" value={String(bagCount)} editing={editing} onChange={(v) => setBagCount(Number(v))} type="number" />
              </>
            )}

            <div>
              <p className="text-xs font-medium text-gray-500">Created</p>
              <p className="text-sm text-gray-900 mt-0.5">{format(new Date(order.created_at), 'dd MMM yyyy HH:mm')}</p>
            </div>
            {order.total_price != null && (
              <div>
                <p className="text-xs font-medium text-gray-500">Total</p>
                <p className="text-sm text-gray-900 mt-0.5 font-medium">{`£${order.total_price.toFixed(2)}`}</p>
              </div>
            )}
          </div>

          {/* Notes */}
          <div>
            <p className="text-sm font-medium text-gray-600 mb-1">Notes</p>
            {editing ? (
              <textarea
                value={notes}
                onChange={(e) => setNotes(e.target.value)}
                rows={3}
                className="w-full px-3 py-2 text-sm border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-gold resize-none"
                placeholder="Add notes..."
              />
            ) : (
              <p className="text-sm text-gray-900 bg-gray-50 rounded-lg p-3 min-h-[40px]">
                {order.notes || 'No notes'}
              </p>
            )}
          </div>

          {/* Items */}
          {order.order_items && order.order_items.length > 0 && (
            <div>
              <h3 className="text-sm font-semibold text-gray-900 mb-3">Items</h3>
              <div className="border border-gray-200 rounded-lg overflow-hidden">
                <table className="w-full text-sm">
                  <thead>
                    <tr className="bg-gray-50 border-b border-gray-200">
                      <th className="px-4 py-2 text-left font-medium text-gray-600">Item</th>
                      <th className="px-4 py-2 text-right font-medium text-gray-600">Sent</th>
                      <th className="px-4 py-2 text-right font-medium text-gray-600">Received</th>
                      <th className="px-4 py-2 text-right font-medium text-gray-600">Price</th>
                    </tr>
                  </thead>
                  <tbody>
                    {order.order_items.map((item) => (
                      <ItemRow
                        key={item.id}
                        item={item}
                        editing={editing}
                        editValues={editItems[item.id]}
                        onChange={(vals) => setEditItems((prev) => ({ ...prev, [item.id]: vals }))}
                      />
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          )}

          {/* Status Timeline */}
          <div>
            <h3 className="text-sm font-semibold text-gray-900 mb-4">Status History</h3>
            {order.status_log && order.status_log.length > 0 ? (
              <div className="relative">
                {/* Timeline line */}
                <div className="absolute left-[15px] top-2 bottom-2 w-0.5 bg-gray-200" />

                <div className="space-y-4">
                  {order.status_log
                    .sort((a, b) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime())
                    .map((log, idx) => {
                      const status = log.status as OrderStatus
                      const colorClass = ORDER_STATUS_COLORS[status] || 'bg-gray-100 text-gray-800'
                      const isLatest = idx === 0

                      return (
                        <div key={log.id} className="flex items-start gap-3 relative">
                          {/* Timeline dot */}
                          <div className={`relative z-10 w-[31px] h-[31px] rounded-full flex items-center justify-center shrink-0 ${
                            isLatest ? 'bg-navy' : 'bg-white border-2 border-gray-300'
                          }`}>
                            {isLatest ? (
                              <CheckCircle className="w-4 h-4 text-white" />
                            ) : (
                              <Clock className="w-3.5 h-3.5 text-gray-400" />
                            )}
                          </div>

                          <div className={`flex-1 rounded-lg p-3 ${isLatest ? 'bg-navy/5 border border-navy/10' : 'bg-gray-50'}`}>
                            <div className="flex items-center justify-between mb-1">
                              <span className={`inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium ${colorClass}`}>
                                {ORDER_STATUS_LABELS[status] || log.status}
                              </span>
                              <span className="text-xs text-gray-400">
                                {format(new Date(log.created_at), 'dd MMM yyyy HH:mm')}
                              </span>
                            </div>
                            {log.changed_by_name && (
                              <p className="text-sm text-gray-700">
                                by <span className="font-medium">{log.changed_by_name}</span>
                              </p>
                            )}
                            {log.reason && (
                              <p className="text-sm text-gray-500 mt-1 italic">"{log.reason}"</p>
                            )}
                          </div>
                        </div>
                      )
                    })}
                </div>
              </div>
            ) : (
              <p className="text-sm text-gray-400 italic">No status history recorded</p>
            )}
          </div>
        </div>
      </div>
    </div>
  )
}

function EditableField({
  label, value, editing, onChange, type = 'text',
}: {
  label: string; value: string; editing: boolean; onChange: (v: string) => void; type?: string
}) {
  return (
    <div>
      <p className="text-xs font-medium text-gray-500 mb-1">{label}</p>
      {editing ? (
        <input
          type={type}
          value={value}
          onChange={(e) => onChange(e.target.value)}
          className="w-full px-2 py-1.5 text-sm border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-gold"
        />
      ) : (
        <p className="text-sm text-gray-900">{value || '—'}</p>
      )}
    </div>
  )
}

function ItemRow({
  item, editing, editValues, onChange,
}: {
  item: OrderItem
  editing: boolean
  editValues: { sent: number; received: number | null }
  onChange: (vals: { sent: number; received: number | null }) => void
}) {
  const sent = editValues?.sent ?? item.quantity_sent
  const received = editValues?.received ?? item.quantity_received

  return (
    <tr className="border-b border-gray-100 last:border-0">
      <td className="px-4 py-2 text-gray-900">{item.item_name}</td>
      <td className="px-4 py-2 text-right">
        {editing ? (
          <input
            type="number"
            min={0}
            value={sent}
            onChange={(e) => onChange({ sent: Number(e.target.value), received })}
            className="w-16 px-2 py-1 text-sm text-right border border-gray-300 rounded focus:outline-none focus:ring-2 focus:ring-gold"
          />
        ) : (
          <span className="text-gray-600">{item.quantity_sent}</span>
        )}
      </td>
      <td className="px-4 py-2 text-right">
        {editing ? (
          <input
            type="number"
            min={0}
            value={received ?? ''}
            onChange={(e) => onChange({ sent, received: e.target.value === '' ? null : Number(e.target.value) })}
            className="w-16 px-2 py-1 text-sm text-right border border-gray-300 rounded focus:outline-none focus:ring-2 focus:ring-gold"
            placeholder="—"
          />
        ) : (
          <span className={
            item.quantity_received != null && item.quantity_received !== item.quantity_sent
              ? 'text-red-600 font-medium'
              : 'text-gray-600'
          }>
            {item.quantity_received ?? '—'}
          </span>
        )}
      </td>
      <td className="px-4 py-2 text-right text-gray-600">
        {item.price_at_time != null ? `£${item.price_at_time.toFixed(2)}` : '—'}
      </td>
    </tr>
  )
}
