-- Supabase-only SQL (applied to Supabase project in Phase D1, NOT applied locally)

-- Enable Row Level Security (RLS) on all tables per Spec Section 4
ALTER TABLE offices ENABLE ROW LEVEL SECURITY;
ALTER TABLE office_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE services ENABLE ROW LEVEL SECURITY;
ALTER TABLE counters ENABLE ROW LEVEL SECURITY;
ALTER TABLE counter_services ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE queue_state ENABLE ROW LEVEL SECURITY;
ALTER TABLE tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE token_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE allowed_transitions ENABLE ROW LEVEL SECURITY;
ALTER TABLE service_stats ENABLE ROW LEVEL SECURITY;
ALTER TABLE counter_service_stats ENABLE ROW LEVEL SECURITY;
ALTER TABLE office_calendar ENABLE ROW LEVEL SECURITY;
ALTER TABLE eta_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE priority_checks ENABLE ROW LEVEL SECURITY;
ALTER TABLE devices ENABLE ROW LEVEL SECURITY;
ALTER TABLE notification_outbox ENABLE ROW LEVEL SECURITY;
ALTER TABLE idempotency_keys ENABLE ROW LEVEL SECURITY;
ALTER TABLE counter_events ENABLE ROW LEVEL SECURITY;

-- Spec Section 4 RLS Policy:
-- "RLS enabled on every table; no policies except SELECT on queue_state for authenticated."
CREATE POLICY "Allow authenticated read queue_state"
ON queue_state
FOR SELECT
TO authenticated
USING (true);

-- Enable Supabase Realtime publication on queue_state only
-- "Rule 3 Exception: Flutter and React may open a read-only Supabase Realtime subscription on queue_state only."
ALTER PUBLICATION supabase_realtime ADD TABLE queue_state;

-- Supabase auth user signup trigger creating profiles row with role CITIZEN
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, role, phone, name, language)
    VALUES (
        new.id,
        COALESCE((new.raw_app_meta_data->>'role')::actor_type_enum, 'CITIZEN'::actor_type_enum),
        new.phone,
        new.raw_user_meta_data->>'name',
        COALESCE(new.raw_user_meta_data->>'language', 'en')
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
