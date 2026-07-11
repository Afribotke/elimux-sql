-- ============================================================
-- ELIMUX 17b: GAMIFICATION SCHEMA MIGRATION
-- Run in Supabase SQL Editor. Idempotent except Step 2 (referrals
-- rebuild), which is a one-time destructive change - safe only because
-- the table has 0 rows (confirmed 2026-07-10).
--
-- Context: gamification_points, gamification_badges, user_badges already
-- exist. This app has no auth (no signup/login anywhere in either repo),
-- so user_id stays a nullable UUID reserved for a future real-auth
-- migration, and device_id (same sha256(ip+ua) hash favorites.ts already
-- computes) is the identity actually used today. display_name/email are
-- optional and live inside the metadata JSONB column, not as new columns.
-- ============================================================

-- Step 1: device-based identity columns
ALTER TABLE gamification_points ADD COLUMN IF NOT EXISTS device_id TEXT;
ALTER TABLE user_badges ADD COLUMN IF NOT EXISTS device_id TEXT;

CREATE INDEX IF NOT EXISTS idx_gamification_points_device ON gamification_points(device_id);
CREATE INDEX IF NOT EXISTS idx_gamification_points_action ON gamification_points(action_type);
CREATE INDEX IF NOT EXISTS idx_user_badges_device ON user_badges(device_id);
CREATE INDEX IF NOT EXISTS idx_user_badges_badge ON user_badges(badge_id);

-- Step 2: rebuild referrals to the new shape (referral_code -> referrer_code,
-- points_earned -> reward_given boolean, + completed_at).
DROP TABLE IF EXISTS referrals CASCADE;

CREATE TABLE referrals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    referrer_code VARCHAR(50) UNIQUE NOT NULL,
    referrer_email VARCHAR(255) NOT NULL,
    referred_email VARCHAR(255),
    status VARCHAR(20) DEFAULT 'pending', -- pending, completed
    reward_given BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX idx_referrals_referrer_code ON referrals(referrer_code);
CREATE INDEX idx_referrals_referrer_email ON referrals(referrer_email);

ALTER TABLE referrals ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Admin full access referrals" ON referrals FOR ALL TO service_role USING (true) WITH CHECK (true);

-- Step 3: leaderboard view - SUM points per device, plus the most recently
-- set display_name for that device (pulled out of metadata JSONB) so the
-- API doesn't have to aggregate in application code.
CREATE OR REPLACE VIEW gamification_leaderboard AS
SELECT
    gp.device_id,
    SUM(gp.points_earned) AS total_points,
    COUNT(*) AS actions_count,
    MAX(gp.created_at) AS last_activity_at,
    (
        SELECT gp2.metadata->>'display_name'
        FROM gamification_points gp2
        WHERE gp2.device_id = gp.device_id
          AND gp2.metadata->>'display_name' IS NOT NULL
        ORDER BY gp2.created_at DESC
        LIMIT 1
    ) AS display_name
FROM gamification_points gp
WHERE gp.device_id IS NOT NULL
GROUP BY gp.device_id
ORDER BY total_points DESC;

-- Step 4: RLS for gamification tables - same convention as payments/
-- applications: all reads/writes go exclusively through the Express API
-- using the service_role key (points are server-validated per action,
-- badges are awarded server-side, leaderboard aggregation happens in the
-- view above). Guarded so this step is safe to re-run.
ALTER TABLE gamification_points ENABLE ROW LEVEL SECURITY;
ALTER TABLE gamification_badges ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_badges ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Admin full access gamification_points' AND tablename = 'gamification_points') THEN
    CREATE POLICY "Admin full access gamification_points" ON gamification_points FOR ALL TO service_role USING (true) WITH CHECK (true);
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Admin full access gamification_badges' AND tablename = 'gamification_badges') THEN
    CREATE POLICY "Admin full access gamification_badges" ON gamification_badges FOR ALL TO service_role USING (true) WITH CHECK (true);
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Admin full access user_badges' AND tablename = 'user_badges') THEN
    CREATE POLICY "Admin full access user_badges" ON user_badges FOR ALL TO service_role USING (true) WITH CHECK (true);
  END IF;
END $$;
