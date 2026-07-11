-- ELIMUX PAYMENTS PART 2: RLS POLICIES
-- Run AFTER 07a (Tables) has been executed
-- All payment data is written/read exclusively via the Express API using the
-- service_role key — no anon/public access, since subscribers/payments hold
-- billing-adjacent data keyed by email.

ALTER TABLE subscription_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscribers ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public read active subscription_plans" ON subscription_plans FOR SELECT USING (is_active = true);

CREATE POLICY "Admin full access subscription_plans" ON subscription_plans FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY "Admin full access subscribers" ON subscribers FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY "Admin full access subscriptions" ON subscriptions FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY "Admin full access payments" ON payments FOR ALL TO service_role USING (true) WITH CHECK (true);
