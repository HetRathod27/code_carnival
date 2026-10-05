-- =============================================================================
-- QueueLess — Supabase Project Configuration & Migration
-- =============================================================================
-- Core Rule 1: The API owns all business logic.
-- Core Rule 3 (Realtime Exception): Flutter and React may open a read-only
-- Supabase Realtime subscription on queue_state only. No other direct DB access.
-- =============================================================================

-- 1. Enable Required Supabase Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_cron";
CREATE EXTENSION IF NOT EXISTS "pg_net";

-- 2. Configure Supabase Realtime for queue_state ONLY
-- Rule 3 Exception: Realtime carries queue_state aggregates only.
-- Clients refetch their own state from the FastAPI API.
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' AND tablename = 'queue_state'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE queue_state;
    END IF;
END $$;

-- 3. Row Level Security (RLS) Enforcement
-- Ensure RLS is active on all tables
ALTER TABLE IF EXISTS offices ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS services ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS counters ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS queue_state ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS token_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS appointments ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS office_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS office_calendar ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS devices ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS notification_outbox ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS eta_log ENABLE ROW LEVEL SECURITY;

-- 4. RLS Policies: Read-Only queue_state for Realtime Subscribers
DROP POLICY IF EXISTS "queue_state_read_public" ON queue_state;
CREATE POLICY "queue_state_read_public"
    ON queue_state
    FOR SELECT
    TO anon, authenticated
    USING (true);

-- Disallow direct client writes to queue_state (API service role or direct backend only)
DROP POLICY IF EXISTS "queue_state_no_client_insert" ON queue_state;
DROP POLICY IF EXISTS "queue_state_no_client_update" ON queue_state;
DROP POLICY IF EXISTS "queue_state_no_client_delete" ON queue_state;

-- Read-only policies for public metadata if accessed via Supabase client
DROP POLICY IF EXISTS "offices_read_public" ON offices;
CREATE POLICY "offices_read_public"
    ON offices
    FOR SELECT
    TO anon, authenticated
    USING (active = true);

DROP POLICY IF EXISTS "services_read_public" ON services;
CREATE POLICY "services_read_public"
    ON services
    FOR SELECT
    TO anon, authenticated
    USING (active = true);

-- Disallow client direct access to personal or token records (Must use API)
DROP POLICY IF EXISTS "tokens_no_direct_client_access" ON tokens;
DROP POLICY IF EXISTS "appointments_no_direct_client_access" ON appointments;
DROP POLICY IF EXISTS "token_events_no_direct_client_access" ON token_events;

-- 5. Periodic Scheduler Job via pg_cron + pg_net
-- Executes /internal/tick every 1 minute to sweep expired buffers,
-- auto-requeue no-shows, update ETAs, and flush outbox notifications.
-- Replace <API_URL> and <INTERNAL_SECRET> with your deployed environment variables.
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_cron') THEN
        -- Remove existing job if present
        PERFORM cron.unschedule('queueless-tick-every-minute')
        WHERE EXISTS (
            SELECT 1 FROM cron.job WHERE jobname = 'queueless-tick-every-minute'
        );

        -- Schedule minute tick
        PERFORM cron.schedule(
            'queueless-tick-every-minute',
            '* * * * *',
            $cron$
            SELECT net.http_post(
                url := current_setting('app.api_url', true) || '/internal/tick',
                headers := jsonb_build_object(
                    'Content-Type', 'application/json',
                    'X-Internal-Secret', current_setting('app.internal_secret', true)
                ),
                body := '{}'::jsonb
            );
            $cron$
        );
    END IF;
END $$;
