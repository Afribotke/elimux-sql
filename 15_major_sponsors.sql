-- 15_major_sponsors.sql
-- Site-wide "Powered by" major sponsor (distinct from sponsor_ads, which are
-- placement-based ads). Only one sponsor should be active at a time; enforced
-- by a partial unique index plus the admin /activate endpoint deactivating any
-- previously active sponsor before activating the new one.

CREATE TABLE IF NOT EXISTS major_sponsors (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_name VARCHAR(200) NOT NULL,
    logo_url VARCHAR(500),
    tagline VARCHAR(300),
    website_url VARCHAR(500),
    sponsorship_tier VARCHAR(50) CHECK (sponsorship_tier IN ('platinum', 'gold', 'silver', 'bronze')),
    start_date DATE,
    end_date DATE,
    show_in_header BOOLEAN DEFAULT true,
    show_in_footer BOOLEAN DEFAULT true,
    show_in_loading BOOLEAN DEFAULT true,
    show_in_email BOOLEAN DEFAULT true,
    is_active BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_major_sponsors_one_active ON major_sponsors(is_active) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_major_sponsors_tier ON major_sponsors(sponsorship_tier);
