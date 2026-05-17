# Site Pivot — Inventory & New IA

Written 2026-05-16 after Jeremy clarified that mcneilmavericks.org is the **McNeil HS football public website** (run by the booster club because no one else does), not the booster club's own website with football info bolted on. The booster club's CRM stuff (memberships, sponsorships, donations, board) is a **section within** the football site, not the whole site.

This doc replaces the "drop these as school-owned" framing in `spec_review.md` and `content_map.md`. Most of those pages weren't school-owned; they were just stale. We're rebuilding them, with admin tooling cheap enough that they don't go stale again.

Reads with `spec_review.md` (open decisions log), `schema.md` (data model, due for an update), `build_plan.md` (Step 4 shipped; Step 5+ needs revision).

---

## What I could and couldn't capture

**Could:** the existing site's nav structure (from Jeremy's Parent Portal + More+ screenshots), every URL that's appeared in search results or in `dns_audit.md`'s sitemap, and full content for two key pages (`/boosters`, `/page/show/5713658-connect-with-a-committee-and-volunteer`, `/sponsors`) via search snippets.

**Couldn't:** direct fetches of individual SE pages — SE is behind Cloudflare and 403s every request without a real browser. For pages where I have only the URL and the page title, I've flagged them as "not yet captured." Jeremy can fill those gaps from his admin login or by sending screenshots.

---

## Existing site inventory

Every page I could identify on the current site, what it contains, and where the content is fresh, stale, or empty. Stale and empty pages still get rebuilt — we just rebuild them right and put an editor in admin to keep them current.

### Primary nav (top bar)

| Nav item | URL | Content (best knowledge) | Freshness |
|---|---|---|---|
| Home | / | Homepage. News articles from 2018, no recent updates. | Stale |
| 2024 Mavs Schedule | /mavsschedule | "Practice Sched - 10/29/24", "2024 Varsity Game Schedule", "2024 JV Game Schedule". No 2025 or 2026 data. | Stale (one year old, label still says "2024") |
| Coaches + Trainers | /coaches | Lists: Athletic Coordinator + Head Football Coach (phone 512.464.6502), Linebackers, Offensive Coordinator + OL, Wide Receivers, OL + Special Teams Coord, Cornerbacks + Track, Defensive Tackles + Track, Defensive Coach, WR + Asst Baseball, Safeties + Asst Baseball, Lead Athletic Trainer (512.464.6503), Assistant Athletic Trainer. Plus individual coach bio pages: `/dwallin`, `/fanara`, etc. (12 total per dns_audit). | **STALE — head coach changed.** New AD/Head Coach Jonathan Cruz announced March 14, 2026 per the program's Facebook page. Wallin is the prior coach. |
| Rosters | /page/show/5974814 | 2019-2024 era rosters per dns_audit and SE admin. | Stale |

### Boosters dropdown

| Nav item | URL | Content | Freshness |
|---|---|---|---|
| Booster Club | /boosters | Full mission statement (already pulled into `spec_review.md` Part 1). **Plus: mailing address.** McNeil Maverick Football Booster Club #412, 6001 W Parmer Ln, Suite 370, Austin TX 78727. Plus physical address: McNeil HS, 5720 McNeil Dr, Austin, TX 78727. | Content is fine; the registration link points to the SE form |
| Join the Club | /page/show/5665778 | Registration form (the 2021 SE form per sportsengine_capture.md) | Stale form (2021) |
| Members | /members | "Membership is open to all who support MavNation Football! Memberships are valid February 1st - January 31st." Plus copy promoting sponsorships and volunteering. | Copy fine; member list itself is stale |
| Booster Committees | /page/show/5713658 | Full descriptions of 11 committees (already pulled into `spec_review.md` Part 1) | Fine |
| Booster Calendar | (greyed out) | Disabled in nav | Empty |
| Make a Donation | (registration link) | SE donation form — last orders Aug 14, 2024 | Stale (no donations in ~9 months per sportsengine_capture.md) |

### Parent Portal dropdown

This is what your wife and other parents actually use. Not admin-only. Stale, but used.

| Nav item | URL | Content | Freshness |
|---|---|---|---|
| (landing) | /parent-portal | "LINKS FOR 2021-22": UIL, Medical History Form 2021, RankOne Online Forms, UIL Strength & Conditioning Program, RRISD Athletic Safety Plan for COVID (PDF) | **Stale 5 years.** Bones are right; links need refresh. Per the JV Roster snippet I found, "Register My Athlete is now aktivate.com" so RankOne link is dead. |
| HUDL | (external) | Link to hudl.com | Working |
| sportsYou | /page/... | Page with a unique access code, "You've been invited to join McNeil Football" via SportsYou. | Working but the code may be old |
| Fall Parent Meeting | /page/... | Presumably docs/dates | Not yet captured |
| Workouts | (greyed) | Disabled | Empty |
| Pink Out Shirts 2020 | (greyed) | Disabled | Empty 2020 leftover |

### More + dropdown

Image 4 (admin-mode visible items, SE-platform internal stuff): Document Collector, Photo Collector, SportsEngine Help, Sponsorship Builder, Meals, For Coaches, SquadLocker, Trophy Case, 2019 Games-At-A-Glance, Events, oldassets.

**Don't carry forward**: Document Collector, Photo Collector, SE Help, Sponsorship Builder, For Coaches, SquadLocker, oldassets — these are SE platform admin tools. Not public content.

Image 5 (public items): Sponsors, Stadiums, Photos, Ryan Murphy Scholarship, Ryan Murphy Award, Alumni, Web Cast.

| Nav item | URL | Content | Freshness |
|---|---|---|---|
| Sponsors | /sponsors | "The McNeil Maverick Booster Club would like to thank our Sponsors. McNeil Community - Please Support Our Sponsors with Your Business (Click logos for more information.)" Plus: "Thank you for your interest in supporting Maverick Football. Please download the 2022-2023 Maverick Football Sponsorship Form." | **Sponsor logos are on the page** — the homepage in `dns_audit.md` listed 7 (AutoNation Chevrolet West Austin, Book My ER, MSF Electric, Pediatric Dentistry of Round Rock, Pioneer Vision Care, TKO Mechanical, Luv Braces). Sponsorship form is 3 years stale. |
| Stadiums | /page/... | Presumably address/parking info for home + opponent stadiums | Not yet captured. Worth keeping — useful for away games. |
| Photos | /page/... | Photo galleries | Not yet captured. Stony Point uses Instagram embed instead. |
| Ryan Murphy Scholarship | /page/... | Memorial scholarship. Need to ask board: is this still active? Who's Ryan Murphy? | Not yet captured |
| Ryan Murphy Award | /page/... | Memorial award | Not yet captured |
| Alumni | /page/... | Tracks former players | Not yet captured. Stony Point has a "Tigers in College" version of this. |
| Web Cast | (external?) | Game broadcasts | Per dns_audit, links to YouTube @iHSFan |
| Meals | /page/... | Probably team meals sign-up — pregame meals for freshman/JV | Not yet captured. Committee is real (in committee descriptions) |
| Trophy Case | /page/... | Team achievements | Not yet captured |
| 2019 Games-At-A-Glance | /page/... | 2019 season summary | Stale 7 years |
| Events | /events | Generic booster events. Visible event URLs: JV Mavs vs Round Rock (Sept 19 2024), JV Mavs vs Vandergrift (Oct 3 2024). | Stale |
| Schedule (under MavNation submenu) | (greyed) | Disabled | Empty |

### Other URLs from sitemap (dns_audit.md)

- 3 news articles from 2018 (3rd Annual Pool Party, 2018 Signed Mavs, Freshman Camp 2018) — don't migrate.
- `/privacy_policy.pdf` — port to MDX (already planned in Step 4).

### What's missing from the existing site but the new one should have

Things Stony Point has that McNeil does not:
- Newsletter (Stony Point has "Tiger Roar" — recurring email + archive on site)
- Hype Video (annual)
- Mixtapes by year (game highlight reels — these are also YouTube embeds)
- District Standings table
- Online shop / merch (separate from booster store, this is team-branded gear)
- Online sponsorship form (McNeil has a downloadable PDF form, Stony Point has a web form)
- Scholarship application process page

---

## Comparable: Stony Point (stpfootball.org)

Same district (25-6A), same booster-runs-the-football-site model, same RRISD compliance disclaimer pattern (already templated into our schema). Built on WordPress + WooCommerce. Their IA is the closest "this is what we should look like" reference:

**Top nav:**
- **Teams** → Schedules (Var/JV/Frosh), Rosters (Var/JV/Frosh Gold/Frosh Blue/Frosh Combined), Coaches, Student Trainers and Film Crew
- **Membership** → Executive Board, Members list, Join the Club, Volunteer Opportunities, Tiger Roar Newsletter (Subscribe + Archive), How We Support, Bylaws (PDF), Minutes
- **Events** → 7 named recurring events (Mulch Madness, Sports Physicals, Ladies Chalk Talk, Reverse Raffle, Program Tributes, Mothers of Fall Photo Shoot, Football Banquet)
- **Sponsorship** → Sponsors list, Sponsorship Opportunities
- **News**
- **Media** → Hype Video, Mixtapes (by year), Scholarship Recipients (by year), Tigers In College
- **Donate** → Donate, Company Match Program
- **Shop** (with cart)

**Homepage sections, top to bottom:**
1. Hero image (banner with team imagery / district affiliation)
2. **Quick Links band** — 6 large clickable links: Become a Booster, Sponsor the Team, Sports Physicals, Make a Donation, Volunteer Opportunities, Subscribe to Newsletter
3. Upcoming Events (auto-populated from events)
4. Latest News (3 most recent, thumbnail + excerpt)
5. Instagram Feed embed
6. **Sponsors carousel** (20 logos scrolling horizontally, all equal-sized on the home page)
7. **District Standings** (table: school, district record, overall record — pre-season shows 0-0 for all)

**Footer:**
- Home, Membership, Sponsorship, Contact Us
- Social icons (FB, Twitter/X, Instagram, YouTube)
- RRISD disclaimer (verbatim — ours uses the same template)
- Copyright

### What's good about Stony Point that we should copy

1. **Football-first framing.** Booster stuff lives under "Membership," not as a top-level concept. Visitors come for game info, get the booster pitch passively via Quick Links and Sponsors strip.
2. **Quick Links band as the dominant home page feature.** This is where the booster club's calls-to-action live without dominating the page.
3. **Named recurring events.** Banquet, Photo Shoot, Reverse Raffle — each has its own URL that can be permalink-shared in flyers. They're not just generic calendar entries.
4. **Year-tagged content.** Schedules tagged by year (2026 Varsity Schedule), Mixtapes by year, Scholarship Recipients by year. Old years stay browsable.
5. **Sponsors carousel on home, full Sponsors page elsewhere.** Home strip is tier-flat (equal logos). Full page can be tiered (it isn't on Stony Point's site, but we'd want it tiered for our $5K MVP vs $500 Blue).
6. **Sponsorship Opportunities page** with online form, not a downloadable PDF.

### What we'd do differently from Stony Point

1. **Don't ship a Shop in Phase 1.** Stony Point uses WooCommerce. We'd have to build it on Stripe. Push to Phase 3 per current plan.
2. **Skip the Instagram embed in Phase 1.** Adds another integration. Link to socials in the footer is enough.
3. **District Standings: skip Phase 1.** Either find an API source or accept that it has to be manually updated weekly. Maybe Phase 2.
4. **Scholarship section: only if McNeil has one.** Open question for the board.
5. **Mixtapes by year: only if we have them.** Open question for Sylvia / Kendra / new head coach.

---

## Proposed IA for the rebuild

Cheap to build (most pages are admin-editable markdown), admin-friendly (one consistent CRUD pattern), better than today.

```
Home
Schedule
Roster
Coaches & Trainers
News
Sponsors
For Parents & Athletes   ← replaces "Parent Portal"
Boosters ▼
   ├ About the Booster Club
   ├ Join / Become a Member
   ├ Members
   ├ Sponsorship Opportunities
   ├ Volunteer
   ├ Committees
   ├ Board
   ├ Calendar / Events
   ├ Newsletter (later)
   └ Documents (bylaws, minutes, IRS letter)
Donate
About / Contact
```

11 top-level nav items including dropdowns. Footer carries Privacy + disclaimer + socials.

### Page-by-page

**Home** — see "Homepage proposal" below.

**Schedule** — single page, 3 sections in tabs or stacked: Varsity, JV, Freshman. Each section: simple table (Date, Opponent, Location, Home/Away, Time, Result). For Phase 1, **embed the existing Google Calendar feeds** (the screenshot Jeremy sent shows there's already a "McNeil Football Calendar" Google Calendar). Each table powered by an iCal/Google Calendar feed lets the coach/AD update one source and have it appear here. **Cheapest possible.** Optional admin override: if the coach refuses to use the calendar, we have a manual game CRUD as fallback.

**Roster** — single page, 3 sections (Varsity, JV, Freshman). Each is a simple admin-editable rich-text section. Coach typically sends a roster as a PDF or Word doc once before the season; admin pastes it in. Year-tagged in admin so 2025 stays browsable next to 2026.

**Coaches & Trainers** — single page. Coach grid (name, role, photo, phone, bio). New table needed in DB (separate from `board_members`). Note: head coach is now Jonathan Cruz, not Wallin. Must update on launch.

**News** — already in schema, no change. Used for both team news and booster news. Tag-by-category if useful.

**Sponsors** — already in schema. Phase 1: tiered display on the public `/sponsors` page (MVP > Diamond > Platinum > Gold > Blue), flat strip on home. Add a "Become a Sponsor" CTA pointing to a `/boosters/sponsorship` form (Stripe-backed).

**For Parents & Athletes** — single page. Curated link list. Replaces Parent Portal AND the public parts of More+. Sections:
- **Registration & Forms**: Aktivate (current state of RankOne), UIL forms, Medical History form, RRISD athletic forms
- **Communications**: HUDL (link out, with team code), SportsYou (link + current invite code)
- **Resources**: workouts, summer conditioning info, Fall Parent Meeting docs
- **Stadiums & Parking**: home stadium, away stadium addresses (the existing Stadiums page)
- **Other**: anything else the board wants here

Powered by an admin-managed "links" table (label, URL, section, sort_order, active). Cheapest possible.

**Boosters ▼** — most of what we've already specified, just nested under a section.
- About the Booster Club = the existing /boosters mission + addresses + 501(c)(3) info
- Join = the Stripe-backed signup form (current spec)
- Members = the public_members view (current spec)
- Sponsorship Opportunities = tier ladder + signup form (current spec)
- Volunteer = volunteer_opportunities (current spec)
- Committees = the 11 committees (current spec, already seeded)
- Board = current spec
- Calendar / Events = booster events (banquet, pool party, photo shoot)
- Newsletter = Phase 2 or 3
- Documents = bylaws PDF, recent minutes, IRS determination letter (`documents` table, already in schema)

**Donate** — already in spec. Standalone page.

**About / Contact** — keep what's in Step 4 (mission, board, contact form). Move the contact form's primary scope to general questions; sponsorship inquiries go through the Sponsorship Opportunities form.

### What this means: pages we DON'T carry forward

Cleanly. Worth stating so the board can object:
- 2019 Games-At-A-Glance (rebuild as historical season recap if anyone wants — probably not)
- Pink Out Shirts 2020
- Trophy Case (only if there's content)
- Ryan Murphy Scholarship/Award — only if it still runs (need board input)
- Alumni — only if maintained (Stony Point's "Tigers in College" version)
- Web Cast — replace with a Media → Watch link to the YouTube channel

---

## Homepage proposal

Lifted heavily from Stony Point with adjustments for what we can realistically maintain.

```
┌─────────────────────────────────────────────────┐
│  HERO                                            │
│  Background: team image or McNeil green block    │
│  Headline: "McNeil Mavericks Football"           │
│  Subhead: "Home of the McNeil Mavericks,         │
│           Austin, TX" (or current-season tag)    │
│  Primary CTA: "Join the Booster Club"            │
├─────────────────────────────────────────────────┤
│  NEXT GAME (or COUNTDOWN if offseason)           │
│  Pulled from schedule. One card.                 │
├─────────────────────────────────────────────────┤
│  QUICK LINKS                                     │
│  6 cards: Join, Sponsor, Donate, Volunteer,      │
│           Schedule, Roster                       │
├─────────────────────────────────────────────────┤
│  LATEST NEWS (3 cards with thumbnails)           │
├─────────────────────────────────────────────────┤
│  UPCOMING EVENTS (3-5 cards, mixed: games +      │
│  booster events. Each tagged with type.)         │
├─────────────────────────────────────────────────┤
│  SPONSORS STRIP (logo carousel, equal sized)     │
├─────────────────────────────────────────────────┤
│  FOOTER                                          │
│  Address, social, disclaimer, copyright          │
└─────────────────────────────────────────────────┘
```

Notes:
- **Next Game card** beats Stony Point's homepage. They don't have one. It's the single most useful thing on a football site during the season. Offseason it shows a countdown to season opener.
- **District Standings table**: skip Phase 1. Update if Cruz wants it Phase 2.
- **Instagram embed**: skip Phase 1. Footer social icons cover it.
- **News + Events as separate sections**, not combined. News is "thing that happened or announcement"; events are "thing on the calendar."

---

## What changes vs. what we've already built

### Step 4 (shipped)

Most survives. Specific changes:

1. **Home page** — the booster-focused hero + about-the-club paragraph becomes the `/boosters` landing page. Home gets the new structure above. The 80-word "about" paragraph moves to `/boosters` (top section).
2. **Header nav** — currently Home/About/Contact. Becomes the 11-item nav above. Mobile drawer still works the same way.
3. **About page** — content stays but moves under `/about` (general about + contact info) vs. `/boosters` (mission, board, committees, etc.). Some content overlap: the mission and "what dues fund" are booster-specific and move to `/boosters`. General contact info stays at `/about`.
4. **Footer** — disclaimer is fine; add social icons (FB, IG, YouTube) once URLs are confirmed. Add "Address" column for the new mailing address found in `/boosters` content: **#412, 6001 W Parmer Ln, Suite 370, Austin TX 78727**.
5. **Site settings table** — add fields for `youtube_url`, `instagram_url`, `next_game_override`, `season_opener_date`, `season_label` (e.g., "2026 Season").

### Schema (needs revision)

New tables required:
- **`games`** — schedule entries. id, year, team_level (varsity/jv/freshman), opponent, date_time, location, location_url, home_or_away, our_score, their_score, result_status (scheduled/final/cancelled/postponed), watch_url (YouTube), notes.
- **`rosters`** — year-tagged roster content. id, year, team_level, body (markdown). Three rows per year. Simpler than a `players` table; coach won't maintain player records.
- **`coaches`** — name, role, phone, email, photo_url, bio, sort_order, year, active. Separate from `board_members`.
- **`resource_links`** — for /resources page. id, section, label, url, description, sort_order, active.

Modify existing:
- **`events`** — already exists. Reuse for booster events. Add a `category` enum if we want to mix games + booster events on home (probably tag at query time, not in schema).
- **`site_settings`** — add the new fields above.

The CRUD admin for `games`, `rosters`, `coaches`, `resource_links` follows the exact same pattern as `news_posts` — copy paste once. Cheap.

### Build plan

Steps 1-3 done. Step 4 mostly stands; needs a follow-up patch step ("Step 4b: rework home + add boosters landing"). Step 5 (public collection routes) expands to cover schedule, roster, coaches, resources, sponsors, plus the booster section. New Step ordering:

- **Step 4b**: nav + home reshape, new `/boosters` landing using current Step 4 content. ~half day.
- **Step 5**: public routes: /schedule, /roster, /coaches, /resources, /sponsors, /news, /boosters/*. Empty-state design for each. ~2 days.
- **Step 6+**: admin auth and CRUD — sequence unchanged, but more content types.
- **Step 7**: news, events, settings (unchanged)
- **Step 7b** (new): schedule, roster, coaches, resource_links admin CRUD. Same pattern, copy-paste.
- (rest unchanged)

Hard date impact: still feasible for July 13-20 cutover IF I commit to evenings/weekends and don't expand scope further. Probably 1 extra weekend versus the original plan.

---

## Things I noticed worth surfacing

Findings that aren't in any existing project doc:

1. **New head coach.** Jonathan Cruz is the new AD and Head Football Coach as of March 14, 2026 (per the program's Facebook page). Wallin is the prior coach. The existing site's coach pages are stale on this. **Action**: introduce yourself (Jeremy) to Cruz before the new site launches — he'll be the de facto owner of schedule/roster/coaches content, and the booster relationship with the new head coach matters more than the new website.

2. **Mailing address found.** McNeil Maverick Football Booster Club #412, 6001 W Parmer Ln, Suite 370, Austin TX 78727. Already exists, already a PO Box style address. **Resolves `next_steps.md` item 5.** Treat as confirmed unless the board says otherwise.

3. **`mcneilmavericks.org` is the football brand publicly.** The Facebook page (mcneilmavsfootball) and Instagram (McNeilMavNation) both link here. This isn't a booster website; it's the football program's website. Booster owns the URL and hosting. That framing matters for content tone going forward.

4. **Sponsors page references a 2022-2023 PDF.** No online sponsorship form today. New site replacing this with a Stripe-backed online form is a meaningful upgrade for Kendra's outreach.

5. **Aktivate replaced RankOne.** Some Parent Portal links are functionally dead. The new `/resources` page needs to point to aktivate.com, not rankone.com.

6. **The football team has a Google Calendar** ("McNeil Football Calendar" per the screenshot Jeremy sent earlier). If we can get the public ICS URL, the schedule page maintenance burden drops to near zero. **Action**: ask Cruz (or whoever currently runs the calendar) for the public sharing URL.

7. **Multi-sport future.** Jeremy mentioned baseball/basketball "down the road." Architectural impact for Phase 1 = none. We add a `sport` column to `games`, `rosters`, `coaches`, `news_posts` later when a second sport actually shows up. Keep URLs unscoped for now (`/schedule` not `/football/schedule`); rewrite if/when needed.

---

## Open decisions before Step 5 spec

Yes/no on each. Most are cheap if either way; flag the expensive ones.

1. **Schedule data source for Phase 1: Google Calendar embed, manual table, or both?**
   My pick: **both — Google Calendar as primary, with a clean styled table that pulls from the same ICS feed**. If we can get the URL, this is free. If we can't, fallback is manual games CRUD. Either way, schedule page is admin-editable on day one.

2. **Carry forward Stadiums, Trophy Case, Alumni, Ryan Murphy items, Meals, Photos?**
   My pick: **Stadiums yes** (inside /resources as a section). **Meals yes** (it's a real committee). **Trophy Case, Alumni, Ryan Murphy: ask the board at June 2 meeting.** **Photos: skip — link to Instagram.**

3. **`/resources` vs. some other name?**
   My pick: **"For Parents & Athletes"** in the nav, route at `/resources`. Stony Point doesn't have this section; they distribute the links across other pages. McNeil's existing site has Parent Portal which parents actually use, so we preserve that mental model with a fresher name.

4. **District Standings on home in Phase 1?**
   My pick: **No.** Skip. Either Phase 2 or never. Maintenance cost not worth it without an API. Cruz can blog about it via news posts.

5. **News + booster events split or combined on home?**
   My pick: **separate sections** (News card row, then Events card row below). Easier to scan. Easier for admins to edit (they go to one collection).

6. **Header treatment with school logo authorization still open?**
   My pick: **type-only wordmark for launch** (matches Step 4). Swap in logo when Sylvia/Cruz confirms permission. No rebuild needed.

7. **Cutover scope: ship with all these new pages, or ship leaner and add some Phase 2?**
   My pick: **ship all of it.** The admin pattern is the same for each. Cost is in the CRUD repetition, not the design. Schedule + Roster + Coaches are the things that make this look like a real football site, not a booster brochure. If we ship without them, the board (and your wife) will say "this is worse than what we had." Better to push cutover by a week than ship a degraded site.

8. **Step 4 work: revise now or finish current Step 4 first?**
   My pick: **revise now.** Step 4 is shipped to staging, no one outside Jeremy has seen it. The header, home, and About changes are mechanical (folder rename + new sections). Doing them before Step 5 is cleaner than doing both in parallel.

---

## What's NOT in this doc that should come next

- Updated schema SQL for the new tables (`games`, `rosters`, `coaches`, `resource_links`, plus `site_settings` additions). Once decisions above are made.
- Updated build_plan.md with Step 4b inserted and Step 5 expanded.
- Updated content_map.md showing every page and what fields/sections it has.
- An explicit decision from Jeremy on whether to delay Step 5 to do this rework properly, or split it.

When you've answered the open decisions, I redo schema.md and content_map.md, then we restart Step 5.
