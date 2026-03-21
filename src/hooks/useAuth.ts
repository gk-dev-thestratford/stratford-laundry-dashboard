import { useState, useEffect, useCallback } from 'react'
import { supabase } from '../lib/supabase'
import type { User, Session } from '@supabase/supabase-js'
import type { DashboardUser } from '../types'

export function useAuth() {
  const [user, setUser] = useState<User | null>(null)
  const [dashboardUser, setDashboardUser] = useState<DashboardUser | null>(null)
  const [session, setSession] = useState<Session | null>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    supabase.auth.getSession().then(({ data: { session } }) => {
      setSession(session)
      setUser(session?.user ?? null)
      if (session?.user) fetchDashboardUser(session.user.id)
      else setLoading(false)
    })

    const { data: { subscription } } = supabase.auth.onAuthStateChange((_event, session) => {
      setSession(session)
      setUser(session?.user ?? null)
      if (session?.user) fetchDashboardUser(session.user.id)
      else {
        setDashboardUser(null)
        setLoading(false)
      }
    })

    return () => subscription.unsubscribe()
  }, [])

  async function fetchDashboardUser(userId: string) {
    const { data } = await supabase
      .from('dashboard_users')
      .select('*')
      .eq('id', userId)
      .single()
    setDashboardUser(data)
    setLoading(false)
  }

  const signIn = useCallback(async (email: string, password: string) => {
    const { error } = await supabase.auth.signInWithPassword({ email, password })
    return { error }
  }, [])

  const signOut = useCallback(async () => {
    await supabase.auth.signOut()
    setUser(null)
    setDashboardUser(null)
    setSession(null)
  }, [])

  return { user, dashboardUser, session, loading, signIn, signOut }
}
