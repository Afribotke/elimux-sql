-- ============================================================
-- ELIMUX 17c: SPONSOR ADS - SCHEMA EXTENSION
-- Run in Supabase SQL Editor. Idempotent (IF NOT EXISTS everywhere).
--
-- Context: institutions.is_featured / featured_until, sponsor_ads,
-- sponsors, and ad_clicks already exist (verified live 2026-07-11).
-- What's missing for the sponsor-ads feature to work end-to-end:
--   - sponsor_ads.sponsor_id  (FK -> sponsors, the ad's sponsor/advertiser)
--   - sponsor_ads.placement   (e.g. 'homepage', 'search')
--   - sponsor_ads.click_count (denormalized counter, incremented on click)
--   - sponsor_ads.updated_at  (+ trigger, matches institutions/programs pattern)
--   - ad_clicks.created_at    (click timestamp, needed to order/prune history)
-- Both sponsor_ads and sponsors have 0 rows (confirmed 2026-07-11), so this
-- is a safe additive change with no backfill required.
-- ============================================================

ALTER TABLE sponsor_ads ADD COLUMN IF NOT EXISTS sponsor_id UUID REFERENCES sponsors(id);
ALTER TABLE sponsor_ads ADD COLUMN IF NOT EXISTS placement VARCHAR(50);
ALTER TABLE sponsor_ads ADD COLUMN IF NOT EXISTS click_count INTEGER DEFAULT 0;
ALTER TABLE sponsor_ads ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

ALTER TABLE ad_clicks ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

CREATE INDEX IF NOT EXISTS idx_sponsor_ads_placement ON sponsor_ads(placement);
CREATE INDEX IF NOT EXISTS idx_sponsor_ads_active ON sponsor_ads(is_active);
CREATE INDEX IF NOT EXISTS idx_sponsor_ads_sponsor ON sponsor_ads(sponsor_id);
CREATE INDEX IF NOT EXISTS idx_ad_clicks_ad ON ad_clicks(ad_id);
CREATE INDEX IF NOT EXISTS idx_institutions_featured ON institutions(is_featured, featured_until);

-- updated_at trigger, reusing the shared function from 01c_triggers.sql
DROP TRIGGER IF EXISTS update_sponsor_ads_updated_at ON sponsor_ads;
CREATE TRIGGER update_sponsor_ads_updated_at
    BEFORE UPDATE ON sponsor_ads
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
