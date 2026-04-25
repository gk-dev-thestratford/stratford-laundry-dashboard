import { useState, useMemo } from 'react'
import { useNavigate } from 'react-router-dom'
import { Activity, ChevronDown, ChevronRight, X, Send, CheckCircle, Trash2, Sparkles } from 'lucide-react'
import { format } from 'date-fns'
import { useSessionActivity, type ActivityEntry } from '../hooks/useSessionActivity'
import { ORDER_STATUS_LABELS, ORDER_STATUS_COLORS } from '../types'
import type { OrderStatus } from '../types'

// Workflow-priority order of category groups in the panel.
const STATUS_GROUP_ORDER: OrderStatus[] = [
  'received',
  'collected',
  'in_processing',
  'approved',
  'picked_up',
  'submitted',
  'rejected',
  'completed',
]

interface ActivityPanelProps {
  /** When true the user is signed in — the panel only renders if authenticated */
  enabled: boolean
  /** Called when the user clicks "Send Daily Report" — wired in a later step */
  onSendReport?: () => void
}

export default function ActivityPanel({ enabled, onSendReport }: ActivityPanelProps) {
  const { todaysEntries, sessionStartedAt, reportSentToday, clear } = useSessionActivity()
  const [open, setOpen] = useState(false)
  const [collapsedGroups, setCollapsedGroups] = useState<Set<string>>(new Set())
  const navigate = useNavigate()

  const grouped = useMemo(() => groupEntries(todaysEntries), [todaysEntries])
  const totalActions = todaysEntries.filter((e) => e.type !== 'daily_report_sent').length

  if (!enabled) return null

  function toggleGroup(key: string) {
    setCollapsedGroups((prev) => {
      const next = new Set(prev)
      if (next.has(key)) next.delete(key)
      else next.add(key)
      return next
    })
  }

  function handleEntryClick(entry: ActivityEntry) {
    if (entry.orderId) {
      navigate(`/orders?open=${entry.orderId}`)
      setOpen(false)
    }
  }

  function handleClear() {
    if (window.confirm("Clear today's activity from this panel? This won't undo any actions — it just hides the log.")) {
      clear()
    }
  }

  // ── Collapsed tab on the right edge ──
  if (!open) {
    return (
      <button
        onClick={() => setOpen(true)}
        className="fixed right-0 top-1/2 -translate-y-1/2 z-40 bg-navy hover:bg-navy-light text-white pl-2 pr-1.5 py-3 rounded-l-lg shadow-lg flex flex-col items-center gap-2 transition-colors"
        title="Open activity panel"
      >
        <Activity className="w-4 h-4" />
        {totalActions > 0 && (
          <span className="bg-gold text-navy text-[10px] font-bold rounded-full min-w-[18px] h-[18px] flex items-center justify-center px-1">
            {totalActions}
          </span>
        )}
        <span className="[writing-mode:vertical-rl] rotate-180 text-[11px] font-medium tracking-wider">
          Activity
        </span>
      </button>
    )
  }

  // ── Expanded drawer ──
  return (
    <>
      <div
        className="fixed inset-0 bg-black/20 z-40"
        onClick={() => setOpen(false)}
        aria-hidden
      />
      <aside className="fixed right-0 top-0 bottom-0 z-50 w-80 bg-white dark:bg-gray-800 shadow-2xl flex flex-col border-l border-gray-200 dark:border-gray-700">
        {/* Header */}
        <div className="px-4 py-3 border-b border-gray-200 dark:border-gray-700 flex items-center justify-between">
          <div>
            <h2 className="font-semibold text-gray-900 dark:text-white text-sm flex items-center gap-2">
              <Activity className="w-4 h-4 text-navy" />
              Today's Activity
            </h2>
            <p className="text-[11px] text-gray-500 dark:text-gray-400 mt-0.5">
              {sessionStartedAt
                ? `Since ${format(new Date(sessionStartedAt), 'HH:mm')} • ${totalActions} action${totalActions !== 1 ? 's' : ''}`
                : 'No activity yet'}
            </p>
          </div>
          <button
            onClick={() => setOpen(false)}
            className="p-1 hover:bg-gray-100 dark:hover:bg-gray-700 rounded-lg"
          >
            <X className="w-4 h-4 text-gray-500" />
          </button>
        </div>

        {/* Send Daily Report */}
        <div className="px-4 py-3 border-b border-gray-200 dark:border-gray-700">
          {reportSentToday ? (
            <div className="flex items-center gap-2 px-3 py-2 bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-800 rounded-lg">
              <CheckCircle className="w-4 h-4 text-green-600 flex-shrink-0" />
              <p className="text-xs text-green-800 dark:text-green-300 flex-1">Daily report sent today</p>
              <button
                onClick={onSendReport}
                className="text-[11px] text-green-700 hover:text-green-900 underline"
              >
                Resend
              </button>
            </div>
          ) : (
            <button
              onClick={onSendReport}
              disabled={!onSendReport || totalActions === 0}
              className="w-full flex items-center justify-center gap-2 px-3 py-2.5 bg-navy hover:bg-navy-light text-white text-sm font-medium rounded-lg disabled:bg-gray-300 disabled:cursor-not-allowed transition-colors"
            >
              <Send className="w-4 h-4" />
              Send Daily Report
            </button>
          )}
        </div>

        {/* Entries */}
        <div className="flex-1 overflow-y-auto px-2 py-2">
          {totalActions === 0 ? (
            <div className="flex flex-col items-center justify-center h-full text-center px-6 text-gray-400 dark:text-gray-500">
              <Sparkles className="w-8 h-8 mb-3 text-gray-300 dark:text-gray-600" />
              <p className="text-sm font-medium text-gray-600 dark:text-gray-400">No activity yet</p>
              <p className="text-[11px] mt-1">Approve, collect, receive or save napkin returns and they'll appear here.</p>
            </div>
          ) : (
            <>
              {STATUS_GROUP_ORDER.map((status) => {
                const items = grouped.byStatus.get(status)
                if (!items || items.length === 0) return null
                const isCollapsed = collapsedGroups.has(status)
                const colorClass = ORDER_STATUS_COLORS[status] || 'bg-gray-100 text-gray-800'
                const groupCount = countTickets(items)
                return (
                  <GroupSection
                    key={status}
                    label={ORDER_STATUS_LABELS[status]}
                    badgeClass={colorClass}
                    count={groupCount}
                    collapsed={isCollapsed}
                    onToggle={() => toggleGroup(status)}
                  >
                    {items.map((entry) => (
                      <EntryRow key={entry.id} entry={entry} onClick={handleEntryClick} />
                    ))}
                  </GroupSection>
                )
              })}

              {grouped.napkins.length > 0 && (
                <GroupSection
                  label="Napkin Returns"
                  badgeClass="bg-purple-100 text-purple-800"
                  count={grouped.napkins.reduce((s, e) => s + (e.napkinQty ?? 0), 0)}
                  collapsed={collapsedGroups.has('napkins')}
                  onToggle={() => toggleGroup('napkins')}
                >
                  {grouped.napkins.map((entry) => (
                    <NapkinRow key={entry.id} entry={entry} />
                  ))}
                </GroupSection>
              )}
            </>
          )}
        </div>

        {/* Footer */}
        {totalActions > 0 && (
          <div className="px-4 py-2 border-t border-gray-200 dark:border-gray-700">
            <button
              onClick={handleClear}
              className="text-[11px] text-gray-500 hover:text-red-600 dark:hover:text-red-400 flex items-center gap-1 transition-colors"
            >
              <Trash2 className="w-3 h-3" />
              Clear panel
            </button>
          </div>
        )}
      </aside>
    </>
  )
}

interface GroupedEntries {
  byStatus: Map<OrderStatus, ActivityEntry[]>
  napkins: ActivityEntry[]
}

function groupEntries(entries: ActivityEntry[]): GroupedEntries {
  const byStatus = new Map<OrderStatus, ActivityEntry[]>()
  const napkins: ActivityEntry[] = []
  for (const entry of entries) {
    if (entry.type === 'daily_report_sent') continue
    if (entry.type === 'napkin_return') {
      napkins.push(entry)
      continue
    }
    if (entry.status) {
      const list = byStatus.get(entry.status) ?? []
      list.push(entry)
      byStatus.set(entry.status, list)
    }
  }
  return { byStatus, napkins }
}

function countTickets(entries: ActivityEntry[]): number {
  return entries.reduce((sum, e) => sum + (e.bulkCount ?? 1), 0)
}

interface GroupSectionProps {
  label: string
  badgeClass: string
  count: number
  collapsed: boolean
  onToggle: () => void
  children: React.ReactNode
}

function GroupSection({ label, badgeClass, count, collapsed, onToggle, children }: GroupSectionProps) {
  return (
    <div className="mb-1">
      <button
        onClick={onToggle}
        className="w-full flex items-center gap-2 px-2 py-1.5 hover:bg-gray-50 dark:hover:bg-gray-700/50 rounded-md transition-colors"
      >
        {collapsed ? (
          <ChevronRight className="w-3.5 h-3.5 text-gray-400" />
        ) : (
          <ChevronDown className="w-3.5 h-3.5 text-gray-500" />
        )}
        <span className={`px-2 py-0.5 rounded-full text-[11px] font-medium ${badgeClass}`}>
          {label}
        </span>
        <span className="text-[11px] text-gray-500 dark:text-gray-400 ml-auto">
          {count}
        </span>
      </button>
      {!collapsed && <div className="pl-6 pr-2 py-1 space-y-1">{children}</div>}
    </div>
  )
}

interface EntryRowProps {
  entry: ActivityEntry
  onClick: (entry: ActivityEntry) => void
}

function EntryRow({ entry, onClick }: EntryRowProps) {
  const time = format(new Date(entry.timestamp), 'HH:mm')

  if (entry.type === 'bulk_status_change') {
    return (
      <div className="flex items-center gap-2 px-2 py-1.5 text-xs rounded-md bg-gray-50 dark:bg-gray-700/30">
        <span className="font-medium text-gray-700 dark:text-gray-200">
          {entry.bulkCount ?? 0} orders
        </span>
        <span className="text-gray-400 ml-auto">{time}</span>
      </div>
    )
  }

  return (
    <button
      onClick={() => onClick(entry)}
      className="w-full flex items-center gap-2 px-2 py-1.5 text-xs rounded-md hover:bg-navy/5 dark:hover:bg-white/5 transition-colors group"
    >
      <span className="font-mono font-medium text-gray-700 dark:text-gray-200 group-hover:text-navy dark:group-hover:text-white">
        #{entry.docketNumber}
      </span>
      <span className="text-gray-400 ml-auto">{time}</span>
    </button>
  )
}

function NapkinRow({ entry }: { entry: ActivityEntry }) {
  const time = format(new Date(entry.timestamp), 'HH:mm')
  return (
    <div className="flex items-center gap-2 px-2 py-1.5 text-xs rounded-md bg-gray-50 dark:bg-gray-700/30">
      <span className="text-gray-700 dark:text-gray-200 truncate flex-1">
        {entry.napkinDeptName || 'Unknown dept'}
      </span>
      <span className="font-medium text-purple-700 dark:text-purple-300">
        +{entry.napkinQty ?? 0}
      </span>
      <span className="text-gray-400">{time}</span>
    </div>
  )
}
