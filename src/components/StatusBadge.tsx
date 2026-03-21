import { ORDER_STATUS_LABELS, ORDER_STATUS_COLORS } from '../types'
import type { OrderStatus } from '../types'

interface StatusBadgeProps {
  status: OrderStatus
  className?: string
}

export default function StatusBadge({ status, className = '' }: StatusBadgeProps) {
  return (
    <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${ORDER_STATUS_COLORS[status]} ${className}`}>
      {ORDER_STATUS_LABELS[status]}
    </span>
  )
}
