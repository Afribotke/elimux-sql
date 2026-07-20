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

**Phases:**
- P0: skills/academic AI-search toggle (in flight — Gate 1 pending)
- P1: homepage hero port (AI ask box + mode pill + localization bar),
      Skolex visual language, ElimuX branding
- P2: localization config (country → qualification system + currency)
- P3: multi-vertical ads (schema + portal + homepage tabs; real campaigns only)
- P4: DELETED — rebrand rejected

**Launch-quality bar ("no room for errors"):**
- Nothing merges without passing its numbered gate; gates are binary
- Real data only in production — mock numbers, fake sponsors, fabricated
  rankings, invented metrics NEVER ship
- Money paths verified to the cent; multi-tenancy 403s proven on every
  tenant-scoped route; test data cleaned after every test
- Theme decision (light vs dark) made on preview evidence, by the founder
- §10 session-close checklist runs every session, no skipping

**Standing queue:**
1. Gate 1 — types-table list + empty-resolution behavior (P0 blocker)
2. Skolex inventory + design/skolex-reference/DESIGN_TOKENS.md committed
3. Phase 1 homepage spec (authored by Kimi, executed on feat/skolex-home)
