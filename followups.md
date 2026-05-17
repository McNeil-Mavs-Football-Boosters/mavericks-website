# Followups

Items surfaced during the Phase 1 build that aren't blocking the current step but need attention before launch or in early Phase 2. Append-only. Mark items done when resolved.

## Security
- [ ] Public pages currently use createServerClient (service role) which bypasses RLS. Switch to anon client before any admin pages land. Affects: every page in app/(public)/. Not blocking Commit B.
- [ ] Rotate Supabase anon key (exposed in chat 2026-05-16 during 4c setup). Studio → Settings → API → rotate, then update .env.local and Vercel env vars.
- [ ] Rotate Supabase service_role key (briefly in chat during original Steps 1-3 setup). Same process.
- [ ] Verify .env.local is gitignored and has never been committed (git log --all --full-history -- .env.local should return nothing).
- [ ] Investigate news-images Studio policy anomaly: Studio shows 4 policies on news-images while other migration-009 buckets show 0. May indicate Studio-side policies added outside of migrations. Run `SELECT policyname FROM pg_policies WHERE schemaname = 'storage' AND tablename = 'objects' AND qual::text LIKE '%news-images%'` and reconcile against migration 009's policy array before launch.

## Pre-cutover content
- [ ] 2025 varsity game results seeded for June 2 board demo. Add as a separate migration (018c or similar) after 025 lands, before the demo.
- [ ] Verify Kelly Reeves Athletic Complex address (10211 W Parmer Ln). Seeded value needs confirmation.
- [ ] SE Tier 1 capture: sponsor logos, coach bios (non-Cruz), parent portal links, stadium info, SportsYou access code. Per site_pivot_addendum.md section 4.
- [ ] Confirm interim head coach contact at June 2 board meeting. That person owns football-side website content.
- [ ] Decide on additional coaches to seed beyond Wallin and Hale (Fanara, Hermes, Dubois pending verification).

## Pre-cutover ops
- [ ] Second super_admin account for Carol with 2FA + recovery codes.
- [ ] Institutional super_admin accounts (president@, webmaster@) wired through Cloudflare Email Routing to personal inboxes.
- [ ] Mobile QA pass: open every public route on iPhone, fix anything broken. Step 14 territory.

## Spec drift to consolidate post-launch
- [ ] Collapse the v2 doc trail (site_pivot + addendum, schema_v2 + 3 addenda, content_map_v2 + 2 addenda, admin_scope_v2, build_plan_v2) into clean canonical docs. Per build_plan_v2 "Post-Step-20" section.
- [ ] Update CLAUDE.md to reflect Phase 1 completion state once cutover is done.

## Privacy / display preferences
- [ ] Anonymous donor option: donors must be able to choose "Anonymous" so their name does not appear on any public donor list/recognition. Needs flag on the donation record (and form UI) plus enforcement on whatever public surface renders donors.
- [ ] Member name-hide flag: members should be able to opt out of having their name displayed publicly. They are still a member of record, but no public surface (member lists, recognition, etc.) renders their identifying info. Needs flag on the member record (and signup/membership-edit UI) plus enforcement on every public query that touches members.

## "Visual polish (Phase 1.5)" section:

- Rudy's-style aesthetic pass: bolder header band, accent colors beyond Mavs green, type with more personality, stronger CTA buttons
- Hero carousel on home page rotating background images every 6 seconds (stadium shots, game action photos)
- Real McNeil photography: players, stadium, sidelines, game action
- Logo treatment beyond the current wordmark
- All of the above gated on photo asset gathering (Track A) and post-cutover

These are not blockers for Commit B, Commit C, or Phase 1 cutover. Capture so they don't get lost.

## Phase 2 / deferred
- [ ] Bulk player import (paste mode primary, CSV upload optional). Spec'd in conversation 2026-05-16; folded into Step 7b admin rosters CRUD.
- [ ] Stats per player (Phase 2 pickup per addendum 2).
- [ ] Lake Travis "parking pass at tier" perk idea for membership ladder. Board input needed.
- [ ] Other Mavericks Sports outbound links on /resources page (after Jeremy has the URLs).
