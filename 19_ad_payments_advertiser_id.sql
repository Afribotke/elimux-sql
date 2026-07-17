-- 19_ad_payments_advertiser_id.sql
-- ad_payments only linked to advertisers indirectly via campaign_id, which
-- is nullable (payments aren't required to be tied to a specific campaign -
-- a plain wallet top-up has no campaign yet). Without a direct advertiser
-- link, top-up payments have no queryable way back to the advertiser that
-- made them, so payment history can't list them. Adds that link directly,
-- same pattern as 18_advertisers_user_id.sql.
-- Safe to re-run (ADD COLUMN IF NOT EXISTS).

ALTER TABLE ad_payments ADD COLUMN IF NOT EXISTS advertiser_id UUID REFERENCES advertisers(id);

CREATE INDEX IF NOT EXISTS idx_ad_payments_advertiser_id ON ad_payments(advertiser_id);
