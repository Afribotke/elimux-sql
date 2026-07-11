-- ============================================================
-- ELIMUX 18: FIX institution_applications DRIFT
-- Run in Supabase SQL Editor. Idempotent (IF NOT EXISTS everywhere).
--
-- Context: 08a_applications_tables.sql defines created_institution_id
-- and updated_at on institution_applications, and both are referenced
-- by live code (admin.ts's approve-application endpoint sets
-- created_institution_id; 08c_applications_triggers.sql defines an
-- updated_at trigger for this table) - but neither column actually
-- exists in production. The approve-application endpoint has likely
-- been erroring on every call. institution_applications has 0 rows
-- (confirmed 2026-07-11), so this is a safe additive fix with no
-- backfill required.
-- ============================================================

ALTER TABLE institution_applications ADD COLUMN IF NOT EXISTS created_institution_id UUID REFERENCES institutions(id);
ALTER TABLE institution_applications ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

DROP TRIGGER IF EXISTS update_institution_applications_updated_at ON institution_applications;
CREATE TRIGGER update_institution_applications_updated_at
    BEFORE UPDATE ON institution_applications
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================
-- ELIMUX 18: analytics_events indexes
-- The table (id, event_type, user_device_id, metadata, created_at)
-- already exists in production. Admin dashboard queries filter by
-- event_type and created_at ranges constantly, so index both.
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_analytics_events_type ON analytics_events(event_type);
CREATE INDEX IF NOT EXISTS idx_analytics_events_created ON analytics_events(created_at);
CREATE INDEX IF NOT EXISTS idx_analytics_events_device ON analytics_events(user_device_id);
