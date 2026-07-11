-- ELIMUX INSTITUTION ONBOARDING PART 1: TABLES
-- Self-service applications from institutions wanting to join the platform.
-- Run AFTER 01a/01b/01c have been executed.

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Institution applications (pending approval)
CREATE TABLE IF NOT EXISTS institution_applications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    type_id UUID REFERENCES institution_types(id),
    country_id UUID REFERENCES countries(id),
    city VARCHAR(100),
    website VARCHAR(255),
    email VARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    description TEXT,
    status VARCHAR(20) DEFAULT 'pending', -- pending, approved, rejected
    admin_notes TEXT,
    -- Set once the application is approved, so approved program applications
    -- submitted later (outside the original batch) know which real
    -- institution row to attach to.
    created_institution_id UUID REFERENCES institutions(id),
    -- Lets an applicant check their status without an account/login, the same
    -- pattern subscribers.access_token uses for email-based subscriptions.
    access_token VARCHAR(64) UNIQUE NOT NULL DEFAULT encode(gen_random_bytes(32), 'hex'),
    submitted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    reviewed_at TIMESTAMP WITH TIME ZONE,
    reviewed_by UUID,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Program applications (pending approval), submitted alongside an
-- institution application as part of the same onboarding session.
CREATE TABLE IF NOT EXISTS program_applications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    institution_application_id UUID NOT NULL REFERENCES institution_applications(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    category_id UUID REFERENCES program_categories(id),
    level VARCHAR(50),
    duration_months INTEGER,
    tuition_fees INTEGER,
    currency VARCHAR(3),
    description TEXT,
    requirements TEXT,
    status VARCHAR(20) DEFAULT 'pending', -- pending, approved, rejected
    admin_notes TEXT,
    -- Set once approved, pointing at the real program row created.
    created_program_id UUID REFERENCES programs(id),
    submitted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    reviewed_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_institution_applications_status ON institution_applications(status);
CREATE INDEX IF NOT EXISTS idx_institution_applications_email ON institution_applications(email);
CREATE INDEX IF NOT EXISTS idx_institution_applications_token ON institution_applications(access_token);
CREATE INDEX IF NOT EXISTS idx_program_applications_institution_application_id ON program_applications(institution_application_id);
CREATE INDEX IF NOT EXISTS idx_program_applications_status ON program_applications(status);
