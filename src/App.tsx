import { HashRouter, Routes, Route, Navigate } from 'react-router-dom'
import { useAuth } from './hooks/useAuth'
import Login from './pages/Login'
import Layout from './components/Layout'
import Orders from './pages/Orders'
import Reports from './pages/Reports'
import SettingsPage from './pages/Settings'

export default function App() {
  const { user, dashboardUser, loading, signIn, signOut } = useAuth()

  if (loading) {
    return (
      <div className="min-h-screen bg-navy flex items-center justify-center">
        <div className="w-8 h-8 border-2 border-gold/30 border-t-gold rounded-full animate-spin" />
      </div>
    )
  }

  if (!user) {
    return <Login onLogin={signIn} />
  }

  return (
    <HashRouter>
      <Routes>
        <Route element={<Layout user={dashboardUser} onSignOut={signOut} />}>
          <Route path="/" element={<Orders />} />
          <Route path="/reports" element={<Reports />} />
          <Route path="/settings" element={<SettingsPage currentUser={dashboardUser} />} />
          <Route path="*" element={<Navigate to="/" replace />} />
        </Route>
      </Routes>
    </HashRouter>
  )
}
