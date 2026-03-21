import { Search, ChevronLeft, ChevronRight } from 'lucide-react'
import { MONTHS, ORDER_STATUS_LABELS } from '../types'
import type { OrderStatus, Department } from '../types'
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
          value={filters.department}
          onChange={(e) => onChange({ ...filters, department: e.target.value })}
          className="px-3 py-2 text-sm border border-gray-200 rounded-lg bg-white focus:outline-none focus:ring-2 focus:ring-gold"
        >
          <option value="all">All Departments</option>
          {departments.map((d) => (
            <option key={d.id} value={d.id}>{d.name}</option>
          ))}
        </select>
      </div>
    </div>
  )
}
