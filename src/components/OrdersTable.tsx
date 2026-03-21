import { format } from 'date-fns'
import StatusBadge from './StatusBadge'
import { ORDER_TYPE_LABELS } from '../types'
import type { Order } from '../types'

interface OrdersTableProps {
  orders: Order[]
  selectedIds: Set<string>
  onToggleSelect: (id: string) => void
  onToggleAll: () => void
  onRowClick: (order: Order) => void
}

export default function OrdersTable({ orders, selectedIds, onToggleSelect, onToggleAll, onRowClick }: OrdersTableProps) {
  return (
    <div className="bg-white rounded-xl border border-gray-200 overflow-hidden">
      <div className="overflow-x-auto">
        <table className="w-full text-sm">
          <thead>
            <tr className="border-b border-gray-200 bg-gray-50">
              <th className="w-10 px-4 py-3">
                <input
                  type="checkbox"
                  checked={selectedIds.size === orders.length && orders.length > 0}
                  onChange={onToggleAll}
                  className="rounded border-gray-300"
                />
              </th>
              <th className="px-4 py-3 text-left font-medium text-gray-600">Docket</th>
              <th className="px-4 py-3 text-left font-medium text-gray-600">Type</th>
              <th className="px-4 py-3 text-left font-medium text-gray-600">Name</th>
              <th className="px-4 py-3 text-left font-medium text-gray-600">Department</th>
              <th className="px-4 py-3 text-left font-medium text-gray-600">Items</th>
              <th className="px-4 py-3 text-left font-medium text-gray-600">Total</th>
              <th className="px-4 py-3 text-left font-medium text-gray-600">Status</th>
              <th className="px-4 py-3 text-left font-medium text-gray-600">Date</th>
            </tr>
          </thead>
          <tbody>
            {orders.length === 0 ? (
              <tr>
                <td colSpan={9} className="px-4 py-12 text-center text-gray-500">
                  No orders found
                </td>
              </tr>
            ) : (
              orders.map((order) => (
                <tr
                  key={order.id}
                  onClick={() => onRowClick(order)}
                  className="border-b border-gray-100 hover:bg-gray-50 cursor-pointer transition-colors"
                >
                  <td className="px-4 py-3" onClick={(e) => e.stopPropagation()}>
                    <input
                      type="checkbox"
                      checked={selectedIds.has(order.id)}
                      onChange={() => onToggleSelect(order.id)}
                      className="rounded border-gray-300"
                    />
                  </td>
                  <td className="px-4 py-3 font-mono font-medium text-navy">
                    {order.docket_number}
                  </td>
                  <td className="px-4 py-3 text-gray-600">
                    {ORDER_TYPE_LABELS[order.order_type]}
                  </td>
                  <td className="px-4 py-3 text-gray-900">
                    {order.staff_name || order.guest_name || '—'}
                  </td>
                  <td className="px-4 py-3 text-gray-600">
                    {order.department?.name || '—'}
                  </td>
                  <td className="px-4 py-3 text-gray-600">
                    {order.order_items?.length || 0}
                  </td>
                  <td className="px-4 py-3 text-gray-900 font-medium">
                    {order.total_price != null ? `£${order.total_price.toFixed(2)}` : '—'}
                  </td>
                  <td className="px-4 py-3">
                    <StatusBadge status={order.status} />
                  </td>
                  <td className="px-4 py-3 text-gray-500 whitespace-nowrap">
                    {format(new Date(order.created_at), 'dd MMM yyyy HH:mm')}
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>
    </div>
  )
}
