# Followups

Items surfaced during the Phase 1 build that aren't blocking the current step but need attention before launch or in early Phase 2. Append-only. Mark items done when resolved.

## Security
- [ ] Rotate Supabase anon key (exposed in chat 2026-05-16 during 4c setup). Studio → Settings → API → rotate, then update .env.local and Vercel env vars.
- [ ] Rotate Supabase service_role key (briefly in chat during original Steps 1-3 setup). Same process.
- [ ] Verify .env.local is gitignored and has never been committed (git log --all --full-history -- .env.local should return nothing).

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
- [ ] Audit all Storage buckets — confirm MIME and size restrictions match the spec for each. sponsor-logos and event-images are spec'd as image buckets (5MB, png/jpeg/webp) but currently show "Any" and 50MB. news-images may also need tightening. documents should keep "Any" and a larger limit.

## Spec drift to consolidate post-launch
- [ ] Collapse the v2 doc trail (site_pivot + addendum, schema_v2 + 3 addenda, content_map_v2 + 2 addenda, admin_scope_v2, build_plan_v2) into clean canonical docs. Per build_plan_v2 "Post-Step-20" section.
- [ ] Update CLAUDE.md to reflect Phase 1 completion state once cutover is done.

## Phase 2 / deferred
- [ ] Bulk player import (paste mode primary, CSV upload optional). Spec'd in conversation 2026-05-16; folded into Step 7b admin rosters CRUD.
- [ ] Stats per player (Phase 2 pickup per addendum 2).
- [ ] Lake Travis "parking pass at tier" perk idea for membership ladder. Board input needed.
- [ ] Other Mavericks Sports outbound links on /resources page (after Jeremy has the URLs).
