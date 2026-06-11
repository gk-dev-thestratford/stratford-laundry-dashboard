import type { Order } from '../types'

/**
 * Canonical order-cost calculation — the single source of truth used by Reconciliation,
 * Reports, Orders and the orders table so every page agrees on the same number.
 *
 * Rule: prefer the sum of item prices (price_at_time × quantity_sent). But if an explicit
 * total_price was set (e.g. from an invoice "Update price") and diverges from the item
 * recalculation by more than a penny, trust total_price — item-price writes can silently
 * fail under RLS while the order total still saved. Falls back to total_price when there
 * are no priced items.
 */
export function computeOrderCost(o: Pick<Order, 'order_items' | 'total_price'>): number {
  if (o.order_items && o.order_items.length > 0) {
    const t = o.order_items.reduce((s, i) => s + (i.price_at_time ?? 0) * (i.quantity_sent ?? 0), 0)
    if (t > 0) {
      const itemTotal = Math.round(t * 100) / 100
      if (o.total_price != null && o.total_price > 0 && Math.abs(itemTotal - o.total_price) > 0.01) {
        return o.total_price
      }
      return itemTotal
    }
  }
  return o.total_price ?? 0
}
