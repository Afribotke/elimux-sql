-- ELIMUX INSTITUTION ONBOARDING PART 2: RLS POLICIES
-- Run AFTER 08a (Tables) has been executed.
-- Applications carry unreviewed contact info (email/phone), so — like
-- payments — all reads/writes go exclusively through the Express API using
-- the service_role key. No anon/public access, even for inserts: the public
-- onboarding form submits through POST /api/institutions/apply and
-- POST /api/programs/apply, not directly against Supabase.

ALTER TABLE institution_applications ENABLE ROW LEVEL SECURITY;
ALTER TABLE program_applications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admin full access institution_applications" ON institution_applications FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY "Admin full access program_applications" ON program_applications FOR ALL TO service_role USING (true) WITH CHECK (true);
