import { useState, useCallback } from 'react'
import { Plus, Download, Trash2, RefreshCw } from 'lucide-react'
import { useOrders } from '../hooks/useOrders'
import Filters from '../components/Filters'
import OrdersTable from '../components/OrdersTable'
import OrderDetail from '../components/OrderDetail'
import CreateOrderModal from '../components/CreateOrderModal'
import type { Order, OrderStatus } from '../types'
import { ORDER_STATUS_LABELS } from '../types'
import { utils, writeFile } from 'xlsx'
import { format } from 'date-fns'

export default function Orders() {
  const { orders, departments, loading, filters, setFilters, fetchOrders, updateOrderStatus, updateOrder, updateOrderItem, deleteOrders } = useOrders()
  const [selectedIds, setSelectedIds] = useState<Set<string>>(new Set())
  const [detailOrder, setDetailOrder] = useState<Order | null>(null)
  const [showCreate, setShowCreate] = useState(false)
  const [bulkStatus, setBulkStatus] = useState<OrderStatus | ''>('')

  function toggleSelect(id: string) {
    setSelectedIds((prev) => {
      const next = new Set(prev)
      if (next.has(id)) next.delete(id)
      else next.add(id)
      return next
    })
  }

  function toggleAll() {
    if (selectedIds.size === orders.length) setSelectedIds(new Set())
    else setSelectedIds(new Set(orders.map((o) => o.id)))
  }

  async function handleBulkDelete() {
    if (selectedIds.size === 0) return
    if (!window.confirm(`Delete ${selectedIds.size} order(s)? This cannot be undone.`)) return
    await deleteOrders(Array.from(selectedIds))
    setSelectedIds(new Set())
  }

  async function handleBulkStatus() {
    if (!bulkStatus || selectedIds.size === 0) return
    if (!window.confirm(`Update ${selectedIds.size} order(s) to "${ORDER_STATUS_LABELS[bulkStatus]}"?`)) return
    for (const id of selectedIds) {
      await updateOrderStatus(id, bulkStatus)
    }
    setSelectedIds(new Set())
    setBulkStatus('')
  }

  const exportExcel = useCallback(() => {
    const rows = orders.map((o) => ({
      'Docket': o.docket_number,
      'Type': o.order_type,
      'Status': o.status,
      'Staff Name': o.staff_name || '',
      'Guest Name': o.guest_name || '',
      'Department': o.department?.name || '',
      'Room': o.room_number || '',
      'Bags': o.bag_count ?? '',
      'Items': o.order_items?.length || 0,
      'Total (£)': o.total_price ?? '',
      'Notes': o.notes || '',
      'Created': format(new Date(o.created_at), 'dd/MM/yyyy HH:mm'),
    }))
    const ws = utils.json_to_sheet(rows)
    const wb = utils.book_new()
    utils.book_append_sheet(wb, ws, 'Orders')
    writeFile(wb, `stratford-orders-${format(new Date(), 'yyyy-MM-dd')}.xlsx`)
  }, [orders])

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-2xl font-semibold text-gray-900">Orders</h1>
          <p className="text-sm text-gray-500 mt-1">
            {orders.length} order{orders.length !== 1 ? 's' : ''} found
          </p>
        </div>
        <div className="flex items-center gap-2">
          <button
            onClick={() => fetchOrders()}
            className="p-2 text-gray-600 hover:bg-gray-100 rounded-lg transition-colors"
            title="Refresh"
          >
            <RefreshCw className={`w-4 h-4 ${loading ? 'animate-spin' : ''}`} />
          </button>
          <button
            onClick={exportExcel}
            className="flex items-center gap-2 px-3 py-2 text-sm text-gray-700 bg-white border border-gray-200 rounded-lg hover:bg-gray-50"
          >
            <Download className="w-4 h-4" />
            Export
          </button>
          <button
            onClick={() => setShowCreate(true)}
            className="flex items-center gap-2 px-4 py-2 text-sm text-white bg-navy rounded-lg hover:bg-navy-light"
          >
            <Plus className="w-4 h-4" />
            New Order
          </button>
        </div>
      </div>

      {/* Filters */}
      <Filters filters={filters} departments={departments} onChange={setFilters} />

      {/* Bulk actions */}
      {selectedIds.size > 0 && (
        <div className="flex items-center gap-3 bg-navy/5 border border-navy/10 rounded-lg px-4 py-3">
          <span className="text-sm font-medium text-navy">{selectedIds.size} selected</span>
          <div className="h-4 w-px bg-gray-300" />
          <select
            value={bulkStatus}
            onChange={(e) => setBulkStatus(e.target.value as OrderStatus)}
            className="px-2 py-1 text-sm border border-gray-200 rounded-lg bg-white"
          >
            <option value="">Change status...</option>
            {Object.entries(ORDER_STATUS_LABELS).map(([key, label]) => (
              <option key={key} value={key}>{label}</option>
            ))}
          </select>
          {bulkStatus && (
            <button
              onClick={handleBulkStatus}
              className="px-3 py-1 text-sm bg-navy text-white rounded-lg hover:bg-navy-light"
            >
              Apply
            </button>
          )}
          <button
            onClick={handleBulkDelete}
            className="flex items-center gap-1 px-3 py-1 text-sm text-red-700 bg-red-50 border border-red-200 rounded-lg hover:bg-red-100"
          >
            <Trash2 className="w-3.5 h-3.5" />
            Delete
          </button>
          <button
            onClick={() => setSelectedIds(new Set())}
            className="text-sm text-gray-500 hover:text-gray-700 ml-auto"
          >
            Clear
          </button>
        </div>
      )}

      {/* Table */}
      {loading ? (
        <div className="flex items-center justify-center py-20">
          <RefreshCw className="w-6 h-6 text-gray-400 animate-spin" />
        </div>
      ) : (
        <OrdersTable
          orders={orders}
          selectedIds={selectedIds}
          onToggleSelect={toggleSelect}
          onToggleAll={toggleAll}
          onRowClick={setDetailOrder}
        />
      )}

      {/* Slide-out detail */}
      {detailOrder && (
        <OrderDetail
          order={detailOrder}
          departments={departments}
          onClose={() => setDetailOrder(null)}
          onStatusChange={(id, status, reason) => {
            updateOrderStatus(id, status, reason)
            setDetailOrder(null)
          }}
          onSave={updateOrder}
          onSaveItem={updateOrderItem}
        />
      )}

      {/* Create modal */}
      {showCreate && (
        <CreateOrderModal
          departments={departments}
          onClose={() => setShowCreate(false)}
          onCreated={fetchOrders}
        />
      )}
    </div>
  )
}
