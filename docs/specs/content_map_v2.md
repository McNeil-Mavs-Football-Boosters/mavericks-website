# Content Map — Phase 1 (Football Pivot)

Written 2026-05-16. **Supersedes the original `content_map.md`** (which was structured around a booster-focused site). The new IA is football-first with booster CRM nested under a section.

**Reads with:**
- `schema_v2.md` + `schema_v2_addendum.md` — the data model
- `site_pivot.md` + `site_pivot_addendum.md` — IA rationale and capture checklist
- `schema.md` — original tables (memberships, payments, etc., unchanged)

---

## Route map

| URL | Purpose | Section |
|---|---|---|
| `/` | Football homepage with booster CTAs | Public |
| `/schedule` | Season schedule, all team levels | Public |
| `/roster` | Player rosters, all team levels | Public |
| `/coaches` | Coaching staff and trainers | Public |
| `/news` | Article index | Public |
| `/news/[slug]` | Individual article | Public |
| `/sponsors` | Tiered sponsor list | Public |
| `/events` | Booster events — List + Month views | Public |
| `/events/[slug]` | Individual event detail page | Public |
| `/events.ics` | Public ICS feed of published events (slice 2) | Public |
| `/resources` | "Forms & Links" links | Public |
| `/boosters` | Booster club landing | Boosters |
| `/boosters/join` | Membership signup with Stripe | Boosters |
| `/boosters/members` | Public members list | Boosters |
| `/boosters/sponsor` | Sponsorship opportunities + form | Boosters |
| `/boosters/volunteer` | Volunteer opportunities | Boosters |
| `/boosters/committees` | Committee descriptions | Boosters |
| `/boosters/board` | Board members for current year | Boosters |
| `/boosters/donate` | Donation form | Boosters |
| `/about` | About the website + contact | Utility |
| `/privacy` | Privacy policy | Utility |
| `/404` | Not found | Utility |

**Nav label override:** `/resources` is labeled "Forms & Links" in the header nav. The URL itself stays short.

19 public routes plus utility. Phase 1 scope.

---

## Site-wide elements

### Header

Same across all routes.

- Logo + wordmark on the left, links to `/` (the logo serves as the Home link — no standalone Home entry). Desktop: "McNeil Mavericks Football". Mobile (<768px): "Mavs Football".
- Primary nav on the right, in order: Schedule, Roster, Coaches & Trainers, Booster Club ▼, Events, Sponsors, Forms & Links. (About is not in primary nav; it lives in the footer right column. News was removed from the top-level row 2026-05-25; no /news page is planned, so there is no nav entry for it anywhere.)
- Booster Club dropdown items: About the Booster Club, Join the Club!, Members, Sponsorship Opportunities, Volunteer, Committees, Donate. (7 items as of 2026-05-25: Calendar / Events promoted to top-level Events; Documents dropped; Board was removed earlier and the route was never built.)
- Events top-level link points to `/events` (List + Month views; full spec in `events_page_spec.md`). Booster Club dropdown no longer carries a calendar link.
- Footer SITE_LINKS already diverges from the top-level nav (curated set: Schedule, Boosters, Join, Sponsors, Donate, Privacy — no News, no Events). Left as-is in the 2026-05-25 nav restructure; decide separately whether to add Events.
- Sticky on scroll, McNeil navy background, no bottom border. Wordmark and nav links render white (dropdown caret and mobile hamburger icon also white). Dropdown panels and the mobile drawer panel remain white with navy text.
- Mobile: hamburger opens a full-height drawer with the same top-level items; Booster Club is an accordion in the drawer.
- No login link in public nav. `/admin` is unlinked.

### Footer

Same across all routes.

- Three columns on desktop, stacked on mobile.
- Column 1: org name, tagline ("Home of the McNeil Mavericks, Austin, TX"), mailing address from `site_settings.mailing_address`. The seeded value is `#412, 6001 W Parmer Ln, Suite 370, Austin TX 78727` per the existing `/boosters` page. Hide the address line if null.
- Column 2: nav repeat — Home, Schedule, Boosters, Sponsors, Donate, About, Privacy. (Not the full top nav, just key destinations.)
- Column 3: `mailto:` link to `site_settings.primary_contact_email`, social icons. Facebook, Instagram, YouTube — each hidden if its corresponding field on `site_settings` is null. **Don't add X/Twitter** unless requested; the existing site links X but the current Mavs accounts may not be active.
- Full-width disclaimer block: render `site_settings.school_affiliation_disclaimer` verbatim.
- Copyright row: `© 2026 McNeil Maverick Football Booster Club · 501(c)(3) · EIN 26-4231242`.

---

## Public routes

### `/` (Home)

**Purpose:** football homepage with booster CTAs woven in. The first thing your wife (and every other parent) sees.

**Sections, top to bottom:**

1. **Hero**
   - Background: `site_settings.hero_image_url` if set; otherwise solid `#1a4d2e` placeholder green
   - Headline: `site_settings.hero_headline` (default "McNeil Mavericks Football")
   - Subhead: `site_settings.hero_subhead` if present (default "Home of the McNeil Mavericks, Austin, TX")
   - Primary CTA: `site_settings.primary_cta_label` + `primary_cta_url`. Default: "Join the Booster Club" → `/boosters/join`.

2. **Next Game card** (or Season Countdown when no upcoming games)
   - Query: `SELECT * FROM games WHERE team_level = 'varsity' AND result_status = 'scheduled' AND game_date > now() ORDER BY game_date ASC LIMIT 1`
   - Card content: matchup ("Mavs vs. Round Rock"), date/time, location, home/away, "View Schedule →" link
   - If query returns nothing AND `site_settings.next_game_override` is set: render the override text
   - If query returns nothing AND no override AND `site_settings.season_opener_date` is in the future: render countdown ("Season opens in 14 days")
   - If none of those: hide the section entirely

3. **Get Involved band** (h2 reads "Get Involved") — 6 cards, equal weight, clickable. Rendered as `bg-mavs-green` band with white heading; cards inside keep white backgrounds with navy icons and navy hover border.
   - Join the Club → `/boosters/join`
   - Sponsor the Team → `/boosters/sponsor`
   - Volunteer → `/boosters/volunteer`
   - Make a Donation → `/boosters/donate`
   - 2026-27 Schedule → `/schedule`
   - 2026-27 Roster → `/roster`
   - The "2026-27" prefix on the last two reads from `site_settings.current_year`

4. **Latest News** — heading "Latest News", "View all news →" link in upper right
   - Query: `SELECT * FROM news_posts WHERE status = 'published' ORDER BY published_at DESC LIMIT 3`
   - Each card: featured_image_url (or default), title, published_at, excerpt
   - Empty state: hide the section entirely

5. **Upcoming Events** — green band (`bg-mavs-green`, white text) matching the Get Involved band above. Centered h2 "Upcoming Events"; centered "All Events →" link below the rows linking to `/events`.
   - This is **booster events**, not games. Games have their own home section above.
   - Query: `SELECT * FROM events WHERE status = 'published' AND starts_at >= now() ORDER BY starts_at ASC LIMIT 2`
   - Rendered via the shared `<EventRowCard variant="on-green">` component from `components/events/EventListView.tsx` — same row layout as `/events` (left date block: weekday / day / month abbr; right body: time range, title link, location, 3-line description excerpt; optional md+ cover image). The variant swaps navy/muted colors for white/white-on-green so the same component reads correctly on either band.
   - Empty state: hide the section entirely

6. **Sponsors strip** — two-row thank-you band (restyled 2026-05-22 PM, supersedes the morning's small-caps strip)
   - Centered h2 heading "Thank You to Our 2025-2026 Sponsors!" (`text-2xl md:text-3xl font-bold text-mavs-navy text-center`). Mixed case; exclamation point kept. Reads warmer than the morning's small-caps left-aligned label.
   - **Row 1** — MVP-tier sponsors only at `max-w-[220px] max-h-20` per logo, `flex flex-wrap items-center justify-center gap-12 mb-8`. Today: Rudy's alone.
   - **Row 2** — everyone else (Diamond / Platinum / Gold / Blue / Other) at `max-w-[160px] max-h-12`, `flex flex-wrap items-center justify-center gap-8 md:gap-12`. Today: 6 Golds.
   - "See All Sponsors →" centered link below logos in `mt-10` block, navy uppercase tracking-wide, links to `/sponsors`.
   - Section padding `py-12 md:py-16`. Larger vertical breathing room than the original strip; reads as a section, not a footer band.
   - Each logo wrapped in `<a target="_blank" rel="noopener noreferrer" class="hover:opacity-80 transition-opacity">` when `website_url` present. Plain `<img>` (not next/image) — same convention as carousel + /sponsors.
   - Partition by tier name: `loadHome()` fetches the MVP `sponsorship_tiers.id` alongside sponsors and partitions client-side by `tier_id === mvpTierId`. Fallback when MVP id is null: everything renders in Row 2 (safe degradation).
   - **`featured` flag no longer drives placement.** Migration 044 reset all sponsors to `featured = false`; the column stays in the schema for future admin-driven badging (e.g. "featured sponsor of the month") but is not read by any current code path.
   - Query: `SELECT id, name, logo_url, website_url, tier_id FROM sponsors WHERE active = true AND year = site_settings.current_year ORDER BY sort_order, name` + a parallel `SELECT id FROM sponsorship_tiers WHERE year=current_year AND active=true AND name='MVP'`
   - Logo URL: `publicStorageUrl(logo_url, 'sponsor-logos')` (logos stored as bare filenames in the `sponsor-logos` bucket)
   - Empty state: hide the section entirely
   - **Known visual risk:** Sunflower Bank source is 384×42 (extreme aspect). At `max-w-[160px] max-h-12` she clamps to ~160×17.5 — small but acceptable. If field feedback says she's unreadable: (a) crop the source PNG, (b) add a per-sponsor size override, or (c) bump the Row 2 width cap. Recheck on `/sponsors` too — the Gold-tier bounding box there gives Sunflower ~280×30.6, more visible.

7. **Footer** (see site-wide above)

**Data sources:** site_settings, games (varsity next), news_posts, events, sponsors.

**Open question:** Should the Get Involved band cards have icons? My pick: yes, simple line icons (lucide-react), one per card. No icons makes the section read like a footer.

---

### `/schedule`

**Purpose:** the 2026-27 football schedule for all three team levels. Source of truth on our site (admin enters games); MaxPreps is the live-scores link for visitors.

**Sections, top to bottom:**

1. **Page header**
   - Title: "[current_year] Schedule" (e.g., "2026-27 Schedule")
   - Subhead with MaxPreps CTA: "Live scores and stats →" linking to `site_settings.maxpreps_team_url` (opens in new tab)

2. **Anchor nav** (sticky below page header, optional)
   - "Jump to: Varsity · JV · Freshman"
   - Links to `#varsity`, `#jv`, `#freshman`

3. **Varsity Schedule** (`<section id="varsity">`)
   - Heading: "Varsity Schedule"
   - Table columns: Date | Opponent | Location | Home/Away | Time | Result | Watch
   - Each row maps to a `games` row with `team_level = 'varsity'`, ordered by `game_date ASC`
   - "Result" column: shows "W 35-14" / "L 21-28" if `result_status = 'final'`; "—" otherwise; "Cancelled" / "Postponed" / "TBD" per status
   - "Watch" column: external link icon if `watch_url IS NOT NULL`; otherwise empty
   - "Notes" rendered as a small subtitle row under the matchup row when populated (Homecoming, Senior Night, Scrimmage, etc.)
   - Empty state: card showing "Varsity schedule coming soon. Check MaxPreps for current details." with MaxPreps CTA

4. **JV Schedule** (`<section id="jv">`) — same pattern, `team_level = 'jv'`
5. **Freshman Schedule** (`<section id="freshman">`) — same pattern, `team_level = 'freshman'`

**Data sources:** site_settings, games.

**Implementation notes:**
- Mobile: tables collapse to cards (each row becomes a stacked card). Don't try to make a 7-column table work on a 375px viewport.
- Print stylesheet: clean print-friendly version. Coaches and parents will print these.
- ICS export: optional. Skip Phase 1, revisit if requested. The MaxPreps link covers the "I want this on my calendar" use case.

**Open question:** should home games visually distinguish from away (e.g., bold the opponent, swap background color)? My pick: yes, light background tint on home game rows. Subtle but readable.

---

### `/roster`

**Purpose:** player rosters for all three team levels. Each level is a row in the `rosters` table with optional body markdown plus a structured list of `players`.

**Sections, top to bottom:**

1. **Page header**
   - Title: "[current_year] Roster"

2. **Anchor nav** (same pattern as `/schedule`)
   - "Jump to: Varsity · JV · Freshman"

3. **Varsity Roster** (`<section id="varsity">`)
   - Heading: "Varsity"
   - If `rosters.body IS NOT NULL AND body != ''`: render markdown as preamble
   - If players exist: render structured table — Jersey # | Name | Position | Grade | Height | Weight
   - Empty state: "2026-27 Varsity roster coming soon."
   - Sort: `players.sort_order ASC`, with `jersey_number ASC` as numeric tiebreaker

4. **JV Roster** — same pattern, `team_level = 'jv'`
5. **Freshman Roster** — same pattern, `team_level = 'freshman'`

**Data sources:** site_settings, rosters, players.

**Implementation notes:**
- Mobile: tables collapse to cards. Each player card = Jersey # | Name | Position (Grade).
- Height/Weight columns: hide on mobile by default; expandable.
- Print stylesheet for coaches.

**Privacy note:** these pages list minors by name. RLS on the `players` table includes a subquery checking parent roster `active = true`. If we soft-archive a roster, all its players become invisible to anonymous visitors. Off-switch is intentional.

**Open question:** display player photos? My pick: **no for Phase 1.** Photo consent for minors is a real legal and operational concern. Skip until the board has a documented consent process. Schema accommodates adding a `photo_url` to `players` later without breaking changes.

---

### `/coaches`

**Purpose:** coaching staff and trainers for the current year. **No head coach listed at launch** per open decision #9 (Cruz situation).

**Sections, top to bottom:**

1. **Page header**
   - Title: "Coaches & Trainers"
   - Subhead: "[current_year]"

2. **Head Coach** (`<section>`)
   - If `coaches` has an active row with `role_category = 'head'` for current year: render coach card
   - If none: render placeholder card with copy "Head Coach: position currently open. We'll update this page when the new coach is announced."
   - **Do not name Cruz, do not list any past head coaches here.** Historical coaches go to archive once `active = false`.

3. **Coordinators** (`<section>`)
   - Query: `role_category = 'coordinator'`, active, current year, ordered by sort_order
   - Each card: photo, name, role, phone (mailto if email, tel: if phone), optional bio
   - Hide section if no rows

4. **Position Coaches** (`<section>`)
   - Same pattern, `role_category = 'position_coach'`. Wallin will show up here in seed.

5. **Trainers** (`<section>`)
   - Same pattern, `role_category = 'trainer'`

6. **Staff** (`<section>`)
   - Same pattern, `role_category = 'staff'` — for non-coaching staff (athletic director's assistant, equipment manager, etc.)

**Data sources:** site_settings, coaches.

**Implementation notes:**
- Coach cards: 2-3 per row on desktop, 1 per row on mobile.
- Photos use the `coach-photos` Storage bucket. Default avatar block if `photo_url` is null.
- Phone: clickable `tel:` link. Email: clickable `mailto:`.
- Bio: markdown, rendered with safe HTML.

**Known data from SE capture:**
- Coach Wallin: position coach, still on staff per Jeremy
- Coach Fanara (per a search snippet): "Linebackers and also serves as Defensive Coordinator. Supervises the Credit Recovery program at McNeil and also coaches Wrestling. Before joining McNeil in April 2020, he coached Defensive Line & Linebackers at..." — verify still on staff during Tier 1 capture pass
- Lead Athletic Trainer: phone 512.464.6503 per existing /coaches page
- Athletic Coordinator + Head Football Coach line: phone 512.464.6502 — that phone may now be reassigned, do not migrate without verification

**Open question:** does the AD slot live on `/coaches` or under the school admin (out of scope)? My pick: if the AD is also a coach (Cruz was both), they appear here. If the AD is a non-coach administrator, they appear on the school's own site, not ours. Phase 1: leave the slot empty until clear.

---

### `/news`

**Purpose:** article index. Used for both football team news and booster news (no separation by category in Phase 1).

**Sections, top to bottom:**

1. **Page header**: "News"

2. **Featured article** (large card)
   - Most recent published post
   - Full-width card: featured image, title, excerpt, "Read more →", published_at, author

3. **Recent articles grid** (3-column desktop, 1-column mobile)
   - Query: `SELECT * FROM news_posts WHERE status = 'published' AND id != [featured_id] ORDER BY published_at DESC LIMIT 11`
   - Each card: featured_image_url, title, excerpt, published_at
   - 12 articles total on page 1 including the featured one

4. **Pagination** if more than 12 articles total
   - "Older posts →" link to `/news?page=2`
   - Simple offset pagination, no fancy infinite scroll

**Data sources:** news_posts.

**Empty state:** "No news yet. Check back soon." with link to `/boosters/join` ("In the meantime, become a booster →").

---

### `/news/[slug]`

**Purpose:** individual news article.

**Sections:**

1. **Article header**
   - Title (h1)
   - Author + published_at
   - Featured image (full-width, optional)

2. **Body** (markdown rendered)

3. **Footer**
   - "Back to all news →" link
   - Social share buttons? My pick: **no.** Phase 1 doesn't need share buttons; users can copy the URL.

**404 if slug not found or status = 'draft' (for anon visitors).**

---

### `/sponsors`

**Purpose:** tiered public list of all current-year sponsors. Sponsors paying $5K (MVP) get visual primacy over $500 (Blue).

**Sections, top to bottom:**

1. **Page header**
   - Title: "Our Sponsors"
   - Subhead: "[current_year]"
   - Right side: "Become a Sponsor →" CTA to `/boosters/sponsor`

2. **MVP** ($5,000 tier)
   - Heading: "MVP Sponsors"
   - Largest logo size (max 300px height)
   - Each sponsor: logo (clickable to website_url), name below if logo doesn't include it
   - Optional perks summary text in heading area: "MVP sponsors get cover ads, PA announcements, and streaming banners at all home games."
   - Hide if no sponsors at this tier

3. **Diamond** ($2,500)
4. **Platinum** ($1,500)
5. **Gold** ($1,000)
6. **Blue** ($500)
   - Same pattern; smaller logo sizes as tier decreases
   - 4-5 logos per row at Blue tier; 1-2 at MVP

7. **Footer CTA card**
   - "Interested in sponsoring? Five tiers available, all benefits listed."
   - Button → `/boosters/sponsor`

**Data sources:** site_settings, sponsors, sponsorship_tiers.

**Empty state:** if zero sponsors in the current year, render: "We're building our 2026-27 sponsor program. [Become our first sponsor →]" with CTA to `/boosters/sponsor`. Don't render the tier scaffolding when empty.

**Implementation notes:**
- Logos use the `sponsor-logos` Storage bucket. Allow PNG, JPEG, SVG, WebP.
- Each sponsor row needs a tier (`tier_id`) to determine which section it appears in. Sponsors with `tier_id IS NULL` go to an "Other Supporters" section at the bottom.
- Sponsor websites open in new tab.

**Open question:** display sponsor perks per tier on this page, or just on `/boosters/sponsor`? My pick: **just on `/boosters/sponsor`**. This page is for thanking sponsors, not selling tiers. The CTA card at the bottom links to the sales page.

---

### `/resources` (nav label: "Forms & Links")

**Purpose:** curated link list. Replaces the SE site's Parent Portal + the public parts of More+. Cheapest possible: one table powers all sections.

**Sections, top to bottom:**

1. **Page header**
   - Title: "Forms & Links"
   - Subhead: "Forms, links, and resources for the McNeil Mavericks football community"

2. **Registration & Forms** (`resource_section = 'registration_forms'`)
   - Heading: "Registration & Forms"
   - List of `resource_links` rows, ordered by sort_order
   - Each item: label (clickable to url), description below in smaller text, icon based on `icon_hint`
   - Hide section if no rows

3. **News & Communications** (`resource_section = 'communications'`)
   - Heading: "News & Communications" (UI string in `app/resources/page.tsx` SECTION_ORDER; the DB enum value `communications` is unchanged). Renamed from "Communications" on 2026-05-25 (commit f11c5f4).
   - Same item rendering. As of 2026-05-25: MavMail (`icon_hint='mail'`, sort_order=-2) at top with description "McNeil High School's weekly newsletter. Published most Sundays at 5PM." (migration 047), then HUDL (1), then SportsYou (2), then McNeil Mavericks Football Parents (Facebook Group) (`icon_hint='facebook'`, sort_order=3, migration 049). The standalone News entry → `/news` from migration 046 was dropped in 047 — no /news page is planned. Negative sort_order on MavMail keeps it above HUDL/SportsYou without renumbering them. `icon_hint='facebook'` is a new lowercase hint registered in `lib/resource-icons.tsx` — lucide-react v1.x dropped brand glyphs (trademark), so the registry holds an inline SVG mirroring the Footer.tsx Facebook component.

4. **Resources** (`resource_section = 'resources'`)
   - Heading: "Resources"
   - Workouts, conditioning, fall parent meeting docs

5. **Stadiums** (`resource_section = 'stadiums'`)
   - Heading: "Stadiums & Directions"
   - Each item is a stadium row: name, address (in description), Google Maps link

6. **Other** (`resource_section = 'other'`)
   - Catch-all for things that don't fit the other sections

**Data sources:** resource_links.

**Empty state:** if the entire table is empty, render: "Resources coming soon. Contact boosters@mcneilmavericks.org with questions."

**Implementation notes:**
- Each section hides if it has zero active rows. No empty-section heading.
- `icon_hint` map (frontend): `external` → external-link icon, `pdf` → file icon, `form` → clipboard icon, `video` → play icon. Unknown values get the external-link icon as fallback.

**Seeded content** (from schema_v2_addendum.md):
- Aktivate (replaces RankOne) → aktivate.com
- UIL Forms → uiltexas.org
- RRISD Athletic Forms → roundrockisd.org/athletics
- HUDL → hudl.com (team code from coaching staff)
- SportsYou → sportsyou.com (access code from existing site capture)
- Kelly Reeves Athletic Complex → Google Maps link, **address needs verification** before launch

---

## Boosters section routes

### `/boosters`

**Purpose:** landing page for the booster club section. About the booster club, mission, key CTAs.

**Sections, top to bottom:**

1. **Page header**
   - Title: "McNeil Maverick Football Booster Club"
   - Subhead: "A 501(c)(3) supporting McNeil Mavericks football"

2. **Mission statement** — verbatim from `spec_review.md` Part 1:

   > The purpose of the Booster Club is to provide encouragement and generate support for the football program at McNeil High School. The Booster Club is a 501(c)(3) organization that works to support and improve the football program through activities for the teams and improvement of facilities and equipment.

   (Full statement is in spec_review.md; render in full. Could be wrapped in `<blockquote>`.)

3. **What dues fund** — placeholder copy with `{/* PLACEHOLDER — replace once Chevon delivers copy */}` comment:

   > Membership dues directly fund the Mavericks football program — team meals, banquet costs, senior recognition, facility improvements, and equipment the school budget doesn't cover. The board will share a detailed allocation breakdown each season.

4. **Quick Actions** — 4 cards (smaller than home Quick Links band):
   - Become a Member → `/boosters/join`
   - Become a Sponsor → `/boosters/sponsor`
   - Make a Donation → `/boosters/donate`
   - Volunteer → `/boosters/volunteer`

5. **Affiliations & contact**
   - 501(c)(3), EIN 26-4231242
   - Mailing address (from site_settings): `#412, 6001 W Parmer Ln, Suite 370, Austin TX 78727`
   - Physical address (McNeil HS): `5720 McNeil Dr, Austin, TX 78727`
   - Email: `boosters@mcneilmavericks.org`
   - Link to `/privacy`

6. **Section nav** — list of all booster sub-pages
   - Join, Members, Sponsorship Opportunities, Volunteer, Committees, Calendar / Events, Donate (7 cards as of 2026-05-25 evening — Board + Documents removed as both 404'd; Calendar / Events repointed to top-level `/events`)
   - Just plain text links, no icons. The header dropdown is the primary nav.

**Data sources:** site_settings.

---

### `/boosters/join`

> **⚠️ Phase 1 reality (as of 2026-05-18):** This section describes the Phase 2 custom-form + Stripe-Checkout flow. **Phase 1 is materially different** — the live page is a server-rendered tier ladder with no payment integration; every tier card CTA opens the same Google Form (`BOOSTER_FORM_URL` in `lib/constants.ts`) in a new tab. No `memberships` row is created on Phase 1 signup; the Google Sheet linked to the Form is the source of record. See `specs/boosters_join_spec.md` for the Phase 1 spec and `app/boosters/join/page.tsx` for the implementation. Everything below applies when the custom form lands as Phase 2 work.

**Purpose:** the membership signup form. Flow: tier selection → form → Stripe Checkout (or $0 bypass for Free Fan Base) → success page.

**Sections, top to bottom:**

1. **Page header**
   - Title: "Join the Booster Club"
   - Subhead: "Memberships are valid February 1 – January 31"

2. **Tier comparison** (cards)
   - Query: `SELECT * FROM membership_tiers WHERE year = site_settings.current_year AND active = true ORDER BY sort_order`
   - Each card: name, price, description, perks list, badge_label if present (e.g., "Most Popular")
   - Tier highlighted on hover; click selects tier for the form below

3. **Membership form**
   - Tier picker (radio, populated from query above; pre-selected if user clicked a tier card)
   - Parent 1: name, email, phone — all required
   - Parent 2: name, email, phone — optional
   - Players: free-text "Player Name(s) and Grade(s)" — optional
   - T-shirt size 1: dropdown (XS/S/M/L/XL/XXL) — required if selected tier has `requires_tshirt_size = true`, hidden otherwise
   - T-shirt size 2: same, required if `requires_second_tshirt_size = true`
   - Additional donation: optional, dollar amount field (defaults to $0)
   - Employer match: optional, company name text field
   - SportsYou opt-in: checkbox, default checked, label "Add me to the team SportsYou group"
   - List publicly: checkbox, default checked, label "Include my name on the public members page"
   - Submit button: "Continue to Payment" (paid tier) or "Sign Up Free" ($0 tier)

4. **Footer notice**
   - "Memberships renew annually. All dues are tax-deductible."

**Data sources:** site_settings, membership_tiers.

**Form submission flow:**
- POST to `/api/memberships/create` (server-side, service role)
- Server validates input with Zod, creates `memberships` row with `paid = false`, returns either:
  - For $0 (Free Fan Base): server completes the row with `paid = true`, redirects to `/boosters/join/thanks`
  - For paid tiers: server creates Stripe Checkout session with `amount_cents = tier.price_cents + additional_donation_cents`, redirects to Stripe
- Stripe webhook (`/api/stripe/webhook`) handles `checkout.session.completed`: upserts payments row idempotently, flips `memberships.paid = true`, links `payment_id`
- Success URL: `/boosters/join/thanks?session_id={CHECKOUT_SESSION_ID}`
- Cancel URL: `/boosters/join/cancelled`

**Thanks page sections:** confirmation message, what to expect next, link to `/boosters` for more involvement options.

**Cancelled page sections:** "Payment cancelled. Your membership wasn't completed." + link back to `/boosters/join`.

---

### `/boosters/members`

> **⚠️ Phase 1 reality (as of 2026-05-19):** The live page does NOT query the `public_members` view or honor a `list_publicly` opt-in (the Google Form has no such checkbox; that field exists only in the Phase 2 custom-form design). Instead it reads the linked Google Sheet via `lib/sheets/boosters.ts` (service-account JWT, ISR 5min), dedupes by Email Address (latest-Timestamp wins, falls back to Parent 1 Name when email is blank), and renders **every row that has a tier selected** — Payable Status is intentionally ignored. Names are displayed as "First L." (conservative privacy default; opt-out is via email to `mcneilfootballboosters@gmail.com`). The list is a **single flat alphabetical-by-Parent-1-surname** layout (no tier grouping), and a separate **Top Donors** band at the bottom (mavs-green band, white text, dynamic 1/2/3-column grid) features the top-3 tiers by sort_order. The "Join the Boosters →" CTA at the bottom links directly to the Google Form, not back to `/boosters/join`. Everything below applies when the Phase 2 custom-form + `public_members` view lands.

**Purpose:** public list of dues-paid members who opted in. Recognition page.

**Sections, top to bottom:**

1. **Page header**
   - Title: "[current_year] Members"
   - Subhead: "Thank you to our supporters"

2. **Members list grouped by tier**
   - Query: `SELECT * FROM public_members WHERE year = site_settings.current_year ORDER BY tier_sort_order DESC, parent_1_name`
   - Group by `tier_name`, render heading per tier
   - Each row: "Parent 1 name" (and "Parent 2 name" if present, joined by ` & `)
   - Display style: vertical list per tier section, alphabetized within section

3. **Footer CTA card**
   - "Not yet a member? [Join here →]"
   - Link to `/boosters/join`

**Data sources:** public_members view, membership_tiers (for tier ordering).

**Empty state:** "We're building our 2026-27 member list. [Be the first to join →]" CTA to `/boosters/join`.

**Privacy notes:**
- Only displays members where `list_publicly = true AND paid = true AND active = true` (enforced by the view)
- No emails, phones, or other personal data exposed via the view
- $0 Free Fan Base members are included if they opted in (per the inclusive design decision in spec_review.md)
- Subhead says "supporters" not "dues-paid members" to keep it welcoming to $0 members

---

### `/boosters/sponsor` (Sponsorship Opportunities)

**Purpose:** sales page for new sponsorships. Tiered perks, form, Stripe Checkout for paid tiers.

**Sections, top to bottom:**

1. **Page header**
   - Title: "Sponsor McNeil Mavericks Football"
   - Subhead: "Five tiers from $500 to $5,000. All sponsors get website placement and program recognition."

2. **Tier comparison cards**
   - Query: `SELECT * FROM sponsorship_tiers WHERE year = site_settings.current_year AND active = true ORDER BY sort_order`
   - Each card: name, price, description, perks list, badge_label if present
   - Higher tiers (MVP, Diamond) get visual emphasis

3. **What you get** (long-form prose section)
   - Bullet summary across tiers: website logo placement, field signage, social/newsletter promotion, PA announcements at games, program ad space, streaming banners, audio commercials per game
   - Verbatim copy TBD from Kendra (VP Fundraising)

4. **Sponsorship inquiry form**
   - Business name (required)
   - Contact name (required)
   - Contact email (required)
   - Contact phone (optional)
   - Selected tier (radio, populated from query)
   - Message / questions (textarea, optional)
   - File upload: logo (PNG/JPEG/SVG/WebP, max 2MB) — optional, can send later
   - Submit button: "Submit Inquiry" for tiers requiring approval; "Continue to Payment" for direct-pay flow

5. **Alternative contact**
   - "Prefer to talk? Email Kendra at `sponsorship@mcneilmavericks.org`"

**Data sources:** site_settings, sponsorship_tiers.

**Form submission flow:** TBD. Options for Phase 1:

A. **Submit-only** — inquiry goes to `sponsorship@mcneilmavericks.org` via Resend, board follows up manually with invoice or Stripe link.
B. **Direct-pay** — like memberships, submit creates a row + redirects to Stripe Checkout.

My pick: **A for Phase 1.** Sponsorships are higher-touch sales (Kendra wants to talk to each one), and contracts often need to be signed before payment. Direct-pay can come in Phase 2 if Kendra wants the speed.

Submit creates a `sponsorship_inquiries` row (new table — flag to add to schema_v2) and sends an email. Inquiry table fields: id, business_name, contact_name, contact_email, contact_phone, tier_id, message, logo_url, status (new/in_progress/closed_won/closed_lost), created_at, etc.

**Open question for Jeremy:** confirm A vs B. If A, I add `sponsorship_inquiries` to schema_v2 in a small follow-up patch.

---

### `/boosters/volunteer`

**Purpose:** list of volunteer opportunities. Each is a row in `volunteer_opportunities`.

**Sections, top to bottom:**

1. **Page header**
   - Title: "Volunteer with the Boosters"
   - Subhead: "Every parent welcome — from $0 to $1,000, you can 'pay your way' by volunteering"

2. **Why volunteer**
   - Short prose block (4-6 sentences) about the why
   - Verbatim copy TBD — surface for board review

3. **Opportunities list**
   - Query: `SELECT * FROM volunteer_opportunities WHERE active = true ORDER BY sort_order`
   - Each card: title, description, when_text ("Friday nights, fall season"), what_you_do, what_you_get, "Sign up →" button
   - Sign-up button links to `signup_url` (external SignUpGenius for Phase 1)

4. **General contact**
   - "Don't see what fits? Contact `volunteer@mcneilmavericks.org`"
   - Note: `volunteer@` alias is in the `site_settings` proposed earlier but dropped in `spec_review.md` C3. Use `boosters@` as the contact instead, or add `volunteer@` back if Kendra wants it.

**Data sources:** volunteer_opportunities, site_settings.

**Empty state:** "Volunteer opportunities are being finalized for the 2026-27 season. [Contact us →]"

---

### `/boosters/committees`

**Purpose:** list of the 11 committees with descriptions. Recruiting page.

**Sections, top to bottom:**

1. **Page header**
   - Title: "Booster Club Committees"
   - Subhead: "Ongoing, seasonal, and one-time roles"

2. **Filter / grouping** (optional)
   - "All · Ongoing · Seasonal · One-Time" toggle, filters by `cadence`

3. **Committee list**
   - Query: `SELECT * FROM committees WHERE active = true ORDER BY sort_order`
   - Each card: name, cadence badge, description, chair (from `chair_board_member_id`), contact_email
   - 2-column grid on desktop, 1-column on mobile

4. **CTA**
   - "Interested in joining a committee? [Volunteer →]"
   - Link to `/boosters/volunteer`

**Data sources:** committees, board_members.

**Seeded content** (11 committees, descriptions in `schema.md` seed): Social Media, Team Meals, Membership, Merchandise, Parent Meetings, Football Banquet, Summer Events, Meet the Mavs, Senior Night, Tunnel Stampede, Fundraisers.

---

### `/boosters/board`

**Purpose:** current-year board members. Faces and roles.

**Sections, top to bottom:**

1. **Page header**
   - Title: "2026-27 Board"
   - Subhead: "The volunteers who keep the booster club running"

2. **Board grid**
   - Query: `SELECT * FROM board_members WHERE active = true AND year = site_settings.current_year ORDER BY sort_order`
   - Each card: photo, name, role, email_alias (if populated and aliases are live), optional bio
   - 3-column desktop, 1-column mobile

3. **Get involved CTA**
   - "Interested in serving on the board? Elections happen each spring. [Contact us →]"

**Data sources:** board_members, site_settings.

**Seeded content** (from schema.md seed): 9 board members for 2026-27 — Carol Glinski (President), Chevon Williams (Treasurer), Ashley Olson (Co-Treasurer), Kendra Jalbert (VP Fundraising), Shannon Schoepflin (VP Social Events), Sylvia Brito (VP Merchandise), Jeremy Vest (Secretary), Debby Mata (Communications & Membership Support), Monica Woods (Social Events Support).

**Note:** per `spec_review.md` C2, "Ashley Olson" vs "Ashley Root" reconciliation still open. Use whichever name Jeremy confirms.

**Email aliases:** per `spec_review.md` M19, only render the email line when `email_alias` is populated AND we know the aliases are live (Cloudflare Email Routing configured per `next_steps.md` item 3a). Until then, board emails are nullable and the line hides.

---

### `/events`, `/events/[slug]`, `/events.ics`

Top-level events surface — promoted out of `/boosters/events` on 2026-05-25. Full design in **`docs/specs/events_page_spec.md`**. Two views (List default + Month), Upcoming/Past filter pills, navy header band matching `/sponsors`. Detail page at `/events/[slug]` with 404 on unknown-slug or non-published status. `/events.ics` is a public ICS feed of published events for "Subscribe to calendar" (slice 2; shape-only button in slice 1). The deprecated `/boosters/events` + `/boosters/events/[slug]` routes were not deleted (they never existed on disk); the dropdown link was removed in the 2026-05-25 nav restructure.

**Data sources:** events.

---

### `/boosters/documents`

**Purpose:** bylaws, IRS determination letter, meeting minutes, sponsor flyers.

**Sections, top to bottom:**

1. **Page header**
   - Title: "Documents"

2. **Governance** (`doc_type = 'governance'`)
   - Heading: "Governance"
   - List of `documents` rows: title, description, doc_date, "Download PDF →" link

3. **Financial** (`doc_type = 'financial'`)
4. **Minutes** (`doc_type = 'minutes'`)
   - Newest first
5. **Sponsor flyers** (`doc_type = 'sponsor_flyer'`)
6. **Other** (`doc_type = 'other'`)

**Data sources:** documents.

**Empty state per section:** hide entirely. Empty state for whole page: "Documents will be posted here once available."

**Phase 1 expectations:**
- Bylaws PDF: from Chevon (item 8 in `next_steps.md`)
- IRS determination letter: from Chevon
- Recent minutes: from Jeremy (he's the secretary)
- No sponsor flyers in Phase 1 (Kendra's redesign)

---

### `/boosters/donate`

**Phase 1 reality (shipped 2026-05-25, see `specs/boosters_donate_spec.md`):** the Stripe-Checkout flow described below is **Phase 2+**. Shipped instead: green hero with Become-a-Member cross-sell, intro prose, 6-card amount grid → single donation Google Form, server-rendered "Thank You to Our Donors" list pulled from the Form-responses sheet via the same service-account JWT used by `/boosters/members`. Treasurer manually verifies each Venmo (`@McNeil-Football`) or mailed-check payment in the sheet (`Payment Received = Yes` + `Payment Received Date` columns) before the row appears on the public list. ISR `revalidate=300`. Anonymous donors render as "Anonymous". Empty state when no rows are confirmed. 20-cap "Show more" placeholder for the future archive page. Bottom navy CTA cross-sells to `/boosters/join`. Form URL + Sheet ID live in `lib/constants.ts` (`DONATION_FORM_URL`, `DONATION_SHEET_ID`); `VENMO_HANDLE` also lifted to a constant.

**Original Phase 2 spec follows:**

**Purpose:** donation form. Standalone from membership. Most donors here are not signing up for a tier.

**Sections, top to bottom:**

1. **Page header**
   - Title: "Make a Donation"
   - Subhead: "Support McNeil Mavericks Football. All donations are tax-deductible."

2. **Donation form**
   - Preset amount buttons: $25 · $50 · $100 · $250 · $500 · Custom
   - Custom amount: dollar field
   - Donor name (required)
   - Donor email (required)
   - Dedication note (optional, "In honor of...")
   - Submit: "Continue to Payment"

3. **Tax info**
   - "McNeil Maverick Football Booster Club is a 501(c)(3). EIN 26-4231242. Your donation is tax-deductible to the full extent allowed by law. You'll receive an emailed receipt."

**Data sources:** none (form posts to API).

**Form submission flow:** server creates Stripe Checkout session with `purpose = 'donation'`, no associated membership. Webhook flips `payments.status = 'succeeded'`. Donor gets Stripe receipt email + an additional thank-you via Resend.

**Thanks page:** `/boosters/donate/thanks?session_id=...` — confirmation, encourage social share, CTA to `/boosters/join` ("Want to do more? Become a member.")

---

## Utility routes

### `/about`

**Purpose:** about the website + general contact. No mission/board (those moved to `/boosters`).

**Sections, top to bottom:**

1. **Page header**
   - Title: "About This Site"

2. **About**
   - Short prose: "mcneilmavericks.org is the public website for McNeil Mavericks football. It's maintained by the McNeil Maverick Football Booster Club, a 501(c)(3) parent volunteer organization. We post game schedules, rosters, news, and information for parents and athletes. To learn more about the booster club, visit [the Boosters section](/boosters)."

3. **Contact form**
   - Existing form from Step 4 (name, email, subject, message + honeypot)
   - Submits to `/api/contact` which emails `boosters@mcneilmavericks.org`

4. **Direct contacts**
   - General questions: `boosters@mcneilmavericks.org`
   - Sponsorship inquiries: `sponsorship@mcneilmavericks.org`
   - Membership questions: `boosters@mcneilmavericks.org` (route to Carol/Ashley)
   - Website / technical issues: `webmaster@mcneilmavericks.org`

5. **Affiliations**
   - "This website is maintained by the McNeil Maverick Football Booster Club and is not a part of McNeil High School or Round Rock ISD. Neither McNeil High School nor Round Rock ISD is responsible for the content or opinions within this website."
   - (Same as footer disclaimer; render again here for emphasis on the page where someone is most likely to ask "who runs this?")

**Data sources:** site_settings.

---

### `/privacy`

**Purpose:** privacy policy.

**Implementation:** MDX rendered from `content/privacy.mdx`. Port from the existing `/privacy_policy.pdf` per Step 4 plan. Frontmatter: title, last_updated. Review against Stripe's required disclosures for accepting payments online.

---

### `/404`

**Purpose:** not found.

**Sections:** title "Page not found.", one paragraph of context, three navigation links (Home, Schedule, Contact).

**Implementation:** static `app/not-found.tsx`.

---

## Page-to-data summary

Quick reference for which tables each public route reads from. Useful for understanding the query load and admin impact when a table changes.

| Route | Reads from |
|---|---|
| `/` | site_settings, games, news_posts, events, sponsors |
| `/schedule` | site_settings, games |
| `/roster` | site_settings, rosters, players |
| `/coaches` | site_settings, coaches |
| `/news` + `/news/[slug]` | news_posts |
| `/sponsors` | site_settings, sponsors, sponsorship_tiers |
| `/resources` | resource_links |
| `/boosters` | site_settings |
| `/boosters/join` | site_settings, membership_tiers |
| `/boosters/members` | public_members view, membership_tiers |
| `/boosters/sponsor` | site_settings, sponsorship_tiers |
| `/boosters/volunteer` | volunteer_opportunities, site_settings |
| `/boosters/committees` | committees, board_members |
| `/boosters/board` | board_members, site_settings |
| `/events` + `/[slug]` + `/events.ics` | events |
| `/boosters/documents` | documents |
| `/boosters/donate` | (form only — no DB read needed) |
| `/about` | site_settings |
| `/privacy` | (static MDX) |
| `/404` | (static) |

---

## Open questions for Jeremy

Quick yes/no, won't block CC from drafting `admin_scope.md` next:

1. **`/sponsors` page tier perks display.** My pick: tiers are sales material; show them on `/boosters/sponsor`, not the thank-you page at `/sponsors`. Confirm or override.
2. **Player photos on `/roster`.** My pick: no for Phase 1 (consent for minors is a real legal issue). Schema accommodates adding later. Confirm.
3. **`/boosters/sponsor` flow A (inquiry form, manual follow-up) vs B (direct Stripe pay).** My pick: A for Phase 1. If A, I add a `sponsorship_inquiries` table in a small schema patch.
4. **Quick Links band icons on home.** My pick: yes, lucide-react line icons, one per card.
5. **`volunteer@mcneilmavericks.org` alias.** Dropped in spec_review.md C3, but `/boosters/volunteer` could use it. My pick: use `boosters@` instead, drop the alias entirely. Confirm.
6. **Social media in footer: X/Twitter or skip?** My pick: skip unless the booster club still actively posts there. Facebook + Instagram + YouTube cover the active surface.

---

## What's next

Content map locked once Jeremy responds to the six open questions above.

Next CC doc: `admin_scope.md` — what each admin role can do across the new content types (coaches, games, rosters, players, resource_links). Then `build_plan.md` patches.
