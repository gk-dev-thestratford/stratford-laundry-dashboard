import { createClient } from '@supabase/supabase-js'

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL || 'https://uhpiwiaadzwgmnusjinv.supabase.co'
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVocGl3aWFhZHp3Z21udXNqaW52Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQwNDM3NDksImV4cCI6MjA4OTYxOTc0OX0.5LFYslZcDuqgC8A7KrAguM6JmjvN1RxQfccEP4qCss8'

export const supabase = createClient(supabaseUrl, supabaseAnonKey)
