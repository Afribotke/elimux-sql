-- 17_programs_verification_flags.sql
-- Adds provenance/verification flags to programs so the frontend can disclose
-- which listings are confirmed vs AI-generated placeholder data.
-- Safe to re-run (ADD COLUMN IF NOT EXISTS).

ALTER TABLE programs ADD COLUMN IF NOT EXISTS is_ai_generated BOOLEAN DEFAULT false;
ALTER TABLE programs ADD COLUMN IF NOT EXISTS is_verified BOOLEAN DEFAULT false;

CREATE INDEX IF NOT EXISTS idx_programs_ai_generated ON programs(is_ai_generated);
