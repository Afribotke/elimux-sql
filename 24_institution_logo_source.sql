-- Migration 24: Track provenance of institutions.logo_url
--
-- Distinguishes manually-curated overrides and institution self-service
-- uploads from logos populated by the automated scraper
-- (elimux-backend/scripts/fetch_logos.js), so the scraper knows which
-- rows it must never overwrite.

ALTER TABLE institutions
  ADD COLUMN IF NOT EXISTS logo_source text;

COMMENT ON COLUMN institutions.logo_source IS
  'Provenance of logo_url: manual (hand-curated override), institution_upload (set via the institution self-service portal), scraped (auto-fetched from the institution website by fetch_logos.js), or NULL (unset).';

-- Protect the KIPS Technical College manual override (added 2026-07-19)
-- so the logo scraper skips it.
UPDATE institutions
SET logo_source = 'manual'
WHERE logo_url = '/logos/kips-technical-college.jpg'
  AND logo_source IS NULL;
