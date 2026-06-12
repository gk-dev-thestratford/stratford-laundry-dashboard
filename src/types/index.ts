export interface Department {
  id: string
  code: string
  name: string
  can_submit_uniforms: boolean
  has_linen_items: boolean
  is_active: boolean
}

export interface CatalogueItem {
  id: string
  code: string
  name: string
  category: 'uniform' | 'hsk_linen' | 'fnb_linen'
  price: number | null
  department_id: string | null
  is_active: boolean
  sort_order: number
}

// Five-stage flow (renamed 2026-06-12 — staff found old names confusing):
//   submitted -> approved -> sent (laundry company collected) -> received (back
//   from laundry) -> collected (owner picked up). rejected/expired auxiliary.
// Old names: sent = collected + in_processing; received = received + completed;
//   collected = picked_up.
export type OrderStatus =
  | 'submitted'
  | 'approved'
  | 'rejected'
  | 'sent'
  | 'received'
  | 'collected'
  | 'expired'

export type OrderType = 'uniform' | 'hsk_linen' | 'fnb_linen' | 'guest_laundry'

export interface Order {
  id: string
  docket_number: string
  order_type: OrderType
  department_id: string | null
  staff_name: string | null
  email: string | null
  room_number: string | null
  guest_name: string | null
  bag_count: number | null
  notes: string | null
  status: OrderStatus
  total_price: number | null
  created_at: string
  updated_at: string
  synced_at: string | null
  reconciliation_id: string | null
  /** Set on outstanding child tickets created by a partial receipt — points at the original order */
  parent_order_id: string | null
  // Joined
  department?: Department
  order_items?: OrderItem[]
  status_log?: OrderStatusLog[]
}

export interface OrderItem {
  id: string
  order_id: string
  item_id: string | null
  item_name: string
  quantity_sent: number
  quantity_received: number | null
  price_at_time: number | null
}

export interface OrderStatusLog {
  id: string
  order_id: string
  status: string
  changed_by: string | null
  changed_by_name: string | null
  reason: string | null
  created_at: string
}

export interface DashboardUser {
  id: string
  email: string
  name: string
  department_id: string | null
  role: 'admin' | 'viewer'
  is_active: boolean
}

// NOTE: key order matters — drives the visual order of status filter dropdowns,
// the bulk-status dropdown, and the Activity panel category groups. Ordered to
// match daily procedure: Sent comes before Approved because staff first mark
// what came back (Sent -> Received), then send out approved items (Approved -> Sent).
export const ORDER_STATUS_LABELS: Record<OrderStatus, string> = {
  submitted: 'Submitted',
  sent: 'Sent',
  rejected: 'Rejected',
  approved: 'Approved',
  received: 'Received',
  collected: 'Collected',
  expired: 'Expired',
}

export const ORDER_STATUS_COLORS: Record<OrderStatus, string> = {
  submitted: 'bg-blue-100 text-blue-800',
  sent: 'bg-orange-100 text-orange-800',
  rejected: 'bg-red-100 text-red-800',
  approved: 'bg-green-100 text-green-800',
  received: 'bg-teal-100 text-teal-800',
  collected: 'bg-gray-100 text-gray-800',
  expired: 'bg-slate-100 text-slate-500',
}

export const ORDER_TYPE_LABELS: Record<OrderType, string> = {
  uniform: 'Staff Uniform',
  hsk_linen: 'HSK Linen',
  fnb_linen: 'F&B Linen',
  guest_laundry: 'Guest Laundry',
}

export const MONTHS = [
  'All', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
] as const

/** Tracks pending edits for bulk edit mode */
export interface BulkEdits {
  orders: Record<string, { docket_number?: string }>
  items: Record<string, { price_at_time?: number; order_id: string }>
}

export type AnnouncementSeverity = 'info' | 'warning' | 'critical'

export interface Announcement {
  id: string
  title: string
  body: string | null
  starts_at: string  // ISO timestamp (UTC)
  ends_at: string
  severity: AnnouncementSeverity
  is_active: boolean
  created_by: string | null
  created_at: string
  updated_at: string
}

export const ANNOUNCEMENT_SEVERITY_LABELS: Record<AnnouncementSeverity, string> = {
  info: 'Info',
  warning: 'Warning',
  critical: 'Critical',
}
