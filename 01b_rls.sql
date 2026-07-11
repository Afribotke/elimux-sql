-- ELIMUX SCHEMA PART 2: RLS POLICIES
-- Run AFTER Part 1 (Tables) has been executed

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

CREATE POLICY "Public read countries" ON countries FOR SELECT USING (is_active = true);
CREATE POLICY "Public read institution_types" ON institution_types FOR SELECT USING (is_active = true);
CREATE POLICY "Public read program_categories" ON program_categories FOR SELECT USING (is_active = true);
CREATE POLICY "Public read institutions" ON institutions FOR SELECT USING (is_active = true);
CREATE POLICY "Public read programs" ON programs FOR SELECT USING (is_active = true);
CREATE POLICY "Public read reviews" ON reviews FOR SELECT USING (is_active = true);
CREATE POLICY "Public read sponsor_ads" ON sponsor_ads FOR SELECT USING (is_active = true);

CREATE POLICY "Public insert reviews" ON reviews FOR INSERT WITH CHECK (true);
CREATE POLICY "Public insert contact_messages" ON contact_messages FOR INSERT WITH CHECK (true);

CREATE POLICY "Admin full access institutions" ON institutions FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY "Admin full access programs" ON programs FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY "Admin full access reviews" ON reviews FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY "Admin full access sponsor_ads" ON sponsor_ads FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY "Admin full access referrals" ON referrals FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY "Admin full access contact_messages" ON contact_messages FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY "Admin full access admin_users" ON admin_users FOR ALL TO service_role USING (true) WITH CHECK (true);
