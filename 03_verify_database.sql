-- ELIMUX DATABASE VERIFICATION SCRIPT
-- Run this in Supabase SQL Editor to see what's actually in your database

-- 1. Count rows in each table
SELECT 'countries' as table_name, COUNT(*) as row_count FROM countries
UNION ALL
SELECT 'institution_types', COUNT(*) FROM institution_types
UNION ALL
SELECT 'program_categories', COUNT(*) FROM program_categories
UNION ALL
SELECT 'institutions', COUNT(*) FROM institutions
UNION ALL
SELECT 'programs', COUNT(*) FROM programs
UNION ALL
SELECT 'reviews', COUNT(*) FROM reviews
UNION ALL
SELECT 'sponsor_ads', COUNT(*) FROM sponsor_ads
UNION ALL
SELECT 'referrals', COUNT(*) FROM referrals
UNION ALL
SELECT 'admin_users', COUNT(*) FROM admin_users
UNION ALL
SELECT 'contact_messages', COUNT(*) FROM contact_messages;

-- 2. Show first 5 countries
SELECT name, iso_code, currency FROM countries LIMIT 5;

-- 3. Show all institution types
SELECT name, icon FROM institution_types;

-- 4. Show all program categories
SELECT name, icon, color FROM program_categories;

-- 5. Check RLS is enabled
SELECT tablename, rowsecurity FROM pg_tables WHERE schemaname = 'public' AND rowsecurity = true;
