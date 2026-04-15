import { Search, ChevronLeft, ChevronRight, Calendar, X } from 'lucide-react'
import { MONTHS, ORDER_STATUS_LABELS, ORDER_TYPE_LABELS } from '../types'
import type { OrderStatus, OrderType, Department } from '../types'
import type { Filters as FilterType } from '../hooks/useOrders'

interface FiltersProps {
  filters: FilterType
  departments: Department[]
  onChange: (filters: FilterType) => void
}

export default function Filters({ filters, departments, onChange }: FiltersProps) {
  return (
    <div className="space-y-4">
      {/* Year selector + Month quick-filters */}
      <div className="flex items-center gap-3">
        {/* Year picker */}
        <div className="flex items-center gap-1 bg-white border border-gray-200 rounded-lg px-1 py-0.5">
          <button
            onClick={() => onChange({ ...filters, year: filters.year - 1 })}
            className="p-1.5 hover:bg-gray-100 rounded transition-colors"
          >
            <ChevronLeft className="w-4 h-4 text-gray-600" />
          </button>
          <span className="px-2 text-sm font-semibold text-navy min-w-[48px] text-center">
            {filters.year}
          </span>
          <button
            onClick={() => onChange({ ...filters, year: filters.year + 1 })}
            className="p-1.5 hover:bg-gray-100 rounded transition-colors"
          >
            <ChevronRight className="w-4 h-4 text-gray-600" />
          </button>
        </div>

        {/* Month pills */}
        <div className="flex flex-wrap gap-1.5">
          {MONTHS.map((label, idx) => (
            <button
              key={label}
              onClick={() => onChange({ ...filters, month: idx })}
              className={`px-3 py-1.5 text-xs font-medium rounded-lg transition-colors ${
                filters.month === idx
                  ? 'bg-navy text-white'
                  : 'bg-white text-gray-600 border border-gray-200 hover:bg-gray-50'
              }`}
            >
              {label}
            </button>
          ))}
        </div>
      </div>

      {/* Dropdowns and search */}
      <div className="flex flex-wrap gap-3">
        <div className="relative flex-1 min-w-[200px]">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
          <input
            type="text"
            value={filters.search}
            onChange={(e) => onChange({ ...filters, search: e.target.value })}
            placeholder="Search docket, name, room..."
            className="w-full pl-9 pr-3 py-2 text-sm border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-gold focus:border-transparent bg-white"
          />
        </div>

        <select
          value={filters.status}
          onChange={(e) => onChange({ ...filters, status: e.target.value as OrderStatus | 'all' })}
          className="px-3 py-2 text-sm border border-gray-200 rounded-lg bg-white focus:outline-none focus:ring-2 focus:ring-gold"
        >
          <option value="all">All Statuses</option>
          {Object.entries(ORDER_STATUS_LABELS).map(([key, label]) => (
            <option key={key} value={key}>{label}</option>
          ))}
        </select>

        <select
          value={filters.orderType}
          onChange={(e) => onChange({ ...filters, orderType: e.target.value as OrderType | 'all' })}
          className="px-3 py-2 text-sm border border-gray-200 rounded-lg bg-white focus:outline-none focus:ring-2 focus:ring-gold"
        >
          <option value="all">All Types</option>
          {Object.entries(ORDER_TYPE_LABELS).map(([key, label]) => (
            <option key={key} value={key}>{label}</option>
          ))}
        </select>

        <select
          value={filters.department}
          onChange={(e) => onChange({ ...filters, department: e.target.value })}
          className="px-3 py-2 text-sm border border-gray-200 rounded-lg bg-white focus:outline-none focus:ring-2 focus:ring-gold"
        >
          <option value="all">All Departments</option>
          {departments.map((d) => (
            <option key={d.id} value={d.id}>{d.name}</option>
          ))}
        </select>

        <button
          onClick={() => onChange({ ...filters, outstanding: !filters.outstanding })}
          className={`px-3 py-2 text-sm rounded-lg border transition-colors ${
            filters.outstanding
              ? 'bg-amber-500 text-white border-amber-500'
              : 'bg-white text-gray-600 border-gray-200 hover:bg-gray-50'
          }`}
        >
          Outstanding Only
        </button>
      </div>

      {/* Date quick filters + custom range */}
      <div className="flex flex-wrap items-center gap-2">
        <Calendar className="w-4 h-4 text-gray-400" />
        {([['sent_today', 'Sent Today'], ['modified_today', 'Modified Today'], ['received_today', 'Received Today']] as const).map(([key, label]) => (
          <button
            key={key}
            onClick={() => onChange({ ...filters, quickDate: filters.quickDate === key ? '' : key, dateFrom: '', dateTo: '' })}
            className={`px-2.5 py-1.5 text-xs font-medium rounded-lg border transition-colors ${
              filters.quickDate === key
                ? 'bg-navy text-white border-navy'
                : 'bg-white text-gray-600 border-gray-200 hover:bg-gray-50'
            }`}
          >
            {label}
          </button>
        ))}
        <span className="text-gray-300 mx-1">|</span>
        <select
          value={filters.dateField}
          onChange={(e) => onChange({ ...filters, dateField: e.target.value as 'created' | 'modified' })}
          className="px-2 py-1.5 text-xs border border-gray-200 rounded-lg bg-white focus:outline-none focus:ring-2 focus:ring-gold"
        >
          <option value="created">Created</option>
          <option value="modified">Modified</option>
        </select>
        <input
          type="date"
          value={filters.dateFrom}
          onChange={(e) => onChange({ ...filters, dateFrom: e.target.value, quickDate: '' })}
          className="px-2 py-1.5 text-xs border border-gray-200 rounded-lg bg-white focus:outline-none focus:ring-2 focus:ring-gold"
        />
        <span className="text-xs text-gray-400">to</span>
        <input
          type="date"
          value={filters.dateTo}
          onChange={(e) => onChange({ ...filters, dateTo: e.target.value, quickDate: '' })}
          className="px-2 py-1.5 text-xs border border-gray-200 rounded-lg bg-white focus:outline-none focus:ring-2 focus:ring-gold"
        />
        {(filters.quickDate || filters.dateFrom || filters.dateTo) && (
          <button
            onClick={() => onChange({ ...filters, quickDate: '', dateFrom: '', dateTo: '' })}
            className="p-1.5 text-gray-400 hover:text-gray-600 hover:bg-gray-100 rounded"
            title="Clear date filters"
          >
            <X className="w-3.5 h-3.5" />
          </button>
        )}
      </div>
    </div>
  )
}
