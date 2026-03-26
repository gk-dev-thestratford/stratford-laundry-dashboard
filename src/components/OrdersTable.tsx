import { format } from 'date-fns'
import StatusBadge from './StatusBadge'
import { ORDER_TYPE_LABELS } from '../types'
import type { Order, BulkEdits } from '../types'

/** Compute order cost from item-level prices (works for uniforms AND linens) */
function orderCost(o: Order, edits?: BulkEdits): number | null {
  if (o.order_items && o.order_items.length > 0) {
    const itemTotal = o.order_items.reduce((sum, i) => {
      const price = edits?.items[i.id]?.price_at_time ?? i.price_at_time ?? 0
      return sum + price * (i.quantity_sent ?? 0)
    }, 0)
    if (itemTotal > 0) return itemTotal
  }
  return o.total_price ?? null
}

interface OrdersTableProps {
  orders: Order[]
  selectedIds: Set<string>
  onToggleSelect: (id: string) => void
  onToggleAll: () => void
  onRowClick: (order: Order) => void
  bulkEdit?: boolean
  bulkEdits?: BulkEdits
  onBulkEditsChange?: (edits: BulkEdits) => void
}

const TH = 'px-4 py-3 font-medium text-gray-600 border-r border-gray-200 last:border-r-0'
const TD = 'px-4 py-3 border-r border-gray-200 last:border-r-0'

export default function OrdersTable({
  orders, selectedIds, onToggleSelect, onToggleAll, onRowClick,
  bulkEdit, bulkEdits, onBulkEditsChange,
}: OrdersTableProps) {
  function setDocket(orderId: string, value: string) {
    if (!bulkEdits || !onBulkEditsChange) return
    onBulkEditsChange({
      ...bulkEdits,
      orders: { ...bulkEdits.orders, [orderId]: { ...bulkEdits.orders[orderId], docket_number: value } },
    })
  }

  function setItemPrice(itemId: string, orderId: string, value: string) {
    if (!bulkEdits || !onBulkEditsChange) return
    const num = parseFloat(value)
    if (value !== '' && isNaN(num)) return
    onBulkEditsChange({
      ...bulkEdits,
      items: { ...bulkEdits.items, [itemId]: { price_at_time: value === '' ? 0 : num, order_id: orderId } },
    })
  }

  return (
    <div className="bg-white rounded-xl border border-gray-200 overflow-hidden">
      <div className="overflow-x-auto">
        <table className="w-full text-sm table-fixed">
          <colgroup>
            <col className="w-[44px]" />
            <col className="w-[120px]" />
            <col className="w-[120px]" />
            <col className="w-[140px]" />
            <col className="w-[150px]" />
            <col className="w-[60px]" />
            <col className="w-[110px]" />
            <col className="w-[110px]" />
            <col className="w-[110px]" />
            <col className="w-[160px]" />
          </colgroup>
          <thead>
            <tr className="border-b border-gray-300 bg-gray-50">
              <th className={`${TH} w-[44px] text-center`}>
                <input
                  type="checkbox"
                  checked={selectedIds.size === orders.length && orders.length > 0}
                  onChange={onToggleAll}
                  className="rounded border-gray-300"
                />
              </th>
              <th className={`${TH} text-left`}>Docket</th>
              <th className={`${TH} text-left`}>Type</th>
              <th className={`${TH} text-left`}>Name</th>
              <th className={`${TH} text-left`}>Department</th>
              <th className={`${TH} text-center`}>Items</th>
              <th className={`${TH} text-right`}>Total ex VAT</th>
              <th className={`${TH} text-right`}>Total inc VAT</th>
              <th className={`${TH} text-center`}>Status</th>
              <th className={`${TH} text-left !border-r-0`}>Date</th>
            </tr>
          </thead>
          <tbody>
            {orders.length === 0 ? (
              <tr>
                <td colSpan={10} className="px-4 py-12 text-center text-gray-500">
                  No orders found
                </td>
              </tr>
            ) : (
              orders.map((order) => {
                const cost = orderCost(order, bulkEdits)
                const hasDiscrepancy = (order.order_items || []).some(
                  (i) => i.quantity_received != null && i.quantity_received !== i.quantity_sent,
                )
                const docketValue = bulkEdits?.orders[order.id]?.docket_number ?? order.docket_number
                const showItemRows = bulkEdit && order.order_items && order.order_items.length > 0

                return (
                  <>
                    {/* Main order row */}
                    <tr
                      key={order.id}
                      onClick={() => !bulkEdit && onRowClick(order)}
                      className={`border-b border-gray-200 transition-colors ${
                        bulkEdit
                          ? hasDiscrepancy ? 'bg-amber-50' : ''
                          : 'hover:bg-gray-50 cursor-pointer'
                      }`}
                    >
                      <td className={`${TD} text-center`} onClick={(e) => e.stopPropagation()}>
                        <input
                          type="checkbox"
                          checked={selectedIds.has(order.id)}
                          onChange={() => onToggleSelect(order.id)}
                          className="rounded border-gray-300"
                        />
                      </td>
                      <td className={`${TD} font-mono font-medium text-navy truncate`}>
                        {bulkEdit ? (
                          <input
                            type="text"
                            value={docketValue}
                            onChange={(e) => setDocket(order.id, e.target.value)}
                            className="w-full px-2 py-1 text-sm font-mono border border-gray-300 rounded focus:outline-none focus:ring-2 focus:ring-gold"
                            onClick={(e) => e.stopPropagation()}
                          />
                        ) : (
                          order.docket_number
                        )}
                      </td>
                      <td className={`${TD} text-gray-600 truncate`}>
                        {ORDER_TYPE_LABELS[order.order_type]}
                      </td>
                      <td className={`${TD} text-gray-900 truncate`}>
                        {order.staff_name || order.guest_name || '\u2014'}
                      </td>
                      <td className={`${TD} text-gray-600 truncate`}>
                        {order.department?.name || '\u2014'}
                      </td>
                      <td className={`${TD} text-center text-gray-600`}>
                        {order.order_items?.length || 0}
                      </td>
                      <td className={`${TD} text-right text-gray-900 font-medium`}>
                        {cost != null ? `\u00a3${cost.toFixed(2)}` : '\u2014'}
                      </td>
                      <td className={`${TD} text-right text-gray-900 font-medium`}>
                        {cost != null ? `\u00a3${(cost * 1.2).toFixed(2)}` : '\u2014'}
                      </td>
                      <td className={`${TD} text-center`}>
                        <StatusBadge status={order.status} />
                      </td>
                      <td className={`${TD} text-gray-500 whitespace-nowrap !border-r-0`}>
                        {format(new Date(order.created_at), 'dd MMM yyyy HH:mm')}
                      </td>
                    </tr>

                    {/* Expanded item rows in bulk edit mode */}
                    {showItemRows && order.order_items!.map((item) => {
                      const editedPrice = bulkEdits?.items[item.id]?.price_at_time
                      const priceVal = editedPrice ?? item.price_at_time ?? 0
                      const lineTotal = priceVal * (item.quantity_sent ?? 0)
                      const qtyMismatch = item.quantity_received != null && item.quantity_received !== item.quantity_sent

                      return (
                        <tr
                          key={item.id}
                          className={`border-b border-gray-100 ${qtyMismatch ? 'bg-red-50' : 'bg-gray-50/50'}`}
                        >
                          <td className={TD} />
                          <td className={TD} />
                          <td colSpan={2} className={`${TD} text-xs text-gray-700 pl-8`}>
                            {item.item_name}
                          </td>
                          <td className={`${TD} text-xs text-gray-500`}>
                            Sent: {item.quantity_sent}
                            {item.quantity_received != null && (
                              <span className={qtyMismatch ? ' text-red-600 font-semibold' : ''}>
                                {' '} Rcvd: {item.quantity_received}
                              </span>
                            )}
                          </td>
                          <td className={TD} />
                          <td className={`${TD} text-right`}>
                            <div className="flex items-center justify-end gap-1">
                              <span className="text-xs text-gray-400">&pound;</span>
                              <input
                                type="number"
                                step="0.01"
                                min="0"
                                value={editedPrice !== undefined ? editedPrice : (item.price_at_time ?? '')}
                                onChange={(e) => setItemPrice(item.id, order.id, e.target.value)}
                                className={`w-20 px-2 py-0.5 text-xs text-right border rounded focus:outline-none focus:ring-2 focus:ring-gold ${
                                  editedPrice !== undefined && editedPrice !== item.price_at_time
                                    ? 'border-gold bg-gold/10'
                                    : 'border-gray-300'
                                }`}
                              />
                            </div>
                          </td>
                          <td className={`${TD} text-right text-xs text-gray-600`}>
                            {lineTotal > 0 ? `\u00a3${(lineTotal * 1.2).toFixed(2)}` : '\u2014'}
                          </td>
                          <td colSpan={2} className={`${TD} !border-r-0`}>
                            {qtyMismatch && (
                              <span className="text-xs text-red-600 font-medium">
                                Discrepancy: {(item.quantity_received ?? 0) - item.quantity_sent}
                              </span>
                            )}
                          </td>
                        </tr>
                      )
                    })}
                  </>
                )
              })
            )}
          </tbody>
        </table>
      </div>
    </div>
  )
}
