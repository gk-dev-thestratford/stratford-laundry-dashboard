-- Migration: Create a database trigger that calls the notify-order-status edge function
-- on every INSERT to order_status_log, replacing the need for a dashboard webhook.

-- Enable the pg_net extension (HTTP client for Postgres)
CREATE EXTENSION IF NOT EXISTS pg_net WITH SCHEMA extensions;

-- Create the trigger function
CREATE OR REPLACE FUNCTION public.notify_order_status_trigger()
RETURNS TRIGGER AS $$
DECLARE
  edge_function_url TEXT;
  service_role_key TEXT;
  payload JSONB;
BEGIN
  -- Build the edge function URL from Supabase project
  edge_function_url := 'https://uhpiwiaadzwgmnusjinv.supabase.co/functions/v1/notify-order-status';

  -- Read the service role key from vault (or use the anon key for edge functions)
  -- Edge functions accept the anon key when called with the correct project URL
  service_role_key := current_setting('app.settings.service_role_key', true);

  -- If service_role_key is not set, try using the anon key from the JWT
  IF service_role_key IS NULL OR service_role_key = '' THEN
    service_role_key := current_setting('request.jwt.claim.sub', true);
  END IF;

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

  -- Fire HTTP POST to edge function (async, non-blocking)
  PERFORM extensions.http_post(
    edge_function_url,
    payload::TEXT,
    'application/json'
  );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Attach trigger to order_status_log
DROP TRIGGER IF EXISTS on_status_log_insert ON public.order_status_log;
CREATE TRIGGER on_status_log_insert
  AFTER INSERT ON public.order_status_log
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_order_status_trigger();
