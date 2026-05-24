# Spec: Booster Club Nav Cleanup + `/boosters/committees` Page

**As-shipped 2026-05-23 — commits `c7668d6` (initial) + `4e3f21c` (hero rework).** All three tasks live. Deviations:
- **Migration renumbered 044 → 045.** Slot 044 was taken by `044_reset_sponsors_featured.sql` (shipped 2026-05-22). Files: `db/migrations/045_committees_full_descriptions.sql` + `045_rollback.sql`. Same renumber pattern as past specs (030→034, 039→041).
- **`BOOSTER_LINKS` is duplicated** in `components/layout/Header.tsx:15-25` AND `components/layout/MobileNav.tsx:22-32`, not the single shared constant the spec assumed (line 78, 87). Edited both identically to keep desktop + mobile in sync. Worth lifting to a shared module at the next nav edit.
- **AC6 fails by spec error**: `/boosters/board` returns 404, not 200 — there is no `app/boosters/board/` route file in the codebase. The Board nav entry was a broken link before this commit; the spec's "Do NOT remove the `/boosters/board` route file itself" guidance had nothing to remove. Decide later: build the route, or leave board-on-`/boosters` as the sole surface.
- **AC19 ≈ pass**: 10/11 descriptions exceed 80 chars; Fundraisers is exactly 80 ("Oversee any board-determined fundraisers. Coordinate with Social Media. Ongoing." = 80). All 11 strings match the spec verbatim; only the `desc_len > 80` assertion is off-by-one for that row.
- **Hero rework (`4e3f21c`)**: Jeremy reviewed the initial hero and called the navy-on-navy horseshoe at `opacity-20` unreadable + title alignment off. Replaced with `mhs-logo.png` in a `rounded-full bg-white p-1` disc on the left (matches Header treatment for navy bg), centered `flex-1 text-center` title block, and a green "Volunteer →" button on the right linking `/boosters/volunteer`. Section dropped `relative overflow-hidden`; mobile stacks vertically.
- **Asset no-op**: `public/brand/mhs-horseshoe.jpg` already existed with identical MD5 to `docs/MHS Horseshoe Color.jpg`. The spec's `cp` step was redundant. (Asset is now unused on this page after the hero rework; left in place for future use.)
- **Cadence badge contrast unchanged**: shipped with `bg-mavs-green/10 text-mavs-green`. If browser QA shows it as too faint, swap to `bg-mavs-green text-white`.

Written 2026-05-23. Three small changes shipped as one commit:

1. Header dropdown: rename "Join" → "Join the Club!" (header dropdown only)
2. Header dropdown: remove "Board" entry (page itself stays accessible at `/boosters/board`)
3. Build `/boosters/committees` page

**Reads with:**
- `content_map_v2.md` — `/boosters/committees` section (the design this implements)
- `schema.md` — `committees` table definition + 11-row seed
- `spec_review.md` — verbatim committee descriptions from the SE site
- `boosters_sponsor_spec.md` — sibling spec shipped same day; visual patterns mirror it
- `boosters_join_spec.md` — sibling tier-cards page; "Join the Club!" rename context

## Prerequisites

CC must verify before starting:
- Working tree clean, `origin/main` matches local
- 11 active rows in `committees` for `cadence IN ('ongoing','seasonal','one_time')`
- `committees` table seeded per `schema.md` (verify with the count query below)

Verification:
```sql
select count(*) from committees where active = true;
-- expect: 11

select name, cadence, sort_order from committees where active = true order by sort_order;
-- expect:
-- 1  Social Media       ongoing
-- 2  Team Meals         seasonal
-- 3  Membership         ongoing
-- 4  Merchandise        ongoing
-- 5  Parent Meetings    seasonal
-- 6  Football Banquet   one_time
-- 7  Summer Events      one_time
-- 8  Meet the Mavs      one_time
-- 9  Senior Night       one_time
-- 10 Tunnel Stampede    one_time
-- 11 Fundraisers        ongoing
```

If preconditions fail, stop and report. The committee descriptions in `schema.md` are shorter than the verbatim SE-site descriptions in `spec_review.md`. The spec below uses the longer SE-site descriptions — that means a small data migration to update existing rows (see Task 3 / Migration 044).

## Task 1: Rename "Join" → "Join the Club!" in header dropdown

**Scope:** header dropdown only. The Booster Club dropdown currently shows:

```
About the Booster Club
Join
Members
Sponsorship Opportunities
Volunteer
Committees
Board
Calendar / Events
Documents
Donate
```

After this change:

```
About the Booster Club
Join the Club!
Members
Sponsorship Opportunities
Volunteer
Committees
Calendar / Events
Documents
Donate
```

(See Task 2 for the Board removal; the two changes ship in one nav edit.)

**Find the constant.** Per `CLAUDE.md` build progress 2026-05-20, this is the `BOOSTER_LINKS` constant. Likely location: `components/layout/Header.tsx` or `components/layout/HeaderDropdown.tsx` or an adjacent constants file. CC: locate it, edit the one label.

**Do NOT change:**
- The route `/boosters/join` (URL stays the same)
- The page H1 / title on `/boosters/join`
- The footer "Site" links row entry (which reads "Join the Booster Club" today)
- The homepage Get Involved card label
- The homepage Hero Carousel headline_cta tile CTA label ("Join the Booster Club")
- Any other CTA label elsewhere on the site
- Mobile drawer label — wait. Mobile drawer renders the same `BOOSTER_LINKS` constant as the desktop dropdown (per the existing accordion pattern). The mobile drawer label flips with the desktop one automatically. That's correct and intentional.

If CC finds the label hardcoded in more than one place, flag and ask before bulk-renaming.

**Acceptance:**
- Desktop header Booster Club dropdown shows "Join the Club!" as the second item
- Mobile drawer Booster Club accordion shows "Join the Club!" as the second item
- Clicking still navigates to `/boosters/join`
- Footer "Join the Booster Club" link unchanged
- All other "Join the Booster Club" CTAs across the site unchanged

## Task 2: Remove "Board" from header dropdown

**Scope:** header dropdown only. The `/boosters/board` route stays in place and accessible at the URL. The dropdown entry is the only thing removed.

**Why:** Board content already appears on `/boosters` (the booster club landing page renders the board grid per `CLAUDE.md`). Two surfaces for the same content adds nav noise. The standalone `/boosters/board` page stays addressable via direct URL — useful for deep-linking, future Phase 2 board-bio expansion, or if it gets re-added later.

**Find the same `BOOSTER_LINKS` constant.** Remove the Board entry. The list shrinks from 10 items to 9.

**Do NOT remove:**
- The `/boosters/board` route file itself
- The board grid section on `/boosters` (the booster club landing page)
- Any link from `/boosters` landing to `/boosters/board` if one exists

**Acceptance:**
- Desktop Booster Club dropdown has 9 items, no Board entry
- Mobile drawer Booster Club accordion has 9 items, no Board entry
- `/boosters/board` still returns 200 if you type the URL directly
- The board grid on `/boosters` still renders

## Task 3: Build `/boosters/committees` page

The actual page. Reads from `committees` table, displays the 11 committees as a grid of cards. Recruiting page — leads volunteers toward `/boosters/volunteer`.

### Migration 044: Update committee descriptions to full SE-site copy

The seed in `schema.md` (and live in DB) uses abbreviated descriptions. The page benefits from the longer descriptions in `spec_review.md`. One migration updates all 11 rows.

File: `db/migrations/044_committees_full_descriptions.sql`

```sql
-- Update committees with full SE-site descriptions per spec_review.md.
-- Original seed (migration 010 or equivalent) used abbreviated copy; this
-- replaces with the verbatim descriptions from the existing SportsEngine site.

update committees set description = 'Maintain football website for communications and notification to parents and players. Maintain Facebook and Twitter accounts. Ongoing throughout school year.' where name = 'Social Media';

update committees set description = 'Coordinate pregame meals for freshman and JV. Discuss menu and price with Sponsor. Identify vendors, solicit bids, coordinate pickup and delivery. Coordinate Varsity parent team dinners. Football season only.' where name = 'Team Meals';

update committees set description = 'Maintain membership list (emails, contact info, current player roster). Collect sign-in sheets from meetings and events. Promote the Booster Club. Ongoing.' where name = 'Membership';

update committees set description = 'Vendors, pricing, design, purchase, inventory. Schedule volunteers to sell at events. Monthly report at Booster meeting. Work with Social Media to advertise. Ongoing.' where name = 'Merchandise';

update committees set description = 'Date, location, volunteers for spring and fall parent meetings. Work with Social Media, Merchandise, and Membership committees. Two-time activity.' where name = 'Parent Meetings';

update committees set description = 'Date, time schedule. Cafeteria booking. Vendor bids. Awards coordination with Sponsor. Volunteer coordination for ads, tickets, decorations, senior gifts. One-time activity.' where name = 'Football Banquet';

update committees set description = 'Pool location, volunteers, food donations. Advertise via Social Media. One-time activity.' where name = 'Summer Events';

update committees set description = 'Date with Sponsor and Principal. Coordinate with other booster clubs. Food vendor bids. Tables, volunteers. One-time activity.' where name = 'Meet the Mavs';

update committees set description = 'Game date set by RRISD. Senior names from Sponsor. Permissions, flower vendors, volunteers. One-time activity.' where name = 'Senior Night';

update committees set description = 'Event date. Business sponsorships. Advertise via Social Media. Application and payment design. Spirit wear order. Volunteers. One-time activity.' where name = 'Tunnel Stampede';

update committees set description = 'Oversee any board-determined fundraisers. Coordinate with Social Media. Ongoing.' where name = 'Fundraisers';
```

Rollback file `044_rollback.sql`: replace each `update` with the corresponding abbreviated text from `schema.md`. Schema unchanged; data-only rollback.

Verification after apply:
```sql
select name, length(description) as desc_len from committees order by sort_order;
-- expect: all 11 rows, every desc_len > 80
```

### Page file: `app/boosters/committees/page.tsx`

Server component, `force-dynamic`. Standard pattern matching `/sponsors`, `/boosters/sponsor`, `/boosters/join`.

Plus: `app/boosters/committees/[catchall]/page.tsx` with unconditional `notFound()`, matching the sibling pattern.

### Data fetch

```ts
const supabase = createServerClient();

const { data: committees } = await supabase
  .from('committees')
  .select('id, name, description, cadence, contact_email, sort_order')
  .eq('active', true)
  .order('sort_order', { ascending: true });
```

`chair_board_member_id` exists in the schema but per `content_map_v2.md` "chair (from `chair_board_member_id`)" — chairs aren't seeded today. Skip the join in Phase 1. The card renders without a chair line. If you want, add a TODO comment: `// TODO: when chair_board_member_id is populated, join board_members and render chair name`.

`contact_email` is also nullable and likely null on all 11 seeded rows. Render conditionally — only show the contact line if non-null.

### Page structure

Top to bottom. Header and footer come from the shared layout.

#### 1. Page header (hero band)

Same visual pattern as `/boosters/sponsor` and `/boosters/join`. Navy band, white text, green underline accent, **horseshoe accent on the right side**.

```
<section class="bg-mavs-navy text-white py-12 md:py-16 relative overflow-hidden">
  <div class="container mx-auto px-4 relative z-10">
    <div class="text-center md:text-left md:max-w-3xl">
      <h1 class="text-3xl md:text-5xl font-black uppercase tracking-tight">
        Booster Club Committees
      </h1>
      <div class="h-1 w-20 bg-mavs-green mt-3 mx-auto md:mx-0"></div>
      <p class="text-lg md:text-xl mt-4 text-white/90">
        Ongoing, seasonal, and one-time roles. Every committee needs help — find where you fit.
      </p>
    </div>
  </div>

  {/* Horseshoe accent — small, decorative, right side, hidden on mobile */}
  <div class="hidden md:block absolute right-8 top-1/2 -translate-y-1/2 opacity-20 pointer-events-none">
    <Image
      src="/brand/mhs-horseshoe.jpg"
      alt=""
      width={180}
      height={180}
      className="object-contain"
    />
  </div>
</section>
```

**Asset prep:** CC copies `docs/MHS Horseshoe Color.jpg` → `public/brand/mhs-horseshoe.jpg`. This is the clean horseshoe-only navy mark already used for favicons. At 180×180 with `opacity-20` it reads as a watermark, not a competing logo. Alt text empty because it's decorative; the section already has the h1.

Notes:
- Section is smaller than `/boosters/sponsor` hero (`py-12 md:py-16` vs `py-16 md:py-20`). This is a section header, not a sales hero.
- h1 sized down to `text-3xl md:text-5xl` (vs sponsor page's `text-4xl md:text-6xl`) — same reason.
- Horseshoe is hidden on mobile (`hidden md:block`) because mobile centers the text content. On desktop the text aligns left and the horseshoe sits right.
- `opacity-20` keeps the horseshoe subtle. If it reads as too faint in QA, bump to `opacity-25` or `opacity-30`. Do not go above 40 — it'll start competing with the heading.
- `pointer-events-none` so the decorative image never accidentally captures clicks.

#### 2. Intro / context band

A short prose block beneath the hero. Sets context before the cards.

```
<section class="container mx-auto px-4 py-10 md:py-12 max-w-3xl">
  <div class="space-y-4 text-lg leading-relaxed text-gray-800">
    <p>
      The Booster Club runs on volunteer effort across 11 committees. Some operate year-round, some only during football season, and some come together for a single signature event.
    </p>
    <p>
      Browse the committees below to see what each one does. When you're ready to step up, head to <a href="/boosters/volunteer" class="text-mavs-navy font-semibold underline hover:text-mavs-green transition-colors">Volunteer</a> to sign up.
    </p>
    <p class="text-sm text-gray-600 italic pt-2">
      Committees coordinate via GroupMe. New volunteers receive the invite link after signing up.
    </p>
  </div>
</section>
```

GroupMe note is from `content_map.md` and `spec_review.md`. It's a real expectation-setter — parents who join a committee should know what platform they'll get pulled into. Italic small-text treatment keeps it informational.

Copy is editable post-launch. Add a comment in code: `// Copy editable. Verbatim from spec 2026-05-23.`

#### 3. Cadence filter (optional, ship as deferred)

`content_map_v2.md` proposed an "All · Ongoing · Seasonal · One-Time" filter toggle. **Defer to Phase 2.** Reason: 11 committees is small enough that a single scrollable grid reads fine without filtering. Adding the filter requires client-side state (this becomes a partial client component) and an `isActive` UI pattern. For Phase 1, group the cards by cadence with section subheadings instead — gives users the same scan-ability without interactivity.

Do not add a filter toggle in this commit.

#### 4. Committee cards, grouped by cadence

Render committees grouped into 3 cadence sections, in this order:

1. **Year-Round** (`cadence = 'ongoing'`) — 4 committees: Social Media, Membership, Merchandise, Fundraisers
2. **Football Season** (`cadence = 'seasonal'`) — 2 committees: Team Meals, Parent Meetings
3. **Signature Events** (`cadence = 'one_time'`) — 5 committees: Football Banquet, Summer Events, Meet the Mavs, Senior Night, Tunnel Stampede

Section heading style mirrors `/sponsors` tier groupings: uppercase, navy, green underline, prose subhead.

Within each section: 2-column grid on desktop, 1-column on mobile.

```
<section class="container mx-auto px-4 py-8 md:py-12 space-y-12 md:space-y-16">

  {/* Year-Round */}
  <div>
    <div class="text-center mb-8">
      <h2 class="text-2xl md:text-3xl font-black uppercase tracking-tight text-mavs-navy">
        Year-Round Committees
      </h2>
      <div class="h-1 w-16 bg-mavs-green mx-auto mt-3"></div>
      <p class="text-base text-gray-600 mt-3 max-w-2xl mx-auto">
        Active throughout the school year. Steady, recurring work.
      </p>
    </div>
    <div class="grid grid-cols-1 md:grid-cols-2 gap-6 max-w-5xl mx-auto">
      {ongoingCommittees.map(c => <CommitteeCard committee={c} />)}
    </div>
  </div>

  {/* Football Season */}
  <div>
    <div class="text-center mb-8">
      <h2 class="text-2xl md:text-3xl font-black uppercase tracking-tight text-mavs-navy">
        Football Season Committees
      </h2>
      <div class="h-1 w-16 bg-mavs-green mx-auto mt-3"></div>
      <p class="text-base text-gray-600 mt-3 max-w-2xl mx-auto">
        Active August through November. Ramp up and wind down with the schedule.
      </p>
    </div>
    <div class="grid grid-cols-1 md:grid-cols-2 gap-6 max-w-5xl mx-auto">
      {seasonalCommittees.map(c => <CommitteeCard committee={c} />)}
    </div>
  </div>

  {/* Signature Events */}
  <div>
    <div class="text-center mb-8">
      <h2 class="text-2xl md:text-3xl font-black uppercase tracking-tight text-mavs-navy">
        Signature Events
      </h2>
      <div class="h-1 w-16 bg-mavs-green mx-auto mt-3"></div>
      <p class="text-base text-gray-600 mt-3 max-w-2xl mx-auto">
        One-time-per-year events. Concentrated effort, big payoff.
      </p>
    </div>
    <div class="grid grid-cols-1 md:grid-cols-2 gap-6 max-w-5xl mx-auto">
      {oneTimeCommittees.map(c => <CommitteeCard committee={c} />)}
    </div>
  </div>

</section>
```

Section grouping in the page server component:

```ts
const ongoingCommittees = committees.filter(c => c.cadence === 'ongoing');
const seasonalCommittees = committees.filter(c => c.cadence === 'seasonal');
const oneTimeCommittees = committees.filter(c => c.cadence === 'one_time');
```

Each section's data stays in `sort_order` (already ordered by the page-level query).

#### 4a. CommitteeCard component

Define inline at the top of the page file (matches the inline-component pattern from `/sponsors` and `/boosters/sponsor`).

```tsx
function CadenceBadge({ cadence }: { cadence: 'ongoing' | 'seasonal' | 'one_time' }) {
  const labels = {
    ongoing: 'Year-Round',
    seasonal: 'Football Season',
    one_time: 'Signature Event',
  };
  return (
    <span class="inline-block bg-mavs-green/10 text-mavs-green text-xs font-bold uppercase tracking-wider px-2.5 py-1 rounded">
      {labels[cadence]}
    </span>
  );
}

function CommitteeCard({ committee }: { committee: Committee }) {
  return (
    <div class="bg-white border-2 border-mavs-navy/20 rounded-lg p-6 flex flex-col hover:border-mavs-navy/40 transition-colors">
      <div class="flex items-start justify-between gap-3 mb-3">
        <h3 class="text-xl font-bold uppercase text-mavs-navy">
          {committee.name}
        </h3>
        <CadenceBadge cadence={committee.cadence} />
      </div>
      <p class="text-gray-800 leading-relaxed flex-grow">
        {committee.description}
      </p>
      {committee.contact_email && (
        <a
          href={`mailto:${committee.contact_email}`}
          class="text-mavs-navy text-sm font-semibold mt-4 hover:text-mavs-green transition-colors"
        >
          Contact: {committee.contact_email}
        </a>
      )}
    </div>
  );
}
```

Notes:
- Card border style matches the unbadged `/boosters/sponsor` tier cards (`border-mavs-navy/20`). Subtle.
- Hover state: border darkens (`hover:border-mavs-navy/40`). Light interactive cue. The card itself isn't clickable in Phase 1 — there's no detail page.
- Name and cadence badge sit on the same row at the top, with the badge to the right. Same visual hierarchy as event cards on news sites.
- `flex-grow` on the paragraph means cards in the same row align their bottoms when descriptions vary in length.
- No chair line in Phase 1 (per data-fetch note above).
- Contact email line only renders if `contact_email` is not null. With current seed data, this never renders. That's fine — when admins start populating per-committee contact emails post-launch, the line lights up automatically.

#### 5. Volunteer CTA

Below the cards. Drives the recruiting purpose of the page. Mirrors the `/boosters/sponsor` Contact CTA visually.

```tsx
<section class="container mx-auto px-4 py-12 md:py-16">
  <div class="bg-mavs-navy text-white rounded-lg p-8 md:p-12 text-center relative overflow-hidden max-w-3xl mx-auto">
    <div class="absolute top-0 left-0 right-0 h-1 bg-mavs-green"></div>
    <h2 class="text-2xl md:text-3xl font-black uppercase tracking-tight">
      Ready to Get Involved?
    </h2>
    <p class="text-lg text-white/90 mt-4 max-w-xl mx-auto">
      Sign up to volunteer with a committee. Every parent has something to offer — from one event a year to year-round help.
    </p>
    <a
      href="/boosters/volunteer"
      class="inline-block mt-8 bg-mavs-green text-white px-8 py-4 font-bold uppercase hover:bg-mavs-green/90 transition-colors text-lg"
    >
      Volunteer with the Mavs
    </a>
  </div>
</section>
```

Notes:
- Same green-stripe-on-navy card pattern as `/boosters/sponsor`'s "Ready to Sponsor?" CTA. Consistent visual rhythm across the booster sales surfaces.
- Links to `/boosters/volunteer` — that page is currently 404 (per `followups.md`). The CTA still works; it just lands on a broken page until volunteer is built. Acceptable for now; this is the natural next page to build after committees ships.

## Layout summary

Top to bottom:
1. Navy hero with horseshoe accent (right, desktop only)
2. Intro prose with GroupMe note
3. Committee cards grouped by cadence (3 sections)
4. Volunteer CTA card

No sponsor strip on this page. Per Jeremy 2026-05-23: "we don't need the sponsors piece" on this page. The /sponsors page handles thank-yous; this page recruits volunteers.

## Accessibility

- Heading order: h1 (hero) → h2 (Year-Round) → h3 (each committee) → h2 (Football Season) → h3 → h2 (Signature Events) → h3 → h2 (Ready to Get Involved). No skipped levels.
- Decorative horseshoe image has empty alt — correct, since the h1 conveys the same context.
- Color contrast: navy on white, white on navy, white on green all pass WCAG AA. The `text-mavs-green/10` background of the cadence badge against `text-mavs-green` foreground — verify in QA; if it fails, swap to `bg-mavs-green text-white` (solid).
- Lighthouse a11y target ≥ 90.

## Acceptance criteria

1. `/boosters/committees` renders without errors. Returns 200 in curl and on Vercel preview.
2. `/boosters/committees/foo` returns 404 (catchall route).
3. Header Booster Club dropdown shows "Join the Club!" as 2nd item, no Board entry. Total items: 9.
4. Mobile drawer Booster Club accordion shows "Join the Club!" as 2nd item, no Board entry.
5. Clicking "Join the Club!" still navigates to `/boosters/join`.
6. `/boosters/board` still returns 200 if visited directly.
7. `/boosters` landing page board grid still renders (regression check).
8. Footer "Join the Booster Club" link unchanged (text and target).
9. Hero band: navy bg, h1 "Booster Club Committees" at text-3xl md:text-5xl, green underline, white prose subhead.
10. Horseshoe accent visible on desktop (right side, opacity-20), hidden on mobile.
11. Intro prose with the GroupMe note in italic small text below the main paragraphs.
12. Three section groupings in this order: Year-Round (4 cards), Football Season (2 cards), Signature Events (5 cards). 11 cards total.
13. Each card shows: committee name (uppercase, navy), cadence badge (green pill, top right), full description (verbatim per migration 044), no chair line, no contact line (because data is null).
14. Hover state on cards: border darkens. No card-level click.
15. Volunteer CTA card at bottom: green-stripe-on-navy, "Volunteer with the Mavs" green button → `/boosters/volunteer`.
16. Mobile (375px viewport): everything stacks. Cards single column. Hero centered.
17. No console errors on Vercel preview.
18. Lighthouse a11y ≥ 90 on Vercel preview.
19. Migration 044 applied. All 11 committee descriptions match the verbatim copy per spec.

## Rollback

- Migration 044: apply `044_rollback.sql` to restore abbreviated descriptions. Schema unchanged; data-only.
- Page: revert the commit. `/boosters/committees` returns to 404. Nav reverts to 10 items including Board and "Join."
- The three tasks ship in one commit; rollback is atomic.

## Decisions confirmed by Jeremy 2026-05-23

1. **"Join" → "Join the Club!"** Header dropdown only. Every other surface keeps its existing label.
2. **Board removed from dropdown.** Route stays accessible at `/boosters/board`. Board content remains on `/boosters` landing.
3. **Cards page, no committee-detail pages.** 11 committees fit on a single scrollable page; detail pages would be overkill.
4. **Logo authorization confirmed.** Jeremy holds rights to use MHS logos. Horseshoe accent uses `docs/MHS Horseshoe Color.jpg` → `public/brand/mhs-horseshoe.jpg`.
5. **No sponsors strip on this page.** Page is about volunteer recruiting, not sponsor recognition.
6. **GroupMe note included.** Sets expectations for what new committee volunteers join into.

## Implementation order

Single CC session, single commit. Order:

1. Verify preconditions (count query + cadence breakdown).
2. Write + apply migration 044. Run verification query.
3. Copy `docs/MHS Horseshoe Color.jpg` → `public/brand/mhs-horseshoe.jpg`.
4. Edit `BOOSTER_LINKS` constant: rename Join → "Join the Club!", remove Board.
5. Build `app/boosters/committees/page.tsx` with inline `CadenceBadge` and `CommitteeCard` components.
6. Build `app/boosters/committees/[catchall]/page.tsx` (unconditional `notFound()`).
7. Add `Committee` type to `lib/types.ts` if not present (id, name, description, cadence, contact_email, sort_order).
8. Verify locally: header dropdown order, mobile drawer accordion, all three card sections render with verbatim copy.
9. Run `npm run typecheck`, `npm run lint`.
10. Verify Vercel preview: all 19 acceptance criteria.
11. Commit + push. Suggested message: `Build /boosters/committees + nav cleanup (Join the Club! rename, Board removal)`.

Estimated effort: one evening.

## Out of scope for this commit

- `/boosters/volunteer` page (still 404 after this ships; that's the natural next page)
- Cadence filter toggle on `/boosters/committees` (deferred to Phase 2)
- Chair person rendering on cards (requires populated `chair_board_member_id` data)
- Committee-detail pages (`/boosters/committees/[slug]`) — not in Phase 1 scope
- Removing the `/boosters/board` route file or board grid from `/boosters` landing
- Renaming "Join the Booster Club" CTA labels elsewhere on the site

## First instruction for CC

(Inline in next message — give all instructions at once per Jeremy's preference.)
