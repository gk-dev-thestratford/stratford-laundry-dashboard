import { NavLink, Outlet } from 'react-router-dom'
import { Hotel, ClipboardList, BarChart3, Users, Package, FileCheck, Clock, LogOut, Menu, X, Sun, Moon } from 'lucide-react'
import { useState, useEffect } from 'react'
import type { DashboardUser } from '../types'

interface LayoutProps {
  user: DashboardUser | null
  onSignOut: () => void
}

const navItems = [
  { to: '/', icon: BarChart3, label: 'Reports' },
  { to: '/orders', icon: ClipboardList, label: 'Orders' },
  { to: '/user-management', icon: Users, label: 'User Management' },
  { to: '/catalogue', icon: Package, label: 'Catalogue' },
  { to: '/reconciliation', icon: FileCheck, label: 'Reconciliation' },
  { to: '/reconciliation/history', icon: Clock, label: 'Recon History' },
]

function useDarkMode() {
  const [dark, setDark] = useState(() => localStorage.getItem('theme') === 'dark')

  useEffect(() => {
    const root = document.documentElement
    if (dark) {
      root.classList.add('dark')
      localStorage.setItem('theme', 'dark')
    } else {
      root.classList.remove('dark')
      localStorage.setItem('theme', 'light')
    }
  }, [dark])

  return [dark, () => setDark(d => !d)] as const
}

export default function Layout({ user, onSignOut }: LayoutProps) {
  const [sidebarOpen, setSidebarOpen] = useState(false)
  const [dark, toggleDark] = useDarkMode()

  return (
    <div className="min-h-screen bg-gray-50 dark:bg-gray-900 flex">
      {/* Mobile overlay */}
      {sidebarOpen && (
        <div className="fixed inset-0 bg-black/50 z-40 lg:hidden" onClick={() => setSidebarOpen(false)} />
      )}

      {/* Sidebar */}
      <aside className={`
        fixed inset-y-0 left-0 z-50 w-64 bg-navy text-white flex flex-col transition-transform lg:translate-x-0 lg:static lg:z-auto
        ${sidebarOpen ? 'translate-x-0' : '-translate-x-full'}
      `}>
        <div className="p-6 flex items-center gap-3 border-b border-white/10">
          <div className="w-9 h-9 rounded-lg bg-gold/20 flex items-center justify-center">
            <Hotel className="w-5 h-5 text-gold" />
          </div>
          <div>
            <h1 className="font-semibold text-sm">The Stratford</h1>
            <p className="text-[11px] text-gray-400">Laundry Dashboard</p>
          </div>
          <button className="ml-auto lg:hidden" onClick={() => setSidebarOpen(false)}>
            <X className="w-5 h-5" />
          </button>
        </div>

        <nav className="flex-1 p-4 space-y-1">
          {navItems.map(({ to, icon: Icon, label }) => (
            <NavLink
              key={to}
              to={to}
              onClick={() => setSidebarOpen(false)}
              className={({ isActive }) =>
                `flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium transition-colors ${
                  isActive
                    ? 'bg-gold/20 text-gold'
                    : 'text-gray-300 hover:bg-white/5 hover:text-white'
                }`
              }
            >
              <Icon className="w-5 h-5" />
              {label}
            </NavLink>
          ))}
        </nav>

        <div className="p-4 border-t border-white/10">
          <div className="flex items-center gap-3 mb-3">
            <div className="w-8 h-8 rounded-full bg-gold/20 flex items-center justify-center text-xs font-semibold text-gold">
              {user?.name?.charAt(0) || '?'}
            </div>
            <div className="flex-1 min-w-0">
              <p className="text-sm font-medium truncate">{user?.name || 'User'}</p>
              <p className="text-[11px] text-gray-400 truncate">{user?.email}</p>
            </div>
          </div>
          <button
            onClick={onSignOut}
            className="flex items-center gap-2 w-full px-3 py-2 text-sm text-gray-400 hover:text-white hover:bg-white/5 rounded-lg transition-colors"
          >
            <LogOut className="w-4 h-4" />
            Sign out
          </button>
        </div>
      </aside>

      {/* Main content */}
      <div className="flex-1 flex flex-col min-w-0">
        {/* Top bar */}
        <header className="bg-white dark:bg-gray-800 border-b border-gray-200 dark:border-gray-700 px-4 py-3 flex items-center gap-3">
          <button className="lg:hidden" onClick={() => setSidebarOpen(true)}>
            <Menu className="w-6 h-6 text-gray-600 dark:text-gray-300" />
          </button>
          <h1 className="font-semibold text-gray-900 dark:text-white lg:hidden">The Stratford</h1>
          <div className="flex-1" />
          <button
            onClick={toggleDark}
            className="p-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-700 transition-colors"
            title={dark ? 'Switch to light mode' : 'Switch to dark mode'}
          >
            {dark
              ? <Sun className="w-5 h-5 text-amber-400" />
              : <Moon className="w-5 h-5 text-gray-500" />}
          </button>
        </header>

        <main className="flex-1 p-4 lg:p-8 overflow-auto">
          <Outlet />
        </main>
      </div>
    </div>
  )
}
