import { useState, useEffect, useCallback } from 'react'
import { supabase } from '../lib/supabase'
import type { Order, Department, OrderStatus } from '../types'

interface Filters {
  status: OrderStatus | 'all'
  department: string
  month: number // 0 = all, 1-12 = Jan-Dec
  search: string
}

export function useOrders() {
  const [orders, setOrders] = useState<Order[]>([])
  const [departments, setDepartments] = useState<Department[]>([])
  const [loading, setLoading] = useState(true)
  const [filters, setFilters] = useState<Filters>({
    status: 'all',
    department: 'all',
    month: 0,
    search: '',
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
    if (filters.month > 0) {
      const year = new Date().getFullYear()
      const startDate = new Date(year, filters.month - 1, 1).toISOString()
      const endDate = new Date(year, filters.month, 1).toISOString()
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
          o.room_number?.toLowerCase().includes(s)
      )
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
      await supabase.from('order_status_log').insert({
        order_id: orderId,
        status,
        reason,
        changed_by_name: 'Dashboard',
      })
      fetchOrders()
    }
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

  return { orders, departments, loading, filters, setFilters, fetchOrders, updateOrderStatus, deleteOrders }
}
