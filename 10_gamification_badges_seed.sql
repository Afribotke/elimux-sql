-- ============================================================
-- ELIMUX 17c: GAMIFICATION BADGES SEED
-- Run in Supabase SQL Editor. Idempotent (ON CONFLICT DO UPDATE).
--
-- All badges use criteria_type = 'points_total' - the only kind
-- awardEligibleBadges() in routes/gamification.ts can auto-evaluate
-- (see comment there). Thresholds are spaced to be reachable by mixing
-- the five point-earning actions (search=1, review=10, share=5,
-- referral=50, login=1).
-- ============================================================

INSERT INTO gamification_badges (id, name, description, icon, criteria_type, criteria_threshold, points_reward, is_active) VALUES
('7d1f0b3e-6a5b-4c1a-9d3e-1a2b3c4d5e01', 'First Steps', 'Earned your first point on ElimuX', 'sparkles', 'points_total', 1, 5, true),
('7d1f0b3e-6a5b-4c1a-9d3e-1a2b3c4d5e02', 'Explorer', 'Reached 25 points searching and browsing ElimuX', 'search', 'points_total', 25, 10, true),
('7d1f0b3e-6a5b-4c1a-9d3e-1a2b3c4d5e03', 'Reviewer', 'Reached 50 points - sharing your experience helps others choose', 'star', 'points_total', 50, 20, true),
('7d1f0b3e-6a5b-4c1a-9d3e-1a2b3c4d5e04', 'Super Sharer', 'Reached 100 points - a true ElimuX advocate', 'share', 'points_total', 100, 50, true),
('7d1f0b3e-6a5b-4c1a-9d3e-1a2b3c4d5e05', 'Community Champion', 'Reached 250 points - a pillar of the ElimuX community', 'crown', 'points_total', 250, 100, true),
('7d1f0b3e-6a5b-4c1a-9d3e-1a2b3c4d5e06', 'Referral Legend', 'Reached 500 points - among the most active ElimuX users', 'trophy', 'points_total', 500, 200, true)
ON CONFLICT (id) DO UPDATE SET
  name = EXCLUDED.name,
  description = EXCLUDED.description,
  icon = EXCLUDED.icon,
  criteria_type = EXCLUDED.criteria_type,
  criteria_threshold = EXCLUDED.criteria_threshold,
  points_reward = EXCLUDED.points_reward,
  is_active = EXCLUDED.is_active;
