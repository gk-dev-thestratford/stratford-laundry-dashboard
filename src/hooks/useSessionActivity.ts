import { useEffect, useState } from 'react'
import { supabase } from '../lib/supabase'
import type { OrderStatus } from '../types'

export type ActivityType =
  | 'status_change'
  | 'bulk_status_change'
  | 'napkin_return'
  | 'daily_report_sent'

export interface ActivityEntry {
  id: string
  timestamp: string
  type: ActivityType
  status?: OrderStatus
  orderId?: string
  docketNumber?: string
  bulkOrderIds?: string[]
  bulkCount?: number
  napkinDeptName?: string
  napkinQty?: number
  napkinNote?: string
  reportSummary?: { collected: number; received: number; outstanding: number; napkins: number }
}

const CHANNEL_NAME = 'stratford-activity'
const STORAGE_PREFIX = 'stratford-activity-'
const ENTRY_TTL_MS = 24 * 60 * 60 * 1000 // 24h — auto-purge older entries on load

interface BroadcastMessage {
  type: 'add' | 'clear'
  userId: string
  entry?: ActivityEntry
}

// ── Module-level singleton state shared across all hook instances in this tab ──
let moduleEntries: ActivityEntry[] = []
let moduleUserId: string | null = null
let broadcastChannel: BroadcastChannel | null = null
let authSubscribed = false
let storageListenerAttached = false
const subscribers = new Set<() => void>()

function getStorageKey(uid: string | null): string | null {
  return uid ? `${STORAGE_PREFIX}${uid}` : null
}

function purgeStale(entries: ActivityEntry[]): ActivityEntry[] {
  const cutoff = Date.now() - ENTRY_TTL_MS
  return entries.filter((e) => new Date(e.timestamp).getTime() >= cutoff)
}

function loadFromStorage(): ActivityEntry[] {
  const key = getStorageKey(moduleUserId)
  if (!key) return []
  try {
    const raw = localStorage.getItem(key)
    if (!raw) return []
    const parsed = JSON.parse(raw)
    if (!Array.isArray(parsed)) return []
    return purgeStale(parsed)
  } catch {
    return []
  }
}

function saveToStorage() {
  const key = getStorageKey(moduleUserId)
  if (!key) return
  try {
    localStorage.setItem(key, JSON.stringify(moduleEntries))
  } catch (err) {
    console.error('Activity panel: failed to persist', err)
  }
}

function notify() {
  subscribers.forEach((cb) => cb())
}

function setUser(uid: string | null) {
  if (uid === moduleUserId) return
  // Logout: wipe the previous user's storage
  if (moduleUserId && !uid) {
    const key = getStorageKey(moduleUserId)
    if (key) {
      try { localStorage.removeItem(key) } catch { /* ignore */ }
    }
  }
  moduleUserId = uid
  moduleEntries = loadFromStorage()
  ensureChannel()
  notify()
}

function ensureChannel() {
  if (broadcastChannel) return
  if (typeof window === 'undefined' || !('BroadcastChannel' in window)) return
  broadcastChannel = new BroadcastChannel(CHANNEL_NAME)
  broadcastChannel.onmessage = (e: MessageEvent<BroadcastMessage>) => {
    const msg = e.data
    if (!msg || msg.userId !== moduleUserId) return
    if (msg.type === 'add' && msg.entry) {
      if (moduleEntries.some((p) => p.id === msg.entry!.id)) return
      moduleEntries = purgeStale([msg.entry, ...moduleEntries])
      saveToStorage()
      notify()
    } else if (msg.type === 'clear') {
      moduleEntries = []
      saveToStorage()
      notify()
    }
  }
}

function ensureAuthSubscription() {
  if (authSubscribed) return
  authSubscribed = true
  supabase.auth.getSession().then(({ data: { session } }) => {
    setUser(session?.user?.id ?? null)
  })
  supabase.auth.onAuthStateChange((event, session) => {
    if (event === 'SIGNED_OUT') {
      setUser(null)
    } else {
      setUser(session?.user?.id ?? null)
    }
  })
}

function ensureStorageListener() {
  if (storageListenerAttached || typeof window === 'undefined') return
  storageListenerAttached = true
  window.addEventListener('storage', (e: StorageEvent) => {
    const key = getStorageKey(moduleUserId)
    if (!key || e.key !== key) return
    try {
      const next = e.newValue ? JSON.parse(e.newValue) : []
      if (Array.isArray(next)) {
        moduleEntries = purgeStale(next)
        notify()
      }
    } catch {
      /* ignore parse errors */
    }
  })
}

function generateId(): string {
  return `${Date.now()}-${Math.random().toString(36).slice(2, 8)}`
}

// ── Public API (exported standalone for non-hook callers) ──

export function logActivity(entry: Omit<ActivityEntry, 'id' | 'timestamp'>) {
  if (!moduleUserId) return
  const full: ActivityEntry = {
    ...entry,
    id: generateId(),
    timestamp: new Date().toISOString(),
  }
  moduleEntries = purgeStale([full, ...moduleEntries])
  saveToStorage()
  notify()
  broadcastChannel?.postMessage({
    type: 'add',
    entry: full,
    userId: moduleUserId,
  } satisfies BroadcastMessage)
}

export function clearActivity() {
  if (!moduleUserId) return
  moduleEntries = []
  saveToStorage()
  notify()
  broadcastChannel?.postMessage({
    type: 'clear',
    userId: moduleUserId,
  } satisfies BroadcastMessage)
}

function isToday(iso: string): boolean {
  const d = new Date(iso)
  const now = new Date()
  return (
    d.getFullYear() === now.getFullYear() &&
    d.getMonth() === now.getMonth() &&
    d.getDate() === now.getDate()
  )
}

export function useSessionActivity() {
  ensureAuthSubscription()
  ensureStorageListener()

  const [, force] = useState(0)
  useEffect(() => {
    const cb = () => force((n) => n + 1)
    subscribers.add(cb)
    return () => {
      subscribers.delete(cb)
    }
  }, [])

  const todaysEntries = moduleEntries.filter((e) => isToday(e.timestamp))
  const reportSentToday = todaysEntries.some((e) => e.type === 'daily_report_sent')

  return {
    entries: moduleEntries,
    todaysEntries,
    reportSentToday,
    sessionStartedAt:
      todaysEntries.length > 0
        ? todaysEntries[todaysEntries.length - 1].timestamp
        : null,
    addEntry: logActivity,
    clear: clearActivity,
    userId: moduleUserId,
  }
}
