-- 32_tveta_scraped_institutions.sql
-- Staging table for the TVETA accreditation-registry scraper. Rows land here
-- for admin review before being linked to (or promoted into) `institutions`.
-- This is separate from the existing AI program scraper (scraper.ts /
-- 'website'|'api'|'rss' sources table) - that one extracts program listings
-- from institution websites; this one cross-checks accreditation status
-- against the government TVETA registry. Complementary, not overlapping.
--
-- RLS is enabled with no policies - only the backend's service-role key can
-- read/write this table, matching contact_messages and the other admin-only
-- tables (see 26_contact_messages.sql).

CREATE TABLE IF NOT EXISTS tveta_scraped_institutions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    registration_number TEXT,
    category TEXT, -- National Polytechnic, Technical Vocational College, Vocational Training Centre
    institution_type TEXT, -- Public, Private
    county TEXT,
    status TEXT DEFAULT 'Active',
    source_url TEXT NOT NULL,
    scraped_at TIMESTAMPTZ DEFAULT NOW(),
    review_status TEXT NOT NULL DEFAULT 'pending' CHECK (review_status IN ('pending', 'approved', 'rejected', 'duplicate')),
    mapped_to_institution_id UUID REFERENCES institutions(id) ON DELETE SET NULL,
    raw_text_snippet TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_tveta_scraped_reg ON tveta_scraped_institutions(registration_number);
CREATE INDEX IF NOT EXISTS idx_tveta_scraped_review ON tveta_scraped_institutions(review_status);

ALTER TABLE tveta_scraped_institutions ENABLE ROW LEVEL SECURITY;

-- Additive, nullable fields on institutions so an approved TVETA match can
-- be reflected on the live institution record. Does not touch is_verified
-- (that flag is a general profile-verification signal used elsewhere, e.g.
-- programs.is_verified from the synthetic-programs pipeline - TVETA
-- accreditation is a distinct, narrower claim).
ALTER TABLE institutions ADD COLUMN IF NOT EXISTS tveta_registration_number TEXT;
ALTER TABLE institutions ADD COLUMN IF NOT EXISTS tveta_accredited BOOLEAN DEFAULT false;
-- tveta_status carries the raw TVETA registry status text (e.g. "Registered
-- and Licensed", "Expired License") separately from tveta_accredited, since
-- accredited=true only means "was approved via the review queue", not
-- "license currently valid". Already present on production (added directly
-- in the Supabase Dashboard, not through a tracked migration) - documented
-- here with IF NOT EXISTS so this file matches reality.
ALTER TABLE institutions ADD COLUMN IF NOT EXISTS tveta_status TEXT;
