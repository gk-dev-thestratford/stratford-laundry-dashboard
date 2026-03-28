import { useState, useEffect, useMemo, useCallback } from 'react'
import { supabase } from '../lib/supabase'
import {
  BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, Legend,
} from 'recharts'
import {
  ChevronLeft, ChevronRight, ChevronDown, Download, RefreshCw,
  ArrowUpRight, ArrowDownLeft, Scale,
} from 'lucide-react'
import { MONTHS } from '../types'
import { format } from 'date-fns'
import { utils, writeFile } from 'xlsx'

interface LedgerEntry {
  id: string
  item_name: string
  direction: 'out' | 'in'
  quantity: number
  order_id: string | null
  department_id: string | null
  note: string | null
  recorded_by: string | null
  created_at: string
  // joined
  order?: { docket_number: string } | null
  department?: { name: string } | null
}

export default function LinenPool() {
  const [entries, setEntries] = useState<LedgerEntry[]>([])
  const [loading, setLoading] = useState(true)
  const [year, setYear] = useState(new Date().getFullYear())
  const [month, setMonth] = useState(0) // 0 = all
  const [directionFilter, setDirectionFilter] = useState<'all' | 'out' | 'in'>('all')
  const [ledgerExpanded, setLedgerExpanded] = useState(false)

  const fetchData = useCallback(async () => {
    setLoading(true)
    const { data } = await supabase
      .from('linen_ledger')
      .select('*, order:orders(docket_number), department:departments(name)')
      .gte('created_at', `${year}-01-01T00:00:00.000Z`)
      .lt('created_at', `${year + 1}-01-01T00:00:00.000Z`)
      .order('created_at', { ascending: false })
    setEntries(data ?? [])
    setLoading(false)
  }, [year])

  useEffect(() => { fetchData() }, [fetchData])

  // ── All-time totals for pool balance ──
  const [allTimeTotals, setAllTimeTotals] = useState({ out: 0, in: 0 })
  useEffect(() => {
    ;(async () => {
      const { data } = await supabase
        .from('linen_ledger')
        .select('direction, quantity')
      if (data) {
        let out = 0, inn = 0
        data.forEach(e => {
          if (e.direction === 'out') out += e.quantity
          else inn += e.quantity
        })
        setAllTimeTotals({ out, in: inn })
      }
    })()
  }, [entries]) // refresh when entries change

  // ── Filtered entries (by month) ──
  const filtered = useMemo(() => {
    if (month === 0) return entries
    return entries.filter(e => new Date(e.created_at).getMonth() + 1 === month)
  }, [entries, month])

  // ── KPIs for selected period ──
  const kpis = useMemo(() => {
    let out = 0, inn = 0
    filtered.forEach(e => {
      if (e.direction === 'out') out += e.quantity
      else inn += e.quantity
    })
    return { out, in: inn, net: out - inn }
  }, [filtered])

  // ── Monthly chart data (always full year) ──
  const monthlyData = useMemo(() => {
    return Array.from({ length: 12 }, (_, m) => {
      const mo = entries.filter(e => new Date(e.created_at).getMonth() === m)
      let out = 0, inn = 0
      mo.forEach(e => {
        if (e.direction === 'out') out += e.quantity
        else inn += e.quantity
      })
      return { month: MONTHS[m + 1] as string, out, in: inn, net: out - inn }
    })
  }, [entries])

  // ── Visible ledger rows (direction filter + collapse) ──
  const visibleEntries = useMemo(() => {
    let result = filtered
    if (directionFilter !== 'all') {
      result = result.filter(e => e.direction === directionFilter)
    }
    return result
  }, [filtered, directionFilter])

  const displayedEntries = ledgerExpanded ? visibleEntries : visibleEntries.slice(0, 10)

  // ── Department breakdown ──
  const deptBreakdown = useMemo(() => {
    const map = new Map<string, { name: string; out: number; in: number }>()
    filtered.forEach(e => {
      const name = e.department?.name || 'No Department'
      const id = e.department_id || '_none'
      if (!map.has(id)) map.set(id, { name, out: 0, in: 0 })
      const d = map.get(id)!
      if (e.direction === 'out') d.out += e.quantity
      else d.in += e.quantity
    })
    return Array.from(map.values()).sort((a, b) => b.out - a.out)
  }, [filtered])

  // ── Export ──
  const exportReport = useCallback(() => {
    const monthlySheet = monthlyData.map(m => ({
      'Month': m.month, 'Sent Out': m.out, 'Received In': m.in, 'Net': m.net,
    }))
    monthlySheet.push({
      'Month': 'TOTAL',
      'Sent Out': monthlyData.reduce((s, m) => s + m.out, 0),
      'Received In': monthlyData.reduce((s, m) => s + m.in, 0),
      'Net': monthlyData.reduce((s, m) => s + m.net, 0),
    })

    const ledgerSheet = filtered.map(e => ({
      'Date': format(new Date(e.created_at), 'dd/MM/yyyy HH:mm'),
      'Direction': e.direction.toUpperCase(),
      'Quantity': e.quantity,
      'Docket': e.order?.docket_number || '—',
      'Department': e.department?.name || '—',
      'Note': e.note || '',
      'Recorded By': e.recorded_by || '',
    }))

    const deptSheet = deptBreakdown.map(d => ({
      'Department': d.name, 'Sent Out': d.out, 'Received In': d.in, 'Net': d.out - d.in,
    }))

    const wb = utils.book_new()
    utils.book_append_sheet(wb, utils.json_to_sheet(monthlySheet), 'Monthly Overview')
    utils.book_append_sheet(wb, utils.json_to_sheet(ledgerSheet), 'Ledger Entries')
    if (deptSheet.length > 0) {
      utils.book_append_sheet(wb, utils.json_to_sheet(deptSheet), 'By Department')
    }
    writeFile(wb, `linen-pool-${year}${month > 0 ? `-${String(month).padStart(2, '0')}` : ''}.xlsx`)
  }, [monthlyData, filtered, deptBreakdown, year, month])

  // ── Render ──

  if (loading) {
    return (
      <div className="flex items-center justify-center py-20">
        <div className="w-6 h-6 border-2 border-navy/30 border-t-navy rounded-full animate-spin" />
      </div>
    )
  }

  const poolBalance = allTimeTotals.out - allTimeTotals.in

  return (
    <div className="space-y-5">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-semibold text-gray-900">Linen Pool</h1>
          <p className="text-sm text-gray-500 mt-1">Napkin inventory tracking — pool-based in/out ledger</p>
        </div>
        <div className="flex items-center gap-2">
          <button onClick={() => fetchData()} className="p-2 text-gray-600 hover:bg-gray-100 rounded-lg transition-colors" title="Refresh">
            <RefreshCw className={`w-4 h-4 ${loading ? 'animate-spin' : ''}`} />
          </button>
          <button onClick={exportReport} className="flex items-center gap-2 px-4 py-2.5 text-sm font-medium text-white bg-navy rounded-xl hover:bg-navy-light shadow-sm transition-colors">
            <Download className="w-4 h-4" />
            Export
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
      <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
        <PoolCard
          icon={<ArrowUpRight className="w-5 h-5" />}
          label={month === 0 ? 'Sent Out (Year)' : `Sent Out (${MONTHS[month]})`}
          value={kpis.out.toLocaleString()}
          color="navy"
        />
        <PoolCard
          icon={<ArrowDownLeft className="w-5 h-5" />}
          label={month === 0 ? 'Received In (Year)' : `Received In (${MONTHS[month]})`}
          value={kpis.in.toLocaleString()}
          color="emerald"
        />
        <PoolCard
          icon={<Scale className="w-5 h-5" />}
          label={month === 0 ? 'Net Movement (Year)' : `Net (${MONTHS[month]})`}
          value={kpis.net > 0 ? `+${kpis.net.toLocaleString()}` : kpis.net.toLocaleString()}
          color={kpis.net > 0 ? 'amber' : 'emerald'}
        />
        <PoolCard
          icon={<Scale className="w-5 h-5" />}
          label="Pool Balance (All Time)"
          value={poolBalance > 0 ? `${poolBalance.toLocaleString()} at laundry` : poolBalance === 0 ? 'Balanced' : `${Math.abs(poolBalance).toLocaleString()} surplus`}
          color={poolBalance > 0 ? 'amber' : 'emerald'}
          subtitle={`${allTimeTotals.out.toLocaleString()} out / ${allTimeTotals.in.toLocaleString()} in`}
        />
      </div>

      {/* Monthly chart */}
      <div className="bg-white rounded-2xl border border-gray-100 shadow-sm p-5">
        <h3 className="text-sm font-semibold text-gray-900 mb-4">Monthly Movement ({year})</h3>
        <ResponsiveContainer width="100%" height={220}>
          <BarChart data={monthlyData} barGap={2}>
            <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" vertical={false} />
            <XAxis dataKey="month" tick={{ fontSize: 11 }} tickLine={false} axisLine={false} />
            <YAxis tick={{ fontSize: 11 }} tickLine={false} axisLine={false} width={40} allowDecimals={false} />
            <Tooltip contentStyle={{ fontSize: 12, borderRadius: 8 }} />
            <Legend wrapperStyle={{ fontSize: 12 }} />
            <Bar dataKey="out" name="Sent Out" fill="#1B2A4A" radius={[3, 3, 0, 0]} barSize={18} />
            <Bar dataKey="in" name="Received In" fill="#10B981" radius={[3, 3, 0, 0]} barSize={18} />
          </BarChart>
        </ResponsiveContainer>
      </div>

      {/* Ledger table */}
      <div className="bg-white rounded-2xl border border-gray-100 shadow-sm overflow-hidden">
        <div className="px-5 py-4 border-b border-gray-100 flex items-center gap-2 flex-wrap">
          <div className="w-8 h-8 rounded-lg bg-navy/10 flex items-center justify-center">
            <Scale className="w-4 h-4 text-navy" />
          </div>
          <div>
            <h3 className="text-sm font-semibold text-gray-900">Ledger Entries</h3>
            <span className="text-[11px] text-gray-400">{visibleEntries.length} transactions</span>
          </div>
          <div className="flex gap-1 ml-auto">
            {(['all', 'out', 'in'] as const).map(f => (
              <button
                key={f}
                onClick={() => setDirectionFilter(f)}
                className={`px-2.5 py-1 text-xs rounded-lg transition-colors ${
                  directionFilter === f
                    ? f === 'out' ? 'bg-navy text-white' : f === 'in' ? 'bg-emerald-500 text-white' : 'bg-navy text-white'
                    : 'text-gray-600 hover:bg-gray-100'
                }`}
              >
                {f === 'all' ? 'All' : f === 'out' ? 'Sent Out' : 'Received In'}
              </button>
            ))}
          </div>
        </div>

        {visibleEntries.length === 0 ? (
          <div className="px-5 py-8 text-center text-sm text-gray-400">
            No ledger entries for this period
          </div>
        ) : (
          <>
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead>
                  <tr className="border-b border-gray-200 bg-gray-50">
                    <th className="px-4 py-2 text-left font-medium text-gray-600">Date</th>
                    <th className="px-4 py-2 text-left font-medium text-gray-600">Direction</th>
                    <th className="px-4 py-2 text-right font-medium text-gray-600">Quantity</th>
                    <th className="px-4 py-2 text-left font-medium text-gray-600">Docket</th>
                    <th className="px-4 py-2 text-left font-medium text-gray-600">Department</th>
                    <th className="px-4 py-2 text-left font-medium text-gray-600">Note</th>
                    <th className="px-4 py-2 text-left font-medium text-gray-600">Recorded By</th>
                  </tr>
                </thead>
                <tbody>
                  {displayedEntries.map(e => (
                    <tr key={e.id} className="border-b border-gray-100 hover:bg-gray-50 transition-colors">
                      <td className="px-4 py-2.5 text-xs text-gray-500 whitespace-nowrap">
                        {format(new Date(e.created_at), 'dd MMM yyyy, HH:mm')}
                      </td>
                      <td className="px-4 py-2.5">
                        <span className={`inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-medium ${
                          e.direction === 'out'
                            ? 'bg-navy/10 text-navy'
                            : 'bg-emerald-50 text-emerald-700'
                        }`}>
                          {e.direction === 'out'
                            ? <ArrowUpRight className="w-3 h-3" />
                            : <ArrowDownLeft className="w-3 h-3" />}
                          {e.direction === 'out' ? 'OUT' : 'IN'}
                        </span>
                      </td>
                      <td className="px-4 py-2.5 text-right font-semibold">{e.quantity}</td>
                      <td className="px-4 py-2.5 font-mono text-xs">{e.order?.docket_number || '—'}</td>
                      <td className="px-4 py-2.5 text-xs">{e.department?.name || '—'}</td>
                      <td className="px-4 py-2.5 text-xs text-gray-500 max-w-[200px] truncate">{e.note || '—'}</td>
                      <td className="px-4 py-2.5 text-xs text-gray-500">{e.recorded_by || '—'}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
            {visibleEntries.length > 10 && (
              <button
                onClick={() => setLedgerExpanded(prev => !prev)}
                className="w-full py-2.5 text-sm font-medium text-navy hover:text-gold border-t border-gray-100 transition-colors flex items-center justify-center gap-1"
              >
                {ledgerExpanded ? (
                  <>Show less <ChevronDown className="w-4 h-4 rotate-180" /></>
                ) : (
                  <>See {visibleEntries.length - 10} more entries <ChevronDown className="w-4 h-4" /></>
                )}
              </button>
            )}
          </>
        )}
      </div>

      {/* Monthly Summary table */}
      <div className="bg-white rounded-2xl border border-gray-100 shadow-sm overflow-hidden">
        <div className="px-5 py-4 border-b border-gray-100 flex items-center gap-3">
          <div className="w-8 h-8 rounded-lg bg-gold/15 flex items-center justify-center">
            <Scale className="w-4 h-4 text-gold-dark" />
          </div>
          <h3 className="text-sm font-semibold text-gray-900">Monthly Summary — {year}</h3>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-gray-200 bg-gray-50">
                <th className="px-5 py-2 text-left font-medium text-gray-600">Month</th>
                <th className="px-5 py-2 text-right font-medium text-gray-600">Sent Out</th>
                <th className="px-5 py-2 text-right font-medium text-gray-600">Received In</th>
                <th className="px-5 py-2 text-right font-medium text-gray-600">Net</th>
              </tr>
            </thead>
            <tbody>
              {monthlyData.map((m, i) => (
                <tr
                  key={i}
                  className={`border-b border-gray-100 ${month > 0 && i === month - 1 ? 'bg-gold/5' : ''} ${m.out === 0 && m.in === 0 ? 'text-gray-300' : ''}`}
                >
                  <td className="px-5 py-2">{m.month}</td>
                  <td className="px-5 py-2 text-right">{m.out || '—'}</td>
                  <td className="px-5 py-2 text-right">{m.in || '—'}</td>
                  <td className={`px-5 py-2 text-right font-medium ${
                    m.net > 0 ? 'text-amber-600' : m.net < 0 ? 'text-emerald-600' : ''
                  }`}>
                    {m.out === 0 && m.in === 0 ? '—' : m.net > 0 ? `+${m.net}` : m.net === 0 ? '✓' : m.net}
                  </td>
                </tr>
              ))}
              <tr className="border-t-2 border-gray-300 bg-gray-50 font-semibold">
                <td className="px-5 py-2.5">Total</td>
                <td className="px-5 py-2.5 text-right">{monthlyData.reduce((s, m) => s + m.out, 0)}</td>
                <td className="px-5 py-2.5 text-right">{monthlyData.reduce((s, m) => s + m.in, 0)}</td>
                <td className={`px-5 py-2.5 text-right ${
                  monthlyData.reduce((s, m) => s + m.net, 0) > 0 ? 'text-amber-600' : 'text-emerald-600'
                }`}>
                  {(() => {
                    const total = monthlyData.reduce((s, m) => s + m.net, 0)
                    return total > 0 ? `+${total}` : total === 0 ? '✓' : total
                  })()}
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>

      {/* Department breakdown */}
      {deptBreakdown.length > 0 && (
        <div className="bg-white rounded-2xl border border-gray-100 shadow-sm overflow-hidden">
          <div className="px-5 py-4 border-b border-gray-100 flex items-center gap-3">
            <div className="w-8 h-8 rounded-lg bg-navy/10 flex items-center justify-center">
              <Scale className="w-4 h-4 text-navy" />
            </div>
            <h3 className="text-sm font-semibold text-gray-900">By Department</h3>
          </div>
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-gray-200 bg-gray-50">
                  <th className="px-5 py-2 text-left font-medium text-gray-600">Department</th>
                  <th className="px-5 py-2 text-right font-medium text-gray-600">Sent Out</th>
                  <th className="px-5 py-2 text-right font-medium text-gray-600">Received In</th>
                  <th className="px-5 py-2 text-right font-medium text-gray-600">Net</th>
                </tr>
              </thead>
              <tbody>
                {deptBreakdown.map((d, i) => {
                  const net = d.out - d.in
                  return (
                    <tr key={i} className="border-b border-gray-100 last:border-0">
                      <td className="px-5 py-2.5">{d.name}</td>
                      <td className="px-5 py-2.5 text-right">{d.out}</td>
                      <td className="px-5 py-2.5 text-right">{d.in}</td>
                      <td className={`px-5 py-2.5 text-right font-medium ${net > 0 ? 'text-amber-600' : net < 0 ? 'text-emerald-600' : 'text-green-600'}`}>
                        {net > 0 ? `+${net}` : net === 0 ? '✓' : net}
                      </td>
                    </tr>
                  )
                })}
              </tbody>
            </table>
          </div>
        </div>
      )}
    </div>
  )
}

// ── Pool KPI Card ──

function PoolCard({ icon, label, value, color, subtitle }: {
  icon: React.ReactNode; label: string; value: string; color: 'navy' | 'gold' | 'emerald' | 'amber'; subtitle?: string
}) {
  const colorMap = {
    navy: 'bg-navy/10 text-navy',
    gold: 'bg-gold/15 text-gold-dark',
    emerald: 'bg-emerald-50 text-emerald-600',
    amber: 'bg-amber-50 text-amber-600',
  }
  return (
    <div className="bg-white rounded-2xl border border-gray-100 p-4 shadow-sm hover:shadow-md transition-shadow">
      <div className="flex items-center gap-3">
        <div className={`w-10 h-10 rounded-xl flex items-center justify-center flex-shrink-0 ${colorMap[color]}`}>
          {icon}
        </div>
        <div className="min-w-0">
          <p className="text-xl font-bold text-gray-900">{value}</p>
          <p className="text-[11px] font-medium text-gray-400 uppercase tracking-wide">{label}</p>
          {subtitle && <p className="text-[10px] text-gray-400 mt-0.5">{subtitle}</p>}
        </div>
      </div>
    </div>
  )
}
