-- 21_institution_accounts.sql
-- The institution_accounts table (added directly via Supabase dashboard during
-- institution-portal Phase 1, untracked until now - see README "Known drift")
-- backs institutionAuth (elimux-backend/src/middleware/institution-auth.ts):
-- Supabase-Auth JWT -> institution_accounts row by user_id -> status check.
-- One row per institution (a claimed institution can't be re-claimed) and one
-- row per user (a user can't claim a second institution), both enforced here
-- as UNIQUE constraints, not just app-level checks.
--
-- Reconstructed from live production schema (project ohlgjvenwekpbpkykutz) via
-- PostgREST OpenAPI introspection + pg_constraint/pg_indexes, 2026-07-18 -
-- column types, defaults, constraints, and indexes below match exactly what's
-- running. Notably: unlike advertisers.user_id, this table's user_id has NO
-- foreign key to auth.users in production (UNIQUE only) - don't assume one
-- exists when writing queries or new migrations against this table.
--
-- Safe to re-run (IF NOT EXISTS throughout).

CREATE TABLE IF NOT EXISTS institution_accounts (
    id UUID PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
    institution_id UUID NOT NULL UNIQUE REFERENCES institutions(id) ON DELETE CASCADE,
    user_id UUID NOT NULL UNIQUE,
    contact_name VARCHAR(255),
    email VARCHAR(255) NOT NULL,
    role VARCHAR(50) NOT NULL DEFAULT 'admin',
    status VARCHAR(20) NOT NULL DEFAULT 'pending',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_institution_accounts_user_id ON institution_accounts(user_id);
CREATE INDEX IF NOT EXISTS idx_institution_accounts_institution_id ON institution_accounts(institution_id);
CREATE INDEX IF NOT EXISTS idx_institution_accounts_status ON institution_accounts(status);

-- RLS enabled, no policies defined (matches institution_applications' pattern
-- in 08b_applications_rls.sql) - all access goes through elimux-backend's
-- service_role client; anon/authenticated roles have no direct table access.
ALTER TABLE institution_accounts ENABLE ROW LEVEL SECURITY;
