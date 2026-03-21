import { useState, useEffect, useMemo } from 'react'
import { supabase } from '../lib/supabase'
import {
  BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer,
  PieChart, Pie, Cell, Legend, LineChart, Line,
} from 'recharts'
import { ORDER_STATUS_LABELS, ORDER_TYPE_LABELS } from '../types'
import type { Order, OrderStatus, OrderType } from '../types'

const COLORS = ['#1B2A4A', '#C9A84C', '#3B82F6', '#EF4444', '#F59E0B', '#8B5CF6', '#10B981']

export default function Reports() {
  const [orders, setOrders] = useState<Order[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    async function fetch() {
      const { data } = await supabase
        .from('orders')
        .select('*, order_items(*)')
        .order('created_at', { ascending: true })
      setOrders(data ?? [])
      setLoading(false)
    }
    fetch()
  }, [])

  const statusData = useMemo(() => {
    const counts: Record<string, number> = {}
    orders.forEach((o) => {
      counts[o.status] = (counts[o.status] || 0) + 1
    })
    return Object.entries(counts).map(([status, count]) => ({
      name: ORDER_STATUS_LABELS[status as OrderStatus] || status,
      value: count,
    }))
  }, [orders])

  const typeData = useMemo(() => {
    const counts: Record<string, number> = {}
    orders.forEach((o) => {
      counts[o.order_type] = (counts[o.order_type] || 0) + 1
    })
    return Object.entries(counts).map(([type, count]) => ({
      name: ORDER_TYPE_LABELS[type as OrderType] || type,
      value: count,
    }))
  }, [orders])

  const monthlyData = useMemo(() => {
    const months: Record<string, number> = {}
    orders.forEach((o) => {
      const month = new Date(o.created_at).toLocaleDateString('en-GB', { month: 'short', year: '2-digit' })
      months[month] = (months[month] || 0) + 1
    })
    return Object.entries(months).map(([month, count]) => ({ month, orders: count }))
  }, [orders])

  const revenueData = useMemo(() => {
    const months: Record<string, number> = {}
    orders.forEach((o) => {
      if (o.total_price) {
        const month = new Date(o.created_at).toLocaleDateString('en-GB', { month: 'short', year: '2-digit' })
        months[month] = (months[month] || 0) + o.total_price
      }
    })
    return Object.entries(months).map(([month, revenue]) => ({ month, revenue: Number(revenue.toFixed(2)) }))
  }, [orders])

  const totalOrders = orders.length
  const totalRevenue = orders.reduce((sum, o) => sum + (o.total_price || 0), 0)
  const totalItems = orders.reduce((sum, o) => sum + (o.order_items?.length || 0), 0)
  const completedOrders = orders.filter((o) => o.status === 'completed').length

  if (loading) {
    return (
      <div className="flex items-center justify-center py-20">
        <div className="w-6 h-6 border-2 border-navy/30 border-t-navy rounded-full animate-spin" />
      </div>
    )
  }

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-semibold text-gray-900">Reports</h1>

      {/* Summary cards */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        <StatCard label="Total Orders" value={totalOrders} />
        <StatCard label="Revenue" value={`£${totalRevenue.toFixed(2)}`} />
        <StatCard label="Items Processed" value={totalItems} />
        <StatCard label="Completed" value={completedOrders} />
      </div>

      {/* Charts */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <ChartCard title="Orders by Month">
          <ResponsiveContainer width="100%" height={280}>
            <BarChart data={monthlyData}>
              <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
              <XAxis dataKey="month" tick={{ fontSize: 12 }} />
              <YAxis tick={{ fontSize: 12 }} />
              <Tooltip />
              <Bar dataKey="orders" fill="#1B2A4A" radius={[4, 4, 0, 0]} />
            </BarChart>
          </ResponsiveContainer>
        </ChartCard>

        <ChartCard title="Revenue by Month">
          <ResponsiveContainer width="100%" height={280}>
            <LineChart data={revenueData}>
              <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
              <XAxis dataKey="month" tick={{ fontSize: 12 }} />
              <YAxis tick={{ fontSize: 12 }} />
              <Tooltip formatter={(v) => `£${Number(v).toFixed(2)}`} />
              <Line type="monotone" dataKey="revenue" stroke="#C9A84C" strokeWidth={2} dot={{ fill: '#C9A84C' }} />
            </LineChart>
          </ResponsiveContainer>
        </ChartCard>

        <ChartCard title="Orders by Status">
          <ResponsiveContainer width="100%" height={280}>
            <PieChart>
              <Pie data={statusData} cx="50%" cy="50%" innerRadius={60} outerRadius={100} dataKey="value" label>
                {statusData.map((_, i) => (
                  <Cell key={i} fill={COLORS[i % COLORS.length]} />
                ))}
              </Pie>
              <Tooltip />
              <Legend />
            </PieChart>
          </ResponsiveContainer>
        </ChartCard>

        <ChartCard title="Orders by Type">
          <ResponsiveContainer width="100%" height={280}>
            <PieChart>
              <Pie data={typeData} cx="50%" cy="50%" innerRadius={60} outerRadius={100} dataKey="value" label>
                {typeData.map((_, i) => (
                  <Cell key={i} fill={COLORS[i % COLORS.length]} />
                ))}
              </Pie>
              <Tooltip />
              <Legend />
            </PieChart>
          </ResponsiveContainer>
        </ChartCard>
      </div>
    </div>
  )
}

function StatCard({ label, value }: { label: string; value: string | number }) {
  return (
    <div className="bg-white rounded-xl border border-gray-200 p-5">
      <p className="text-sm text-gray-500">{label}</p>
      <p className="text-2xl font-semibold text-gray-900 mt-1">{value}</p>
    </div>
  )
}

function ChartCard({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <div className="bg-white rounded-xl border border-gray-200 p-5">
      <h3 className="text-sm font-semibold text-gray-900 mb-4">{title}</h3>
      {children}
    </div>
  )
}
