import { useState } from 'react'
import { Hotel } from 'lucide-react'

interface LoginProps {
  onLogin: (email: string, password: string) => Promise<{ error: Error | null }>
}

export default function Login({ onLogin }: LoginProps) {
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    setError('')
    setLoading(true)
    const { error } = await onLogin(email, password)
    if (error) setError(error.message)
    setLoading(false)
  }

  return (
    <div className="min-h-screen bg-navy flex items-center justify-center p-4">
      <div className="w-full max-w-md">
        <div className="text-center mb-8">
          <div className="inline-flex items-center justify-center w-16 h-16 rounded-full bg-gold/20 mb-4">
            <Hotel className="w-8 h-8 text-gold" />
          </div>
          <h1 className="text-2xl font-semibold text-white">The Stratford</h1>
          <p className="text-gray-400 mt-1">Laundry Management Dashboard</p>
        </div>

        <form onSubmit={handleSubmit} className="bg-white rounded-xl shadow-xl p-8">
          <h2 className="text-lg font-semibold text-gray-900 mb-6">Sign in to your account</h2>

          {error && (
            <div className="mb-4 p-3 bg-red-50 border border-red-200 rounded-lg text-sm text-red-700">
              {error}
            </div>
          )}

          <div className="space-y-4">
            <div>
              <label htmlFor="email" className="block text-sm font-medium text-gray-700 mb-1">
                Email address
              </label>
              <input
                id="email"
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                required
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-gold focus:border-transparent text-sm"
                placeholder="you@stratford.com"
              />
            </div>

            <div>
              <label htmlFor="password" className="block text-sm font-medium text-gray-700 mb-1">
                Password
              </label>
              <input
                id="password"
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                required
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-gold focus:border-transparent text-sm"
                placeholder="Enter your password"
              />
            </div>

            <button
              type="submit"
              disabled={loading}
              className="w-full py-2.5 bg-navy text-white font-medium rounded-lg hover:bg-navy-light transition-colors disabled:opacity-50 text-sm"
            >
              {loading ? 'Signing in...' : 'Sign in'}
            </button>
          </div>

          <p className="mt-4 text-xs text-gray-500 text-center">
            Contact your administrator for account access
          </p>
        </form>

        <p className="text-center text-gray-500 text-xs mt-6">
          The Stratford Hotel &middot; Laundrevo Limited
        </p>
      </div>
    </div>
  )
}
