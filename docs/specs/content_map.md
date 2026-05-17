# Content Map & Route Spec

Phase 1 spec for the new mcneilmavericks.org. Written 2026-05-14.

**North star (from CC research, adopted verbatim):** Give parents an easy way to put money or time into the program, give sponsors a reason to write a check, and give the booster club a durable home that doesn't require one person holding all the passwords.

**Design rule:** Anything a board member needs to change must be editable through a web admin UI by someone who has never written code. Board edits content; webmaster edits structure. Webmaster role can be empty for months and nothing breaks.

**Scope discipline:** No member portal. Public visitors never log in. Anything currently gated either becomes public, gets killed, or moves to SportsYou.

---

## Top-level public nav

Five items. Matches what we saw scroll cleanly on the current SE site and matches the Stony Point comp.

1. **Home** — `/`
2. **About** — `/about`
3. **Join** — `/join`
4. **Sponsor** — `/sponsor`
5. **Get Involved** — `/get-involved`

Plus footer/secondary links: News, Events, Sponsors (full list), Board, Documents, Contact, Privacy.

---

## Public page inventory

| Route | Purpose | Content source | Editable by board? |
|---|---|---|---|
| `/` | Homepage hero, primary CTA, latest 3 news, upcoming events, sponsor strip | Mix: site settings + news collection + events collection + sponsors collection | Yes (via content types) |
| `/about` | Who we are, mission, what dues fund, board roster, meeting cadence, bylaws PDF, IRS letter, RRISD disclaimer | Page-level editable blocks + board collection + documents collection | Yes |
| `/join` | Membership tiers, pay-your-way / volunteer-instead, signup with Stripe checkout | Membership tiers (settings) + page blocks | Yes (prices + copy) |
| `/sponsor` | Sponsorship tier comparison, why-sponsor pitch, current sponsors strip (empty state ok), become-a-sponsor flow with Stripe checkout, sponsorship flyer PDF download, contact alias | Sponsorship tiers (settings) + sponsors collection + page blocks | Yes |
| `/get-involved` | Volunteer opportunities, committee list, upcoming events with sign-ups, contact | Volunteer opportunities collection + committee list (settings) + events collection | Yes |
| `/news` | Reverse-chron list of announcements | News collection | Yes |
| `/news/[slug]` | Individual announcement | News collection | Yes |
| `/events` | Calendar view + list view of upcoming events | Events collection | Yes |
| `/events/[slug]` | Individual event with sign-up link, location, time | Events collection | Yes |
| `/sponsors` | Full list of current sponsors with logos, tier, link to sponsor site | Sponsors collection | Yes |
| `/members` | Public list of dues-paid members, opt-in, grouped by tier | Memberships collection (filtered to opted-in) | Yes (per-member opt-in at signup) |
| `/board` | Board roster with photos, roles, contact (or aliased contact) | Board collection | Yes |
| `/documents` | Bylaws, IRS determination letter, meeting minutes archive, financial summaries | Documents collection | Yes |
| `/contact` | Contact form, mailing address, role-based email aliases, Facebook group link | Site settings + contact form | Yes (settings) |
| `/privacy` | Privacy policy | MDX in repo (ported from existing PDF) | No (structural, set once) |
| `/404` | Not found page | MDX in repo | No |

16 routes total. 12 content-driven, 4 collection-detail pages. Membership listing pattern reuses the 2021-22 SE site's "Thank you to our members" page structure.

---

## Homepage detail (most-trafficked page)

**Layout (top to bottom):**

1. **Hero band**
   - Background image (uploadable in admin; placeholder = generic stadium at night)
   - Site title / wordmark ("McNeil Mavericks Football Booster Club")
   - One-sentence value prop (editable in admin) — e.g., "Funding the program. Building the community. Supporting every Mav on the field."
   - **One primary CTA button** — defaults to "Join the Club" linking to `/join`. Admin can swap to "Become a Sponsor" or "Make a Donation" depending on season (sponsorship drive in summer, dues push at the start of school, donations at end-of-year giving time).

2. **Three quick-action cards** (admin can reorder/swap from a fixed set of 5)
   - Join the Club → `/join`
   - Become a Sponsor → `/sponsor`
   - Make a Donation → `/join#donate` (or Stripe direct)
   - Volunteer → `/get-involved`
   - Subscribe to Newsletter → mailto or future signup form

3. **Latest news** — auto-populates from News collection, latest 3, each card = image + headline + date + 1-line excerpt + Read More link

4. **Upcoming events widget** — auto-populates from Events collection, next 3 upcoming, each = date + name + location, "View all" link to `/events`. Empty state: "No upcoming events yet. Check back soon." (don't show a sad empty box)

5. **Sponsor strip** — horizontal scroll/grid of current sponsor logos. Auto-populates from Sponsors collection. Empty state for now: hide the entire strip. Once 1+ sponsors are added, strip appears. Click logo → sponsor's website (new tab).

6. **Secondary CTA band** — "Want to support the Mavs? Here's how →" with links to Join, Sponsor, Donate, Volunteer.

7. **Footer** (site-wide)
   - Booster club name, mailing address (settings)
   - Contact email (settings)
   - Social links (settings: Facebook group, Instagram if exists, YouTube if exists)
   - RRISD disclaimer (hardcoded text — required by district)
   - Copyright line
   - Small "Admin" link in corner → `/admin` login (only admins know to look)

**Key admin edits on homepage:** value prop sentence, primary CTA destination, hero image, which 3 quick-action cards show. Everything else is auto-driven from collections.

---

## About page detail

**Layout:**

1. Page title + intro paragraph (editable)
2. **Our Mission** — Real copy ported from the existing SE site (seed for new site, admin-editable):

   > "The purpose of the Booster Club is to provide encouragement and generate support for the football program at McNeil High School. The Booster Club is a 501(c)3 organization that works to support and improve the football program through activities for the teams and improvement of facilities and equipment.
   >
   > Support and improve the McNeil Mavericks Football program and teams through:
   > - Positive interaction between the Booster Club, school officials, the coaching staff, the student body, and the community.
   > - Hosting and sponsoring events to build team spirit and morale amongst athletes, student body, parents, and community including pre-game and post-game gatherings, dinners, and rallies as well as an EOY awards ceremony.
   > - Hosting and sponsoring events to bring the community and school together in support of the McNeil Football program.
   > - Fundraising activities to provide upgrades and benefits to the teams, athletes, and program.
   > - Working for the development of a constructive attitude by all students towards all levels of athletic endeavors."

3. **What dues fund** — placeholder for cutover, admin-editable post-launch. Real copy comes from Chevon when she has time. Placeholder text: "Your dues directly support team meals, equipment, the end-of-year banquet, senior recognition, and other ways we boost McNeil Mavericks Football."
4. **Board roster** — auto-populated from Board collection. Photo + name + role + (optional) email alias.
5. **Meeting cadence** — editable text. Default: "First Tuesday of every month at McNeil High School. All members welcome."
6. **Governing documents** — links to Bylaws PDF, IRS Determination Letter PDF, any other official docs. Pulled from Documents collection filtered to type=governance.
7. **501(c)(3) statement** — editable. Default mentions EIN 26-4231242 and tax-deductibility.
8. **RRISD disclaimer block** — hardcoded with the following default (verified against `next_steps.md` item 8 before launch):

   > "This website is maintained by the McNeil Maverick Football Booster Club and is not a part of McNeil High School or Round Rock ISD. Neither McNeil High School nor Round Rock ISD is responsible for the content or opinions within this website."

---

## Join page detail

**Layout:**

1. Headline + 2-3 sentence pitch (editable)
2. **"Every parent in" callout** — the booster club's commitment from `booster_club_info.md`: "$0 to $500 — pay your way. Cash, time, or both." Editable.
3. **Membership tiers table** — auto-rendered from Membership Tiers settings. Each tier = name, price, what's included, action button.
4. **Action button behavior** depends on tier price:
   - **$0 tier (Free Fan Base)** — button label "Sign up free." Form submits directly to `memberships` table. `payment_id` is null, `paid` is true (nothing to pay). Skips Stripe entirely (Stripe rejects $0 charges).
   - **Paid tier** — button label "Join at this level." Routes to Stripe Checkout with the tier's price and the form data captured as Stripe metadata. On webhook receipt of `checkout.session.completed`, the `memberships` row is created with `paid = true` and `payment_id` linked.
5. **Public listing opt-in** — checkbox on the form: "List my household on the public Supporters page" (default unchecked). Drives `memberships.list_publicly`. Populates `/members`.
6. **Volunteer-only option** — for the $0 "pay with time" path. Links to `/get-involved`.
7. **Make a one-time donation** — separate from membership. Links to Stripe one-time donation flow. Pre-set amounts ($25/$50/$100/$250/$500) plus custom amount field. (Note: max preset is $500 not $1000, matching the actual 2026-27 tier ceiling.)
8. **Tax-deductibility note** — editable, includes EIN.
9. **FAQ accordion** (optional Phase 1, drop if tight): "Do I have to renew every year?" "Can my employer match?" etc.

**Membership tier data model:**
```
- name (string) — e.g., "Blitz!"
- price_cents (integer) — 0 for Free Fan Base, no Stripe call for $0 tiers
- description (text) — short pitch
- perks (array of strings) — bulleted list
- sort_order (integer)
- active (boolean) — soft-archive old tiers without deleting
- year (string) — "2026-27" school-year format
- requires_tshirt_size (boolean) — collect t-shirt size at checkout if true
- requires_second_tshirt_size (boolean) — collect second size for $250+ tiers
- badge_label (string, nullable) — e.g., "Most Popular", null = no badge
```

**Membership signup form fields** (based on the existing Google Form which is actively working):
- Parent 1 name + email + phone (required)
- Parent 2 name + email + phone (optional)
- Player name(s) and grade(s)
- Tier selection (drives price)
- T-shirt size 1 (conditional on tier)
- T-shirt size 2 (conditional on tier $250+)
- Additional donation amount (optional)
- Employer match name (optional)
- SportsYou opt-in checkbox

This replaces the Google Form. The form data captured today should keep being captured — it's what Kendra and Sylvia need (t-shirt sizes for merch, employer match for fundraising).

Phase 1 seed data (real — pulled from the 2026-27 Google Form responses Jeremy provided):

- **Free Fan Base!** — $0 — "Stay in the loop. Newsletters, updates, community."
- **Game Day!** — $20 — perks TBD by board
- **Offense ⇄ Defense!** — $50 — perks TBD by board
- **Blitz!** — $100 — includes one t-shirt (size collected at signup)
- **Touchdown!** — $250 — includes a second t-shirt (size collected at signup)
- **Playoffs!** — $500 — perks TBD by board

Real demand signal from 2026-04-08 → 2026-04-24 (35 signups):
- Game Day ($20): 12 — most popular paid tier
- Blitz ($100): 10
- Free Fan Base ($0): 7 — meaningful "I want in but can't pay" signal
- Offense/Defense ($50): 3
- Playoffs ($500): 1
- Touchdown ($250): 1

Implications for the new site:
- The "Free Fan Base" tier validates the "pay-your-way / $0 option" instinct from `booster_club_info.md`. Keep it.
- Game Day is the volume tier. Likely deserves a "Most Popular" badge in the UI.
- Form already collects: parent 1/2 name + email + phone, player name(s) and grade(s), SportsYou opt-in, t-shirt size(s), additional donation amount, employer match name.
- 8 of 15 invoices are still in "email-sent" status (unpaid). $770 sitting uncollected. Stripe Checkout would close that gap — no manual invoice chasing.

---

## Sponsor page detail

**Layout:**

1. Headline: "Become a McNeil Mavericks Football Sponsor"
2. **Why sponsor** — 3 short paragraphs (editable). Audience size, community goodwill, tax deduction.
3. **Sponsorship tier comparison table** — auto-rendered from Sponsorship Tiers settings. Tier name, price, perks matrix (checkmarks). Modeled on Stony Point's table.
4. **Download sponsorship flyer (PDF)** — link to PDF in Documents collection (type=sponsor-flyer).
5. **Become a sponsor** — two paths:
   - **Pay online now** → Stripe checkout, choose tier
   - **Request more info** → contact form to `sponsorship@` alias (or `boosters@` until that alias exists)
6. **Current sponsors** — empty state for now. Once populated, grid of logos with tier badges.

**Sponsorship tier data model:**
```
- name (string) — e.g., "MVP"
- price_cents (integer)
- description (text)
- perks (array of strings)
- badge_label (string, nullable) — e.g., "Recommended", null = no badge (standardized with membership tier)
- sort_order (integer)
- active (boolean)
- year (string) — "2026-27" school-year format
```

Phase 1 default seed (mirrors Stony Point, board confirms post-launch):
- MVP — $5,000
- Diamond — $2,500
- Platinum — $1,500
- Gold — $1,000
- Blue — $500

**Sponsor (the company) data model:**
```
- name (string)
- logo_url (string) — uploaded via admin, stored in Supabase Storage
- website_url (string)
- tier_id (FK → sponsorship_tier)
- year (string) — "2026-27"
- featured (boolean) — show on homepage strip
- sort_order (integer)
- active (boolean)
```

---

## Get Involved page detail

**Layout:**

1. Headline + pitch (editable)
2. **Volunteer opportunities** — cards from Volunteer Opportunities collection. Each = title, when, what you do, what you get (steal Lake Travis pattern — "Friday night Spirit Shack shift = parking pass"), sign-up link (SignUpGenius URL Phase 1, internal form Phase 2).
3. **Committees** — Committees are a separate collection (not part of Board). Each committee has a description + chair contact. Seed content for cutover (ported from existing SE Booster Committees page):
   - **Social Media** — Maintain football website for communications and notifications. Maintain Facebook accounts promoting a positive image of the program. Ongoing throughout school year.
   - **Team Meals** — Coordinate pregame meals for freshman and JV players. Discuss menu and price with the Sponsor. Identify meal vendors, solicit bids, coordinate pickup/delivery. Coordinate Varsity parent team dinners. Football season only.
   - **Membership** — Maintain membership list (emails, contact info, current player roster). Collect sign-in sheets from meetings and events. Promote the Booster Club. Ongoing.
   - **Merchandise** — Vendors, pricing, design, purchase, inventory. Schedule volunteers to sell at events. Monthly report at Booster meeting. Work with Social Media to advertise. Ongoing.
   - **Parent Meetings** — Date, location, volunteers for spring/fall parent meetings. Work with Social Media, Merchandise, Membership committees. Two-time activity.
   - **Football Banquet** — Date, time schedule. Cafeteria booking. Vendor bids. Awards coordination with Sponsor. Volunteer coordination for ads, tickets, decorations, senior gifts. One-time activity.
   - **Summer Events** — Pool location, volunteers, food donations. Advertise via Social Media. One-time activity.
   - **Meet the Mavs** — Date with Sponsor/Principal. Coordinate with other booster clubs. Food vendor bids. Tables, volunteers. One-time activity.
   - **Senior Night** — Game date set by RRISD. Senior names from Sponsor. Permissions, flower vendors, volunteers. One-time activity.
   - **Tunnel Stampede** — Event date. Business sponsorships. Advertise via Social Media. Application/payment design. Spirit wear order. Volunteers. One-time activity.
   - **Fundraisers** — Oversee any board-determined fundraisers. Coordinate with Social Media. Ongoing.

   Note: Committees coordinate via GroupMe (separate from board comms which use iMessage). Mention GroupMe on the page so volunteers know what to expect.

4. **Upcoming events** — same widget as homepage, auto-populated.
5. **Contact a board member** — links to `/board`.

**Committee data model:**
```
- name (string) — e.g., "Tunnel Stampede"
- description (text) — full description, what they do, when active
- cadence (enum) — "ongoing" | "seasonal" | "one-time"
- chair_board_member_id (FK → board_members, nullable) — link to current chair
- contact_email (string, optional) — usually boosters@ or a role alias
- sort_order (integer)
- active (boolean)
```

**Volunteer Opportunity data model:**
```
- title (string)
- description (text)
- when_text (string) — "Friday nights, fall season" (named when_text because `when` is a SQL reserved word)
- what_you_do (text)
- what_you_get (text)
- signup_url (string) — external SignUpGenius link, or internal form route
- active (boolean)
- sort_order (integer)
```

---

## News collection

**Data model:**
```
- title (string)
- slug (string, auto-generated, editable)
- excerpt (text, ~200 chars)
- body (rich text / markdown via admin editor)
- featured_image (string, uploaded)
- published_at (datetime)
- author (string) — free text, e.g., "Jeremy V., Secretary"
- status (enum: draft, published)
```

**Index page (`/news`):** reverse-chron list, paginated 10 per page. Each card = image + title + excerpt + date + read more.

**Detail page (`/news/[slug]`):** full article, share buttons (Facebook, copy link), back to news index. Below: 2 related news posts.

**Admin needs:** create, edit, publish, unpublish, delete. Rich text editor that handles bold/italic/links/headings/lists/images. Image upload inline. Draft preview.

---

## Events collection

**Data model:**
```
- title (string)
- slug (string)
- description (text)
- starts_at (datetime)
- ends_at (datetime, nullable)
- location (string)
- location_url (string, optional — Google Maps link)
- signup_url (string, optional)
- cover_image (string, uploaded)
- status (enum: draft, published, cancelled)
- featured (boolean) — homepage widget
```

**Index page (`/events`):** Two views — list (default, upcoming first) + calendar (month grid). Past events accessible but de-emphasized.

**Detail page (`/events/[slug]`):** Date, time, location with map link, full description, sign-up button if URL set, share buttons.

**Admin needs:** create, edit, mark cancelled (don't delete — visitors may have bookmarked), recurring events optional (skip for Phase 1, manually duplicate for now).

---

## Board collection

**Data model:**
```
- name (string)
- role (string) — "President", "Treasurer", etc.
- email_alias (string, optional) — "president@mcneilmavericks.org" — only displayed if populated AND the alias actually routes (see dependency note)
- bio (text, optional, short)
- photo_url (string, uploaded, optional)
- sort_order (integer) — by hierarchy: Pres, VPs, Treasurer, Secretary, then alphabetical
- year (string) — "2026-27" school-year format — supports historical boards
- active (boolean)
```

**Display:** `/board` page = card grid. About page = condensed strip.

**Dependency note:** `email_alias` displays a real email only if `next_steps.md` item 3a (Cloudflare Email Routing) is complete. If aliases aren't live at cutover, leave the field blank for each board member — the UI falls back to "Contact via boosters@mcneilmavericks.org" rather than displaying a bouncing address.

**Phase 1 default seed** (from `booster_club_info.md`, with Ashley Olson as canonical name per spec_review C2):
- Carol Glinski — President
- Chevon Williams — Treasurer
- Ashley Olson — Co-Treasurer (Past President)
- Kendra Jalbert — VP Fundraising
- Shannon Schoepflin — VP Social Events
- Sylvia Brito — VP Merch
- Jeremy Vest — Secretary
- Debby Mata — Communications & Membership Support
- Monica Woods — Social Events Support

---

## Documents collection

**Data model:**
```
- title (string)
- description (text, optional)
- file_url (string, uploaded PDF)
- type (enum: governance, financial, minutes, sponsor-flyer, other)
- date (date)
- public (boolean) — true = anyone can view, false = admin-only (Phase 2 if needed)
- sort_order (integer)
```

**Display (`/documents`):** Grouped by type. Governance docs at top (bylaws, IRS letter), then minutes archive (reverse-chron), then financial summaries, then other.

**Admin needs:** Upload PDF, set metadata, archive (don't delete).

**Recommend public default for minutes** — Stony Point publishes minutes publicly, signals transparency. Board can override per-document.

---

## Site settings (singletons, one record each)

These are the "one-off" content pieces that don't fit a collection model. Each is editable in admin.

**Organization settings:**
- legal_name — "McNeil Maverick Football Booster Club"
- display_name — "McNeil Mavericks Football Booster Club"
- ein — "26-4231242"
- mailing_address (text)
- primary_contact_email — boosters@mcneilmavericks.org
- school_affiliation_disclaimer (rich text, RRISD-required, hardcoded default editable in case wording changes)

**Social links:**
- facebook_group_url
- instagram_url
- youtube_url
- (each can be empty; UI hides empty ones)

**Homepage settings:**
- hero_image_url (uploaded)
- hero_headline (string)
- hero_subhead (string)
- primary_cta_label (string)
- primary_cta_url (string)
- quick_action_card_1, _2, _3 — each is a pick from a fixed enum: `join | sponsor | donate | volunteer | newsletter`. Admin selects which 3 to show and in what order. Each option has a hardcoded icon + label + destination URL (centralized in code, not editable per-card).

**Email aliases for display** (canonical list per spec_review C3 — not the email server config):
- boosters (general / info — fallback for all unrouted inquiries)
- president
- treasurer
- secretary
- webmaster
- sponsorship
- (each is a string the admin types; UI shows whichever are populated. VP-specific aliases deferred. `info@` is dropped — `boosters@` serves that purpose.)

---

## What's intentionally NOT on the site

Closing the loop on the SE features we're killing or punting:

- **Roster pages** — link out to school athletics site, don't host
- **Game schedule** — link out, don't host
- **Live game streaming** — link to iHSFAN, don't host
- **Coach bios** — link to school, don't host (and they're stale anyway)
- **HUDL** — link only
- **Parent Portal** — concept eliminated; anything still useful moves to SportsYou (Kendra owns)
- **Member-only content** — no logged-in member experience exists
- **SE 176-member directory** — not auto-migrated. Most entries are from 2019. Email outreach to re-engage; new signups go through the new `/join` form. SE directory is read-only reference until SE lapses.
- **MAV Store / merch** — Phase 3, not in cutover scope. Sylvia's t-shirt activities continue offline for now.
- **Photo galleries** — Phase 3
- **Hype videos / mixtapes** — Phase 3 if at all (Stony Point has these, but they're a heavy maintenance burden)
- **Scholarship recipient list** — add post-Phase-1 once a scholarship exists. Booster club doesn't have one currently.
- **iCal feeds** — defer; revisit if anyone asks
- **Discount codes** — defer
- **Recurring events** — defer; duplicate manually for Phase 1
- **Internal volunteer sign-up forms** — Phase 2; use SignUpGenius links in Phase 1

---

## Pages reachable from where

For navigation auditing — every page should be reachable without typing a URL.

- `/` → linked from logo, "Home"
- `/about` → top nav "About"; footer
- `/join` → top nav "Join"; homepage CTA; multiple in-page links
- `/sponsor` → top nav "Sponsor"; homepage card
- `/get-involved` → top nav "Get Involved"; homepage card
- `/news` → footer; "View all news" from homepage
- `/news/[slug]` → from `/news`, from homepage news cards
- `/events` → footer; "View all events" from homepage and get-involved
- `/events/[slug]` → from `/events`, homepage events widget
- `/sponsors` → from `/sponsor` page, from homepage sponsor strip ("View all sponsors")
- `/members` → from `/join` page ("See current supporters"), from `/about` ("Thank you to our members")
- `/board` → from `/about` ("View full board")
- `/documents` → from `/about` ("Governing documents"), from footer
- `/contact` → footer, multiple page CTAs
- `/privacy` → footer
- `/admin` → footer corner link (small, "Admin")

No orphan pages.

---

## Open items to confirm at next board meeting (won't block build)

Not blockers because every item below is configurable in admin without a code change. May 2026 meetings did not resolve most of these (per Jeremy).

1. Membership tier prices + perks (seed values from existing Google Form; board ratifies actual amounts)
2. Sponsorship tier names + prices + perks (seed values from Stony Point comp; board ratifies)
3. "What dues fund" final copy (placeholder text shipped at launch; Chevon writes real version when ready)
4. Mailing address (PO box decision still open per `booster_club_info.md`)
5. Whether to publish meeting minutes publicly (default: yes, per Stony Point pattern)
6. School logo authorization status (until confirmed, site uses type-only booster branding)
7. Final board roster + photos (we'll seed from `booster_club_info.md`)

---

## What I need from you / the board, when

**Don't need yet (writing spec only):** anything.

**Need before Phase 1 build is "done":**
- Sponsor logos — none yet (0 current sponsors). Logos arrive as Kendra closes deals.
- Hero image — can use a generic stadium placeholder; replace anytime
- Board member photos — optional, looks better with them; defaults to initial-circle avatar without
- Bylaws PDF + IRS letter PDF — from Chevon, for `/documents`

**Need before going live (DNS flip):**
- Board sign-off (June 2 or July 7 meeting)
- Final membership tier prices (admin-edit, but board should ratify)
- Final sponsorship tier prices (same)
- Confirmation that mailing address is set
- Confirmation that role-based email aliases exist (next_steps item 3a)

**Need post-launch (not blocking cutover):**
- Real sponsor logos as Kendra closes deals
- Ongoing news/events content (Jeremy as Secretary)
