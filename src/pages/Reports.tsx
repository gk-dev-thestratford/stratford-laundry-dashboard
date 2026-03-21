import { useState, useEffect, useMemo, useCallback, Fragment } from 'react'
import { supabase } from '../lib/supabase'
import {
  BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, Cell,
} from 'recharts'
import {
  ChevronLeft, ChevronRight, ChevronDown, Download, RefreshCw,
  AlertTriangle, Package, ClipboardList, Building2, TrendingUp,
} from 'lucide-react'
import { MONTHS, ORDER_TYPE_LABELS, ORDER_STATUS_LABELS, ORDER_STATUS_COLORS } from '../types'
import type { Order, OrderType, OrderStatus } from '../types'
import { utils, writeFile } from 'xlsx'
import { format } from 'date-fns'

const DEPT_COLORS = ['#1B2A4A', '#C9A84C', '#3B82F6', '#10B981', '#8B5CF6', '#F59E0B', '#EF4444', '#06B6D4', '#EC4899', '#14B8A6']

export default function Reports() {
  const [orders, setOrders] = useState<Order[]>([])
  const [loading, setLoading] = useState(true)
  const [year, setYear] = useState(new Date().getFullYear())
  const [month, setMonth] = useState(0) // 0 = all
  const [expandedOrders, setExpandedOrders] = useState<Set<string>>(new Set())
  const [discrepancyFilter, setDiscrepancyFilter] = useState<'all' | 'discrepancies'>('all')

  const fetchData = useCallback(async () => {
    setLoading(true)
    const { data } = await supabase
      .from('orders')
      .select('*, departments(*), order_items(*)')
      .gte('created_at', `${year}-01-01T00:00:00.000Z`)
      .lt('created_at', `${year + 1}-01-01T00:00:00.000Z`)
      .order('created_at', { ascending: true })
    setOrders(data ?? [])
    setLoading(false)
  }, [year])

  useEffect(() => { fetchData() }, [fetchData])

  // Filtered by month (KPIs, dept breakdown, discrepancies respond to this)
  const filtered = useMemo(() => {
    if (month === 0) return orders
    return orders.filter(o => new Date(o.created_at).getMonth() + 1 === month)
  }, [orders, month])

  // ── KPIs ──
  const kpis = useMemo(() => {
    let sent = 0, received = 0, cost = 0
    filtered.forEach(o => {
      cost += o.total_price || 0
      o.order_items?.forEach(item => {
        sent += item.quantity_sent || 0
        received += item.quantity_received || 0
      })
    })
    return { orders: filtered.length, sent, received, outstanding: sent - received, cost }
  }, [filtered])

  // ── Order type breakdown ──
  const typeBreakdown = useMemo(() => {
    const counts: Record<string, number> = {}
    filtered.forEach(o => { counts[o.order_type] = (counts[o.order_type] || 0) + 1 })
    return Object.entries(counts).map(([type, count]) => ({
      type: ORDER_TYPE_LABELS[type as OrderType] || type, count,
    }))
  }, [filtered])

  // ── Monthly data (always full year for chart + yearly table) ──
  const monthlyData = useMemo(() => {
    return Array.from({ length: 12 }, (_, m) => {
      const mo = orders.filter(o => new Date(o.created_at).getMonth() === m)
      let sent = 0, received = 0, cost = 0
      mo.forEach(o => {
        cost += o.total_price || 0
        o.order_items?.forEach(item => {
          sent += item.quantity_sent || 0
          received += item.quantity_received || 0
        })
      })
      return { month: MONTHS[m + 1] as string, orders: mo.length, sent, received, outstanding: sent - received, cost: Number(cost.toFixed(2)) }
    })
  }, [orders])

  // ── Department breakdown ──
  const deptData = useMemo(() => {
    const map = new Map<string, { name: string; orders: number; sent: number; received: number; cost: number }>()
    filtered.forEach(o => {
      const name = o.department?.name || 'No Department'
      const id = o.department_id || '_none'
      if (!map.has(id)) map.set(id, { name, orders: 0, sent: 0, received: 0, cost: 0 })
      const d = map.get(id)!
      d.orders++
      d.cost += o.total_price || 0
      o.order_items?.forEach(item => {
        d.sent += item.quantity_sent || 0
        d.received += item.quantity_received || 0
      })
    })
    return Array.from(map.values()).sort((a, b) => b.orders - a.orders)
  }, [filtered])

  const deptChartData = useMemo(() => deptData.map(d => ({ name: d.name, orders: d.orders })), [deptData])

  // ── Discrepancies / outstanding ──
  const discrepancies = useMemo(() => {
    return filtered
      .map(o => {
        const items = (o.order_items || [])
          .filter(i => i.quantity_sent > (i.quantity_received ?? 0))
          .map(i => ({ ...i, outstanding: i.quantity_sent - (i.quantity_received ?? 0) }))
        if (items.length === 0) return null
        return {
          id: o.id, docket: o.docket_number, department: o.department?.name || '\u2014',
          type: ORDER_TYPE_LABELS[o.order_type as OrderType] || o.order_type,
          status: o.status, date: o.created_at,
          totalSent: items.reduce((s, i) => s + i.quantity_sent, 0),
          totalReceived: items.reduce((s, i) => s + (i.quantity_received ?? 0), 0),
          totalOutstanding: items.reduce((s, i) => s + i.outstanding, 0),
          items,
        }
      })
      .filter(Boolean) as DiscrepancyOrder[]
  }, [filtered])

  const visibleDiscrepancies = discrepancyFilter === 'discrepancies'
    ? discrepancies.filter(o => ['received', 'completed'].includes(o.status))
    : discrepancies

  function toggleExpand(id: string) {
    setExpandedOrders(prev => {
      const next = new Set(prev)
      if (next.has(id)) next.delete(id); else next.add(id)
      return next
    })
  }

  // ── Export ──
  const exportReport = useCallback(() => {
    const monthlySheet = monthlyData.map(m => ({
      'Month': m.month, 'Orders': m.orders, 'Items Sent': m.sent,
      'Items Received': m.received, 'Outstanding': m.outstanding,
      'Cost (\u00a3)': m.cost,
    }))
    monthlySheet.push({
      'Month': 'TOTAL',
      'Orders': monthlyData.reduce((s, m) => s + m.orders, 0),
      'Items Sent': monthlyData.reduce((s, m) => s + m.sent, 0),
      'Items Received': monthlyData.reduce((s, m) => s + m.received, 0),
      'Outstanding': monthlyData.reduce((s, m) => s + m.outstanding, 0),
      'Cost (\u00a3)': Number(monthlyData.reduce((s, m) => s + m.cost, 0).toFixed(2)),
    })

    const deptSheet = deptData.map(d => ({
      'Department': d.name, 'Orders': d.orders, 'Items Sent': d.sent,
      'Items Received': d.received, 'Outstanding': d.sent - d.received,
      'Cost (\u00a3)': Number(d.cost.toFixed(2)),
    }))

    const outstandingSheet: Record<string, string | number>[] = []
    discrepancies.forEach(o => {
      o.items.forEach(item => {
        outstandingSheet.push({
          'Docket': o.docket, 'Department': o.department, 'Type': o.type,
          'Status': ORDER_STATUS_LABELS[o.status as OrderStatus] || o.status,
          'Date': format(new Date(o.date), 'dd/MM/yyyy'),
          'Item': item.item_name, 'Sent': item.quantity_sent,
          'Received': item.quantity_received ?? 0, 'Outstanding': item.outstanding,
          'Unit Price (\u00a3)': item.price_at_time ?? 0,
          'Outstanding Value (\u00a3)': Number(((item.price_at_time ?? 0) * item.outstanding).toFixed(2)),
        })
      })
    })

    const wb = utils.book_new()
    utils.book_append_sheet(wb, utils.json_to_sheet(monthlySheet), 'Monthly Overview')
    utils.book_append_sheet(wb, utils.json_to_sheet(deptSheet), 'Department Breakdown')
    if (outstandingSheet.length > 0) {
      utils.book_append_sheet(wb, utils.json_to_sheet(outstandingSheet), 'Outstanding Items')
    }
    writeFile(wb, `stratford-report-${year}${month > 0 ? `-${String(month).padStart(2, '0')}` : ''}.xlsx`)
  }, [monthlyData, deptData, discrepancies, year, month])

  // ── Render ──

  if (loading) {
    return (
      <div className="flex items-center justify-center py-20">
        <div className="w-6 h-6 border-2 border-navy/30 border-t-navy rounded-full animate-spin" />
      </div>
    )
  }

  return (
    <div className="space-y-5">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-semibold text-gray-900">Reports</h1>
          <p className="text-sm text-gray-500 mt-1">Performance overview and item tracking</p>
        </div>
        <div className="flex items-center gap-2">
          <button onClick={() => fetchData()} className="p-2 text-gray-600 hover:bg-gray-100 rounded-lg transition-colors" title="Refresh">
            <RefreshCw className={`w-4 h-4 ${loading ? 'animate-spin' : ''}`} />
          </button>
          <button onClick={exportReport} className="flex items-center gap-2 px-4 py-2 text-sm text-white bg-navy rounded-lg hover:bg-navy-light">
            <Download className="w-4 h-4" />
            Export Report
          </button>
        </div>
      </div>

      {/* Date filters */}
      <div className="flex items-center gap-3">
        <div className="flex items-center gap-1 bg-white border border-gray-200 rounded-lg px-1 py-0.5">
          <button onClick={() => setYear(y => y - 1)} className="p-1.5 hover:bg-gray-100 rounded transition-colors">
            <ChevronLeft className="w-4 h-4 text-gray-600" />
          </button>
          <span className="px-2 text-sm font-semibold text-navy min-w-[48px] text-center">{year}</span>
          <button onClick={() => setYear(y => y + 1)} className="p-1.5 hover:bg-gray-100 rounded transition-colors">
            <ChevronRight className="w-4 h-4 text-gray-600" />
          </button>
        </div>
        <div className="flex flex-wrap gap-1.5">
          {MONTHS.map((label, idx) => (
            <button
              key={label}
              onClick={() => setMonth(idx)}
              className={`px-3 py-1.5 text-xs font-medium rounded-lg transition-colors ${
                month === idx ? 'bg-navy text-white' : 'bg-white text-gray-600 border border-gray-200 hover:bg-gray-50'
              }`}
            >
              {label}
            </button>
          ))}
        </div>
      </div>

      {/* KPI cards */}
      <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-5 gap-3">
        <KpiCard icon={<ClipboardList className="w-4 h-4" />} label="Total Orders" value={kpis.orders.toLocaleString()} />
        <KpiCard icon={<Package className="w-4 h-4" />} label="Items Sent" value={kpis.sent.toLocaleString()} />
        <KpiCard icon={<Package className="w-4 h-4" />} label="Items Received" value={kpis.received.toLocaleString()} />
        <KpiCard
          icon={<AlertTriangle className="w-4 h-4" />}
          label="Outstanding"
          value={kpis.outstanding.toLocaleString()}
          alert={kpis.outstanding > 0}
        />
        <KpiCard
          icon={<TrendingUp className="w-4 h-4" />}
          label="Total Cost"
          value={kpis.cost > 0 ? `\u00a3${kpis.cost.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}` : '\u2014'}
        />
      </div>

      {/* Order type pills */}
      {typeBreakdown.length > 0 && (
        <div className="flex flex-wrap items-center gap-2">
          {typeBreakdown.map(t => (
            <span key={t.type} className="inline-flex items-center gap-1.5 px-3 py-1 bg-white border border-gray-200 rounded-lg text-xs text-gray-600">
              <span className="font-semibold text-gray-900">{t.count}</span> {t.type}
            </span>
          ))}
        </div>
      )}

      {/* Charts */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
        <div className="bg-white rounded-xl border border-gray-200 p-4">
          <h3 className="text-sm font-semibold text-gray-900 mb-3">Monthly Orders ({year})</h3>
          <ResponsiveContainer width="100%" height={180}>
            <BarChart data={monthlyData} barSize={20}>
              <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" vertical={false} />
              <XAxis dataKey="month" tick={{ fontSize: 11 }} tickLine={false} axisLine={false} />
              <YAxis tick={{ fontSize: 11 }} tickLine={false} axisLine={false} width={30} allowDecimals={false} />
              <Tooltip contentStyle={{ fontSize: 12, borderRadius: 8 }} />
              <Bar dataKey="orders" radius={[3, 3, 0, 0]}>
                {monthlyData.map((_, i) => (
                  <Cell key={i} fill={month > 0 && i === month - 1 ? '#C9A84C' : '#1B2A4A'} />
                ))}
              </Bar>
            </BarChart>
          </ResponsiveContainer>
        </div>

        <div className="bg-white rounded-xl border border-gray-200 p-4">
          <h3 className="text-sm font-semibold text-gray-900 mb-3">Orders by Department</h3>
          {deptChartData.length > 0 ? (
            <ResponsiveContainer width="100%" height={Math.max(180, deptChartData.length * 36)}>
              <BarChart data={deptChartData} layout="vertical" barSize={16}>
                <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" horizontal={false} />
                <XAxis type="number" tick={{ fontSize: 11 }} tickLine={false} axisLine={false} allowDecimals={false} />
                <YAxis type="category" dataKey="name" tick={{ fontSize: 11 }} tickLine={false} axisLine={false} width={110} />
                <Tooltip contentStyle={{ fontSize: 12, borderRadius: 8 }} />
                <Bar dataKey="orders" radius={[0, 3, 3, 0]}>
                  {deptChartData.map((_, i) => (
                    <Cell key={i} fill={DEPT_COLORS[i % DEPT_COLORS.length]} />
                  ))}
                </Bar>
              </BarChart>
            </ResponsiveContainer>
          ) : (
            <div className="flex items-center justify-center h-[180px] text-sm text-gray-400">No data for this period</div>
          )}
        </div>
      </div>

      {/* Outstanding & Discrepancies */}
      <div className="bg-white rounded-xl border border-gray-200 overflow-hidden">
        <div className="px-5 py-3 border-b border-gray-200 flex items-center gap-2 flex-wrap">
          <AlertTriangle className={`w-4 h-4 flex-shrink-0 ${discrepancies.length > 0 ? 'text-amber-500' : 'text-gray-400'}`} />
          <h3 className="text-sm font-semibold text-gray-900">Outstanding Items</h3>
          <span className="text-xs text-gray-400">
            ({discrepancies.reduce((s, o) => s + o.totalOutstanding, 0)} items across {discrepancies.length} orders)
          </span>
          <div className="flex gap-1 ml-auto">
            <button
              onClick={() => setDiscrepancyFilter('all')}
              className={`px-2.5 py-1 text-xs rounded-lg transition-colors ${
                discrepancyFilter === 'all' ? 'bg-navy text-white' : 'text-gray-600 hover:bg-gray-100'
              }`}
            >
              All Outstanding
            </button>
            <button
              onClick={() => setDiscrepancyFilter('discrepancies')}
              className={`px-2.5 py-1 text-xs rounded-lg transition-colors ${
                discrepancyFilter === 'discrepancies' ? 'bg-amber-500 text-white' : 'text-gray-600 hover:bg-gray-100'
              }`}
            >
              Discrepancies Only
            </button>
          </div>
        </div>

        {visibleDiscrepancies.length === 0 ? (
          <div className="px-5 py-8 text-center text-sm text-gray-400">
            {discrepancies.length === 0
              ? 'All items accounted for \u2014 no outstanding discrepancies'
              : 'No discrepancies found (items still in progress are filtered out)'}
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-gray-200 bg-gray-50">
                  <th className="px-4 py-2 text-left font-medium text-gray-600 w-8" />
                  <th className="px-4 py-2 text-left font-medium text-gray-600">Docket</th>
                  <th className="px-4 py-2 text-left font-medium text-gray-600">Department</th>
                  <th className="px-4 py-2 text-left font-medium text-gray-600">Type</th>
                  <th className="px-4 py-2 text-left font-medium text-gray-600">Date</th>
                  <th className="px-4 py-2 text-left font-medium text-gray-600">Status</th>
                  <th className="px-4 py-2 text-right font-medium text-gray-600">Sent</th>
                  <th className="px-4 py-2 text-right font-medium text-gray-600">Received</th>
                  <th className="px-4 py-2 text-right font-medium text-gray-600">Outstanding</th>
                </tr>
              </thead>
              <tbody>
                {visibleDiscrepancies.map(o => (
                  <Fragment key={o.id}>
                    <tr
                      onClick={() => toggleExpand(o.id)}
                      className="border-b border-gray-100 cursor-pointer hover:bg-gray-50 transition-colors"
                    >
                      <td className="px-4 py-2.5">
                        {expandedOrders.has(o.id)
                          ? <ChevronDown className="w-4 h-4 text-gray-400" />
                          : <ChevronRight className="w-4 h-4 text-gray-400" />}
                      </td>
                      <td className="px-4 py-2.5 font-mono text-xs">{o.docket}</td>
                      <td className="px-4 py-2.5">{o.department}</td>
                      <td className="px-4 py-2.5 text-xs">{o.type}</td>
                      <td className="px-4 py-2.5 text-xs text-gray-500">{format(new Date(o.date), 'dd MMM')}</td>
                      <td className="px-4 py-2.5">
                        <span className={`inline-flex px-2 py-0.5 rounded-full text-xs font-medium ${ORDER_STATUS_COLORS[o.status as OrderStatus] || 'bg-gray-100 text-gray-600'}`}>
                          {ORDER_STATUS_LABELS[o.status as OrderStatus] || o.status}
                        </span>
                      </td>
                      <td className="px-4 py-2.5 text-right">{o.totalSent}</td>
                      <td className="px-4 py-2.5 text-right">{o.totalReceived}</td>
                      <td className="px-4 py-2.5 text-right font-semibold text-amber-600">{o.totalOutstanding}</td>
                    </tr>
                    {expandedOrders.has(o.id) && o.items.map((item, idx) => (
                      <tr key={`${o.id}-${idx}`} className="bg-amber-50/50 border-b border-amber-100/50">
                        <td />
                        <td colSpan={5} className="px-4 py-1.5 text-xs text-gray-600 pl-12">{item.item_name}</td>
                        <td className="px-4 py-1.5 text-right text-xs">{item.quantity_sent}</td>
                        <td className="px-4 py-1.5 text-right text-xs">{item.quantity_received ?? 0}</td>
                        <td className="px-4 py-1.5 text-right text-xs font-medium text-amber-600">-{item.outstanding}</td>
                      </tr>
                    ))}
                  </Fragment>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* Department Breakdown */}
      <div className="bg-white rounded-xl border border-gray-200 overflow-hidden">
        <div className="px-5 py-3 border-b border-gray-200 flex items-center gap-2">
          <Building2 className="w-4 h-4 text-gray-500" />
          <h3 className="text-sm font-semibold text-gray-900">Department Breakdown</h3>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-gray-200 bg-gray-50">
                <th className="px-5 py-2 text-left font-medium text-gray-600">Department</th>
                <th className="px-5 py-2 text-right font-medium text-gray-600">Orders</th>
                <th className="px-5 py-2 text-right font-medium text-gray-600">Items Sent</th>
                <th className="px-5 py-2 text-right font-medium text-gray-600">Items Received</th>
                <th className="px-5 py-2 text-right font-medium text-gray-600">Outstanding</th>
                <th className="px-5 py-2 text-right font-medium text-gray-600">Cost (\u00a3)</th>
              </tr>
            </thead>
            <tbody>
              {deptData.map((d, i) => {
                const out = d.sent - d.received
                return (
                  <tr key={i} className="border-b border-gray-100 last:border-0">
                    <td className="px-5 py-2.5">
                      <div className="flex items-center gap-2">
                        <div className="w-2.5 h-2.5 rounded-full flex-shrink-0" style={{ backgroundColor: DEPT_COLORS[i % DEPT_COLORS.length] }} />
                        {d.name}
                      </div>
                    </td>
                    <td className="px-5 py-2.5 text-right">{d.orders}</td>
                    <td className="px-5 py-2.5 text-right">{d.sent}</td>
                    <td className="px-5 py-2.5 text-right">{d.received}</td>
                    <td className={`px-5 py-2.5 text-right font-medium ${out > 0 ? 'text-amber-600' : 'text-green-600'}`}>
                      {out > 0 ? out : '\u2713'}
                    </td>
                    <td className="px-5 py-2.5 text-right">{d.cost > 0 ? `\u00a3${d.cost.toFixed(2)}` : '\u2014'}</td>
                  </tr>
                )
              })}
              {deptData.length > 1 && (
                <tr className="border-t-2 border-gray-300 bg-gray-50 font-semibold">
                  <td className="px-5 py-2.5">Total</td>
                  <td className="px-5 py-2.5 text-right">{deptData.reduce((s, d) => s + d.orders, 0)}</td>
                  <td className="px-5 py-2.5 text-right">{deptData.reduce((s, d) => s + d.sent, 0)}</td>
                  <td className="px-5 py-2.5 text-right">{deptData.reduce((s, d) => s + d.received, 0)}</td>
                  <td className={`px-5 py-2.5 text-right ${kpis.outstanding > 0 ? 'text-amber-600' : 'text-green-600'}`}>
                    {kpis.outstanding > 0 ? kpis.outstanding : '\u2713'}
                  </td>
                  <td className="px-5 py-2.5 text-right">
                    {kpis.cost > 0 ? `\u00a3${kpis.cost.toFixed(2)}` : '\u2014'}
                  </td>
                </tr>
              )}
              {deptData.length === 0 && (
                <tr><td colSpan={6} className="px-5 py-8 text-center text-gray-400">No data for this period</td></tr>
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Yearly Summary */}
      <div className="bg-white rounded-xl border border-gray-200 overflow-hidden">
        <div className="px-5 py-3 border-b border-gray-200 flex items-center gap-2">
          <TrendingUp className="w-4 h-4 text-gray-500" />
          <h3 className="text-sm font-semibold text-gray-900">Yearly Summary \u2014 {year}</h3>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-gray-200 bg-gray-50">
                <th className="px-5 py-2 text-left font-medium text-gray-600">Month</th>
                <th className="px-5 py-2 text-right font-medium text-gray-600">Orders</th>
                <th className="px-5 py-2 text-right font-medium text-gray-600">Items Sent</th>
                <th className="px-5 py-2 text-right font-medium text-gray-600">Items Received</th>
                <th className="px-5 py-2 text-right font-medium text-gray-600">Outstanding</th>
                <th className="px-5 py-2 text-right font-medium text-gray-600">Cost (\u00a3)</th>
              </tr>
            </thead>
            <tbody>
              {monthlyData.map((m, i) => (
                <tr
                  key={i}
                  className={`border-b border-gray-100 ${month > 0 && i === month - 1 ? 'bg-gold/5' : ''} ${m.orders === 0 ? 'text-gray-300' : ''}`}
                >
                  <td className="px-5 py-2">{m.month}</td>
                  <td className="px-5 py-2 text-right">{m.orders || '\u2014'}</td>
                  <td className="px-5 py-2 text-right">{m.sent || '\u2014'}</td>
                  <td className="px-5 py-2 text-right">{m.received || '\u2014'}</td>
                  <td className={`px-5 py-2 text-right font-medium ${m.outstanding > 0 ? 'text-amber-600' : ''}`}>
                    {m.orders > 0 ? (m.outstanding > 0 ? m.outstanding : '\u2713') : '\u2014'}
                  </td>
                  <td className="px-5 py-2 text-right">{m.cost > 0 ? `\u00a3${m.cost.toFixed(2)}` : '\u2014'}</td>
                </tr>
              ))}
              <tr className="border-t-2 border-gray-300 bg-gray-50 font-semibold">
                <td className="px-5 py-2.5">Total</td>
                <td className="px-5 py-2.5 text-right">{monthlyData.reduce((s, m) => s + m.orders, 0)}</td>
                <td className="px-5 py-2.5 text-right">{monthlyData.reduce((s, m) => s + m.sent, 0)}</td>
                <td className="px-5 py-2.5 text-right">{monthlyData.reduce((s, m) => s + m.received, 0)}</td>
                <td className={`px-5 py-2.5 text-right ${monthlyData.reduce((s, m) => s + m.outstanding, 0) > 0 ? 'text-amber-600' : 'text-green-600'}`}>
                  {monthlyData.reduce((s, m) => s + m.outstanding, 0) || '\u2713'}
                </td>
                <td className="px-5 py-2.5 text-right">
                  {monthlyData.reduce((s, m) => s + m.cost, 0) > 0
                    ? `\u00a3${monthlyData.reduce((s, m) => s + m.cost, 0).toFixed(2)}`
                    : '\u2014'}
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>
  )
}

// ── Helper types ──

interface DiscrepancyOrder {
  id: string
  docket: string
  department: string
  type: string
  status: string
  date: string
  totalSent: number
  totalReceived: number
  totalOutstanding: number
  items: Array<{
    item_name: string
    quantity_sent: number
    quantity_received: number | null
    outstanding: number
    price_at_time: number | null
  }>
}

// ── KPI Card ──

function KpiCard({ icon, label, value, alert }: {
  icon: React.ReactNode; label: string; value: string | number; alert?: boolean
}) {
  return (
    <div className={`bg-white rounded-xl border p-4 ${alert ? 'border-amber-200 bg-amber-50/50' : 'border-gray-200'}`}>
      <div className="flex items-center gap-1.5 text-gray-500 mb-1">
        {icon}
        <span className="text-xs font-medium">{label}</span>
      </div>
      <p className={`text-xl font-semibold ${alert ? 'text-amber-600' : 'text-gray-900'}`}>{value}</p>
    </div>
  )
}
