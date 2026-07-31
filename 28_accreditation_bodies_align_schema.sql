-- ELIMUX: align accreditation_bodies with the code that reads it
-- Run once in Supabase SQL Editor.
--
-- Why: GET /api/accreditation-bodies (list and /:id) returns 500 in production
-- with PGRST200 - "Could not find a relationship between 'accreditation_bodies'
-- and 'countries'". src/routes/accreditation-bodies.ts selects
-- `*, country:countries(name, flag_emoji)`, but the live table has no country_id
-- FK. It also filters on country_id and body_type, and
-- POST /api/admin/accreditation-bodies inserts description / country_id /
-- body_type (and rejects any request without body_type), so admin creation of
-- accreditation bodies cannot succeed either.
--
-- The live table drifted from 14_accreditation_bodies.sql, whose header wrongly
-- claims to document the applied schema:
--   live:     id, name, code, country (TEXT), website_url, contact_email,
--             is_active, created_at, logo_url
--   expected: id, name, code, description, logo_url, website_url,
--             country_id UUID REFERENCES countries(id), body_type, is_active,
--             created_at
--
-- This migration adds the three missing columns and backfills them. It does NOT
-- drop the existing `country` TEXT column - nothing needs it gone, and dropping
-- it would be irreversible. Note the API response deliberately shadows it: the
-- route aliases the embed as `country`, and AccreditationBodyRow in
-- src/lib/api.ts declares `country` as an object, so the embedded object is what
-- the frontend expects to see under that key.

-- 1. Add the missing columns. Idempotent; safe to re-run.
ALTER TABLE accreditation_bodies
  ADD COLUMN IF NOT EXISTS description TEXT,
  ADD COLUMN IF NOT EXISTS country_id UUID REFERENCES countries(id),
  ADD COLUMN IF NOT EXISTS body_type VARCHAR(50)
    CHECK (body_type IN ('university', 'tvet', 'secondary', 'professional'));

-- 2. Backfill country_id from the existing country text.
-- All three current rows are 'Kenya', which exists in countries.
UPDATE accreditation_bodies ab
SET country_id = c.id
FROM countries c
WHERE LOWER(c.name) = LOWER(ab.country)
  AND ab.country_id IS NULL;

-- 3. Backfill body_type for the three seeded Kenyan bodies.
-- CUE accredits universities; NITA and TVETA are both vocational/technical.
-- Matched on code so this is a no-op if the rows were renamed.
UPDATE accreditation_bodies
SET body_type = 'university'
WHERE code = 'CUE' AND body_type IS NULL;

UPDATE accreditation_bodies
SET body_type = 'tvet'
WHERE code IN ('NITA', 'TVETA') AND body_type IS NULL;

-- 4. Indexes named in 14_accreditation_bodies.sql that could not have been
-- created there, since the columns they cover did not exist.
CREATE INDEX IF NOT EXISTS idx_accreditation_bodies_country ON accreditation_bodies(country_id);
CREATE INDEX IF NOT EXISTS idx_accreditation_bodies_type ON accreditation_bodies(body_type);
CREATE INDEX IF NOT EXISTS idx_accreditation_bodies_active ON accreditation_bodies(is_active);

-- 5. Verify. Expect 3 rows, every one with a non-null country_id and body_type.
-- Any NULL here means a country name did not match countries.name, or a row
-- carries a code other than CUE / NITA / TVETA and needs body_type set by hand
-- (allowed values: university, tvet, secondary, professional).
SELECT
  code,
  name,
  country            AS country_text,
  country_id,
  body_type
FROM accreditation_bodies
ORDER BY code;
