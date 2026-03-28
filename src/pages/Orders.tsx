import { useState, useCallback } from 'react'
import { Plus, Download, Trash2, RefreshCw, Pencil, Save, X, FileSpreadsheet, Mail, CheckCircle } from 'lucide-react'
import { useOrders } from '../hooks/useOrders'
import Filters from '../components/Filters'
import OrdersTable from '../components/OrdersTable'
import OrderDetail from '../components/OrderDetail'
import CreateOrderModal from '../components/CreateOrderModal'
import type { Order, OrderStatus, BulkEdits } from '../types'
import { ORDER_STATUS_LABELS, ORDER_TYPE_LABELS } from '../types'
import { utils, writeFile } from 'xlsx'
import { format } from 'date-fns'

const EMPTY_EDITS: BulkEdits = { orders: {}, items: {} }

function computeCost(o: Order): number {
  if (o.order_items && o.order_items.length > 0) {
    const t = o.order_items.reduce((s, i) => s + (i.price_at_time ?? 0) * (i.quantity_sent ?? 0), 0)
    if (t > 0) return t
  }
  return o.total_price ?? 0
}

export default function Orders() {
  const { orders, departments, loading, filters, setFilters, fetchOrders, updateOrderStatus, updateOrder, updateOrderItem, deleteOrders, bulkSaveEdits, bulkUpdateStatus } = useOrders()
  const [selectedIds, setSelectedIds] = useState<Set<string>>(new Set())
  const [detailOrder, setDetailOrder] = useState<Order | null>(null)
  const [showCreate, setShowCreate] = useState(false)
  const [bulkStatus, setBulkStatus] = useState<OrderStatus | ''>('')

  // Bulk edit state
  const [bulkEdit, setBulkEdit] = useState(false)
  const [bulkEdits, setBulkEdits] = useState<BulkEdits>(EMPTY_EDITS)
  const [saving, setSaving] = useState(false)

  // Bulk status progress
  const [bulkProgress, setBulkProgress] = useState<{ done: number; total: number } | null>(null)

  // Email outstanding modal
  const [showEmailModal, setShowEmailModal] = useState(false)
  const [emailTo, setEmailTo] = useState('')
  const [emailSending, setEmailSending] = useState(false)
  const [emailSent, setEmailSent] = useState(false)

  const editCount = Object.keys(bulkEdits.orders).length + Object.keys(bulkEdits.items).length

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

  function enterBulkEdit() {
    setBulkEdit(true)
    setBulkEdits(EMPTY_EDITS)
  }

  function cancelBulkEdit() {
    setBulkEdit(false)
    setBulkEdits(EMPTY_EDITS)
  }

  async function saveBulkEdits() {
    if (editCount === 0) return
    setSaving(true)
    setBulkProgress({ done: 0, total: editCount })
    await bulkSaveEdits(bulkEdits, (done, total) => setBulkProgress({ done, total }))
    setBulkProgress(null)
    setBulkEdits(EMPTY_EDITS)
    setBulkEdit(false)
    setSaving(false)
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
    setBulkProgress({ done: 0, total: selectedIds.size })
    await bulkUpdateStatus(
      Array.from(selectedIds),
      bulkStatus,
      (done, total) => setBulkProgress({ done, total }),
    )
    setBulkProgress(null)
    setSelectedIds(new Set())
    setBulkStatus('')
  }

  // ── Email outstanding items ──
  function getOutstandingEmailData() {
    const selected = orders.filter(o => selectedIds.has(o.id))
    const rows: Array<{ docket: string; department: string; item: string; sent: number; received: number; outstanding: number }> = []
    selected.forEach(o => {
      (o.order_items || []).forEach(i => {
        const out = (i.quantity_sent || 0) - (i.quantity_received ?? 0)
        if (out > 0) {
          rows.push({
            docket: o.docket_number,
            department: o.department?.name || '—',
            item: i.item_name,
            sent: i.quantity_sent,
            received: i.quantity_received ?? 0,
            outstanding: out,
          })
        }
      })
    })
    return rows
  }

  function handleSendEmail() {
    if (!emailTo.trim()) return
    const rows = getOutstandingEmailData()
    if (rows.length === 0) return

    setEmailSending(true)

    const subject = `Outstanding Laundry Items — ${rows.reduce((s, r) => s + r.outstanding, 0)} item(s) requiring investigation`
    const body = [
      'Dear Team,',
      '',
      'Please find below a list of outstanding laundry items that require investigation:',
      '',
      ...rows.map(r =>
        `• Docket: ${r.docket} | Dept: ${r.department} | Item: ${r.item} | Sent: ${r.sent} | Received: ${r.received} | Outstanding: ${r.outstanding}`
      ),
      '',
      `Total outstanding items: ${rows.reduce((s, r) => s + r.outstanding, 0)}`,
      `Across ${new Set(rows.map(r => r.docket)).size} order(s)`,
      '',
      'Please investigate and advise on the status of these items.',
      '',
      'Kind regards,',
      'The Stratford Laundry Team',
    ].join('\n')

    window.location.href = `mailto:${encodeURIComponent(emailTo)}?subject=${encodeURIComponent(subject)}&body=${encodeURIComponent(body)}`

    setEmailSending(false)
    setEmailSent(true)
    setTimeout(() => {
      setShowEmailModal(false)
      setEmailSent(false)
      setEmailTo('')
    }, 2000)
  }

  // ── Standard export (all filtered orders) ──
  const exportExcel = useCallback(() => {
    const source = selectedIds.size > 0 ? orders.filter((o) => selectedIds.has(o.id)) : orders

    const rows = source.map((o) => {
      const cost = computeCost(o)
      return {
        'Docket': o.docket_number,
        'Type': ORDER_TYPE_LABELS[o.order_type] || o.order_type,
        'Status': ORDER_STATUS_LABELS[o.status as OrderStatus] || o.status,
        'Staff Name': o.staff_name || '',
        'Guest Name': o.guest_name || '',
        'Department': o.department?.name || '',
        'Room': o.room_number || '',
        'Bags': o.bag_count ?? '',
        'Items': o.order_items?.length || 0,
        'Total ex VAT (\u00a3)': cost > 0 ? Number(cost.toFixed(2)) : '',
        'Total inc VAT (\u00a3)': cost > 0 ? Number((cost * 1.2).toFixed(2)) : '',
        'Notes': o.notes || '',
        'Created': format(new Date(o.created_at), 'dd/MM/yyyy HH:mm'),
      }
    })
    const ws = utils.json_to_sheet(rows)
    const wb = utils.book_new()
    utils.book_append_sheet(wb, ws, 'Orders')
    const suffix = selectedIds.size > 0 ? `-selected-${selectedIds.size}` : ''
    writeFile(wb, `stratford-orders-${format(new Date(), 'yyyy-MM-dd')}${suffix}.xlsx`)
  }, [orders, selectedIds])

  // ── Smart Export: separate sheet per department for accounts ──
  const exportForAccounts = useCallback(() => {
    const source = selectedIds.size > 0 ? orders.filter((o) => selectedIds.has(o.id)) : orders
    if (source.length === 0) return

    const wb = utils.book_new()

    // Group orders by department
    const byDept = new Map<string, Order[]>()
    source.forEach((o) => {
      const deptName = o.department?.name || 'No Department'
      if (!byDept.has(deptName)) byDept.set(deptName, [])
      byDept.get(deptName)!.push(o)
    })

    // Summary sheet first
    const summaryRows: Record<string, string | number>[] = []
    let grandTotalEx = 0
    let grandTotalInc = 0

    for (const [dept, deptOrders] of byDept) {
      let deptCostEx = 0
      let deptItems = 0
      let deptOutstanding = 0

      deptOrders.forEach((o) => {
        deptCostEx += computeCost(o)
        ;(o.order_items || []).forEach((i) => {
          deptItems += i.quantity_sent ?? 0
          const outstanding = (i.quantity_sent ?? 0) - (i.quantity_received ?? 0)
          if (outstanding > 0) deptOutstanding += outstanding
        })
      })

      grandTotalEx += deptCostEx
      grandTotalInc += deptCostEx * 1.2

      summaryRows.push({
        'Department': dept,
        'Orders': deptOrders.length,
        'Total Items': deptItems,
        'Outstanding Items': deptOutstanding,
        'Total ex VAT (\u00a3)': Number(deptCostEx.toFixed(2)),
        'VAT (\u00a3)': Number((deptCostEx * 0.2).toFixed(2)),
        'Total inc VAT (\u00a3)': Number((deptCostEx * 1.2).toFixed(2)),
      })
    }

    summaryRows.push({
      'Department': 'GRAND TOTAL',
      'Orders': source.length,
      'Total Items': source.reduce((s, o) => s + (o.order_items || []).reduce((s2, i) => s2 + (i.quantity_sent ?? 0), 0), 0),
      'Outstanding Items': source.reduce((s, o) => s + (o.order_items || []).reduce((s2, i) => {
        const out = (i.quantity_sent ?? 0) - (i.quantity_received ?? 0)
        return s2 + (out > 0 ? out : 0)
      }, 0), 0),
      'Total ex VAT (\u00a3)': Number(grandTotalEx.toFixed(2)),
      'VAT (\u00a3)': Number((grandTotalEx * 0.2).toFixed(2)),
      'Total inc VAT (\u00a3)': Number(grandTotalInc.toFixed(2)),
    })

    utils.book_append_sheet(wb, utils.json_to_sheet(summaryRows), 'Summary')

    // Per-department sheets with item-level detail
    for (const [dept, deptOrders] of byDept) {
      const rows: Record<string, string | number>[] = []

      deptOrders.forEach((o) => {
        const items = o.order_items || []
        if (items.length === 0) {
          // Order with no items (e.g. guest laundry)
          rows.push({
            'Docket': o.docket_number,
            'Type': ORDER_TYPE_LABELS[o.order_type] || o.order_type,
            'Name': o.staff_name || o.guest_name || '',
            'Status': ORDER_STATUS_LABELS[o.status as OrderStatus] || o.status,
            'Item': '',
            'Qty Sent': '',
            'Qty Received': '',
            'Outstanding': '',
            'Unit Price (\u00a3)': '',
            'Line Total ex VAT (\u00a3)': '',
            'Line Total inc VAT (\u00a3)': '',
            'Date': format(new Date(o.created_at), 'dd/MM/yyyy'),
          })
        } else {
          items.forEach((item, idx) => {
            const price = item.price_at_time ?? 0
            const lineEx = price * (item.quantity_sent ?? 0)
            const outstanding = (item.quantity_sent ?? 0) - (item.quantity_received ?? 0)
            rows.push({
              'Docket': idx === 0 ? o.docket_number : '',
              'Type': idx === 0 ? (ORDER_TYPE_LABELS[o.order_type] || o.order_type) : '',
              'Name': idx === 0 ? (o.staff_name || o.guest_name || '') : '',
              'Status': idx === 0 ? (ORDER_STATUS_LABELS[o.status as OrderStatus] || o.status) : '',
              'Item': item.item_name,
              'Qty Sent': item.quantity_sent,
              'Qty Received': item.quantity_received ?? '',
              'Outstanding': outstanding > 0 ? outstanding : '',
              'Unit Price (\u00a3)': price > 0 ? Number(price.toFixed(2)) : '',
              'Line Total ex VAT (\u00a3)': lineEx > 0 ? Number(lineEx.toFixed(2)) : '',
              'Line Total inc VAT (\u00a3)': lineEx > 0 ? Number((lineEx * 1.2).toFixed(2)) : '',
              'Date': idx === 0 ? format(new Date(o.created_at), 'dd/MM/yyyy') : '',
            })
          })
        }
      })

      // Department totals row
      const deptCost = deptOrders.reduce((s, o) => s + computeCost(o), 0)
      rows.push({
        'Docket': '', 'Type': '', 'Name': '', 'Status': 'TOTAL',
        'Item': '', 'Qty Sent': '', 'Qty Received': '', 'Outstanding': '',
        'Unit Price (\u00a3)': '',
        'Line Total ex VAT (\u00a3)': Number(deptCost.toFixed(2)),
        'Line Total inc VAT (\u00a3)': Number((deptCost * 1.2).toFixed(2)),
        'Date': '',
      })

      // Sheet name max 31 chars
      const sheetName = dept.length > 31 ? dept.substring(0, 31) : dept
      utils.book_append_sheet(wb, utils.json_to_sheet(rows), sheetName)
    }

    const monthLabel = filters.month > 0
      ? `-${String(filters.month).padStart(2, '0')}`
      : ''
    writeFile(wb, `stratford-accounts-${filters.year}${monthLabel}.xlsx`)
  }, [orders, selectedIds, filters])

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-2xl font-semibold text-gray-900">Orders</h1>
          <p className="text-sm text-gray-500 mt-1">
            {orders.length} order{orders.length !== 1 ? 's' : ''} found
            {selectedIds.size > 0 && ` \u2022 ${selectedIds.size} selected`}
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

          {!bulkEdit ? (
            <>
              <button
                onClick={enterBulkEdit}
                className="flex items-center gap-2 px-3 py-2 text-sm text-navy bg-navy/5 border border-navy/10 rounded-lg hover:bg-navy/10"
                title="Edit prices & docket numbers inline"
              >
                <Pencil className="w-4 h-4" />
                Bulk Edit
              </button>
              <button
                onClick={exportExcel}
                className="flex items-center gap-2 px-3 py-2 text-sm text-gray-700 bg-white border border-gray-200 rounded-lg hover:bg-gray-50"
              >
                <Download className="w-4 h-4" />
                Export
              </button>
              <button
                onClick={exportForAccounts}
                className="flex items-center gap-2 px-3 py-2 text-sm text-white bg-gold rounded-lg hover:bg-gold/90"
                title="Export with separate sheets per department"
              >
                <FileSpreadsheet className="w-4 h-4" />
                Export for Accounts
              </button>
              <button
                onClick={() => setShowCreate(true)}
                className="flex items-center gap-2 px-4 py-2 text-sm text-white bg-navy rounded-lg hover:bg-navy-light"
              >
                <Plus className="w-4 h-4" />
                New Order
              </button>
            </>
          ) : (
            <>
              <button
                onClick={cancelBulkEdit}
                className="flex items-center gap-2 px-3 py-2 text-sm text-gray-600 bg-gray-100 rounded-lg hover:bg-gray-200"
              >
                <X className="w-4 h-4" />
                Cancel
              </button>
              <button
                onClick={saveBulkEdits}
                disabled={saving || editCount === 0}
                className="flex items-center gap-2 px-4 py-2 text-sm text-white bg-navy rounded-lg hover:bg-navy-light disabled:opacity-50"
              >
                <Save className="w-4 h-4" />
                {saving ? 'Saving...' : `Save All${editCount > 0 ? ` (${editCount})` : ''}`}
              </button>
            </>
          )}
        </div>
      </div>

      {/* Bulk edit banner */}
      {bulkEdit && (
        <div className="flex items-center gap-3 bg-gold/10 border border-gold/30 rounded-lg px-4 py-3">
          <Pencil className="w-4 h-4 text-gold flex-shrink-0" />
          <p className="text-sm text-gray-700">
            <span className="font-medium">Bulk Edit Mode</span> \u2014 Edit docket numbers and item prices inline. Changed fields are highlighted.
            {editCount > 0 && <span className="ml-2 text-gold font-semibold">{editCount} change{editCount !== 1 ? 's' : ''} pending</span>}
          </p>
        </div>
      )}

      {/* Filters */}
      <Filters filters={filters} departments={departments} onChange={setFilters} />

      {/* Bulk progress bar */}
      {bulkProgress && (
        <div className="bg-navy/5 border border-navy/10 rounded-lg px-4 py-3">
          <div className="flex items-center justify-between mb-2">
            <span className="text-sm font-medium text-navy">
              {saving ? 'Saving changes' : 'Updating orders'}... {bulkProgress.done} of {bulkProgress.total}
            </span>
            <span className="text-xs text-gray-500">
              {Math.round((bulkProgress.done / bulkProgress.total) * 100)}%
            </span>
          </div>
          <div className="w-full bg-gray-200 rounded-full h-2">
            <div
              className="bg-navy h-2 rounded-full transition-all duration-300"
              style={{ width: `${(bulkProgress.done / bulkProgress.total) * 100}%` }}
            />
          </div>
        </div>
      )}

      {/* Bulk actions (when not in bulk edit) */}
      {!bulkEdit && !bulkProgress && selectedIds.size > 0 && (
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
            onClick={() => { setShowEmailModal(true); setEmailSent(false); setEmailTo('') }}
            className="flex items-center gap-1 px-3 py-1 text-sm text-navy bg-navy/10 border border-navy/20 rounded-lg hover:bg-navy/20"
          >
            <Mail className="w-3.5 h-3.5" />
            Email Outstanding
          </button>
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
          bulkEdit={bulkEdit}
          bulkEdits={bulkEdits}
          onBulkEditsChange={setBulkEdits}
        />
      )}

      {/* Slide-out detail */}
      {detailOrder && !bulkEdit && (
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

      {/* Email Outstanding modal */}
      {showEmailModal && (
        <div className="fixed inset-0 bg-black/40 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-2xl shadow-xl w-full max-w-lg overflow-hidden">
            <div className="px-6 py-4 border-b border-gray-100 flex items-center justify-between">
              <div className="flex items-center gap-2">
                <Mail className="w-5 h-5 text-navy" />
                <h3 className="font-semibold text-gray-900">Email Outstanding Items</h3>
              </div>
              <button onClick={() => setShowEmailModal(false)} className="p-1 hover:bg-gray-100 rounded-lg">
                <X className="w-4 h-4 text-gray-500" />
              </button>
            </div>

            {emailSent ? (
              <div className="px-6 py-12 text-center">
                <CheckCircle className="w-12 h-12 text-green-500 mx-auto mb-3" />
                <p className="text-lg font-semibold text-gray-900">Email client opened</p>
                <p className="text-sm text-gray-500 mt-1">Review and send the email from your mail app</p>
              </div>
            ) : (
              <>
                <div className="px-6 py-4 space-y-4">
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">Recipient email</label>
                    <input
                      type="email"
                      value={emailTo}
                      onChange={e => setEmailTo(e.target.value)}
                      placeholder="e.g. laundry@supplier.com"
                      className="w-full px-3 py-2 text-sm border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-navy/30 focus:border-navy"
                    />
                  </div>

                  {/* Preview */}
                  <div>
                    <p className="text-sm font-medium text-gray-700 mb-1">Items to include</p>
                    <div className="bg-gray-50 rounded-lg border border-gray-200 max-h-48 overflow-y-auto">
                      {(() => {
                        const rows = getOutstandingEmailData()
                        if (rows.length === 0) return (
                          <p className="px-4 py-6 text-center text-sm text-gray-400">No outstanding items in selected orders</p>
                        )
                        return (
                          <table className="w-full text-xs">
                            <thead>
                              <tr className="border-b border-gray-200 bg-gray-100 sticky top-0">
                                <th className="px-3 py-1.5 text-left font-medium text-gray-600">Docket</th>
                                <th className="px-3 py-1.5 text-left font-medium text-gray-600">Dept</th>
                                <th className="px-3 py-1.5 text-left font-medium text-gray-600">Item</th>
                                <th className="px-3 py-1.5 text-right font-medium text-gray-600">Sent</th>
                                <th className="px-3 py-1.5 text-right font-medium text-gray-600">Rcvd</th>
                                <th className="px-3 py-1.5 text-right font-medium text-amber-600">Out</th>
                              </tr>
                            </thead>
                            <tbody>
                              {rows.map((r, i) => (
                                <tr key={i} className="border-b border-gray-100">
                                  <td className="px-3 py-1.5 font-mono">{r.docket}</td>
                                  <td className="px-3 py-1.5">{r.department}</td>
                                  <td className="px-3 py-1.5">{r.item}</td>
                                  <td className="px-3 py-1.5 text-right">{r.sent}</td>
                                  <td className="px-3 py-1.5 text-right">{r.received}</td>
                                  <td className="px-3 py-1.5 text-right font-semibold text-amber-600">{r.outstanding}</td>
                                </tr>
                              ))}
                            </tbody>
                          </table>
                        )
                      })()}
                    </div>
                    <p className="text-[11px] text-gray-400 mt-1">
                      {getOutstandingEmailData().reduce((s, r) => s + r.outstanding, 0)} outstanding items across {new Set(getOutstandingEmailData().map(r => r.docket)).size} orders
                    </p>
                  </div>
                </div>


                <div className="px-6 py-3 border-t border-gray-100 flex items-center justify-end gap-2">
                  <button
                    onClick={() => setShowEmailModal(false)}
                    className="px-4 py-2 text-sm text-gray-600 hover:bg-gray-100 rounded-lg"
                  >
                    Cancel
                  </button>
                  <button
                    onClick={handleSendEmail}
                    disabled={!emailTo.trim() || getOutstandingEmailData().length === 0 || emailSending}
                    className="flex items-center gap-2 px-4 py-2 text-sm font-medium text-white bg-navy rounded-lg hover:bg-navy-light disabled:opacity-50 disabled:cursor-not-allowed"
                  >
                    <Mail className="w-4 h-4" />
                    {emailSending ? 'Sending...' : 'Send Email'}
                  </button>
                </div>
              </>
            )}
          </div>
        </div>
      )}
    </div>
  )
}
