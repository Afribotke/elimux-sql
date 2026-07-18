-- 22_referrals_referrer_device_id.sql
-- Adds referrer_device_id to referrals so a completed referral can pay out
-- points to the correct gamification_points ledger. referrals are keyed by
-- email (referrer_email/referred_email); gamification is keyed by device_id
-- (see 09_gamification_migration.sql). Without this column there was no way
-- to know which device to credit when a referral code got redeemed.
--
-- Backfill: existing rows (created before this column existed) stay NULL -
-- the redeem handler in gamification.ts only awards points when
-- referrer_device_id is set, so old dangling referrals are simply skipped,
-- not retroactively paid out.
--
-- Idempotent (IF NOT EXISTS throughout). Run in Supabase SQL Editor.

ALTER TABLE referrals ADD COLUMN IF NOT EXISTS referrer_device_id TEXT;

CREATE INDEX IF NOT EXISTS idx_referrals_referrer_device_id ON referrals(referrer_device_id);

-- Verify: column exists and (on a fresh run) is NULL for all pre-existing rows.
SELECT referrer_code, referrer_email, referrer_device_id, status
FROM referrals
ORDER BY created_at DESC
LIMIT 20;
