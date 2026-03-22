import { useState, useEffect, useCallback } from 'react'
import { useNavigate } from 'react-router-dom'
import { RefreshCw, Clock, Upload } from 'lucide-react'
import { supabase } from '../lib/supabase'
import { format } from 'date-fns'

interface SavedReconciliation {
  id: string
  invoice_number: string
  invoice_date: string
  invoice_period: string
  created_at: string
  created_by: string
  invoice_net: number
  invoice_gross: number
  system_total: number
  topup_total: number
  matched_count: number
  mismatch_count: number
  not_found_count: number
  missing_count: number
  department_breakdown: {
    departmentName: string
    orderCount: number
    invoiceNet: number
    systemTotal: number
    allocatedTopUp: number
    totalCostNet: number
    totalCostGross: number
  }[]
}

export default function ReconciliationHistory() {
  const navigate = useNavigate()
  const [history, setHistory] = useState<SavedReconciliation[]>([])
  const [loading, setLoading] = useState(true)
  const [expanded, setExpanded] = useState<string | null>(null)

  const loadHistory = useCallback(async () => {
    setLoading(true)
    const { data } = await supabase
      .from('reconciliations').select('*')
      .order('created_at', { ascending: false }).limit(50)
    setHistory((data as SavedReconciliation[] | null) ?? [])
    setLoading(false)
  }, [])

  useEffect(() => { loadHistory() }, [loadHistory])

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-semibold text-gray-900">Reconciliation History</h1>
          <p className="text-sm text-gray-500 mt-1">Past reconciliations and audit trail</p>
        </div>
        <button
          onClick={() => navigate('/reconciliation')}
          className="flex items-center gap-2 px-4 py-2 text-sm text-white bg-navy rounded-lg hover:bg-navy-light"
        >
          <Upload className="w-4 h-4" /> New Reconciliation
        </button>
      </div>

      {loading ? (
        <div className="flex justify-center py-20">
          <RefreshCw className="w-6 h-6 text-gray-400 animate-spin" />
        </div>
      ) : history.length === 0 ? (
        <div className="bg-white rounded-xl border border-gray-200 p-12 text-center">
          <Clock className="w-12 h-12 text-gray-300 mx-auto mb-3" />
          <p className="text-gray-500">No reconciliations saved yet</p>
          <p className="text-sm text-gray-400 mt-1">Upload an invoice on the Reconciliation page and click Save to create a record</p>
        </div>
      ) : (
        <div className="bg-white rounded-xl border border-gray-200 overflow-hidden">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-gray-200 bg-gray-50">
                <th className="px-4 py-3 text-left font-medium text-gray-600">Invoice</th>
                <th className="px-4 py-3 text-left font-medium text-gray-600">Period</th>
                <th className="px-4 py-3 text-left font-medium text-gray-600">Reconciled</th>
                <th className="px-4 py-3 text-right font-medium text-gray-600">Invoice NET</th>
                <th className="px-4 py-3 text-right font-medium text-gray-600">TopUp</th>
                <th className="px-4 py-3 text-right font-medium text-gray-600">Total</th>
                <th className="px-4 py-3 text-center font-medium text-gray-600">Matched</th>
                <th className="px-4 py-3 text-center font-medium text-gray-600">Issues</th>
                <th className="px-4 py-3 text-left font-medium text-gray-600">By</th>
              </tr>
            </thead>
            <tbody>
              {history.map(h => {
                const issues = h.mismatch_count + h.not_found_count + h.missing_count
                const isExpanded = expanded === h.id
                return (
                  <>{/* eslint-disable-next-line react/jsx-key */}
                    <tr
                      key={h.id}
                      className={`border-b border-gray-100 hover:bg-gray-50 cursor-pointer ${isExpanded ? 'bg-gray-50' : ''}`}
                      onClick={() => setExpanded(isExpanded ? null : h.id)}
                    >
                      <td className="px-4 py-3 font-mono font-medium text-navy">{h.invoice_number || '—'}</td>
                      <td className="px-4 py-3 text-gray-600">{h.invoice_period || '—'}</td>
                      <td className="px-4 py-3 text-gray-500">{format(new Date(h.created_at), 'dd MMM yyyy HH:mm')}</td>
                      <td className="px-4 py-3 text-right font-medium">{'\u00a3'}{h.invoice_net.toFixed(2)}</td>
                      <td className="px-4 py-3 text-right text-amber-600">{h.topup_total > 0 ? `\u00a3${h.topup_total.toFixed(2)}` : '\u2014'}</td>
                      <td className="px-4 py-3 text-right font-semibold">{'\u00a3'}{(h.invoice_net + h.topup_total).toFixed(2)}</td>
                      <td className="px-4 py-3 text-center">
                        <span className="inline-flex px-2 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-700">{h.matched_count}</span>
                      </td>
                      <td className="px-4 py-3 text-center">
                        <span className={`inline-flex px-2 py-0.5 rounded-full text-xs font-medium ${issues > 0 ? 'bg-amber-100 text-amber-700' : 'bg-green-100 text-green-700'}`}>{issues}</span>
                      </td>
                      <td className="px-4 py-3 text-gray-500 text-xs">{h.created_by}</td>
                    </tr>
                    {isExpanded && h.department_breakdown && h.department_breakdown.length > 0 && (
                      <tr key={`${h.id}-detail`}>
                        <td colSpan={9} className="px-6 py-4 bg-gray-50/50">
                          <p className="text-xs font-semibold text-gray-500 uppercase mb-2">Department Breakdown</p>
                          <table className="w-full text-xs">
                            <thead>
                              <tr className="text-gray-500">
                                <th className="text-left py-1 pr-4">Department</th>
                                <th className="text-right py-1 pr-4">Orders</th>
                                <th className="text-right py-1 pr-4">Invoice NET</th>
                                <th className="text-right py-1 pr-4">TopUp</th>
                                <th className="text-right py-1 pr-4">Total NET</th>
                                <th className="text-right py-1">Total inc VAT</th>
                              </tr>
                            </thead>
                            <tbody>
                              {h.department_breakdown.map((d, i) => (
                                <tr key={i} className="border-t border-gray-100">
                                  <td className="py-1.5 pr-4 font-medium text-gray-800">{d.departmentName}</td>
                                  <td className="py-1.5 pr-4 text-right">{d.orderCount}</td>
                                  <td className="py-1.5 pr-4 text-right">{'\u00a3'}{d.invoiceNet.toFixed(2)}</td>
                                  <td className="py-1.5 pr-4 text-right text-amber-600">{d.allocatedTopUp > 0 ? `\u00a3${d.allocatedTopUp.toFixed(2)}` : '\u2014'}</td>
                                  <td className="py-1.5 pr-4 text-right font-medium">{'\u00a3'}{d.totalCostNet.toFixed(2)}</td>
                                  <td className="py-1.5 text-right font-medium">{'\u00a3'}{d.totalCostGross.toFixed(2)}</td>
                                </tr>
                              ))}
                            </tbody>
                          </table>
                        </td>
                      </tr>
                    )}
                  </>
                )
              })}
            </tbody>
          </table>
        </div>
      )}
    </div>
  )
}
