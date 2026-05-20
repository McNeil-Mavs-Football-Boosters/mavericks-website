# Spec: Homepage Hero Carousel (Option C2 — independent rotations)

Written 2026-05-19. Replaces the current static navy hero on `/` with a full-bleed photo carousel that has two independent rotation layers: background images and foreground tiles. Source of truth for the rotation behavior is this doc; do not infer from `content_map_v2.md`'s `/` section, which describes the old single-image hero and will be updated post-implementation.

## What this is

A new top section of the homepage. Replaces the existing static hero block entirely. Two rotation layers running on separate timers, decoupled so a photo swap requires no foreground edit and vice versa.

- **Layer 1: background photos.** Cycle of N images, cross-fading every 7 seconds.
- **Layer 2: foreground tiles.** Cycle of M content tiles, cross-fading every 11 seconds. Tiles render on a dark scrim over the photo so text stays readable regardless of which photo is currently showing.

Layers do not coordinate. Photo X may be visible during any foreground tile and vice versa.

## What this is NOT

- Not an admin-editable feature in this commit. Content is seeded. Admin CRUD is Phase 2.
- Not C1 (coupled slides). Each photo is not paired to a headline.
- Not a replacement for the Next Game card or Quick Links band. Those sections stay where they are, immediately below the carousel.
- Not a hero on `/boosters`. The previous static hero block is being relocated to `/boosters` per separate scope — see "Relocation of current hero" section below.

## Migrations

Two new tables. Both small. One migration file, applied via the standard psql workflow.

`db/migrations/035_hero_carousel.sql` (or next sequential number — confirm before writing). Contents:

```sql
-- hero_background_images: photos that rotate behind everything in the homepage hero
create table hero_background_images (
  id uuid primary key default gen_random_uuid(),
  storage_path text not null,         -- e.g. 'hero/hero-01.jpg' inside the site-images bucket
  alt_text text not null,             -- accessibility; describe the photo
  sort_order int not null default 0,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index hero_background_images_active_sort_idx
  on hero_background_images (active, sort_order);

-- hero_foreground_tiles: rotating content tiles overlaying the photos
-- tile_type drives rendering; payload is jsonb for flexibility
create type hero_tile_type as enum ('headline_cta', 'sponsor_spotlight');

create table hero_foreground_tiles (
  id uuid primary key default gen_random_uuid(),
  tile_type hero_tile_type not null,
  payload jsonb not null,             -- shape depends on tile_type; see below
  sort_order int not null default 0,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index hero_foreground_tiles_active_sort_idx
  on hero_foreground_tiles (active, sort_order);

-- standard updated_at triggers
create trigger touch_hero_background_images
  before update on hero_background_images
  for each row execute function touch_updated_at();

create trigger touch_hero_foreground_tiles
  before update on hero_foreground_tiles
  for each row execute function touch_updated_at();

-- RLS: public read of active rows, no public write
alter table hero_background_images enable row level security;
alter table hero_foreground_tiles enable row level security;

create policy hero_bg_public_read on hero_background_images
  for select using (active = true);

create policy hero_fg_public_read on hero_foreground_tiles
  for select using (active = true);

-- (Admin write policies come with the admin CRUD work; not in this migration.)
```

### Payload shapes

`hero_foreground_tiles.payload` is jsonb. Shape depends on `tile_type`:

**`headline_cta`:**
```json
{
  "headline": "McNeil Mavericks Football",
  "subhead": "Home of the McNeil Mavericks, Austin, TX",
  "cta_label": "Join the Booster Club",
  "cta_url": "/boosters/join"
}
```
All four fields required.

**`sponsor_spotlight`:**
```json
{
  "sponsor_name": "Round Rock Honda",
  "logo_storage_path": "sponsors/round-rock-honda.png",
  "tagline": "Proud Mavs sponsor since 2022"
}
```
`sponsor_name` and `logo_storage_path` required. `tagline` optional.

The page renders each tile type differently; see "Frontend rendering" below.

### Seed

In the same migration, seed rows. Background images: insert one row per photo Jeremy uploads. Storage paths follow the convention `hero/hero-01.jpg`, `hero/hero-02.jpg`, etc., inside the `site-images` bucket.

Jeremy will provide the count and the alt text for each photo before this migration is written. Do not seed background images blindly.

Foreground tiles seed (initial set):

| sort_order | tile_type | payload |
|---|---|---|
| 1 | headline_cta | `{"headline":"McNeil Mavericks Football","subhead":"Home of the McNeil Mavericks, Austin, TX","cta_label":"Join the Booster Club","cta_url":"/boosters/join"}` |
| 2 | headline_cta | `{"headline":"Support the Mavs","subhead":"Your booster dues fund equipment, meals, and senior gifts.","cta_label":"Make a Donation","cta_url":"/boosters/donate"}` |
| 3 | headline_cta | `{"headline":"Get Involved","subhead":"Game-day help, banquet planning, sponsor outreach. We need you.","cta_label":"Volunteer","cta_url":"/boosters/volunteer"}` |

Sponsor spotlight tiles are not seeded in this migration. Sponsors will be wired up in a follow-up once sponsor logos are captured from SE (followups.md, "SE Tier 1 capture").

### Verification queries after apply

```sql
select count(*) from hero_background_images where active = true;
-- expect Jeremy's photo count

select count(*) from hero_foreground_tiles where active = true and tile_type = 'headline_cta';
-- expect 3

select tile_type, payload->>'headline' as headline, sort_order
from hero_foreground_tiles where active = true order by sort_order;
-- spot-check: 3 rows, sort_order 1/2/3, headlines match seed table above
```

### Rollback

`035_rollback.sql`: drop both tables, drop the enum, in reverse order. Schema-only rollback; the seed disappears with the tables.

## Storage

Backgrounds and sponsor logos both live in the existing `site-images` Supabase Storage bucket (created in migration 009, per `schema.md` line 930).

- Background photos go into `hero/` folder inside `site-images`. Example: `site-images/hero/hero-01.jpg`.
- Sponsor logos (when wired up) go into `sponsors/` folder. Example: `site-images/sponsors/round-rock-honda.png`.

Bucket is already public-readable per the migration 009 policies. No new bucket needed.

**Constraint check:** the bucket is capped at 10MB per file. Jeremy's source photos at 20-25MB will not upload. Resize to ≤1920px longest side, JPEG quality 80, target 200-500KB each. Walkthrough lives in the chat where this spec originated.

## Frontend rendering

### Component structure

Create a new client component at `components/home/HeroCarousel.tsx`. Client component because rotation requires `useEffect` + `setInterval`. The homepage `page.tsx` is server, fetches the data, passes it as props to `<HeroCarousel backgrounds={...} tiles={...} />`.

Data fetch in `app/page.tsx` (or wherever the home route lives):

```
const supabase = createServerClient()  // anon-key client; see followups.md note
const [{ data: backgrounds }, { data: tiles }] = await Promise.all([
  supabase.from('hero_background_images').select('*').eq('active', true).order('sort_order'),
  supabase.from('hero_foreground_tiles').select('*').eq('active', true).order('sort_order'),
])
```

Pass both arrays to `<HeroCarousel>`. If either is empty, the component should render a graceful fallback (see "Empty states" below).

### Layout

Full-bleed section. No container padding. Heights:

- Desktop (`md` and up): `min-h-[70vh]`.
- Mobile (default): `min-h-[50vh]`.

This is ~15% taller than the existing static hero on desktop, per Jeremy's request.

### Background layer

Render all background images as absolutely-positioned `<img>` elements stacked on top of each other inside a relatively-positioned wrapper. Use `next/image` with `priority` on the first image, regular loading on the rest. Each image has its own opacity controlled by React state; the "current" image has `opacity-100`, the rest `opacity-0`. CSS transition: `transition-opacity duration-1000`. Cross-fade is implicit.

Image rendering:
- `next/image` with `fill` prop
- `object-cover` to crop intelligently
- `sizes="100vw"`
- `alt` from the row's `alt_text`
- Public URL constructed from `storage_path`: `https://<project-ref>.supabase.co/storage/v1/object/public/site-images/<storage_path>`. Helper function `publicStorageUrl(path)` in `lib/storage.ts` — if it doesn't exist, create it.

Rotation: `setInterval` with 7000ms, advance the current index modulo `backgrounds.length`. Single image: no rotation. Zero images: render a solid `#011858` (navy) fallback `<div>` instead of the image stack.

### Foreground layer

Dark scrim over the photos to ensure text contrast. Gradient from `rgba(0,0,0,0.55)` at the bottom to `rgba(0,0,0,0.25)` at the top. Constant across all photos and tiles.

Above the scrim, render the foreground tiles the same way: all absolutely positioned, only the current has `opacity-100`. Vertical centering. Container width respected.

Rotation: `setInterval` with 11000ms, advance modulo `tiles.length`. Single tile: no rotation. Zero tiles: render only the background, no foreground (no scrim either, since there's nothing to make readable).

Tile rendering varies by type:

**`headline_cta` tile:**
```
<h1 class="font-black text-white text-5xl md:text-7xl uppercase tracking-tight">
  {payload.headline}
</h1>
<p class="text-white/90 text-lg md:text-xl mt-4 max-w-2xl">
  {payload.subhead}
</p>
<a href={payload.cta_url}
   class="inline-block mt-8 bg-mavs-navy text-white px-8 py-3 font-bold uppercase">
  {payload.cta_label}
</a>
```
Typography matches existing hero (Lato Black for h1, Lato Bold for CTA). Reuse existing CTA button styling from the current hero — pull from the same component or class set so future brand changes propagate.

**`sponsor_spotlight` tile:**
```
<div class="text-white">
  <p class="uppercase tracking-wide text-sm font-bold opacity-80">Thanks to our sponsor</p>
  <img src={publicStorageUrl(payload.logo_storage_path)}
       alt={payload.sponsor_name}
       class="h-24 md:h-32 mt-4" />
  <p class="mt-4 text-lg font-bold">{payload.sponsor_name}</p>
  {payload.tagline && <p class="text-white/80 italic mt-1">{payload.tagline}</p>}
</div>
```
Logo height bounded, width auto. White-on-dark logos may not contrast on a fully white scrim area; the dark scrim plus the photo behind should give enough variation. If a specific sponsor logo turns out to be unreadable, swap the logo file for a light variant. Don't add per-tile scrim adjustments.

### Behavior

Implement all of these in the client component:

1. **Pause on hover (desktop).** When mouse enters the carousel section, freeze both timers; resume on mouse leave. Detect via `onMouseEnter` / `onMouseLeave` on the section.
2. **Pause on tab hidden.** Use the Page Visibility API (`document.visibilityState`). When hidden, clear both intervals. When visible again, restart from the current indices.
3. **Respect `prefers-reduced-motion`.** If `window.matchMedia('(prefers-reduced-motion: reduce)').matches`, do not start either interval. Show backgrounds[0] and tiles[0] only.
4. **Initial render is stable.** No flash of unstyled content. The first background and first tile must be visible immediately on first paint. Use `priority` on the first `next/image`.
5. **Don't leak intervals.** Clean up both intervals in the `useEffect` return.

### Empty states

| backgrounds.length | tiles.length | Behavior |
|---|---|---|
| 0 | 0 | Render solid navy section with no content. Section still occupies the height. Acceptable as a degraded state during migration timing. |
| 0 | >0 | Solid navy background, tiles rotate on top with the scrim. |
| >0 | 0 | Photos rotate, no scrim, no overlay content. |
| >0 | >0 | Full carousel. |

The page should never throw. The carousel section must always render at the correct height even with zero data.

## Relocation of current hero

The current homepage hero (the navy block with "McNeil Mavericks Football" + Join CTA) moves to `/boosters` as the **first section** of that page. Existing sections on `/boosters` (mission, board grid, affiliations, etc.) slide down — none deleted, none reorganized, just pushed below the new top section.

Implementation:
- Extract the existing hero JSX from `app/page.tsx` (or `app/(public)/page.tsx`) into a reusable component if not already one. Suggested location: `components/shared/StaticHero.tsx` or similar — match existing conventions.
- Mount that component as the first child of `/boosters` page, above the existing mission section.
- The existing hero on `/` is removed entirely. `<HeroCarousel>` takes its place.
- Headline/subhead/CTA on the relocated hero stay as they currently are. No copy changes in this commit.

## Page composition after this commit

`/` (top to bottom):
1. `<HeroCarousel>` — new
2. Next Game card / Season Countdown / hidden — existing
3. Quick Links band — existing
4. Latest News — existing
5. Upcoming Events — existing
6. Sponsors strip — existing
7. Footer — existing

`/boosters` (top to bottom):
1. `<StaticHero>` (relocated from `/`) — new on this page, content unchanged
2. Mission — existing
3. "What dues fund" placeholder — existing
4. Board grid — existing
5. Affiliations — existing
6. Footer — existing

## Acceptance criteria

1. Migration 035 (or next number) applies cleanly via psql. Verification queries return expected results.
2. `/` homepage shows the carousel as the topmost section, ~70vh on desktop, ~50vh on mobile.
3. Background photos cross-fade every 7 seconds in sort_order.
4. Foreground tiles cross-fade every 11 seconds in sort_order, with a dark scrim between them and the photos.
5. With 3 seeded headline_cta tiles, all three are visible in turn within a 35-second window.
6. Mouse hover pauses both rotations. Mouse leave resumes both.
7. Switching to another browser tab pauses; returning resumes.
8. `prefers-reduced-motion: reduce` (test via DevTools rendering emulation) shows only the first photo and first tile, no animation.
9. The current navy static hero appears as the first section of `/boosters`. Existing `/boosters` content is unchanged and rendered below.
10. No console errors on Vercel preview.
11. Lighthouse performance score on `/` desktop stays ≥ 80 (current baseline; carousel must not tank performance via giant images).
12. With zero rows in either table, the section still renders at correct height and the page does not throw.

## Rollback

- Migration: `035_rollback.sql` drops both tables and the enum. Schema-only.
- Page: revert the commit. `/` returns to current static hero. `/boosters` returns to current structure. Storage files in `site-images/hero/` can stay; they're orphaned but harmless.

## Implementation order

Three CC turns:

**Turn 1 — migration.** Write and apply migration 035 (or next sequential number, confirm at apply-time). Seed three `headline_cta` tiles per the table above. Do not seed background images yet — those wait for Jeremy's uploads. Run verification queries. Commit and push. Report counts.

**Turn 2 — relocation.** Extract current homepage hero into a reusable component. Mount it as first section of `/boosters` above existing content. Confirm `/boosters` still renders all existing sections in order below. Commit and push.

**Turn 3 — carousel.** After Jeremy has uploaded photos and confirmed background image rows are seeded (a small follow-up migration he runs, or psql inserts from chat), build `<HeroCarousel>` component per the spec. Replace the homepage top section with it. Verify all behavior items 3-8 above. Commit and push.

Turns 1 and 2 can happen in either order or in parallel. Turn 3 depends on Turn 1 (tables exist) and on Jeremy completing the photo upload.

## Open follow-ups created by this work

Add to `followups.md` after this commit:

- **Admin UI for hero content.** `/admin/hero/backgrounds` (upload, reorder, enable/disable) and `/admin/hero/tiles` (CRUD for headline_cta and sponsor_spotlight tiles). Phase 2.
- **Sponsor spotlight tiles seed.** Wait for SE Tier 1 capture (sponsor logos). Then write a small follow-up migration that inserts `sponsor_spotlight` rows for each active sponsor.
- **Mobile photo variants.** If Lighthouse mobile flags hero images as too large, generate 768w variants of each photo and switch `next/image` to use those on small viewports via `sizes`. Not blocking v1.
- **Featured slide override.** If Jeremy ever wants a temporary coupled slide (e.g. championship game promo where photo + headline are paired), add a `hero_featured_override` row that, when active, suspends both rotations and shows a fixed pairing. Phase 2 or later.

## Shipped state (2026-05-19)

All three turns landed in one session. Implementation status by commit:

- **Turn 1** — Migration **036_hero_carousel.sql** (renumbered from spec's 035; `035_fix_rrisd_athletic_forms_url.sql` shipped first). Two tables, the `hero_tile_type` enum, active+sort_order indexes, `touch_updated_at` triggers, RLS `FOR SELECT TO anon, authenticated USING (active = true)` policies, three `headline_cta` seed rows. Verification: 0 active backgrounds (intentional), 3 active headline_cta tiles in sort_order 1/2/3. Commit `279f47a`.
- **Turn 2** — `<StaticHero>` extracted to `components/shared/StaticHero.tsx`; `lib/hero.ts` houses the shared `HeroFields` type + `HERO_DEFAULTS` + `mergeHero` + `loadHero` server fetcher. Mounted as the first child of `/boosters` (full-bleed, above the existing `max-w-5xl` wrapper). Commit `0cd6c51`.
- **Background image seed** — Migration **037_seed_hero_backgrounds.sql** added six rows under `hero/hero-0{1..6}.jpg` with Jeremy-provided alt text. Paired `037_rollback.sql` introduced the rollback-alongside-migration convention (with the corresponding `apply_all.sql` regen guard noted in `docs/CLAUDE.md`). Commit `4ef9154`.
- **Turn 3** — `components/home/HeroCarousel.tsx` (client component, ~210 lines). Built via two parallel subagents (data layer + UI) against a pre-defined type contract. New helpers: `lib/storage.ts publicStorageUrl` (site-images), `lib/queries/hero.ts loadHeroCarouselData`. Implements all behavior items 1–5 (hover pause, Page Visibility pause, prefers-reduced-motion live-tracked via `matchMedia.addEventListener('change')`, priority on first bg image, interval cleanup). Empty states honor a stricter scrim rule than the empty-state table — scrim only when `backgrounds.length > 0 && tiles.length > 0` (on solid navy the scrim adds nothing because the text is already legible). **Latent next.config.ts bug surfaced + fixed**: `images.remotePatterns` had to be added for `*.supabase.co` under `/storage/v1/object/public/**` because the previous `next/image` callers had only ever pointed at `hero_image_url` which has always been null. Commit `efe2113`.
- **Visual polish** — `object-cover object-top` on background images so cropping happens at the bottom, and section height bumped +10% (`min-h-[55vh] md:min-h-[77vh]` on both the section and the foreground flex container). Commit `8b35446`.

Acceptance criteria 1–10 and 12 verified locally (typecheck + lint baseline-aware + production build + dev-server smoke against `/` and `/boosters` returning 200 with the carousel in SSR). Item 11 (Lighthouse ≥ 80 on Vercel preview) is the deployment-side check.

**HeroCarousel.tsx:35 pre-existing lint error** — `setReducedMotion(mql.matches)` is a synchronous `setState` inside a `useEffect`. The `react-hooks/set-state-in-effect` rule flags it. Acceptable cascading-render cost (one extra render at mount when reduce-motion is on). Proper fix is `useSyncExternalStore` — deferred to followups.md.
