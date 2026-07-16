-- 18_advertisers_user_id.sql
-- The advertisers table (added directly via Supabase dashboard, untracked
-- until now - see README "Known drift") was built without a link to
-- auth.users, so the advertiser portal's Supabase-Auth-based login has no
-- way to find "my" advertiser record. Adds that link, plus balance/spend
-- tracking that advertiser.ts and campaigns.ts already depend on for the
-- account-balance and campaign-budget checks.
-- Safe to re-run (ADD COLUMN IF NOT EXISTS).

ALTER TABLE advertisers ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id);
ALTER TABLE advertisers ADD COLUMN IF NOT EXISTS balance DECIMAL(12, 2) NOT NULL DEFAULT 0;
ALTER TABLE advertisers ADD COLUMN IF NOT EXISTS total_spent DECIMAL(12, 2) NOT NULL DEFAULT 0;

CREATE UNIQUE INDEX IF NOT EXISTS idx_advertisers_user_id ON advertisers(user_id) WHERE user_id IS NOT NULL;
