/// Supabase configuration — fill in with actual values from Supabase dashboard
class SupabaseConfig {
  static const String url = 'https://uhpiwiaadzwgmnusjinv.supabase.co';
  static const String anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVocGl3aWFhZHp3Z21udXNqaW52Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQwNDM3NDksImV4cCI6MjA4OTYxOTc0OX0.5LFYslZcDuqgC8A7KrAguM6JmjvN1RxQfccEP4qCss8';

  /// Whether Supabase is configured (not using placeholder values)
  static bool get isConfigured =>
      !url.contains('YOUR_PROJECT') && !anonKey.contains('YOUR_ANON_KEY');
}
