-- 14_accreditation_bodies.sql
-- Accreditation bodies (CUE, TVETA, KNEC, NCK, MPDC, etc.) and their links to institutions.
-- Tables already exist in Supabase; this migration documents the applied schema and is
-- safe to re-run (IF NOT EXISTS / ADD COLUMN IF NOT EXISTS throughout).

CREATE TABLE IF NOT EXISTS accreditation_bodies (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(200) NOT NULL,
    code VARCHAR(50),
    description TEXT,
    logo_url VARCHAR(500),
    website_url VARCHAR(500),
    country_id UUID REFERENCES countries(id),
    body_type VARCHAR(50) CHECK (body_type IN ('university', 'tvet', 'secondary', 'professional')),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS institution_accreditations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    institution_id UUID REFERENCES institutions(id) ON DELETE CASCADE,
    body_id UUID REFERENCES accreditation_bodies(id) ON DELETE CASCADE,
    accreditation_number VARCHAR(100),
    accreditation_status VARCHAR(50) DEFAULT 'active',
    valid_from TIMESTAMPTZ,
    valid_until TIMESTAMPTZ,
    document_url VARCHAR(500),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE institutions ADD COLUMN IF NOT EXISTS accreditation_status VARCHAR(50) DEFAULT 'pending';

CREATE INDEX IF NOT EXISTS idx_accreditation_bodies_country ON accreditation_bodies(country_id);
CREATE INDEX IF NOT EXISTS idx_accreditation_bodies_type ON accreditation_bodies(body_type);
CREATE INDEX IF NOT EXISTS idx_accreditation_bodies_active ON accreditation_bodies(is_active);
CREATE INDEX IF NOT EXISTS idx_institution_accreditations_institution ON institution_accreditations(institution_id);
CREATE INDEX IF NOT EXISTS idx_institution_accreditations_body ON institution_accreditations(body_id);
