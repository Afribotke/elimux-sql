-- ELIMUX WHITE-LABEL CAREERS PAGE: employers.slug
-- Adds a unique, URL-safe slug per employer for /careers/[slug].
-- Run once in Supabase SQL Editor.

ALTER TABLE employers ADD COLUMN IF NOT EXISTS slug TEXT UNIQUE;

-- Backfill: base slug from company name (or name, whichever column is populated),
-- de-duplicated by appending the row's short id when a collision would occur.
WITH base AS (
  SELECT
    id,
    LOWER(REGEXP_REPLACE(COALESCE(company_name, name, 'employer'), '[^a-zA-Z0-9]+', '-', 'g')) AS base_slug
  FROM employers
  WHERE slug IS NULL
),
numbered AS (
  SELECT
    id,
    base_slug,
    ROW_NUMBER() OVER (PARTITION BY base_slug ORDER BY id) AS rn
  FROM base
)
UPDATE employers e
SET slug = CASE WHEN n.rn = 1 THEN n.base_slug ELSE n.base_slug || '-' || SUBSTRING(n.id::text, 1, 8) END
FROM numbered n
WHERE e.id = n.id;
