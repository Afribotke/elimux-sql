-- 20_campaign_clicks.sql
-- ad_clicks.ad_id is a foreign key to sponsor_ads(id), actively used by the
-- (working, live) sponsor-ads banner feature (sponsor-ads.ts). The newer
-- ad_campaigns system needs the same kind of click record but referencing
-- ad_campaigns(id) instead - a single FK column can't point at two
-- different parent tables, so this is a new, separate table rather than
-- repointing ad_clicks (which would break sponsor-ads click tracking).
-- Mirrors ad_clicks' shape (id, ad_id, user_device_id, ip_address,
-- clicked_at) so ads.ts's insert logic barely changes.

CREATE TABLE IF NOT EXISTS campaign_clicks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    ad_id UUID NOT NULL REFERENCES ad_campaigns(id) ON DELETE CASCADE,
    user_device_id VARCHAR(255),
    ip_address VARCHAR(64),
    clicked_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_campaign_clicks_ad_id ON campaign_clicks(ad_id);
CREATE INDEX IF NOT EXISTS idx_campaign_clicks_clicked_at ON campaign_clicks(clicked_at);
