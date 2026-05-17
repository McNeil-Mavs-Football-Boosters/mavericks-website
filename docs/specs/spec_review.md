# Spec Review — Findings & Open Decisions

Created 2026-05-14 after the first pass of `content_map.md` and `admin_scope.md`.

Two sources combined here:
1. **CC's review** of `content_map.md` + `admin_scope.md` (20 contradictions/gaps/inconsistencies)
2. **SE admin spelunking** done same evening — discovered real content on the existing site that the spec should reuse

This doc tracks what's resolved, what needs a decision, and what's intentionally punted. Should be read before the schema doc gets written.

---

## Part 1 — Real content discovered on the existing SE site

The current site has more usable content than originally assumed. Pulling it forward into the spec instead of writing placeholders.

### Historical membership tier ladder (2021-22 era — for reference, not the current tiers)

Six tiers, real perks ladder. Names rotated since but structure is consistent:

| Tier | Price | Listed on Website | T-shirt | Booster sign | Cowbell | 2 T-shirts | 2 Tickets to home game | 2 Banquet tickets |
|---|---|---|---|---|---|---|---|---|
| Mav Colt | $25 | ✓ | | | | | | |
| Mav Fan | $50 | ✓ | ✓ | | | | | |
| Mav Cowboy | $100 | ✓ | ✓ | ✓ | | | | |
| Mav Family | $250 | ✓ | ✓ | ✓ | ✓ | | | |
| Field Goal Club | $500 | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | |
| Touchdown Club | $1,000 | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |

**Use:** reference pattern for the perk ladder when seeding the 2026-27 tier perks. The current tier names (Game Day / Blitz / Touchdown / etc.) likely map to a similar perk structure, just with different naming.

### Public members list pattern (already established)

The 2021-22 site had a public "Thank you to our members" page organized by tier. This validates:
- The `list_publicly` boolean on the memberships table (CC flagged this as orphan — it's not, it's the data field that powers this page)
- A `/members` route showing dues-paid members grouped by tier
- Opt-in at signup, not automatic

**Add to spec:** `/members` public route, members collection display, opt-in checkbox on `/join` form.

### Mission statement — real copy from existing site

Reuse verbatim as seed content for `/about`:

> "The purpose of the Booster Club is to provide encouragement and generate support for the football program at McNeil High School. The Booster Club is a 501(c)3 organization that works to support and improve the football program through activities for the teams and improvement of facilities and equipment. Activities in the Booster Club will include, but may not be limited to:
>
> Support and improve the McNeil Mavericks Football program and teams through:
> - Positive interaction between the Booster Club, school officials, the coaching staff, the student body, and the community.
> - Hosting and sponsoring events to build team spirit and morale amongst athletes, student body, parents, and community including pre-game and post-game gatherings, dinners, and rallies as well as an EOY awards ceremony.
> - Hosting and sponsoring events to bring the community and school together in support of the McNeil Football program.
> - Fundraising activities to provide upgrades and benefits to the teams, athletes, and program.
> - Working for the development of a constructive attitude by all students towards all levels of athletic endeavors."

### Committee descriptions — 11 real committees with content

These are the existing committee descriptions from the SE Booster Committees page. Use as seed content for `/get-involved`:

- **Social Media** — Maintain football website for communications and notification to parents and players. Maintain Facebook and Twitter accounts. Ongoing throughout school year.
- **Team Meals** — Coordinate pregame meals for freshman and JV. Discuss menu/price with Sponsor. Identify vendors, solicit bids, coordinate pickup/delivery. Coordinate Varsity parent team dinners. Football season only.
- **Membership** — Maintain membership list (emails, contact info, current player roster). Collect sign-in sheets from meetings and events. Promote the Booster Club. Ongoing.
- **Merchandise** — Vendors, pricing, design, purchase, inventory. Schedule volunteers to sell at events. Monthly report at Booster meeting. Work with Social Media to advertise. Ongoing.
- **Parent Meetings** — Date, location, volunteers for spring/fall parent meetings. Work with Social Media, Merchandise, Membership committees. Two-time activity.
- **Football Banquet** — Date, time schedule. Cafeteria booking. Vendor bids. Awards coordination with Sponsor. Volunteer coordination for ads, tickets, decorations, senior gifts. Media show. One-time activity.
- **Summer Events** — Pool location, volunteers, food donations. Advertise via Social Media. One-time activity.
- **Meet the Mavs** — Date with Sponsor/Principal. Coordinate with other booster clubs. Food vendor bids. Tables, volunteers. One-time activity.
- **Senior Night** — Game date set by RRISD. Senior names from Sponsor. Permissions, flower vendors, volunteers. One-time.
- **Tunnel Stampede** — Event date. Business sponsorships. Advertise via Social Media. Application/payment design. Spirit wear order. Volunteers. One-time.
- **Fundraisers** — Oversee any board-determined fundraisers. Coordinate with Social Media. Ongoing.

**Note:** Committees communicate via **GroupMe**, not the platforms in `booster_club_info.md` (SportsYou, Facebook, iMessage, newsletter). Adding GroupMe to the comms platform list.

### Make a Donation URL (current SE registration)

`https://mcneilmavericks.sportngin.com/register/form/096820484`

This is the link the current "Make a Donation" button points to. Useful for:
- Knowing what we're replacing
- Deciding whether to set up a redirect post-cutover or just kill the URL

### Sponsors page on existing site is just placeholder

The current SE site has a sponsor page template but **no actual sponsor data is populated**. The 7 sponsor names from `dns_audit.md` (AutoNation, Book My ER, etc.) must be from a different source — probably the homepage footer at one point, or a prior version of the page. Worth confirming with Kendra whether any of those 7 should be re-approached for 2026-27.

### Brand asset captured

The McNeil helmet + wordmark image was extracted from CSS via dev tools (`background-image` on `div.site-banner-wrapper`). Saved to local `assets/reference/`. School-branded image (helmet + "MCNEIL HIGH SCHOOL" wordmark in green), reference only — we won't use it directly on the new site pending logo authorization (open item).

### What's intentionally NOT being preserved

Re-confirming items the spec drops:
- Parent Portal (HUDL, SportsYou, Fall Parent Meeting, Workouts, Pink Out Shirts 2020 — all stale or moving to SportsYou)
- "Assets" and "MavNation" submenu items (member-only, stale)
- "More +" overflow items (Schedule — disabled, etc.)
- 2024 Mavs Schedule (school owns)
- Coaches + Trainers (school owns, also stale — 14 last names no first names)
- Rosters (school owns, 2 years stale)
- Past board officer list (Image 4 showed 2024 board — different from current 2026-27 board in `booster_club_info.md`)

---

## Part 2 — CC's contradictions (need resolution before schema)

### C1. Stripe in Tier A vs. Phase 2

**Conflict:** `admin_scope.md` puts Stripe Checkout + one-time donation in Tier A (cutover-critical). `CLAUDE.md` build plan says Phase 1 = content shell, Phase 2 = Stripe.

**Reality check:** The whole point of the new site is to fix the "8 of 15 invoices stuck in email-sent / $770 uncollected" gap from the actual 2026-27 form data. If Phase 1 ships without payments, we ship a brochure site and the booster club's biggest pain point is unfixed.

**Resolution proposal:** Move Stripe Checkout into Phase 1, update `CLAUDE.md` to reflect. **Needs Jeremy's call.** This expands Phase 1 scope; the alternative is shipping cutover without payments and pushing the money fix to month 2.

**Status:** ⚠️ Needs decision

### C2. Ashley Olson vs. Ashley Root

**Conflict:** Two different Ashleys across the project files.

- `sportsengine_capture.md` + `credentials.md`: **Ashley Olson**, `aolson@jatx.com`, pending SE admin, President role
- `content_map.md` seed + `booster_club_info.md`: **Ashley Root**, `Jtwogtwo@gmail.com`, Co-Treasurer (past President)

**Resolution proposal:** Likely the same person; "Root" is probably her current married/preferred name and Olson was on the SE invite from earlier. **Jeremy confirms.**

**Status:** ⚠️ Needs decision

### C3. Email alias lists differ across three docs

Three different alias sets:
- `credentials.md`: boosters@, president@, treasurer@, secretary@, webmaster@ + VP aliases
- `next_steps.md` 3a: president@, treasurer@, secretary@, webmaster@, boosters@, info@
- `content_map.md` site settings: president, treasurer, secretary, webmaster, sponsorship, volunteer

**Resolution proposal:** Canonical list for Phase 1 = `boosters@` (general / info alias), `president@`, `treasurer@`, `secretary@`, `webmaster@`, `sponsorship@`. Drop `volunteer@` (volunteers contact via the form or board members). Drop separate `info@` (alias `boosters@`). VP aliases optional, defer.

**Status:** 📝 Proposed; need Jeremy's nod

---

## Part 3 — CC's gaps (missing source material)

### G4. RRISD disclaimer wording

Both specs treat it as "hardcoded with a known-good default" but the actual wording isn't captured anywhere. Stony Point's site uses:

> "This website is maintained by the [club] and is not a part of [school] or Round Rock ISD. Neither [school] nor Round Rock ISD is responsible for the content or opinions within this website."

**Resolution proposal:** Use Stony Point's wording with names swapped. Verify against RRISD's actual policy (item 8 in `next_steps.md`) before launch. Phase 1 ships with this string; can be adjusted in site settings if needed.

**Status:** 📝 Proposed; verify with RRISD before launch

### G5. "What dues fund" copy

Referenced as a "trust-building section" on `/about` but no source copy exists in project files. **Real board ask.** Treasurer (Chevon) is the right person — she knows what the money actually went toward last year.

**Status:** ⚠️ Needs board input — formal ask for May/June meeting

### G6. $0 Free Fan Base tier × Stripe Checkout

Stripe rejects $0 charges. 7 of 35 actual signups picked Free Fan Base. Spec needs a bypass path.

**Resolution proposal:** Free Fan Base ($0) skips Stripe entirely — form submits directly to `memberships` table with `payment_id = null` and `paid = true` (since there's nothing to pay). UI shows "Sign up free" instead of "Pay $0". All other tiers go through Stripe Checkout.

**Status:** 📝 Proposed; design decision, locked

### G7. `list_publicly` field has no corresponding feature

**Resolved by Part 1 above.** This field powers the `/members` page (a real pattern from the 2021-22 site). Adding `/members` route to spec. Opt-in checkbox added to `/join` form.

**Status:** ✅ Resolved — adding `/members` route + opt-in checkbox

### G8. SportsYou opt-in workflow

`memberships.sportsyou_optin` is captured. How it gets into SportsYou (manual CSV? API? nothing?) is undocumented.

**Resolution proposal:** Phase 1 = capture only, no automation. Admin can export memberships to CSV (already in scope). Kendra manually imports SportsYou-opted-in rows into her SportsYou setup. Document as a manual process in the admin handbook (Phase 3 deliverable).

**Status:** 📝 Proposed

### G9. Memberships admin: view-only or full CRUD?

CC's question. Real-world need: 8 unpaid invoices from the current cycle need someone to clean up during migration.

**Resolution proposal:** Full CRUD for memberships. Admin can edit any record, manually mark paid (e.g., for cash/check payments outside Stripe), delete (with confirmation). Audit trail via `last_edited_by`. This is essential for migrating the existing 35 signups from the Google Form.

**Status:** 📝 Proposed; locking unless Jeremy objects

### G10. May 5 / 7 / 8 meetings happened — does spec reference June 2?

**Source clarification:** The project files reference May 5 as the upcoming meeting. CC mentions May 7 and 8 minutes existing. Either CC is reading from a project file Jeremy hasn't shared yet, or there's confusion about dates. **Need Jeremy to clarify.**

If May meetings resolved any of the open items (board roster, logo authorization, mission copy, mailing address), the spec should reflect those decisions.

**Status:** ⚠️ Needs Jeremy clarification

### G11. Privacy policy: reuse PDF, port to MDX, or write new?

Existing site serves `/privacy_policy.pdf`. New site spec says "MDX in repo, set once."

**Resolution proposal:** Port the existing PDF content to MDX (better SEO, better mobile UX, no PDF download required). Review against Stripe's required disclosures for accepting payments online (data collection, refund policy, etc.). May require minor additions. **Webmaster task, not board task.**

**Status:** 📝 Proposed; do during Phase 1 build

### G12. Logo authorization status post-May meetings

Sylvia was asking at the April 13 meeting. Status after May meetings unknown.

**Status:** ⚠️ Needs Jeremy clarification or formal ask

---

## Part 4 — CC's minor inconsistencies (cleanup)

### M13. Tier numbering off-by-one in admin_scope.md

Tier B restarts at 9 instead of 10. Tier C lists 13, 14 instead of 14, 15. **Trivial fix when updating admin_scope.md.**

**Status:** 📝 Fix on next edit

### M14. "14 admin-editable content types" includes apparent duplicates

"Board roster" + "Board photos" likely same admin surface. "Homepage hero / CTA" + "Hero image" same. **Reduce to one entry each, clarify they're sub-fields not separate types.**

Real count is closer to 12 content types.

**Status:** 📝 Fix on next edit

### M15. `featured_badge` (string) vs `featured` (boolean)

Membership tier has `featured_badge` (string like "Most Popular"). Sponsorship tier has `featured` (boolean).

**Resolution proposal:** Standardize on `badge_label` (string, nullable) for both. Empty = no badge. Clearer than boolean for non-technical admins.

**Status:** 📝 Proposed for schema doc

### M16. Year format: "2026" vs "2026-27" school year

Booster club operates on school year (Feb-Jan per `next_steps.md`).

**Resolution proposal:** Use `"2026-27"` format for all year fields. More accurate, matches the form filename Jeremy uploaded (`Membership 2026-2027`). Cost: 7 characters instead of 4.

**Status:** 📝 Proposed; locking unless objection

### M17. Quick action cards constraint not in data model

Prose says "3 cards from a fixed set of 5." Schema is free-form.

**Resolution proposal:** Add `enum` constraint on quick action card type in site settings: `join | sponsor | donate | volunteer | newsletter`. Admin picks 3 from these 5; each renders with appropriate icon/label.

**Status:** 📝 Proposed

### M18. SE `/members` page (176 entries) killed by new spec — name it

The 176-person directory in SE goes away. Most were 2019-era anyway and we're not auto-importing. **Acknowledge explicitly so it's not a surprise.**

**Status:** 📝 Add note to spec under "What's intentionally NOT being preserved"

### M19. Board roster email_alias field assumes role mailboxes exist

If board roster ships before role mailboxes (`president@`, `treasurer@`, etc.) are live, displayed emails bounce.

**Resolution proposal:** Block board roster from showing email aliases until `next_steps.md` item 3a (Cloudflare Email Routing) is done. Phase 1 ships with email field nullable — show only if populated, otherwise "Contact via boosters@" fallback.

**Status:** 📝 Proposed; ordering dependency

### M20. Membership signup form depends on tiers existing

Implicit but unstated. Form can't render without tiers in DB.

**Resolution proposal:** Build order in Phase 1: seed tier data → build admin tier CRUD → build public form. Already implied by Tier A ordering; doesn't need a spec change, just a note.

**Status:** ✅ Noted

---

## Part 5 — Decisions Jeremy needs to make (consolidated)

Most actionable list. Items below need a yes/no/proposal before schema doc can be written.

| # | Decision | Default if no decision | Blocking? |
|---|---|---|---|
| C1 | Stripe in Phase 1 (cutover-critical) or Phase 2 (post-launch)? | Phase 1 (per spec) | Yes — biggest scope question |
| C2 | Ashley Olson and Ashley Root are the same person? | Assume yes | No |
| C3 | Canonical email alias list (proposal above) | Use proposal | No |
| G4 | RRISD disclaimer wording (Stony Point pattern) | Use proposal | No |
| G5 | "What dues fund" copy — ask Chevon | Placeholder text | No (admin-editable later) |
| G9 | Memberships full CRUD with manual-paid override | Yes per proposal | No |
| G10 | What happened at May meetings? Did anything get resolved? | Assume nothing | Affects open-item tracking |
| G12 | Logo authorization status after May meetings? | Assume not yet | No (type-only branding works) |
| M16 | Year format "2026-27" (proposed) vs "2026" | Use "2026-27" | No |

---

## Next steps (proposed order)

1. **Jeremy answers Part 5 decisions** (most are quick yes/no, biggest is C1)
2. **Update `content_map.md` and `admin_scope.md`** to reflect resolutions:
   - Add `/members` route
   - Add Free Fan Base $0 bypass path
   - Add committee descriptions seed data
   - Add mission statement seed data
   - Fix tier numbering, dedupe content types, standardize badge field, switch to "2026-27" year format
   - Update Stripe phase decision (C1)
3. **Write the data model / schema doc** based on the reconciled specs
4. **Then** the Phase 1 build plan working backward from cutover

---

## What CC should do

Hold position. Don't scaffold, don't write schema. Reading this doc and the (soon-to-be-updated) spec docs is the next CC task. When Jeremy says "go," CC's next job is to surface anything in this resolution that doesn't survive contact with the schema.
