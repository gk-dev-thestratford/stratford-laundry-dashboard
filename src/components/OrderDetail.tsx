import { X, Clock } from 'lucide-react'
import { format } from 'date-fns'
import StatusBadge from './StatusBadge'
import { ORDER_TYPE_LABELS, ORDER_STATUS_LABELS } from '../types'
import type { Order, OrderStatus } from '../types'

interface OrderDetailProps {
  order: Order
  onClose: () => void
  onStatusChange: (orderId: string, status: OrderStatus, reason?: string) => void
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

export default function OrderDetail({ order, onClose, onStatusChange }: OrderDetailProps) {
  const nextStatuses = STATUS_TRANSITIONS[order.status] || []

  function handleStatusChange(newStatus: OrderStatus) {
    let reason: string | undefined
    if (newStatus === 'rejected') {
      reason = window.prompt('Reason for rejection:') || undefined
    }
    onStatusChange(order.id, newStatus, reason)
  }

  return (
    <div className="fixed inset-0 z-50 flex justify-end">
      <div className="absolute inset-0 bg-black/40" onClick={onClose} />
      <div className="relative w-full max-w-lg bg-white shadow-2xl overflow-y-auto animate-slide-in">
        {/* Header */}
        <div className="sticky top-0 bg-white border-b border-gray-200 px-6 py-4 flex items-center justify-between">
          <div>
            <h2 className="text-lg font-semibold text-gray-900">Order #{order.docket_number}</h2>
            <p className="text-sm text-gray-500">{ORDER_TYPE_LABELS[order.order_type]}</p>
          </div>
          <button onClick={onClose} className="p-2 hover:bg-gray-100 rounded-lg transition-colors">
            <X className="w-5 h-5 text-gray-500" />
          </button>
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
                    {s === 'approved' && 'Approve'}
                    {s === 'rejected' && 'Reject'}
                    {s === 'collected' && 'Mark Collected'}
                    {s === 'in_processing' && 'Mark In Processing'}
                    {s === 'received' && 'Mark Received'}
                    {s === 'completed' && 'Mark Completed'}
                  </button>
                ))}
              </div>
            )}
          </div>

          {/* Details */}
          <div className="grid grid-cols-2 gap-4">
            <Detail label="Department" value={order.department?.name} />
            {order.staff_name && <Detail label="Staff Name" value={order.staff_name} />}
            {order.email && <Detail label="Email" value={order.email} />}
            {order.guest_name && <Detail label="Guest Name" value={order.guest_name} />}
            {order.room_number && <Detail label="Room" value={order.room_number} />}
            {order.bag_count != null && <Detail label="Bags" value={String(order.bag_count)} />}
            <Detail label="Created" value={format(new Date(order.created_at), 'dd MMM yyyy HH:mm')} />
            {order.total_price != null && <Detail label="Total" value={`£${order.total_price.toFixed(2)}`} />}
          </div>

          {order.notes && (
            <div>
              <p className="text-sm font-medium text-gray-600 mb-1">Notes</p>
              <p className="text-sm text-gray-900 bg-gray-50 rounded-lg p-3">{order.notes}</p>
            </div>
          )}

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
                      <tr key={item.id} className="border-b border-gray-100 last:border-0">
                        <td className="px-4 py-2 text-gray-900">{item.item_name}</td>
                        <td className="px-4 py-2 text-right text-gray-600">{item.quantity_sent}</td>
                        <td className={`px-4 py-2 text-right ${
                          item.quantity_received != null && item.quantity_received !== item.quantity_sent
                            ? 'text-red-600 font-medium'
                            : 'text-gray-600'
                        }`}>
                          {item.quantity_received ?? '—'}
                        </td>
                        <td className="px-4 py-2 text-right text-gray-600">
                          {item.price_at_time != null ? `£${item.price_at_time.toFixed(2)}` : '—'}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          )}

          {/* Status Timeline */}
          {order.status_log && order.status_log.length > 0 && (
            <div>
              <h3 className="text-sm font-semibold text-gray-900 mb-3">Status History</h3>
              <div className="space-y-3">
                {order.status_log
                  .sort((a, b) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime())
                  .map((log) => (
                    <div key={log.id} className="flex items-start gap-3">
                      <div className="mt-0.5">
                        <Clock className="w-4 h-4 text-gray-400" />
                      </div>
                      <div>
                        <p className="text-sm text-gray-900">
                          <span className="font-medium">{ORDER_STATUS_LABELS[log.status as OrderStatus] || log.status}</span>
                          {log.changed_by_name && <span className="text-gray-500"> by {log.changed_by_name}</span>}
                        </p>
                        {log.reason && (
                          <p className="text-sm text-gray-500 mt-0.5">Reason: {log.reason}</p>
                        )}
                        <p className="text-xs text-gray-400 mt-0.5">
                          {format(new Date(log.created_at), 'dd MMM yyyy HH:mm')}
                        </p>
                      </div>
                    </div>
                  ))}
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  )
}

function Detail({ label, value }: { label: string; value?: string | null }) {
  return (
    <div>
      <p className="text-xs font-medium text-gray-500">{label}</p>
      <p className="text-sm text-gray-900 mt-0.5">{value || '—'}</p>
    </div>
  )
}
