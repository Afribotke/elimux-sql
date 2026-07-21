# ElimuX — Project State (Living Document)

**Purpose:** Single source of truth for onboarding any AI/dev session. Read this first. Update it at the END of every work session (Kimi prompts the update; Claude commits it).

**Last updated:** 2026-07-21 (v7 — P1 SHIPPED; Skolex university-portal feature diff ruled by Kimi (§6/§7); migration 25 (Task 3 Gate A) ratified, drafted, awaiting founder confirmation it ran in Supabase before commit)

---

## 1. Platform Overview

ElimuX is a global education discovery SaaS. Students discover, compare, and apply to institutions worldwide; institutions claim and manage their own profiles and programs; advertisers run paid campaigns; subscriptions monetize institution features.

- **Directory:** ~8,969 institutions, ~21,000 pre-rendered pages
- **Frontend:** https://www.elimux.ke — Next.js static export (`output: export`) on Vercel
- **Backend:** https://api.elimux.ke — Express + TypeScript on Railway
- **Data/Auth/Storage:** Supabase (Postgres + Auth + Storage; public bucket `institution-logos`)

**Critical architecture fact:** the frontend is a static export — institution pages are pre-rendered at build time. Any DB content change (logos, descriptions, programs) requires a frontend rebuild + redeploy to go live. `NEXT_PUBLIC_*` env vars are build-time inlined — changing them also requires a rebuild.

---

## 2. Repositories & Infrastructure

| Repo | Purpose | Notes |
|---|---|---|
| `elimux-frontend` | Next.js static site → Vercel | Feature flags via `NEXT_PUBLIC_*` |
| `elimux-backend` | Express/TS API → Railway | Scripts run via `railway run -- node scripts/...` (service key in Railway env) |
| `elimux-sql` | Numbered SQL migrations | Applied by manual paste into Supabase SQL Editor, then committed. Latest: `24_institution_logo_source.sql`. Also home of this state file. |

**Hard-won operational facts:**
- PostgREST default cap = 1000 rows/query — always paginate (id-cursor, never offset over a mutating filter)
- `.neq('col', x)` silently drops rows where col IS NULL — use `.or('col.is.null,col.neq.x')`
- `.single()` throws PGRST116 on zero rows (breaks 404 logic) — use `.maybeSingle()`
- Embedded-resource filters: `.eq('programs.is_active', true)` on the embed, not the parent
- Service-role key: rotated 2026-07-19 after terminal exposure. NEVER paste keys in chat. On rotation, update Railway env too.

---

## 3. Working Protocol (permanent)

- **Kimi (K3) = the brain:** writes complete production-ready code, decisions, checklists. Never instructions-only.
- **Claude Code = the hands:** creates files, runs commands, deploys, tests (Playwright vs production, API curls, SQL via `railway run`).
- **Founder = intermediary:** forwards messages, runs SQL in Supabase Editor when asked, approves permission prompts. NEVER manually creates files, NEVER runs JavaScript.
- **Stage gates:** audit → code → review checklist → deploy → verify (SQL + API + UI) → cleanup test data → update elimux-sql.
- **Discipline:** multi-tenancy ownership checks (403) on every tenant-scoped route; whitelist-only PUT updates; money paths verified to the cent; test data cleaned after every test; test-auth-users deleted after use.
- **Founder rule (2026-07-20):** no change merges without the founder previewing it first. For visual/UX-affecting work: push the branch → wait for the Vercel preview deployment → post the preview URL → hold for explicit founder approval before merging. No exceptions. (Non-visual reference/doc changes, like design-token extraction, use the PR diff itself as the "preview.")

---

## 4. Shipped Systems (all LIVE)

| System | Key pieces | Gotchas |
|---|---|---|
| Institution directory | ~8,969 institutions, programs, applications | Applications join via `institution_applications.created_institution_id`; `program_applications` has `submitted_at` NOT `created_at` |
| Student identity | Device fingerprint (no student auth) | Weak identity — student accounts are a future build |
| Auth middleware | `adminMiddleware` (X-Admin-Key), `advertiserAuth`, `institutionAuth` | All: Supabase JWT → account row → status check |
| Admin panel | 16 pages incl. reviews moderation, institution-account approval | — |
| Advertiser portal | Campaigns, `campaign_clicks` (mig. 20), KES billing, Paystack + webhook signature | `ad_clicks` FK bug history — clicks live in `campaign_clicks` |
| Institution portal | Claim flow (pending→active), profile PUT (7-field whitelist), programs CRUD (soft delete `is_active`), analytics | Mig. 21 `institution_accounts` (UNIQUE institution_id + user_id) |
| Subscriptions | Paystack only (M-Pesa `mobile_money` channel + cards). NO Stripe — deliberate. Expiry sweep (24h interval + lazy on GET /subscription), renewal UI, `payment_method` from channel | — |
| Reviews | POST hardened: IP rate limit 5/hr, 30-day duplicate guard (409), link filter (400), ≤2000 chars. Admin DELETE endpoint | `pros`/`cons` are TEXT — ReviewCard must handle `string \| string[]` (Array.isArray fix, else live page crash) |
| PWA | `sw.js` v3 `navigationHandler` (network-first → cache → `/offline`), viewport zoom unlocked | Playwright offline emulation can't reach SW — test in SW context |
| Gamification | Points ledger (`badge` action server-only, mig. 23), referrals `referrer_device_id` (mig. 22), redeem pays referrer 50 pts, leaderboard | Leaderboard view has seconds-long read-after-write lag (cosmetic) |
| Logo pipeline | `InstitutionLogo` 2-tier: `logo_url` → Google favicon (sz=128) → Globe icon. **Clearbit tier REMOVED 2026-07-19** (dead API returns HTTP 200 + 0×0 image, never triggers onError). `logo_source` provenance (scraped/manual, mig. 24). `scripts/fetch_logos.js` (crash-guarded). 5,609 logos live (5,608 scraped + KIPS manual). Mismatch backlog: `scripts/logo-domain-mismatches.json` (541 rows, commit b17b999) | fetch_logos.js has a socket-leak hang — see backlog before ANY rerun. 3,358 institutions have no scrapable logo (2 have no website at all) |
| Hydration fix | `WebsiteLinkButton` component — `<span role="link">`, `stopPropagation`, `window.open(..., 'noopener,noreferrer')`, keyboard handlers. Cards own ZERO anchors (nested `<a>` was invalid HTML → React hydration mismatch on /institutions) | Commits 8b1b5c9, 54ab585. Never put `<a>`, `<Link>`, or `<button>` inside a card wrapped in `<Link>` |

---

## 5. In-Flight Work

**AI search academic/skills mode toggle** (P0 — SHIPPED, live end-to-end on production as of 2026-07-20):
- Backend `src/routes/ai-search.ts`: `institutionMode` param + `resolveInstitutionTypeIds()` — academic → University/College/Community College; skills → TVET Institute/Polytechnic/Vocational School/Institute of Technology. Applied as `.in('type_id', ids)` only when mode set.
- Frontend: `SearchModeToggle` behind `NEXT_PUBLIC_FEATURE_SKILLS_TOGGLE` (byte-identical old behavior when unset).
- **Gate 1: verified 2026-07-20.** All 7 hardcoded type names match the live `institution_types` table exactly (case/spelling). Code already fails open: `modeTypeIds.length > 0` gates the `.in('type_id', ...)` call, so an empty resolution never produces `.in('type_id', [])`.
- **Gate 2: verified 2026-07-20.** Live curl matrix — baseline 1930 programs/8969 institutions, academic 1543/8926, skills 1016/42, invalid-mode probe falls open to baseline (HTTP 200 throughout).
- **Gate 3: verified 2026-07-20.** `NEXT_PUBLIC_FEATURE_SKILLS_TOGGLE=true` set to Production scope only (Preview kept at its existing empty value as a separate record), production rebuilt (dpl_GVLGt59ScecAWrXt9Dk1DVWSMPVP, main@eea2ccf, 21,509 pages), aliased to elimux.ke/www.elimux.ke/v2.elimux.ke. Playwright against the live site: toggle renders, clicking "Skills & Trades" flips `aria-pressed` and the next search correctly POSTs `institutionMode:"skills"` (captured on the wire, not simulated), mobile pill renders at iPhone-12 width, zero JS/hydration console errors (2 pre-existing favicon-fallback 404s only, same signature as the Clearbit-removal check).
- **Process note:** PR #1 on both repos merged to `main` and Railway auto-deployed BEFORE Gate 1's ruling landed — confirmed live via direct POST to `api.elimux.ke/api/ai-search`. Not a Claude Code action; flagged as a gate-integrity gap. §11 layer 3 ("Preview-only" flag scoping) is now satisfied for Preview; Production carries the flag deliberately as of Gate 3.
- Empty-name-resolution must NOT produce `.in('type_id', [])` (silently zeroes results) — confirmed the code already falls back to no filter + logs a warning (`ai-search.ts:244-250`).

**Skolex Harvest P1 — homepage hero port** (SHIPPED 2026-07-21, live on production behind `NEXT_PUBLIC_FEATURE_SKOLEX_HOME=true`):
- Spec: `elimux-frontend/design/p1-homepage-spec.md` (authored by Kimi, committed 2026-07-21)
- New components under `elimux-frontend/src/components/skolex/`: `SkolexHome`, `HeroSearch`, `HeroModePill`, `LocalizationBar`, `TrustStats` + scoped `skolex-theme.css`. `page.tsx`'s existing homepage body was renamed to `CurrentHome` and left otherwise byte-identical — diffed to confirm only an additive top-level flag branch was introduced.
- Headline copy deviated from the spec's draft ("...top 10 options") to **"Ask anything. Find your perfect course."** per the spec's own verify-first instruction — the AI search results page renders plain result grids, not a ranked top-10 shortlist.
- **Flagged deviation from §11's "existing components untouched" rule:** `ai-search/page.tsx` and `AISearchBar` got small additive changes (read `?q=`/`?mode=` via `useSearchParams`, optional `initialQuery` prop) so the hero's submit-and-navigate flow actually works — without it the spec's own §6 acceptance criteria (#3/#4) were unsatisfiable, and the spec explicitly disallowed a direct API call from the homepage as the alternative. No-op / behaviorally identical to before when the params are absent. Founder was shown this explicitly and approved the merge with it called out — not yet written up as a standing §11 exception.
- Verified on Vercel Preview (`feat/skolex-home`) via Playwright: 18/18 of spec §6's acceptance checks pass. One apparent console-error hit during testing was `<vercel-live-feedback>` (Vercel's own preview-only toolbar widget, not app code, absent on production).
- Founder approved the preview 2026-07-21 → merged to `main` same day → Production auto-rebuilt (21,509 pages, clean, homepage bundle size unchanged at 10.9 kB) → verified live: H1/subcopy unchanged, zero console errors, flag confirmed absent from Production env scope (Preview-only, unchanged).
- **Cutover DONE 2026-07-21:** `NEXT_PUBLIC_FEATURE_SKOLEX_HOME=true` added to Production scope → new build (`dpl_E8J6UCtihgko8dNuxEKy1b9H3HhH`) → verified live on `www.elimux.ke`: headline/pill/ask-box/chips/localization-bar/stats-line all render; `/ai-search/?q=medicine` auto-runs (baseline results); skills mode routes with `mode=skills`; country selection survives reload; iPhone-12 clean (no horizontal scroll); zero console errors on desktop and mobile. **P1 is SHIPPED.**

---

## 6. Backlog (prioritized)

1. **fetch_logos.js hardening** (before ANY rerun): flood-limit exit on uncaughtException (>50 → exit 1); 5-min inactivity watchdog (`lastProgressAt` → exit 1); `--out` file-logging for mismatches; root-cause the undici socket leak (agent/keepAlive config)
2. **541-entry domain-mismatch data curation** — renames/mergers need directory-entry review (e.g. University Campus Suffolk → University of Suffolk; UniSA → Adelaide merger). Benign TLD moves can be ignored
3. Monthly logo re-run cadence (only after #1)
4. Student accounts (replaces weak device-fingerprint identity)
5. Badge system: multiple criteria types (currently single)
6. Leaderboard read-after-write lag
7. Skolex Standing Queue (see §11): P1 SHIPPED (live on production 2026-07-21) — Task 3 (Partners & Advertisers homepage section) is the active queue item
8. ~~P6 Developer Platform~~ — EXCLUDED from Skolex harvest scope, founder decision 2026-07-20 (see §7); revisit only as an independent initiative if ever prioritized
9. TVET/skills data growth — skills-mode search matches only 42 institutions today vs 8,926 in academic mode (Gate 2 curl matrix, 2026-07-20); TVET Institute/Polytechnic/Vocational School/Institute of Technology directory coverage is thin relative to universities/colleges and should be expanded before P0's skills toggle is a genuinely useful discovery path
10. **Institution portal upgrade batch** (scheduled after P2, ruled 2026-07-21 from the Skolex university-portal feature diff — see §5/§7): dashboard landing screen (KPI tiles + quick actions + recent-activity feed) + profile whitelist extension (WhatsApp admissions line, virtual tour, accreditation number/body, QS/national ranking — accreditation and ranking also feed public trust badges)
11. Self-service scholarships (institution-managed, not admin-only) — needs schema + a public display surface; ruled BACKLOG 2026-07-21
12. Applications review queue (admissions pending/in-review workflow on the institution side) — real workflow feature, schedule with P5; ruled BACKLOG 2026-07-21
13. Gated student-lead unlock (Pro-paywalled contact reveal) — genuine revenue lever, but **student data triggers Kenya DPA 2019 consent/privacy design first; never sell leads without it**. Ruled BACKLOG-with-caution 2026-07-21
14. Notifications settings panel — needs notification infrastructure that doesn't exist yet; ruled BACKLOG 2026-07-21
15. Institution-run ad campaigns (institutions launching their own campaigns from their own portal, not via a separate advertiser account) — ADOPTED as direction 2026-07-21; unify with the advertiser flow during P4/P5 design, not before

---

## 7. Key Decisions Log

| Decision | Rationale |
|---|---|
| No Stripe | Paystack covers M-Pesa + cards for the target market |
| Logo scrape follows redirects; keep logo on domain mismatch, log for review | Redirect = institution's own live web presence; merged institutions are a data problem, not a logo problem |
| Logo pipeline doesn't persist failure state | Re-runs auto-retry all NULL rows (diminishing returns after pass 2) |
| Soft-delete programs (`is_active=false`) + filter embeds publicly | Preserve referential history |
| Feature flags for risky UI (`NEXT_PUBLIC_FEATURE_*`) | Backend ships dark; frontend reveal is one env var + rebuild |
| One bundled deploy per workstream | 21K-page static builds are expensive; batch DB changes before rebuilds |
| No rebrand — Skolex is harvest-only | Founder decision, 2026-07-20. ElimuX stays the brand/product/domain/SEO identity; Skolex is a frozen design reference and parts source only — never a live product |
| Four-layer isolation stack is standard for all UX-affecting work | Feature branch → Vercel Preview verified against real prod API → Preview-only feature flag → new components only (existing live components untouched). Prevents any harvest/port work from reaching production unverified (full detail: §11) |
| Skolex-embedded business decisions (plan pricing 8k/22k/35k/55k KES, 12 hero slots, agent fees) are DRAFTS pending founder ratification | These numbers are ported from the Skolex prototype for reference only — none are committed ElimuX pricing until the founder signs off |
| P6 (Developer Platform) excluded from Skolex harvest scope | Founder decision, 2026-07-20. Public /api/v1 + API keys + MCP server is a separate-initiative-sized bet, not part of the harvest program's UX/monetization/directory-vertical focus |
| Skolex university-portal feature diff ruled 2026-07-21 (Kimi, on the full inventory in §5/design/skolex-reference/html/skolex-university-portal.html) | ADOPT: dashboard landing + profile-field extension (portal upgrade batch, after P2, §6#10); institution-run ad campaigns as a direction (unify with advertiser flow in P4/P5, §6#15). BACKLOG: self-service scholarships, applications review queue, gated student-lead unlock (DPA 2019 caution), notifications panel (§6#11-14). REJECT: multi-user/RBAC — one user per institution is fine at this scale, revisit only when institutions ask. Billing tiers (#5 in the original diff) needs no separate item — already covered by P4 monetization |
| `ad_campaigns.featured` is a separate BOOLEAN from `status` | Migration 25, ratified 2026-07-21. `status='active'` means "running/billable"; `featured` means "chosen for the homepage carousel" — two independent decisions (one automatic, one curatorial), conflating them would block feature-curating without pausing a campaign |

---

## 8. Verification Cheat-Sheet

```sql
-- Logo coverage
SELECT logo_source, count(*) FROM institutions GROUP BY logo_source;

-- Types table (name from resolveInstitutionTypeIds)
SELECT id, name FROM institution_types ORDER BY name;

-- KIPS manual override intact
SELECT id, name, logo_url, logo_source FROM institutions WHERE name ILIKE '%kips%';
```

---

## 9. Git-History Timeline

*Reconstructed 2026-07-20 from `git log --date=short --pretty='%ad|<repo>|%s'` across all three repos, chronological, deduplicated.*

**2026-07-05**
- backend: ElimuX backend v1.0 - Initial build
- backend: Adapt Express app for Vercel serverless deployment
- frontend: ElimuX frontend v1.0 - Initial build
- frontend: Add backend API connectivity check to admin dashboard
- frontend: Upgrade Next.js to 15.1.9 to patch CVE-2025-66478

**2026-07-06**
- backend: Add AI-powered search endpoint using Claude Opus 4.8
- backend: Protect write endpoints with adminMiddleware
- backend: Add favorites and share-link endpoints
- backend: Fix unstable device fingerprint for favorites
- backend: Fix share_url pointing at the wrong domain
- backend: Point share redirects at the new per-item detail pages
- frontend: Add AI-powered search page with interest and career-pathway matching
- frontend: Add admin forms for creating institutions and programs
- frontend: Add dark/light theme toggle
- frontend: Add per-item detail pages for programs and institutions
- frontend: Add favorites page with share and quick-remove actions
- frontend: Fix hydration mismatch in theme toggle
- frontend: Rebrand to Golden Africa theme

**2026-07-07**
- backend: Elimux 13: Full CRUD for institutions/programs + DB-backed payments
- backend: Add missing GET /api/programs/:id endpoint
- backend: Fix POST /api/programs inserting nonexistent columns
- frontend: Add full institution/program management to admin dashboard

**2026-07-08**
- backend: docs: Add backend guardrails and pre-deploy safety check
- backend: feat: Add /api/admin/verify for the frontend's admin-key gate
- backend: feat: Add reviews API (GET/POST/helpful)
- backend: feat: Enhance AI search response with rich program cards and CTAs
- backend: fix: Resolve country/category synonyms in AI search intent
- backend: fix: Use !inner join for country filter in AI search
- frontend: feat: Add admin layout with shared nav/key, extend overview dashboard
- frontend: feat: Add filterable programs page with real Supabase data
- frontend: feat: Add reviews frontend - cards, form, and program page integration
- frontend: feat: Add soft admin-key gate before the dashboard renders
- frontend: feat: Integrate programs page into homepage with real stats
- frontend: feat: Wire /programs filters to URL query params
- frontend: fix: Use !inner join for country filter in homepage search

**2026-07-09**
- backend: feat: Add institution onboarding application endpoints
- backend: feat: Add Paystack payment integration with admin pricing management
- frontend: feat: Add institution onboarding portal
- frontend: feat: Add pricing page, payment callback, and admin pricing management
- frontend: feat: Add PWA support with offline capabilities

**2026-07-11**
- backend: feat: Add admin analytics API (ELIMUX 18)
- backend: feat: Add admin reviews moderation endpoints
- backend: feat: Add data scraper API (ELIMUX 19)
- backend: feat: Add gamification backend
- backend: feat: Add PWA backend API (17d)
- backend: feat: Add sponsor ads API (17c)
- backend: feat: Make favorites idempotent, add delete-by-item route
- backend: feat: Mount gamification router in index.ts
- backend: fix: Increase extractPrograms max_tokens 4096 -> 16384
- backend: fix: Increase scraper fetch timeout 15s -> 30s -> 60s
- backend: fix: Prevent scraper fabrication with a verbatim-presence check
- backend: fix: Raise max_tokens to 32000, retry with smaller input on truncation
- backend: fix: Restore reviews status/is_anonymous support
- backend: fix: Use streaming for extractPrograms, not client.messages.parse()
- backend: fix: Validate action_type against queued_actions' check constraint
- backend: refactor: Use shared getDeviceFingerprint from lib
- backend: chore: Add gamification badges seed script
- backend: chore: Ignore CSV data files and upload scripts
- backend: docs: Add README covering routes, identity model, env vars
- backend: docs: Document scraper fetch failures against uonbi.ac.ke and jkuat.ac.ke
- frontend: feat: Add admin analytics dashboard (ELIMUX 18)
- frontend: feat: Add admin reviews moderation page
- frontend: feat: Add BadgeShowcase component to leaderboard page
- frontend: feat: Add data scraper admin UI (ELIMUX 19)
- frontend: feat: Add gamification frontend
- frontend: feat: Add PWA frontend (17d)
- frontend: feat: Add ReferralGenerator component to leaderboard page
- frontend: feat: Add sponsor ads UI (17c)
- frontend: feat: Wire offline queue into application submission
- frontend: feat: Wire trackEvent into search, page views, reviews, shares, applications, payments
- frontend: feat: Wire useBackgroundSync into favorites and reviews
- frontend: fix: Offline queue silently dropped actions, duplicate-flushed on reconnect
- frontend: fix: Paginate generateStaticParams for institutions/[id] and programs/[id]
- frontend: docs: Add README covering routes, data access, static-export gotcha
- frontend: docs: Document analytics event tracking, add trackEvent helper
- sql: chore: Version-control Supabase SQL migrations (01-12)
- sql: docs: Add README explaining migration order
- sql: docs: Document migration 13 and the tracked-but-never-applied drift mode
- sql: fix: Add missing institution_applications columns, index analytics_events

**2026-07-12**
- backend: feat: Add accreditation bodies API
- backend: feat: Add major sponsor ("Powered by") API
- backend: feat: Add scholarships API
- backend: feat: Filter institutions by accreditation body, surface badges in list
- backend: fix: Include show_in_* placement flags in public major-sponsor response
- backend: Fix 500-vs-404 on malformed IDs; document missing env vars
- backend: Log webhook charge.success delivery for Paystack verification
- frontend: feat: Add accreditation bodies to frontend
- frontend: feat: Add major sponsor ("Powered by") to frontend
- frontend: feat: Add scholarship alert signup form
- frontend: feat: Add Scholarships page and Ranks navigation
- sql: docs: Document accreditation_bodies / institution_accreditations schema
- sql: docs: Document major_sponsors schema

**2026-07-14**
- backend: feat: Add share-search and analytics-tracking endpoints
- backend: fix: remove advertiser/campaigns/ads imports that broke the build
- backend: fix: resolve Graphic Designer career pathway to a real category
- backend: fix: stop leaking raw error messages from AI search endpoint
- frontend: chore: add Playwright testing infrastructure and dependencies
- frontend: feat: add navigation, homepage sections, and stable testing
- frontend: feat: Add program comparison, search-result sharing, and university analytics
- frontend: fix: exclude playwright.config.ts from Next.js type-check
- frontend: fix: make AI search interest chips navigate to filtered programs
- frontend: fix: remove dead category resolution from career pathway buttons
- frontend: fix: wire homepage search to the working AI search flow
- frontend: test: remove Authentication test block
- sql: feat: Add search_analytics, program_views, shared_searches tables

**2026-07-15**
- backend: feat: Add synthetic program seeding script
- backend: feat: wire advertiser/campaigns/ads routes
- frontend: feat: add program verification badges (verified, AI-generated, legacy)
- sql: feat: Add is_ai_generated/is_verified flags to programs

**2026-07-16**
- backend: fix: match actual advertisers.status and ad_campaigns.placement constraints
- backend: fix: rewrite advertiser/campaigns/ads/payments to match actual DB schema
- frontend: feat: advertiser login, register, and dashboard pages
- frontend: fix: advertiser dashboard treats 403 as unregistered, not just 404
- frontend: fix: dashboard distinguishes unregistered from pending/rejected advertisers
- frontend: fix: register page skips signUp() when a session already exists
- sql: feat: link advertisers table to auth.users, add balance/total_spent

**2026-07-17**
- backend: Add admin campaign moderation and advertiser management routes
- backend: fix: ad_payments_status_check rejects 'completed', use 'paid'
- backend: fix: click tracking uses campaign_clicks, not ad_clicks
- backend: fix: creating a campaign never actually deducted its budget from balance
- backend: fix: minimum payment 100 (was 10, sized for USD not KES)
- backend: fix: payments are wallet top-ups (advertiser_id), not campaign-scoped
- backend: fix: validate duration_days range (7-30) before hitting the DB constraint
- frontend: Add admin ad-campaign moderation page
- frontend: feat: per-campaign analytics page
- frontend: feat: rewrite campaign creation form to match actual ad_campaigns schema
- frontend: fix: billing page uses 'paid' status, not 'completed'
- frontend: fix: campaign detail page as a query param, not a [id] dynamic segment
- frontend: fix: campaigns table crash - stale field names from before schema alignment
- frontend: fix: consistent KES labeling across the whole advertiser portal
- frontend: fix: dashboard checks status === 'active', not 'approved'
- frontend: fix: enforce duration_days 7-30 range in campaign form
- frontend: fix: label billing amounts as KES, not USD
- frontend: fix: rescale billing presets to realistic KES amounts
- frontend: fix: rewrite billing page - wallet top-up model, dark theme, drop M-Pesa
- sql: feat: add campaign_clicks table, separate from ad_clicks
- sql: feat: link ad_payments to advertisers directly

**2026-07-18**
- backend: Add ad revenue to admin revenue analytics
- backend: Add institution portal: self-service accounts for claiming institutions
- backend: Add institution self-service analytics endpoint, fix admin university analytics join
- backend: Add institution self-service editing: own profile + own programs CRUD
- backend: Add subscription expiry handling and payment_method tracking
- backend: Fix program_applications date column in analytics queries
- backend: Fix: public institution detail page was showing soft-deleted programs
- frontend: Add admin advertisers page and sidebar link
- frontend: Add Analytics tab to institution portal dashboard
- frontend: Add institution portal frontend: login, register/claim, dashboard
- frontend: Add Reviews section to institution pages, fix pros/cons string mismatch
- frontend: Fix ReviewCard crash on reviews with pros/cons
- frontend: Show ad revenue on the admin revenue page
- frontend: Show expired subscription state and renewal prompt
- sql: feat: add institution_accounts table (institution portal auth)
- sql: docs: backfill README run-order table for migrations 14-16 and 18-20

**2026-07-19**
- backend: Add logo scraper (fetch_logos.js) with provenance-based write protection
- backend: Add logo-domain-mismatches.json from the completed logo scraper run
- backend: feat: add DELETE /api/admin/reviews/:id for permanent review removal
- backend: feat: rate limit, duplicate guard, and link filter on review submissions
- backend: Fix candidate selection to page past PostgREST's 1000-row cap
- backend: Fix false-positive logo match on img alt="logout icon"
- backend: fix: return 404 instead of 500 for delete/patch on nonexistent reviews
- backend: Flag cross-domain redirects instead of silently accepting them
- backend: Guard against stray socket errors crashing the full scraper run
- backend: Wire up badge bonus points and referral point payout
- frontend: Add multi-tier institution logo fallback (own logo -> Clearbit -> Google favicon -> Globe icon)
- frontend: Add offline fallback page and enable pinch-zoom
- frontend: Drop dead Clearbit tier from InstitutionLogo fallback chain
- frontend: Extract WebsiteLinkButton from InstitutionCard/FeaturedInstitutionCard
- frontend: feat: add Delete button to admin reviews page
- frontend: feat: add KIPS Technical College logo override
- frontend: Fix nested <a> hydration mismatch on institution listing cards
- frontend: Wire point-earning actions into search, reviews, and referral sharing
- sql: Add migration 24: institutions.logo_source provenance column
- sql: Add referrals.referrer_device_id and gamification_points 'badge' action type

**2026-07-20**
- backend: feat(ai-search): add optional institutionMode filter (academic/skills) — merged PR #1
- frontend: feat(ai-search): University/Skills & Trades toggle UI + placeholder modes — merged PR #1
- sql: Ratify Skolex Harvest Program (§11) and complete state doc build-out
- frontend: Add Skolex design-token reference (§11 harvest inventory) — feat/skolex-reference, PR #2 open

**2026-07-21**
- frontend: Merge PR #2 — Skolex design-token reference (docs-only)
- frontend: Add Kimi's P1 homepage hero port spec (`design/p1-homepage-spec.md`)
- frontend: feat(skolex-home): P1 homepage hero port behind `NEXT_PUBLIC_FEATURE_SKOLEX_HOME` — Preview-verified (18/18 Playwright checks), founder-approved, merged to `main`
- frontend: P1 cutover — flag flipped to Production, verified live on `www.elimux.ke`. **P1 SHIPPED.**
- frontend: Add Skolex university-portal reference HTML (§11 harvest inventory)
- sql: Kimi rules on university-portal feature diff — adopt/backlog/reject recorded in §6/§7
- sql: Draft migration 25 (platform_settings + ad_campaigns verticals/creative fields) for Task 3 Gate A — ratified by Kimi, not yet applied (awaiting founder to run it in Supabase)

---

## 10. Session Close Checklist

At the end of EVERY work session:
1. All test data cleaned (DB + auth users)
2. Migrations committed to elimux-sql
3. This file updated (new systems → §4, decisions → §7, backlog → §6, in-flight → §5)
4. Claude saves session memory notes

---

## 11. Skolex Harvest Program (ACTIVE — governing law)

**Prime directive:** ElimuX remains the brand, product, domain, and SEO identity.
NO rebrand to Skolex — decided by the founder, final. Skolex is a FROZEN design
reference and parts source only. No new features are ever built in the prototype.
All borrowed work is re-implemented inside elimux-frontend, ElimuX-branded.

**The four-layer isolation stack (mandatory for ALL harvest work):**
1. All harvest code on feature branches (feat/skolex-*) — never directly on main
2. Vercel preview deployments are the review environment, wired to the real
   production API — verified there BEFORE any merge
3. Feature flags (NEXT_PUBLIC_FEATURE_*) scoped Preview-only in Vercel —
   production builds stay byte-identical until deliberately flipped
4. New components only — existing live components are NOT modified; shared data
   libs only. Phase 1 uses read-only public API: zero backend/schema changes

**Cutover protocol (every phase, no exceptions):**
merge with flag OFF → verify production unchanged → flip flag in Vercel
Production scope → rebuild → verify live.
Rollback = flag off, or `vercel rollback` (static export = full snapshots).

**Founder rule (2026-07-20):** no change merges without the founder previewing it
first. Push the branch → wait for the Vercel preview deployment → post the
preview URL → hold for explicit founder approval before merging. No exceptions.

**Phases:**
- P0: skills/academic AI-search toggle — SHIPPED, live end-to-end on
      production as of 2026-07-20 (see §5)
- P1: homepage hero port (AI ask box + mode pill + localization bar),
      Skolex visual language, ElimuX branding — SHIPPED, live on
      production 2026-07-21 behind `NEXT_PUBLIC_FEATURE_SKOLEX_HOME`
      (now true in Production scope) (see §5 for full detail, including
      a flagged deviation from the "existing components untouched" rule)
- P2: localization config (country → qualification system + currency)
- P3: multi-vertical ads (schema + portal + homepage tabs; real campaigns only)
- P4: Monetization expansion — ad plan tiers with DB-stored pricing, hero slot
      capacity, public Advertise rate-card page, agent fees, revenue
      milestones widget *(slot reused — original P4 "rebrand" scope was
      rejected/deleted 2026-07-19)*
- P5: New directory verticals — visa-agent listings with licence verification
      workflow + tiers + success stats; Examining & Professional Bodies listing
      type + portal; TVET uses the same institution portal with type-aware
      branding
- P6: EXCLUDED — Developer platform (public /api/v1, API key issuance, docs,
      MCP server) is out of scope for the Skolex harvest program. Founder
      decision, 2026-07-20. See §7.

**Small borrow list** (lower-effort ports, not standalone phases — fold into the
nearest relevant phase above when executed):
- WhatsApp float + share tracking
- Share-card OG image
- Security-panel + platform-settings admin pages
- Country-config admin (= P2 schema)
- Bottom mobile nav (= P1)
- RBAC (deferred — no target phase yet)

**Launch-quality bar ("no room for errors"):**
- Nothing merges without passing its numbered gate; gates are binary
- Real data only in production — mock numbers, fake sponsors, fabricated
  rankings, invented metrics NEVER ship
- Money paths verified to the cent; multi-tenancy 403s proven on every
  tenant-scoped route; test data cleaned after every test
- Theme decision (light vs dark) made on preview evidence, by the founder
- §10 session-close checklist runs every session, no skipping

**Standing queue:**
1. Gate 1 — types-table list + empty-resolution behavior (P0 blocker) — DONE 2026-07-20, awaiting Kimi's ruling on Gate 2/3
2. Skolex inventory + design/skolex-reference/DESIGN_TOKENS.md committed — DONE 2026-07-20 (feat/skolex-reference, PR #2, merged 2026-07-21)
3. Phase 1 homepage spec (authored by Kimi, executed on feat/skolex-home) — DONE 2026-07-21: spec delivered, implemented, Preview-verified (18/18 Playwright checks), founder-approved, merged to `main`
4. P1 cutover — DONE 2026-07-21: flag flipped to Production, rebuilt, verified live on `www.elimux.ke` (headline, pill, ask box, chips, localization bar, stats line, mode routing, country persistence, iPhone-12, zero console errors). **P1 SHIPPED.**
5. Skolex university-portal reference (`design/skolex-reference/html/skolex-university-portal.html`) committed 2026-07-21 — full feature diff vs ElimuX's live institution portal reported for Kimi's adoption ruling
6. Task 3 — Partners & Advertisers homepage section: Gate A (schema audit + migration 25 presented for founder to run) is next
