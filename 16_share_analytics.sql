-- ELIMUX SHARE & ANALYTICS MODULE
-- Adds: search_analytics, program_views, shared_searches
-- Run after 01a_tables.sql (institutions, programs, program_categories, countries must exist)
-- All three tables are written/read exclusively via the Express API using the
-- service_role key, same convention as payments (see 07b_payments_rls.sql).

CREATE TABLE IF NOT EXISTS search_analytics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    query_text VARCHAR(255),
    category_id UUID REFERENCES program_categories(id),
    country_filter UUID REFERENCES countries(id),
    level_filter VARCHAR(50),
    results_count INTEGER NOT NULL DEFAULT 0,
    user_country VARCHAR(100),
    device_id VARCHAR(64),
    shared BOOLEAN DEFAULT false,
    -- Set only once a search's results are actually shared, e.g. 'whatsapp' /
    -- 'email' / 'copy_link' / 'pdf'. Nothing writes this yet - there's no
    -- link today between a share action and the search_analytics row it
    -- followed - so it stays null until that wiring exists.
    shared_via VARCHAR(50),
    converted BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS program_views (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    program_id UUID REFERENCES programs(id) ON DELETE CASCADE,
    institution_id UUID REFERENCES institutions(id) ON DELETE CASCADE,
    device_id VARCHAR(64),
    user_country VARCHAR(100),
    -- Free-text search query that led to this view, if any. Lets the
    -- university dashboard derive "top programs searched" without needing
    -- an institution_id column on search_analytics (a single search spans
    -- many institutions, so it can't carry one FK).
    source_query VARCHAR(255),
    -- Per-browser-tab identifier (sessionStorage-backed, generated
    -- client-side) - a finer grain than device_id, which is a persistent
    -- IP+user-agent fingerprint shared across visits.
    session_id VARCHAR(64),
    -- What page/flow led to this view, e.g. 'list', 'shared_search', 'search'.
    view_source VARCHAR(50),
    -- No geo-IP lookup wired up yet, so this stays null until one exists.
    referrer_country VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS shared_searches (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    share_token VARCHAR(64) UNIQUE NOT NULL,
    user_email VARCHAR(255),
    query_text VARCHAR(255),
    -- Denormalized snapshot of the shared programs (id/name/institution/tuition/etc)
    -- at share time, so the /share page keeps working even if a program is
    -- later deactivated or changes.
    programs JSONB NOT NULL DEFAULT '[]',
    view_count INTEGER DEFAULT 0,
    last_viewed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_search_analytics_created ON search_analytics(created_at);
CREATE INDEX IF NOT EXISTS idx_search_analytics_category ON search_analytics(category_id);
CREATE INDEX IF NOT EXISTS idx_program_views_program ON program_views(program_id);
CREATE INDEX IF NOT EXISTS idx_program_views_institution ON program_views(institution_id);
CREATE INDEX IF NOT EXISTS idx_program_views_created ON program_views(created_at);
CREATE INDEX IF NOT EXISTS idx_shared_searches_token ON shared_searches(share_token);

ALTER TABLE search_analytics ENABLE ROW LEVEL SECURITY;
ALTER TABLE program_views ENABLE ROW LEVEL SECURITY;
ALTER TABLE shared_searches ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Service role full access search_analytics" ON search_analytics FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY "Service role full access program_views" ON program_views FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY "Service role full access shared_searches" ON shared_searches FOR ALL TO service_role USING (true) WITH CHECK (true);
