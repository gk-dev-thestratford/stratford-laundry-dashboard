-- Schedule the daily-report edge function to run at 2pm UK time every day.
-- UK is UTC+0 in winter (GMT) and UTC+1 in summer (BST).
-- We schedule at 14:00 UTC which is 2pm GMT / 3pm BST.
-- Adjust to 13:00 UTC if you want 2pm BST during summer.
-- Using 14:00 UTC as a reasonable year-round compromise.

CREATE EXTENSION IF NOT EXISTS pg_cron WITH SCHEMA extensions;

SELECT cron.schedule(
  'daily-laundry-report',
  '0 14 * * *',  -- Every day at 14:00 UTC (2pm GMT / 3pm BST)
  $$
  SELECT net.http_post(
    url := 'https://uhpiwiaadzwgmnusjinv.supabase.co/functions/v1/daily-report',
    body := '{}',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVocGl3aWFhZHp3Z21udXNqaW52Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQwNDM3NDksImV4cCI6MjA4OTYxOTc0OX0.5LFYslZcDuqgC8A7KrAguM6JmjvN1RxQfccEP4qCss8'
    )
  );
  $$
);
