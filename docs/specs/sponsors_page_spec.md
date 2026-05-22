# Spec: Build `/sponsors` Page

Written 2026-05-22. Builds the missing `/sponsors` public route. Today the route 404s; the homepage strip heading link, the footer "Sponsors" link, and the new `/sponsors` footer CTA card all point at a page that doesn't exist.

## As-shipped (2026-05-22, commit `5ed2b4d`)

Three deviations applied during build:

1. **Footer CTA card button is `bg-mavs-green text-white`, not the spec's `bg-mavs-green text-mavs-navy`.** Post-brand-pass `mavs-green` is `#1E541E` (darker per the McNeil HS style guide); navy text on that is ~1.3:1 contrast — fails WCAG AA and would have failed acceptance criterion #9 (Lighthouse a11y ≥ 90). White text on the same green clears AA at the large-bold size used.
2. **Internal `/boosters/sponsor` CTAs use `<Link>` from `next/link`, not raw `<a href>`.** Matches the rest of the site's internal nav (prefetch, no full-page reload). External `website_url` links stay as `<a target="_blank">`.
3. **A `/sponsors/[catchall]/page.tsx` companion route added** (unconditional `notFound()`). Sibling routes `/coaches` and `/resources` both have this — `/sponsors/foo` returns 404 instead of falling through.

`Sponsor` and `SponsorshipTier` types live inline in `app/sponsors/page.tsx` rather than in `lib/types.ts` (page-specific shape, no other consumer). Acceptance criteria 1–8, 10 verified against staging via curl; criterion 9 (Lighthouse a11y) not yet run from a browser.

**Reads with:**
- `content_map_v2.md` lines 290–330 (`/sponsors` section) — source of truth for page structure
- `commit_sponsors_seed_and_carousel_spec_v2.md` — defines the sponsor data shape, `publicStorageUrl` helper signature, and link conventions
- `schema.md` — `sponsors` and `sponsorship_tiers` table definitions

## What this is

A new file: `app/sponsors/page.tsx` (server component, no client interactivity needed). Reads from `sponsors` and `sponsorship_tiers` tables, groups sponsors by tier, renders each tier as its own section, largest tier first.

## What this is NOT

- Not an admin CRUD for sponsors. Editing happens via Studio. Admin work is Phase 2.
- Not a redesign of any sponsor data shape. The seed in migration 041 is the data this page renders.
- Not `/boosters/sponsor` (sales page with the inquiry form). That's a separate future commit.
- Not a redesign of the homepage sponsors strip or hero carousel. Those shipped 2026-05-22.

## Data fetch

Single page-level fetch. Use the same Supabase server client pattern as other public routes (see Note on security below).

```
const { data: tiers } = await supabase
  .from('sponsorship_tiers')
  .select('id, name, price_cents, sort_order, year')
  .eq('year', currentYear)
  .eq('active', true)
  .order('sort_order', { ascending: true });

const { data: sponsors } = await supabase
  .from('sponsors')
  .select('id, name, logo_url, website_url, tier_id, sort_order, year')
  .eq('year', currentYear)
  .eq('active', true)
  .order('sort_order', { ascending: true });
```

`currentYear` is read from `site_settings.current_year` — same as the homepage. If your existing pages have a `getSiteSettings()` helper, use it.

After fetch, group sponsors by `tier_id` in JavaScript:

```
const sponsorsByTier = new Map<string, Sponsor[]>();
const unaffiliatedSponsors: Sponsor[] = [];

for (const s of sponsors) {
  if (s.tier_id == null) {
    unaffiliatedSponsors.push(s);
  } else {
    if (!sponsorsByTier.has(s.tier_id)) sponsorsByTier.set(s.tier_id, []);
    sponsorsByTier.get(s.tier_id)!.push(s);
  }
}
```

## Page structure

Top to bottom. Follow existing public route conventions for outer layout (header/footer come from the shared layout, not this page).

### 1. Page header

```
<section class="container mx-auto px-4 py-12 md:py-16">
  <div class="flex flex-col md:flex-row md:items-end md:justify-between gap-4">
    <div>
      <h1 class="text-4xl md:text-5xl font-black uppercase tracking-tight text-mavs-navy">
        Our Sponsors
      </h1>
      <div class="h-1 w-20 bg-mavs-green mt-3"></div>
      <p class="text-lg text-gray-600 mt-3">{currentYear} Season</p>
    </div>
    <a href="/boosters/sponsor"
       class="inline-block bg-mavs-navy text-white px-6 py-3 font-bold uppercase hover:bg-mavs-navy/90 transition-colors">
      Become a Sponsor →
    </a>
  </div>
</section>
```

Match the wordmark/heading style of other public pages (`text-mavs-navy`, Lato Black per existing header). The "Become a Sponsor" button uses the same styling as the hero CTA buttons — reuse a shared button class or component if it exists. The thin green bar under the title (h-1 w-20 bg-mavs-green) is a deliberate brand accent — keep it.

### 2. Tier sections

For each row in `tiers` (already sorted by sort_order):
- Look up `sponsorsByTier.get(tier.id)`. If undefined or empty: skip this tier entirely. Don't render an empty heading.
- Otherwise render a tier section.

Tier section markup:

```
<section class="container mx-auto px-4 py-10 md:py-14 border-t-2 border-mavs-green/30">
  <h2 class="text-2xl md:text-3xl font-bold uppercase tracking-tight text-mavs-navy mb-2">
    {tier.name} Sponsors
  </h2>
  <div class="h-0.5 w-12 bg-mavs-green mb-8"></div>
  <div class="flex flex-wrap items-center justify-center gap-8 md:gap-12">
    {tierSponsors.map(sponsor => <SponsorCard sponsor={sponsor} maxHeight={tierMaxHeight(tier)} />)}
  </div>
</section>
```

The top border uses `border-mavs-green/30` (semi-transparent green) instead of `border-gray-200` for a subtle brand accent between tiers. The small green underline (h-0.5 w-12 bg-mavs-green) under each tier heading mirrors the page title treatment for visual rhythm.

**Tier-to-logo-height mapping** (matches content_map_v2 line 314 "smaller logo sizes as tier decreases"):

| Tier | Logo max height |
|---|---|
| MVP | 240px (`h-60`) |
| Diamond | 192px (`h-48`) |
| Platinum | 160px (`h-40`) |
| Gold | 128px (`h-32`) |
| Blue | 96px (`h-24`) |

Map by tier name with a switch or lookup object. If a future tier name doesn't match, fall back to `h-32` (Gold default) and don't crash.

### 3. SponsorCard component (inline or extracted)

```
function SponsorCard({ sponsor, maxHeight }: { sponsor: Sponsor; maxHeight: string }) {
  const logoSrc = publicStorageUrl(sponsor.logo_url, 'sponsor-logos');
  const inner = (
    <img src={logoSrc}
         alt={sponsor.name}
         class={`${maxHeight} w-auto object-contain`} />
  );
  return (
    <div class="flex items-center justify-center">
      {sponsor.website_url ? (
        <a href={sponsor.website_url} target="_blank" rel="noopener noreferrer"
           class="hover:opacity-80 transition-opacity"
           aria-label={`Visit ${sponsor.name}`}>
          {inner}
        </a>
      ) : (
        inner
      )}
    </div>
  );
}
```

Notes:
- `object-contain` keeps logo aspect ratio inside the bounded height
- No sponsor name text below the logo (Jeremy's call 2026-05-22; logos carry their own brand recognition, name text adds visual noise)
- `alt` text on the logo image and `aria-label` on the link wrapper preserve accessibility
- Only the logo is the link; nothing else clickable in the card

### 4. "Other Supporters" section

If `unaffiliatedSponsors.length > 0`, render after the last tier section:

```
<section class="container mx-auto px-4 py-10 md:py-14 border-t-2 border-mavs-green/30">
  <h2 class="text-2xl md:text-3xl font-bold uppercase tracking-tight text-mavs-navy mb-2">
    Other Supporters
  </h2>
  <div class="h-0.5 w-12 bg-mavs-green mb-8"></div>
  <div class="flex flex-wrap items-center justify-center gap-8 md:gap-12">
    {unaffiliatedSponsors.map(s => <SponsorCard sponsor={s} maxHeight="h-24" />)}
  </div>
</section>
```

Same `h-24` size as Blue tier. With current seed: this section is empty and hidden. Future sponsors with `tier_id IS NULL` will land here.

### 5. Footer CTA card

Last section, before the global footer.

```
<section class="container mx-auto px-4 py-12 md:py-16">
  <div class="bg-mavs-navy text-white rounded-lg p-8 md:p-12 text-center relative overflow-hidden">
    <div class="absolute top-0 left-0 right-0 h-1 bg-mavs-green"></div>
    <h2 class="text-2xl md:text-3xl font-black uppercase tracking-tight">
      Want to Join Them in 2026-27?
    </h2>
    <p class="text-lg text-white/90 mt-4 max-w-2xl mx-auto">
      Five sponsorship tiers. Each one supports McNeil football and puts your business in front of Mavs families all season long.
    </p>
    <a href="/boosters/sponsor"
       class="inline-block mt-8 bg-mavs-green text-mavs-navy px-8 py-3 font-bold uppercase hover:bg-mavs-green/90 transition-colors">
      See Sponsorship Options
    </a>
  </div>
</section>
```

The top green stripe and the green CTA button anchor this card visually. The headline ("Want to Join Them in 2026-27?") leans into the recruitment angle — this page thanks last year's sponsors AND sells next year. Reuse a CardCTA or PromoCard component if one already exists in the codebase; the styling above is a fallback if no such component exists.

## Empty state

If `sponsors.length === 0` after fetch:

```
<section class="container mx-auto px-4 py-16 md:py-24 text-center">
  <h1 class="text-4xl md:text-5xl font-black uppercase tracking-tight text-mavs-navy">
    Our Sponsors
  </h1>
  <div class="h-1 w-20 bg-mavs-green mx-auto mt-4"></div>
  <p class="text-lg text-gray-600 mt-6 max-w-xl mx-auto">
    We're building our {currentYear} sponsor program. Be the first to put your business in front of every Mavs family this season.
  </p>
  <a href="/boosters/sponsor"
     class="inline-block mt-8 bg-mavs-navy text-white px-8 py-3 font-bold uppercase hover:bg-mavs-navy/90 transition-colors">
    Become Our First Sponsor →
  </a>
</section>
```

No tier scaffolding, no footer CTA card. Just the empty pitch. Don't render the page header section separately above this; this IS the page.

## Error / no-data handling

If the fetch returns an error or undefined data (network issue, Supabase down), render the empty state above. Don't show a stack trace to users. Log the error server-side.

## Note on security

The current security followup in `followups.md` says public pages use `createServerClient` (service role) which bypasses RLS, and that should be switched to anon client before admin pages land. This page should follow whatever the other public pages do today — don't introduce a new pattern here. If other public routes already use the anon client, this one does too. Match the existing convention.

## Accessibility

- Page title in browser tab: `Our Sponsors | McNeil Mavericks Football` — set via `metadata` export.
- All logos have `alt` text equal to sponsor name.
- All link wrappers have `aria-label` so the link target is clear.
- Headings are semantic: one `<h1>` (page title), `<h2>` per tier section.
- Color contrast: navy on white, gray-600 on white, white on navy — all WCAG AA at the font sizes used.

## Acceptance criteria

1. `/sponsors` returns 200, not 404.
2. With current seed (1 MVP Rudy's + 6 Gold + 0 Diamond/Platinum/Blue): MVP section shows Rudy's logo at h-60, Gold section shows 6 logos at h-32, Diamond/Platinum/Blue sections do not render (no empty headings).
3. Each logo is a working link to the sponsor's `website_url`, opens in new tab.
4. "Become a Sponsor →" button in the page header links to `/boosters/sponsor` (which still 404s — that's fine, separate commit).
5. Footer CTA card "See Sponsorship Options" button also links to `/boosters/sponsor`.
6. Page heading reads "Our Sponsors" with "2025-26 Season" subhead, year pulled from `site_settings.current_year`.
7. Empty state renders correctly when sponsors table has zero rows for the current year (verify by querying with a fake year in dev, not by deleting data).
8. Mobile: logos wrap, page header stacks button below title. No horizontal scroll.
9. Lighthouse a11y ≥ 90.
10. No console errors.

## Verification queries before declaring done

These run against the staging DB after the page deploys:

```sql
-- Confirm what the page should display
select s.name, t.name as tier, s.featured
from sponsors s
left join sponsorship_tiers t on t.id = s.tier_id
where s.year = '2025-26' and s.active = true
order by t.sort_order, s.sort_order;
```

Expect: Rudy's at MVP, then 6 sponsors at Gold (AutoNation, Sunflower, LUV Braces, Dave's, TKO, Laurie Flood).

Visit the staging URL `/sponsors` and confirm:
- Rudy's logo appears large in MVP section
- 6 Gold logos appear in Gold section
- No Diamond/Platinum/Blue section headings render
- All logos clickable
- Become a Sponsor buttons present in two places

## Rollback

Revert the commit. The new route disappears, `/sponsors` returns to 404. No data changes — this commit doesn't touch the DB.

## Decisions confirmed by Jeremy 2026-05-22

1. **Logo size scale:** 240/192/160/128/96px for MVP/Diamond/Platinum/Gold/Blue. Uniform within tier, larger tier = larger logo. "Give people value for what they paid."
2. **Sponsor name below logo:** NO. Logos carry their own brand recognition. Schema unchanged so a future admin can re-enable per-row if wanted.
3. **Footer CTA copy:** "Want to Join Them in 2026-27?" headline with recruitment-angle body copy. Recruitment is the page's secondary purpose.
4. **Subhead format:** "2025-26 Season" — last year's season prominent so 2026-27 prospects see the thank-you context.
5. **Brand colors:** McNeil navy (text-mavs-navy) for primary text and the page-header CTA button. McNeil green (mavs-green) used as accent: title underlines, tier section dividers (semi-transparent), footer card top stripe, footer card button background. Subtle, not loud.

## What changes in other docs after this ships

- `followups.md` — close the "/sponsors page doesn't exist" item from CC's flag in today's recap.
- No spec doc updates needed. The `/sponsors` section in `content_map_v2.md` accurately described the page; this spec just turns it into implementation detail.
