-- 25_platform_settings_and_ad_verticals.sql
-- Gate A for Skolex Harvest Task 3 (Partners & Advertisers homepage section).
-- NOT YET APPLIED - drafted for founder review, run manually in Supabase SQL
-- Editor per project convention (elimux-sql/README.md "Applying a new migration").
--
-- What this does:
--   1. platform_settings - a small key/value config table so prices and
--      feature toggles are never hardcoded in frontend/backend code (founder
--      directive). Seeded with the two values Task 3 needs.
--   2. ad_campaigns.vertical - which industry vertical a campaign belongs to,
--      so the homepage ads section can group/tab by vertical. Defaults
--      existing rows to 'education' (verified 2026-07-21: ad_campaigns has 0
--      rows in production today, so this default is a no-op in practice, but
--      is set anyway for schema correctness/future-proofing).
--   3. ad_campaigns creative fields the homepage cards need that don't exist
--      yet: chips (short tag list) and cta_label (button text). description
--      and headline already exist (verified against src/types/advertiser.ts)
--      and are reused as-is - see mapping table below.
--   4. Index to support the homepage query's status+vertical filter.
--
-- Idempotent: IF NOT EXISTS everywhere; the vertical CHECK constraint is
-- guarded by a DO block that only adds it if missing (same pattern as
-- 23_gamification_points_badge_action_type.sql).
--
-- Run in Supabase SQL Editor against project ohlgjvenwekpbpkykutz, then
-- verify with the SELECTs at the bottom before this file gets committed.

CREATE TABLE IF NOT EXISTS platform_settings (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL,
  description TEXT
);

INSERT INTO platform_settings (key, value, description) VALUES
  ('ad_placeholder_price_kes', '10000', 'Monthly entry ad price on homepage placeholder card'),
  ('show_public_impressions', 'false', 'Whether public ad cards display impression counts')
ON CONFLICT (key) DO NOTHING;

ALTER TABLE ad_campaigns ADD COLUMN IF NOT EXISTS vertical TEXT NOT NULL DEFAULT 'education';

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'ad_campaigns_vertical_check'
  ) THEN
    ALTER TABLE ad_campaigns
      ADD CONSTRAINT ad_campaigns_vertical_check
      CHECK (vertical IN ('education','finance','visa-agents','tvet','travel','technology','career','health'));
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_ad_campaigns_status_vertical ON ad_campaigns (status, vertical);

-- Creative fields the SponsoredCard/FeaturedCarousel components need that
-- ad_campaigns doesn't have yet. NULLABLE - existing rows are unaffected.
-- Mapping for the rest of what the cards need (already exist, no ALTER needed):
--   card name        -> ad_campaigns.headline (or advertisers.organization_name via join)
--   card description  -> ad_campaigns.description
--   card cta_url       -> ad_campaigns.target_url
--   featured eligibility -> ad_campaigns.status = 'active' (no separate boolean existed;
--                           see note below on why 'featured' is added anyway)
ALTER TABLE ad_campaigns ADD COLUMN IF NOT EXISTS chips TEXT[];
ALTER TABLE ad_campaigns ADD COLUMN IF NOT EXISTS cta_label TEXT;

-- 'featured' is a separate flag from status: an advertiser's campaign can be
-- 'active' (live, billable, counted) without being chosen for the homepage
-- carousel. Reusing status for both would conflate "is running" with
-- "is showcased" - two different decisions (one automatic, one curatorial).
ALTER TABLE ad_campaigns ADD COLUMN IF NOT EXISTS featured BOOLEAN NOT NULL DEFAULT false;

-- Verify after running:
-- SELECT key, value, description FROM platform_settings;
-- SELECT column_name, data_type, is_nullable, column_default
--   FROM information_schema.columns
--   WHERE table_name = 'ad_campaigns' AND column_name IN ('vertical','chips','cta_label','featured');
-- SELECT conname, pg_get_constraintdef(oid) FROM pg_constraint WHERE conname = 'ad_campaigns_vertical_check';
