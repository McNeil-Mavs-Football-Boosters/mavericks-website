# Site Pivot — Addendum (Schedule, Coach, Capture Checklist)

Written 2026-05-16 after Jeremy's response confirming: ship all of it, push cutover a week if needed, revise now, deprioritize Google Calendar, look at Lake Travis / Westlake.

Reads with `site_pivot.md` (the main pivot doc).

---

## 1. Schedule data source — MaxPreps is the answer

**MaxPreps already maintains McNeil's full schedule, roster, stats, and staff** at:

`https://www.maxpreps.com/tx/austin/mcneil-mavericks/football/`

What they have for free:
- Full season schedule (Varsity confirmed; sub-varsity may be more limited)
- Live and historical scores
- Final season record (25-26 is showing 2-1, 1-0 district as of latest)
- Player roster with positions and class year
- Coaching staff
- District standings
- Photo galleries (third-party photographers)
- Game recaps

This is the de facto Texas HS football schedule platform. Stats are entered by team staff and confirmed by MaxPreps editors. Texas state UIL playoff brackets flow through them.

**Phase 1 implementation:**

Don't try to embed MaxPreps (they don't offer a free embed widget, and scraping is against ToS and fragile).

Instead:
- The Schedule page has a manually-maintained admin-editable table with the 12-14 games of the season (admin enters once per year from MaxPreps or from the coach's preseason packet).
- Prominent CTA at the top of the page: **"Live scores, stats, and standings: McNeil Mavericks on MaxPreps →"** linking to the MaxPreps team page.
- Each game row has an optional `score` field admin can update after games. If skipped, just shows "Final: see MaxPreps" with a link.
- Game cards on home also use this data; "Next Game" pulls the soonest unfinished game.

**Admin maintenance burden per season:** ~30 minutes once to enter the 12-14 game schedule + optional 2-min updates after each game. If admin doesn't update scores, the MaxPreps link covers it.

**Alternatives considered:**
- Dave Campbell's Texas Football: paywalled previews, less useful for free.
- Austin Sports Journal: editorial coverage, no structured schedule.
- ScoreStream: real but obscure; visitors don't know it. MaxPreps wins on familiarity.
- Google Calendar: Jeremy explicitly deprioritized. Skip.

**Note on sub-varsity schedules:** Varsity is well-covered on MaxPreps. JV and Freshman schedules may not be. For those, the manual table IS the source of truth. Coach usually sends those once preseason.

---

## 2. Comparables — Stony Point still the best fit

Stony Point Football Booster Club (`stpfootball.org`) is the best operational comparable. Already analyzed in `site_pivot.md`.

**Lake Travis** (`laketravisfootball.com`) — blocked from direct fetch, but per snippets:
- ~400 kids in the program (McNeil is far smaller)
- Booster membership tiers with parking pass perks at higher levels
- Sub-varsity game day meal orders via online form
- TexanLive subscription stream for live broadcast
- More premium / state-powerhouse aesthetic

LT is a top-tier 6A program with state titles. Their site reflects that scale. We won't (and shouldn't) match their feature set. But the **tier-perk structure (parking pass at higher membership levels)** is worth noting — a parking pass is a real, near-zero-cost perk we could offer. Worth raising with the board.

**Westlake** (Austin Eanes ISD) — **not comparable.** Westlake uses Chap Club (`chapclub.com`), a multi-sport all-UIL-sports booster, not a football-only booster. Their model is fundamentally different. The football page lives inside the school athletic site (`westlakenation.com`) rather than on a booster-run site. Don't model on this.

**Conclusion:** stick with Stony Point as the IA reference. Borrow the parking-pass perk idea from Lake Travis. Ignore Westlake's structure.

---

## 3. Head coach situation — be aware

**Confirmed via KXAN and KERA (~May 6, 2026):** Jonathan Cruz was arrested on a charge of injury to a child. The alleged incident is from January 2024 in Arlington, where Cruz was a coach at Arlington ISD before being hired by McNeil in March 2026. RRISD says they only became aware of the investigation the week of the arrest. Cruz is on administrative leave. This is fresh, public news.

**Operational impacts on the website project:**

1. **The new site cannot launch with Cruz as head coach.** That would be a PR disaster. Whoever is interim/permanent head coach needs to be confirmed before we publish the Coaches page. Until then, list Athletic Director / Head Coach as "TBD" or leave the position blank rather than naming Cruz.

2. **No "welcome" content for any new coach until the board says it's safe.** Booster posts and homepage news that previously celebrated Cruz's hiring should be reviewed before any of that content gets migrated forward. If old "welcome Cruz" content exists on the SE site, it shouldn't move to the new site.

3. **Schedule and roster work proceed independently.** Schedule is determined by UIL / district, not by the head coach. We can build out the Schedule page from MaxPreps data without resolving the coach situation.

4. **Operational ask for Jeremy:** the next booster meeting (June 2) is going to talk about this whether you want to or not. Ask the board: who's interim head coach? Who's the contact for schedule/roster content for the 2026 season? That contact is the de facto owner of the football half of the website regardless of title.

5. **PR posture:** the booster club is **not** the school district. The website is run by the booster club. The RRISD disclaimer in our footer ("This website is maintained by the McNeil Maverick Football Booster Club and is not a part of McNeil High School or Round Rock ISD") protects the booster from being conflated with district HR decisions. That disclaimer is already in our template. Worth keeping it visible.

---

## 4. What to capture from the existing SE site before cutover

Cloudflare blocks me from fetching SE pages directly. Jeremy has SE admin access. Here's what to grab so we don't lose content. Order is "most useful" to "nice to have."

**Format: for each page, take a full-page screenshot AND copy-paste the page text/HTML to a file. Drop them in a `legacy_capture/` folder in the project.**

### Tier 1 — Must capture before cutover

These have content we'll need on the new site or that's worth preserving as historical reference.

| Page | URL | What to grab |
|---|---|---|
| Homepage | / | Full page screenshot. Note any text content, recent posts, hero image. |
| Sponsors | /sponsors | **Sponsor logos** (right-click save each one) + the names. Even though the page text is stale, the logos are the asset. Save to `legacy_capture/sponsor_logos/`. |
| Boosters / About | /boosters | Full text (mission, addresses already pulled into `site_pivot.md`, but capture anyway in case there's more). |
| Booster Committees | /page/show/5713658 | Full text. The 11 committee descriptions are already in `spec_review.md` Part 1 but verify nothing's changed. |
| Members | /members | Full page. Especially: any historical members list shown publicly. |
| Join the Club | /page/show/5665778 | Form fields (which we already know from sportsengine_capture.md), any descriptive copy. |
| Coaches & Trainers | /coaches | Full page + individual coach bio pages. We need bios for the staff who are NOT Cruz to carry forward (assistant coaches, trainers — likely remain in place). |
| Each coach bio page | /dwallin /fanara /hermes etc. | Visit each, screenshot, save text. Note phone numbers, photos. We'll re-shoot photos for the new site but keep bios as starting drafts. |
| Parent Portal landing | /parent-portal | Full screenshot. List of links + the PDF link to RRISD Athletic Safety Plan. |
| Each Parent Portal sub-link | HUDL, sportsYou, Fall Parent Meeting, Workouts (if real), Pink Out Shirts (skip) | For each: where it points (external URL) or the page content. SportsYou access code is likely stale; don't carry forward without re-validating with Cruz's replacement. |
| Stadiums | /page/... | Addresses, parking info for home + away stadiums in the district. Useful for the new site's Resources page. |
| Privacy policy | /privacy_policy.pdf | Already planned to port to MDX. Confirm it's the file we have. |

### Tier 2 — Capture if you have time, decide later whether to migrate

| Page | URL | Why |
|---|---|---|
| Ryan Murphy Scholarship | /page/... | Decide at board meeting whether it's still active. If active, we add to new site. Need history if so. |
| Ryan Murphy Award | /page/... | Same. |
| Alumni | /page/... | Decide if anyone maintains this. If yes, capture the alumni list. |
| Meals | /page/... | Active committee. Worth seeing what they had set up — sign-up links, vendors, etc. |
| Trophy Case | /page/... | If empty, skip. If real achievements, capture. |
| Web Cast | (link) | Capture the YouTube channel URL. Probably @iHSFan per dns_audit. |
| Events (each event page) | /event/show/* | If there are any non-game events with rich content (banquet info, photo shoot details), capture. Skip individual game pages. |

### Tier 3 — Reference only, don't carry forward

Skip migration but capture if you want a "we used to have this" record:

- 2019 Games-At-A-Glance
- Pink Out Shirts 2020
- Old news articles (2018)
- SportsEngine internal admin tools (Document Collector, Photo Collector, SE Help, Sponsorship Builder, For Coaches, SquadLocker, oldassets)
- 2024 schedule page (we'll have 2026 on the new site)
- 2019/2024 rosters

### What SE admin views to also capture

From `sportsengine_capture.md` we already have:
- People directory (176 members)
- Groups (13 groups)
- Registrations (3 forms)
- Sale items / donation tiers
- Invoicing
- Orders history
- Financial reports

Still TODO from sportsengine_capture.md:
- **Settings → Billing**: plan, renewal date, payment method, cardholder
- **Settings → Site**: DNS records as SE displays them
- **Settings → Payments**: confirm SE Payments is the only processor
- **Members → Groups → Booster Board**: the 7 members of that group, to cross-check with current officer roster
- **Add-Ons**: anything paid/installed beyond base plan

These don't affect the new site's content, but they affect the SE termination step (build_plan Step 20) and the security cleanup.

---

## 5. Updated open decisions

From `site_pivot.md` section "Open decisions before Step 5 spec," resolved by Jeremy's response:

| # | Decision | Status |
|---|---|---|
| 1 | Schedule data source | **Resolved**: MaxPreps link + admin-maintained table. No Google Calendar. |
| 2 | Carry forward Stadiums, Trophy Case, Alumni, Ryan Murphy, Meals, Photos | **Resolved**: defer all of these. Decide later per board input. Don't include in Phase 1. **Capture them** (per Section 4 above) so we don't lose content if we want to add later. |
| 3 | `/resources` page name | Still **"For Parents & Athletes"** in nav per my pick. Jeremy didn't push back. |
| 4 | District Standings on home in Phase 1 | Still **no**. |
| 5 | News + booster events split or combined on home | Still **separate sections**. |
| 6 | Header logo treatment | Still **type-only wordmark for launch**. |
| 7 | Cutover scope: ship all or ship lean | **Resolved: ship all, push cutover a week if needed.** |
| 8 | Step 4 work: revise now or finish first | **Resolved: revise now while staging is private.** |

**New decisions added by this addendum:**

| # | Decision | My pick |
|---|---|---|
| 9 | Should the new site list any head coach at launch, given Cruz situation? | **No.** Show "Head Coach: TBD" or hide the slot. Show only the assistant coaches and trainers we can verify are still on staff. Update once RRISD/booster confirms permanent or interim. |
| 10 | Should we migrate any "welcome Coach Cruz" homepage news or images from the SE site? | **No.** Cruz content stays off the new site entirely. |
| 11 | Borrow the Lake Travis "parking pass at higher membership tier" perk for our membership ladder? | **Defer to board.** It's a nice idea, but requires the booster to actually coordinate reserved parking spots with the stadium. Real operational cost. Don't add unilaterally. |

---

## 6. What's next for me (CC), once Jeremy confirms

1. Read this addendum + `site_pivot.md` together, make sure decisions are consistent.
2. Rewrite `schema.md` with the four new tables (`games`, `rosters`, `coaches`, `resource_links`) plus the `site_settings` additions.
3. Rewrite `content_map.md` with every page, sections, and what fields/sources each uses (per the new IA).
4. Rewrite `admin_scope.md` for the new content types.
5. Patch `build_plan.md` with the Step 4b insert and the Step 5 expansion. Update hard dates and rollback paths.

Then we restart Step 5 with the revised spec.

## What I need from Jeremy

- Confirm Section 5 decisions 9, 10, 11 (or override).
- Start working through the Tier 1 capture list. Don't have to finish before I rewrite the schema, but the sooner the better — especially the sponsor logos (likely the most time-sensitive asset to grab before SE goes away).
- At the June 2 board meeting: confirm the interim head coach contact for schedule/roster content. That's the de facto football-side owner of the website regardless of title.
