-- ============================================================
-- ELIMUX MIGRATION: Reviews moderation - default to 'pending'
-- Run in Supabase SQL Editor. Safe to re-run (idempotent).
--
-- Context: `reviews.status` (varchar(20), default 'approved') exists in
-- production but was never added by a tracked migration - it was created
-- directly in the Supabase dashboard at some point. This file both closes
-- that drift gap (guarded ADD COLUMN, no-op in prod) and changes the
-- default going forward so new reviews require admin approval before
-- showing up publicly, matching the GET /api/reviews filter in
-- elimux-backend/src/routes/reviews.ts (.eq('status', 'approved')).
-- ============================================================

-- Step 1: Ensure the column exists (no-op in prod, needed for any env that
-- only ran the tracked migrations up to 06_reviews_migration.sql).
ALTER TABLE reviews ADD COLUMN IF NOT EXISTS status VARCHAR(20) DEFAULT 'approved';

-- Step 2: Change the default for new rows going forward. Existing rows keep
-- their current status - this does not retroactively hide already-approved
-- reviews.
ALTER TABLE reviews ALTER COLUMN status SET DEFAULT 'pending';

-- Step 3: RLS - "Public read reviews" (from 01b_rls.sql) currently only
-- checks is_active = true and does not check status, so any client reading
-- with an anon/authenticated key (not the service_role key elimux-backend
-- uses) would see pending/rejected reviews too. Tighten it to match the
-- app-level filter.
--
-- Admin access is intentionally NOT added as a separate auth.uid()-based
-- policy here: admin_users is keyed by email with no FK to auth.users, so
-- there's no auth.uid() to match against. The existing "Admin full access
-- reviews" policy (FOR ALL TO service_role USING true) already covers
-- admin/moderation access - any admin dashboard must talk to Supabase via
-- a server-side route using the service role key, the same pattern
-- elimux-backend already uses. Never expose the service role key to a
-- browser client.
DROP POLICY IF EXISTS "Public read reviews" ON reviews;
CREATE POLICY "Public read reviews" ON reviews
  FOR SELECT USING (is_active = true AND status = 'approved');
