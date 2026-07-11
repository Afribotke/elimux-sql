-- ELIMUX PAYMENTS PART 4: SEED DATA
-- Run AFTER 07a (Tables) has been executed

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
