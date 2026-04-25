import { useEffect, useState } from 'react'
import { CheckCircle, XCircle } from 'lucide-react'
import { ORDER_STATUS_LABELS } from '../types'
import type { OrderStatus } from '../types'

interface ToastPayload {
  status?: OrderStatus
  docketNumber?: string
  subtitle?: string
  customLabel?: string
  variant?: 'success' | 'error'
}

interface InternalToast extends ToastPayload {
  id: number
  visible: boolean
}

let showFn: ((p: ToastPayload) => void) | null = null

/**
 * Imperative API: call from anywhere to flash a centered confirmation overlay.
 * Stays visible ~1.2s with a 300ms fade in/out. <StatusToast /> must be mounted.
 */
export function showStatusToast(p: ToastPayload) {
  if (showFn) showFn(p)
  else console.warn('StatusToast not mounted yet — payload dropped:', p)
}

export default function StatusToast() {
  const [toast, setToast] = useState<InternalToast | null>(null)

  useEffect(() => {
    showFn = (p) => {
      const id = Date.now() + Math.random()
      setToast({ ...p, id, visible: false })
      // Fade in on next frame so the transition fires
      requestAnimationFrame(() => {
        requestAnimationFrame(() => {
          setToast((cur) => (cur && cur.id === id ? { ...cur, visible: true } : cur))
        })
      })
      // Hold 1.2s then fade out
      setTimeout(() => {
        setToast((cur) => (cur && cur.id === id ? { ...cur, visible: false } : cur))
      }, 1200)
      // Unmount after fade-out completes
      setTimeout(() => {
        setToast((cur) => (cur && cur.id === id ? null : cur))
      }, 1500)
    }
    return () => {
      showFn = null
    }
  }, [])

  if (!toast) return null

  const variant = toast.variant ?? (toast.status === 'rejected' ? 'error' : 'success')
  const Icon = variant === 'error' ? XCircle : CheckCircle
  const iconColorClass = variant === 'error' ? 'text-red-500' : 'text-green-500'
  const iconBgClass = variant === 'error' ? 'bg-red-50' : 'bg-green-50'
  const label = toast.customLabel ?? (toast.status ? ORDER_STATUS_LABELS[toast.status] : 'Done')

  return (
    <div
      className={`fixed inset-0 z-[100] flex items-center justify-center pointer-events-none transition-opacity duration-300 ${
        toast.visible ? 'opacity-100' : 'opacity-0'
      }`}
      aria-live="polite"
    >
      <div className="absolute inset-0 backdrop-blur-[2px] bg-black/20" />
      <div className="relative bg-white dark:bg-gray-800 rounded-2xl shadow-2xl px-10 py-8 flex flex-col items-center min-w-[280px] max-w-sm">
        <div className={`w-20 h-20 rounded-full flex items-center justify-center ${iconBgClass}`}>
          <Icon className={`w-12 h-12 ${iconColorClass}`} />
        </div>
        {toast.docketNumber && (
          <p className="mt-4 text-3xl font-bold font-mono text-navy dark:text-gold">#{toast.docketNumber}</p>
        )}
        <p className="mt-2 text-base font-semibold text-gray-900 dark:text-white">{label}</p>
        {toast.subtitle && (
          <p className="mt-1 text-sm text-gray-500 dark:text-gray-400 text-center">{toast.subtitle}</p>
        )}
      </div>
    </div>
  )
}
