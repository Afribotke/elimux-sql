-- ============================================================
-- RLS POLICY FIX — user_roles, student_levels, gamification_actions
-- Applied directly to Supabase via MCP on 2026-08-08; documented here
-- for the repo record. Fixes RLS-enabled-no-policy tables that were
-- silently returning zero rows to anon/authenticated clients:
--   - RoleGuard / PermissionGuard (src/lib/auth/guards.tsx) bouncing
--     legitimate non-student users to /unauthorized
--   - src/app/gamification/page.tsx "Ways to Earn" card empty for
--     all visitors, level/next-level lookup empty for logged-in users
-- ============================================================

ALTER TABLE IF EXISTS user_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS student_levels ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS gamification_actions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "user_roles_select_own" ON user_roles;
DROP POLICY IF EXISTS "Users can view own role" ON user_roles;
DROP POLICY IF EXISTS "student_levels_select_all" ON student_levels;
DROP POLICY IF EXISTS "Authenticated users can view student levels" ON student_levels;
DROP POLICY IF EXISTS "gamification_actions_select_all" ON gamification_actions;
DROP POLICY IF EXISTS "Authenticated users can view gamification actions" ON gamification_actions;
DROP POLICY IF EXISTS "Anonymous users can view gamification actions" ON gamification_actions;
DROP POLICY IF EXISTS "Anyone can view gamification actions" ON gamification_actions;

-- user_roles: each authenticated user can read only their own row
CREATE POLICY "Users can view own role"
  ON user_roles
  FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

-- student_levels: reference data (level thresholds), used only inside
-- logged-in code paths (src/app/gamification/page.tsx) — authenticated only
CREATE POLICY "Authenticated users can view student levels"
  ON student_levels
  FOR SELECT
  TO authenticated
  USING (true);

-- gamification_actions: feeds the public "Ways to Earn" card, which
-- renders for every visitor regardless of login state — anon + authenticated
CREATE POLICY "Anyone can view gamification actions"
  ON gamification_actions
  FOR SELECT
  TO anon, authenticated
  USING (true);
