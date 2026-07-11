-- ============================================================
-- ELIMUX DATABASE SCHEMA - SUPABASE COMPATIBLE
-- Created: 2026-07-04
-- Purpose: Complete database structure for ElimuX platform
-- ============================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================
-- 1. COUNTRIES TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS countries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL UNIQUE,
    iso_code VARCHAR(2) NOT NULL UNIQUE,
    flag_emoji VARCHAR(10),
    currency VARCHAR(10),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================
-- 2. INSTITUTION TYPES TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS institution_types (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(50) NOT NULL UNIQUE,
    description TEXT,
    icon VARCHAR(50),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================
-- 3. PROGRAM CATEGORIES TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS program_categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    icon VARCHAR(50),
    color VARCHAR(20),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================
-- 4. INSTITUTIONS TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS institutions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    slug VARCHAR(255) UNIQUE,
    type_id UUID REFERENCES institution_types(id),
    country_id UUID REFERENCES countries(id),
    city VARCHAR(100),
    address TEXT,
    website_url VARCHAR(255),
    email VARCHAR(255),
    phone VARCHAR(50),
    description TEXT,
    logo_url VARCHAR(500),
    cover_image_url VARCHAR(500),
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    is_verified BOOLEAN DEFAULT false,
    is_active BOOLEAN DEFAULT true,
    founded_year INTEGER,
    student_count INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================
-- 5. PROGRAMS TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS programs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    slug VARCHAR(255) UNIQUE,
    institution_id UUID REFERENCES institutions(id) ON DELETE CASCADE,
    category_id UUID REFERENCES program_categories(id),
    description TEXT,
    duration_months INTEGER,
    tuition_fees DECIMAL(12, 2),
    currency VARCHAR(10),
    level VARCHAR(50),
    mode VARCHAR(50),
    requirements TEXT,
    career_outcomes TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================
-- 6. REVIEWS TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS reviews (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    institution_id UUID REFERENCES institutions(id) ON DELETE CASCADE,
    program_id UUID REFERENCES programs(id) ON DELETE CASCADE,
    reviewer_name VARCHAR(100),
    reviewer_email VARCHAR(255),
    rating INTEGER CHECK (rating >= 1 AND rating <= 5),
    comment TEXT,
    is_verified BOOLEAN DEFAULT false,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================
-- 7. SPONSOR ADS TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS sponsor_ads (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR(255) NOT NULL,
    description TEXT,
    image_url VARCHAR(500),
    target_url VARCHAR(500),
    institution_id UUID REFERENCES institutions(id),
    start_date DATE,
    end_date DATE,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================
-- 8. REFERRALS TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS referrals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    referrer_email VARCHAR(255) NOT NULL,
    referred_email VARCHAR(255),
    referral_code VARCHAR(50) UNIQUE,
    status VARCHAR(50) DEFAULT 'pending',
    points_earned INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================
-- 9. ADMIN USERS TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS admin_users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) NOT NULL UNIQUE,
    role VARCHAR(50) DEFAULT 'editor',
    is_active BOOLEAN DEFAULT true,
    last_login TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================
-- 10. CONTACT MESSAGES TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS contact_messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL,
    subject VARCHAR(255),
    message TEXT NOT NULL,
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================
-- INDEXES FOR PERFORMANCE
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_institutions_country ON institutions(country_id);
CREATE INDEX IF NOT EXISTS idx_institutions_type ON institutions(type_id);
CREATE INDEX IF NOT EXISTS idx_institutions_active ON institutions(is_active);
CREATE INDEX IF NOT EXISTS idx_programs_institution ON programs(institution_id);
CREATE INDEX IF NOT EXISTS idx_programs_category ON programs(category_id);
CREATE INDEX IF NOT EXISTS idx_programs_active ON programs(is_active);
CREATE INDEX IF NOT EXISTS idx_reviews_institution ON reviews(institution_id);
CREATE INDEX IF NOT EXISTS idx_reviews_rating ON reviews(rating);

-- ============================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================================
ALTER TABLE countries ENABLE ROW LEVEL SECURITY;
ALTER TABLE institution_types ENABLE ROW LEVEL SECURITY;
ALTER TABLE program_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE institutions ENABLE ROW LEVEL SECURITY;
ALTER TABLE programs ENABLE ROW LEVEL SECURITY;
ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE sponsor_ads ENABLE ROW LEVEL SECURITY;
ALTER TABLE referrals ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE contact_messages ENABLE ROW LEVEL SECURITY;

-- Public read policies
CREATE POLICY "Public read countries" ON countries FOR SELECT USING (is_active = true);
CREATE POLICY "Public read institution_types" ON institution_types FOR SELECT USING (is_active = true);
CREATE POLICY "Public read program_categories" ON program_categories FOR SELECT USING (is_active = true);
CREATE POLICY "Public read institutions" ON institutions FOR SELECT USING (is_active = true);
CREATE POLICY "Public read programs" ON programs FOR SELECT USING (is_active = true);
CREATE POLICY "Public read reviews" ON reviews FOR SELECT USING (is_active = true);
CREATE POLICY "Public read sponsor_ads" ON sponsor_ads FOR SELECT USING (is_active = true);

-- Public insert policies
CREATE POLICY "Public insert reviews" ON reviews FOR INSERT WITH CHECK (true);
CREATE POLICY "Public insert contact_messages" ON contact_messages FOR INSERT WITH CHECK (true);

-- Admin policies (using service role)
CREATE POLICY "Admin full access institutions" ON institutions FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY "Admin full access programs" ON programs FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY "Admin full access reviews" ON reviews FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY "Admin full access sponsor_ads" ON sponsor_ads FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY "Admin full access referrals" ON referrals FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY "Admin full access contact_messages" ON contact_messages FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY "Admin full access admin_users" ON admin_users FOR ALL TO service_role USING (true) WITH CHECK (true);

-- ============================================================
-- FUNCTION: Update updated_at timestamp
-- ============================================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS '
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
' LANGUAGE plpgsql;

-- Apply trigger to institutions
CREATE TRIGGER update_institutions_updated_at
    BEFORE UPDATE ON institutions
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Apply trigger to programs
CREATE TRIGGER update_programs_updated_at
    BEFORE UPDATE ON programs
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================
-- SCHEMA COMPLETE
-- ============================================================
