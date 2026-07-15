# elimux-sql

Supabase SQL for the ElimuX platform (project ref `ohlgjvenwekpbpkykutz`). There is no migration
runner here — every file is pasted by hand into **Supabase Dashboard → SQL Editor → New query → Run**,
in the order below. Most files are idempotent (`IF NOT EXISTS` / `ON CONFLICT`), but a few contain a
one-time destructive step called out explicitly.

## Order

| # | File | What it does |
|---|------|---------------|
| 1a | `01a_tables.sql` | Base schema: `countries`, `institution_types`, `program_categories`, `institutions`, `programs`, `reviews`, `sponsor_ads`, `referrals`, `admin_users`, `contact_messages`. Starts with `DROP TABLE ... CASCADE` — run only on a fresh database. |
| 1b | `01b_rls.sql` | Row-Level Security: public `SELECT` for active rows, full access for `service_role` (the backend). |
| 1c | `01c_triggers.sql` | `update_updated_at_column()` function + triggers on `institutions`/`programs`. |
| 2a | `02a_seed_countries_part1.sql` | First 50 countries. |
| 2b | `02b_seed_data_part2.sql` | Remaining countries + `institution_types`. |
| 2c | `02c_seed_program_categories.sql` | `program_categories`, mirrored from production. |
| 3 | `03_verify_database.sql` | Read-only: row counts per table. Run any time as a sanity check, not part of the migration order. |
| 4a | `04a_kenya_public_universities.sql` | Seeds Kenyan public universities into `institutions`. |
| 5a | `05a_uk_institutions.sql` | Seeds UK institutions into `institutions`. |
| 6 | `06_reviews_migration.sql` | Extends `reviews` in place: adds `user_id` (nullable, optional auth), `title`, and other rich fields on top of the anonymous reviewer_name/reviewer_email shape from `01a`. |
| 7 | `07_payments_combined.sql` **or** `07a`+`07b`+`07c`+`07d` | Subscriptions/payments: `subscription_plans`, `subscribers`, `subscriptions`, `payments`. `07_payments_combined.sql` is the four split files concatenated for a single paste — run **either** the combined file **or** the four parts, never both. |
| 8a | `08a_applications_tables.sql` | `institution_applications` / `program_applications` — self-service onboarding. |
| 8b | `08b_applications_rls.sql` | RLS for applications: service_role only, no anon access (submissions go through the API). |
| 8c | `08c_applications_triggers.sql` | `updated_at` trigger for `institution_applications`. |
| 9 | `09_gamification_migration.sql` | Adds device-based identity (`device_id`) to `gamification_points`/`user_badges`, and rebuilds `referrals` to the device-identity shape (`referrer_code`, `reward_given`). Contains a one-time destructive `DROP TABLE referrals` — was safe only because the table had 0 rows at the time (2026-07-10). |
| 10 | `10_gamification_badges_seed.sql` | Seeds `gamification_badges` (all `criteria_type = 'points_total'`). |
| 11 | `11_reviews_status_pending.sql` | Ensures `reviews.status` exists and flips its default to `'pending'`, closing a drift gap where the column had been added by hand in the Supabase dashboard outside any tracked migration. |
| 12 | `12_sponsor_ads_extend.sql` | Adds `sponsor_id`, `placement`, `click_count`, `updated_at` to `sponsor_ads`, and `created_at` to `ad_clicks`, for the sponsor-ads feature. |
| 13 | `13_fix_institution_applications.sql` | Adds `created_institution_id` and `updated_at` to `institution_applications` — both were defined in `08a` and referenced by live code, but never actually applied (see "Known drift" below). Also indexes `analytics_events` for the admin dashboard. |
| 17 | `17_programs_verification_flags.sql` | Adds `is_ai_generated` and `is_verified` to `programs`, so the frontend can disclose which listings are confirmed vs AI-generated placeholder data. Run before any synthetic program data is generated. |

## Not part of the run order

- **`01_schema.sql`** — an earlier, monolithic draft of the schema (single file, `CREATE TABLE IF NOT EXISTS`, no RLS/triggers split). Superseded by `01a`/`01b`/`01c` about an hour after it was written. Kept for history only — do **not** run it alongside or after `01a`, since `01a` starts with `DROP TABLE ... CASCADE` and the two schemas have since diverged (e.g. `01_schema.sql` predates `is_featured`/`featured_until` on `institutions`).
- **`03_verify_database.sql`** — a read-only row-count query, safe to re-run any time.

## Known drift

Two different failure modes have shown up so far — check for both when something errors that "should"
work per the tracked files:

**Applied but never tracked** — schema that exists in production but isn't captured by any numbered
file here, because it was applied directly in the Supabase dashboard before this repo existed:
- `institutions.is_featured`, `institutions.featured_until`, `institutions.featured_plan_id`
- `sponsors` table (`id`, `name`, `logo_url`, `website_url`, `is_active`, `created_at`)
- `ad_clicks` table (`id`, `ad_id`, `user_device_id`, `ip_address`) — `created_at` was added by `12_sponsor_ads_extend.sql`, the rest predates it
- `analytics_events` table (`id`, `event_type`, `user_device_id`, `metadata`, `created_at`) — indexed by `13_fix_institution_applications.sql`, but the table itself predates any tracked `CREATE TABLE`

**Tracked but never applied** — the opposite problem: a file in this repo defines a column, and live
code depends on it, but the `ALTER`/`CREATE` was never actually run against production:
- `institution_applications.created_institution_id` / `.updated_at` — both are in `08a_applications_tables.sql` and used by `elimux-backend`'s approve-application endpoint, but didn't exist live until `13_fix_institution_applications.sql`. The approve-application flow had likely been erroring on every call until this was caught (2026-07-11).

Don't assume a column exists just because it's in a migration file, or that a column in production is
covered by one. When adding a feature that depends on existing schema, verify directly against
Supabase first (`select=column_name&limit=1` via the REST API is enough to confirm existence). When
you close a gap, add a numbered migration file the same way `12` and `13` did, rather than assuming
this repo's history is complete.

## Applying a new migration

1. Add a new file `NN_description.sql` (next number after the highest existing one).
2. Make it idempotent where practical (`IF NOT EXISTS`, `ON CONFLICT DO UPDATE`) so it's safe to
   re-run.
3. Paste it into Supabase SQL Editor and run it against project `ohlgjvenwekpbpkykutz`.
4. Verify with a targeted `SELECT` (or `03_verify_database.sql` for row counts), then commit and push.
