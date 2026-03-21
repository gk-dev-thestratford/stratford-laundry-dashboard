import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'GET, POST, DELETE, OPTIONS',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders })
  }

  try {
    // Verify the caller is authenticated
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return new Response(JSON.stringify({ error: 'Not authenticated' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

    // Client with caller's token to verify they're an admin
    const callerClient = createClient(supabaseUrl, serviceKey, {
      global: { headers: { Authorization: authHeader } },
    })

    const { data: { user: caller } } = await callerClient.auth.getUser(
      authHeader.replace('Bearer ', '')
    )
    if (!caller) {
      return new Response(JSON.stringify({ error: 'Invalid token' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // Admin client with service role for user management
    const adminClient = createClient(supabaseUrl, serviceKey)

    // Check caller is an admin
    const { data: callerProfile } = await adminClient
      .from('dashboard_users')
      .select('role')
      .eq('id', caller.id)
      .single()

    if (!callerProfile || callerProfile.role !== 'admin') {
      return new Response(JSON.stringify({ error: 'Admin access required' }), {
        status: 403,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const url = new URL(req.url)

    // GET — list all dashboard users
    if (req.method === 'GET') {
      const { data: users, error } = await adminClient
        .from('dashboard_users')
        .select('*')
        .order('name')

      if (error) throw error

      return new Response(JSON.stringify(users), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // POST — create a new user
    if (req.method === 'POST') {
      const { email, password, name, role = 'viewer', department_id = null } = await req.json()

      if (!email || !password || !name) {
        return new Response(JSON.stringify({ error: 'email, password, and name are required' }), {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        })
      }

      // Create auth user
      const { data: authData, error: authError } = await adminClient.auth.admin.createUser({
        email,
        password,
        email_confirm: true,
      })

      if (authError) {
        return new Response(JSON.stringify({ error: authError.message }), {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        })
      }

      // Insert dashboard_users record
      const { data: dashUser, error: dashError } = await adminClient
        .from('dashboard_users')
        .insert({
          id: authData.user.id,
          email,
          name,
          role,
          department_id,
          is_active: true,
        })
        .select()
        .single()

      if (dashError) {
        // Rollback: delete auth user if dashboard insert fails
        await adminClient.auth.admin.deleteUser(authData.user.id)
        throw dashError
      }

      return new Response(JSON.stringify(dashUser), {
        status: 201,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // DELETE — remove a user
    if (req.method === 'DELETE') {
      const userId = url.searchParams.get('id')
      if (!userId) {
        return new Response(JSON.stringify({ error: 'id parameter required' }), {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        })
      }

      // Prevent self-deletion
      if (userId === caller.id) {
        return new Response(JSON.stringify({ error: 'Cannot delete your own account' }), {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        })
      }

      // Delete from dashboard_users
      await adminClient.from('dashboard_users').delete().eq('id', userId)

      // Delete auth user
      const { error: authError } = await adminClient.auth.admin.deleteUser(userId)
      if (authError) {
        return new Response(JSON.stringify({ error: authError.message }), {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        })
      }

      return new Response(JSON.stringify({ success: true }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    return new Response(JSON.stringify({ error: 'Method not allowed' }), {
      status: 405,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  } catch (err) {
    return new Response(JSON.stringify({ error: err.message }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})
