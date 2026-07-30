-- ELIMUX: public read access for accreditation_bodies
-- Run once in Supabase SQL Editor.
--
-- Why: accreditation_bodies was never added to the public-read policy set in
-- 01b_rls.sql, which covers every other public-catalog table (countries,
-- institution_types, program_categories, institutions, programs, reviews,
-- sponsor_ads) with the same "Public read <table>" / is_active = true
-- pattern. As a result the anon key gets 0 rows back from
-- accreditation_bodies even though is_active = true rows exist and the
-- table is meant to be public - confirmed empirically (service-role sees 3
-- rows, anon key sees []). That breaks two public pages:
--   * /accreditation-bodies (list) - renders "No accreditation bodies"
--   * /accreditation-bodies/[id] (detail) - the .single() lookup returns no
--     row, so the page 404s via notFound()
-- institutions and institution_accreditations already have working public
-- policies, so only this table was missing one.
--
-- This does not touch RLS state we can't already infer from the symptom:
-- anon getting 0 rows where service-role gets 3 means either RLS is on with
-- no permissive policy for anon, or on with a policy that excludes anon.
-- ENABLE ROW LEVEL SECURITY is a no-op if already enabled, and the
-- drop-then-create pattern (CREATE POLICY has no IF NOT EXISTS - only DROP
-- POLICY supports IF EXISTS) makes this safe to re-run and safe against an
-- existing policy under the same or a different name being in the way.

ALTER TABLE accreditation_bodies ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public read accreditation_bodies" ON accreditation_bodies;
CREATE POLICY "Public read accreditation_bodies" ON accreditation_bodies FOR SELECT USING (is_active = true);

-- Service role (the backend's Express API) always has full access,
-- independent of the public policy above - matches 07b_payments_rls.sql.
DROP POLICY IF EXISTS "Admin full access accreditation_bodies" ON accreditation_bodies;
CREATE POLICY "Admin full access accreditation_bodies" ON accreditation_bodies FOR ALL TO service_role USING (true) WITH CHECK (true);

-- Verify: run this as the anon role (e.g. via the Supabase SQL Editor's
-- "Run as" role switcher, or re-curl the frontend's anon key) - expect all
-- 3 seeded bodies (CUE, NITA, TVETA) back, not [].
SELECT id, code, name, is_active FROM accreditation_bodies ORDER BY code;
