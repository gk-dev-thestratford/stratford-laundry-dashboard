-- Fix: Use net.http_post with proper auth headers for the edge function

CREATE OR REPLACE FUNCTION public.notify_order_status_trigger()
RETURNS TRIGGER AS $$
DECLARE
  payload JSONB;
BEGIN
  -- Build the webhook payload (same format as Supabase database webhooks)
  payload := jsonb_build_object(
    'type', 'INSERT',
    'table', 'order_status_log',
    'record', jsonb_build_object(
      'id', NEW.id,
      'order_id', NEW.order_id,
      'status', NEW.status,
      'changed_by_name', NEW.changed_by_name,
      'reason', NEW.reason,
      'created_at', NEW.created_at
    )
  );

  -- Use pg_net to call the edge function with the anon key
  PERFORM net.http_post(
    url := 'https://uhpiwiaadzwgmnusjinv.supabase.co/functions/v1/notify-order-status',
    body := payload,
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVocGl3aWFhZHp3Z21udXNqaW52Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQwNDM3NDksImV4cCI6MjA4OTYxOTc0OX0.5LFYslZcDuqgC8A7KrAguM6JmjvN1RxQfccEP4qCss8'
    )
  );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
