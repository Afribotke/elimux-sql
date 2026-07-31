-- ============================================
-- Migration 29: Backfill institution_accreditations.accreditation_body_id
-- from accreditation_number prefix
-- ============================================
--
-- Context: all 16 rows in institution_accreditations have
-- accreditation_body_id NULL, so nothing is linked to a body. The rows do carry
-- the body in their accreditation_number prefix (CUE/UON/001, TVETA/ENP/007,
-- CUE/JKUAT/004, ...), and accreditation_bodies holds exactly three codes:
-- CUE, NITA, TVETA. This infers the FK from that prefix.
--
-- Depends on 28_accreditation_bodies_align_schema.sql having been applied.
--
-- CAVEAT: this derives a relationship from a string convention, not from
-- recorded data. Run the preview first and eyeball every row before applying.
-- Two things the preview will surface:
--   * inferred_body_id NULL  -> the prefix matches no body code; that row is
--     left untouched by the UPDATE and stays NULL.
--   * a row appearing twice  -> two bodies share a code prefix, in which case
--     UPDATE ... FROM would pick one arbitrarily. Not possible with the current
--     three codes, but worth checking if bodies were added.
-- Rows whose code is NULL never match, since NULL || '/%' is NULL.

-- Preview: show what would be updated
SELECT
  ia.id,
  ia.accreditation_number,
  ia.accreditation_body_id,
  ab.id AS inferred_body_id,
  ab.code,
  ab.name
FROM institution_accreditations ia
LEFT JOIN accreditation_bodies ab
  ON ia.accreditation_number LIKE ab.code || '/%'
WHERE ia.accreditation_body_id IS NULL;

-- Apply backfill
UPDATE institution_accreditations ia
SET accreditation_body_id = ab.id
FROM accreditation_bodies ab
WHERE ia.accreditation_body_id IS NULL
  AND ia.accreditation_number LIKE ab.code || '/%';

-- Verify: should show 0 rows with NULL accreditation_body_id
SELECT COUNT(*) AS null_count FROM institution_accreditations WHERE accreditation_body_id IS NULL;

-- If null_count is not 0, list the stragglers and set them by hand:
-- SELECT id, accreditation_number FROM institution_accreditations
-- WHERE accreditation_body_id IS NULL;
