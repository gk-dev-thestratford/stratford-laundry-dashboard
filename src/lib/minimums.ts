// Goldstar weekly minimums and top-up rates — one place for the Reconciliation page and the
// Reports history, so both price "pieces short of the minimum" the same way.

export type ChefItemKey = 'chef jacket' | 'apron' | 'chef trouser'

export const CHEF_ITEM_KEYS: ChefItemKey[] = ['chef jacket', 'apron', 'chef trouser']

/** Weekly minimum pieces per chef item (Main Kitchen uniform contract). */
export const CHEF_WEEKLY_MINIMUMS: Record<ChefItemKey, number> = { 'chef jacket': 85, 'apron': 80, 'chef trouser': 80 }

/**
 * Per-piece top-up rates. Derived from the September 2026 top-up lines (they fit to the
 * penny) and confirmed by Georgi 2026-11-05 — chef trouser was previously £1.48 in the app.
 */
export const CHEF_TOPUP_RATES: Record<ChefItemKey, number> = { 'chef jacket': 1.41, 'apron': 0.99, 'chef trouser': 1.41 }

/** Weekly napkin minimum and the per-napkin rate. */
export const NAPKIN_WEEKLY_MINIMUM = 2500
export const NAPKIN_RATE = 0.215
