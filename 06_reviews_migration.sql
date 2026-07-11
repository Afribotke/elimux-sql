-- ============================================================
-- ELIMUX MIGRATION: Reviews - rich fields + optional user auth
-- Run in Supabase SQL Editor. Safe to re-run (idempotent).
--
-- Context: a `reviews` table already existed (01a_tables.sql) with an
-- anonymous shape (reviewer_name/reviewer_email, no auth). This migrates
-- it in place to support BOTH anonymous and authenticated reviews:
-- user_id is nullable, reviewer_name/reviewer_email are kept for the
-- anonymous path.
-- ============================================================

-- Step 1: Add new columns to existing reviews table
ALTER TABLE reviews
  ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS title VARCHAR(255),
  ADD COLUMN IF NOT EXISTS pros TEXT[],
  ADD COLUMN IF NOT EXISTS cons TEXT[],
  ADD COLUMN IF NOT EXISTS would_recommend BOOLEAN,
  ADD COLUMN IF NOT EXISTS helpful_count INTEGER DEFAULT 0,
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- Step 2: Rename comment -> content (keep data). RENAME COLUMN can't be
-- combined with other ALTER TABLE clauses in one statement, and this must
-- be safe to re-run once already renamed - hence the guarded DO block.
-- (comment is already TEXT in the live schema, so no type change needed.)
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'reviews' AND column_name = 'comment'
  ) AND NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'reviews' AND column_name = 'content'
  ) THEN
    ALTER TABLE reviews RENAME COLUMN comment TO content;
  END IF;
END $$;

-- Step 3: Add review_target_check constraint (only if not exists)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE constraint_name = 'review_target_check' AND table_name = 'reviews'
  ) THEN
    ALTER TABLE reviews ADD CONSTRAINT review_target_check
      CHECK ((program_id IS NOT NULL) OR (institution_id IS NOT NULL));
  END IF;
END $$;

-- Step 4: Create additional indexes (with IF NOT EXISTS).
-- idx_reviews_institution and idx_reviews_rating already exist from
-- 01a_tables.sql - left untouched, these are net-new, non-colliding names.
CREATE INDEX IF NOT EXISTS idx_reviews_program ON reviews(program_id);
CREATE INDEX IF NOT EXISTS idx_reviews_user ON reviews(user_id);
CREATE INDEX IF NOT EXISTS idx_reviews_helpful ON reviews(helpful_count DESC);

-- Step 5: Create/update rating views
CREATE OR REPLACE VIEW program_ratings AS
SELECT
    program_id,
    COUNT(*) as review_count,
    AVG(rating)::NUMERIC(3,2) as avg_rating
FROM reviews
WHERE is_active = true
GROUP BY program_id;

CREATE OR REPLACE VIEW institution_ratings AS
SELECT
    institution_id,
    COUNT(*) as review_count,
    AVG(rating)::NUMERIC(3,2) as avg_rating
FROM reviews
WHERE is_active = true
GROUP BY institution_id;

-- Step 6: RLS policies (only if not exists)
ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;

-- "Public insert reviews" (WITH CHECK true) already exists from
-- 01b_rls.sql and permits ANY insert, including a spoofed user_id -
-- Postgres OR's multiple permissive policies for the same command, so a
-- separate "auth.uid() = user_id" policy alongside it would be silently
-- ineffective. Replace it with one check that covers both paths: allow
-- anonymous inserts (user_id null) and authenticated inserts only under
-- the caller's own id.
DROP POLICY IF EXISTS "Public insert reviews" ON reviews;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Insert own or anonymous reviews' AND tablename = 'reviews') THEN
    CREATE POLICY "Insert own or anonymous reviews" ON reviews
      FOR INSERT WITH CHECK (user_id IS NULL OR auth.uid() = user_id);
  END IF;

  -- "Public read reviews" (is_active = true) already exists from 01b_rls.sql
  -- and covers this - not duplicating it here.

  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Users can update own reviews' AND tablename = 'reviews') THEN
    CREATE POLICY "Users can update own reviews" ON reviews FOR UPDATE USING (auth.uid() = user_id);
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Users can delete own reviews' AND tablename = 'reviews') THEN
    CREATE POLICY "Users can delete own reviews" ON reviews FOR DELETE USING (auth.uid() = user_id);
  END IF;
END $$;

-- Step 7: Atomic helpful-count increment. The reviews API calls this via RPC
-- and falls back to a non-atomic read-then-write if it's missing - this makes
-- the primary path work and avoids that race under concurrent clicks.
CREATE OR REPLACE FUNCTION increment_helpful_count(review_id UUID)
RETURNS void AS $$
BEGIN
  UPDATE reviews SET helpful_count = helpful_count + 1 WHERE id = review_id;
END;
$$ LANGUAGE plpgsql;

-- Step 8: Correction - live-tested the reviews API and found user_id had
-- ended up NOT NULL with reviewer_name/reviewer_email dropped (auth-required
-- shape), which blocks all review submission since no login flow exists in
-- the frontend. Reverting to the agreed Option 2 shape: nullable user_id,
-- anonymous fields restored.
ALTER TABLE reviews ALTER COLUMN user_id DROP NOT NULL;
ALTER TABLE reviews ADD COLUMN IF NOT EXISTS reviewer_name VARCHAR(100);
ALTER TABLE reviews ADD COLUMN IF NOT EXISTS reviewer_email VARCHAR(255);
