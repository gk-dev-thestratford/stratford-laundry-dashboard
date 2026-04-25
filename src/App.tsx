import { HashRouter, Routes, Route, Navigate } from 'react-router-dom'
import { useAuth } from './hooks/useAuth'
import Login from './pages/Login'
import Layout from './components/Layout'
import Orders from './pages/Orders'
import Reports from './pages/Reports'
import UserManagement from './pages/Settings'
import Catalogue from './pages/Catalogue'
import Reconciliation from './pages/Reconciliation'
import ReconciliationHistory from './pages/ReconciliationHistory'
import LinenPool from './pages/LinenPool'
import StatusToast from './components/StatusToast'

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
          <Route path="/" element={<Reports />} />
          <Route path="/orders" element={<Orders />} />
          <Route path="/user-management" element={<UserManagement currentUser={dashboardUser} />} />
          <Route path="/catalogue" element={<Catalogue />} />
          <Route path="/linen-pool" element={<LinenPool />} />
          <Route path="/reconciliation" element={<Reconciliation />} />
          <Route path="/reconciliation/history" element={<ReconciliationHistory />} />
          <Route path="*" element={<Navigate to="/" replace />} />
        </Route>
      </Routes>
      <StatusToast />
    </HashRouter>
  )
}
