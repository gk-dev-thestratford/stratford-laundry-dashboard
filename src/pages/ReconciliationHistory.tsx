import { useState, useEffect, useCallback } from 'react'
import { useNavigate } from 'react-router-dom'
import { RefreshCw, Clock, Upload, FileText, FileSpreadsheet, Trash2 } from 'lucide-react'
import { supabase } from '../lib/supabase'
import { format } from 'date-fns'
import { utils, writeFile } from 'xlsx'

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
  invoice_file_path: string | null
  report_file_path: string | null
  invoice_category: string | null
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
  const [categoryFilter, setCategoryFilter] = useState<string | null>(null)

  const loadHistory = useCallback(async () => {
    setLoading(true)
    const { data } = await supabase
      .from('reconciliations').select('*')
      .order('created_at', { ascending: false }).limit(50)
    setHistory((data as SavedReconciliation[] | null) ?? [])
    setLoading(false)
  }, [])

  useEffect(() => { loadHistory() }, [loadHistory])

  async function downloadInvoice(h: SavedReconciliation) {
    if (!h.invoice_file_path) return
    const { data } = await supabase.storage.from('reconciliations').download(h.invoice_file_path)
    if (data) {
      const url = URL.createObjectURL(data)
      const a = document.createElement('a')
      a.href = url
      a.download = `invoice-${h.invoice_number || 'unknown'}.pdf`
      a.click()
      URL.revokeObjectURL(url)
    }
  }

  function exportExcel(h: SavedReconciliation) {
    const summarySheet = [{
      'Invoice Number': h.invoice_number,
      'Invoice Date': h.invoice_date,
      'Invoice Period': h.invoice_period,
      'Reconciled On': format(new Date(h.created_at), 'dd/MM/yyyy HH:mm'),
      'Reconciled By': h.created_by,
      'Invoice NET (\u00a3)': h.invoice_net,
      'Invoice Gross (\u00a3)': h.invoice_gross,
      'System Total (\u00a3)': h.system_total,
      'TopUp (\u00a3)': h.topup_total,
      'Matched': h.matched_count,
      'Price Mismatches': h.mismatch_count,
      'Not Found': h.not_found_count,
      'Missing': h.missing_count,
    }]
    const deptSheet = (h.department_breakdown || []).map(d => ({
      'Department': d.departmentName,
      'Orders': d.orderCount,
      'Invoice NET (\u00a3)': d.invoiceNet,
      'System Total (\u00a3)': d.systemTotal,
      'TopUp (\u00a3)': d.allocatedTopUp,
      'Total NET (\u00a3)': d.totalCostNet,
      'Total inc VAT (\u00a3)': d.totalCostGross,
    }))
    const wb = utils.book_new()
    utils.book_append_sheet(wb, utils.json_to_sheet(summarySheet), 'Summary')
    if (deptSheet.length > 0) utils.book_append_sheet(wb, utils.json_to_sheet(deptSheet), 'Department Breakdown')
    writeFile(wb, `reconciliation-${h.invoice_number || 'report'}-${format(new Date(h.created_at), 'yyyy-MM-dd')}.xlsx`)
  }

  async function downloadReport(h: SavedReconciliation) {
    if (!h.report_file_path) return
    const { data } = await supabase.storage.from('reconciliations').download(h.report_file_path)
    if (data) {
      const url = URL.createObjectURL(data)
      const a = document.createElement('a')
      a.href = url
      a.download = `reconciliation-report-${h.invoice_number || 'unknown'}.pdf`
      a.click()
      URL.revokeObjectURL(url)
    }
  }

  async function deleteRecord(h: SavedReconciliation) {
    if (!window.confirm(`Delete reconciliation for invoice ${h.invoice_number || 'unknown'}? This cannot be undone.`)) return
    // Delete stored files
    if (h.invoice_file_path) await supabase.storage.from('reconciliations').remove([h.invoice_file_path])
    if (h.report_file_path) await supabase.storage.from('reconciliations').remove([h.report_file_path])
    // Delete DB record
    await supabase.from('reconciliations').delete().eq('id', h.id)
    setHistory(prev => prev.filter(r => r.id !== h.id))
  }

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
      ) : (<>
        {/* Category filter pills */}
        {(() => {
          const categories = [...new Set(history.map(h => h.invoice_category || 'Other'))].sort()
          return categories.length > 1 ? (
            <div className="flex gap-2 mb-4 flex-wrap">
              <button
                onClick={() => setCategoryFilter(null)}
                className={`px-3 py-1.5 text-xs font-medium rounded-full border transition-colors ${!categoryFilter ? 'bg-navy text-white border-navy' : 'bg-white text-gray-600 border-gray-300 hover:bg-gray-50'}`}
              >All ({history.length})</button>
              {categories.map(cat => {
                const count = history.filter(h => (h.invoice_category || 'Other') === cat).length
                return (
                  <button key={cat} onClick={() => setCategoryFilter(categoryFilter === cat ? null : cat)}
                    className={`px-3 py-1.5 text-xs font-medium rounded-full border transition-colors ${categoryFilter === cat ? 'bg-navy text-white border-navy' : 'bg-white text-gray-600 border-gray-300 hover:bg-gray-50'}`}
                  >{cat} ({count})</button>
                )
              })}
            </div>
          ) : null
        })()}
        <div className="bg-white rounded-xl border border-gray-200 overflow-hidden">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-gray-200 bg-gray-50">
                <th className="px-4 py-3 text-left font-medium text-gray-600">Category</th>
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
              {history.filter(h => !categoryFilter || (h.invoice_category || 'Other') === categoryFilter).map(h => {
                const issues = h.mismatch_count + h.not_found_count + h.missing_count
                const isExpanded = expanded === h.id
                return (
                  <>{/* eslint-disable-next-line react/jsx-key */}
                    <tr
                      key={h.id}
                      className={`border-b border-gray-100 hover:bg-gray-50 cursor-pointer ${isExpanded ? 'bg-gray-50' : ''}`}
                      onClick={() => setExpanded(isExpanded ? null : h.id)}
                    >
                      <td className="px-4 py-3">
                        <span className={`inline-flex px-2 py-0.5 rounded-full text-xs font-medium ${
                          h.invoice_category === 'Staff Uniforms' ? 'bg-blue-100 text-blue-700'
                          : h.invoice_category === 'Guest Laundry' ? 'bg-purple-100 text-purple-700'
                          : h.invoice_category === 'Bathrobes' ? 'bg-teal-100 text-teal-700'
                          : h.invoice_category === 'Napkins' ? 'bg-amber-100 text-amber-700'
                          : h.invoice_category === 'HSK Linen' ? 'bg-green-100 text-green-700'
                          : 'bg-gray-100 text-gray-700'
                        }`}>{h.invoice_category || 'Other'}</span>
                      </td>
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
                    {isExpanded && (
                      <tr key={`${h.id}-detail`}>
                        <td colSpan={10} className="px-6 py-4 bg-gray-50/50">
                          {/* Download buttons */}
                          <div className="flex items-center gap-2 mb-4">
                            <span className="text-xs font-semibold text-gray-500 uppercase mr-2">Documents</span>
                            {h.invoice_file_path && (
                              <button
                                onClick={(e) => { e.stopPropagation(); downloadInvoice(h) }}
                                className="flex items-center gap-1.5 px-3 py-1.5 text-xs font-medium text-navy bg-navy/5 border border-navy/10 rounded-lg hover:bg-navy/10 transition-colors"
                              >
                                <FileText className="w-3.5 h-3.5" />
                                Invoice PDF
                              </button>
                            )}
                            <button
                              onClick={(e) => { e.stopPropagation(); exportExcel(h) }}
                              className="flex items-center gap-1.5 px-3 py-1.5 text-xs font-medium text-green-700 bg-green-50 border border-green-200 rounded-lg hover:bg-green-100 transition-colors"
                            >
                              <FileSpreadsheet className="w-3.5 h-3.5" />
                              Excel Report
                            </button>
                            {h.report_file_path && (
                              <button
                                onClick={(e) => { e.stopPropagation(); downloadReport(h) }}
                                className="flex items-center gap-1.5 px-3 py-1.5 text-xs font-medium text-purple-700 bg-purple-50 border border-purple-200 rounded-lg hover:bg-purple-100 transition-colors"
                              >
                                <FileText className="w-3.5 h-3.5" />
                                PDF Report
                              </button>
                            )}
                            <div className="flex-1" />
                            <button
                              onClick={(e) => { e.stopPropagation(); deleteRecord(h) }}
                              className="flex items-center gap-1.5 px-3 py-1.5 text-xs font-medium text-red-600 bg-red-50 border border-red-200 rounded-lg hover:bg-red-100 transition-colors"
                            >
                              <Trash2 className="w-3.5 h-3.5" />
                              Delete
                            </button>
                          </div>

                          {h.department_breakdown && h.department_breakdown.length > 0 && <>
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
                          </>}
                        </td>
                      </tr>
                    )}
                  </>
                )
              })}
            </tbody>
          </table>
        </div>
      </>)}
    </div>
  )
}
