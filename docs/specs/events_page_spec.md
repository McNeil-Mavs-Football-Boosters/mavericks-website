# Spec: /events Page

Written 2026-05-25. Builds the new top-level `/events` route.

**Reads with:**
- `content_map_v2.md` — old `/boosters/events` section (being deprecated by this spec)
- `schema.md` — `events` table definition
- `site_pivot.md` — News + Events split rationale

## What this is

A public page at `/events` listing booster club events (parent meetings, banquet, photo shoot, pool party, Meet the Mavs, etc.). Two views: List (default) and Month. Filter pills for Upcoming/Past in List view. Subscribe-to-calendar dropdown that exports/feeds via ICS.

## What this is NOT

- NOT football games. Games live in the `games` table and render on `/schedule`. Don't mix.
- NOT admin CRUD for events. Admin work is Step 7 — events admin page.
- NOT a Day view. Cut from v1; not useful for ~monthly cadence events.
- NOT a search box. Cut from v1 per Jeremy 2026-05-25; volume doesn't warrant it. If event count ever blows past ~50, revisit.

## Deprecates

- `/boosters/events` route — DELETE the route directory (`app/boosters/events/page.tsx` and any sibling files). The booster dropdown link was already removed earlier today.
- `/boosters/events/[slug]` — DELETE. Replaced by `/events/[slug]` below.
- `content_map_v2.md` `/boosters/events` and `/boosters/events/[slug]` sections — replace with reference to this spec.

## Routes

| URL | Purpose |
|---|---|
| `/events` | Default — List view, Upcoming filter |
| `/events?view=month` | Month view, current month |
| `/events?view=month&date=2026-08` | Month view, specific month |
| `/events?filter=past` | List view, Past events (most recent 10) |
| `/events/[slug]` | Individual event detail page |
| `/events.ics` | Public ICS feed of all published events |

View param and filter param are independent.

## Page structure

### Page header
- Navy band (consistent with site pattern), `py-12 md:py-16`
- h1: "Events", white, large (matches `/sponsors`, `/boosters/sponsor` h1 sizing)
- Subhead: "Booster club events, parent meetings, and team gatherings"

### Toolbar (white band below header)

Single row, flex space-between:

- LEFT: List | Month tab buttons
  - Active state: navy text, navy underline (`border-b-2 border-mavs-navy`)
  - Inactive: muted text, no underline, hover navy
  - List is default (no `view` param or `view=list`)
  - Month view URL: `/events?view=month`

- RIGHT: "Subscribe to calendar ▾" button
  - Style: border `border-mavs-navy`, text `text-mavs-navy`, white bg, `px-4 py-2 rounded`
  - Click toggles a popover with 4 options (see "Subscribe popover" below)

Mobile (<640px): toolbar stacks — tabs on top row, Subscribe button on second row right-aligned.

### List view

Active when no `view` param, or `view=list`.

**Filter pills row** above the list:
- "Upcoming" (default, active when no `filter` param)
- "Past" (active when `filter=past`)
- Pills are clickable; toggling rewrites URL.
- Active pill: `bg-mavs-navy text-white`. Inactive: `bg-white border border-mavs-navy/30 text-mavs-navy hover:bg-mavs-navy/5`.

**Upcoming list:**
- Query: `SELECT * FROM events WHERE status='published' AND starts_at >= now() ORDER BY starts_at ASC`
- No LIMIT (we won't have hundreds)
- Group by month with a section subheading ("September 2026", "October 2026") rendered whenever the current row's month differs from the previous row's month
- Each row layout (flex):
  - **Date block** (left, ~120px wide): 3-letter weekday uppercase ("THU"), large day number ("10"), small muted month abbreviation below. Vertical stack, centered text.
  - **Body** (middle, flex-1): time range ("September 10 @ 5:00 PM – September 12 @ 12:00 PM" or "May 26 @ 7:00 PM" for single-day), event title (h3 bold, navy, clickable to slug), location (bold venue name + address on same line if both fit, else stacked), short description (first ~200 chars of `description`, ellipsized).
  - **Cover image** (right, ~280px wide aspect-video, hidden below `md:`): `cover_image_url` rendered with `object-cover`. Hidden entirely if no image (don't render an empty box).
- Border-bottom between rows (`border-b border-mavs-navy/10`)
- Click anywhere in the body or date block → `/events/[slug]`. Cover image is also clickable.

**Past list:**
- Query: `SELECT * FROM events WHERE status='published' AND starts_at < now() ORDER BY starts_at DESC LIMIT 10`
- Same row layout, reverse chronological
- Below the list, muted small text: "Showing 10 most recent events."

**Empty state (Upcoming):**
- Centered card with light navy border: "No upcoming events. Check back as we plan the 2026-27 season."
- Below: "Want to host an event? Email mcneilfootballboosters@gmail.com" (using the gmail until aliases ship — see followups.md).

**Empty state (Past):**
- Centered card: "No past events recorded yet."

**Pagination:** none Phase 1.

### Month view

Active when `?view=month`.

- **Header row** above the grid:
  - LEFT: prev chevron `◀`, current month/year h2 ("June 2026"), next chevron `▶`. Chevrons are `<Link>` to `?view=month&date=YYYY-MM` — server-side navigation is fine here.
  - RIGHT: "Today" button (border, navy text). Hidden when the displayed month equals current month. Click → `?view=month` (drops the date param, falls back to current month).
- **Grid:** 7 columns. Top row is day labels (Sun, Mon, Tue, Wed, Thu, Fri, Sat) — muted uppercase. Below: 5 or 6 rows of day cells covering the calendar weeks that intersect the month.
- Each day cell:
  - Day number top-left. Days outside the current month: muted gray text.
  - Today's cell: navy circle (24px) behind the number, white number text.
  - Events on that day: render as chips inside the cell — `bg-mavs-navy text-white text-xs px-2 py-1 rounded truncate`, max 2 visible.
  - If more than 2 events on the day: "+N more" link below the chips, click goes to List view filtered to that month-day (out of scope for v1 — just `/events` is fine).
  - Each chip is clickable → `/events/[slug]`.
- Cell sizing: `min-h-24 md:min-h-32`, square-ish on desktop. Border-collapse style.

**Mobile (<768px):** Month view collapses to a stacked week list:
- Same prev/next/Today header
- For each week with at least one event, render: week range subhead ("June 1 – 7"), then the events for that week in List-view row format (without the cover image).
- Weeks with zero events do not render at all on mobile.
- Suppresses the 7-col grid entirely below `md:`.

**Empty state (Month):** if no events anywhere in the visible month, leave the grid empty on desktop, render "No events in this month." muted card on mobile.

### Event detail page (`/events/[slug]`)

Same shape as the deprecated `/boosters/events/[slug]` from `content_map_v2.md`.

- 404 if slug not found OR `status != 'published'`
- Sections, top to bottom:
  1. Page header (navy band): event title (h1, white), date/time range (subhead), location text (subhead). `py-12 md:py-16`.
  2. Cover image (if present): full-width within `max-w-4xl mx-auto`, `aspect-video object-cover`.
  3. Description body (markdown rendered).
  4. Location card: venue name (bold), address, "Get directions →" link (target=_blank) if `location_url` populated.
  5. Sign-up CTA (only if `signup_url` populated): navy button "Sign Up →" target=_blank.
  6. Bottom: "← Back to all events" `<Link>` to `/events`.
- `export const dynamic = 'force-dynamic'`.

## Subscribe popover

Client component. Triggered by "Subscribe to calendar ▾" button. White card, border-mavs-navy/20, shadow, drops below the button. Z-index above content.

Four rows, each clickable, each with a small icon (lucide-react where possible):

1. **Google Calendar** (icon: Calendar) → opens new tab to `https://calendar.google.com/calendar/r?cid=<url-encoded webcal:// ICS URL>`
2. **Apple / iCal** (icon: Apple or Calendar) → opens `webcal://<host>/events.ics` (the `webcal:` scheme triggers macOS/iOS Calendar.app)
3. **Outlook** (icon: Calendar) → opens new tab to `https://outlook.live.com/calendar/0/addcalendar?url=<url-encoded https:// ICS URL>`
4. **Copy ICS URL** (icon: Copy) → button that copies `https://<host>/events.ics` to clipboard, shows ephemeral toast or inline text "Copied!" for 2s

Close popover on: outside click, Escape key, any option clicked.

**Host:** absolute URL required. Use `process.env.NEXT_PUBLIC_SITE_URL` if set, else derive from request headers via the route handler approach. Don't ship relative URLs in the calendar links — they break.

## ICS feed endpoint

New route: `app/events.ics/route.ts` (Next.js Route Handler).

Response:
- `Content-Type: text/calendar; charset=utf-8`
- `Content-Disposition: inline; filename="mcneil-mavericks-events.ics"`
- `Cache-Control: public, max-age=3600, s-maxage=3600`

Body format (standard iCalendar):

```
BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//McNeil Maverick Football Booster Club//Events//EN
CALSCALE:GREGORIAN
METHOD:PUBLISH
X-WR-CALNAME:McNeil Mavericks Events
X-WR-TIMEZONE:America/Chicago
BEGIN:VEVENT
UID:<event.id>@mcneilmavericks.org
DTSTAMP:<event.updated_at in UTC, format YYYYMMDDTHHMMSSZ>
DTSTART:<event.starts_at in UTC, same format>
DTEND:<event.ends_at in UTC, or starts_at + 1 hour if null>
SUMMARY:<event.title>
DESCRIPTION:<event.description, plain text, escape commas/semicolons/newlines, line-fold at 75 octets>
LOCATION:<event.location>
URL:https://<host>/events/<event.slug>
END:VEVENT
... repeat ...
END:VCALENDAR
```

**Query for the feed:** `status='published'`, `starts_at` within 1 year past or 2 years future, ordered by `starts_at ASC`. Calendar clients handle filtering once subscribed; bounded range keeps feed size sane.

**ICS line folding:** lines over 75 octets MUST be folded with CRLF + single space. Common oversight. Verify with https://icalendar.org/validator.html before shipping.

**Escaping in DESCRIPTION:** commas → `\,`, semicolons → `\;`, newlines → `\n` (literal backslash-n in the file), backslashes → `\\`.

**Library decision:** hand-roll the string. The `ics` npm package is fine but adds ~50KB and abstracts something that's ~40 lines of well-specified format. CC's call — if hand-rolling produces validator errors, fall back to the package.

`export const dynamic = 'force-dynamic'` on the route handler so it doesn't get statically prerendered and stale.

## Schema changes

**None required.** Existing `events` table covers everything:
- `title`, `slug`, `description`, `starts_at`, `ends_at`, `location`, `location_url`, `signup_url`, `cover_image_url`, `status`, `featured`

`featured` column unused in this spec; reserved for future "Featured Event" treatment on homepage.

## Seed data

New migration (next available number — check `db/migrations/` for highest, write `0XX_events_seed.sql` plus `0XX_events_seed_rollback.sql`).

```sql
-- Seed 3 events for /events page initial render and Past/Upcoming testing.
INSERT INTO events (
  title, slug, description, starts_at, ends_at,
  location, location_url, status, featured
) VALUES
(
  'Parent and Athlete Meeting',
  'parent-athlete-meeting-may-2026',
  'Important meeting for parents and athletes covering the 2026-27 season. Topics include summer workouts, fall expectations, and key dates for the upcoming season. Please make every effort to attend.',
  '2026-05-26 19:00:00-05'::timestamptz,
  '2026-05-26 20:30:00-05'::timestamptz,
  'McNeil High School Cafeteria',
  'https://maps.google.com/?q=5720+McNeil+Drive+Austin+TX+78729',
  'published',
  false
),
(
  '2025 Football Banquet',
  'football-banquet-2025',
  'End-of-season celebration honoring the 2025 McNeil Mavericks varsity, JV, and freshman football teams. Awards, video highlights, and dinner.',
  '2025-12-06 18:00:00-06'::timestamptz,
  '2025-12-06 21:00:00-06'::timestamptz,
  'McNeil High School Cafeteria',
  'https://maps.google.com/?q=5720+McNeil+Drive+Austin+TX+78729',
  'published',
  false
),
(
  '2025 Meet the Mavs',
  'meet-the-mavs-2025',
  'Annual season-kickoff event introducing the 2025-26 Mavericks football team to the community. Player introductions, coach remarks, and food.',
  '2025-08-15 18:00:00-05'::timestamptz,
  '2025-08-15 20:00:00-05'::timestamptz,
  'McNeil High School Stadium',
  'https://maps.google.com/?q=5720+McNeil+Drive+Austin+TX+78729',
  'published',
  false
);
```

Time zone offsets explicit (`-05` Central Daylight, `-06` Central Standard). One upcoming, two past — Past filter renders with two rows, demonstrating the reverse-chronological order.

Rollback DELETEs the three rows by slug.

## Acceptance criteria

1. `/events` returns 200 with List view + Upcoming filter by default
2. Parent and Athlete Meeting (May 26 2026) renders in Upcoming list
3. `/events?filter=past` renders 2025 Football Banquet AND 2025 Meet the Mavs, banquet first (reverse chronological)
4. `/events?view=month` shows current month (May 2026) with the parent meeting chip on the 26th
5. `/events?view=month&date=2025-08` shows August 2025 with Meet the Mavs chip on the 15th
6. "Today" button hidden when current month displayed, visible when navigated away
7. Prev/next chevrons in Month view rewrite URL with `date=YYYY-MM` param
8. Subscribe popover opens with 4 options, closes on outside click + Escape
9. "Copy ICS URL" copies absolute `https://<host>/events.ics` to clipboard, shows "Copied!" confirmation
10. `/events.ics` returns 200 with `Content-Type: text/calendar`, contains 3 VEVENT blocks
11. `/events.ics` passes https://icalendar.org/validator.html with zero errors
12. `/events/parent-athlete-meeting-may-2026` renders detail page; `/events/foo` returns 404
13. `/boosters/events` returns 404 (route deleted)
14. `/boosters/events/anything` returns 404 (route deleted)
15. Mobile 375px: List rows hide cover image; Month view collapses to stacked week list
16. `npx tsc --noEmit` clean
17. `npx eslint .` clean

## Implementation notes

- List view and Month view are server components. URL params drive queries; navigation is server-side `<Link>` based.
- `<SubscribeCalendarButton>` is a client component (popover state + clipboard).
- ICS endpoint at `app/events.ics/route.ts` is a Route Handler, not a page. `export const dynamic = 'force-dynamic'`. Cache headers as specified.
- Date formatting: prefer `date-fns` (already in deps for `/schedule` pages — verify before adding). `format(d, 'MMMM d @ h:mm a')` for list view headlines. `format(d, 'EEE')` for the 3-letter weekday block. Both events on same day at different times → "May 26 @ 7:00 PM – 8:30 PM" (single date prefix).
- Time zone display: events stored as `timestamptz`. Convert to `America/Chicago` for display. Use `date-fns-tz` if needed (verify dep) or accept that server renders in UTC and adjust before format() call.
- Page-header navy band: same `py-12 md:py-16` pattern as `/sponsors`, `/boosters/sponsor`, `/boosters/committees`.
- The deprecated `/boosters/events` route files: delete entirely. No 308 redirect — nothing has ever linked there externally.
- `content_map_v2.md` update: replace the `/boosters/events` and `/boosters/events/[slug]` sections with a brief note pointing to this spec and a new `/events` + `/events/[slug]` + `/events.ics` entry in the route map table.

## Open questions for Jeremy

1. **Event chip color in Month view.** My pick: navy (`bg-mavs-navy text-white`) for all events — matches site palette, single category for now. If categories ever get added to the schema, revisit. Confirm.
2. **Past events visible count.** Spec says 10. Confirm or push to 20.
3. **ICS feed range.** 1 year past + 2 years future. Confirm.

## Followups (not in this spec)

- Admin CRUD for events lives in Step 7 (already on the build plan).
- "Add to my calendar" single-event ICS download on each detail page — Phase 2.
- Recurring events (booster board meetings, etc.) — Phase 2, needs RRULE handling.
- Year-grouped archive at `/events/archive` if 10-most-recent becomes insufficient — Phase 2.
- Search box (cut from v1) — only revisit if event count exceeds ~50.
