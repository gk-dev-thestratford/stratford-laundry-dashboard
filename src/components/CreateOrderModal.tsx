import { useState, useEffect } from 'react'
import { X } from 'lucide-react'
import { supabase } from '../lib/supabase'
import type { Department, CatalogueItem, OrderType } from '../types'
import { ORDER_TYPE_LABELS } from '../types'

interface CreateOrderModalProps {
  departments: Department[]
  onClose: () => void
  onCreated: () => void
}

export default function CreateOrderModal({ departments, onClose, onCreated }: CreateOrderModalProps) {
  const [orderType, setOrderType] = useState<OrderType>('uniform')
  const [docketNumber, setDocketNumber] = useState('')
  const [departmentId, setDepartmentId] = useState('')
  const [staffName, setStaffName] = useState('')
  const [email, setEmail] = useState('')
  const [guestName, setGuestName] = useState('')
  const [roomNumber, setRoomNumber] = useState('')
  const [bagCount, setBagCount] = useState(1)
  const [notes, setNotes] = useState('')
  const [catalogueItems, setCatalogueItems] = useState<CatalogueItem[]>([])
  const [quantities, setQuantities] = useState<Record<string, number>>({})
  const [submitting, setSubmitting] = useState(false)
  const [error, setError] = useState('')

  const isGuestOrder = orderType === 'guest_laundry'
  const category = orderType === 'uniform' ? 'uniform' : orderType === 'hsk_linen' ? 'hsk_linen' : 'fnb_linen'

  useEffect(() => {
    if (isGuestOrder) return
    async function fetchItems() {
      const { data } = await supabase
        .from('item_catalogue')
        .select('*')
        .eq('category', category)
        .eq('is_active', true)
        .order('sort_order')
      if (data) setCatalogueItems(data)
    }
    fetchItems()
  }, [category, isGuestOrder])

  function setQuantity(itemId: string, qty: number) {
    setQuantities((prev) => ({ ...prev, [itemId]: Math.max(0, qty) }))
  }

  const selectedItems = catalogueItems.filter((item) => (quantities[item.id] || 0) > 0)
  const totalPrice = selectedItems.reduce((sum, item) => sum + (item.price || 0) * (quantities[item.id] || 0), 0)

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    setError('')
    setSubmitting(true)

    try {
      const orderData = {
        docket_number: docketNumber,
        order_type: orderType,
        department_id: departmentId || null,
        staff_name: isGuestOrder ? null : staffName,
        email: isGuestOrder ? null : email || null,
        guest_name: isGuestOrder ? guestName : null,
        room_number: isGuestOrder ? roomNumber : null,
        bag_count: isGuestOrder ? bagCount : null,
        notes: notes || null,
        status: 'submitted' as const,
        total_price: !isGuestOrder && totalPrice > 0 ? totalPrice : null,
      }

      const { data: order, error: orderError } = await supabase
        .from('orders')
        .insert(orderData)
        .select()
        .single()

      if (orderError) throw orderError

      if (!isGuestOrder && selectedItems.length > 0) {
        const itemRows = selectedItems.map((item) => ({
          order_id: order.id,
          item_id: item.id,
          item_name: item.name,
          quantity_sent: quantities[item.id],
          price_at_time: item.price,
        }))

        const { error: itemsError } = await supabase
          .from('order_items')
          .insert(itemRows)

        if (itemsError) throw itemsError
      }

      // Get current user name for status log
      let userName = 'Dashboard'
      const { data: { user: authUser } } = await supabase.auth.getUser()
      if (authUser) {
        const { data: du } = await supabase.from('dashboard_users').select('name, email').eq('id', authUser.id).single()
        userName = du?.name || du?.email || 'Dashboard'
      }

      await supabase.from('order_status_log').insert({
        order_id: order.id,
        status: 'submitted',
        changed_by_name: userName,
      })

      onCreated()
      onClose()
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : 'Failed to create order')
    } finally {
      setSubmitting(false)
    }
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
      <div className="absolute inset-0 bg-black/40" onClick={onClose} />
      <div className="relative bg-white rounded-xl shadow-2xl w-full max-w-2xl max-h-[90vh] overflow-y-auto">
        <div className="sticky top-0 bg-white border-b border-gray-200 px-6 py-4 flex items-center justify-between">
          <h2 className="text-lg font-semibold text-gray-900">Create New Order</h2>
          <button onClick={onClose} className="p-2 hover:bg-gray-100 rounded-lg">
            <X className="w-5 h-5 text-gray-500" />
          </button>
        </div>

        <form onSubmit={handleSubmit} className="p-6 space-y-5">
          {error && (
            <div className="p-3 bg-red-50 border border-red-200 rounded-lg text-sm text-red-700">{error}</div>
          )}

          {/* Order Type */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">Order Type</label>
            <div className="grid grid-cols-2 sm:grid-cols-4 gap-2">
              {(Object.entries(ORDER_TYPE_LABELS) as [OrderType, string][]).map(([key, label]) => (
                <button
                  key={key}
                  type="button"
                  onClick={() => { setOrderType(key); setQuantities({}) }}
                  className={`px-3 py-2 text-sm rounded-lg border transition-colors ${
                    orderType === key
                      ? 'bg-navy text-white border-navy'
                      : 'bg-white text-gray-700 border-gray-200 hover:bg-gray-50'
                  }`}
                >
                  {label}
                </button>
              ))}
            </div>
          </div>

          {/* Common fields */}
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Docket Number *</label>
              <input
                type="text"
                value={docketNumber}
                onChange={(e) => setDocketNumber(e.target.value)}
                required
                className="w-full px-3 py-2 text-sm border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-gold"
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Department</label>
              <select
                value={departmentId}
                onChange={(e) => setDepartmentId(e.target.value)}
                className="w-full px-3 py-2 text-sm border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-gold"
              >
                <option value="">Select department</option>
                {departments.map((d) => (
                  <option key={d.id} value={d.id}>{d.name}</option>
                ))}
              </select>
            </div>
          </div>

          {/* Type-specific fields */}
          {isGuestOrder ? (
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Guest Name *</label>
                <input
                  type="text"
                  value={guestName}
                  onChange={(e) => setGuestName(e.target.value)}
                  required
                  className="w-full px-3 py-2 text-sm border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-gold"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Room Number *</label>
                <input
                  type="text"
                  value={roomNumber}
                  onChange={(e) => setRoomNumber(e.target.value)}
                  required
                  className="w-full px-3 py-2 text-sm border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-gold"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Bag Count</label>
                <input
                  type="number"
                  min={1}
                  value={bagCount}
                  onChange={(e) => setBagCount(Number(e.target.value))}
                  className="w-full px-3 py-2 text-sm border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-gold"
                />
              </div>
            </div>
          ) : (
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Staff Name *</label>
                <input
                  type="text"
                  value={staffName}
                  onChange={(e) => setStaffName(e.target.value)}
                  required
                  className="w-full px-3 py-2 text-sm border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-gold"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Email</label>
                <input
                  type="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  className="w-full px-3 py-2 text-sm border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-gold"
                />
              </div>
            </div>
          )}

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Notes</label>
            <textarea
              value={notes}
              onChange={(e) => setNotes(e.target.value)}
              rows={2}
              className="w-full px-3 py-2 text-sm border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-gold resize-none"
            />
          </div>

          {/* Item selection (non-guest) */}
          {!isGuestOrder && catalogueItems.length > 0 && (
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Items {orderType === 'uniform' && totalPrice > 0 && (
                  <span className="text-gold font-semibold ml-2">Total: £{totalPrice.toFixed(2)}</span>
                )}
              </label>
              <div className="border border-gray-200 rounded-lg divide-y divide-gray-100 max-h-60 overflow-y-auto">
                {catalogueItems.map((item) => (
                  <div key={item.id} className="flex items-center justify-between px-4 py-2.5">
                    <div>
                      <span className="text-sm text-gray-900">{item.name}</span>
                      {item.price != null && (
                        <span className="text-xs text-gray-500 ml-2">£{item.price.toFixed(2)}</span>
                      )}
                    </div>
                    <div className="flex items-center gap-2">
                      <button
                        type="button"
                        onClick={() => setQuantity(item.id, (quantities[item.id] || 0) - 1)}
                        className="w-7 h-7 rounded-md border border-gray-200 flex items-center justify-center text-gray-600 hover:bg-gray-50"
                      >
                        -
                      </button>
                      <span className="w-8 text-center text-sm font-medium">
                        {quantities[item.id] || 0}
                      </span>
                      <button
                        type="button"
                        onClick={() => setQuantity(item.id, (quantities[item.id] || 0) + 1)}
                        className="w-7 h-7 rounded-md border border-gray-200 flex items-center justify-center text-gray-600 hover:bg-gray-50"
                      >
                        +
                      </button>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )}

          <div className="flex justify-end gap-3 pt-2">
            <button
              type="button"
              onClick={onClose}
              className="px-4 py-2 text-sm text-gray-700 bg-white border border-gray-200 rounded-lg hover:bg-gray-50"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={submitting}
              className="px-4 py-2 text-sm text-white bg-navy rounded-lg hover:bg-navy-light disabled:opacity-50"
            >
              {submitting ? 'Creating...' : 'Create Order'}
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}
