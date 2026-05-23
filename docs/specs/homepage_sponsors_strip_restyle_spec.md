# Spec: Homepage Sponsors Strip Restyle

Written 2026-05-22. Small follow-up to today's two earlier ships. Restyles the homepage Sponsors strip so featured (MVP-tier) sponsors get a dedicated top row and everyone else fits on a second row. Replaces the small-caps left-aligned heading with a centered black thank-you. Moves the "See all sponsors" link below the logos.

## As-shipped (2026-05-22, commits `827cf0e` + `ed002da`)

Frontend (`827cf0e`) — only `app/page.tsx` touched. Replaced the single-row strip block (lines ~254–297 pre-edit) with the two-row layout per spec. `SponsorTile` type and `HomeData` type extended with `tier_id` / `mvpTierId` fields; `loadHome()` gained a fourth `Promise.all` entry that fetches the MVP tier id from `sponsorship_tiers` (`maybeSingle()` keyed on `year + active + name='MVP'`). New inline `SponsorStripLogo` component handles `logo_url == null` by returning `null`. No new component file; matches the inline pattern used by SponsorCard in `app/sponsors/page.tsx`.

Data cleanup (`ed002da`, migration 044) — ran after frontend verified on staging. Pre-grep across `app/`, `lib/`, `components/` confirmed no live code path reads `sponsors.featured` (only references were `featured_image_url` on `news_posts` and an unrelated `featured: boolean` on the `Game` interface in `lib/types.ts`). UPDATE set `featured = false` for all 7 rows at `year = '2025-26'`. Column kept in schema for future admin-driven badging.

No deviations from spec text. Sunflower Bank readability at `max-w-[160px] max-h-12` (~160×17.5 px) deferred to visual judgment on staging — flagged for Jeremy. Acceptance criterion #9 (Lighthouse a11y ≥ 90) not yet run from a browser.

**Context for CC:** the carousel sponsor_spotlight tiles were already reverted in a separate commit earlier today (Jeremy's call after seeing how logos read against photos). This spec does NOT touch the carousel. Pool A / Pool B rotation logic stays in place — it degrades gracefully to single-pool when Pool B is empty.

**Reads with:**
- `sponsors_page_spec.md` — the `/sponsors` page that opened earlier today; same tier-prominence philosophy
- `commit_sponsors_seed_and_carousel_spec_v2.md` — defines the existing strip implementation that this spec restyles

## What this is

A restyle of the homepage section that shows the sponsor logos near the bottom of `/`. Plus a small data cleanup query to reset `featured` flags now that they're no longer driving carousel inclusion.

## What this is NOT

- Not new sponsor data. Same 7 sponsors as the seed.
- Not a schema change. `featured` boolean already exists.
- Not a carousel change. CC already removed the sponsor_spotlight tiles in a separate commit today.
- Not a `/sponsors` page change. Separate evaluation later if Sunflower's aspect ratio causes problems there too.

## The featured-flag carve-out

Approach: split the strip into two rows by **tier name**, not by the `featured` flag.

- Row 1: sponsors at the MVP tier (top tier). Rudy's today.
- Row 2: all other active sponsors at lower tiers. Six sponsors today.

Why tier-based and not flag-based: the `featured` boolean was originally used to decide which sponsors appeared in the carousel. With the carousel revert, it has no functional purpose anymore — but leaving it tied to strip placement creates a weird coupling. Tier names are stable, sponsor-paid, and aligned with `/sponsors` page rendering. One source of truth.

The `featured` column stays in the schema (future-proofing for things like "featured sponsor of the month" or sales page badges). Its values get reset to a clean state in the same migration that runs the restyle, see below.

## Data cleanup

The original seed set three sponsors to `featured = true` (Rudy's, AutoNation, Sunflower) so they'd appear in the carousel. Since the carousel use is gone, reset the flags:

```sql
-- Reset featured flags. Carousel no longer uses this column.
-- Future: admin may set sponsors.featured = true for cases like "featured this month."
update sponsors
set featured = false
where year = '2025-26';
```

No commit-breaking dependencies — at the time this migration runs, nothing reads `featured` anymore.

**CC: confirm before applying that no live code path still reads `sponsors.featured`.** Grep the repo. If the homepage strip or any other page still filters on this column, stop and tell Jeremy — the restyle work below needs to land first, then the cleanup.

This migration runs AFTER the frontend restyle commit, not in the same commit. Order:
1. Frontend commit: restyle the strip (this spec, frontend section).
2. Verify on staging that the strip renders correctly and nothing reads `featured`.
3. Data cleanup migration (the SQL above).

This sequencing is safe even if order slips — running the SQL first just makes the carousel-removed state stricter; it doesn't break the restyle.

## Frontend changes

### The strip section markup

Current state per `commit_sponsors_seed_and_carousel_spec_v2.md`:
- Small-caps heading "OUR 2025-26 SPONSORS" left-aligned
- "See all sponsors →" link inline with heading, right-aligned on desktop
- Single flex row of 7 logos at `h-10 md:h-12`

New state:

```
<section class="container mx-auto px-4 py-12 md:py-16">

  {/* Heading: centered, black, mixed-case */}
  <h2 class="text-2xl md:text-3xl font-bold text-mavs-navy text-center mb-10">
    Thank You to Our 2025-2026 Sponsors!
  </h2>

  {/* Row 1: top-tier (MVP) sponsors only */}
  {topTierSponsors.length > 0 && (
    <div class="flex flex-wrap items-center justify-center gap-12 mb-8">
      {topTierSponsors.map(s => <SponsorStripLogo sponsor={s} sizeClass="max-w-[220px] max-h-20" />)}
    </div>
  )}

  {/* Row 2: everyone else */}
  {otherSponsors.length > 0 && (
    <div class="flex flex-wrap items-center justify-center gap-8 md:gap-12">
      {otherSponsors.map(s => <SponsorStripLogo sponsor={s} sizeClass="max-w-[160px] max-h-12" />)}
    </div>
  )}

  {/* See all link: centered, below logos */}
  <div class="text-center mt-10">
    <a href="/sponsors"
       class="text-mavs-navy font-semibold uppercase tracking-wide text-sm hover:text-mavs-green transition-colors">
      See All Sponsors →
    </a>
  </div>

</section>
```

### Data partition

In the page data fetch, partition sponsors by tier name:

```
// Pseudo-code, match the codebase's existing pattern
const allSponsors = await fetchActiveSponsorsForYear(currentYear);
const topTierSponsors = allSponsors.filter(s => s.tier_name === 'MVP');
const otherSponsors  = allSponsors.filter(s => s.tier_name !== 'MVP');
```

If the existing query doesn't already join `sponsorship_tiers` to get `tier_name`, add that join. Or do the partition by `tier_id` matching the MVP tier id fetched separately. Use whichever pattern matches the codebase.

### SponsorStripLogo component

```
function SponsorStripLogo({ sponsor, sizeClass }: { sponsor: Sponsor; sizeClass: string }) {
  const logoSrc = publicStorageUrl(sponsor.logo_url, 'sponsor-logos');
  const inner = (
    <img src={logoSrc}
         alt={sponsor.name}
         class={`${sizeClass} w-auto h-auto object-contain`} />
  );
  return sponsor.website_url ? (
    <a href={sponsor.website_url} target="_blank" rel="noopener noreferrer"
       class="hover:opacity-80 transition-opacity"
       aria-label={`Visit ${sponsor.name}`}>
      {inner}
    </a>
  ) : inner;
}
```

Reuse the existing strip logo component if there's already a SponsorLogo or similar — just thread the `sizeClass` prop through. Don't create a parallel component.

### Sizing rationale

**Row 1 (MVP):** `max-w-[220px] max-h-20` (220px × 80px bounding box). Rudy's logo at 508×262 hits the height cap, renders ~155×80. Substantial enough to read as "featured."

**Row 2 (others):** `max-w-[160px] max-h-12` (160px × 48px bounding box).
- AutoNation 3167×1000 → 152×48 (hits height)
- Sunflower 384×42 → 160×17.5 (hits width)
- LUV Braces 781×262 → 143×48 (hits height)
- Dave's 268×118 → 109×48 (hits height)
- TKO 378×348 → 52×48 (hits height)
- Laurie Flood 800×218 → 160×44 (hits width, very close to height)

Sunflower will be short (17.5px tall). That's the trade with extreme aspect ratios. If it's truly unreadable in practice, we revisit either (a) cropping the Sunflower logo, (b) per-sponsor sizing overrides, or (c) bumping the width cap up. Inspect on staging before re-deciding.

### Visual rhythm

Row 1 logo larger, row 2 logos smaller. Visible whitespace between rows (`mb-8` between rows). Whitespace before the "See all" link (`mt-10`). The whole section breathes more vertically than the old single-line strip — that's intentional. This is meant to read like a thank-you page section, not a tight footer band.

### Heading typography choices

"Thank You to Our 2025-2026 Sponsors!"

- Mixed case, not small caps. Reads warmer.
- `text-2xl md:text-3xl` — comparable to other section headings on the homepage.
- `font-bold text-mavs-navy` — brand color, weight matches site headings.
- Exclamation point at the end — yes, keep it. It's a thank-you, not a label.
- `text-center` — centered to anchor both rows below it.

## Acceptance criteria

1. Homepage `/` renders the new strip section with the centered "Thank You to Our 2025-2026 Sponsors!" heading in mavs-navy.
2. Rudy's BBQ appears alone on row 1, larger than the other logos.
3. AutoNation, Sunflower Bank, LUV Braces, Dave's Ultimate Automotive, TKO Heating and Air, Laurie Flood Realtor all appear on row 2 at uniform smaller height (except Sunflower which hits the width cap).
4. Sunflower Bank's logo, while short, is still readable as the Sunflower Bank logo (not a thin line of pixels).
5. "See All Sponsors →" link centered below the logos, links to `/sponsors`.
6. Each logo is clickable to its sponsor's website, opens in new tab.
7. Mobile: row 1 stacks fine (only one logo today), row 2 wraps to two rows if needed.
8. No console errors.
9. Lighthouse a11y ≥ 90.

After the frontend ships and verifies, run the data cleanup SQL and verify:
```sql
select count(*) from sponsors where year = '2025-26' and featured = true;
-- expect: 0
```

## Rollback

Revert the commit. Strip returns to the previous single-row layout with the small-caps heading. No data changes are touched by the frontend commit, so revert is clean.

The data cleanup SQL has no revert beyond a manual `update` if you really wanted three sponsors flagged again — but there's no functional reason to roll that back.

## Decisions confirmed by Jeremy 2026-05-22

1. **Revert sponsor spotlights in carousel:** done in earlier commit. No work for this spec.
2. **Heading:** "Thank You to Our 2025-2026 Sponsors!" — black text (mavs-navy), centered, mixed case.
3. **"See all sponsors" link:** moves below logos, centered.
4. **Featured carve-out:** top-tier sponsor (Rudy's, MVP) gets its own row, larger logo. Other sponsors below at smaller uniform width.
5. **Featured flag cleanup:** reset to false for all 2025-26 sponsors since carousel no longer uses it.

## What changes in other docs after this ships

- `commit_sponsors_seed_and_carousel_spec_v2.md` — add a one-line note at the top: "**Updated 2026-05-22 (afternoon):** sponsor_spotlight carousel tiles reverted; homepage strip restyled per `homepage_sponsors_strip_restyle_spec.md`."
- `content_map_v2.md` `/` section #6 — refresh to describe the two-row strip layout.
- `followups.md` — close any line items about strip styling. If the Sunflower aspect ratio issue appears on `/sponsors` too, file a new followup.
