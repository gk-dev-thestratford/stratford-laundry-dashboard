import { useState, useEffect, useCallback } from 'react'
import { supabase } from '../lib/supabase'
import type { Order, Department, OrderStatus, OrderType, BulkEdits } from '../types'

export interface Filters {
  status: OrderStatus | 'all'
  department: string
  month: number // 0 = all, 1-12 = Jan-Dec
  year: number  // e.g. 2026
  search: string
  orderType: OrderType | 'all'
  outstanding: boolean // true = only show orders with outstanding items
  quickDate: '' | 'sent_today' | 'modified_today' | 'received_today'
  dateFrom: string // ISO date, e.g. '2026-03-01'
  dateTo: string   // ISO date, e.g. '2026-03-31'
  dateField: 'created' | 'modified'
}

async function getDashboardUserName(): Promise<string> {
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) return 'Dashboard'
  const { data } = await supabase.from('dashboard_users').select('name, email').eq('id', user.id).single()
  const name = data?.name || data?.email || 'Unknown'
  return `Dashboard / ${name}`
}

export function useOrders() {
  const [orders, setOrders] = useState<Order[]>([])
  const [departments, setDepartments] = useState<Department[]>([])
  const [loading, setLoading] = useState(true)
  const [filters, setFilters] = useState<Filters>({
    status: 'all',
    department: 'all',
    month: new Date().getMonth() + 1,
    year: new Date().getFullYear(),
    search: '',
    orderType: 'all',
    outstanding: false,
    quickDate: '',
    dateFrom: '',
    dateTo: '',
    dateField: 'created',
  })

  const fetchDepartments = useCallback(async () => {
    const { data } = await supabase
      .from('departments')
      .select('*')
      .eq('is_active', true)
      .order('name')
    if (data) setDepartments(data)
  }, [])

  const fetchOrders = useCallback(async () => {
    setLoading(true)
    let query = supabase
      .from('orders')
      .select(`
        *,
        department:departments(*),
        order_items(*),
        status_log:order_status_log(*)
      `)
      .order('created_at', { ascending: false })

    if (filters.status !== 'all') {
      query = query.eq('status', filters.status)
    }
    if (filters.department !== 'all') {
      query = query.eq('department_id', filters.department)
    }
    if (filters.orderType !== 'all') {
      query = query.eq('order_type', filters.orderType)
    }

    // Year + month filtering
    if (filters.month > 0) {
      const startDate = new Date(filters.year, filters.month - 1, 1).toISOString()
      const endDate = new Date(filters.year, filters.month, 1).toISOString()
      query = query.gte('created_at', startDate).lt('created_at', endDate)
    } else {
      // Year only
      const startDate = new Date(filters.year, 0, 1).toISOString()
      const endDate = new Date(filters.year + 1, 0, 1).toISOString()
      query = query.gte('created_at', startDate).lt('created_at', endDate)
    }

    const { data } = await query
    let results = data ?? []

    if (filters.search) {
      const s = filters.search.toLowerCase()
      results = results.filter(
        (o) =>
          o.docket_number.toLowerCase().includes(s) ||
          o.staff_name?.toLowerCase().includes(s) ||
          o.guest_name?.toLowerCase().includes(s) ||
          o.room_number?.toLowerCase().includes(s) ||
          o.department?.name?.toLowerCase().includes(s) ||
          (o.total_price != null && o.total_price.toFixed(2).includes(s)) ||
          (o.order_items || []).some((i: { item_name: string }) => i.item_name.toLowerCase().includes(s))
      )
    }

    if (filters.outstanding) {
      results = results.filter((o) =>
        (o.order_items || []).some(
          (i: any) => i.quantity_sent > (i.quantity_received ?? 0)
        )
      )
    }

    // Quick date filters (client-side — checks status_log timestamps)
    if (filters.quickDate) {
      const todayStart = new Date(); todayStart.setHours(0, 0, 0, 0)
      const todayEnd = new Date(); todayEnd.setHours(23, 59, 59, 999)
      if (filters.quickDate === 'sent_today') {
        results = results.filter(o => {
          const d = new Date(o.created_at)
          return d >= todayStart && d <= todayEnd
        })
      } else if (filters.quickDate === 'modified_today') {
        results = results.filter(o => {
          const logs = o.status_log || []
          return logs.some(l => { const d = new Date(l.created_at); return d >= todayStart && d <= todayEnd })
        })
      } else if (filters.quickDate === 'received_today') {
        results = results.filter(o => {
          const logs = o.status_log || []
          return logs.some(l => l.status === 'received' && (() => { const d = new Date(l.created_at); return d >= todayStart && d <= todayEnd })())
        })
      }
    }

    // Custom date range filter (client-side for 'modified', server already handled 'created')
    if (filters.dateFrom && filters.dateTo) {
      const from = new Date(filters.dateFrom); from.setHours(0, 0, 0, 0)
      const to = new Date(filters.dateTo); to.setHours(23, 59, 59, 999)
      if (filters.dateField === 'modified') {
        results = results.filter(o => {
          const logs = o.status_log || []
          if (logs.length === 0) return false
          const latest = logs.reduce((best, l) => new Date(l.created_at) > new Date(best.created_at) ? l : best)
          const d = new Date(latest.created_at)
          return d >= from && d <= to
        })
      } else {
        results = results.filter(o => {
          const d = new Date(o.created_at)
          return d >= from && d <= to
        })
      }
    }

    setOrders(results)
    setLoading(false)
  }, [filters])

  useEffect(() => {
    fetchDepartments()
  }, [fetchDepartments])

  useEffect(() => {
    fetchOrders()
  }, [fetchOrders])

  const updateOrderStatus = useCallback(async (orderId: string, status: OrderStatus, reason?: string) => {
    const { error } = await supabase
      .from('orders')
      .update({ status })
      .eq('id', orderId)

    if (!error) {
      const userName = await getDashboardUserName()
      await supabase.from('order_status_log').insert({
        order_id: orderId,
        status,
        reason,
        changed_by_name: userName,
      })

      // When marking received/completed, auto-fill quantity_received for items
      // that haven't been manually reconciled yet (null or 0)
      if (status === 'received' || status === 'completed') {
        const { data: items } = await supabase
          .from('order_items')
          .select('id, quantity_sent, quantity_received')
          .eq('order_id', orderId)
        if (items) {
          const toUpdate = items.filter(i => !i.quantity_received)
          if (toUpdate.length > 0) {
            await Promise.all(
              toUpdate.map(i =>
                supabase.from('order_items')
                  .update({ quantity_received: i.quantity_sent })
                  .eq('id', i.id)
              )
            )
          }
        }
      }

      fetchOrders()
    }
    return { error }
  }, [fetchOrders])

  const updateOrder = useCallback(async (orderId: string, updates: Partial<Order>) => {
    const { error } = await supabase
      .from('orders')
      .update(updates)
      .eq('id', orderId)
    if (!error) fetchOrders()
    return { error }
  }, [fetchOrders])

  const updateOrderItem = useCallback(async (itemId: string, updates: { quantity_sent?: number; quantity_received?: number }) => {
    const { error } = await supabase
      .from('order_items')
      .update(updates)
      .eq('id', itemId)
    if (!error) fetchOrders()
    return { error }
  }, [fetchOrders])

  const deleteOrders = useCallback(async (orderIds: string[]) => {
    const { error } = await supabase
      .from('orders')
      .delete()
      .in('id', orderIds)
    if (!error) fetchOrders()
    return { error }
  }, [fetchOrders])

  /** Bulk save: docket numbers + item prices in one go */
  const bulkSaveEdits = useCallback(async (
    edits: BulkEdits,
    onProgress?: (done: number, total: number) => void,
  ) => {
    const promises: PromiseLike<unknown>[] = []

    for (const [orderId, updates] of Object.entries(edits.orders)) {
      if (Object.keys(updates).length > 0) {
        promises.push(supabase.from('orders').update(updates).eq('id', orderId).then())
      }
    }

    for (const [itemId, updates] of Object.entries(edits.items)) {
      if (Object.keys(updates).length > 0) {
        promises.push(supabase.from('order_items').update({ price_at_time: updates.price_at_time }).eq('id', itemId).then())
      }
    }

    await Promise.all(promises)

    // Recalculate total_price for affected orders
    const affectedOrderIds = new Set<string>(Object.keys(edits.orders))
    for (const upd of Object.values(edits.items)) {
      if (upd.order_id) affectedOrderIds.add(upd.order_id)
    }

    const orderIdList = Array.from(affectedOrderIds)
    for (let i = 0; i < orderIdList.length; i++) {
      const orderId = orderIdList[i]
      const { data: items } = await supabase
        .from('order_items')
        .select('quantity_sent, price_at_time')
        .eq('order_id', orderId)
      if (items) {
        const total = items.reduce((s, i) => s + (i.price_at_time ?? 0) * (i.quantity_sent ?? 0), 0)
        if (total > 0) {
          await supabase.from('orders').update({ total_price: Number(total.toFixed(2)) }).eq('id', orderId)
        }
      }
      onProgress?.(i + 1, orderIdList.length)
    }

    await fetchOrders()
  }, [fetchOrders])

  /** Bulk status update — processes all orders without refreshing in between, calls progress callback */
  const bulkUpdateStatus = useCallback(async (
    orderIds: string[],
    status: OrderStatus,
    onProgress?: (done: number, total: number) => void,
  ) => {
    const total = orderIds.length
    const userName = await getDashboardUserName()
    for (let i = 0; i < total; i++) {
      const orderId = orderIds[i]

      await supabase.from('orders').update({ status }).eq('id', orderId)

      await supabase.from('order_status_log').insert({
        order_id: orderId,
        status,
        changed_by_name: userName,
      })

      // Auto-fill quantity_received when marking received/completed
      if (status === 'received' || status === 'completed') {
        const { data: items } = await supabase
          .from('order_items')
          .select('id, quantity_sent, quantity_received')
          .eq('order_id', orderId)
        if (items) {
          const toUpdate = items.filter(i => !i.quantity_received)
          if (toUpdate.length > 0) {
            await Promise.all(
              toUpdate.map(i =>
                supabase.from('order_items')
                  .update({ quantity_received: i.quantity_sent })
                  .eq('id', i.id)
              )
            )
          }
        }
      }

      onProgress?.(i + 1, total)
    }

    await fetchOrders()
  }, [fetchOrders])

  return { orders, departments, loading, filters, setFilters, fetchOrders, updateOrderStatus, updateOrder, updateOrderItem, deleteOrders, bulkSaveEdits, bulkUpdateStatus }
}
