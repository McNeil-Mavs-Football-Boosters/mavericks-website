# Spec: Sponsors Seed + Carousel Two-Pool Rotation

Written 2026-05-22. Updated 2026-05-22 to use the existing `sponsor-logos` bucket instead of a new `site-images/sponsors/` folder. Four changes shipped together as one commit:

## As-shipped (2026-05-22, commit `732209c`)

Three deviations from the spec text below, made during implementation:

1. **Migration number renumbered to `041`** (spec assumed `039`). `039_update_coach_wallin.sql` and `040_fix_freshmen_pdf_path.sql` shipped on 2026-05-19 in the Print View PDFs work, so the next sequential slot was 041. Rollback at `db/migrations/041_rollback.sql`.
2. **`sponsorship_tiers` year relabeled in the same migration.** Preflight found 5 tier rows still stamped `2026-27` — migration 030's football-year split (2026-27 → 2025-26 on rosters/practice/coaches/games) missed `sponsorship_tiers`. Per `content_map_v2.md`, the `/sponsors` and homepage sponsor queries read by `current_year` (= 2025-26), so the `tier_id` lookups in this seed would have hit NULL. Migration 041 prefixes the inserts with `update sponsorship_tiers set year='2025-26' where year='2026-27';`, which is the same hygiene fix migration 030 already applied to the four other football-stamped tables. Rollback re-labels back to `2026-27`.
3. **`/sponsors` page does not exist yet.** The spec assumed the page was already built per `content_map_v2.md`, but `app/sponsors/` was never created (Step 5 still pending in `docs/CLAUDE.md`). No code changes were made to add it — the spec explicitly says "/sponsors page itself is unchanged." All in-app links to `/sponsors` (header, mobile nav, footer, homepage "See all sponsors →") 404 today; this is unchanged from the pre-commit state. Building the route is tracked as a Step 5 follow-up. The "Become a Sponsor" CTA in the carousel similarly links to `/boosters/sponsor`, also a 404 today, matching the existing `/boosters/donate` and `/boosters/volunteer` CTA-target pattern in the previous carousel.

Everything else shipped as specced. Acceptance criteria 1–8 verified against the staging URL on commit. Criterion 9 (Lighthouse a11y ≥ 90) not yet run.

1. **Seed migration**: 7 sponsors for `2025-26` (1 placeholder MVP + 6 last-year Golds), 1 new "Become a Sponsor" headline_cta tile, 3 sponsor_spotlight tiles for the featured sponsors.
2. **HeroCarousel JS change**: foreground rotation splits tiles into two pools (`headline_cta` and `sponsor_spotlight`) and alternates between them every tick.
3. **Helper change for cross-bucket reads**: the carousel currently reads from `site-images` via `publicStorageUrl(path)`. Sponsor logos live in `sponsor-logos`. A small helper update lets the sponsor_spotlight tile read from a different bucket.
4. **Homepage sponsors strip restyle**: dial down the existing strip so it reads as a quiet thank-you band, not a marketing section.

`/sponsors` page itself is unchanged — the existing implementation per `content_map_v2.md` renders correctly with the seeded data.

**Reads with:**
- `commit_homepage_hero_carousel_spec.md` — the carousel this commit modifies. Shipped 2026-05-19 as migrations 036+037.
- `schema.md` — `sponsors` table definition (uses existing `featured boolean` column).
- `content_map_v2.md` — `/` and `/sponsors` page specs (unchanged by this commit).

## What this is NOT

- Not the real 2026-27 sponsor program. These are last year's sponsors plus a placeholder MVP, displayed as a 2025-26 thank-you. Kendra refines for 2026-27 at the June 2 board meeting.
- Not admin CRUD for sponsors. Editing happens via Studio or future admin work.
- Not a redesign of `/sponsors` page. Existing tier-grouped layout is correct.
- Not a redesign of the hero carousel. Only the foreground rotation function changes.

## Sponsor data

Display names, URLs, tier, and featured-in-carousel status, all for `year = '2025-26'`:

| # | Display name | Tier | Website | Featured in carousel |
|---|---|---|---|---|
| 1 | Rudy's BBQ | MVP | https://rudysbbq.com | YES (placeholder MVP) |
| 2 | AutoNation Chevrolet West Austin | Gold | https://www.autonationchevroletwestaustin.com | YES |
| 3 | Sunflower Bank | Gold | https://www.sunflowerbank.com | YES |
| 4 | LUV Braces | Gold | https://luvbraces.com | no |
| 5 | Dave's Ultimate Automotive | Gold | https://davesultimateautomotive.com | no |
| 6 | TKO Heating and Air | Gold | https://www.tkomechanical.com | no |
| 7 | Laurie Flood, Realtor | Gold | https://austintexasbestrealestate.com | no |

URL normalization rules used above: keep `https://`, keep `www.` when the sponsor's canonical uses it (AutoNation, Sunflower, TKO) and omit when they don't (Rudy's, LUV Braces, Dave's, Laurie Flood), strip trailing slashes.

**Featured set rationale:** Rudy's gets MVP airtime. AutoNation and Sunflower are the two most recognizable Gold names — strongest visual impact for the carousel. Other 4 still appear on the homepage strip and the `/sponsors` page.

## Logo files

Jeremy uploads logos to Supabase Storage, bucket `sponsor-logos` (existing bucket, defined in `schema.md` line 928). No folder nesting — files at the bucket root.

Exact filenames required:

```
rudys-bbq.png
autonation-chevrolet-west-austin.png
sunflower-bank.png
luv-braces.png
daves-ultimate-automotive.png
tko-heating-and-air.png
laurie-flood-realtor.png
```

Bucket is public-read per existing storage policies. Public URLs follow:
`https://rgdoolafpvhtsdpxbqvj.supabase.co/storage/v1/object/public/sponsor-logos/{filename}`

**Bucket constraints (per `schema.md`):** 2 MB per file, allowed types `image/png`, `image/jpeg`, `image/svg+xml`, `image/webp`. Logos that exceed 2 MB need compression before upload — most sponsor logos are well under this limit, but flag if any fail.

**CC must verify all 7 files exist in the bucket before applying the migration.** Query:
```sql
select name from storage.objects
where bucket_id = 'sponsor-logos'
  and name in (
    'rudys-bbq.png',
    'autonation-chevrolet-west-austin.png',
    'sunflower-bank.png',
    'luv-braces.png',
    'daves-ultimate-automotive.png',
    'tko-heating-and-air.png',
    'laurie-flood-realtor.png'
  )
order by name;
```
Expect exactly 7 rows. If any missing, stop and tell Jeremy which.

## Payload schema change: `sponsor_spotlight` tiles

The carousel spec defined `sponsor_spotlight.payload` with `sponsor_name`, `logo_storage_path`, and optional `tagline`. This commit:

1. Adds an optional `website_url` field so the carousel logo can be a clickable link.
2. Adds a `logo_bucket` field so the renderer knows which Storage bucket the path is in. Default behavior when omitted: read from `site-images` (existing assumption). When present and set to `sponsor-logos`, read from there instead.

Updated shape:
```json
{
  "sponsor_name": "Rudy's BBQ",
  "logo_bucket": "sponsor-logos",
  "logo_storage_path": "rudys-bbq.png",
  "tagline": null,
  "website_url": "https://rudysbbq.com"
}
```

- `sponsor_name` required (still)
- `logo_storage_path` required (still). Note: file path within the bucket, no `bucket/` prefix.
- `logo_bucket` optional, defaults to `site-images` when omitted. Migration 039 sets it to `sponsor-logos` on every sponsor_spotlight tile it inserts.
- `tagline` optional, can be null or omitted
- `website_url` optional, can be null or omitted

No DB column changes — payload is `jsonb`, the new fields just appear in the JSON.

## Migration

`db/migrations/039_sponsors_seed.sql`. CC confirms next sequential number before writing — should be 039 if no migrations have landed since 038.

### Preflight verification (before INSERT)

CC runs these queries first and reports the row counts to Jeremy. Stop and ask if any are unexpected:

```sql
-- expect: 1 row, MVP at price 500000 for 2025-26
select name, price_cents from sponsorship_tiers
where year = '2025-26' and name = 'MVP';

-- expect: 1 row, Gold at price 100000 for 2025-26
select name, price_cents from sponsorship_tiers
where year = '2025-26' and name = 'Gold';

-- expect: 0 rows (no sponsors seeded yet for 2025-26)
select count(*) from sponsors where year = '2025-26';

-- expect: 3 rows (the headline_cta tiles from migration 037)
select count(*) from hero_foreground_tiles
where tile_type = 'headline_cta' and active = true;
```

If any tier missing, stop — sponsorship_tiers seed didn't run for 2025-26 and needs investigation before this migration.
If sponsors > 0, stop — something else has been seeded and Jeremy needs to decide whether to replace or skip.

### Insert sponsors

```sql
-- Capture tier IDs by name for use in inserts
do $$
declare
  mvp_tier uuid;
  gold_tier uuid;
begin
  select id into mvp_tier from sponsorship_tiers where year = '2025-26' and name = 'MVP';
  select id into gold_tier from sponsorship_tiers where year = '2025-26' and name = 'Gold';

  insert into sponsors (name, logo_url, website_url, tier_id, year, featured, sort_order, active) values
    ('Rudy''s BBQ',
     'rudys-bbq.png',
     'https://rudysbbq.com',
     mvp_tier, '2025-26', true, 1, true),
    ('AutoNation Chevrolet West Austin',
     'autonation-chevrolet-west-austin.png',
     'https://www.autonationchevroletwestaustin.com',
     gold_tier, '2025-26', true, 2, true),
    ('Sunflower Bank',
     'sunflower-bank.png',
     'https://www.sunflowerbank.com',
     gold_tier, '2025-26', true, 3, true),
    ('LUV Braces',
     'luv-braces.png',
     'https://luvbraces.com',
     gold_tier, '2025-26', false, 4, true),
    ('Dave''s Ultimate Automotive',
     'daves-ultimate-automotive.png',
     'https://davesultimateautomotive.com',
     gold_tier, '2025-26', false, 5, true),
    ('TKO Heating and Air',
     'tko-heating-and-air.png',
     'https://www.tkomechanical.com',
     gold_tier, '2025-26', false, 6, true),
    ('Laurie Flood, Realtor',
     'laurie-flood-realtor.png',
     'https://austintexasbestrealestate.com',
     gold_tier, '2025-26', false, 7, true);
end $$;
```

**Note on `logo_url`:** stored as a bare filename (no path prefix), reflecting placement at the root of the `sponsor-logos` bucket. The frontend builds the full URL via a helper (see "Helper change" section). CC checks before applying: read any existing sponsor row (any year) and inspect `logo_url`. If existing rows store full URLs, the migration needs reconciling — CC tells Jeremy what it finds and asks how to proceed. If existing rows store relative paths or the table is empty for non-2025-26 years, proceed.

### Insert "Become a Sponsor" headline_cta tile

```sql
insert into hero_foreground_tiles (tile_type, payload, sort_order, active) values
  ('headline_cta',
   '{"headline":"Become a Sponsor","subhead":"Five tiers, real visibility. Reach every Mavs family from August through December.","cta_label":"Sponsorship Info","cta_url":"/boosters/sponsor"}'::jsonb,
   4, true);
```

This brings Pool A (headline_cta) to 4 tiles. Sort_order 4 keeps it after the existing 3.

### Insert sponsor_spotlight tiles

```sql
insert into hero_foreground_tiles (tile_type, payload, sort_order, active) values
  ('sponsor_spotlight',
   '{"sponsor_name":"Rudy''s BBQ","logo_bucket":"sponsor-logos","logo_storage_path":"rudys-bbq.png","tagline":null,"website_url":"https://rudysbbq.com"}'::jsonb,
   101, true),
  ('sponsor_spotlight',
   '{"sponsor_name":"AutoNation Chevrolet West Austin","logo_bucket":"sponsor-logos","logo_storage_path":"autonation-chevrolet-west-austin.png","tagline":null,"website_url":"https://www.autonationchevroletwestaustin.com"}'::jsonb,
   102, true),
  ('sponsor_spotlight',
   '{"sponsor_name":"Sunflower Bank","logo_bucket":"sponsor-logos","logo_storage_path":"sunflower-bank.png","tagline":null,"website_url":"https://www.sunflowerbank.com"}'::jsonb,
   103, true);
```

Sort_order 101+ keeps these grouped after the headline_ctas. The frontend pools them by `tile_type`, so sort_order only matters within each pool.

### Verification (after INSERT)

```sql
-- expect: 7 rows
select name, year from sponsors where year = '2025-26' order by sort_order;

-- expect: 3 rows where featured = true (Rudy's, AutoNation, Sunflower)
select name from sponsors where year = '2025-26' and featured = true order by sort_order;

-- expect: 4 rows
select payload->>'headline' as headline, sort_order from hero_foreground_tiles
where tile_type = 'headline_cta' and active = true order by sort_order;

-- expect: 3 rows (Rudy's, AutoNation, Sunflower)
select payload->>'sponsor_name' as sponsor, sort_order from hero_foreground_tiles
where tile_type = 'sponsor_spotlight' and active = true order by sort_order;
```

### Rollback

`039_rollback.sql`:
```sql
delete from hero_foreground_tiles
  where tile_type = 'sponsor_spotlight'
  and payload->>'sponsor_name' in (
    'Rudy''s BBQ', 'AutoNation Chevrolet West Austin', 'Sunflower Bank'
  );

delete from hero_foreground_tiles
  where tile_type = 'headline_cta'
  and payload->>'headline' = 'Become a Sponsor';

delete from sponsors where year = '2025-26';
```

Schema-only rollback. No table drops, no column drops.

## Helper change: cross-bucket public URLs

`lib/storage.ts` currently has `publicStorageUrl(path)` that constructs URLs assuming the `site-images` bucket (per `commit_homepage_hero_carousel_spec.md` line 189). Update so it accepts an optional bucket name:

```
publicStorageUrl(path, bucket = 'site-images')
  → https://<project>.supabase.co/storage/v1/object/public/{bucket}/{path}
```

Existing callers (hero background images, anything else assuming `site-images`) keep working unchanged because the default is preserved.

Three new callers in this commit:
- `/sponsors` page: pass `bucket = 'sponsor-logos'` when rendering each sponsor's logo.
- Homepage sponsors strip: same.
- Hero carousel `sponsor_spotlight` tile renderer: pass `bucket = payload.logo_bucket ?? 'site-images'` to handle both this commit's tiles (sponsor-logos) and any future tiles that might live in site-images.

## Frontend change 1: HeroCarousel foreground rotation

Current: foreground tiles array is one flat list; `setInterval(11000)` advances `current = (current + 1) % tiles.length`.

New: split tiles by type into two pools at fetch time. Rotation alternates which pool advances each tick, and toggles which pool is showing.

### Data fetching change

Wherever the page currently fetches `hero_foreground_tiles`, it should now split the result:

```
const allTiles = await fetchActiveForegroundTiles();
const ctaTiles = allTiles.filter(t => t.tile_type === 'headline_cta').sort by sort_order;
const sponsorTiles = allTiles.filter(t => t.tile_type === 'sponsor_spotlight').sort by sort_order;
```

Pass both pools as separate props to `<HeroCarousel>`.

### Component state

Inside `<HeroCarousel>`:

```
const [ctaIndex, setCtaIndex] = useState(0);
const [sponsorIndex, setSponsorIndex] = useState(0);
const [activePool, setActivePool] = useState('cta'); // 'cta' | 'sponsor'
```

Initial pool: `'cta'` so the first thing visible is a headline_cta tile (the existing first impression doesn't change).

### Rotation logic

`setInterval` at 11000ms (unchanged) runs:

```
if (activePool === 'cta') {
  if (sponsorTiles.length > 0) {
    // swap to sponsor pool
    setActivePool('sponsor');
    // sponsorIndex stays where it was; we show the next sponsor next time we land here
  } else {
    // no sponsors → stay in cta pool, just advance
    setCtaIndex((i) => (i + 1) % ctaTiles.length);
  }
} else { // activePool === 'sponsor'
  // about to leave sponsor pool: advance sponsor pointer so next visit shows next sponsor
  setSponsorIndex((i) => (i + 1) % sponsorTiles.length);
  if (ctaTiles.length > 0) {
    // swap to cta pool, advance cta pointer so next cta visit shows next cta
    setCtaIndex((i) => (i + 1) % ctaTiles.length);
    setActivePool('cta');
  } else {
    // no ctas → stay in sponsor pool (already advanced)
  }
}
```

Pattern with 4 CTAs + 3 sponsors gives: `CTA1 → S1 → CTA2 → S2 → CTA3 → S3 → CTA4 → S1 → CTA1 → S2 → ...`

CTA and sponsor cycle lengths differ, so the pairing shifts over time. That's fine — desirable, even. Avoids the same CTA always preceding the same sponsor.

### Empty state handling

| ctaTiles.length | sponsorTiles.length | Behavior |
|---|---|---|
| 0 | 0 | No foreground rendered (no scrim either). Photos rotate alone. Matches existing zero-tile spec. |
| >0 | 0 | Single pool: rotate ctaTiles. activePool stays `'cta'`. |
| 0 | >0 | Initial activePool flips to `'sponsor'`. Single pool: rotate sponsorTiles. |
| >0 | >0 | Two-pool alternation as described. |

The single-pool fallbacks must not break when migration 039 hasn't run yet (so on a fresh checkout pulling production data, the page works with 0 sponsor tiles).

### Rendering the active tile

The render function picks one tile from the active pool:

```
const currentTile = activePool === 'cta'
  ? ctaTiles[ctaIndex]
  : sponsorTiles[sponsorIndex];
```

Then dispatches on `currentTile.tile_type` to render the appropriate JSX (existing headline_cta and sponsor_spotlight blocks per the carousel spec). Both rendering blocks stay the same except the sponsor_spotlight block updates to wrap the logo in a link when `payload.website_url` is present.

### Sponsor_spotlight tile: clickable logo

Current rendering per carousel spec:
```
<img src={publicStorageUrl(payload.logo_storage_path)}
     alt={payload.sponsor_name}
     class="h-24 md:h-32 mt-4" />
```

New rendering (uses the updated helper signature):
```
const logoSrc = publicStorageUrl(
  payload.logo_storage_path,
  payload.logo_bucket ?? 'site-images'
);

{payload.website_url ? (
  <a href={payload.website_url} target="_blank" rel="noopener noreferrer"
     class="hover:opacity-80 transition-opacity">
    <img src={logoSrc} alt={payload.sponsor_name} class="h-24 md:h-32 mt-4" />
  </a>
) : (
  <img src={logoSrc} alt={payload.sponsor_name} class="h-24 md:h-32 mt-4" />
)}
```

The sponsor name text below the logo does NOT become a link — only the logo.

### Behavior preserved

All other carousel behavior unchanged:
- 7000ms background rotation, independent of foreground
- Pause on hover (whole section)
- Pause on tab hidden
- Respect `prefers-reduced-motion` (show first tile of initial pool, no rotation)
- Cross-fade transitions
- Initial render stable, no flash

The reduced-motion path with two pools: show `ctaTiles[0]` if present, else `sponsorTiles[0]`, else nothing.

## Frontend change 2: homepage sponsors strip restyle

Existing implementation per `content_map_v2.md` `/` section #6:
- Heading "Thank You to Our Sponsors"
- Horizontal scrolling row of sponsor logos, uniform size
- "See all sponsors →" link to `/sponsors`

Jeremy's feedback: "not near as big as current." Restyle:

- **Heading**: drop from full section heading to small caps text. Text: `OUR 2025-26 SPONSORS` (pull year from `site_settings.current_year`, format as small caps).
- **Heading typography**: `text-xs md:text-sm uppercase tracking-widest text-gray-600 font-semibold`
- **"See all sponsors →" link**: inline with the heading, right-aligned on desktop, below on mobile. Same small-caps style, slightly lighter weight.
- **Logo row**: no horizontal scrolling. Single flex row, wraps on mobile. Logo height drops to `h-10 md:h-12` (was likely `h-16` or larger). Generous horizontal gap (`gap-8 md:gap-12`).
- **Logo alignment**: `items-center` so logos with different aspect ratios visually balance.
- **Section padding**: tighter than before — `py-8 md:py-12` (was likely `py-16` or more).
- **Background**: stays transparent or matches the surrounding section. Don't add a separate colored band.
- **Logo treatment**: each logo wrapped in `<a href={sponsor.website_url} target="_blank" rel="noopener noreferrer" class="hover:opacity-80 transition-opacity">` when `website_url` present. Same link convention as carousel.

Visual goal: a quiet pre-footer thank-you, not a marketing section. Big sponsor moments live in the hero carousel and on `/sponsors`.

Query stays the same (sponsors where `active = true` and `year = current_year`). All 7 sponsors appear here, not just the carousel-featured 3.

## Frontend change 3: `/sponsors` page — verify, do not modify

Existing `/sponsors` implementation already specs:
- Page header with "Become a Sponsor →" top-right
- Tier groupings (MVP largest → Blue smallest)
- "Hide if no sponsors at this tier" rule
- Footer CTA card

With this seed:
- MVP section: 1 logo (Rudy's), large
- Gold section: 6 logos (others), medium
- Diamond, Platinum, Blue sections: hidden (no sponsors)
- Footer CTA card: rendered

CC verifies the page renders correctly after the migration applies. **No code changes expected.** If the page doesn't render as described, file a followup — don't fix in this commit. This commit's scope is locked at: seed migration + carousel JS + homepage strip restyle.

Also verify each sponsor logo is clickable to `website_url` on the page. If the existing implementation doesn't wrap logos in links, add the same `<a>` wrapper used in the homepage strip. Same target/rel/hover treatment.

## Acceptance criteria

1. Migration 039 applies cleanly. Verification queries return the expected row counts.
2. Homepage hero carousel rotates foreground tiles in the alternating pattern: headline_cta → sponsor_spotlight → headline_cta → sponsor_spotlight, cycling through 4 CTAs and 3 sponsors at different rates so pairings shift.
3. Each sponsor_spotlight tile in the carousel: logo clickable, opens sponsor's website in a new tab.
4. "Become a Sponsor" tile appears in the CTA rotation, clicks through to `/boosters/sponsor`.
5. Homepage sponsors strip: small-caps heading, all 7 logos visible in a single row (desktop), wraps to multiple rows on mobile, no horizontal scroll. Logos clickable.
6. `/sponsors` page: Rudy's appears in MVP section large, 6 others in Gold section medium. Diamond/Platinum/Blue sections hidden. Each logo clickable.
7. Carousel still respects prefers-reduced-motion, pause-on-hover, pause-on-tab-hidden.
8. No console errors on `/` or `/sponsors`.
9. Lighthouse a11y ≥ 90 on `/` and `/sponsors`.

## Rollback path

If the migration looks right but the carousel JS breaks production: revert the commit. Migration data stays; the previous flat-rotation carousel handles `sponsor_spotlight` tiles fine (per the original 036/037 spec). The 4th headline_cta and 3 sponsor_spotlight tiles just join the flat rotation. Worst case: rotation order isn't alternating, but nothing breaks.

If the migration itself causes problems: run `039_rollback.sql`. Removes all seeded sponsor rows and the new tiles. Carousel falls back to the original 3 CTAs.

## Open items for Jeremy to confirm before CC applies

1. Confirm display name spelling, especially **Rudy's BBQ** (the apostrophe in SQL is escaped as `''`; visible text uses curly or straight apostrophe per the rest of the site — match whatever the current implementation does).
2. Confirm **"Laurie Flood, Realtor"** with the comma. (The HTML title used "Laurie Flood Realtor" without a comma. Pick one and we go.)
3. Confirm all 7 logo files uploaded to the `sponsor-logos` bucket (at root, no folder nesting) with exact filenames listed above before CC applies the migration.
4. CC must verify `logo_url` column convention by reading existing rows. If prior data uses full URLs, CC reports back and Jeremy decides whether the migration switches to full URLs OR a separate small migration converts existing rows to bare filenames. Don't decide in advance.

## What changes in other docs after this ships

- `commit_homepage_hero_carousel_spec.md` gets a note in the "Payload shapes" section: "**Updated 2026-05-22:** sponsor_spotlight payload now includes optional `website_url` (clickable logos) and optional `logo_bucket` (defaults to `site-images`, set to `sponsor-logos` when reading from that bucket). The `publicStorageUrl` helper now takes an optional bucket arg. See `commit_sponsors_seed_and_carousel_spec.md`."
- `content_map_v2.md` `/` section #6 updated to reflect the smaller-strip styling.
- `followups.md` — the "SE Tier 1 capture: sponsor logos" line moves to done (or at least: the placeholder set is in place; real 2026-27 sponsors swap in via admin once Kendra confirms).
