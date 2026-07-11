-- ELIMUX PAYMENTS — combined migration (07a + 07b + 07c + 07d)
-- Paste this whole file into Supabase → SQL Editor → New query → Run.
-- Assumes 01_schema.sql (or 01a/01b/01c) has already been run, since this
-- reuses uuid_generate_v4() and update_updated_at_column() from there.

-- ===== 07a: TABLES =====

DROP TABLE IF EXISTS payments CASCADE;
DROP TABLE IF EXISTS subscriptions CASCADE;
DROP TABLE IF EXISTS subscribers CASCADE;
DROP TABLE IF EXISTS subscription_plans CASCADE;

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Subscription plans (Free, Premium, Institution)
CREATE TABLE IF NOT EXISTS subscription_plans (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    slug VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    price_kes INTEGER NOT NULL,
    price_usd INTEGER,
    currency VARCHAR(3) DEFAULT 'KES',
    duration_months INTEGER DEFAULT 1,
    features JSONB,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Subscribers (email-based, no auth required)
CREATE TABLE IF NOT EXISTS subscribers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    name VARCHAR(100),
    phone VARCHAR(20),
    country VARCHAR(100),
    paystack_customer_code VARCHAR(100),
    access_token VARCHAR(64) UNIQUE NOT NULL DEFAULT encode(gen_random_bytes(32), 'hex'),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Subscriptions
CREATE TABLE IF NOT EXISTS subscriptions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    subscriber_id UUID REFERENCES subscribers(id) ON DELETE CASCADE,
    plan_id UUID REFERENCES subscription_plans(id),
    status VARCHAR(20) DEFAULT 'pending', -- pending, active, cancelled, expired
    paystack_subscription_code VARCHAR(100),
    paystack_email_token VARCHAR(100),
    current_period_start TIMESTAMP WITH TIME ZONE,
    current_period_end TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    cancelled_at TIMESTAMP WITH TIME ZONE
);

-- Payment transactions
CREATE TABLE IF NOT EXISTS payments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    subscriber_id UUID REFERENCES subscribers(id) ON DELETE SET NULL,
    subscription_id UUID REFERENCES subscriptions(id) ON DELETE SET NULL,
    amount INTEGER NOT NULL,
    currency VARCHAR(3) NOT NULL,
    paystack_reference VARCHAR(100) UNIQUE NOT NULL,
    paystack_transaction_id VARCHAR(100),
    status VARCHAR(20) DEFAULT 'pending', -- pending, success, failed, refunded
    payment_method VARCHAR(50), -- mpesa, card, bank_transfer, ussd
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_subscribers_email ON subscribers(email);
CREATE INDEX IF NOT EXISTS idx_subscriptions_subscriber_id ON subscriptions(subscriber_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_status ON subscriptions(status);
CREATE INDEX IF NOT EXISTS idx_payments_subscriber_id ON payments(subscriber_id);
CREATE INDEX IF NOT EXISTS idx_payments_reference ON payments(paystack_reference);

-- ===== 07b: RLS POLICIES =====

ALTER TABLE subscription_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscribers ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public read active subscription_plans" ON subscription_plans FOR SELECT USING (is_active = true);

CREATE POLICY "Admin full access subscription_plans" ON subscription_plans FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY "Admin full access subscribers" ON subscribers FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY "Admin full access subscriptions" ON subscriptions FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY "Admin full access payments" ON payments FOR ALL TO service_role USING (true) WITH CHECK (true);

-- ===== 07c: TRIGGERS =====

CREATE TRIGGER update_subscribers_updated_at
    BEFORE UPDATE ON subscribers
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ===== 07d: SEED DATA =====

INSERT INTO subscription_plans (name, slug, description, price_kes, price_usd, currency, duration_months, features, is_active)
VALUES
    (
        'Free',
        'free',
        'Browse institutions and programs with basic access.',
        0,
        0,
        'KES',
        1,
        '["Browse all institutions and programs", "Save up to 10 favorites", "Basic search"]'::jsonb,
        true
    ),
    (
        'Premium',
        'premium',
        'Unlimited access for serious applicants.',
        500,
        5,
        'KES',
        1,
        '["Unlimited favorites", "Priority AI search", "Ad-free browsing", "Program comparison tools"]'::jsonb,
        true
    ),
    (
        'Institution',
        'institution',
        'For institutions listing on ElimuX.',
        5000,
        40,
        'KES',
        1,
        '["Verified badge", "Priority listing placement", "Analytics dashboard", "Dedicated support"]'::jsonb,
        true
    )
ON CONFLICT (slug) DO NOTHING;

-- ===== VERIFY =====
SELECT name, slug, price_kes, currency, is_active FROM subscription_plans ORDER BY price_kes;
