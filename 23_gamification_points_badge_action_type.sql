-- 23_gamification_points_badge_action_type.sql
-- Widens gamification_points_action_type_check to allow action_type = 'badge',
-- so badge bonus points (gamification_badges.points_reward) can be recorded
-- as their own ledger entries instead of being purely informational (see
-- awardEligibleBadges() in elimux-backend/src/routes/gamification.ts).
--
-- 'badge' is deliberately NOT added to ACTION_POINTS in gamification.ts, so
-- POST /api/gamification/points rejects it from clients - only the server-side
-- badge-award path can insert a 'badge' row.
--
-- The constraint name is looked up dynamically rather than hardcoded, since
-- gamification_points was created directly in the Supabase dashboard (not
-- via a tracked migration - see elimux-sql/README.md "Known drift") and its
-- exact constraint name was never confirmed against a tracked file before now.
-- Idempotent: re-running finds and replaces whatever check constraint already
-- exists on the action_type column with the same expanded definition.
--
-- Run in Supabase SQL Editor.

DO $$
DECLARE
  existing_constraint text;
BEGIN
  SELECT con.conname INTO existing_constraint
  FROM pg_constraint con
  JOIN pg_class rel ON rel.oid = con.conrelid
  JOIN pg_attribute att
    ON att.attrelid = con.conrelid
   AND att.attnum = ANY (con.conkey)
  WHERE rel.relname = 'gamification_points'
    AND con.contype = 'c'
    AND att.attname = 'action_type';

  IF existing_constraint IS NOT NULL THEN
    EXECUTE format('ALTER TABLE gamification_points DROP CONSTRAINT %I', existing_constraint);
  END IF;

  ALTER TABLE gamification_points
    ADD CONSTRAINT gamification_points_action_type_check
    CHECK (action_type IN ('search', 'review', 'share', 'referral', 'login', 'badge'));
END $$;

-- Verify: confirm 'badge' is now part of the constraint definition.
SELECT conname, pg_get_constraintdef(oid) AS definition
FROM pg_constraint
WHERE conrelid = 'gamification_points'::regclass
  AND contype = 'c';
